Create Or Replace Procedure "AD_STP_ROC_UPDREGFRE_SF"(p_codusu Number,
                                                      p_idsessao Varchar2,
                                                      p_qtdlinhas Number,
                                                      p_mensagem Out Nocopy Varchar2) As
   p_codregfre Varchar2(4000);
   v_numrocc   Number;
   v_numrocp   Number;
Begin
   /*
   ** Autor: M. Rangel
   ** Processo: Sequenciamento geografico de ordem de cargas
   ** Objetivo: Ação "Alterar Região de Frete" na tela de Form. Carga (seq distancia)
   */
   p_codregfre := act_txt_param(p_idsessao, 'CODREGFRE');

   v_numrocc := act_int_field(p_idsessao, 1, 'NUMROCC');
   --v_numrocp   := act_int_field(p_idsessao,i,'NUMROCP');

   Begin
      Update ad_tsfrocp Set codregfre = To_Number(p_codregfre) Where numrocc = v_numrocc;
   Exception
      When Others Then
         p_mensagem := 'Erro ao atualizar as regiões de Frete. ' || Chr(13) || Sqlerrm;
         Return;
   End;

   p_mensagem := 'Regiões atualizadas com sucesso!!!';

End;
/
