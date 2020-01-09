Create Or Replace Procedure "AD_STP_JUR_TRASFVLR_SF"(p_codusu Number, p_idsessao Varchar2, p_qtdlinhas Number,
																										 p_mensagem Out Varchar2) As
	p_tipooper     Varchar2(4000);
	p_DtLanc       Date;
	v_nujurmbc     Number;
	v_nujurmbctr   Number;
	realizados     Int := 0;
	nao_realizados Int := 0;
	bloq           ad_jurmbctr%Rowtype;
	jur            ad_jurite%Rowtype;
	v_TopTransf    Number;
	v_CtaOrig      Number;
	v_CtaDest      Number;
	v_Numtransf    Number;
	v_Numdoc       Number;
	v_Historico    tgfmbc.historico%Type;
	v_Nufin        Number;
Begin

	/*
  * Autor: M. Rangel
  * Processo: Bloqueio Judicial em lotes
  * Objetivo: Realizar as transferência tanto dos bloqueios quanto dos retornos
  */
	ad_pkg_jur.processo_juridico := True;

	p_tipooper := act_txt_param(p_idsessao, 'TIPOOPER');
	p_Dtlanc   := act_dta_param(p_idsessao, 'DTLANC');

	Select codtoptransf
		Into v_toptransf
		From ad_jurparam
	 Where nujurpar = 1;

	For i In 1 .. p_qtdlinhas
	Loop
	
		v_nujurmbc   := act_int_field(p_idsessao, i, 'NUJURMBC');
		v_nujurmbctr := act_int_field(p_idsessao, i, 'NUJURMBCTR');
	
		If v_nujurmbc Is Null Then
			p_mensagem := 'Nenhum registro selecionado!';
			Return;
		End If;
	
		If p_idsessao = 'debug' Then
			p_tipooper   := 'R';
			v_nujurmbc   := 6;
			v_nujurmbctr := 3;
		End If;
	
		-- busca os dados do lançamento selecionado
		Begin
			Select *
				Into bloq
				From ad_jurmbctr
			 Where nujurmbc = v_nujurmbc
				 And nujurmbctr = v_nujurmbctr;
		Exception
			When no_data_found Then
				p_mensagem := 'Não foi possível encontrar os dados da transferência. (' || v_nujurmbc || ',' || v_nujurmbctr || ')';
				Return;
		End;
	
		-- busca a conta contrapartida informada no cadastro da conta judicial
		Begin
			Select ad_codctabcocp
				Into v_ctadest
				From tsicta
			 Where codctabcoint = bloq.codcta;
		Exception
			When no_data_found Then
				Select ad_codctabcocp
					Into v_CtaDest
					From tsicta
				 Where codctabcoint = bloq.codcta;
		End;
	
		-- valida conta destino
		If v_CtaDest Is Null Then
			p_mensagem := 'Verifique o cadastro de contas, se a conta contrapartida (bancária) está informada.';
			Return;
		End If;
	
		-- se Bloqueio
		If Nvl(p_tipooper, 'N') = 'T' Then
		
			-- se já possui número de transferência, pula para o próximo
			If bloq.numtransf Is Not Null Then
				If p_qtdlinhas > 1 Then
					nao_realizados := nao_realizados + 1;
					Continue;
				Else
					p_mensagem := 'Operação de transferência já realizada.';
					Return;
				End If;
			End If;
		
			v_CtaOrig   := bloq.codcta;
			v_Historico := 'BLOQUEIO JUDICIAL';
		
			-- se Desbloqueio
			-- se possuir nro do processo, não devolve
		Elsif Nvl(p_tipooper, 'N') = 'R' Then
		
			-- busca os dados do processo
		
			If bloq.codproc Is Not Null Then
				-- se nr processo informado, não processa
			
				If p_qtdlinhas > 1 Then
					nao_realizados := nao_realizados + 1;
					Continue;
				Else
					p_mensagem := 'Impossível realizar desbloqueio de lançamento com nro do processo informado.<br>' ||
												'As operações de reembolso devem ser realizadas pela tela de Despesas jurídicas.';
					Return;
				End If;
			
			End If;
		
			-- se não foi feito bloqueio e tem mais de um selecionado
			If bloq.numtransf Is Null Then
				If p_qtdlinhas > 1 Then
					nao_realizados := nao_realizados + 1;
					Continue;
				Else
					p_mensagem := 'Não foi realizada a operação de bloqueio.';
					Return;
				End If;
			End If;
		
			-- se já foi feito o desbloqueio e tem mais de um selecionado
			If bloq.dtret Is Not Null Then
				If p_qtdlinhas > 1 Then
					nao_realizados := nao_realizados + 1;
					Continue;
				Else
					p_mensagem := ad_fnc_formataerro('Reembolso já realizado no dia ' || To_Char(bloq.dtret, 'dd/mm/yyyy') ||
																					 ' pelo usuário ' || ad_get.nomeusu(bloq.codusuret, 'resumido') || '.');
				
					If act_escolher_simnao('Geração de Adiantamento Jurídico', p_mensagem, p_idsessao, 1) = 'N' Then
						Return;
					End If;
				
				End If;
			
			End If;
		
			/*      If jur.numprocesso Is Null Then
        Continue;
      End If;*/
		
			v_CtaOrig   := v_CtaDest;
			v_CtaDest   := bloq.codcta;
			v_Historico := 'DESBLOQUEIO JUDICIAL';
		
		End If;
	
		v_Numdoc := Replace(To_Char(p_Dtlanc, 'dd/mm/yyyy'), '/', '');
	
		ad_pkg_jur.realiza_transf_mbc(p_top        => v_toptransf,
																	p_dtlanc     => p_Dtlanc,
																	p_predata    => p_Dtlanc,
																	p_ctaorig    => v_CtaDest,
																	p_ctadestino => v_CtaOrig,
																	p_numdoc     => v_Numdoc,
																	p_valor      => bloq.vlrtransf,
																	p_historico  => v_Historico,
																	p_numtransf  => v_Numtransf);
	
		If bloq.codproc Is Not Null Then
		
			Begin
				Select i.nufin
					Into v_nufin
					From ad_jurite i
				 Where i.nupasta = jur.nupasta
					 And i.seq = jur.seq;
			Exception
				When Others Then
					If p_qtdlinhas > 1 Then
						nao_realizados := nao_realizados + 1;
						Continue;
					Else
						p_mensagem := 'Erro ao buscar informações do processo. ' || Sqlerrm;
						Return;
					End If;
			End;
		
			Begin
				Update tgfmbc m
					 Set m.ad_nufinproc = v_nufin
				 Where m.numtransf = v_Numtransf;
			Exception
				When Others Then
					If p_qtdlinhas > 1 Then
						nao_realizados := nao_realizados + 1;
					Else
						p_mensagem := 'Erro ao atualizar a movimentação bancária. ' || Sqlerrm;
						Return;
					End If;
			End;
		
			Begin
				ad_pkg_jur.grava_log_transf_bancaria(jur.nupasta, jur.seq, v_numtransf);
			Exception
				When Others Then
					If p_qtdlinhas > 1 Then
						nao_realizados := nao_realizados + 1;
					Else
						p_mensagem := 'Erro ao atualizar a aba lançamentos da despesa jurídica. ' || Sqlerrm;
						Return;
					End If;
			End;
		
		End If;
	
		Begin
			Update ad_jurmbctr t
				 Set t.numtransf = Case
															When p_tipooper = 'T' Then
															 v_Numtransf
															Else
															 Null
														End,
						 t.codusutransf = Case
																 When p_tipooper = 'T' Then
																	p_codusu
																 Else
																	Null
															 End,
						 t.dttransf = Case
														 When p_tipooper = 'T' Then
															Sysdate
														 Else
															Null
													 End,
						 t.numtransfret = Case
																 When p_tipooper = 'R' Then
																	v_Numtransf
																 Else
																	Null
															 End,
						 
						 t.codusuret = Case
															When p_tipooper = 'R' Then
															 p_codusu
															Else
															 Null
														End,
						 t.dtret = Case
													When p_tipooper = 'R' Then
													 Sysdate
													Else
													 Null
												End
			 Where nujurmbc = v_nujurmbc
				 And nujurmbctr = v_nujurmbctr;
		Exception
			When Others Then
				If p_qtdlinhas > 1 Then
					nao_realizados := nao_realizados + 1;
				Else
					p_mensagem := 'Erro ao atualizar informações no lançamento selecionado. ' || Sqlerrm;
					Return;
				End If;
		End;
		realizados := realizados + 1;
	
	End Loop;

	If p_qtdlinhas > 1 Then
		p_mensagem := realizados || ' Operações realizadas com sucesso!!!';
		If nao_realizados > 0 Then
			p_mensagem := p_mensagem || Chr(13) || nao_realizados || ' Operações não realizadas!!!';
		End If;
	Else
		p_mensagem := 'Operação realizada com sucesso!';
	End If;

End;
/
