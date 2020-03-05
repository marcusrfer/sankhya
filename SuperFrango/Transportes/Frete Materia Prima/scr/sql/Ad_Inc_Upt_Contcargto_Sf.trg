Create Or Replace Trigger Ad_Inc_Upt_Contcargto_Sf
		Before Insert Or Update On Sankhya.Ad_Contcargto
		Referencing New As New Old As Old
		For Each Row
Declare

		Ncol         Integer := 0;
		p_Acao       Varchar(15);
		p_Count      Integer := 0;
		p_Podeabast  Varchar(3);
		p_Motivobloq Tgfvei.Ad_Motivobloq%Type;

		Pragma Autonomous_Transaction;

Begin

		-- alteração M. Rangel 06/06/2018
		If Inserting Or Updating Then
		
				-- preenche a data de validade
				If :New.Dtvalidade Is Null And :New.Dtaprevcarg Is Not Null Then
						:New.Dtvalidade := :New.Dtaprevcarg + 4;
				End If;
		
				If Inserting Then
				
						If To_Char(:New.Datasaidatrans, 'hh24:mi:ss') = '00:00:00' And Nvl(:New.Codlocal, 0) = 0 And
									(:New.Datachegadapatio Is Null And :New.Dataentradadesc Is Null And :New.Datafimdescarga Is Null) Then
								:New.Statusvei := 'A';
						End If;
				
				Else
						--atualizações do statusvei
				
						/* Status dos veículos
      {null   Aguard. Programação},{A Programado},{AP Aguard. Programação},{C Descarregado}
      {D Descarregando}, {P No Pátio},{T Em Trânsito}       */
				
						If Nvl(:New.Codveiculo, 0) = 0 And :New.Datasaidatrans Is Null Then
								:New.Statusvei := 'AP';
						Elsif (:New.Datasaidatrans Is Not Null And To_Char(:New.Datasaidatrans, 'hh24:mi:ss') <> '00:00:00' And
												(:New.Datachegadapatio Is Null And :New.Dataentradadesc Is Null And :New.Datafimdescarga Is Null) And
												Nvl(:New.Codlocal, 0) <> 0) Then
								:New.Statusvei := 'T';
						Elsif :New.Datasaidatrans Is Null Or To_Char(:New.Datasaidatrans, 'hh24:mi:ss') = '00:00:00' Then
								:New.Statusvei := 'A';
						Elsif :New.Datachegadapatio Is Not Null And To_Char(:New.Datachegadapatio, 'hh24:mi:ss') <> '00:00:00' And
												((:New.Dataentradadesc Is Null Or To_Char(:New.Dataentradadesc, 'hh24:mi:ss') = '00:00:00') And
												:New.Datafimdescarga Is Null) Then
								:New.Statusvei := 'P';
						Elsif :New.Datachegadapatio Is Null Or To_Char(:New.Datachegadapatio, 'hh24:mi:ss') = '00:00:00' Then
								:New.Statusvei := 'T';
						Elsif :New.Dataentradadesc Is Not Null And To_Char(:New.Dataentradadesc, 'hh24:mi:ss') <> '00:00:00' And
												(:New.Datafimdescarga Is Null Or To_Char(:New.Datafimdescarga, 'hh:mi:ss') = '00:00:00') Then
								:New.Statusvei := 'D';
								:New.Status    := 'ABERTO';
						Elsif :New.Datafimdescarga Is Not Null And To_Char(:New.Datafimdescarga, 'hh24:mi:ss') <> '00:00:00' Then
								:New.Statusvei := 'C';
						End If;
				
						-- M. Rangel - 28/11/18 - não foi finalizada se não descarregou    
						If Updating('STATUS') And :Old.Status != 'FECHADO' And :New.Status = 'FECHADO' Then
								If :Old.Dataentradadesc Is Null Then
										Raise_Application_Error(-20105,
																																		Ad_Fnc_Formataerro('Ordens de carregamento sem descarga não podem ser fechadas, ' ||
																																																						'pois o processo não foi concluído. Por favor, cancele a ordem e ' ||
																																																						'informe o motivo da mesma não possuir descarga.'));
								End If;
						End If;
				
						-- iniciando viagem sem veículo informado
						If Updating('DATASAIDATRANS') And (:Old.Datasaidatrans Is Null And :New.Datasaidatrans Is Not Null) And
									Nvl(:Old.Codveiculo, 0) = 0 Then
								Raise_Application_Error(-20105,
																																Ad_Fnc_Formataerro('Não é possível iniciar a viagem sem possuir veículo informado.'));
						End If;
				
						-- valida se veículo saiu, para que possa retornar
						/*IF updating('DATACHEGADAPATIO') and :old.statusvei != 'T' THEN
            RAISE_APPLICATION_ERROR(-20000,ad_fnc_formataerro('Não é possível registrar entrada no pátio se o status '||
            'anterior do veículo não for em "Em Trânsito", verifique se o horário foi informado e se o status foi '||
            'atualizado corretamento na última atualização de status.'));
      END IF;*/
				
				End If;
		
				-- identificar fonte de alterações, será removido
				/*
    TODO: owner="Marcus Rangel" created="13/03/2019"
    text="remover linhas do envio de mensagem do sistema"
    */
				If :old.statusvei = 'T' And :new.Statusvei = 'AP' And :new.Datasaidatrans Is Not Null Then
						ad_set.Ins_Avisosistema(p_Titulo => 'Alteração de Status de Carregamento',
																														p_Descricao => 'Status de veículo alterado',
																														p_Solucao => sys_context('userenv', 'action'), p_Usurem => stp_get_codusulogado,
																														p_Usudest => 0, p_Prioridade => 1, p_Tabela => 'AD_CONTCARGTO',
																														p_Nrounico => :new.Sequencia, p_Erro => ad_pkg_var.Errmsg);
				End If;
		
		End If;
		-- fim alteração M. Rangel 06/06/2018

		Select Count(*)
				Into Ncol
				From Sys.Dba_Tab_Columns
			Where Owner = 'SANKHYA'
					And Table_Name = 'AD_CONTCARGTO';

		p_Count := 0;

		Select Count(*)
				Into p_Count
				From Ad_Contcargto_Alt_Sf
			Where Campo = 'STATUS'
					And Sequencia = :New.Sequencia
					And Trunc(Dtalter) <> Trunc(Sysdate)
					And Valornov = 'FECHADO';

		/*
  IF P_COUNT > 0 THEN
       RAISE_APPLICATION_ERROR(-20101, 'Só pode alterar uma ordem após fechada no dia!!!');
  END IF;
  */

		-- CRIADO BY RODRIGO 18/12/2012 PARA NUMERAÇÃO AUTOMÁTICA DE FILA
		If Updating('DATACHEGADAPATIO') And :New.Datachegadapatio Is Not Null And (:New.Ordemdesc Is Null) And
					(:New.Codemp Is Not Null) Then
				p_Count := 0;
				Select Nvl(Max(Ordemdesc), 0) + 1
						Into p_Count
						From Ad_Contcargto a
					Where Trunc(a.Datachegadapatio) = Trunc(:New.Datachegadapatio)
							And a.Sequencia <> :New.Sequencia
							And a.Codemp = :New.Codemp;
				:New.Ordemdesc := p_Count;
				Commit;
		End If;

		If Updating Then
		
				If :New.Sequencia <> :Old.Sequencia Then
						Raise_Application_Error(-20101, 'Proibido alterar sequencia!!!');
				End If;
		
		End If;

		-- para não permitir à alteração de cancelado para aberto ou fechado

		If (:Old.Status = 'CANCELADO') And (:New.Status <> 'CANCELADO') Then
				Raise_Application_Error(-20101, 'Depois de cancelado não é permitido alterar seu status!!!');
		End If;

		-- M. Rangel - 27/11/18
		-- atualizando a saída do veículo - movendo para "Em Trânsito"
		--If :old.Datasaidatrans Is Null And :new.Datasaidatrans Is Not Null Then
		If :Old.Dataentradadesc Is Null And :New.Dataentradadesc Is Not Null Then
		
				Select Count(*)
						Into p_Count
						From Ad_Contcargto c
					Where c.Codveiculo = :New.Codveiculo
							And c.Sequencia != :New.Sequencia
							And c.Status = 'ABERTO'
							And c.Statusvei In ('T', 'P', 'D'); -- em trânsito, no pátio e descarregando 
		
				If p_Count > 0 Then
						Raise_Application_Error(-20105,
																														Fc_Formatahtml('Não é possível iniciar outra saída deste veículo',
																																														'O mesmo já se encontra em outra viagem aberta',
																																														'Finalize a outra ordem de carregamento deste veículo que está aberta'));
				
				End If;
		End If;
		---

		-- PARA VERIFICAR SE O VEICULO ESTÁ DISPONÍVEL

		Select Count(*)
				Into p_Count
				From Ad_Contcargto p
			Where p.Codveiculo = :New.Codveiculo
					And p.Sequencia <> :New.Sequencia
					And Nvl(p.Status, 'ABERTO') Not In ('CANCELADO', 'FECHADO')
					And (p.Datachegadapatio Is Not Null And p.Codlocal Is Null)
					And p.Codveiculo <> 0;

		If p_Count > 0 Then
				Raise_Application_Error(-20101,
																												'O veículo não está disponível, feche ou cancele a ordem de carregamento!!!');
		End If;

		If Inserting Then
				p_Acao := 'INSERÇÃO';
		
				-- M. Rangel - 30/11/2018
				-- com a implementação dos pré agendamentos, o usuário pode abrir carregamento e identificar o veículo depois
				-- a data de saída do veículo, muda o status para "Em Trânsito" logo não está disponívle na inserção
				-- campos obritatórios para a inserção
				/*If (:NEW.Codveiculo Is Null) Or (:NEW.Datasaidatrans Is Null) Then
      Raise_Application_Error(-20101,
                              'Os campos veiculo, parceiro, produto e data saida transporte devem ser preenchidos!!!');
    End If;*/
		
				:New.Status       := 'ABERTO';
				:New.Datahoralanc := Sysdate;
				:New.Tipomov      := 'ENTRADA';
		
		Else
				p_Acao := 'MODIFICACÃO';
		End If;

		If (:New.Datasaidatrans > :New.Datachegadapatio) Then
				Raise_Application_Error(-20101,
																												'A data de chegada ao pátio não pode ser menor que a data de carregamento!!!');
		End If;

		If (:New.Datasaidatrans > :New.Dataentradadesc) Or (:New.Datachegadapatio > :New.Dataentradadesc) Then
				Raise_Application_Error(-20101,
																												'A data de chegada ao pátio não pode ser menor que a data de carregamento ' ||
																													'OU data de chegada ao pátio não pode ser maior que a entrada de descarga!!!');
		End If;

		If (:New.Datasaidatrans > :New.Datafimdescarga) Or (:New.Dataentradadesc > :New.Datafimdescarga) Then
				Raise_Application_Error(-20101,
																												'A data de fim de descarga  não pode ser menor que a data de carregamento ' ||
																													'OU data de inicio de descarga não pode ser maior que a data de fim de descarga!!!');
		End If;

		If (:New.Datasaidatrans Is Null) And (:New.Datachegadapatio Is Not Null) Then
				Raise_Application_Error(-20101, 'A data de saida do transporte deve ser preenchida primeiro!!!');
		End If;

		If (:New.Datachegadapatio Is Null) And (:New.Dataentradadesc Is Not Null) Then
				Raise_Application_Error(-20101, 'A data de chegada ao pátio deve ser preenchida primeiro!!!');
		End If;

		If (:New.Dataentradadesc Is Null) And (:New.Datafimdescarga Is Not Null) Then
				Raise_Application_Error(-20101, 'A data de entrada de descarga deve ser preenchida primeiro!!!');
		End If;

		-- muda o status pra fechado quando termina a descarga
		If Updating('DATAFIMDESCARGA') And :New.Datafimdescarga Is Not Null Then
				:New.Status := 'FECHADO';
		End If;

		-- O.S  11698 PARA GERAR A SEQUENCIA DE CORTE USADA NAS ETIQUETAS NO CONTROLE DE LAUDO BY RODRIGO 05/03/2013
		If Updating('DATACHEGADAPATIO') And :New.Datachegadapatio Is Not Null Then
		
				-- obriga a preencher itens antes de a data de chegada ao patio
				p_Count := 0;
		
				-- VERIFICA SE ESTÁ PREENCHIDO OS CAMPOS BASE
				Select Count(*)
						Into p_Count
						From Ad_Itecargto i
					Where Nvl(i.Codprod, 0) > 0
							And Nvl(i.Codparc, 0) > 0
							And Nvl(i.Numnota, 0) > 0
							And i.Sequencia = :New.Sequencia;
		
				If p_Count = 0 Then
						Raise_Application_Error(-20101, 'Preencha os campos nº nota, produto e parceiro dos itens!!!');
				Else
						-- percorre itens da sequencia atual pra atrubuir sequencia de corte;
				
						For Itecargto In (Select Codprod,
																															Sequencia
																										From Ad_Itecargto i
																									Where Nvl(i.Codparc, 0) > 0
																											And Nvl(i.Numnota, 0) > 0
																											And i.Sequencia = :New.Sequencia)
						Loop
								p_Count := 0;
								-- verifica o ultimo atribuido diferente da sequencia atual
								Select Nvl(Max(Seqcorteprod), 0) + 1
										Into p_Count
										From Ad_Itecargto i
									Where Nvl(i.Codprod, 0) > 0
											And Nvl(i.Codparc, 0) > 0
											And Nvl(i.Numnota, 0) > 0
											And i.Codprod = Itecargto.Codprod
											And i.Sequencia <> :New.Sequencia;
						
								If Nvl(p_Count, 0) > 0 Then
										Update Ad_Itecargto
													Set Seqcorteprod = p_Count
											Where Codprod = Itecargto.Codprod
													And Sequencia = :New.Sequencia;
								End If;
						
						End Loop;
				
				End If;
		
		End If;

		-- SO PERMITE ALTERAÇAO NO DIA DEPOIS DE FECHADO

		/*   IF (:NEW.STATUS ='FECHADO') AND (TRUNC(:NEW.DATAHORALANC) <> TRUNC(SYSDATE))  THEN
      RAISE_APPLICATION_ERROR(-20101, 'A alteração de uma ordem fechada só é permitida no dia do fechamento!!!');
  END IF;*/

		-- GRAVA LOG DE ALTERAÇÕES
		If Ncol <> 25 Then
				Raise_Application_Error(-20101,
																												'Numero de colunas da AD_CONTCARGTO alterado, adicionar/retirar na Trigger de Log');
		Else
		
				If (:New.Classificacao <> :Old.Classificacao) Or
							(:New.Classificacao Is Null And :Old.Classificacao Is Not Null) Or
							(:New.Classificacao Is Not Null And :Old.Classificacao Is Null) Then
						Insert Into Ad_Contcargto_Alt_Sf
						Values
								(:New.Sequencia, :New.Codusu, Sysdate, 'CLASSIFICACAO', :Old.Classificacao, :New.Classificacao,
									p_Acao);
				End If;
		
				If (:New.Codemp <> :Old.Codemp) Or (:New.Codemp Is Null And :Old.Codemp Is Not Null) Or
							(:New.Codemp Is Not Null And :Old.Codemp Is Null) Then
						Insert Into Ad_Contcargto_Alt_Sf
						Values
								(:New.Sequencia, :New.Codusu, Sysdate, 'CODEMP', :Old.Codemp, :New.Codemp, p_Acao);
				End If;
		
				If (:New.Codlocal <> :Old.Codlocal) Or (:New.Codlocal Is Null And :Old.Codlocal Is Not Null) Or
							(:New.Codlocal Is Not Null And :Old.Codlocal Is Null) Then
						Insert Into Ad_Contcargto_Alt_Sf
						Values
								(:New.Sequencia, :New.Codusu, Sysdate, 'CODLOCAL', :Old.Codlocal, :New.Codlocal, p_Acao);
				End If;
		
				If (:New.Codusu <> :Old.Codusu) Or (:New.Codusu Is Null And :Old.Codusu Is Not Null) Or
							(:New.Codusu Is Not Null And :Old.Codusu Is Null) Then
						Insert Into Ad_Contcargto_Alt_Sf
						Values
								(:New.Sequencia, :New.Codusu, Sysdate, 'CODUSU', :Old.Codusu, :New.Codusu, p_Acao);
				End If;
		
				If (:New.Codveiculo <> :Old.Codveiculo) Or (:New.Codveiculo Is Null And :Old.Codveiculo Is Not Null) Or
							(:New.Codveiculo Is Not Null And :Old.Codveiculo Is Null) Then
						Insert Into Ad_Contcargto_Alt_Sf
						Values
								(:New.Sequencia, :New.Codusu, Sysdate, 'CODVEICULO', :Old.Codveiculo, :New.Codveiculo, p_Acao);
				End If;
		
				If (:New.Datachegadapatio <> :Old.Datachegadapatio) Or
							(:New.Datachegadapatio Is Null And :Old.Datachegadapatio Is Not Null) Or
							(:New.Datachegadapatio Is Not Null And :Old.Datachegadapatio Is Null) Then
						Insert Into Ad_Contcargto_Alt_Sf
						Values
								(:New.Sequencia, :New.Codusu, Sysdate, 'DATACHEGADAPATIO', :Old.Datachegadapatio,
									:New.Datachegadapatio, p_Acao);
				End If;
		
				If (:New.Dataentradadesc <> :Old.Dataentradadesc) Or
							(:New.Dataentradadesc Is Null And :Old.Dataentradadesc Is Not Null) Or
							(:New.Dataentradadesc Is Not Null And :Old.Dataentradadesc Is Null) Then
						Insert Into Ad_Contcargto_Alt_Sf
						Values
								(:New.Sequencia, :New.Codusu, Sysdate, 'DATAENTRADADESC', :Old.Dataentradadesc, :New.Dataentradadesc,
									p_Acao);
				End If;
		
				If (:New.Datafimdescarga <> :Old.Datafimdescarga) Or
							(:New.Datafimdescarga Is Null And :Old.Datafimdescarga Is Not Null) Or
							(:New.Datafimdescarga Is Not Null And :Old.Datafimdescarga Is Null) Then
						Insert Into Ad_Contcargto_Alt_Sf
						Values
								(:New.Sequencia, :New.Codusu, Sysdate, 'DATAFIMDESCARGA', :Old.Datafimdescarga, :New.Datafimdescarga,
									p_Acao);
				End If;
		
				If (:New.Datasaidatrans <> :Old.Datasaidatrans) Or
							(:New.Datasaidatrans Is Null And :Old.Datasaidatrans Is Not Null) Or
							(:New.Datasaidatrans Is Not Null And :Old.Datasaidatrans Is Null) Then
						Insert Into Ad_Contcargto_Alt_Sf
						Values
								(:New.Sequencia, :New.Codusu, Sysdate, 'DATASAIDATRANS', :Old.Datasaidatrans, :New.Datasaidatrans,
									p_Acao);
				End If;
		
				If (:New.Obs <> :Old.Obs) Or (:New.Obs Is Null And :Old.Obs Is Not Null) Or
							(:New.Obs Is Not Null And :Old.Obs Is Null) Then
						Insert Into Ad_Contcargto_Alt_Sf
						Values
								(:New.Sequencia, :New.Codusu, Sysdate, 'OBS', :Old.Obs, :New.Obs, p_Acao);
				End If;
		
				If (:New.Ordemdesc <> :Old.Ordemdesc) Or (:New.Ordemdesc Is Null And :Old.Ordemdesc Is Not Null) Or
							(:New.Ordemdesc Is Not Null And :Old.Ordemdesc Is Null) Then
						Insert Into Ad_Contcargto_Alt_Sf
						Values
								(:New.Sequencia, :New.Codusu, Sysdate, 'ORDEMDESC', :Old.Ordemdesc, :New.Ordemdesc, p_Acao);
				End If;
		
				If (:New.Sequencia <> :Old.Sequencia) Or (:New.Sequencia Is Null And :Old.Sequencia Is Not Null) Or
							(:New.Sequencia Is Not Null And :Old.Sequencia Is Null) Then
						Insert Into Ad_Contcargto_Alt_Sf
						Values
								(:New.Sequencia, :New.Codusu, Sysdate, 'SEQUENCIA', :Old.Sequencia, :New.Sequencia, p_Acao);
				End If;
		
				If (:New.Status <> :Old.Status) Or (:New.Status Is Null And :Old.Status Is Not Null) Or
							(:New.Status Is Not Null And :Old.Status Is Null) Then
						Insert Into Ad_Contcargto_Alt_Sf
						Values
								(:New.Sequencia, :New.Codusu, Sysdate, 'STATUS', :Old.Status, :New.Status, p_Acao);
				End If;
		
				If (:New.Datahoralanc <> :Old.Datahoralanc) Or
							(:New.Datahoralanc Is Null And :Old.Datahoralanc Is Not Null) Or
							(:New.Datahoralanc Is Not Null And :Old.Datahoralanc Is Null) Then
						Insert Into Ad_Contcargto_Alt_Sf
						Values
								(:New.Sequencia, :New.Codusu, Sysdate, 'DATAHORALANC', :Old.Datahoralanc, :New.Datahoralanc, p_Acao);
				End If;
		
				If (:New.Dtaprevcarg <> :Old.Dtaprevcarg) Or (:New.Dtaprevcarg Is Null And :Old.Dtaprevcarg Is Not Null) Or
							(:New.Dtaprevcarg Is Not Null And :Old.Dtaprevcarg Is Null) Then
						Insert Into Ad_Contcargto_Alt_Sf
						Values
								(:New.Sequencia, :New.Codusu, Sysdate, 'DTAPREVCARG', :Old.Dtaprevcarg, :New.Dtaprevcarg, p_Acao);
				End If;
		
				If (:New.Podeabastecer <> :Old.Podeabastecer) Or
							(:New.Podeabastecer Is Null And :Old.Podeabastecer Is Not Null) Or
							(:New.Podeabastecer Is Not Null And :Old.Podeabastecer Is Null) Then
						Insert Into Ad_Contcargto_Alt_Sf
						Values
								(:New.Sequencia, :New.Codusu, Sysdate, 'PODEABASTECER', :Old.Podeabastecer, :New.Podeabastecer,
									p_Acao);
				End If;
		
				If (:New.Ordemcarga <> :Old.Ordemcarga) Or (:New.Ordemcarga Is Null And :Old.Ordemcarga Is Not Null) Or
							(:New.Ordemcarga Is Not Null And :Old.Ordemcarga Is Null) Then
						Insert Into Ad_Contcargto_Alt_Sf
						Values
								(:New.Sequencia, :New.Codusu, Sysdate, 'ORDEMCARGA', :Old.Ordemcarga, :New.Ordemcarga, p_Acao);
				End If;
		
				If (:New.Lib_Descarregar <> :Old.Lib_Descarregar) Or
							(:New.Lib_Descarregar Is Null And :Old.Lib_Descarregar Is Not Null) Or
							(:New.Lib_Descarregar Is Not Null And :Old.Lib_Descarregar Is Null) Then
						Insert Into Ad_Contcargto_Alt_Sf
						Values
								(:New.Sequencia, :New.Codusu, Sysdate, 'LIB_DESCARREGAR', :Old.Lib_Descarregar, :New.Lib_Descarregar,
									p_Acao);
				End If;
		
				If (:New.Emitiu_Espelho <> :Old.Emitiu_Espelho) Or
							(:New.Emitiu_Espelho Is Null And :Old.Emitiu_Espelho Is Not Null) Or
							(:New.Emitiu_Espelho Is Not Null And :Old.Emitiu_Espelho Is Null) Then
						Insert Into Ad_Contcargto_Alt_Sf
						Values
								(:New.Sequencia, :New.Codusu, Sysdate, 'EMITIU_ESPELHO', :Old.Emitiu_Espelho, :New.Emitiu_Espelho,
									p_Acao);
				End If;
		
				If (:New.Dthenvioord <> :Old.Dthenvioord) Or (:New.Dthenvioord Is Null And :Old.Dthenvioord Is Not Null) Or
							(:New.Dthenvioord Is Not Null And :Old.Dthenvioord Is Null) Then
						Insert Into Ad_Contcargto_Alt_Sf
						Values
								(:New.Sequencia, :New.Codusu, Sysdate, 'DTHENVIOORD', :Old.Dthenvioord, :New.Dthenvioord, p_Acao);
				End If;
		
				If :New.Nunota <> :Old.Nunota Then
						Insert Into Ad_Contcargto_Alt_Sf
						Values
								(:New.Sequencia, :New.Codusu, Sysdate, 'NUNOTA', :Old.Nunota, :New.Nunota, p_Acao);
				End If;
		
				If :New.Analise_Avulsa <> :Old.Analise_Avulsa Then
						Insert Into Ad_Contcargto_Alt_Sf
						Values
								(:New.Sequencia, :New.Codusu, Sysdate, 'ANALISE_AVULSA', :Old.Analise_Avulsa, :New.Analise_Avulsa,
									p_Acao);
				End If;
		
				Commit;
		End If;

		-- by rodrigo 28/03/2013 verifica se há laudo para a referida sequencia

		p_Count := 0;

		If Updating And Not Updating('DATAENTRADADESC') And Not Updating('DATAFIMDESCARGA') And
					Not Updating('CODLOCAL') And Not Updating('ORDEMCARGA') Then
		
				Select Count(*) Into p_Count From Ad_Cablaudo a Where a.Sequencia = :New.Sequencia;
		
				If p_Count > 0 And :new.status != 'CANCELADO' Then
						Raise_Application_Error(-20101, 'Já existe laudo gerado para essa sequência, proibida alteração');
				End If;
		
		End If;

		-- by rodrigo dia 16/02/2017 depois de vinculado o abastecimento é probido mudar o veiculo

		If :New.Codveiculo <> :Old.Codveiculo Then
		
				Select Count(*) Into p_Count From Ad_Abastvincordem a Where a.Sequencia = :New.Sequencia;
		
				If p_Count > 0 Then
						Raise_Application_Error(-20101, 'Houve vinculação de combustível, proibida alteração');
				End If;
		
		End If;

		If Nvl(:New.Codveiculo, 0) > 0 --AND (:NEW.PODEABASTECER IS NULL)
			Then
		
				Select Ad_Podeabast Into p_Podeabast From Tgfvei Vei Where Vei.Codveiculo = :New.Codveiculo;
				:New.Podeabastecer := Nvl(p_Podeabast, 'NÃO');
		
		End If;

		-- BY RODRIGO DIA 19/07/2018 O.S 32504 
		Select Count(*)
				Into p_Count
				From Tgfvei Vei
			Where Vei.Codveiculo = :New.Codveiculo
					And Nvl(Ad_Codusubloq, 0) > 0;

		If p_Count > 0 Then
				Select Vei.Ad_Motivobloq
						Into p_Motivobloq
						From Tgfvei Vei
					Where Vei.Codveiculo = :New.Codveiculo
							And Nvl(Ad_Codusubloq, 0) > 0;
				Raise_Application_Error(-20101, 'O veículo está bloqueado, cancelando!!!!  Motivo: ' || p_Motivobloq);
		End If;

End;
/
