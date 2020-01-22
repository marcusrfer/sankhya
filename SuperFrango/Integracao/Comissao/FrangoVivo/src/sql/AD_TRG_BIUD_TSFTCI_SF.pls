create or replace trigger ad_trg_biud_tsftci_sf
  before update on ad_tsftci
  for each row
declare

  i int;
  e varchar2(4000);

begin
  /*
  ** Autor: m.rangel
  ** processo: comissão do integrado frango vivo
  ** objetivo: impedir alterações 
  */

  if updating then
  
    select count(*)
      into i
      from ad_tsffci f
     where f.tabela = :new.codtab
       and f.codemp = :new.codemp
       and f.statuslote != 'P';
  
    if i > 0 then
      e := 'A tabela não pode ser alterada pois já existem fechamentos ' ||
           'confirmados que utilizam os valores desta tabela';
      raise_application_error(-20105, ad_fnc_formataerro(e));
    end if;
  
  end if;

end;
/
