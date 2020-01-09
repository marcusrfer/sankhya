Create Or Replace Trigger Ad_Trg_Aiud_Tsilib_Sf
	After Insert Or Update Or Delete On Tsilib
	For Each Row
Declare
	Mail          Tmdfmg%Rowtype;
	v_Count       Int := 0;
	v_NuEvento    Number;
	v_Descrevento Varchar2(200);
	v_Nomesolicit Varchar2(200);
	v_Ordcarga    Number;
	v_Codusulog   Number := Stp_Get_Codusulogado();
	Errmsg        Varchar2(4000);
Begin
	/*
  Autor: Marcus Rangel
  Dt. Criação: 31/08/2016
  Objetivo: Atender os processos customizados implemnentados no sistema. Envio de e-mail, envio de avisos no sistema, gravação de log, atualização de status.
  
  ** Atualizações **
  Autor: Ricardo Soares
  Dt. Atualização: 01/09/2017
  Descritivo: Guardar log quando houver a exclusão do evento 1001;
  */

	If stp_get_atualizando Then
		Return;
	End If;

	/* Busca o nome do evento para o corpo do e-mail*/
	Begin
		Select e.Descricao
			Into v_Descrevento
			From Vgflibeve e
		 Where e.Evento = Nvl(:New.Evento, :Old.Evento);
	Exception
		When No_Data_Found Then
			v_Descrevento := 'Autorização de Pagamento';
	End;

	If :New.Evento = 1017 Then
		--ver com gusttavo se isso tem grandes impactos, se entrar nessa trigger dá tabela mutante no momento em que a Trg_Cmp_Tgffin_Confirma_Sf identifica que :NEW.PROVISAO = S
		Return;
	End If;

	If Inserting Then
	
		-- liberação de pagamento de acerto
		Select Evelibpagacert
			Into v_NuEvento
			From Ad_Tsfelt e
		 Where e.Nuelt = 1;
	
		If :New.Evento = v_NuEvento Then
			If :New.Dhlib Is Null Then
				Mail.Assunto  := 'Nova Solicitação de Liberação.';
				Mail.Mensagem := '<font align="left">Atenção, foi inserida uma nova Solicitação de Liberação para ' ||
												 v_Descrevento || '<br> <b> Solicitante : </b>' ||
												 Ad_Get.Nomeusu(:New.Codususolicit, 'resumido') ||
												 '<br> <b>Número Único: </b>' || :New.Nuchave ||
												 '<br><b>Valor Solicitado: </b>' ||
												 Replace(Ltrim(Rtrim('R$' || To_Char(:New.Vlratual, '999G999D99'))),
																 '   ',
																 ' ');
			
				Mail.Email := Ad_Get.Mailusu(:New.Codusulib);
				--Ad_Stp_Gravafilabi(Mail.Assunto, Mail.Mensagem, Mail.Email); solicitado Paulo Modesto
			End If;
		End If;
	
		-- liberação de pagemento de despesas extras de frete
		If :New.Tabela = 'AD_TSFDEF' Then
			Select Nvl(u.Nomeusucplt, u.Nomeusu)
				Into v_Nomesolicit
				From Tsiusu u
			 Where Codusu = :New.Codususolicit;
		
			Begin
				Select d.Ordemcarga
					Into v_Ordcarga
					From Ad_Tsfdef d
				 Where Nudef = :New.Nuchave;
			Exception
				When No_Data_Found Then
					v_Ordcarga := 0;
			End;
		
			Mail.Assunto := 'Nova solicitação de liberação.';
		
			Mail.Mensagem := '<br> Uma nova solicitação de liberação para pagamento de despesas extras de fretes, ' ||
											 'referente à Ordem de Carga nº ' || v_Ordcarga || ', no valor de ' ||
											 Ad_Get.Formatavalor(:New.Vlratual) || ', foi cadastrada no sistema por ' ||
											 v_Nomesolicit;
		
			Select Nvl(u.Emailsollib, u.Email)
				Into Mail.Email
				From Tsiusu u
			 Where u.Codusu = :New.Codusulib;
		
		End If;
	
		/*
      Alteração: Inclusão de teste para trabalhar com controle de multas.
      Data: 10/10/2016
      Autor: Guilherme Hahn
    */
		If :New.Tabela = 'AD_MULCONT' Then
			Select Nvl(u.Nomeusucplt, u.Nomeusu)
				Into v_Nomesolicit
				From Tsiusu u
			 Where Codusu = :New.Codususolicit;
		
			Mail.Assunto := 'Nova solicitação de liberação.';
		
			Mail.Mensagem := '<br> Uma nova solicitação de liberação para Pagamento de Multas, ' ||
											 'referente ao Código de Controle de Multas nº ' || :New.Nuchave ||
											 ', no valor de ' || Ad_Get.Formatavalor(:New.Vlratual) ||
											 ', foi cadastrada no sistema por ' || v_Nomesolicit;
		
			Select Nvl(u.Emailsollib, u.Email)
				Into Mail.Email
				From Tsiusu u
			 Where u.Codusu = :New.Codusulib;
		
		End If;
	
		/*
    * Autor: Marcus Rangel
    * Objetivo: Tratativas do processo de despesas jurídicas
    */
	
		If :New.Tabela = 'AD_JURITE' Then
		
			Declare
				j ad_jurite%Rowtype;
			Begin
			
				v_Nomesolicit := ad_get.nomeusu(:New.Codususolicit, 'completo');
			
				mail.email := ad_get.Mailusu(:new.Codusulib);
			
				ad_pkg_jur.v_Reclamante := ad_pkg_jur.get_nome_reclamante(p_nupasta => :new.Nuchave);
			
				j.numprocesso := ad_pkg_jur.get_nro_processo_jur(:new.Nuchave, :new.Sequencia);
			
				Mail.Assunto := 'Nova solicitação de liberação.';
			
				Mail.Mensagem := '<br> Uma nova solicitação de liberação para pagamento de despesas juridicas, ' ||
												 'referente ao processo nº ' || j.numprocesso || ' de ' ||
												 ad_pkg_jur.v_Reclamante || '(pasta nro ' || :new.Nuchave || ', sequência ' ||
												 :new.Sequencia || '), no valor de ' || Ad_Get.Formatavalor(:New.Vlratual) ||
												 ', foi cadastrada no sistema por ' || v_Nomesolicit;
			
			Exception
				When Others Then
					Raise;
			End;
		End If;
		-- fim if juridico
	
		If :new.Codusulib > 0 Then
		
			Ad_Stp_Gravafilabi(Mail.Assunto, Mail.Mensagem, Mail.Email);
		
			ad_set.ins_avisosistema(p_titulo     => 'Liberação solicitada.',
															p_descricao  => 'Uma nova solicitação de liberação para você foi cadastrada no sistema, ' ||
																							v_descrevento,
															p_solucao    => 'Verifique a tela de liberação disponíveis para maiores detalhes.',
															p_usurem     => :new.Codususolicit,
															p_usudest    => :new.Codusulib,
															p_prioridade => 1,
															p_tabela     => :new.Tabela,
															p_nrounico   => :new.Nuchave,
															p_erro       => Errmsg);
		
			If errmsg Is Not Null Then
				Raise_Application_Error(-20105, ad_fnc_formataerro(errmsg));
			End If;
		
		End If;
	
		Begin
			Insert Into Ad_Tsiliblog
				(Nuchave, Tabela, Dhsolicit, Dhlib, Codususol, Codusulib, Codusuexc, Vlratual, Vlrliberado,
				 Evento, Observacao, Obslib, Operacao, Dhoper, Seqlog)
			Values
				(:New.Nuchave, :New.Tabela, :New.Dhsolicit, :New.Dhlib, :New.Codususolicit, :New.Codusulib,
				 v_Codusulog, :New.Vlratual, :New.Vlrliberado, :New.Evento, :New.Observacao, :New.Obslib,
				 'Inclusão', Sysdate, Ad_Seq_Tsilib_Log.Nextval);
		Exception
			When Others Then
				Errmsg := 'Erro ao gravar o log da liberação - Insert - ' || Sqlerrm;
				Raise_Application_Error(-20105, Ad_Fnc_Formataerro(Errmsg));
		End;
	
	End If;
	-- if inserting

	If updating Then
	
		If Updating('DHLIB') And :New.Dhlib Is Not Null And :Old.Dhlib Is Null Then
		
			If :New.Tabela = 'AD_TABCOTCAB' Then
				Begin
					Update Ad_Tabcotcab c
						 Set c.Situacao = 'L'
					 Where c.Numcotacao = :New.Nuchave;
				Exception
					When Others Then
						Errmsg := 'Erro ao atualizar o status do lançamento de origem. ' || Sqlerrm;
						Raise_Application_Error(-20105, Ad_Fnc_Formataerro(Errmsg));
				End;
			End If;
		
			If :New.Tabela = 'AD_TSFDEF' Then
				v_Count := Ad_Get.Qtdlibpend(p_Nuchave   => :New.Nuchave,
																		 p_Tabela    => 'AD_TSFDEF',
																		 p_Sequencia => :New.Sequencia);
				If v_Count = 0 Then
					Begin
						Update Ad_Tsfdef d
							 Set d.Status = 'L'
						 Where Nudef = :New.Nuchave;
					Exception
						When Others Then
							Errmsg := 'Erro ao atualizar o status da despesa. ' || Sqlerrm;
							Raise_Application_Error(-20105, Ad_Fnc_Formataerro(Errmsg));
					End;
				End If;
			
				Select Nvl(u.Emailsollib, u.Email)
					Into Mail.Email
					From Tsiusu u
				 Where u.Codusu = :New.Codususolicit;
			
				Mail.Assunto := 'Solicitação liberada.';
			
				Mail.Mensagem := '<br> A solicitação de liberação para pagamento    de despesas extras de fretes, ' ||
												 'referente à Ordem de Carga nº ' || :New.Nuchave || ', no valor de ' ||
												 Ad_Get.Formatavalor(:New.Vlratual) || ', foi liberada no sistema.';
			
				If Nvl(:New.Reprovado, 'N') = 'S' Then
					Begin
						Update Ad_Tsfdef d
							 Set d.Status = 'N'
						 Where Nudef = :New.Nuchave;
						Select Nvl(u.Emailsollib, u.Email)
							Into Mail.Email
							From Tsiusu u
						 Where u.Codusu = :New.Codususolicit;
					
						Mail.Assunto  := 'Solicitação Reprovada.';
						Mail.Mensagem := '<br> A solicitação de liberação para pagamento    de despesas extras de fretes, ' ||
														 'referente à Ordem de Carga nº ' || :New.Nuchave || ', no valor de ' ||
														 Ad_Get.Formatavalor(:New.Vlratual) || ', foi reprovada no sistema.' ||
														 '<br> Motivo: ' || :New.Obslib;
					
						Ad_Stp_Gravafilabi(Mail.Assunto, Mail.Mensagem, Mail.Email);
					Exception
						When Others Then
							Errmsg := 'Erro ao atualizar o status da despesa reprovada. ' || Sqlerrm;
							Raise_Application_Error(-20105, Ad_Fnc_Formataerro(Errmsg));
					End;
				End If;
			
			End If;
		
			/*
        Alteração: Inclusão de teste para trabalhar com controle de multas.
        Data: 10/10/2016
        Autor: Guilherme Hahn
      */
			If :New.Tabela = 'AD_MULCONT' Then
			
				/*Stp_Controle_Multa(p_Codmulta => :new.Nuchave, p_Mensagem => errmsg);
        
        If Errmsg Is Not Null Then
          Raise_Application_Error(-20105, Ad_Fnc_Formataerro(Errmsg));
        End If;
        
        v_Count := Ad_Get.Qtdlibpend(p_Nuchave   => :New.Nuchave,
                                     p_Tabela    => 'AD_MULCONT',
                                     p_Sequencia => :New.Sequencia);*/
				--If v_Count = 0 Then
				Begin
					Update Ad_Mulcontrol m
						 Set m.Situacao = 'A', m.Dtlib = Sysdate
					 Where m.Codmulcont = :New.Nuchave;
				Exception
					When Others Then
						Errmsg := 'Erro ao atualizar o status da liberação da multa. ' || Sqlerrm;
						Raise_Application_Error(-20105, Ad_Fnc_Formataerro(Errmsg));
				End;
			
				--End If;
			
				Select Nvl(u.Emailsollib, u.Email)
					Into Mail.Email
					From Tsiusu u
				 Where u.Codusu = :New.Codususolicit;
			
				Mail.Assunto := 'Solicitação liberada.';
			
				Mail.Mensagem := '<br> A solicitação de liberação para pagamento de multa, ' ||
												 'referente código de controle de multa nº ' || :New.Nuchave ||
												 ', no valor de ' || Ad_Get.Formatavalor(:New.Vlratual) ||
												 ', foi liberada no sistema.';
			
				If :New.Reprovado = 'S' Then
					Begin
						Update Ad_Mulcontrol m
							 Set m.Situacao = 'N'
						 Where m.Codmulcont = :New.Nuchave;
						Select Nvl(u.Emailsollib, u.Email)
							Into Mail.Email
							From Tsiusu u
						 Where u.Codusu = :New.Codususolicit;
					
						Mail.Assunto  := 'Solicitação Reprovada.';
						Mail.Mensagem := '<br> A solicitação de liberação para pagamento de multa, ' ||
														 'referente código de controle de multa nº ' || :New.Nuchave ||
														 ', no valor de ' || Ad_Get.Formatavalor(:New.Vlratual) ||
														 ', foi reprovada no sistema.' || '<br> Motivo: ' || :New.Obslib;
					
					Exception
						When Others Then
							Errmsg := 'Erro ao atualizar o status da liberação da multa. ' || Sqlerrm;
							Raise_Application_Error(-20105, Ad_Fnc_Formataerro(Errmsg));
					End;
				End If;
			
			End If;
		
			/*
        Alteração: Aprovadores - Solicitação de Compras
        Data: 24/04/2017
        Autor: Gusttavo Lopes
        ---Tela - Solicitação de compra
        ---  Rotinas Personalizadas » Almoxarifado » Telas Adicionais » Solicitação de compra
        --- SubTela - Aprovadores
      */
			If :New.Tabela = 'AD_CABSOLCPA' Then
			
				Select Nvl(u.Emailsollib, u.Email)
					Into Mail.Email
					From Tsiusu u
				 Where u.Codusu = :New.Codususolicit;
			
				---Liberado
				If Nvl(:New.Reprovado, 'N') = 'N' Then
					Mail.Assunto  := 'Solicitação liberada.';
					Mail.Mensagem := '<br> A solicitação de Liberação para ' || v_Descrevento || ', ' ||
													 'referente ao código nº ' || :New.Nuchave ||
													 ', foi liberada no sistema.';
				
				End If;
			
				---Reprovado
				If Nvl(:New.Reprovado, 'N') = 'S' Then
					Mail.Assunto  := 'Solicitação Reprovada.';
					Mail.Mensagem := '<br> A solicitação de liberação para ' || v_Descrevento || ', ' ||
													 'referente ao código nº ' || :New.Nuchave ||
													 ', foi reprovada no sistema.' || '<br> Motivo: ' || :New.Obslib;
				
				End If;
			
			End If;
		
			If :New.Tabela = 'AD_TSFCAPSOL' Then
				Declare
					v_Codususol Number;
				Begin
				
					ad_pkg_cap.v_permite_edicao := True;
				
					If Nvl(:New.Reprovado, 'N') = 'N' Then
					
						Begin
							Update Ad_Tsfcapsol s
								 Set s.Status = 'L'
							 Where Nucapsol = :New.Nuchave;
						Exception
							When Others Then
								Raise;
						End;
					
						Select s.Codusu
							Into v_Codususol
							From Ad_Tsfcapsol s
						 Where Nucapsol = :New.Nuchave;
					
						Insert Into Execparams
							(Idsessao, Sequencia, Nome, Tipo, Numint)
						Values
							('liberaeeenviaparaagendamento', 1, 'NUCAPSOL', 'I', :New.Nuchave);
					
						/* Ao liberar, já envia a solicitação automaticamente, evitando que o solicitante
            * necessite entrar na solicitação e realizar o envio manualmente.
            */
						Ad_Stp_Cap_Enviaagend(v_Codususol, 'liberaeeenviaparaagendamento', 1, Errmsg);
					
						Delete From Execparams
						 Where Idsessao = 'liberaeeenviaparaagendamento';
					
						Mail.Assunto  := 'Solicitação liberada.';
						Mail.Mensagem := '<br> A solicitação de Liberação para ' || v_Descrevento || ', ' ||
														 'referente ao código nº ' || :New.Nuchave ||
														 ', foi liberada no sistema.';
					
					Else
					
						Begin
							Update Ad_Tsfcapsol s
								 Set s.Status = 'SR'
							 Where Nucapsol = :New.Nuchave;
						Exception
							When Others Then
								Raise;
						End;
					
						Mail.Assunto  := 'Solicitação Reprovada.';
						Mail.Mensagem := '<br> A solicitação de liberação para ' || v_Descrevento || ', ' ||
														 'referente ao código nº ' || :New.Nuchave ||
														 ', foi reprovada no sistema.' || '<br> Motivo: ' || :New.Obslib;
					End If;
				
				Exception
					When Others Then
						Raise_Application_Error(-20105, Sqlerrm);
				End;
			
			End If;
		
			If :new.Codusulib > 0 Then
			
				Ad_Stp_Gravafilabi(Mail.Assunto, Mail.Mensagem, Mail.Email);
			
				ad_set.ins_avisosistema(p_titulo     => 'Liberação realizada.',
																p_descricao  => 'Ocorreu uma liberação em uma solicitação realizada por você.',
																p_solucao    => 'Verifique o evento ' || v_descrevento ||
																								', lançamento ' || :new.Nuchave,
																p_usurem     => :new.Codusulib,
																p_usudest    => :new.Codususolicit,
																p_prioridade => 1,
																p_tabela     => :new.Tabela,
																p_nrounico   => :new.Nuchave,
																p_erro       => errmsg);
				If errmsg Is Not Null Then
					Raise_Application_Error(-20105, ad_fnc_formataerro(errmsg));
				End If;
			
			End If;
		
		End If;
		-- fim if updating dhlib
	
		-- grava log 
		Begin
			----Valores Antigos
			Insert Into Ad_Tsiliblog
				(Nuchave, Tabela, Dhsolicit, Dhlib, Codususol, Codusulib, Codusuexc, Vlratual, Vlrliberado,
				 Evento, Observacao, Obslib, Operacao, Dhoper, Seqlog, nuadto)
			Values
				(:Old.Nuchave, :Old.Tabela, :Old.Dhsolicit, :Old.Dhlib, :Old.Codususolicit, :Old.Codusulib,
				 v_Codusulog, :Old.Vlratual, :Old.Vlrliberado, :Old.Evento, :Old.Observacao, :Old.Obslib,
				 'Alteração - valores antigos', Sysdate, Ad_Seq_Tsilib_Log.Nextval, :New.Ad_Nuadto);
		
			----Valores Novos    
			Insert Into Ad_Tsiliblog
				(Nuchave, Tabela, Dhsolicit, Dhlib, Codususol, Codusulib, Codusuexc, Vlratual, Vlrliberado,
				 Evento, Observacao, Obslib, Operacao, Dhoper, Seqlog, nuadto)
			Values
				(:New.Nuchave, :New.Tabela, :New.Dhsolicit, :New.Dhlib, :New.Codususolicit, :New.Codusulib,
				 v_Codusulog, :New.Vlratual, :New.Vlrliberado, :New.Evento, :New.Observacao, :New.Obslib,
				 'Alteração - valores novos', Sysdate, Ad_Seq_Tsilib_Log.Nextval, :New.Ad_Nuadto);
		
		Exception
			When Others Then
				Errmsg := 'Erro ao gravar o log da exclusão da liberação. ' || Sqlerrm;
				Raise_Application_Error(-20105, Ad_Fnc_Formataerro(Errmsg));
		End;
	
	End If;
	-- fim if updating

	If Deleting Then
	
		If :Old.Tabela = 'AD_TSFDEF' Then
		
			Select Nvl(u.Nomeusucplt, u.Nomeusu)
				Into v_Nomesolicit
				From Tsiusu u
			 Where Codusu = v_Codusulog;
		
			Begin
				Select d.Ordemcarga
					Into v_Ordcarga
					From Ad_Tsfdef d
				 Where Nudef = :Old.Nuchave;
			Exception
				When No_Data_Found Then
					v_Ordcarga := 0;
			End;
		
			Mail.Assunto  := 'Exclusão de liberação.';
			Mail.Mensagem := '<br> A solicitação de liberação para pagamento    de despesas extras de fretes, ' ||
											 'referente à Ordem de Carga nº ' || v_Ordcarga || ', no valor de ' ||
											 Ad_Get.Formatavalor(:Old.Vlratual) || ', foi excluída no sistema por ' ||
											 v_Nomesolicit;
		
			Select Nvl(u.Emailsollib, u.Email)
				Into Mail.Email
				From Tsiusu u
			 Where u.Codusu = :Old.Codusulib;
		
		End If;
	
		If :Old.Tabela = 'AD_MULCONT' Then
		
			Select Nvl(u.Nomeusucplt, u.Nomeusu)
				Into v_Nomesolicit
				From Tsiusu u
			 Where Codusu = v_Codusulog;
		
			Mail.Assunto  := 'Exclusão de liberação.';
			Mail.Mensagem := '<br> A solicitação de liberação para pagamento de multa, ' ||
											 'referente código de controle de multas nº ' || :New.Nuchave ||
											 ', no valor de ' || Ad_Get.Formatavalor(:Old.Vlratual) ||
											 ', foi excluída no sistema por ' || v_Nomesolicit;
		
			Select Nvl(u.Emailsollib, u.Email)
				Into Mail.Email
				From Tsiusu u
			 Where u.Codusu = :Old.Codusulib;
		
		End If;
	
		If :Old.Tabela = 'AD_CABSOLCPA' Then
		
			Select Nvl(u.Nomeusucplt, u.Nomeusu)
				Into v_Nomesolicit
				From Tsiusu u
			 Where Codusu = v_Codusulog;
		
			Mail.Assunto  := 'Exclusão de liberação.';
			Mail.Mensagem := '<br> A solicitação de liberação para ' || v_Descrevento || ', ' ||
											 'referente ao código nº ' || :Old.Nuchave ||
											 ', foi excluída no sistema por ' || v_Nomesolicit;
		
			Select Nvl(u.Emailsollib, u.Email)
				Into Mail.Email
				From Tsiusu u
			 Where u.Codusu = :Old.Codusulib;
		
		End If;
	
		Begin
		
			Insert Into Ad_Tsiliblog
				(Nuchave, Tabela, Dhsolicit, Dhlib, Codususol, Codusulib, Codusuexc, Vlratual, Vlrliberado,
				 Evento, Observacao, Obslib, Operacao, Dhoper, Seqlog)
			Values
				(:Old.Nuchave, :Old.Tabela, :Old.Dhsolicit, :Old.Dhlib, :Old.Codususolicit, :Old.Codusulib,
				 v_Codusulog, :Old.Vlratual, :Old.Vlrliberado, :Old.Evento, :Old.Observacao, :Old.Obslib,
				 'Exclusão', Sysdate, Ad_Seq_Tsilib_Log.Nextval);
		Exception
			When Others Then
				Errmsg := 'Erro ao gravar o log da exclusão da liberação. ' || Sqlerrm;
				Raise_Application_Error(-20105, Ad_Fnc_Formataerro(Errmsg));
		End;
	
		If :old.Codusulib > 0 Then
			Ad_Stp_Gravafilabi(Mail.Assunto, Mail.Mensagem, Mail.Email);
		End If;
	
	End If;

End;
/
