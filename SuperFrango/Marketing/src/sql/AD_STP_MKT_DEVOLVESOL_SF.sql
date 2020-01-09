Create Or Replace Procedure "AD_STP_MKT_DEVOLVESOL_SF"(p_codusu Number,
                                                       p_idsessao Varchar2,
                                                       p_qtdlinhas Number,
                                                       p_mensagem Out Varchar2) As
   p_motivo Varchar2(4000);
   msg      Clob;
   c        ad_tsfcmkt%Rowtype;
   s        ad_tsfsmkt%Rowtype;
Begin
   /* 
   * Dt. Criação:  26/03/2019
   * Autor: M. Rangel
   * Processo: Solicitação de Material de Marketing
   * Objetivo: Efetuar a devolução para o solicitante verificar possíveis problemas e realizar o registro dos fatos.
   */

   p_motivo := act_txt_param(p_idsessao, 'MOTIVO');

   If p_qtdlinhas > 1 Then
   
      --confirma se mesmo motivo para vários lanctos
      If act_confirmar('Briefings selecionados',
                       'Mais de um briefing foi selecionado, deseja devolver todos com o mesmo motivo?',
                       p_idsessao,
                       1) Then
         Null;
      Else
         Return;
      End If;
   End If;

   For i In 1 .. p_qtdlinhas
   Loop
      c.nucmkt := act_int_field(p_idsessao, i, 'NUCMKT');
      Select * Into c From ad_tsfcmkt Where nucmkt = c.nucmkt;
      Select * Into s From ad_tsfsmkt Where nusmkt = c.nusmkt;
   
      --atualiza o rgistro na central   
      Begin
         Update ad_tsfcmkt Set status = 'C' Where nucmkt = c.nucmkt;
      Exception
         When Others Then
            Raise;
      End;
   
      --atualiza a solicitação
      Begin
         Update ad_tsfsmkt
            Set detagencia = detagencia || Chr(13) || To_Char(Sysdate, 'dd/mm/yyyy hh24:mi:ss') ||
                             ' - Devolvido para revisão - Motivo: ' || p_motivo
          Where nusmkt = s.nusmkt;
      Exception
         When Others Then
            Raise;
      End;
   
      --insere a interação
      Declare
         v_nuimkt Number;
      Begin
      
         Select Nvl(Max(nuimkt), 0) + 1 Into v_nuimkt From ad_tsfimkt Where nucmkt = c.nucmkt;
      
         Insert Into ad_tsfimkt
            (nucmkt, nuimkt, dhcontato, codusuint, contato, ocorrencia, status)
         Values
            (c.nucmkt, v_nuimkt, Sysdate, p_codusu, 'S', 'Devolução do briefing para correção.', 'C');
      Exception
         When Others Then
            Raise;
      End;
   
      --notifica solicitante
      ad_set.Ins_Avisosistema(p_Titulo => 'Briefing Devolvido',
                              p_Descricao => 'O briefing ' || c.nusmkt || ' foi devolvido.',
                              p_Solucao => 'Motivo: ' || p_motivo,
                              p_Usurem => p_codusu,
                              p_Usudest => s.codususol,
                              p_Prioridade => 1,
                              p_Tabela => 'AD_TSFSMKT',
                              p_Nrounico => s.nusmkt,
                              p_Erro => p_mensagem);
   
      If p_mensagem Is Not Null Then
         Return;
      End If;
   
      --send mail solicitante
      Begin
         msg := Null;
         dbms_lob.createtemporary(msg, True);
         dbms_lob.append(msg, '<!DOCTYPE html>');
         dbms_lob.append(msg, '<head><meta meta http-equiv="content-language" content="pt-br">');
         dbms_lob.append(msg, '<meta http-equiv="content-type" content="text/html; charset=iso-8859-1"></head>');
         dbms_lob.append(msg, '<body>');
         dbms_lob.append(msg, 'Olá, ' || ad_get.Nomeusu(s.codususol, 'completo') || '<br>');
         dbms_lob.append(msg, 'O Briefing ' || s.nusmkt || ' foi devolvido em ');
         dbms_lob.append(msg, To_Char(Sysdate, 'dd/mm/yyyy hh24:mi:ss'));
         dbms_lob.append(msg, ' por ' || ad_get.Nomeusu(p_codusu, 'resumido'));
         dbms_lob.append(msg, '<br>pelo seguinte motivo: ' || p_motivo || '.');
         dbms_lob.append(msg, '<br><br>');
         dbms_lob.append(msg, '<p>Para maiores informações, clique ');
         dbms_lob.append(msg, '<a href="');
         dbms_lob.append(msg, ad_fnc_urlskw('AD_TSFSMKT', S.NUSMKT, Null, Null));
         dbms_lob.append(msg, '"> AQUI </a></p>');
         dbms_lob.append(msg, '</body>');
         dbms_lob.append(msg, '</html>');
      
         ad_stp_gravafilabi(p_Assunto => 'Devolução de Briefing para correção.',
                            p_Mensagem => msg,
                            p_Email => ad_get.Mailusu(s.codususol));
      End;
   End Loop;

   p_mensagem := 'Briefing devolvido para correção!';

End;
/
