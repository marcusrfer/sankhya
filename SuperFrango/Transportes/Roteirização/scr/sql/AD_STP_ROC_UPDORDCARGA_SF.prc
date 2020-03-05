Create Or Replace Procedure "AD_STP_ROC_UPDORDCARGA_SF"(p_codusu Number,
                                                        p_idsessao Varchar2,
                                                        p_qtdlinhas Number,
                                                        p_mensagem Out Varchar2) As

   r            ad_tsfrocp%Rowtype;
   v_OrdemCarga Number;
   x            Int;
Begin

   /* 
   Autor: M. Rangel
   Processo: Sequenciador de Ordem de Carga
   Objetivo: Alterar Ordens de Carga em lote na tela de sequenciamento de entrega, ação "Alterar Ordem de Carga"
   */

   v_OrdemCarga := act_txt_param(p_idsessao, 'NEWORDCARGA');

   For i In 1 .. p_qtdlinhas
   Loop
      r.numrocc := act_int_field(p_idsessao, i, 'NUMROCC');
      r.numrocp := act_int_field(p_idsessao, i, 'NUMROCP');
   
      Begin
         Select *
           Into r
           From ad_tsfrocp
          Where numrocc = r.numrocc
            And numrocp = r.numrocp;
      Exception
         When Others Then
            p_mensagem := 'Erro ao buscar os dados dos pedidos, verifique se algum foi selecionado!';
            Return;
      End;
   
      Begin
         Select Count(*)
           Into x
           From tgford o
          Where o.codemp = r.codemp
            And o.ordemcarga = v_OrdemCarga;
      
         If x = 0 Then
            p_mensagem := 'Ordem de carga não existe com a empresa ' || r.codemp || '.';
            Return;
         End If;
      Exception
         When Others Then
            Raise;
      End;
   
      If stp_get_atualizando Then
         Null;
      Else
         Begin
            Update ad_tsfrocp p
               Set p.ordemcarga = v_OrdemCarga, p.sequencia = 0
             Where numrocc = r.numrocc
               And numrocp = r.numrocp;
         Exception
            When Others Then
               p_mensagem := 'Erro ao atualizar os dados do pedido. ' || Sqlerrm;
               Return;
         End;
      End If;
   
   End Loop;

   p_mensagem := 'Operação realizada com sucesso!';

End;
/
