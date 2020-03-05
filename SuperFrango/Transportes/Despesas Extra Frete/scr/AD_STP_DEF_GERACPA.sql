Create Or Replace Procedure "AD_STP_DEF_GERACPA"(P_CODUSU Number, P_IDSESSAO Varchar2, P_QTDLINHAS Number,
																								 P_MENSAGEM Out Varchar2) As
	v_Nudef      Number;
	r_def        ad_tsfdef%Rowtype;
	r_Rec        ad_tsfdefr%Rowtype;
	v_Count      Int;
	v_NomeLibTmp Varchar2(400);
	v_NomeLib    Varchar2(400) := '';
	v_vlrTotRota Float;
	v_Nunota     Number;
	r_prod       tgfpro%Rowtype;
	r_top        tgftop%Rowtype;
	v_atualEst   Int;
	v_Nufin      Number;
	v_vlrParcela Float;
	v_percRat    Float;
	v_provRec    Char(1);
	v_CodUsuLog  Number := stp_get_codusulogado();
	v_CodNat     Number;
	v_VlrTotRec  Float;
	v_dtvenc     Date;
	v_vlrRat     Float;
	v_Historico  tgffin.historico%Type;
	ErrMsg       Varchar2(4000);
	Error Exception;
Begin
	/*
  Dt. Criação: 27/09/2016
  Autor: Marcus Rangel
  Objetivo: Gerar o pedido de compras para ser faturado com a nota do transportador a partir da rotina de despesas extras de frete
  */

	For I In 1 .. P_QTDLINHAS
	Loop
		v_Nudef := ACT_INT_FIELD(P_IDSESSAO, I, 'NUDEF');
	
		Select *
			Into r_def
			From ad_tsfdef
		 Where nudef = v_nudef;
	
		Select Count(*)
			Into v_Count
			From ad_tsfdefr r
		 Where r.nudef = r_def.nudef;
	
		If v_count = 1 Then
			Select *
				Into r_Rec
				From ad_tsfdefr r
			 Where r.nudef = v_nudef;
			If r_rec.usacrmot = 'S' Then
				Select m.codcencus
					Into r_def.codcencusped
					From ad_tsfdefm m
				 Where m.codmot = r_rec.codmot;
			End If;
		End If;
	
		If r_def.codtipoperped Is Null Then
			ErrMsg := 'Top do Pedido de Compras não informada.';
		Elsif r_def.codtipvendaped Is Null Then
			errmsg := 'Tipo de negociação do Pedido de Compras não informado.';
		Elsif r_def.codvend Is Null Then
			ErrMsg := 'Cód Usuário responsável no Pedido de Compras não informado.';
		Elsif r_def.codprod Is Null Then
			ErrMsg := 'Cód. Produto/Serviço do Pedido de Compras  não informado.';
		End If;
	
		If ErrMsg Is Not Null Then
			Raise error;
		End If;
	
		If r_def.status = 'A' Then
			ErrMsg := 'Somente lançamentos liberados podem gerar pedidos de compras.';
			Raise error;
		Elsif r_def.status = 'P' Then
			ErrMsg := 'Já existe pedido de compras gerado para esse lançamento. Nro Único ' || r_def.nunota;
			Raise error;
		End If;
	
		Select Sum(r.vlrdesdob)
			Into v_vlrTotRec
			From ad_tsfdefr r
		 Where nudef = v_Nudef;
		Select Sum(vlrnota)
			Into v_vlrTotRota
			From tgfcab
		 Where ordemcarga = r_def.ordemcarga;
	
		-- verifica se o lançamento já possui pedido de compras
		Begin
			If r_def.nunota Is Not Null Then
				Select Count(*)
					Into v_Count
					From tgfcab c
				 Where c.nunota = r_def.nunota;
				If v_count <> 0 Then
					ErrMsg := 'Já existe pedido de compras gerado para esse lançamento. Nro Único ' || r_def.nunota;
					Raise error;
				End If;
			End If;
		End;
	
		--verifica se o lançamento está aprovado parcialmente
		Begin
			Select Count(*)
				Into v_Count
				From tsilib l
			 Where l.nuchave = v_Nudef
				 And l.tabela = 'AD_TSFDEF'
				 And l.dhlib Is Null;
		
			If v_Count <> 0 Then
				For Lib In (Select codusulib
											From tsilib l
										 Where l.nuchave = v_nudef
											 And dhlib Is Null
											 And tabela = 'AD_TSFDEF')
				Loop
					Select '<font color="green">' || nomeusu || '</font>'
						Into v_NomeLibTmp
						From tsiusu
					 Where codusu = lib.codusulib;
				
					If v_NomeLib Is Null Then
						v_NomeLib := v_NomeLibTmp;
					Else
						v_NomeLib := ' - ' || v_NomeLib || Chr(13) || ' - ' || v_NomeLibTmp;
					End If;
				
				End Loop;
				ErrMsg := 'Somente lançamentos liberados podem gerar pedidos. Aguardando liberação dos seguintes usuários: ' ||
									Chr(10) || v_NomeLib;
				Raise error;
			End If;
		End;
	
		-- insere pedido de compra de serviço de transporte
		Begin
		
			Select *
				Into r_top
				From tgftop
			 Where codtipoper = r_def.codtipoperped
				 And dhalter = ad_get.maxDhTipOper(r_def.codtipoperped);
		
			ad_set.ins_pedidocab(p_codemp => r_def.codemp, p_codparc => r_def.codparctransp,
													 p_codvend => Nvl(r_def.codvend, 0), p_codtipoper => r_def.codtipoperped,
													 p_codtipvenda => r_def.codtipvendaped, p_dtneg => Trunc(Sysdate),
													 p_vlrnota => v_VlrTotRec, p_codnat => r_def.codnatped,
													 p_codcencus => r_def.codcencusped, p_codproj => 0,
													 p_obs => 'Ref.: despesas extras da Ordem de Serviço Nº ' || r_def.ordemcarga,
													 p_nunota => v_Nunota);
		
		Exception
			When Others Then
				ErrMsg := 'Erro ao inserir o cabeçalho do pedido de compras - ' || Sqlerrm;
				Raise error;
		End;
	
		/* Insere a solicitação de liberação do pedido de compras evento 18 */
	
		/* Alteração realizada em 07/11/17 por M. Rangel 
     * Solicitação de Neif Martins, o processo já envia uma solicitação de autorização
     * para o dono do CR, logo a aprovação do pedido pelo transportes, será substituída
     * pela liberação da nota, implementada nos processos de controle que o Ricardo Soares
     * está  implementando.
    */
	
		/*Begin
    
      Begin
        Select codusu
          Into v_CodUsuLib
          From tsiusu u
         Where Nvl(u.ad_gertransp, 'N') = 'S'
           And rownum = 1;
      Exception
        When no_data_found Then
          ErrMsg := 'Não foi encontrado o usuário liberador para o pedido de compras.';
      End;
    
      Begin
      
        Select t.evelibconfped Into v_EveLibPed From ad_tsfelt t Where t.nuelt = 1;
      
        Insert Into tsilib
          (nuchave, tabela, evento, codususolicit, dhsolicit, vlratual, vlrlimite, codusulib, codcencus, codtipoper)
        Values
          (v_nunota, 'TGFCAB', v_EveLibPed, v_CodUsuLog, Sysdate, 1, 99999999999, v_CodUsuLib, r_def.codcencusped, r_def.codtipoperped);
      Exception
        When Others Then
          ErrMsg := 'Erro na criação prévia do evento de liberação do pedido - ' || Sqlerrm;
          Raise error;
      End;
    
    End;*/
	
		Begin
			Select *
				Into r_prod
				From tgfpro
			 Where codprod = r_def.codprod;
		
			If Nvl(r_top.atualest, 'N') = 'N' Then
				v_atualEst := 0;
			Elsif Nvl(r_top.atualest, 'N') = 'S' And r_top.tipmov = 'C' Then
				v_atualEst := 1;
			Elsif Nvl(r_top.atualest, 'N') = 'S' And r_top.tipmov = 'V' Then
				v_atualEst := -1;
			End If;
		
			Ad_set.Ins_Pedidoitens(p_Nunota => v_Nunota, p_Codprod => r_def.codprod, p_Qtdneg => 1,
														 p_codvol => r_prod.codvol, p_Vlrunit => v_VlrTotRec, p_Vlrtotal => v_VlrTotRec,
														 p_Mensagem => errmsg);
			If ErrMsg Is Not Null Then
				Raise error;
			End If;
		
		Exception
			When Others Then
				ErrMsg := 'Erro ao inserir o serviço. ' || Sqlerrm;
				Raise error;
		End;
	
		-- inserir o financeiro e o rateio
		Begin
		
			If r_top.atualfin = 0 Then
				Return;
			End If;
		
			If r_top.tipatualfin = 'I' Then
				v_provRec := 'N';
			Else
				v_provRec := 'S';
			End If;
		
			For c_Ppg In (Select *
											From tgfppg ppg
										 Where ppg.codtipvenda = r_def.codtipvendaped
										 Order By ppg.sequencia)
			Loop
				v_vlrParcela := v_vlrTotrec * (c_Ppg.percentual / 100);
				v_Nufin      := seq_tgffin_nufin.nextval;
			
				If c_ppg.codnatpad = 0 Then
					v_codNat := r_def.codnatped;
				Else
					v_Codnat := c_ppg.codnatpad;
				End If;
			
				v_dtvenc := Trunc(Sysdate) + c_ppg.prazo;
			
				If To_Char(v_dtvenc, 'd') = 7 Then
					v_Dtvenc := v_dtvenc + 2;
				End If;
			
				If To_Char(v_dtvenc, 'd') = 1 Then
					v_dtvenc := v_dtvenc + 1;
				End If;
			
				-- preenche o historico com os tipos de despesas dos recibos
				Begin
					For Rec In (Select m.descricao
												From ad_tsfdefr r
											 Inner Join ad_tsfdefm m
													On (r.codmotpai = m.codmot And m.analitico = 'N')
											 Where r.nudef = v_nudef
											 Group By m.descricao)
					Loop
						If v_Historico Is Null Then
							v_Historico := rec.descricao;
						Else
							v_Historico := v_Historico || '; ' || rec.descricao;
						End If;
					End Loop;
					v_Historico := 'Ref. despesas de: ' || v_Historico;
				End;
			
				Begin
				
					Insert Into tgffin
						(nufin, nunota, codemp, numnota, dtneg, dhmov, dtvenc, dtalter, dtentsai, codparc, codtipoper,
						 dhtipoper, codnat, codcencus, vlrdesdob, origem, recdesp, provisao, historico, autorizado)
					Values
						(v_nufin, v_nunota, r_def.codemp, 0, Trunc(Sysdate), Sysdate, v_DtVenc, Sysdate, Sysdate,
						 r_def.codparctransp, r_def.codtipoperped, r_top.dhalter, v_codNat, r_def.codcencusped,
						 v_vlrParcela, 'E', r_top.atualfin, v_provRec, v_Historico, 'S');
				
				Exception
					When Others Then
						ErrMsg := 'Erro na inclusão do financeiro. ' || Sqlerrm;
						Raise error;
				End;
			
				-- insere o rateio
				Begin
				
					For c_rec In (Select r.rateio_oc, r.codcencus, Sum(r.vlrdesdob) As vlrdesdob
													From ad_tsfdefr r
												 Where nudef = v_Nudef
												 Group By r.rateio_oc, r.codcencus)
					Loop
						If Nvl(c_rec.rateio_oc, 'N') = 'S' Then
						
							For c_Cus In (Select u.codcencus, Sum(c.vlrnota) valor
															From tgfcab c, tsicus u
														 Where c.codcencus = u.codcencus
															 And c.ordemcarga = r_Def.Ordemcarga
														 Group By u.codcencus)
							Loop
								v_percRat := 100 * (c_cus.valor / v_vlrTotRota);
								v_vlrRat  := c_rec.vlrdesdob * (v_percRat / 100);
								v_percRat := 100 * (v_vlrrat / v_VlrTotRec);
								v_count   := 0;
							
								-- insere/atualiza rateio para esse CR
								Begin
									Merge Into tgfrat r
									Using (Select v_nufin As nufin, v_codnat As codnat, c_cus.codcencus As codcencus
													 From dual) C
									On (r.nufin = c.nufin And r.codnat = c.codnat And r.codcencus = c.codcencus)
									When Matched Then
										Update
											 Set r.percrateio = r.percrateio + v_percRat
									When Not Matched Then
										Insert
											(origem, nufin, codnat, codcencus, codproj, percrateio, codusu, dtalter)
										Values
											('F', v_Nufin, v_codnat, c_cus.codcencus, 0, Round(v_percrat, 5), v_CodUsuLog, Sysdate);
								End;
							
							End Loop; ---end c_cus
						Else
							-- rateio_oc = N
							v_percRat := 0;
							v_percRat := 100 * (c_rec.vlrdesdob / v_VlrTotRec);
							v_count   := 0;
						
							Begin
							
								Merge Into tgfrat r
								Using (Select v_nufin As nufin, v_codnat As codnat, c_rec.codcencus As codcencus
												 From dual) C
								On (r.nufin = c.nufin And r.codnat = c.codnat And r.codcencus = c.codcencus)
								When Matched Then
									Update
										 Set r.percrateio = r.percrateio + v_percRat
								When Not Matched Then
									Insert
										(origem, nufin, codnat, codcencus, codproj, percrateio, codusu, dtalter)
									Values
										('F', v_Nufin, r_def.codnatped, c_rec.codcencus, 0, Round(v_percrat, 5), v_CodUsuLog,
										 Sysdate);
							
								Update tgffin f
									 Set f.rateado = 'S'
								 Where nufin = v_nufin;
							
							End;
						
						End If;
					End Loop; -- end c_rec
				End;
			End Loop;
		End;
	
	End Loop;

	P_MENSAGEM := 'Pedido Nº único <a target="_parent" href="' || ad_fnc_urlskw('TGFCAB', v_nunota) || '"> <u>' ||
								v_nunota || '</u></a> inserido com sucesso.';

	Update ad_tsfdef d
		 Set d.nunota = v_Nunota, d.status = 'P'
	 Where nudef = v_nudef;

	Insert Into ad_tblcmf
		(nometaborig, nuchaveorig, nometabdest, nuchavedest)
	Values
		('AD_TSFDEF', v_nudef, 'TGFCAB', v_nunota);

Exception
	When error Then
		Rollback;
		Delete From tgfcab
		 Where nunota = v_nunota; -- melhor não arriscar
		P_MENSAGEM := ErrMsg;
	When Others Then
		Rollback;
		Delete From tgfcab
		 Where nunota = v_nunota;
		P_MENSAGEM := 'Encontrado um problema. Detalhes: ' || Sqlerrm;
End;
/
