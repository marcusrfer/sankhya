Create Or Replace Procedure "AD_STP_MKT_ENVAGENCIA_SF"(p_codusu Number, p_idsessao Varchar2, p_qtdlinhas Number, p_mensagem Out Varchar2) As
			p_mail Varchar2(4000);
			c      ad_tsfcmkt%Rowtype;
			s      ad_tsfsmkt%Rowtype;
			mail   Varchar2(1000);
Begin

			/* 
   * Autor: M. Rangel
   * Processo: Briefing Marketing
   * Objetivo: Enviar mail contendo briefing para mail informado no parametro.
   */

			p_mail := act_txt_param(p_idsessao, 'MAIL');

			For i In 1 .. p_qtdlinhas
			Loop
						c.nucmkt := act_int_field(p_idsessao, i, 'NUCMKT');
						Select * Into c From ad_tsfcmkt Where nucmkt = c.nucmkt;
						Select * Into s From ad_tsfsmkt k Where nusmkt = c.nusmkt;
			
						Begin
									Select ad_get.Mailusu(codusu)
											Into mail
											From ad_centparamusu
										Where nupar = 19
												And validacao = 'S';
						Exception
									When no_data_found Then
												p_mensagem := 'Não foi encontrado nenhum e-mail na Central de parametros';
									When too_many_rows Then
												Select ad_get.Mailusu(codusu)
														Into mail
														From ad_centparamusu
													Where nupar = 19
															And validacao = 'S'
															And rownum = 1;
									When Others Then
												p_mensagem := 'Erro ao buscar o mail na central de parametros - ' || Sqlerrm;
						End;
			
						--send mail   
						ad_stp_gravafilabi(p_Assunto => 'Solicitação de desenvolvimento de material - SSA',
																									p_Mensagem => s.mailtext,
																									p_Email => p_mail || ', ' || mail || ', ' || ad_get.Mailusu(p_codusu));
			
						-- send aviso
						ad_set.Ins_Avisosistema(p_Titulo => 'Solicitação Enviada à Agência',
																														p_Descricao => 'A solicitação nro. ' || s.nusmkt || ' foi enviada à agencia em ' || Sysdate,
																														p_Solucao => Null,
																														p_Usurem => p_codusu,
																														p_Usudest => s.codususol,
																														p_Prioridade => 3,
																														p_Tabela => 'TSFSMKT',
																														p_Nrounico => S.NUSMKT,
																														p_Erro => p_mensagem);
						If p_mensagem Is Not Null Then
									Return;
						End If;
			
						--insere interação
						Declare
									v_nuimkt Number;
						Begin
						
									Select Nvl(Max(nuimkt), 0) + 1 Into v_nuimkt From ad_tsfimkt Where nucmkt = c.nucmkt;
						
									Insert Into ad_tsfimkt
												(nucmkt, nuimkt, dhcontato, codusuint, contato, ocorrencia, status)
									Values
												(c.nucmkt, v_nuimkt, Sysdate, p_codusu, 'A', 'Envio para Agência', 'C');
						Exception
									When Others Then
												p_mensagem := 'Erro ao atualizar o status da Solicitação na Central. Erro: ' || Sqlerrm;
												Return;
						End;
			
						--atualiza solicitação
						Begin
									Update ad_tsfsmkt
												Set detagencia = detagencia || Chr(13) || To_Char(Sysdate, 'dd/mm/yyyy hh24:mi:ss') || ' - Envio para Agência'
										Where nusmkt = s.nusmkt;
						Exception
									When Others Then
												p_mensagem := 'Erro ao atualizar o status da Solicitação na Central. Erro: ' || Sqlerrm;
												Return;
						End;
			
			End Loop;

			p_mensagem := 'E-mail enviado corretamente para ' || p_mail || ', <br>com cópia para ' || mail;

End;
/
