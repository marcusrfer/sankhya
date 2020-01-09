create or replace trigger ad_trg_cmp_tsffcibnf_sf
  for insert or update or delete on ad_tsffcibnf
  compound trigger

  --type type_linhas_excluidas is table of number;
  --t type_linhas_excluidas := type_linhas_excluidas();
  --i         int;
  --v_numlote number(10);
  --v_errmsg  varchar2(4000);

  /*before statement is
  begin
    Null;
  end before statement;*/

  /*before each row is
  begin
    null;
  exception
    when others then
      raise;
  end before each row;*/

  after each row is
  begin
  
    update ad_tsffci f
       set f.codusualter = stp_get_codusulogado,
           f.dhalter     = sysdate
     where f.numlote = nvl(:old.numlote, :new.numlote);
  
  end after each row;

  /*after statement is
    v_count integer;
  begin
    select count(*) into v_count from ad_tsffcibnf where numlote = v_numlote;
    if v_count = t.count then
      update ad_tsffci f set f.statusbonif = 'A' where numlote = v_numlote;
    end if;
  
    <<fim_da_linha>>
    null;
  
  end after statement;*/

end;
/
