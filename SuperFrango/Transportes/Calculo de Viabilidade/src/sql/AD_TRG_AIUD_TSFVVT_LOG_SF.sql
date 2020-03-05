Create Or Replace Trigger AD_TRG_AIUD_TSFVVT_LOG_SF
  After Insert Or Update Or Delete On ad_tsfvvt
  For Each Row
Begin
  /*
   * Autor: Marcus Rangel
   * Processo: Viabilidade de Veículos
   * Objetivo: Gravar log de alterações dos valores da tabela
  */

  If inserting Then
  
    Begin
      Insert Into ad_tsfvvt_log
        (numvvt, dtref, codcat, codparctransp, vlrcarroceria, vlrveiculo, vlrtotbens, vlripva, vlrseguro, mediakm,
         custokm, vlrcombust, distanciakm, qtdviagens, vlrcustofixo, vlrcustovar, vlrtotcusto, lucroliq, txretorno,
         vlrcustotemp, codregfre, custosugerido, vlrsaida, vlrsaidasug, formaprecif, vlrkmsaida, vlrkmsaidasug, dhalter,
         codusu, maquina, operacao, numoper)
      Values
        (:new.numvvt, :new.dtref, :new.codcat, :new.codparctransp, :new.vlrcarroceria, :new.vlrveiculo, :new.vlrtotbens,
         :new.vlripva, :new.vlrseguro, :new.mediakm, :new.custokm, :new.vlrcombust, :new.distanciakm, :new.qtdviagens,
         :new.vlrcustofixo, :new.vlrcustovar, :new.vlrtotcusto, :new.lucroliq, :new.txretorno, :new.vlrcustotemp,
         :new.codregfre, :new.custosugerido, :new.vlrsaida, :new.vlrsaidasug, :new.formaprecif, :new.vlrkmsaida,
         :new.vlrkmsaidasug, Sysdate, stp_get_codusulogado, ad_get.nomemaquina, 'INCLUSÃO', AD_SEQ_LOG_TSFVVT.Nextval);
    Exception
      When Others Then
        Raise;
    End;
  
  Elsif updating Then
  
    Begin
      Insert Into ad_tsfvvt_log
        (numvvt, dtref, codcat, codparctransp, vlrcarroceria, vlrveiculo, vlrtotbens, vlripva, vlrseguro, mediakm,
         custokm, vlrcombust, distanciakm, qtdviagens, vlrcustofixo, vlrcustovar, vlrtotcusto, lucroliq, txretorno,
         vlrcustotemp, codregfre, custosugerido, vlrsaida, vlrsaidasug, formaprecif, vlrkmsaida, vlrkmsaidasug, dhalter,
         codusu, maquina, operacao, numoper)
      Values
        (:old.numvvt, :old.dtref, :old.codcat, :old.codparctransp, :old.vlrcarroceria, :old.vlrveiculo, :old.vlrtotbens,
         :old.vlripva, :old.vlrseguro, :old.mediakm, :old.custokm, :old.vlrcombust, :old.distanciakm, :old.qtdviagens,
         :old.vlrcustofixo, :old.vlrcustovar, :old.vlrtotcusto, :old.lucroliq, :old.txretorno, :old.vlrcustotemp,
         :old.codregfre, :old.custosugerido, :old.vlrsaida, :old.vlrsaidasug, :old.formaprecif, :old.vlrkmsaida,
         :old.vlrkmsaidasug, Sysdate, stp_get_codusulogado, ad_get.nomemaquina, 'UPDATE - VALORES VELHOS',
         AD_SEQ_LOG_TSFVVT.Nextval);
    
      Insert Into ad_tsfvvt_log
        (numvvt, dtref, codcat, codparctransp, vlrcarroceria, vlrveiculo, vlrtotbens, vlripva, vlrseguro, mediakm,
         custokm, vlrcombust, distanciakm, qtdviagens, vlrcustofixo, vlrcustovar, vlrtotcusto, lucroliq, txretorno,
         vlrcustotemp, codregfre, custosugerido, vlrsaida, vlrsaidasug, formaprecif, vlrkmsaida, vlrkmsaidasug, dhalter,
         codusu, maquina, operacao, numoper)
      Values
        (:new.numvvt, :new.dtref, :new.codcat, :new.codparctransp, :new.vlrcarroceria, :new.vlrveiculo, :new.vlrtotbens,
         :new.vlripva, :new.vlrseguro, :new.mediakm, :new.custokm, :new.vlrcombust, :new.distanciakm, :new.qtdviagens,
         :new.vlrcustofixo, :new.vlrcustovar, :new.vlrtotcusto, :new.lucroliq, :new.txretorno, :new.vlrcustotemp,
         :new.codregfre, :new.custosugerido, :new.vlrsaida, :new.vlrsaidasug, :new.formaprecif, :new.vlrkmsaida,
         :new.vlrkmsaidasug, Sysdate, stp_get_codusulogado, ad_get.nomemaquina, 'UPDATE - VALORES NOVOS',
         AD_SEQ_LOG_TSFVVT.Currval);
    Exception
      When Others Then
        Raise;
    End;
  
  Elsif deleting Then
    If Nvl(:old.Ativo, 'N') = 'N' Then
      Begin
        Insert Into ad_tsfvvt_log
          (numvvt, dtref, codcat, codparctransp, vlrcarroceria, vlrveiculo, vlrtotbens, vlripva, vlrseguro, mediakm,
           custokm, vlrcombust, distanciakm, qtdviagens, vlrcustofixo, vlrcustovar, vlrtotcusto, lucroliq, txretorno,
           vlrcustotemp, codregfre, custosugerido, vlrsaida, vlrsaidasug, formaprecif, vlrkmsaida, vlrkmsaidasug,
           dhalter, codusu, maquina, operacao, numoper)
        Values
          (:old.numvvt, :old.dtref, :old.codcat, :old.codparctransp, :old.vlrcarroceria, :old.vlrveiculo,
           :old.vlrtotbens, :old.vlripva, :old.vlrseguro, :old.mediakm, :old.custokm, :old.vlrcombust, :old.distanciakm,
           :old.qtdviagens, :old.vlrcustofixo, :old.vlrcustovar, :old.vlrtotcusto, :old.lucroliq, :old.txretorno,
           :old.vlrcustotemp, :old.codregfre, :old.custosugerido, :old.vlrsaida, :old.vlrsaidasug, :old.formaprecif,
           :old.vlrkmsaida, :old.vlrkmsaidasug, Sysdate, stp_get_codusulogado, ad_get.nomemaquina, 'EXCLUSÃO',
           AD_SEQ_LOG_TSFVVT.Nextval);
      Exception
        When Others Then
          Raise;
      End;
    Else
      Raise_Application_Error(-20105,
                              ad_fnc_formataerro('Lançamentos ativos não podem ser excluídos. Cadastre uma nova configuração e ative-a.'));
    End If;
  End If;

End;
/
