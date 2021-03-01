create or replace trigger ad_trg_biud_dre_cadindger_log
  before insert or update or delete on dre_cadindger
  for each row
declare
  host_name varchar2(40);
begin
  select host_name
    into host_name
    from v$instance;

  if inserting then
    insert into dre_cadindger_log
      (operacao, machine, codusu, dhalter, codindger, descrindger)
    values
      ('INSERT', host_name, stp_get_codusulogado, sysdate, :new.codindger, :new.descrindger);
  
  elsif updating then
  
    insert into dre_cadindger_log
      (operacao, machine, codusu, dhalter, codindger, descrindger)
    values
      ('UPDATE NEW VALUES', host_name, stp_get_codusulogado, sysdate, :new.codindger, :new.descrindger);
  
    insert into dre_cadindger_log
      (operacao, machine, codusu, dhalter, codindger, descrindger)
    values
      ('UPDATE OLD VALUES', host_name, stp_get_codusulogado, sysdate, :old.codindger, :old.descrindger);
  
  elsif deleting then
  
    insert into dre_cadindger_log
      (operacao, machine, codusu, dhalter, codindger, descrindger)
    values
      ('UPDATE OLD VALUES', host_name, stp_get_codusulogado, sysdate, :old.codindger, :old.descrindger);
  
  end if;

end ad_trg_biud_dre_cadindger_log;
/
