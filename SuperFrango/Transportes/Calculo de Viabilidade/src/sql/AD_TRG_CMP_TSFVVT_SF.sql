CREATE OR REPLACE Trigger AD_TRG_CMP_TSFVVT_SF
  For Update On Ad_Tsfvvt
  Compound Trigger

  /* 
  * Autor: M. Rangel - 15/06/2018
  * Processo: Viabilidade de Veículos de transporte 
  * Objetivo: Atualizar o valor das despesas variáveis na aba "Despesas"
  */

  t dbms_utility.maxname_array;
  i Pls_Integer;

  /*  Before Statement Is
  Begin
    t.delete;
  End Before Statement;*/

  /*Before Each Row Is
  Begin
    If deleting Then
      If Nvl(:old.Ativo, 'N') = 'S' Then
        Raise_Application_Error(-20105,
                                ad_fnc_formataerro('Lançamentos ativos não podem ser excluídos.'||
																' Cadastre uma nova configuração e ative-a.'));
      End If;
    End If;
  End Before Each Row;*/

  After Each Row Is
  Begin
    -- se atualizando algum desses campos
    -- popula um array para ser usado no after statement
    If updating('VLRCARROCERIA') Or updating('VLRVEICULO') Or updating('VLRIPVA') Or updating('VLRSEGURO') Or
       updating('MEDIAKM') Or updating('VLRCOMBUST') Or updating('DISTANCIAKM') Or updating('FORMAPRECIF') Then
      i := Nvl(t.first, 0);
      i := i + 1;
      t(i) := :new.Numvvt;
    End If;
  
  End After Each Row;

  After Statement Is
  Begin
    If t.first Is Not Null Then
      For z In t.first .. t.last
      Loop
        Begin
          Update ad_tsfdvt dvt Set dvt.dhalter = Sysdate Where dvt.numvvt = t(z);
        Exception
          When Others Then
            Raise_Application_Error(-20105, 'Ocorreu um erro ao recalcular as despesas. <br>' || Sqlerrm);
        End;
        Begin
          Update ad_tsfvvt v
             Set v.vlrkmsaidasug = fc_divide(v.vlrcustovar, v.distanciakm),
                 v.custosugerido = fc_divide(v.vlrtotcusto, v.distanciakm)
           Where numvvt = t(z);
        Exception
          When Others Then
            Raise_Application_Error(-20105, 'Ocorreu um erro ao reacalcular o valor do km sugerido');
        End;
      End Loop;
    Else
      Null;
    End If;
  End After Statement;

End;
/
