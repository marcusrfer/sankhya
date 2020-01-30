create or replace trigger ad_trg_cmp_tsffcifin_sf
  for insert or update or delete on ad_tsffcifin
  compound trigger

  conf   ad_tsffciconf%rowtype;
  modelo ad_tsfmgn%rowtype;

  e varchar2(4000);
  i int;

  before each row is
    v_atualiza boolean default false;
  
  begin
    -- quando limpa o nufin da tabela pela FK
    if :old.nufin is not null and :new.nufin is null then
      goto final_trgigger;
    end if;
  
    -- preenchendo a data de vencimento
    if (updating('DTVENC') or updating('VLRDESDOB')) and :new.nufin is not null then
      e := 'Lançamentos com financeiro gerados não podem ser alterados!';
      raise_application_error(-20105, ad_fnc_formataerro(e));
    else
      stp_set_atualizando('S');
      update ad_tsffci f
         set f.codusualter = stp_get_codusulogado,
             f.dhalter     = sysdate
       where numlote = nvl(:old.numlote, :new.numlote);
      stp_set_atualizando('N');
    end if;
  
    /* if updating('DTVENC') and :new.origem = 'COM' then
    
      -- busca a top da configuração    
      ad_pkg_fci.get_config(trunc(sysdate), conf);
    
      select * into modelo from ad_tsfmgn where numodelo = conf.numodcpafrv;
    
      -- verifica se a nota de compra já foi gerada
      select count(*)
        into i
        from ad_tsffcinf n
       where n.numlote = :new.numlote
         and n.codtipoper = modelo.codtipoper;
    
      if i > 0 then
        v_atualiza := true;
      end if;
    
    else
      v_atualiza := true;
    end if;*/
  
    /*if v_atualiza then
      begin
      
      exception
        when others then
          e := 'Erro ao atulizar a data de alteração na tela principal. ' ||
               sqlerrm;
          raise_application_error(-20105, ad_fnc_formataerro(e));
      end;
    end if;*/
  
    <<final_trgigger>>
    null;
  end before each row;

end;
/
