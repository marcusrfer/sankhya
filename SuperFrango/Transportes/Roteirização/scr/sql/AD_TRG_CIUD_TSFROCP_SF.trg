Create Or Replace Trigger AD_TRG_CIUD_TSFROCP_SF
   For Insert Or Update Or Delete On AD_TSFROCP
   Compound Trigger

   /*
   Autor: M. Rangel
   Processo: Sequenciamento de entrega pela distância entre parceiros
   Objetivo: Inicialmente, é realizar a "limpeza" da tela quando é informada uma OC diferente
             da informada no cabeçalho.
   */

   v_Nunota Number;
   c        ad_tsfrocc%Rowtype;

   Before Each Row Is
   Begin
   
      If Not stp_get_atualizando Then
      
         Begin
            Select * Into c From ad_tsfrocc Where numrocc = Nvl(:old.Numrocc, :new.Numrocc);
         Exception
            When Others Then
               Raise;
         End;
      
         /* If deleting Then
         
           -- obriga a zerar os pedidos antes da exclusão
           If ad_pkg_var.permite_update = False And (:old.ordemcarga > 0 Or c.status = 'P') Then
             Raise_Application_Error(-20105,
                                     ad_fnc_formataerro('Exclusão proibida.<br>' ||
                                                         'Não é permitido excluir os pedidos diretamente da tela. <br>' ||
                                                         'Altere a Ordem de carga para 0, confirme e depois exclua.'));
           End If;
         
         End If;*/
      
         If updating Then
         
            -- se está atualizando e o status do cabeçalho está confirmado, volta o cabeçalho para pendente, obrigando nova confirmação.
            If c.status = 'C' Then
               Raise_Application_Error(-20105, 'Já confirmado');
            End If;
         
            -- se há atualização do número da ordem de carga
            If :new.Ordemcarga = :old.Ordemcarga Then
               Null;
            Else
               -- e a nova é diferente da OC do cabeçalho
               If :new.Ordemcarga != c.ordemcarga Then
                  Begin
                     -- atualiza direto no pedido, para aparecer na pesquisa por OC
                     Dbms_Output.Put_Line(:new.Ordemcarga);
                     Dbms_Output.Put_Line(:new.Nunota);
                     Null;
                     v_nunota := :new.Nunota;
                  
                     Update tgfcab
                        Set ordemcarga = :new.Ordemcarga
                      Where nunota = :new.Nunota
                     --And ordemcarga = 0
                     ;
                  
                     /*If Sql%Rowcount > 0 Then
                       v_nunota := :new.Nunota;
                     End If;*/
                  
                  Exception
                     When Others Then
                        Raise;
                  End;
               End If;
            End If;
         
         End If;
      
         If deleting Then
            Begin
               Update ad_tsfrocc Set dhalter = Sysdate Where numrocc = :old.Numrocc;
            Exception
               When Others Then
                  Raise;
            End;
         End If;
      Else
         Null;
      End If;
   
   End Before Each Row;

   After Statement Is
   Begin
      If v_nunota Is Not Null Then
         Begin
            Null;
            Delete From ad_tsfrocp
             Where numrocc = c.numrocc
               And nunota = v_nunota;
         Exception
            When Others Then
               Raise;
         End;
      End If;
   End After Statement;

End;
/
