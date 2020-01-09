--------------------------------------------------------
--  DDL for Procedure AD_STP_MKT_APROVASOL_SF
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "SANKHYA"."AD_STP_MKT_APROVASOL_SF" (p_codusu Number, p_idsessao Varchar2, p_qtdlinhas Number, p_mensagem Out Varchar2) As
			/* 
   * Dt. Cria��o:  26/03/2019
   * Autor: M. Rangel
   * Processo: Solicita��es de Materiais de Marketing
   * Objetivo: Marcar a solicita��o como aprovada, distribuir a informa��o
   */

			c   ad_tsfcmkt%Rowtype;
			s   ad_tsfsmkt%Rowtype;
			msg Clob;
Begin
			For i In 1 .. p_qtdlinhas
			Loop
						c.nucmkt := act_int_field(p_idsessao, i, 'NUCMKT');
						Select * Into c From ad_tsfcmkt where nucmkt = c.nucmkt;
						Select * Into s From ad_tsfsmkt Where nusmkt = c.nusmkt;
			
						If c.status = 'F' Then
									p_mensagem := 'Solicita��o entregue, n�o h� necessidade de nova aprova��o.';
									Return;
						End If;
			
						--atualiza registro na central
						Begin
									Update ad_tsfcmkt k Set k.codusuaprov = p_codusu, k.dhaprov = Sysdate, k.status = 'A' Where nucmkt = c.nucmkt;
						Exception
									When Others Then
												p_mensagem := 'Erro ao atualizar solicita��o! ' || Sqlerrm;
												Return;
						End;
			
						--atualiza solicita��o
						Begin
									Update ad_tsfsmkt k
												Set k.codaprov = p_codusu,
																k.dhaprov = Sysdate,
																k.detagencia = k.detagencia || Chr(13) || To_Char(Sysdate, 'dd/mm/yyyy hh24:mi:ss') || ' - ' ||
																															'Aprova��o da Briefing pelo Marketing'
										Where k.nusmkt = c.nusmkt;
						Exception
									When Others Then
												p_mensagem := 'Erro ao atualizar solicita��o! ' || Sqlerrm;
												Return;
						End;
			
						--insere intera��o
						Declare
									v_nuimkt Number;
						Begin
						
									Select Nvl(Max(nuimkt), 0) + 1 Into v_nuimkt From ad_tsfimkt Where nucmkt = c.nucmkt;
						
									Insert Into ad_tsfimkt
												(nucmkt, nuimkt, dhcontato, codusuint, contato, ocorrencia, status)
									Values
												(c.nucmkt, v_nuimkt, Sysdate, p_codusu, 'S', 'Aprova��o do Briefing', 'C');
						Exception
									When Others Then
												p_mensagem := 'Erro ao atualizar o status da Solicita��o na Central. Erro: ' || Sqlerrm;
												Return;
						End;
			
						--notifica solicitante
						Begin
									ad_set.Ins_Avisosistema(p_Titulo => 'Solicita��o de MKT (briefing) aprovada',
																																	p_Descricao => 'A solicita��o ' || c.nusmkt || ' acaba de ser aprovada por ' ||
																																																ad_get.Nomeusu(p_codusu, 'resumido'),
																																	p_Solucao => 'Aguarde maiores atualiza��es sobre o andamento da mesma.',
																																	p_Usurem => p_codusu,
																																	p_Usudest => s.codususol,
																																	p_Prioridade => 3,
																																	p_Tabela => 'AD_TSFSMKT',
																																	p_Nrounico => s.nusmkt,
																																	p_Erro => p_mensagem);
						
									If p_mensagem Is Not Null Then
												Return;
									End If;
						
						End;
			
						--send mail solicitante
						Begin
									msg := Null;
									dbms_lob.createtemporary(msg, True);
									dbms_lob.append(msg, '<!DOCTYPE html>');
									dbms_lob.append(msg, '<head><meta meta http-equiv="content-language" content="pt-br">');
									dbms_lob.append(msg, '<meta http-equiv="content-type" content="text/html; charset=iso-8859-1"></head>');
									dbms_lob.append(msg, '<body>');
									dbms_lob.append(msg, 'Ol�, ' || ad_get.Nomeusu(s.codususol, 'completo') || '<br>');
									dbms_lob.append(msg, 'O Briefing ' || s.nusmkt || ' foi aprovado em ');
									dbms_lob.append(msg, To_Char(Sysdate, 'dd/mm/yyyy hh24:mi:ss'));
									dbms_lob.append(msg, ' por ' || ad_get.Nomeusu(p_codusu, 'resumido'));
									dbms_lob.append(msg, '<br><br>');
									dbms_lob.append(msg, '<p>Para maiores informa��es, consulte o Briefing clicando ');
									dbms_lob.append(msg, '<a href="');
									dbms_lob.append(msg, ad_fnc_urlskw('AD_TSFSMKT', S.NUSMKT, Null, Null));
									dbms_lob.append(msg, '"> AQUI </a></p>');
									dbms_lob.append(msg, '</body>');
									dbms_lob.append(msg, '</html>');
						
									ad_stp_gravafilabi(p_Assunto => 'Aprova��o de Briefing.', p_Mensagem => msg, p_Email => ad_get.Mailusu(s.codususol));
						End;
			
			End Loop;

			p_mensagem := 'Aprova��o realizada com sucesso!';

End;

/
