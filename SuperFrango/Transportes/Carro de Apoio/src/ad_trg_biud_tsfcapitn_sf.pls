create or replace trigger ad_trg_biud_tsfcapitn_sf
  before insert or update or delete on ad_tsfcapitn
  for each row
declare
  v_status varchar2(10);
  errmsg   varchar2(4000);
  error exception;
begin

  /*
  * Processo: carro de apoio
  * autor: m. rangel
  * objetivo: validação de regras relacionadas ao itinerario
  */

  if (stp_get_atualizando) then
    return;
  end if;

  if inserting or updating or deleting then
  
    select c.status
      into v_status
      from ad_tsfcapsol c
     where c.nucapsol = nvl(:new.nucapsol, :old.nucapsol);
  
    if v_status in ('E', 'A', 'R', 'C') then
      errmsg := 'lançamentos já enviados/aguardando/realizados/cancelados não podem ser alterados.';
      raise error;
    end if;
  
    begin
      update ad_tsfcapsol c
         set c.dhalter = sysdate
       where c.nucapsol = nvl(:new.nucapsol, :old.nucapsol);
    exception
      when others then
        raise;
    end;
  
  end if;

exception
  when error then
    raise_application_error(-20105, ad_fnc_formataerro(errmsg));
end;
/
