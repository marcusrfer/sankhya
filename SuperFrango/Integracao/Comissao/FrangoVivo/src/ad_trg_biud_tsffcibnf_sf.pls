create or replace trigger ad_trg_biud_tsffcibnf_sf
  before insert or update or delete on ad_tsffcibnf
  for each row

begin
  if stp_get_atualizando then
    return;
  end if;

  if updating then
  
    update ad_tsffci f
       set f.codusualter = stp_get_codusulogado,
           f.dhalter     = sysdate
     where f.numlote = nvl(:old.numlote, :new.numlote);
  
    if :old.nunota is not null and :new.nunota is null then
      update ad_tsffci f
         set f.statusbonif = 'A'
       where f.numlote = nvl(:new.numlote, :old.numlote);
    end if;
  
  end if;

end;
/
