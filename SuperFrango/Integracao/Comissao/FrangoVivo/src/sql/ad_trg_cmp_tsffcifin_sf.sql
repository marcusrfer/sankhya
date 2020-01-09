create or replace trigger ad_trg_cmp_tsffcifin_sf
 for insert or update or delete on ad_tsffcifin
 compound trigger

 conf   ad_tsffciconf%rowtype;
 modelo ad_tsfmgn%rowtype;

 before each row is
  v_atualiza boolean default false;
  i         int;
 begin
  -- preenchendo a data de 
  if updating('DTVENC') and :new.origem = 'COM' then
  
   -- busca a top da configura��o    
   ad_pkg_fci.get_config(trunc(sysdate), conf);
  
   select * into modelo from ad_tsfmgn where numodelo = conf.numodcpafrv;
  
   -- verifica se a nota de compra j� foi gerada
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
  end if;
 
  if v_atualiza then
   begin
    update ad_tsffci f
       set f.codusualter = stp_get_codusulogado,
           f.dhalter     = sysdate
     where numlote = nvl(:old.numlote, :new.numlote);
   exception
    when others then
     ad_pkg_var.errmsg := 'Erro ao atulizar a data de altera��o na tela principal. ' || sqlerrm;
     raise_application_error(-20105, ad_fnc_formataerro(ad_pkg_var.errmsg));
   end;
  end if;
 
 exception
  when others then
   raise;
 end before each row;

end;
/
