Create Or Replace Procedure "AD_STP_SST_ENVANALISE"(P_CODUSU    Number,
																										P_IDSESSAO  Varchar2,
																										P_QTDLINHAS Number,
																										P_MENSAGEM  Out Varchar2) As
	v_QtdServ     Int := 0;
	v_QtdMaq      Int := 0;
	r_sol         ad_tsfsstc%Rowtype;
	listaUsuarios Varchar2(4000);
	v_mailUsu     Varchar2(100);
	r_mail        tmdfmg%Rowtype;
	v_NomeEmpresa Varchar2(1000);
	v_NomeUsuario Varchar2(100);
	errMsg        Varchar2(4000);
	Error Exception;
Begin
	/*************************************************************************
  * Autor: Marcus Rangel
  * Processo: Solicita��o de Servi�os de Transporte
  * Objetivo: Procedimento de envio da solicita��o para analise da area de transportes
  * Ponte para estabelecer comunica��o entre solicitante e responsavel
  *************************************************************************/
	For I In 1 .. P_QTDLINHAS
	Loop
		r_sol.Codsolst := ACT_INT_FIELD(P_IDSESSAO, I, 'CODSOLST');
	
		Select *
			Into r_sol
			From AD_TSFSSTC c
		 Where c.codsolst = r_sol.codsolst;
	
		Select Count(*)
			Into v_QtdServ
			From ad_tsfssti i
		 Where i.codsolst = r_sol.codsolst;
		Select Count(*)
			Into v_QtdMaq
			From ad_tsfsstm m
		 Where m.codsolst = r_sol.codsolst;
	
		If v_QtdServ = 0 Then
			errMsg := 'Solicita��es sem servi�os n�o podem ser confirmadas.';
			Raise error;
		End If;
	
		/*    
    If v_QtdMaq = 0 Then
      errMsg := 'Solicita��es sem m�quinas ou equipamentos n�o podem ser confirmadas.';
    End If;*/
	
		/* If r_sol.status <> 'P' Then
      errMsg := 'Solicita��o j� se encontra ' || ad_get.opcoescampo(r_sol.status, 'STATUS', 'AD_TSFSSTC');
      Raise error;
    End If;
    
    If errMsg Is Not Null Then
      Raise error;
    End If;*/
	
		-- valida status da solicitacao
		If r_sol.status <> 'P' Then
			errmsg := 'O lan�amento se encontra <b>' ||
								ad_get.opcoesCampo(r_sol.status, 'STATUS', 'AD_TSFSSTC') || '</b>.' || chr(13) ||
								'Somente lan�amentos <font color = "#FF0000">Pendentes</font> podem ser enviados para Analise.';
			Raise error;
		End If;
	
		Select e.nomefantasia
			Into v_NomeEmpresa
			From tsiemp e
		 Where e.codemp = r_sol.codemp;
		v_NomeUsuario := ad_get.nomeUsu(r_sol.codsol, 'completo');
	
		-- atualiza o status do lan�amento  
		Begin
			Update ad_tsfsstc c
				 Set c.status = 'A'
			 Where c.codsolst = r_sol.codsolst;
		Exception
			When Others Then
				errmsg := 'Ocorreu um erro ao atualizar o status da solicita��o. - ' || Sqlerrm;
				Raise error;
		End;
	
		-- busca lista de usu�rios
		listaUsuarios := get_tsipar_texto('USURESPSERVTRP');
	
		-- percorre o parametro para buscar os emails dos usuarios informados
		For cl In (Select regexp_substr(listaUsuarios, '[^,]+', 1, Level) codusu
								 From dual
							 Connect By regexp_substr(listaUsuarios, '[^,]+', 1, Level) Is Not Null)
		Loop
			Select Nvl(u.emailsollib, u.email)
				Into v_mailUsu
				From tsiusu u
			 Where u.codusu = To_Number(cl.codusu);
			If v_mailUsu Is Null Then
				Continue;
			End If;
		
			If r_mail.email Is Null Then
				r_mail.email := v_mailUsu;
			Else
				r_mail.email := r_mail.email || ',' || v_mailUsu;
			End If;
		
		End Loop;
	
		-- SEND MAIL
		Begin
			r_mail.assunto  := 'Nova solicita��o de servi�os de transportes.';
			r_mail.mensagem := '<BODY>' ||
												 '<P><FONT STYLE="font-size: 14px; font-family: arial; ">Aten��o!</FONT></P><P><BR/></P>' ||
												 '<p><FONT STYLE="font-size: 14px; font-family: arial; ">Uma nova solicita��o de compras de servi�os de transportes foi inserida.</FONT></P>' ||
												 '<br><br>' ||
												 '<p><FONT STYLE="font-size: 14px; font-family: arial; "><U>Detalhes:</U></FONT></P><P><BR/></P>' ||
												 '<p><FONT STYLE="font-size: 14px; font-family: arial; "><B>Nro Solicita��o: </B>' ||
												 r_sol.codsolst || '.</FONT></P>' ||
												 '<p><FONT STYLE="font-size: 14px; font-family: arial; "><B>Empresa:</B> ' ||
												 v_NomeEmpresa || '.</FONT></P>' ||
												 '<p><FONT STYLE="font-size: 14px; font-family: arial; "><B>Solicitante:</B> ' ||
												 v_NomeUsuario || '.</FONT></P>' ||
												 '<p><FONT STYLE="font-size: 14px; font-family: arial; "><B>Observa��es: </B>' ||
												 r_sol.obs || '.</FONT></P><P><BR/></P>' ||
												 '<p><FONT STYLE="font-size: 14px; font-family: arial; ">Para mais detalhes clique <A HREF="' ||
												 ad_fnc_urlskw('AD_TSFSSTC', r_sol.codsolst) ||
												 '" TARGET="_blank">aqui</A>.</FONT></P>' || '<P><BR/></P>' ||
												 '<P><BR/></P>' || '</BODY>';
		
			ad_stp_gravafilabi(r_mail.assunto, r_mail.mensagem, r_mail.email);
		End;
	
		-- envia mensagem no sistema
		Begin
			ad_set.Ins_Avisosistema(p_Titulo     => 'Nova solicita��o de Servi�o',
															p_Descricao  => 'Uma nova solicita��o de servi�os de transportes foi cadastrada por ' ||
																							ad_get.nomeUsu(r_sol.codsol, 'resumido') ||
																							' com previs�o de inicio de uso em ' || r_sol.dtinicio ||
																							' , e requer sua aten��o',
															p_Solucao    => 'Verifique do que se trata e posicione  o solicitante.',
															p_prioridade => 2,
															p_Usurem     => r_sol.codsol,
															p_Usudest    => r_sol.codusu,
															p_Tabela     => 'AD_TSFSSTC',
															p_Nrounico   => r_sol.codsolst,
															p_Erro       => errMsg);
		End;
	End Loop;
	P_MENSAGEM := 'Solicita��o enviada para an�lise com sucesso!!!';
Exception
	When error Then
		P_MENSAGEM := '<font style="color:#FF0000;font-size:14px;"><b>Aten��o!</b></font><br>' ||
									errMsg;
	When Others Then
		p_mensagem := Sqlerrm;
End;
/
