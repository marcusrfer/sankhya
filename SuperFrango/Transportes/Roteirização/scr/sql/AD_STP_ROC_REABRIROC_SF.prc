Create Or Replace Procedure "AD_STP_ROC_REABRIROC_SF"(p_codusu Number,
                                                      p_idsessao Varchar2,
                                                      p_qtdlinhas Number,
                                                      p_mensagem Out Varchar2) As
   r ad_tsfrocc%Rowtype;
   x Int;
Begin
   /* Autor: M. Rangel
   * Processo: Formação de carga
   * Objetivo: Realizar a reabertura para permitir a alteração em formações confirmadas
   */

   variaveis_pkg.v_atualizando := True;

   For i In 1 .. p_qtdlinhas
   Loop
      r.numrocc := act_int_field(p_idsessao, i, 'NUMROCC');
   
      Select * Into r From ad_tsfrocc Where numrocc = r.numrocc;
   
      Select Count(*) Into x From tgfvar v Where v.nunotaorig In (Select p.nunota From ad_tsfrocp p Where p.numrocc = r.numrocc);
   
      If x > 0 And Nvl(r.teste, 'N') = 'N' Then
         p_mensagem := 'Já existem pedidos faturados nesta Ordem de Carga, não é possível reabrir.';
         Return;
      Else
         Begin
            Update ad_tsfrocc Set status = 'P' Where numrocc = r.numrocc;
         Exception
            When Others Then
               Raise;
         End;
      End If;
   
   End Loop;

   p_mensagem := 'Ordem de carga reaberta com sucesso!!!';

End;
/
