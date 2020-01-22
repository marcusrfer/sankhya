create or replace trigger ad_trg_biud_tsftcpref_sf
before update on ad_tsftcpref
for each row
declare
  i int;
  e varchar2(4000);
  x exception;
Begin
 
 /*
 ** autor: m. rangel
 ** processo: fechamento comissão integrado postura
 ** objetivo: controle de alterações
 */

  if updating then

  begin
    --verifica se alguma referência está presente 
    -- em algum fechamento recria
     select count(*) 
       into i
     from ad_tsffcr r
    where 1 = 1
     and r.statuslote != 'P'
     and (
     (r.codtabprev = :new.CODTABPOS and r.dreftabprev = :new.dtref)
     or (r.codtabreal = :new.CODTABPOS and r.dreftabreal = :new.dtref)
     );

    if i > 0 then
     e:= 'Valores não podem ser alterados pois existem fechamentos '||
        'que utilizam os valores dessa referência';
     raise x;
    end if;

    -- verifica postura
    select count(*) into i
     from ad_tsffcpref p
    where 1 = 1
     and p.codtabpos = :new.codtabpos
     and p.dtreftab = :new.dtref
     and p.statuslote != 'A';
     
    if i > 0 then
     e:= 'Valores não podem ser alterados pois existem fechamentos '||
        'que utilizam os valores dessa referência';
     raise x;
    end if;

  exception
    when x then
    raise_application_error(-20105, ad_fnc_formataerro(e));
  end;
  end if;


end;
/
