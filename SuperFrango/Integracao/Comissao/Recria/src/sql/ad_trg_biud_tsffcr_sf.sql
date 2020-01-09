create or replace trigger ad_trg_biud_tsffcr_sf
 before insert or update or delete on ad_tsffcr
 for each row
declare
 v_errmsg varchar2(4000);

begin

 /*
   Autor: MARCUS.RANGEL 20/12/2019 11:14:36
   Processo: Fechamento de Comissáo Recria
   Objetivo: Validação exigidas pelo processo
 */

 if stp_get_atualizando then
  return;
 end if;

 /*if inserting then
  null;
 end if;*/

 if Not updating('STATUS') And :old.status != 'P' then
  v_errmsg := 'Somente fechamentos com status "Pendente" pode ser alterado!' || :new.status;
  raise_application_error(-20105, v_errmsg);
 end if;

 /*if deleting then
  null;
 end if;*/

end;
/
