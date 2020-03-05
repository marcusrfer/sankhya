Create Or Replace Procedure "AD_STP_ROC_REJEITASEQ_SF"(p_codusu Number,
                                                       p_idsessao Varchar2,
                                                       p_qtdlinhas Number,
                                                       p_mensagem Out Varchar2) As
   p_qtdmin Number;
   r        ad_tsfrocc%Rowtype;
Begin
   /* 
   Autor: M. Rangel
   Processo: Sequencia por distancia
   Objetivo: Simular o botão rejeitar da tela de formação de carga nativa
   */

   If p_qtdlinhas > 0 Then
      p_mensagem := 'Não é possível selecionar mais de 1 OC!';
      Return;
   End If;

   p_qtdmin := act_int_param(p_idsessao, 'QTDMIN');

   r.numrocc := act_int_field(p_idsessao, 1, 'NUMROCC');

   For c_roc In (Select * From ad_tsfrocp As Of Timestamp(Sysdate - 15 / 60 / 24) Where numrocc = r.numrocc)
   Loop
   
      Begin
         Update ad_tsfrocp
            Set ordemcarga = c_roc.ordemcarga, sequencia = c_roc.sequencia
          Where numrocc = c_roc.numrocc
            And nunota = c_roc.nunota;
      Exception
         When Others Then
            p_mensagem := 'Erro ao recuperar dados do registro de número único ' || c_roc.nunota || '. <br>' || Sqlerrm;
            Return;
      End;
   
   End Loop;

   p_mensagem := 'Dados restaurados com sucesso!!!';

End;
/
