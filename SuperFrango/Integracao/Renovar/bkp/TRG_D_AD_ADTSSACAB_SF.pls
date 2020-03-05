CREATE OR REPLACE TRIGGER "TRG_D_AD_ADTSSACAB_SF"
   For Delete On Ad_Adtssacab
   Compound Trigger

   Before Each Row Is

   Begin

      If Deleting And Nvl(:Old.Nuacerto, 0) > 0 Then

         Raise_Application_Error(-20101,
                                 Fc_Formatahtml_Sf('Exclusão não permitida',
                                                    'Adiantamento já gerado, a exclusão do registro não é permitida',
                                                    'Reabra a solicitação!'));
      End If;

   End Before Each Row;

End Trg_d_Ad_Adtssacab_Sf;
/
