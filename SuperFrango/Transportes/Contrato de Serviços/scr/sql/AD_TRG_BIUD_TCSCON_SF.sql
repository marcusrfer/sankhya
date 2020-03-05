Create Or Replace Trigger AD_TRG_BIUD_TCSCON_SF
	Before Insert Or Update Or Delete On tcscon
	For Each Row
Declare
	v_NuApont  Int;
	v_Temmed   Char(1);
	v_NuSeqMaq Int := 0;
	v_NomeParc Varchar2(1000);
	errmsg     Varchar2(1000);
	error Exception;
Begin
	/*
    Autor: Marcus Rangel
    Processo: Contrata��o de servi�os de Transportes
    Objetivo: Controle de altera��es de acordo com o status do contrato. 
              Gera��o autom�tica do apontamento. 
              Tratativa para aditivos e contratos sem medi��o 
  */

	/* Hist�rico de Mudan�as
  * 12/12/2016 - valida��o da parcela do contrato por empreito
  * 25/04/2017 - Remo��o da atualiza��o da solicita��o de origem no delete, enviado para trigger After
  * 28/08/2018 - adicionado o campo ad_codusuapont no contrato, atualizado o insert da ad_tsfahmc para preencher
                 esse campo.
  */
	-- sa�da para quando o contrato n�o � oriundo de solicita��o de servi�os de transportes.
	If inserting Or updating Or deleting Then
		If Nvl(:old.Ad_Codsolst, :new.Ad_Codsolst) Is Null Then
			Return;
		End If;
	End If;

	If inserting Then
		If Nvl(:new.Temmed, 'N') = 'N' Then
		
			If :new.Parcelaqtd Is Null Then
				errmsg := '� necess�rio informar a quantidade de parcelas para contratos que n�o possuem medi��o.';
				Raise error;
			End If;
		
		End If;
	End If;

	If updating Then
		-- valida altera��o de status
		If :new.Temmed = 'S' And updating('AD_SITUACAO') Then
		
			/*Contratos situa��o
        pendente para confirmado - ok
        Confirmado para execu��o - ok
        Confirmado para cancelado - ok
        Em execu��o para conclu�do - ok
        Em execu��o para cancelado - ok
      */
			If :old.ad_situacao <> :new.Ad_Situacao Then
				If Not ((:old.Ad_Situacao = 'P' And :new.Ad_Situacao = 'L') Or
						(:old.Ad_Situacao = 'C' And :new.Ad_Situacao = 'E') Or
						(:old.Ad_Situacao = 'C' And :new.Ad_Situacao = '0') Or
						(:old.Ad_Situacao = 'E' And :new.Ad_Situacao = 'C') Or
						(:old.Ad_Situacao = 'E' And :new.Ad_Situacao = '0')) Then
					errmsg := 'Altera��o de Status n�o permitida (De ' || :old.Ad_Situacao || ', para ' ||
										:new.Ad_Situacao || ').';
					Raise error;
				End If;
			End If;
		
			Begin
				Select temmed
					Into v_temmed
					From (Select m.temmed
									From ad_tsfsstm m
								 Where m.codsolst = :new.Ad_Codsolst
									 And m.numcontrato = :new.Numcontrato
								 Group By m.temmed
								Union
								Select i.temmed
									From ad_tsfssti i
								 Where i.codsolst = :new.Ad_Codsolst
									 And i.numcontrato = :new.Numcontrato
								 Group By i.temmed);
			Exception
				When no_data_found Then
					errmsg := 'A solicita��o que originou esse contrato n�o possui medi��o.';
					Raise error;
				When too_many_rows Then
					errmsg := 'Este contrato possui um erro, pois um contrato n�o pode possuir formas de medi��es diferentes, verifique a solicita��o nro ' ||
										:new.Ad_Codsolst || '.';
					Raise error;
			End;
		
			If Nvl(v_temmed, 'N') <> 'S' Then
				errmsg := 'A solicita��o nro ' || :new.Ad_Codsolst ||
									' n�o est� marcada para trabalhar com medi��o.';
				Raise error;
			End If;
		
		End If;
	
		<<check_contrato>>
	
		/*Confirma��o do Contrato*/
	
		/*Se pendente mundando para Confirmado e possui medi��o*/
		If (Nvl(:old.Ad_Situacao, 'P') = 'P' And :New.Ad_Situacao = 'L') Then
			If :new.Temmed = 'S' Then
				/*tratativa para aditivos, se n�o tem, insere um novo apontamento*/
				If :new.numcontratoorigem Is Null Then
				
					Select Nvl(Max(nuapont), 0) + 1
						Into v_NuApont
						From AD_TSFAHMC;
				
					Select nomeparc
						Into v_nomeparc
						From tgfpar
					 Where codparc = :new.Codparc;
				
					Begin
						If :new.Ad_Codusuapont Is Null Then
							errmsg := 'Para contratos que possuem apontamento, o c�digo do usu�rio respons�vel pelo apontemento � obrigat�rio.';
							Raise error;
						End If;
					
						Insert Into ad_tsfahmc
							(nuapont, pendente, dtcontrato, nomeparc, numcontrato, codcencus, codproj, codusur)
						Values
							(v_NuApont, 'S', :new.Dtcontrato, v_nomeparc, :new.Numcontrato, :new.Codcencus,
							 :new.Codproj, :new.Ad_Codusuapont);
					Exception
						When Others Then
							errmsg := 'Erro na gera��o do apontamento. - ' || Sqlerrm;
							Raise error;
					End;
				
					/*Cursor para leitura dos servi�os da solicita��o*/
					For c_Serv In (Select *
													 From ad_tsfssti i
													Where i.codsolst = :new.Ad_Codsolst)
					Loop
					
						If c_serv.numcontrato Is Null Then
						
							/*Cursor para leiutura das maquinas e veiculos*/
							For c_Maq In (Select *
															From ad_tsfsstm m
														 Where m.codsolst = c_Serv.codsolst
															 And m.codserv = c_serv.codserv
															 And m.numcontrato = :new.Numcontrato)
							Loop
								Begin
									v_Nuseqmaq := v_Nuseqmaq + 1;
									Insert Into ad_tsfahmmaq
										(nuapont, numcontrato, codprod, codmaq, codvol, codsolst, codproj, qtdprevista,
										 qtdusada, saldohoras, id, nuseqmaq, nussti, seqmaq)
									Values
										(v_nuapont, :new.Numcontrato, c_maq.codserv, c_maq.codmaq, c_maq.codvol,
										 :new.Ad_Codsolst, :new.Codproj, Null, Null, Null, c_maq.id, v_Nuseqmaq,
										 c_maq.nussti, c_maq.seqmaq);
								Exception
									When Others Then
										errmsg := 'Erro ao inserir os servi�os do contrato ' || :new.Numcontrato ||
															Chr(13) || Sqlerrm;
										Raise error;
								End;
							End Loop c_Maq;
						
						End If;
					
					End Loop c_Serv;
				Else
					/*Insere apenas os servi�os e as maquinas da solicita��o no apontamento existente*/
					v_nuapont := ad_pkg_ahm.NuApontOrig(:new.Numcontratoorigem);
				
					If v_nuapont <> 0 Then
						For c_Serv In (Select *
														 From ad_tsfssti i
														Where i.codsolst = :new.Ad_Codsolst)
						Loop
							For c_Maq In (Select *
															From ad_tsfsstm m
														 Where m.codsolst = c_Serv.codsolst
															 And m.codserv = c_serv.codserv
															 And m.numcontrato = :new.Numcontrato)
							Loop
								Begin
									Insert Into ad_tsfahmmaq
										(nuapont, numcontrato, codsolst, codmaq, id, codprod, codvol)
									Values
										(v_nuapont, :new.Numcontrato, :new.Ad_Codsolst, c_maq.codmaq, c_maq.id,
										 c_maq.codserv, c_maq.codvol);
								Exception
									When Others Then
										errmsg := 'Erro ao inserir os servi�os do contrato ' || :new.Numcontrato;
										Raise error;
								End;
							End Loop c_Maq;
						End Loop c_Serv;
					End If;
				End If; -- end of numcontrato is null
			Else
				/*Se n�o tem Medi��o*/
				If :new.Codtipvenda Is Null Or :new.Codtipvenda = 0 Then
					errmsg := 'Para contratos sem medi��o, o tipo de negocia��o � obrigat�rio.';
					Raise error;
				End If;
			
				/*valida parcela pra gera��o de pedidos*/
				If :new.Parcelaatual > :new.Parcelaqtd Then
					errmsg := 'Essa parcela ultrapassa a quantidade de parcelas definidas para esse contrato.';
					Raise error;
				End If;
			
				If :new.Parcelaatual = :new.Parcelaqtd Then
					:new.Ad_Situacao := 'C';
				End If;
			
			End If; -- end of tem medi��o
		End If; -- end of confirmando
		:new.Ad_Nuapont := v_nuapont;
	End If; -- end of updating

Exception
	When error Then
		Raise_Application_Error(-20105, ad_fnc_formataerro(errmsg));
	When Others Then
		errmsg := Sqlerrm;
		Raise_Application_Error(-20105, ad_fnc_formataerro(errmsg));
End;
/
