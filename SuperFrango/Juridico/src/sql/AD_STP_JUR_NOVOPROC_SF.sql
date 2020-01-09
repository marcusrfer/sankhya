Create Or Replace Procedure "AD_STP_JUR_NOVOPROC_SF"(p_codusu Number, p_idsessao Varchar2, p_qtdlinhas Number,
																										 p_mensagem Out Varchar2) As
	p_numprocesso Varchar2(4000);
	p_reclamante  Varchar2(4000);
	v_nujurmbc    Number;
	jc            ad_jurcab%Rowtype;
	ji            ad_jurite%Rowtype;
Begin
	/* Autor: M. Rangel 
  * Processo: Bloqueio jurídico
  * Objetivo: Permitir que o financeiro realize o cadastro do processo.
  */
	p_numprocesso := act_txt_param(p_idsessao, 'NUMPROCESSO');
	p_reclamante  := act_txt_param(p_idsessao, 'RECLAMANTE');
	ji.seq        := 0;

	For i In 1 .. p_qtdlinhas
	Loop
	
		v_nujurmbc := act_int_field(p_idsessao, i, 'NUJURMBC');
	
		-- tratativa para o número do processo
		p_numprocesso := Substr(Lpad(Replace(Replace(Ltrim(Rtrim(Regexp_Replace(p_numprocesso, '[^0-9]+', Null))), '-', ''), '/', ''),
																 20,
																 '0'),
														1,
														20);
	
		-- insere o processo
		Begin
			stp_keygen_tgfnum('AD_JURCAB', 1, 'AD_JURCAB', 'NUPASTA', 0, jc.nupasta);
		
			Insert Into ad_jurcab
				(nupasta, reclamante, dhinclusao, codusuinc)
			Values
				(jc.nupasta, p_reclamante, Sysdate, p_codusu);
		Exception
			When Others Then
				p_mensagem := 'Não foi possível inserir o processo.' || Chr(13) || 'Motivo: ' || Sqlerrm;
				Return;
		End;
	
		-- insere os detalhes do processo
		Begin
			ji.seq := ji.seq + 1;
		
			Insert Into ad_jurite
				(situacao, seq, adto, nupasta, tipo, codemp, codparc, codcencus, codnat, forma, valor, dtvenc, numprocesso, dhinclusao,
				 codusuinc, codproj, obsjur, numdoc, status, reembfeito, libreembolso)
			Values
				('E', ji.seq, 'S', jc.nupasta, 'BJ', 1, 0, 0, 0, 'Q', 0, Null, p_numprocesso, Sysdate, p_codusu, 0,
				 'Lançamento gerado pelo financeiro, necessita complemento', Null, 'P', 'N', 'N');
		Exception
			When Others Then
				p_mensagem := 'Não foi possível inserir o processo.' || Chr(13) || 'Motivo: ' || Sqlerrm;
				Return;
		End;
	
		If p_idsessao = 'debug' Then
			p_mensagem := 'ok';
			Return;
		End If;
	
		-- notificação (aviso e e-mail)
		For r_usu In (
									
									Select u.codusu, u.nomeusu, u.nomeusucplt, u.email
										From tsiusu u
										Join tsigru g
											On u.codgrupo = g.codgrupo
									 Where g.codgrupo = (Select codgrupo
																				 From tsiusu u2
																				 Join ad_jurparam p
																					 On p.codusulib = u2.codusu
																				Where p.nujurpar = 1)
									
									)
		Loop
			-- envia aviso
			ad_set.Ins_Avisosistema(p_Titulo     => 'Novo processo cadastrado',
															p_Descricao  => 'Um novo processo foi cadastrado pelo financeiro',
															p_Solucao    => 'Necessário concluir o cadastro',
															p_Usurem     => p_codusu,
															p_Usudest    => r_usu.codusu,
															p_Prioridade => 0,
															p_Tabela     => 'AD_JURCAB',
															p_Nrounico   => jc.nupasta,
															p_Erro       => p_mensagem);
		
			If p_mensagem Is Not Null Then
				Return;
			End If;
		
			-- envia e-mail
			ad_stp_gravafilabi(p_Assunto  => 'Novo processo cadastrado',
												 p_Mensagem => 'Um novo processo foi cadastrado pelo financeiro.' || Chr(13) ||
																			 'Necessário concluir o cadastro',
												 p_Email    => r_usu.email);
		End Loop;
	
	End Loop;

	p_mensagem := 'Processo ' || ad_pkg_jur.fmt_numprocesso(p_NumProcesso) || ' cadastrado com sucesso!!!';

End;
/
