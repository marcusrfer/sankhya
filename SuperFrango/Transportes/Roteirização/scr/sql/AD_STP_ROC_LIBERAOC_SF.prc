Create Or Replace Procedure "AD_STP_ROC_LIBERAOC_SF"(p_codusu Number,
                                                     p_idsessao Varchar2,
                                                     p_qtdlinhas Number,
                                                     p_mensagem Out Varchar2) As
   r          ad_tsfrocc%Rowtype;
   v_libcarg  Varchar2(1);
   v_libacert Varchar2(1);

Begin

   /* 
   * Autor: M. Rangel
   * Processo: Sequencia por dist�ncia
   * Objetivo: A��o "Liberar" na tela de form. carga (seq dist). Existem outras regras de neg�cio que impedem a altera��o dos
     campos de libera��o no momento da confirma��o, ent�o foi criada essa a��o para ap�s a confirma��o, efetuar a libera��o 
     da ordem de carga.
   */

   For i In 1 .. p_qtdlinhas
   Loop
      r.numrocc := act_int_field(p_idsessao, i, 'NUMROCC');
   
      Begin
         Select * Into r From ad_tsfrocc Where numrocc = r.numrocc;
      Exception
         When no_data_found Then
            p_mensagem := 'N�o foram encontrados';
      End;
   
      If r.status != 'C' Then
         p_mensagem := 'Somente Ordens de Cargas confirmadas podem ser liberadas!';
         Return;
      End If;
   
      If act_escolher_simnao(P_TITULO => 'Libera��es Ordem de Carga',
                             P_TEXTO => 'Deseja liberar a ordem de carga ' || r.ordemcarga || ' para <b>Carregamento</b>?',
                             P_CHAVE => p_idsessao,
                             P_SEQUENCIA => 1) = 'S' Then
         v_libcarg := 'S';
      Else
         v_libcarg := 'N';
      End If;
   
      If act_escolher_simnao(P_TITULO => 'Libera��es Ordem de Carga',
                             P_TEXTO => 'Deseja liberar a ordem de carga ' || r.ordemcarga ||
                                        ' se a mesma possuir <b>Acertos Pendentes</b>?',
                             P_CHAVE => p_idsessao,
                             P_SEQUENCIA => 2) = 'S' Then
         v_libacert := 'S';
      Else
         v_libacert := 'N';
      End If;
   
      Begin
         Update tgford
            Set ad_liberado = v_libcarg, ad_libacertopen = v_libacert
          Where codemp = r.codemp
            And ordemcarga = r.ordemcarga;
      Exception
         When Others Then
            p_mensagem := 'Erro ao atualizar dados na Ordem de Carga. <br>' || Sqlerrm;
            Return;
      End;
   
      Begin
         variaveis_pkg.v_atualizando := True;
      
         Update ad_tsfrocc Set liberado = v_libcarg, libacertopen = v_libacert Where numrocc = r.numrocc;
      Exception
         When Others Then
            p_mensagem := 'Erro ao atualizar dados no cabe�alho do sequenciamento. <br>' || Sqlerrm;
      End;
   
   End Loop;

   p_mensagem := 'A��o realizada com sucesso!!!';

End;
/
