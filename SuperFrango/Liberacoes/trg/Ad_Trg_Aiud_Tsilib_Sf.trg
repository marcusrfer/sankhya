Create Or Replace Trigger Ad_Trg_Aiud_Tsilib_Sf
		After Delete Or Insert Or Update On Sankhya.Tsilib
		Referencing New As New Old As Old
		For Each Row
Declare
		Mail          Tmdfmg%Rowtype;
		eventos       ad_tsfelt%Rowtype;
		v_Count       Int := 0;
		v_Nuevento    Number;
		v_Descrevento Varchar2(200);
		v_Nomesolicit Varchar2(200);
		v_Ordcarga    Number;
		v_Codusulog   Number := Stp_Get_Codusulogado();
		v_Enviamail   Varchar2(1) := 'N';
		Errmsg        Varchar2(4000);
Begin
		/*
  Autor: Marcus Rangel
  Dt. Cria��o: 31/08/2016
  Objetivo: Atender os processos customizados implemnentados no sistema. Envio de e-mail, envio de avisos no sistema, grava��o de log, atualiza��o de status.
  
  ** Atualiza��es **
  Autor: Ricardo Soares
  Dt. Atualiza��o: 01/09/2017
  Descritivo: Guardar log quando houver a exclus�o do evento 1001;
  
  Autor: Ricardo Soares
  Dt. Atualiza��o: 01/10/2018
  Descritivo: 001 - Dispara e-mail quando libera TOP 1009, se evento 1001 manda email para quem libera 1007, se evento 1007 dispara email para quem libera 1006, caso o usu�rio liberador n�o tenha tentado confirmar a nota
  */

		/*If Stp_Get_Atualizando Then
      Return;
  End If;*/

		/* Busca o nome do evento para o corpo do e-mail*/
		Begin
				Select e.Descricao Into v_Descrevento From Vgflibeve e Where e.Evento = Nvl(:New.Evento, :Old.Evento);
		Exception
				When No_Data_Found Then
						v_Descrevento := 'Autoriza��o de Pagamento';
		End;

		If :New.Evento = 1017 Then
				--ver com gusttavo se isso tem grandes impactos, se entrar nessa trigger d� tabela mutante no momento em que a Trg_Cmp_Tgffin_Confirma_Sf identifica que :NEW.PROVISAO = S
				Return;
		End If;

		-- get eventos do transporte
		Select * Into eventos From ad_tsfelt Where nuelt = 1;

		If Inserting Then
		
				-- libera��o de pagamento de acerto
				Select Evelibpagacert Into v_Nuevento From Ad_Tsfelt e Where e.Nuelt = 1;
		
				--If :New.Evento = v_NuEvento Then
				If :New.Dhlib Is Null Then
						Mail.Assunto  := 'Nova Solicita��o de Libera��o.';
						Mail.Mensagem := '<font align="left">Aten��o, foi inserida uma nova Solicita��o de Libera��o para ' ||
																							v_Descrevento || '<br> <b> Solicitante : </b>' ||
																							Ad_Get.Nomeusu(:New.Codususolicit, 'resumido') || '<br> <b>N�mero �nico: </b>' ||
																							:New.Nuchave || '<br><b>Valor Solicitado: </b>' ||
																							Replace(Ltrim(Rtrim('R$' || To_Char(:New.Vlratual, '999G999D99'))), '   ', ' ');
				
						Mail.Email := Ad_Get.Mailusu(:New.Codusulib);
						--Ad_Stp_Gravafilabi(Mail.Assunto, Mail.Mensagem, Mail.Email); solicitado Paulo Modesto
				End If;
				--End If;
		
				-- libera��o de pagemento de despesas extras de frete
				If :New.Tabela = 'AD_TSFDEF' Then
				
						Select Nvl(u.Nomeusucplt, u.Nomeusu)
								Into v_Nomesolicit
								From Tsiusu u
							Where Codusu = :New.Codususolicit;
				
						Begin
								Select d.Ordemcarga Into v_Ordcarga From Ad_Tsfdef d Where Nudef = :New.Nuchave;
						Exception
								When No_Data_Found Then
										v_Ordcarga := 0;
						End;
				
						Mail.Mensagem := '<br> Uma nova solicita��o de libera��o para pagamento de despesas extras de fretes, ' ||
																							'referente � Ordem de Carga n� ' || v_Ordcarga || ', no valor de ' ||
																							Ad_Get.Formatavalor(:New.Vlratual) || ', foi cadastrada no sistema por ' ||
																							v_Nomesolicit;
				
						Mail.Email := Ad_Get.Mailusu(:New.Codusulib);
				
						v_Enviamail := 'S';
				
				End If;
		
				/*
      Altera��o: Inclus�o de teste para trabalhar com controle de multas.
      Data: 10/10/2016
      Autor: Guilherme Hahn
    */
				If :New.Tabela = 'AD_MULCONT' Then
				
						Select Nvl(u.Nomeusucplt, u.Nomeusu)
								Into v_Nomesolicit
								From Tsiusu u
							Where Codusu = :New.Codususolicit;
				
						Mail.Assunto := 'Nova solicita��o de libera��o.';
				
						Mail.Mensagem := '<br> Uma nova solicita��o de libera��o para Pagamento de Multas, ' ||
																							'referente ao C�digo de Controle de Multas n� ' || :New.Nuchave || ', no valor de ' ||
																							Ad_Get.Formatavalor(:New.Vlratual) || ', foi cadastrada no sistema por ' ||
																							v_Nomesolicit;
				
						Mail.Email := Ad_Get.Mailusu(:New.Codusulib);
				
						v_Enviamail := 'S';
				
				End If;
		
				/*
    * Autor: Marcus Rangel
    * Objetivo: Tratativas do processo de despesas jur�dicas
    */
				-- libera��o de pagemento de despesas juridicas
		
				If :New.Tabela = 'AD_JURITE' Then
				
						Declare
								j Ad_Jurite%Rowtype;
						Begin
								v_Enviamail := 'S';
						
								v_Nomesolicit := Ad_Get.Nomeusu(:New.Codususolicit, 'completo');
						
								Mail.Email := Ad_Get.Mailusu(:New.Codusulib);
						
								Ad_Pkg_Jur.v_Reclamante := Ad_Pkg_Jur.Get_Nome_Reclamante(p_Nupasta => :New.Nuchave);
						
								j.Numprocesso := Ad_Pkg_Jur.Get_Nro_Processo_Jur(:New.Nuchave, :New.Sequencia);
						
								Mail.Assunto := 'Nova solicita��o de libera��o.';
						
								Mail.Mensagem := '<br> Uma nova solicita��o de libera��o para pagamento de despesas juridicas, ' ||
																									'referente ao processo n� ' || j.Numprocesso || ' de ' || Ad_Pkg_Jur.v_Reclamante ||
																									'(pasta nro ' || :New.Nuchave || ', sequ�ncia ' || :New.Sequencia ||
																									'), no valor de ' || Ad_Get.Formatavalor(:New.Vlratual) ||
																									', foi cadastrada no sistema por ' || v_Nomesolicit;
						
								-- envia o mail de notifica��o para o liberador do centro de resultados
						
						Exception
								When Others Then
										Raise;
						End;
				End If;
				-- fim if juridico
		
				/* M. Rangel 21/01/2019
    **se evento de libera��o de confer�ncia de pedido
    **adicionado basicamente para efetuar a comunica��o dos pedidos
    **gerados pelo apontamento de horas
    */
				If :new.Evento = eventos.Evelibconfped Then
						v_enviamail := 'S';
				End If;
		
				-- se liberador j� selecionar e assunto preenchido e marcado para enviar e-mail
				If :New.Codusulib > 0 And Mail.Assunto Is Not Null And v_Enviamail = 'S' Then
				
						--Ad_Stp_Gravafilabi(Mail.Assunto, Mail.Mensagem, Mail.Email);
				
						Ad_Set.Insere_Mail_Fila_Fmg(Mail.Assunto, Mail.Mensagem, Mail.Email, :New.Nuchave, :New.Evento);
				
						Ad_Set.Ins_Avisosistema(p_Titulo => 'Libera��o solicitada.',
																														p_Descricao => 'Uma nova solicita��o de libera��o para voc� foi cadastrada no sistema, ' ||
																																														v_Descrevento,
																														p_Solucao => 'Verifique a tela de libera��o dispon�veis para maiores detalhes.',
																														p_Usurem => :New.Codususolicit, p_Usudest => :New.Codusulib, p_Prioridade => 1,
																														p_Tabela => :New.Tabela, p_Nrounico => :New.Nuchave, p_Erro => Errmsg);
				
						If Errmsg Is Not Null Then
								Raise_Application_Error(-20105, Ad_Fnc_Formataerro(Errmsg));
						End If;
				
						Begin
								Insert Into Ad_Filanotificacaopush
										(Codfila, Codusudest, Codapp, Mensagem, Dtentrada, Status)
								Values
										(Nvl((Select Max(Codfila) From Ad_Filanotificacaopush), 0) + 1, :New.Codusulib, 1,
											'Nova libera��o de limites solicitada', Sysdate, 'P');
						Exception
								When Others Then
										Errmsg := 'Erro ao enviar notifica��o para apps. ' || Sqlerrm;
										Raise_Application_Error(-20105, Ad_Fnc_Formataerro(Errmsg));
						End;
				
				End If;
		
				Begin
						Insert Into Ad_Tsiliblog
								(Nuchave, Tabela, Dhsolicit, Dhlib, Codususol, Codusulib, Codusuexc, Vlratual, Vlrliberado, Evento,
									Observacao, Obslib, Operacao, Dhoper, Seqlog)
						Values
								(:New.Nuchave, :New.Tabela, :New.Dhsolicit, :New.Dhlib, :New.Codususolicit, :New.Codusulib,
									v_Codusulog, :New.Vlratual, :New.Vlrliberado, :New.Evento, :New.Observacao, :New.Obslib, 'Inclus�o',
									Sysdate, Ad_Seq_Tsilib_Log.Nextval);
				Exception
						When Others Then
								Errmsg := 'Erro ao gravar o log da libera��o - Insert - ' || Sqlerrm;
								Raise_Application_Error(-20105, Ad_Fnc_Formataerro(Errmsg));
				End;
		
		End If;
		-- fim inserting

		If Updating Then
		
				Mail.Email := Ad_Get.Mailusu(:New.Codususolicit);
		
				If Updating('DHLIB') And (:New.Dhlib Is Not Null And :Old.Dhlib Is Null) Then
				
						-- descri��o padr�o
						If Nvl(:New.Reprovado, 'N') = 'N' Then
								Mail.Assunto  := 'Solicita��o liberada.';
								Mail.Mensagem := '<br> A solicita��o de Libera��o para ' || v_Descrevento || ', ' ||
																									'referente ao c�digo n� ' || :New.Nuchave || ', foi liberada no sistema. linha 206';
						Else
								Mail.Assunto  := 'Solicita��o Reprovada.';
								Mail.Mensagem := '<br> A solicita��o de Libera��o para ' || v_Descrevento || ', ' ||
																									'referente ao c�digo n� ' || :New.Nuchave || ', foi reprovada no sistema.';
						End If;
						-- fim descri��o padr�o
				
						If :New.Tabela = 'AD_TABCOTCAB' Then
								Begin
										Update Ad_Tabcotcab c Set c.Situacao = 'L' Where c.Numcotacao = :New.Nuchave;
								Exception
										When Others Then
												Errmsg := 'Erro ao atualizar o status do lan�amento de origem. ' || Sqlerrm;
												Raise_Application_Error(-20105, Ad_Fnc_Formataerro(Errmsg));
								End;
						End If;
				
						-- Inicio altera��o 001 por Ricardo Soares em 01/10/2018 - Envia aviso que tem uma libera��o pendente, caso o usu�rio liberador n�o tenha tentado confirmar a nota
						If :New.Tabela = 'TGFCAB' And :New.Evento In (1001, 1007) Then
						
								v_Enviamail := 'S';
						
								v_Count := Ad_Get.Qtdlibpend(p_Nuchave => :New.Nuchave, p_Tabela => 'TGFCAB',
																																					p_Sequencia => :New.Sequencia);
						
								If v_Count = 0 Then
										-- neste caso � possivel que o usu�rio n�o tenha clicado no confirmar e com isso a pr�xima solicita��o n�o foi enviada.
								
										Mail.Assunto := 'Empr�stimo de Funcion�rios';
								
										Mail.Mensagem := '<br> A solicita��o de ' || Case
																													When :New.Evento = 1001 Then
																														' Aprova��o de Urg�ncia de Despesa '
																													Else
																														' Aprova��o do RH '
																											End || 'foi efetuada pelo usu�rio , ' || :New.Codusulib || ' ' ||
																											Ad_Get.Nomeusu(:New.Codusulib, 'RESUMIDO') || ' no lan�amento ' || :New.Nuchave ||
																											', no valor de ' || Ad_Get.Formatavalor(:New.Vlratual) ||
																											'. � possivel que o usu�rio n�o tenha encaminhado a pr�xima aprova��o, favor verificar.';
								
										Select Listagg(u.Email, ', ') Within Group(Order By u.Email)
												Into Mail.Email
												From Tsilim l,
																	Tsiusu u
											Where u.Codusu = l.Codusu
													And l.Evento = :New.Evento
													And Email Is Not Null;
								
										Ad_Set.Insere_Mail_Fila_Fmg(Mail.Assunto, Mail.Mensagem, Mail.Email, :New.Nuchave, :New.Evento);
								End If;
						
						End If;
						-- Fim altera��o 001 por Ricardo Soares em 01/10/2018 - Envia aviso que tem uma libera��o pendente, caso o usu�rio liberador n�o tenha tentado confirmar a nota
				
						If :New.Tabela = 'AD_TSFDEF' Then
						
								v_Enviamail := 'S';
						
								v_Count := Ad_Get.Qtdlibpend(p_Nuchave => :New.Nuchave, p_Tabela => 'AD_TSFDEF',
																																					p_Sequencia => :New.Sequencia);
								If v_Count = 0 Then
										Begin
												Update Ad_Tsfdef d Set d.Status = 'L' Where Nudef = :New.Nuchave;
										Exception
												When Others Then
														Errmsg := 'Erro ao atualizar o status da despesa. ' || Sqlerrm;
														Raise_Application_Error(-20105, Ad_Fnc_Formataerro(Errmsg));
										End;
								End If;
						
								Mail.Assunto := 'Solicita��o liberada.';
						
								Mail.Mensagem := '<br> A solicita��o de libera��o para pagamento de despesas extras de fretes, ' ||
																									'referente � Ordem de Carga n� ' || :New.Nuchave || ', no valor de ' ||
																									Ad_Get.Formatavalor(:New.Vlratual) || ', foi liberada no sistema.';
						
								If Nvl(:New.Reprovado, 'N') = 'S' Then
										Begin
												Update Ad_Tsfdef d Set d.Status = 'N' Where Nudef = :New.Nuchave;
										
												Mail.Assunto  := 'Solicita��o Reprovada.';
												Mail.Mensagem := '<br> A solicita��o de libera��o para pagamento    de despesas extras de fretes, ' ||
																													'referente � Ordem de Carga n� ' || :New.Nuchave || ', no valor de ' ||
																													Ad_Get.Formatavalor(:New.Vlratual) || ', foi reprovada no sistema.' ||
																													'<br> Motivo: ' || :New.Obslib;
										
												--Ad_Stp_Gravafilabi(Mail.Assunto, Mail.Mensagem, Mail.Email);
												Ad_Set.Insere_Mail_Fila_Fmg(Mail.Assunto, Mail.Mensagem, Mail.Email, :New.Nuchave, :New.Evento);
										
										Exception
												When Others Then
														Errmsg := 'Erro ao atualizar o status da despesa reprovada. ' || Sqlerrm;
														Raise_Application_Error(-20105, Ad_Fnc_Formataerro(Errmsg));
										End;
								End If;
						
						End If;
				
						If :New.Tabela = 'AD_MULCONT' Then
						
								v_Enviamail := 'S';
								/*
          Altera��o: Inclus�o de teste para trabalhar com controle de multas.
          Data: 10/10/2016
          Autor: Guilherme Hahn
        */
						
								Stp_Controle_Multa(p_Codmulta => :New.Nuchave, p_Mensagem => Errmsg);
						
								If Errmsg Is Not Null Then
										Raise_Application_Error(-20105, Ad_Fnc_Formataerro(Errmsg));
								End If;
						
								-- v_Count := Ad_Get.Qtdlibpend(New.Nuchave,'AD_MULCONT',:New.Sequencia);
								-- If v_Count = 0 Then
						
								Begin
										Update Ad_Mulcontrol m
													Set m.Situacao = 'A',
																	m.Dtlib = Sysdate
											Where m.Codmulcont = :New.Nuchave;
								Exception
										When Others Then
												Errmsg := 'Erro ao atualizar o status da libera��o da multa. ' || Sqlerrm;
												Raise_Application_Error(-20105, Ad_Fnc_Formataerro(Errmsg));
								End;
						
								--End If;
						
								Mail.Assunto := 'Solicita��o liberada.';
						
								Mail.Mensagem := '<br> A solicita��o de libera��o para pagamento de multa, ' ||
																									'referente c�digo de controle de multa n� ' || :New.Nuchave || ', no valor de ' ||
																									Ad_Get.Formatavalor(:New.Vlratual) || ', foi liberada no sistema.';
						
								If :New.Reprovado = 'S' Then
										Begin
												Update Ad_Mulcontrol m Set m.Situacao = 'N' Where m.Codmulcont = :New.Nuchave;
										
												Mail.Assunto  := 'Solicita��o Reprovada.';
												Mail.Mensagem := '<br> A solicita��o de libera��o para pagamento de multa, ' ||
																													'referente c�digo de controle de multa n� ' || :New.Nuchave || ', no valor de ' ||
																													Ad_Get.Formatavalor(:New.Vlratual) || ', foi reprovada no sistema.' ||
																													'<br> Motivo: ' || :New.Obslib;
										
										Exception
												When Others Then
														Errmsg := 'Erro ao atualizar o status da libera��o da multa. ' || Sqlerrm;
														Raise_Application_Error(-20105, Ad_Fnc_Formataerro(Errmsg));
										End;
								End If;
						
						End If;
				
						If :New.Tabela = 'AD_CABSOLCPA' Then
						
								v_Enviamail := 'S';
						
								/*
          Altera��o: Aprovadores - Solicita��o de Compras
          Data: 24/04/2017
          Autor: Gusttavo Lopes
          ---Tela - Solicita��o de compra
          ---  Rotinas Personalizadas � Almoxarifado � Telas Adicionais � Solicita��o de compra
          --- SubTela - Aprovadores
        */
						
								---Liberado
								If Nvl(:New.Reprovado, 'N') = 'N' Then
										Mail.Assunto  := 'Solicita��o liberada.';
										Mail.Mensagem := '<br> A solicita��o de Libera��o para ' || v_Descrevento || ', ' ||
																											'referente ao c�digo n� ' || :New.Nuchave || ', foi liberada no sistema.';
								
								Else
										---Reprovado
										Mail.Assunto  := 'Solicita��o Reprovada.';
										Mail.Mensagem := '<br> A solicita��o de libera��o para ' || v_Descrevento || ', ' ||
																											'referente ao c�digo n� ' || :New.Nuchave || ', foi reprovada no sistema.' ||
																											'<br> Motivo: ' || :New.Obslib;
								
								End If;
						
						End If;
				
						If :New.Tabela = 'AD_TSFCAPSOL' Then
						
								Declare
										v_Codususol Number;
								Begin
								
										Ad_Pkg_Cap.v_Permite_Edicao := True;
								
										v_Enviamail := 'S';
								
										If Nvl(:New.Reprovado, 'N') = 'N' Then
										
												Begin
														Update Ad_Tsfcapsol s Set s.Status = 'L' Where Nucapsol = :New.Nuchave;
												Exception
														When Others Then
																Raise;
												End;
										
												Select s.Codusu Into v_Codususol From Ad_Tsfcapsol s Where Nucapsol = :New.Nuchave;
										
												Insert Into Execparams
														(Idsessao, Sequencia, Nome, Tipo, Numint)
												Values
														('liberaeeenviaparaagendamento', 1, 'NUCAPSOL', 'I', :New.Nuchave);
										
												/* Ao liberar, j� envia a solicita��o automaticamente, evitando que o solicitante
            * necessite entrar na solicita��o e realizar o envio manualmente.
            */
												Ad_Stp_Cap_Enviaagend(v_Codususol, 'liberaeeenviaparaagendamento', 1, Errmsg);
										
												Delete From Execparams Where Idsessao = 'liberaeeenviaparaagendamento';
										
												Mail.Assunto  := 'Solicita��o liberada.';
												Mail.Mensagem := '<br> A solicita��o de Libera��o para ' || v_Descrevento || ', ' ||
																													'referente ao c�digo n� ' || :New.Nuchave || ', foi liberada no sistema.';
										
										Else
										
												Begin
														Update Ad_Tsfcapsol s
																	Set s.Status = 'SR' --Sol. Reprovada
															Where Nucapsol = :New.Nuchave;
												Exception
														When Others Then
																Raise;
												End;
										
												Mail.Assunto  := 'Solicita��o Reprovada.';
												Mail.Mensagem := '<br> A solicita��o de libera��o para ' || v_Descrevento || ', ' ||
																													'referente ao c�digo n� ' || :New.Nuchave || ', foi reprovada no sistema.' ||
																													'<br> Motivo: ' || :New.Obslib;
										End If;
								
								Exception
										When Others Then
												Raise_Application_Error(-20105, Sqlerrm);
								End;
						
						End If;
				
						-- Bloco adicionado dia 11/06/2018
						-- por M. Rangel
						-- enviar e-mail de libera��o/reprova��o do evento de horas/m�quina
				
						If :New.Tabela = 'TGFCAB' And :New.Evento = 1011 Then
								If Nvl(:New.Reprovado, 'N') = 'N' Then
										Mail.Assunto  := 'Solicita��o liberada.';
										Mail.Mensagem := '<br> A solicita��o de Libera��o para ' || v_Descrevento || ', ' ||
																											'referente ao c�digo n� ' || :New.Nuchave || ', foi liberada no sistema.';
								Else
										Mail.Assunto  := 'Solicita��o Reprovada.';
										Mail.Mensagem := '<br> A solicita��o de Libera��o para ' || v_Descrevento || ', ' ||
																											'referente ao c�digo n� ' || :New.Nuchave || ', foi reprovada no sistema.';
								End If;
						End If;
				
						If :new.Evento = eventos.Evelibconfped Then
								v_enviamail := 'S';
						End If;
				
						If :New.Codusulib > 0 And Mail.Assunto Is Not Null And v_Enviamail = 'S' Then
						
								--Ad_Stp_Gravafilabi(Mail.Assunto, Mail.Mensagem, Mail.Email);
								Ad_Set.Insere_Mail_Fila_Fmg(Mail.Assunto, Mail.Mensagem, Mail.Email, :New.Nuchave, :New.Evento);
						
								Ad_Set.Ins_Avisosistema(p_Titulo => 'Libera��o realizada.',
																																p_Descricao => 'Ocorreu uma libera��o em uma solicita��o realizada por voc�.',
																																p_Solucao => 'Verifique o evento ' || v_Descrevento || ', lan�amento ' ||
																																														:New.Nuchave, p_Usurem => :New.Codusulib,
																																p_Usudest => :New.Codususolicit, p_Prioridade => 1, p_Tabela => :New.Tabela,
																																p_Nrounico => :New.Nuchave, p_Erro => Errmsg);
								If Errmsg Is Not Null Then
										Raise_Application_Error(-20105, Ad_Fnc_Formataerro(Errmsg));
								End If;
						End If;
				
				End If;
				-- fim if updating dhlib
		
				-- grava log 
				Begin
						----Valores Antigos
						Insert Into Ad_Tsiliblog
								(Nuchave, Tabela, Dhsolicit, Dhlib, Codususol, Codusulib, Codusuexc, Vlratual, Vlrliberado, Evento,
									Observacao, Obslib, Operacao, Dhoper, Seqlog, Nuadto)
						Values
								(:Old.Nuchave, :Old.Tabela, :Old.Dhsolicit, :Old.Dhlib, :Old.Codususolicit, :Old.Codusulib,
									v_Codusulog, :Old.Vlratual, :Old.Vlrliberado, :Old.Evento, :Old.Observacao, :Old.Obslib,
									'Altera��o - valores antigos', Sysdate, Ad_Seq_Tsilib_Log.Nextval, :New.Ad_Nuadto);
				
						----Valores Novos    
						Insert Into Ad_Tsiliblog
								(Nuchave, Tabela, Dhsolicit, Dhlib, Codususol, Codusulib, Codusuexc, Vlratual, Vlrliberado, Evento,
									Observacao, Obslib, Operacao, Dhoper, Seqlog, Nuadto)
						Values
								(:New.Nuchave, :New.Tabela, :New.Dhsolicit, :New.Dhlib, :New.Codususolicit, :New.Codusulib,
									v_Codusulog, :New.Vlratual, :New.Vlrliberado, :New.Evento, :New.Observacao, :New.Obslib,
									'Altera��o - valores novos', Sysdate, Ad_Seq_Tsilib_Log.Nextval, :New.Ad_Nuadto);
				
				Exception
						When Others Then
								Errmsg := 'Erro ao gravar o log da exclus�o da libera��o. ' || Sqlerrm;
								Raise_Application_Error(-20105, Ad_Fnc_Formataerro(Errmsg));
				End;
		
		End If;
		-- fim if updating

		If Deleting Then
		
				Mail.Email := Ad_Get.Mailusu(:Old.Codusulib);
				Mail.Email := Mail.Email || ', ' || Ad_Get.Mailusu(:Old.Codususolicit);
		
				Select Nvl(u.Nomeusucplt, u.Nomeusu)
						Into v_Nomesolicit
						From Tsiusu u
					Where Codusu = Stp_Get_Codusulogado;
		
				Mail.Assunto  := 'Exclus�o de libera��o.';
				Mail.Mensagem := '<br> A solicita��o de libera��o para ' || v_Descrevento || ', ' ||
																					'referente ao c�digo n� ' || :Old.Nuchave || ', foi exclu�da no sistema por ' ||
																					v_Nomesolicit;
		
				If :Old.Tabela = 'AD_TSFDEF' Then
				
						v_Enviamail := 'S';
				
						Begin
								Select d.Ordemcarga Into v_Ordcarga From Ad_Tsfdef d Where Nudef = :Old.Nuchave;
						Exception
								When No_Data_Found Then
										v_Ordcarga := 0;
						End;
				
						Mail.Assunto  := 'Exclus�o de libera��o.';
						Mail.Mensagem := '<br> A solicita��o de libera��o para pagamento    de despesas extras de fretes, ' ||
																							'referente � Ordem de Carga n� ' || v_Ordcarga || ', no valor de ' ||
																							Ad_Get.Formatavalor(:Old.Vlratual) || ', foi exclu�da no sistema por ' ||
																							v_Nomesolicit;
				
				End If;
		
				If :Old.Tabela = 'AD_MULCONT' Then
				
						v_Enviamail := 'S';
				
						Mail.Assunto  := 'Exclus�o de libera��o.';
						Mail.Mensagem := '<br> A solicita��o de libera��o para pagamento de multa, ' ||
																							'referente c�digo de controle de multas n� ' || :New.Nuchave || ', no valor de ' ||
																							Ad_Get.Formatavalor(:Old.Vlratual) || ', foi exclu�da no sistema por ' ||
																							v_Nomesolicit;
				
				End If;
		
				Begin
				
						Insert Into Ad_Tsiliblog
								(Nuchave, Tabela, Dhsolicit, Dhlib, Codususol, Codusulib, Codusuexc, Vlratual, Vlrliberado, Evento,
									Observacao, Obslib, Operacao, Dhoper, Seqlog)
						Values
								(:Old.Nuchave, :Old.Tabela, :Old.Dhsolicit, :Old.Dhlib, :Old.Codususolicit, :Old.Codusulib,
									v_Codusulog, :Old.Vlratual, :Old.Vlrliberado, :Old.Evento, :Old.Observacao, :Old.Obslib, 'Exclus�o',
									Sysdate, Ad_Seq_Tsilib_Log.Nextval);
				Exception
						When Others Then
								Errmsg := 'Erro ao gravar o log da exclus�o da libera��o. ' || Sqlerrm;
								Raise_Application_Error(-20105, Ad_Fnc_Formataerro(Errmsg));
				End;
		
				If :Old.Codusulib > 0 And Mail.Assunto Is Not Null And v_Enviamail = 'S' Then
						Ad_Set.Insere_Mail_Fila_Fmg(Mail.Assunto, Mail.Mensagem, Mail.Email, :Old.Nuchave, :Old.Evento);
						--Ad_Stp_Gravafilabi(Mail.Assunto, Mail.Mensagem, Mail.Email);
				End If;
		
		End If;

End;
/
