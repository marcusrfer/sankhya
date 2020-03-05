Create Or Replace Procedure AD_STP_NOTIFLIBPEND As
	v_DiasSolicitado Int;
	v_DiasparaVencto Int;
	v_Dias           Int;
	v_NomeUsu        Varchar2(200);
	v_CodUsuLib      Int;
	v_CodUsuAuxLib2  Int;

	mail       tmdfmg%Rowtype;
	mailheader Varchar2(2000);

	htmlhead    Varchar2(400);
	htmlbottom  Varchar2(400);
	htmllinklib Varchar2(400);
	htmllinksnk Varchar2(400);

	v_CodEvento Number;

Begin

	--  Autor: Marcus Rangel
	--  Dt. Criação: 31/08/2016
	--  Dt. Alteração: 03/11/2016 - Gusttavo Lopes/ Marcus Rangel
	--  Objetivo: Atender o processo de autorização de pagamento de acerto. 
	--  Acompanhamento e notifiação de títulos pendentes de liberação 
	--  e proximos do vencimento ou limite de pagamento definido pelo financeiro

	v_Dias := get_tsipar_inteiro('DIASAVISLIBPEND');

	---Consulta se o evento possui liberação pendente para usuário especifico
	For c_Lib In (Select Lib.Codusu As Codusulib, Lib.CodUsuLibAux
									From Vgflibpend_Sf Lib
									Join AD_EVELIBNOTIF Eve
										On Lib.Evento = Eve.Evento
								 Where --Evento In (1001, 1010, 1011, 1012, 1013, 1014, 1015)   
								 Lib.Diassolicitado > 0
						 And Lib.Diasparavencto <= Nvl(Eve.Diasavislibpend, v_Dias)
								 Group By Lib.Codusu, Lib.CodUsuLibAux
								 Order By Lib.Codusu, Lib.CodUsuLibAux)
	Loop
		v_CodUsuLib   := c_Lib.Codusulib;
		v_NomeUsu     := ad_get.nomeUsu(v_CodUsuLib, 'resumido');
		mail.email    := ad_get.mailUsu(v_CodUsuLib);
		mail.mensagem := '';
		dbms_output.put_line(mail.mensagem);
	
		If Nvl(c_Lib.CodUsuLibAux, 0) > 0 Then
			mail.email := mail.email || ',' || ad_get.mailUsu(c_Lib.CodUsuLibAux);
		
			---Foi adicionado outro liberador auxiliar quando o usuário liberador for a Caroline
			----Outro usuário Auxiliar - Marcel
			If Nvl(c_Lib.CodUsuLibAux, 0) = 761 Then
				v_CodUsuAuxLib2 := 626;
				mail.email      := mail.email || ',' || ad_get.mailUsu(v_CodUsuAuxLib2);
			End If;
		End If;
	
		mailheader := 'Cód.Lib: ' || v_CodUsuLib || ' - ' || v_NomeUsu ||
									', favor verificar o quanto antes as liberações que ainda constam como pendentes.' ||
									chr(13) || 'Obrigado.' || chr(13) || chr(13) || chr(10);
	
		htmlhead := '<table border = 1>' || chr(13) || '<tr>' || chr(13) || ' <td>Nº Solicit. </td>' ||
								chr(13) || ' <td>Evento </td>' || chr(13) || ' <td>Descr. Evento </td>' || chr(13) ||
								' <td>Qtd. Solicitações</td>' || chr(13) || ' <td>Dt. Solicitação</td>' || chr(13) ||
								' <td>Dias Atraso</td>' || chr(13) || ' <td>Dt. Vencto</td>' || chr(13) ||
								' <td>Dias Vencto</td>' || chr(13) || '</tr>';
	
		For Pendente In (Select Count(*) As Contador,
														L.Evento,
														L.DescrEvento,
														L.Dhsolicit,
														L.Dthoje,
														L.Dtvenc,
														L.NUSOLCPA
											 From Vgflibpend_Sf L
											 Join AD_EVELIBNOTIF Eve
												 On L.Evento = Eve.Evento
											Where L.Codusu = v_CodUsuLib
													 --And Evento In (1001, 1010, 1011, 1012, 1013, 1014, 1015)
												And L.Diassolicitado > 0
												And L.Diasparavencto <= Nvl(Eve.Diasavislibpend, v_Dias)
											Group By L.Evento, L.DescrEvento, L.Dhsolicit, L.Dthoje, L.Dtvenc, L.NUSOLCPA)
		Loop
			v_CodEvento      := pendente.Evento;
			v_DiasSolicitado := pendente.Dthoje - pendente.Dhsolicit;
			v_DiasparaVencto := pendente.Dtvenc - pendente.Dthoje;
		
			mail.mensagem := mail.mensagem || chr(13) || '<tr align="center">' || chr(13) || '<td>' ||
											 Pendente.NUSOLCPA || '</td>' || '<td>' || v_CodEvento || '</td>' || chr(13) ||
											 '<td>' || pendente.DescrEvento || '</td>' || chr(13) || '<td>' ||
											 pendente.Contador || '</td>' || chr(13) || '<td>' || pendente.Dhsolicit ||
											 '</td>' || chr(13) || '<td>' || v_DiasSolicitado || '</td>' || chr(13) ||
											 '<td>' || pendente.Dtvenc || '</td>' || chr(13) || '<td><font color=red>' ||
											 v_DiasparaVencto || '</font></td>' || chr(13) || '</tr>';
		End Loop;
	
		htmlbottom := chr(13) || '</table>';
	
		htmllinklib := chr(13) || '<p><a href="' || ad_fnc_urlskw('TSIDSB', '97') ||
									 '" target="_blank"> Clicar aqui para liberar </a></p>';
	
		htmllinksnk := chr(13) ||
									 '<p><a href="http://www.sankhya.com.br" target="_blank"><img src="http://www.sankhya.com.br/imagens/logo-sankhya-rodape.png" widht="141" height="32" ></img></a></p>';
	
		mail.mensagem := mailheader || htmlhead || mail.mensagem || htmlbottom || htmllinklib ||
										 htmllinksnk;
		dbms_output.put_line(mail.mensagem);
	
		mail.assunto := 'Agendador - Liberações pendentes!!!';
		ad_stp_gravafilabi(mail.assunto, mail.mensagem, mail.email);
		mail := Null;
	End Loop;

End;
/
