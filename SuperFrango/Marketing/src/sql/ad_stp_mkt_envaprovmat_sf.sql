Create Or Replace Procedure "AD_STP_MKT_ENVAPROVMAT_SF"(P_codusu Number, P_idsessao Varchar2, P_qtdlinhas Number, P_mensagem Out Varchar2) As
			c      Ad_tsfcmkt%Rowtype;
			s      Ad_tsfsmkt%Rowtype;
			m      Tmdfmg%Rowtype;
			v_link Varchar2(400);

Begin

			/* Autor: M. Rangel
   * Processo: Solicitações Endo MKT
   * Objetivo: Registrar a conclusão do material, notificar o solicitante sobre a conclusão
               alterar status para aguardando confirmação do solicitante, registrar notificaões/ocorrências
   */

			For I In 1 .. P_qtdlinhas
			Loop
						c.Nucmkt := Act_int_field(P_idsessao, I, 'NUCMKT');
			
						Select * Into c From Ad_tsfcmkt Where Nucmkt = c.Nucmkt;
			
						Select * Into s From Ad_tsfsmkt Where Nusmkt = c.Nusmkt;
			
						If c.status = 'F' Then
									p_mensagem := 'Briefing já avaliado!';
									Return;
						End If;
			
						--Insere a ocorrência 
						ad_pkg_mkt.inserir_ocorrencia(c.Nucmkt, 'Envio para validação do solicitante.', p_mensagem);
						If p_mensagem Is Not Null Then
									Return;
						End If;
			
						-- notificações
						m.Assunto := 'Novidades sobre o Briefing nro ' || c.Nusmkt;
						m.Email   := ad_get.Mailusu(s.Codususol);
			
						v_link := Ad_fnc_urlskw('AD_TSFSMKT', s.Nusmkt, Null, Null);
			
						dbms_lob.Createtemporary(m.Mensagem, True);
						dbms_lob.Append(m.Mensagem, ad_pkg_var.html_head);
						dbms_lob.Append(m.Mensagem, '<body>');
						dbms_lob.Append(m.Mensagem, '<p>Olá ' || ad_get.Nomeusu(s.Nusmkt, 'completo') || '</p>');
						dbms_lob.Append(m.Mensagem,
																						'<p>O usuário ' || ad_get.Nomeusu(P_codusu, 'resumido') || ' atualizou o Briefing' || c.Nusmkt ||
																						', com a informação de que o mesmo já possui materiais para sua avaliação!</p><br>');
						dbms_lob.Append(m.Mensagem,
																						'<p>Por favor, verifique sua caixa de entrada em busca de e-mails' || 'do remetente ' || ad_get.Mailusu(P_codusu) ||
																						' com conteúdo relacionado ao seguinte material:</p><br>');
						dbms_lob.Append(m.Mensagem, '<quote>' || s.Especificajob || '</quote><br><br>');
						dbms_lob.Append(m.Mensagem, 'Para maiores informações, acesse o briefing clicando ');
						dbms_lob.Append(m.Mensagem, '<a href="' || v_link || '">AQUI</a>');
						dbms_lob.Append(m.Mensagem, '</body></html>');
			
						Ad_stp_gravafilabi(m.assunto, m.mensagem, m.email);
			
						ad_set.Ins_avisosistema('Atualização de Briefing',
																														'O briefing número ' || s.Nusmkt || 'foi concluído!',
																														Null,
																														P_codusu,
																														s.Codususol,
																														0,
																														'AD_TSFSMKT',
																														s.Nusmkt,
																														P_mensagem);
			
						If P_mensagem Is Not Null Then
									Return;
						End If;
			
						--atualiza o status da solicitação
						Begin
									Update Ad_tsfcmkt Set status = 'AS' Where Nucmkt = c.Nucmkt;
						Exception
									When Others Then
												P_mensagem := 'Erro ao atualizar o status do briefing. - ' || Sqlerrm;
												Return;
						End;
			
			End Loop;

			P_mensagem := 'Notificação enviada para o Solicitante avaliar o Material, envie o mesmo para o e-mail ' ||
																	Lower(ad_get.Mailusu(s.Codususol)) || '.';

End;
/
