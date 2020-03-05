Create Or Replace Procedure "AD_STP_SST_CONFSOLST"(P_CODUSU    Number,
																							 P_IDSESSAO  Varchar2,
																							 P_QTDLINHAS Number,
																							 P_MENSAGEM  Out Varchar2) As
	v_codSolicit  Number;
	r_Sol         ad_tsfsstc%Rowtype;
	v_QtdServ     Int := 0;
	v_QtdMaq      Int := 0;
	listaUsuarios Varchar2(4000);
	v_mailUsu     Varchar2(100);
	r_mail        tmdfmg%Rowtype;
	v_NomeEmpresa Varchar2(1000);
	v_NomeUsuario Varchar2(100);
	v_MsgServicos Clob;
	error Exception;
	errmsg Varchar2(1000);
Begin
	/***************************************************************************************
  * Autor: Marcus Rangel
  * Objetivo: Cnfirmar a solicita��o de servi�os de transporte e loca��o de 
  * maquinas e equipamentos, alterar o status da solicita��o e notificar o respons�vel.
  ****************************************************************************************/
	For I In 1 .. P_QTDLINHAS
	Loop
		v_codSolicit := ACT_INT_FIELD(P_IDSESSAO, I, 'CODSOLST');
	
		Select * Into r_sol From AD_TSFSSTC c Where c.codsolst = v_codSolicit;
	
		-- valida se possui servi�os e/ou m�quinas
		Select Count(*) Into v_QtdServ From ad_tsfssti i Where i.codsolst = r_sol.codsolst;
		Select Count(*) Into v_QtdMaq From ad_tsfsstm m Where m.codsolst = r_sol.codsolst;
	
		If v_QtdServ = 0 Then
			errMsg := 'Solicita��es sem servi�os n�o podem ser confirmadas.';
			/*    Elsif v_QtdMaq = 0 Then
      errMsg := 'Solicita��es sem m�quinas ou equipamentos n�o podem ser confirmadas.';*/
		End If;
	
		If errMsg Is Not Null Then
			Raise error;
		End If;
	
		-- valida��o do status da solicita��o
		If r_sol.status <> 'A' Then
			errmsg := 'O lan�amento se encontra <b>' ||
								ad_get.opcoesCampo(r_sol.status, 'STATUS', 'AD_TSFSSTC') || '</b>.' || chr(13) ||
								'Somente lan�amentos <font color = "#FF0000">Em An�lise</font> podem ser confirmados.';
			Raise error;
		End If;
	
		-- valida��o do parceiro
		/*  If r_sol.codparc Is Null Or r_sol.codparc = 0 Then
     errmsg := 'Necess�rio informar o parceiro que prestar� o servi�o antes de confirmar a solicita��o.';
     Raise error;
    End If;*/
	
		-- valida valor dos servi�os
		For c_Serv In (Select i.nussti, i.codserv, i.vlrtot, p.descrprod, i.codparc, a.nomeparc
										 From ad_tsfssti i
										 Join tgfpro p
											 On i.codserv = p.codprod
										 Left Join tgfpar a
											 On i.codparc = a.codparc
										Where i.codsolst = r_sol.codsolst)
		Loop
		
			If v_MsgServicos Is Null Then
				v_MsgServicos := 'Servi�o: ' || c_serv.codserv || ' - ' || c_Serv.Descrprod || '( Parc.: ' ||
												 c_serv.codparc || ' - ' || c_serv.nomeparc || ')';
			Else
				v_MsgServicos := v_MsgServicos || chr(13) || 'Servi�o: ' || c_serv.codserv || ' - ' ||
												 c_Serv.Descrprod || '( Parc.: ' || c_serv.codparc || ' - ' ||
												 c_serv.nomeparc || ')';
			End If;
		
			If c_Serv.vlrtot <> 0 Then
				For c_Maq In (Select m.codmaq, e.descrmaq, m.vlrtot, m.codparc, p.nomeparc
												From ad_tsfsstm m
												Join ad_tsfcme e
													On m.codmaq = e.codmaq
												Left Join tgfpar p
													On m.codparc = p.codparc
											 Where m.codsolst = r_sol.codsolst
												 And m.nussti = c_Serv.Nussti
											--And m.codserv = c_Serv.Codserv
											)
				Loop
				
					v_MsgServicos := v_MsgServicos || chr(13) || '     M�q/Equip/Ve�culo: ' || c_maq.descrmaq ||
													 ' (Parc.: ' || c_maq.codparc || ' - ' || c_maq.nomeparc || ')';
				
					If c_Maq.Vlrtot <> 0 Then
						Continue;
					Else
						errmsg := 'Para confirma��o, se faz necess�rio que todas as m�quinas possuam pre�o.';
						Raise error;
					End If;
				
				End Loop;
			
			Else
				errmsg := 'Para confirma��o, se faz necess�rio que todos os servi�os possuam  pre�o.';
				Raise error;
			End If;
		
		End Loop;
	
		Select e.nomefantasia Into v_NomeEmpresa From tsiemp e Where e.codemp = r_sol.codemp;
	
		v_NomeUsuario := ad_get.nomeUsu(r_sol.codsol, 'completo');
	
		Update ad_tsfsstc c Set c.status = 'L' Where c.codsolst = v_codSolicit;
	
		listaUsuarios := get_tsipar_texto('USURESPSERVTRP');
	
		For c_lista In (Select regexp_substr(listaUsuarios, '[^,]+', 1, Level) codusu
											From dual
										Connect By regexp_substr(listaUsuarios, '[^,]+', 1, Level) Is Not Null)
		Loop
			Select Nvl(u.emailsollib, u.email)
				Into v_mailUsu
				From tsiusu u
			 Where u.codusu = To_Number(c_lista.codusu);
		
			If v_mailUsu Is Null Then
				Continue;
			End If;
		
			If r_mail.email Is Null Then
				r_mail.email := v_mailUsu;
			Else
				r_mail.email := r_mail.email || ',' || v_mailUsu;
			End If;
		
		End Loop;
	
		Begin
			r_mail.assunto  := 'Confirma��o de solicita��o de servi�os de transportes.';
			r_mail.mensagem := '<BODY>' || '<P>' ||
												 '<FONT STYLE="font-size: 14px; font-family: arial; ">Aten��o!</FONT></P><P><BR/></P><P>' ||
												 '<FONT STYLE="font-size: 14px; font-family: arial; ">A solicita��o de servi�os de transportes foi confirmada.</FONT></P><P><BR/></P><P>' ||
												 '<FONT STYLE="font-size: 14px; font-family: arial; "><U>Detalhes:</U></FONT></P><P><BR/></P><P>' ||
												 '<FONT STYLE="font-size: 14px; font-family: arial; "><B>Nro Solicita��o: </B>' ||
												 r_sol.codsolst || '.</FONT></P><P>' ||
												 '<FONT STYLE="font-size: 14px; font-family: arial; "><B>Empresa: </B>' ||
												 v_NomeEmpresa || '.</FONT></P><P>' ||
												 '<FONT STYLE="font-size: 14px; font-family: arial; "><B>Solicitante: </B> ' ||
												 v_NomeUsuario || '.</FONT></P><P>' ||
												 '<FONT STYLE="font-size: 14px; font-family: arial; "><B>Servi�os: </B> ' ||
												 v_MsgServicos || '.</FONT></P><P>' ||
												 '<FONT STYLE="font-size: 14px; font-family: arial; "><B>Observa��es: </B>' ||
												 r_sol.obs || '.</FONT></P><P><BR/></P><P>' ||
												 '<FONT STYLE="font-size: 14px; font-family: arial; ">Para mais detalhes clique <A HREF="' ||
												 ad_fnc_urlskw('AD_TSFSSTC', r_sol.codsolst) ||
												 '" TARGET="_blank">aqui</A>.</FONT></P>' || '<P><BR/></P>' ||
												 '<P><BR/></P>' || '</BODY>';
		
			ad_stp_gravafilabi(r_mail.assunto, r_mail.mensagem, r_mail.email);
		End;
	
		-- envia mensagem no sistema
		Begin
			ad_set.Ins_Avisosistema(p_Titulo => 'Confirma��o de solicita��o de Servi�o',
															p_Descricao => 'Solicita��o de servi�os de transportes confirmada por ' ||
																							ad_get.nomeUsu(stp_get_codusulogado, 'resumido') || '.',
															p_Solucao => 'Para maiores informa��es, verifique o registro..',
															p_prioridade => 2, p_Usurem => stp_get_codusulogado,
															p_Usudest => r_sol.codsol, p_Tabela => 'AD_TSFSSTC',
															p_Nrounico => r_sol.codsolst, p_Erro => errMsg);
		End;
	
	End Loop;

	P_MENSAGEM := 'Confirma��o conclu�da com sucesso!';

Exception
	When error Then
		p_mensagem := '<font color="#FF0000" sizee="14px"><b>Aten��o!</b></font><br>' || errmsg;
	When Others Then
		p_mensagem := 'Algo deu errado! ' || Sqlerrm;
End;
/
