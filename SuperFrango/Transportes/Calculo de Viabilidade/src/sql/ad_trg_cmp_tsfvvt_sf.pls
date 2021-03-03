create or replace trigger ad_trg_cmp_tsfvvt_sf
  for update on ad_tsfvvt
  compound trigger

  /* 
  * Autor: M. Rangel - 15/06/2018
  * Processo: Viabilidade de Veículos de transporte 
  * Objetivo: Atualizar o valor das despesas variáveis na aba "Despesas"
  */

  t dbms_utility.maxname_array;
  i pls_integer;
  e varchar2(4000);

  /*  Before Statement Is
  Begin
    t.delete;
  End Before Statement;*/

  before each row is
  begin
  
    if stp_get_atualizando then
      goto end_trigger;
    end if;
  
    if updating then
      if (updating('CODREGFRE') or updating('DTREF') or updating('CODCAT') or updating('DHVIGOR')) and
         (:old.ativo = 'S') then
        e := 'Lançamentos Ativos não podem ter os campos ' ||
             '<b>REGIÃO DE FRETE</b>, <b>DT. REFERÊNCIA</b>, <b>CATEGORIA</b> ou <b:DH. VIGOR</b> alterados';
        raise_application_error(-20105, ad_fnc_formataerro(e));
      end if;
    end if;
  
    if deleting then
      if nvl(:old.ativo, 'N') = 'S' then
        e := 'Lançamentos ativos não podem ser excluídos. ' || 'Cadastre uma nova configuração e ative-a.';
        raise_application_error(-20105, ad_fnc_formataerro(e));
      end if;
    end if;
  
    <<end_trigger>>
    null;
  end before each row;

  after each row is
  begin
  
    if stp_get_atualizando then
      goto end_after;
    end if;
    -- se atualizando algum desses campos
    -- popula um array para ser usado no after statement
    if updating('VLRCARROCERIA') or updating('VLRVEICULO') or updating('VLRIPVA') or updating('VLRSEGURO') or
       updating('MEDIAKM') or updating('VLRCOMBUST') or updating('DISTANCIAKM') or updating('FORMAPRECIF') then
      i := nvl(t.first, 0);
      i := i + 1;
      t(i) := :new.numvvt;
    end if;
    <<end_after>>
    null;
  end after each row;

  after statement is
  begin
    if t.first is not null then
      for z in t.first .. t.last
      loop
        begin
          update ad_tsfdvt dvt
             set dvt.dhalter = sysdate
           where dvt.numvvt = t(z);
        exception
          when others then
            raise_application_error(-20105, 'Ocorreu um erro ao recalcular as despesas. <br>' || sqlerrm);
        end;
        begin
          update ad_tsfvvt v
             set v.vlrkmsaidasug = fc_divide(v.vlrcustovar, v.distanciakm),
                 v.custosugerido = fc_divide(v.vlrtotcusto, v.distanciakm)
           where numvvt = t(z);
        exception
          when others then
            raise_application_error(-20105, 'Ocorreu um erro ao reacalcular o valor do km sugerido');
        end;
      end loop;
    else
      null;
    end if;
  end after statement;

end;
/
