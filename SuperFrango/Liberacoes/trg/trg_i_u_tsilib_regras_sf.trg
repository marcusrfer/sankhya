Create or replace Trigger Trg_i_u_tsilib_regras_sf
   Before Insert Or Update On Sankhya.Tsilib
   Referencing New As New Old As Old
   For Each Row
Declare
   p_Assunto     Varchar2(200);
   p_Codusu      Int;
   p_Codusuinc   Int;
   p_Nomeparc    Varchar2(100);
   p_Count       Int;
   p_Email       Tsiusu.Email%Type;
   p_Email_Envia Varchar(4000);
   p_Nuaviso     Int;
   p_Msg         Clob;
   p_Motivo      Varchar2(400);
   p_Saudacao    Varchar(100);

   p_Testando Boolean := False;

   v_Count Number;

   Pragma Autonomous_Transaction;

Begin
   --RETURN;
   /***** Informaçãoes Importantes ******
   Criada Por  : Ricardo Soares De Oliveira - Consultor Sankhya
   Data Criação: 15/10/2015
   Objetivo    : A) Não Uso Isso Esse Gatilho É Muito Importante Pois É Ele Quem Gerencia A Sequencia Da Tsilib Nos Eventos Relativos As 
                    Regras De Negócio Solicitadas Durante A Confirmação De Pedidos / Notas. Se Não Incluirmos Sequencia
                    Na Tsilib Cada Evento Solicitará A Liberação Apenas Do Primeiro Liberador E Depois Vai Pensar 
                    Que Não Existe Mais Liberação Pendente.
                 B) Tops Envolvidas
                    Requisicao
                    Evento 1000 - Regra 02 - Aprovação Adiantamento
                    Evento 1001 - Regra 01 - Aprova Urgência Adiantamento
                    
                C) Inserir Ad_Codusulib=Codusulib, Isso Vai Ser Importante Para Ser Utilizado Quando O Usuário For Suplente
                D) Se A Solicitação Foi Reprovada Avisa O Parceiro
   
   Alterado   : Ricardo Soares
   Data       : 30/11/2016
   Objetivo   : E) Se Evento 1015 Envia E-Mail Para Solicitante
   
   Alterado   : Ricardo Soares
   Data       : 09/01/2017
   Objetivo   : F) Se Evento 1015 Envia E-Mail Para Solicitante
   
   Alterado   : Ricardo Soares
   Data       : 31/01/2018
   Objetivo   : G) Se evento 1001 verifica se o título não esta vencido antes de fazer a aprovação
   
   Alterado   : Ricardo Soares
   Data       : 16/08/2018
   Objetivo   : H) Se reprovado evento 1046 envia mensagem para usuário da inclusão
   
   */

   -- Item G - Inicio
   If Updating('DHLIB') And :New.Dhlib Is Not Null And :New.Evento = 1001 Then
      Select Count(*)
        Into v_Count
        From Tgffin f
       Where ((:New.Nuchave = f.Nufin And :New.Tabela = 'TGFFIN') Or
             (:New.Nuchave = f.Nunota And :New.Tabela = 'TGFCAB'))
         And f.Provisao = 'S'
         And f.Dtvenc < Trunc(Sysdate);
   
      If v_Count > 0 Then
         Raise_Application_Error(-20101, 'Vencimento inferior à data atual! Ajustes antes de fazer a aprovação.');
      End If;
   
   End If;

   -- Item G Fim
   ----Item C
   If :New.Codusulib > 0 And Nvl(:New.Ad_Codusulib, 0) = 0 And :New.Evento Not In (1026, 1029) Then
      :New.Ad_Codusulib := :New.Codusulib;
      --:New.Nurng        := NULL; -- Ricardo Soares em 20/06/2017 - Se esse valor estiver preenchido não consegue usar o conceito de suplência
   End If;

   ----Item D
   If :New.Evento In (1000, 1001, 1002, 1003, 1004, 1005, 1006, 1007, 1008, 1009) And Updating('REPROVADO') And
      :New.Reprovado = 'S' Then
   
      -- Pega O Email Do Parceiro
      Select p.Email,
             c.Codusuinc
        Into p_Email,
             p_Codusuinc
        From Tgfcab c,
             Tgfpar p
       Where c.Nunota = :New.Nuchave
         And c.Codparc = p.Codparc;
   
      Case
         When To_Number(To_Char(Sysdate, 'hh24')) < 12 Then
            p_Saudacao := '<b><font size=3>Bom dia!!!!<BR><BR> ';
         
         When To_Number(To_Char(Sysdate, 'hh24')) < 18 Then
            p_Saudacao := '<b><font size=3>Boa tarde!!!!<BR><BR> ';
         Else
            p_Saudacao := '<b><font size=3>Boa noite!!!!<BR><BR> ';
      End Case;
   
      Select Count(*)
        Into p_Count
        From Tgfcab Cab,
             Tsiusu Usu
       Where Cab.Nunota = :New.Nuchave
         And Cab.Codparc = Usu.Codparc;
   
      If p_Count > 0 Then
      
         Select Min(Usu.Codusu)
           Into p_Codusu
           From Tgfcab Cab,
                Tsiusu Usu
          Where Cab.Nunota = :New.Nuchave
            And Cab.Codparc = Usu.Codparc;
      
         Stp_Grava_Fila_Aviso_Sf(:New.Codusulib, p_Codusu,
                                 'Lançamento número único ' || :New.Nuchave || ' negada pelo aprovador!');
      
      End If;
   
      -- Grava No Fila De Aviso  
      Stp_Grava_Fila_Aviso_Sf(:New.Codusulib, 109,
                              'Lançamento número único ' || :New.Nuchave || ' negada pelo aprovador!');
      If :New.Evento Not In (1009) Then
         Stp_Gravafilabi_Sf('Lançamento negado pelo aprovador', Null, Sysdate, 'Pendente', 0, 0,
                            p_Saudacao || '<B>Lançamento no valor de: ' || :New.Vlratual ||
                             ' foi negada pelo aprovador', 'E', 3, p_Email);
         Commit;
      End If;
   
   End If;

   -----Inicio De E
   ----Não pode colocar o Evento 1014, pois o mesmo ja esta sendo gerado na 
   ----procedure STP_REQCART_GERARFIN_SF      
   If Inserting And :New.Evento In (1008, 1009, 1015) And (:New.Evento <> 1014) Then
      Case
         When To_Number(To_Char(Sysdate, 'hh24')) < 12 Then
            p_Saudacao := '<b><font size=3>Bom dia!!!!<BR><BR> ';
         
         When To_Number(To_Char(Sysdate, 'hh24')) < 18 Then
            p_Saudacao := '<b><font size=3>Boa tarde!!!!<BR><BR> ';
         Else
            p_Saudacao := '<b><font size=3>Boa noite!!!!<BR><BR> ';
      End Case;
   
      -- Pega O Email Do Liberador
      For r In (Select u.Email,
                       l.Codusu
                  From Tsiusu u,
                       Tsilim l
                 Where l.Codusu = u.Codusu
                   And l.Evento = :New.Evento
                   And l.Limite >= :New.Vlratual
                   And l.Enviaremail = 'S')
      
      --Envia E-Mail E Grava Na Fila De Aviso A Mensagem Para O Liberador
      Loop
         --                IF Not P_Testando Then
         --                    Exit;
         --                Else
         --                    R.Codusu := 0;
         --                    R.Email  := 'gusttavo.lopes@sankhya.com.br';    
         --                End if;
      
         Stp_Grava_Fila_Aviso_Sf(:New.Codususolicit, r.Codusu,
                                 'Solicitação de aprovação da despesa nr ' || :New.Nuchave || ' aguardando avaliação!');
         Commit;
      
         If :New.Evento Not In (1009) Then
            Stp_Gravafilabi_Sf('Solicitação de aprovação da despesa', Null, Sysdate, 'Pendente', 0, 0,
                               p_Saudacao || '<B>Aprovação do número único: ' || :New.Nuchave ||
                                ' aguardando aprovação', 'E', 3, r.Email);
            Commit;
         
         End If;
      
      End Loop;
   
   End If;

   If Updating('DHLIB') And :New.Dhlib Is Not Null And :New.Evento In (1008, 1009, 1014, 1015) Then
   
      Case
         When To_Number(To_Char(Sysdate, 'hh24')) < 12 Then
            p_Saudacao := '<b><font size=3>Bom dia!!!!<BR><BR> ';
         
         When To_Number(To_Char(Sysdate, 'hh24')) < 18 Then
            p_Saudacao := '<b><font size=3>Boa tarde!!!!<BR><BR> ';
         Else
            p_Saudacao := '<b><font size=3>Boa noite!!!!<BR><BR> ';
      End Case;
   
      -- Pega O Email Do Liberador
      For r In (Select u.Email From Tsiusu u Where u.Codusu = :New.Codususolicit)
      --Envia E-Mail E Grava Na Fila De Aviso A Mensagem Para O Solicitante
      Loop
         --                IF Not P_Testando Then
         --                    Exit;
         --                Else
         --                    R.Email  := 'gusttavo.lopes@sankhya.com.br';    
         --                End if;
      
         Stp_Grava_Fila_Aviso_Sf(:New.Codusulib, :New.Codususolicit, :New.Observacao || ' aprovada');
      
         Stp_Gravafilabi_Sf('Despesa Aprovada', Null, Sysdate, 'Pendente', 0, 0,
                            p_Saudacao || :New.Observacao || ' aprovada em ' || :New.Dhlib, 'E', 3, r.Email);
         Commit;
      End Loop;
   End If;

   /*Inicio de F*/
   If Updating('DHLIB') And :New.Dhlib Is Not Null And :New.Evento In (1016) Then
   
      Update Ad_Itecomisrep
         Set Statusaprovacao = 'P',
             Codusulib       = :New.Codusulib,
             Dhlib           = Sysdate
       Where Nunotalanc = :New.Nuchave;
   
      Update Ad_Cabrecisaovend
         Set Statusaprovacao = 'P',
             Codusu          = :New.Codusulib,
             Dhlib           = Sysdate
       Where Nunota = :New.Nuchave;
      Commit;
   
   End If;
   /*Fim de F*/

   /*Ao liberar esse evento vejo se o título já havia sido conferido, se foi altero ele para ad_conferido = C*/
   If Updating('DHLIB') And :New.Dhlib Is Not Null And :New.Evento = 1027 Then
   
      Select Count(*)
        Into p_Count
        From Tsilib l
       Where l.Nuchave = :New.Nuchave
         And l.Evento In (1026,
                          --Desp. Conferida / Liberada p/ Pagamento
                          1029) --Revisão Conta Bancária Parceiro
         And l.Dhlib Is Not Null;
   
      If p_Count > 0 Then
         Update Tgffin f Set f.Ad_Conferido = 'S' Where Nufin = :New.Nuchave;
      
         Commit;
      End If;
   End If;

   ----Item H
   If :New.Evento In (1046) And Updating('REPROVADO') And :New.Reprovado = 'S' Then
   
      -- Pega O Email Do Parceiro
      Select u.Email,
             c.Codusuinc,
             p.Nomeparc
        Into p_Email,
             p_Codusuinc,
             p_Nomeparc
        From Tgfcab c,
             Tsiusu u,
             Tgfpar p
       Where c.Nunota = :New.Nuchave
         And c.Codusuinc = u.Codusu
         And c.Codparc = p.Codparc;
   
      Case
         When To_Number(To_Char(Sysdate, 'hh24')) < 12 Then
            p_Saudacao := '<b><font size=3>Bom dia!!!!<BR><BR> ';
         
         When To_Number(To_Char(Sysdate, 'hh24')) < 18 Then
            p_Saudacao := '<b><font size=3>Boa tarde!!!!<BR><BR> ';
         Else
            p_Saudacao := '<b><font size=3>Boa noite!!!!<BR><BR> ';
      End Case;
   
      p_Motivo := Case
                     When :New.Obslib Is Not Null Then
                      '<br><br><b>Motivo: </b>' || :New.Obslib
                     Else
                      ''
                  End;
   
      If :New.Evento Not In (1009) Then
         Stp_Gravafilabi_Sf('Solicitação de produtos negada', Null, Sysdate, 'Pendente', 0, 0,
                            p_Saudacao || '<B>O pedido de requisição nr. ' || :New.Nuchave || ' do parceiro ' ||
                             p_Nomeparc || ' foi negada pelo aprovador. ' || p_Motivo, 'E', 3, p_Email);
         Commit;
      End If;
   
   End If;

End;
/
