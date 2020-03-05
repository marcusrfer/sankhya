Create Or Replace Procedure "AD_STP_ROC_ROTAPEDOPC_SF"(p_codusu Number,
                                                       p_idsessao Varchar2,
                                                       p_qtdlinhas Number,
                                                       p_mensagem Out Varchar2) As
   p_acao    Varchar2(4000);
   v_numrocc Number;
   v_numrocp Number;
Begin
   /* 
   * Autor: M. rangel
   * Processo: sequencia de entrega de oc pela distancia
   * Objetivo: realizar ações comuns à operação, botão de ação "Ações Úteis"
   */

   /*
   1=Zerar Ordem de Carga
   2=Atualizar Ordem de Carga
   3=Zerar Sequência
   4=Atualizar Dados de Parceiros
   */

   p_acao := act_txt_param(p_idsessao, 'ACAO');

   If p_qtdlinhas > 1 And p_codusu > 0 Then
      p_mensagem := 'Selecione apenas 1 linha por vez';
   End If;

   For i In 1 .. p_qtdlinhas
   Loop
      v_numrocc := act_int_field(p_idsessao, i, 'NUMROCC');
      v_numrocp := act_int_field(p_idsessao, i, 'NUMROCP');
   
      If V_NUMROCP Is Not Null Then
         If p_acao = '1' Then
            ad_pkg_roc.zera_ordem_carga(v_numrocc, v_numrocp);
         Elsif p_acao = '2' Then
            ad_pkg_roc.atualizar_ordcarga(v_numrocc, v_numrocp);
         Elsif p_acao = '3' Then
            ad_pkg_roc.zera_sequencia_ordcarga(v_numrocc, v_numrocp);
         End If;
      Else
         If p_acao = '1' Then
            ad_pkg_roc.zera_ordem_carga(v_numrocc);
         Elsif p_acao = '2' Then
            ad_pkg_roc.atualizar_ordcarga(v_numrocc);
         Elsif p_acao = '3' Then
            ad_pkg_roc.zera_sequencia_ordcarga(v_numrocc);
         Elsif p_acao = '4' Then
            --ad_pkg_roc.atualiza_dados_parceiros(p_numrocc => v_numrocc);
            ad_pkg_roc.atualiza_dados(v_numrocc, p_mensagem);
         End If;
      End If;
   
      If p_mensagem Is Not Null Then
         Return;
      End If;
   End Loop;

   p_mensagem := 'Ação realizada com sucesso!';

End;
/
