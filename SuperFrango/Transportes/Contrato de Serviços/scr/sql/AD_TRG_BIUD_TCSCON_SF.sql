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
    Processo: Contratação de serviços de Transportes
    Objetivo: Controle de alterações de acordo com o status do contrato. 
              Geração automática do apontamento. 
              Tratativa para aditivos e contratos sem medição 
  */

	/* Histórico de Mudanças
  * 12/12/2016 - validação da parcela do contrato por empreito
  * 25/04/2017 - Remoção da atualização da solicitação de origem no delete, enviado para trigger After
  * 28/08/2018 - adicionado o campo ad_codusuapont no contrato, atualizado o insert da ad_tsfahmc para preencher
                 esse campo.
  */
	-- saída para quando o contrato não é oriundo de solicitação de serviços de transportes.
	If inserting Or updating Or deleting Then
		If Nvl(:old.Ad_Codsolst, :new.Ad_Codsolst) Is Null Then
			Return;
		End If;
	End If;

	If inserting Then
		If Nvl(:new.Temmed, 'N') = 'N' Then
		
			If :new.Parcelaqtd Is Null Then
				errmsg := 'É necessário informar a quantidade de parcelas para contratos que não possuem medição.';
				Raise error;
			End If;
		
		End If;
	End If;

	If updating Then
		-- valida alteração de status
		If :new.Temmed = 'S' And updating('AD_SITUACAO') Then
		
			/*Contratos situação
        pendente para confirmado - ok
        Confirmado para execução - ok
        Confirmado para cancelado - ok
        Em execução para concluído - ok
        Em execução para cancelado - ok
      */
			If :old.ad_situacao <> :new.Ad_Situacao Then
				If Not ((:old.Ad_Situacao = 'P' And :new.Ad_Situacao = 'L') Or
						(:old.Ad_Situacao = 'C' And :new.Ad_Situacao = 'E') Or
						(:old.Ad_Situacao = 'C' And :new.Ad_Situacao = '0') Or
						(:old.Ad_Situacao = 'E' And :new.Ad_Situacao = 'C') Or
						(:old.Ad_Situacao = 'E' And :new.Ad_Situacao = '0')) Then
					errmsg := 'Alteração de Status não permitida (De ' || :old.Ad_Situacao || ', para ' ||
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
					errmsg := 'A solicitação que originou esse contrato não possui medição.';
					Raise error;
				When too_many_rows Then
					errmsg := 'Este contrato possui um erro, pois um contrato não pode possuir formas de medições diferentes, verifique a solicitação nro ' ||
										:new.Ad_Codsolst || '.';
					Raise error;
			End;
		
			If Nvl(v_temmed, 'N') <> 'S' Then
				errmsg := 'A solicitação nro ' || :new.Ad_Codsolst ||
									' não está marcada para trabalhar com medição.';
				Raise error;
			End If;
		
		End If;
	
		<<check_contrato>>
	
		/*Confirmação do Contrato*/
	
		/*Se pendente mundando para Confirmado e possui medição*/
		If (Nvl(:old.Ad_Situacao, 'P') = 'P' And :New.Ad_Situacao = 'L') Then
			If :new.Temmed = 'S' Then
				/*tratativa para aditivos, se não tem, insere um novo apontamento*/
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
							errmsg := 'Para contratos que possuem apontamento, o código do usuário responsável pelo apontemento é obrigatório.';
							Raise error;
						End If;
					
						Insert Into ad_tsfahmc
							(nuapont, pendente, dtcontrato, nomeparc, numcontrato, codcencus, codproj, codusur)
						Values
							(v_NuApont, 'S', :new.Dtcontrato, v_nomeparc, :new.Numcontrato, :new.Codcencus,
							 :new.Codproj, :new.Ad_Codusuapont);
					Exception
						When Others Then
							errmsg := 'Erro na geração do apontamento. - ' || Sqlerrm;
							Raise error;
					End;
				
					/*Cursor para leitura dos serviços da solicitação*/
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
										errmsg := 'Erro ao inserir os serviços do contrato ' || :new.Numcontrato ||
															Chr(13) || Sqlerrm;
										Raise error;
								End;
							End Loop c_Maq;
						
						End If;
					
					End Loop c_Serv;
				Else
					/*Insere apenas os serviços e as maquinas da solicitação no apontamento existente*/
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
										errmsg := 'Erro ao inserir os serviços do contrato ' || :new.Numcontrato;
										Raise error;
								End;
							End Loop c_Maq;
						End Loop c_Serv;
					End If;
				End If; -- end of numcontrato is null
			Else
				/*Se não tem Medição*/
				If :new.Codtipvenda Is Null Or :new.Codtipvenda = 0 Then
					errmsg := 'Para contratos sem medição, o tipo de negociação é obrigatório.';
					Raise error;
				End If;
			
				/*valida parcela pra geração de pedidos*/
				If :new.Parcelaatual > :new.Parcelaqtd Then
					errmsg := 'Essa parcela ultrapassa a quantidade de parcelas definidas para esse contrato.';
					Raise error;
				End If;
			
				If :new.Parcelaatual = :new.Parcelaqtd Then
					:new.Ad_Situacao := 'C';
				End If;
			
			End If; -- end of tem medição
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
