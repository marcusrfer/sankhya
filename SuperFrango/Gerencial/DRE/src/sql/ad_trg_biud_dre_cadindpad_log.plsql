create or replace trigger ad_trg_biud_dre_cadindpad_log
  before insert or update or delete on dre_cadindpad
  for each row
declare
  host_name varchar2(40);
begin

  select host_name
    into host_name
    from v$instance;

  if inserting then
    insert into dre_cadindpad_log
      (operacao, machine, codusu, dhalter, codindpad, descrindpad, ativo, totalizador)
    values
      ('INSERT', host_name, stp_get_codusulogado, sysdate, :new.codindpad, :new.descrindpad, :new.ativo,
       :new.totalizador);
  elsif updating then
  
    insert into dre_cadindpad_log
      (operacao, machine, codusu, dhalter, codindpad, descrindpad, ativo, totalizador)
    values
      ('UPDATE NEW VALUES', host_name, stp_get_codusulogado, sysdate, :new.codindpad, :new.descrindpad, :new.ativo,
       :new.totalizador);
  
    insert into dre_cadindpad_log
      (operacao, machine, codusu, dhalter, codindpad, descrindpad, ativo, totalizador)
    values
      ('UPDATE OLD VALUES', host_name, stp_get_codusulogado, sysdate, :old.codindpad, :old.descrindpad, :old.ativo,
       :old.totalizador);
  
  elsif deleting then
  
    insert into dre_cadindpad_log
      (operacao, machine, codusu, dhalter, codindpad, descrindpad, ativo, totalizador)
    values
      ('UPDATE OLD VALUES', host_name, stp_get_codusulogado, sysdate, :old.codindpad, :old.descrindpad, :old.ativo,
       :old.totalizador);
  
  end if;

end ad_trg_biud_dre_cadindpad_log;
/
