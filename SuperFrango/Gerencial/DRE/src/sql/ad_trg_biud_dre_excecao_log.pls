create or replace trigger ad_trg_biud_dre_excecao_log
  before insert or update or delete on dre_excecoes
  for each row
declare
  host_name varchar2(100);
begin

  select host_name into host_name from v$instance;

  if inserting then
  
    insert into dre_excecoes_log
      (operacao, machine, codusu, dhalter, codexc, descrexc, codemp, codune, codgrupoprod, codprod,
       coduf, tipoexc, tipovlr, formexc, codindpad, vlrperc, dtinclusao, codusuinc, ativo)
    values
      ('INSERT', host_name, stp_get_codusulogado(), sysdate, :new.codexc, :new.descrexc,
       :new.codemp, :new.codune, :new.codgrupoprod, :new.codprod, :new.coduf, :new.tipoexc,
       :new.tipovlr, :new.formexc, :new.codindpad, :new.vlrperc, :new.dtinclusao, :new.codusuinc,
       :new.ativo);
  
  elsif updating then
  
    insert into dre_excecoes_log
      (operacao, machine, codusu, dhalter, codexc, descrexc, codemp, codune, codgrupoprod, codprod,
       coduf, tipoexc, tipovlr, formexc, codindpad, vlrperc, dtinclusao, codusuinc, ativo)
    values
      ('UPDATE NEW VALUES', host_name, stp_get_codusulogado(), sysdate, :new.codexc, :new.descrexc,
       :new.codemp, :new.codune, :new.codgrupoprod, :new.codprod, :new.coduf, :new.tipoexc,
       :new.tipovlr, :new.formexc, :new.codindpad, :new.vlrperc, :new.dtinclusao, :new.codusuinc,
       :new.ativo);
  
    insert into dre_excecoes_log
      (operacao, machine, codusu, dhalter, codexc, descrexc, codemp, codune, codgrupoprod, codprod,
       coduf, tipoexc, tipovlr, formexc, codindpad, vlrperc, dtinclusao, codusuinc, ativo)
    values
      ('UPDATE OLD VALUES', host_name, stp_get_codusulogado(), sysdate, :old.codexc, :old.descrexc,
       :old.codemp, :old.codune, :old.codgrupoprod, :new.codprod, :old.coduf, :old.tipoexc,
       :old.tipovlr, :old.formexc, :old.codindpad, :old.vlrperc, :old.dtinclusao, :old.codusuinc,
       :old.ativo);
  
  elsif deleting then
  
    insert into dre_excecoes_log
      (operacao, machine, codusu, dhalter, codexc, descrexc, codemp, codune, codgrupoprod, codprod,
       coduf, tipoexc, tipovlr, formexc, codindpad, vlrperc, dtinclusao, codusuinc, ativo)
    values
      ('DELETE', host_name, stp_get_codusulogado(), sysdate, :old.codexc, :old.descrexc,
       :old.codemp, :old.codune, :old.codgrupoprod, :old.codprod, :old.coduf, :old.tipoexc,
       :old.tipovlr, :old.formexc, :old.codindpad, :old.vlrperc, :old.dtinclusao, :old.codusuinc,
       :old.ativo);
  
  end if;

end ad_trg_biud_dre_excecao_log;
/
