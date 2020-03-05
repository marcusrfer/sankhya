Create Or Replace Trigger AD_TRG_CMP_TSFROCC_SF
   For Insert Or Update Or Delete On AD_TSFROCC
   Compound Trigger

   -- Autor: M. Rangel
   -- Processo: Precifica��o de Frete - Roterizador
   -- Objetivo: Valida��es de dados, atualiza��es entre tabelas, 

   Before Each Row Is
      r_vei   tgfvei%Rowtype;
      oc      tgford%Rowtype;
      v_count Int;
   Begin
   
      If Stp_Get_Atualizando Or Nvl(:new.Teste, 'N') = 'S' Then
         Goto fim_update;
      End If;
   
      -- se j� confirmado
      If Nvl(:old.status, 'P') = 'C' Then
         Raise_Application_Error(-20105,
                                 fc_formatahtml(P_MENSAGEM => 'Altera��es n�o permitidas.',
                                                P_MOTIVO => 'Forma��o de carga j� confirmada.',
                                                P_SOLUCAO => 'Reabra a mesma para realizar a altera��o.'));
      End If;
   
      If inserting Then
      
         If :new.codemp Is Not Null And :new.Ordemcarga Is Not Null Then
         
            Begin
               Select *
                 Into oc
                 From tgford
                Where codemp = :new.Codemp
                  And ordemcarga = :new.Ordemcarga;
            
               :new.Dtinic        := oc.dtinic;
               :new.Codveiculo    := oc.codveiculo;
               :new.Codparcorig   := oc.codparcorig;
               :new.Codparctransp := oc.Codparctransp;
            
            Exception
               When Others Then
                  Raise_Application_Error(-20105,
                                          fc_formatahtml_sf(P_MENSAGEM => 'Erro ao buscar os dados para a Ordem de carga',
                                                            P_MOTIVO => 'N�o especificado',
                                                            P_SOLUCAO => 'Entre em contato com o suporte',
                                                            P_ERROR => Sqlerrm));
            End;
         
            -- valida se o parceiro da OC possui coordenadas
            Select Count(*)
              Into v_count
              From tgfpar
             Where codparc = :new.Codparcorig
               And latitude Is Not Null
               And longitude Is Not Null;
         
            If v_count = 0 Then
               Raise_Application_Error(-20105,
                                       fc_formatahtml_sf('Erro ao Inserir Ordem de Carga',
                                                         'O parceiro de Origem n�o possui latitude/longitude informada',
                                                         'Informe as coordenadas no cadastro do parceiro.'));
            End If;
         
         End If;
      
      End If;
   
      If updating Then
      
         -- se est� atualizando o ve�culo ou o parceiro transportador, atualizar os dados na  ordem de carga
         If (updating('CODVEICULO') Or updating('CODPARCTRANSP')) Or updating('CODPARCORIG') And :old.Status != 'C' Then
            Begin
            
               Select * Into r_vei From tgfvei v Where v.codveiculo = :new.Codveiculo;
            
               If Nvl(r_vei.ad_codcat, 0) = 0 Then
                  Raise_Application_Error(-20105,
                                          'O ve�culo n�o possui categoria informada. <br>' ||
                                          'Clique sobre o c�digo do ve�culo para ir para o cadastro do mesmo. ' || '<a href="' ||
                                          ad_fnc_urlskw('TGFVEI', :new.Codveiculo) || '" target="_parent">' ||
                                          '<font color="#FF0000"><b>' || :new.Codveiculo || '</b></font></a>');
               Else
               
                  Update tgford o
                     Set o.codveiculo = :new.Codveiculo, o.codparctransp = r_vei.codparc, o.codparcorig = :new.Codparcorig
                   Where codemp = :new.Codemp
                     And o.ordemcarga = :new.Ordemcarga;
               
                  :new.Codparctransp := r_vei.codparc;
               
               End If;
            
            Exception
               When Others Then
                  Raise_Application_Error(-20105,
                                          fc_formatahtml(Sqlerrm,
                                                         'Erro ao atualizar forma��o de carga para esta OC',
                                                         'Verifique os detalhes do ve�culo, se est�o cadastrados corretamente.'));
            End;
         
         End If;
      
         If Nvl(:new.Libacertopen, 'N') = 'S' Or Nvl(:new.Liberado, 'N') = 'S' Then
            Raise_Application_Error(-20105,
                                    fc_formatahtml(P_MENSAGEM => 'Erro ao atualizar dados do cabe�alho',
                                                   P_MOTIVO => 'Somente forma��es confirmadas podem ser liberadas',
                                                   P_SOLUCAO => 'Confirme a forma��o ou entre em contato com o suporte interno.'));
         End If;
      
         -- se alterando o parceiro de origem, zera toda sequencia
         If :old.Codparcorig != :new.Codparcorig Then
         
            Begin
            
               variaveis_pkg.v_atualizando := True;
            
               Update ad_tsfrocp p Set p.sequencia = 0 Where p.numrocc = :new.Numrocc;
            
               variaveis_pkg.v_atualizando := False;
            
            Exception
               When Others Then
                  Raise_Application_Error(-20105,
                                          ad_fnc_formataerro('Erro ao zerar a sequ�ncia! <br>' || dbms_utility.format_error_stack));
            End;
         End If;
      
      End If;
   
      <<fim_update>>
      Null;
   End Before Each Row;

End AD_TRG_CMP_TSFROCC_SF;
/
