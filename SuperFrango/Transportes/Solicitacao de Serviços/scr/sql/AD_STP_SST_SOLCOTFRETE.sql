Create Or Replace Procedure "AD_STP_SST_SOLCOTFRETE"(P_CODUSU    Number,
																										 P_IDSESSAO  Varchar2,
																										 P_QTDLINHAS Number,
																										 P_MENSAGEM  Out Varchar2) As
	v_Nunota         Number;
	c                tgfcab%Rowtype;
	p                tgfpar%Rowtype;
	v_Codsolicitacao Number;
	v_Nussti         Number := 0;
	v_Obs            Varchar2(400);
	v_itens          Varchar2(2000);
	Errmsg           Varchar2(4000);
	Error Exception;
Begin
	/*
  Autor: Marcus Rangel
  Processo: Solicitação de serviços de Transportes
  Objetivo: Gerar uma solicitação de contratação de serviços de frete dedicado.
  */
	For I In 1 .. P_QTDLINHAS
	Loop
	
		v_Nunota := ACT_INT_FIELD(P_IDSESSAO, I, 'NUNOTA');
		Select *
			Into c
			From tgfcab
		 Where nunota = v_Nunota;
		Select *
			Into p
			From tgfpar
		 Where codparc = c.codparc;
	
		-- verifica se movimento de compra
		If c.tipmov Not In ('O', 'C', 'E') Then
			Errmsg := 'Somente movimentações de Compras (Pedidos, Notas) podem usar essa funcionalidade.';
			Raise error;
		End If;
	
		-- verifica se possui peso informado
		If Nvl(c.peso, 0) = 0 And Nvl(c.pesobruto, 0) = 0 Then
			Errmsg := 'Para a utilização desse recurso, é necessário que o peso ou o peso bruto estejam informados.';
			Raise error;
		End If;
	
		-- verifica se é fob extra nota
		If Not Nvl(c.tipfrete, 'S') = 'N' And Nvl(c.cif_fob, 'N') = 'F' Then
			Errmsg := 'Somente lançamentos com frete FOB Extra Nota podem utilizar essa funcionanlidade';
			Raise error;
		End If;
	
		Begin
			--v_Codsolicitacao := v_Codsolicitacao + 1;
			--stp_obtemid(p_tabela => 'AD_TSFSSTC', p_proxcod => v_Codsolicitacao);
			v_Codsolicitacao := ad_get.ultcod(p_tabela => 'AD_TSFSSTC', p_codemp => 1, p_serie => '.') + 1;
		
			Update tgfnum
				 Set ultcod = v_Codsolicitacao
			 Where arquivo = 'AD_TSFSSTC'
				 And codemp = 1;
		
			-- popula observação
			V_Obs := 'Ref. Pedido de Compras nro ' || v_nunota;
			v_obs := v_obs || chr(13) || 'Fornecedor: ' || p.nomeparc || '  Telefone: ' ||
							 ad_get.formatatelefone(p.telefone);
			v_obs := v_Obs || chr(13) || ad_get.enderecocompleto('P', p.codparc, 0);
			v_obs := v_obs || chr(13) || 'Peso Total: ' || Nvl(c.peso, c.pesobruto) || ' KG';
			v_obs := v_obs || chr(13) || '**** Itens *****' || chr(13) || 'Qtde | Descrição | Peso';
		
			For c_Itens In (Select qtdneg, ad_get.descrproduto(codprod) descrprod, Nvl(i.peso, 0) peso
												From tgfite i
											 Where nunota = v_Nunota)
			Loop
				If v_itens Is Null Then
					v_itens := c_itens.qtdneg || ' | ' || c_itens.descrprod || ' | ' || c_itens.peso;
				Else
					v_itens := v_itens || chr(13) || c_itens.qtdneg || ' | ' || c_itens.descrprod || ' | ' ||
										 c_itens.peso;
				End If;
			End Loop;
		
			v_obs := v_obs || chr(13) || v_itens;
		
			-- insere solicitação
			Begin
				Insert Into ad_tsfsstc
					(codsolst,
					 codsol,
					 dhsolicit,
					 codemp,
					 codnat,
					 codcencus,
					 codproj,
					 codparc,
					 status,
					 numcontrato,
					 dhalter,
					 codusu,
					 obs,
					 nunotaorig)
				Values
					(v_codsolicitacao,
					 P_CODUSU,
					 Sysdate,
					 c.Codemp,
					 c.codnat,
					 c.codcencus,
					 c.codproj,
					 0,
					 'P',
					 c.numcontrato,
					 Sysdate,
					 P_CODUSU,
					 v_Obs,
					 v_Nunota);
			Exception
				When Others Then
					Errmsg := Sqlerrm;
					Raise error;
			End;
		
			-- insere o serviço de frete
			Begin
				v_Nussti := 0;
			
				Insert Into ad_tsfssti
					(codsolst, nussti, codserv, qtdneg, codvol, vlrunit, vlrtot)
				Values
					(v_Codsolicitacao, v_Nussti + 1, get_tsipar_inteiro('SERVFRET'), 1, 'UN', 0, 0);
			Exception
				When Others Then
					Errmsg := Sqlerrm;
					Raise error;
			End;
		
			-- executa "envio para liberação" automático
			Begin
				Insert Into execparams
					(idsessao, sequencia, nome, tipo, numint, numdec, texto, dta)
				Values
					(P_IDSESSAO, 1, 'CODSOLST', 'I', v_Codsolicitacao, Null, Null, Null);
			
				ad_stp_sst_envanalise(P_CODUSU, P_IDSESSAO, 1, errmsg);
			
				Delete From execparams
				 Where idsessao = P_IDSESSAO
					 And sequencia = 1
					 And nome = 'CODSOLST'
					 And NUMINT = v_Codsolicitacao;
			End;
		
		End;
	
	End Loop;

	P_MENSAGEM := 'Gerada a solicitação nro <a href="' ||
								ad_fnc_urlskw('AD_TSFSSTC', v_Codsolicitacao) ||
								'" target="_parent"><font color="#FF00000">' || v_Codsolicitacao || '</font></a>';

Exception
	When error Then
		Rollback;
		P_MENSAGEM := Errmsg;
	When Others Then
		Rollback;
		P_MENSAGEM := Sqlerrm;
End;
/
