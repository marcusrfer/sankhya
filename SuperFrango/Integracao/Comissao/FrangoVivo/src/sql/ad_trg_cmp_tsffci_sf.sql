create or replace trigger ad_trg_cmp_tsffci_sf
  for insert or update or delete on ad_tsffci
  compound trigger

  i        int;
  v_errmsg varchar2(4000);

  /*before statement is
  begin
    null;
  end before statement;*/

  before each row is
  begin
  
    if inserting then
      null;
    elsif updating then
    
      if (:old.statuslote = :new.statuslote) and :new.statuslote in ('F', 'L') and
         not variaveis_pkg.v_atualizando then
        v_errmsg := 'Lotes <b>"Finalizados"</b> ou <b>"Em faturamento"</b> não podem ser editados';
        raise_application_error(-20105, ad_fnc_formataerro(v_errmsg));
      end if;
    
      -- atualiza status bonificação quando nota confirmada    
      if :old.statusbonif = 'F' then
        select count(*)
          into i
          from ad_tsffcibnf b
          join ad_tsffcinf n
            on b.nunota = n.nunota
         where n.statusnota = 'L';
      
        if i > 0 then
          :new.statusbonif := 'L';
        end if;
      
      end if;
    
      if :old.statuslote = 'F' then
        select count(*)
          into i
          from ad_tsffcinf n
         where n.codtipoper in (152, 329, 401,365)
           and n.statusnota != 'L';
      
        if i = 4 then
          :new.statuslote := 'L';
        end if;
      end if;
    
    elsif deleting then
    
      if :old.statuslote in ('F', 'L') then
        v_errmsg := 'Lotes <b>"Finalizados"</b> ou <b>"Em faturamento"</b> não podem ser editados';
        raise_application_error(-20105, ad_fnc_formataerro(v_errmsg));
      end if;
    
    end if;
  
  end before each row;

  /*After each row is
  begin
    if inserting then
      null;
    elsif updating then
      null;
    elsif deleting then
      null;
    end if;
  end After each row;*/

  /*After Statement
  Is
  Begin
    Null;
  End After Statement;*/

end;
/
