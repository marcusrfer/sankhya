create or replace trigger ad_trg_aiud_tsfvvt_log_sf
  after insert or update or delete on ad_tsfvvt
  for each row
declare
  e varchar2(4000);
begin
  /*
   * Autor: Marcus Rangel
   * Processo: Viabilidade de Veículos
   * Objetivo: Gravar log de alterações dos valores da tabela
  */

  if inserting then
  
    begin
      insert into ad_tsfvvt_log
        (numvvt, dtref, codcat, codparctransp, vlrcarroceria, vlrveiculo, vlrtotbens, vlripva, vlrseguro, mediakm,
         custokm, vlrcombust, distanciakm, qtdviagens, vlrcustofixo, vlrcustovar, vlrtotcusto, lucroliq, txretorno,
         vlrcustotemp, codregfre, custosugerido, vlrsaida, vlrsaidasug, formaprecif, vlrkmsaida, vlrkmsaidasug, dhalter,
         codusu, maquina, operacao, numoper)
      values
        (:new.numvvt, :new.dtref, :new.codcat, :new.codparctransp, :new.vlrcarroceria, :new.vlrveiculo, :new.vlrtotbens,
         :new.vlripva, :new.vlrseguro, :new.mediakm, :new.custokm, :new.vlrcombust, :new.distanciakm, :new.qtdviagens,
         :new.vlrcustofixo, :new.vlrcustovar, :new.vlrtotcusto, :new.lucroliq, :new.txretorno, :new.vlrcustotemp,
         :new.codregfre, :new.custosugerido, :new.vlrsaida, :new.vlrsaidasug, :new.formaprecif, :new.vlrkmsaida,
         :new.vlrkmsaidasug, sysdate, stp_get_codusulogado, ad_get.nomemaquina, 'INCLUSÃO', ad_seq_log_tsfvvt.nextval);
    exception
      when others then
        raise;
    end;
  
  elsif updating then
  
    begin
      insert into ad_tsfvvt_log
        (numvvt, dtref, codcat, codparctransp, vlrcarroceria, vlrveiculo, vlrtotbens, vlripva, vlrseguro, mediakm,
         custokm, vlrcombust, distanciakm, qtdviagens, vlrcustofixo, vlrcustovar, vlrtotcusto, lucroliq, txretorno,
         vlrcustotemp, codregfre, custosugerido, vlrsaida, vlrsaidasug, formaprecif, vlrkmsaida, vlrkmsaidasug, dhalter,
         codusu, maquina, operacao, numoper)
      values
        (:old.numvvt, :old.dtref, :old.codcat, :old.codparctransp, :old.vlrcarroceria, :old.vlrveiculo, :old.vlrtotbens,
         :old.vlripva, :old.vlrseguro, :old.mediakm, :old.custokm, :old.vlrcombust, :old.distanciakm, :old.qtdviagens,
         :old.vlrcustofixo, :old.vlrcustovar, :old.vlrtotcusto, :old.lucroliq, :old.txretorno, :old.vlrcustotemp,
         :old.codregfre, :old.custosugerido, :old.vlrsaida, :old.vlrsaidasug, :old.formaprecif, :old.vlrkmsaida,
         :old.vlrkmsaidasug, sysdate, stp_get_codusulogado, ad_get.nomemaquina, 'UPDATE - VALORES VELHOS',
         ad_seq_log_tsfvvt.nextval);
    
      insert into ad_tsfvvt_log
        (numvvt, dtref, codcat, codparctransp, vlrcarroceria, vlrveiculo, vlrtotbens, vlripva, vlrseguro, mediakm,
         custokm, vlrcombust, distanciakm, qtdviagens, vlrcustofixo, vlrcustovar, vlrtotcusto, lucroliq, txretorno,
         vlrcustotemp, codregfre, custosugerido, vlrsaida, vlrsaidasug, formaprecif, vlrkmsaida, vlrkmsaidasug, dhalter,
         codusu, maquina, operacao, numoper)
      values
        (:new.numvvt, :new.dtref, :new.codcat, :new.codparctransp, :new.vlrcarroceria, :new.vlrveiculo, :new.vlrtotbens,
         :new.vlripva, :new.vlrseguro, :new.mediakm, :new.custokm, :new.vlrcombust, :new.distanciakm, :new.qtdviagens,
         :new.vlrcustofixo, :new.vlrcustovar, :new.vlrtotcusto, :new.lucroliq, :new.txretorno, :new.vlrcustotemp,
         :new.codregfre, :new.custosugerido, :new.vlrsaida, :new.vlrsaidasug, :new.formaprecif, :new.vlrkmsaida,
         :new.vlrkmsaidasug, sysdate, stp_get_codusulogado, ad_get.nomemaquina, 'UPDATE - VALORES NOVOS',
         ad_seq_log_tsfvvt.currval);
    exception
      when others then
        raise;
    end;
  
  elsif deleting then
    if nvl(:old.ativo, 'N') = 'N' and not stp_get_atualizando then
      begin
        insert into ad_tsfvvt_log
          (numvvt, dtref, codcat, codparctransp, vlrcarroceria, vlrveiculo, vlrtotbens, vlripva, vlrseguro, mediakm,
           custokm, vlrcombust, distanciakm, qtdviagens, vlrcustofixo, vlrcustovar, vlrtotcusto, lucroliq, txretorno,
           vlrcustotemp, codregfre, custosugerido, vlrsaida, vlrsaidasug, formaprecif, vlrkmsaida, vlrkmsaidasug,
           dhalter, codusu, maquina, operacao, numoper)
        values
          (:old.numvvt, :old.dtref, :old.codcat, :old.codparctransp, :old.vlrcarroceria, :old.vlrveiculo,
           :old.vlrtotbens, :old.vlripva, :old.vlrseguro, :old.mediakm, :old.custokm, :old.vlrcombust, :old.distanciakm,
           :old.qtdviagens, :old.vlrcustofixo, :old.vlrcustovar, :old.vlrtotcusto, :old.lucroliq, :old.txretorno,
           :old.vlrcustotemp, :old.codregfre, :old.custosugerido, :old.vlrsaida, :old.vlrsaidasug, :old.formaprecif,
           :old.vlrkmsaida, :old.vlrkmsaidasug, sysdate, stp_get_codusulogado, ad_get.nomemaquina, 'EXCLUSÃO',
           ad_seq_log_tsfvvt.nextval);
      exception
        when others then
          raise;
      end;
    else
      e := 'Lançamentos ativos não podem ser excluídos. Cadastre uma nova configuração e ative-a.';
      raise_application_error(-20105, ad_fnc_formataerro(e));
    end if;
  end if;

end;
/
