create or replace trigger ad_trg_ad_tgfcab_ligext
  before delete or update on tgfcab
  for each row
--when (old.ad_tela is not null or new.ad_tela is not null)
declare
  i   int := 0;
  lig ad_tblcmf%rowtype;
begin
  /*
  Autor: Marcus Rangel
  Objetivo: desfazer a ligação entre os portais e as telas adicionais personalizadas.
  */

  begin
    select *
      into lig
      from ad_tblcmf
     where nometabdest = 'TGFCAB'
        And (nuchavedest = nvl(:old.nunota, :new.nunota)
        or nuchaveorig = nvl(:old.nunota, :new.nunota));
  exception
    when no_data_found then
      return;
  end;

  if lig.nometaborig is null then
    return;
  end if;

  if updating then
  
    if (:new.statusnota = 'L' and :new.numnota > 0) or updating('STATUSNFE') then
      
      if lig.nometaborig = 'AD_TSFFCI' then
      
        begin
          update ad_tsffcinf n
             set n.numnota    = :new.numnota,
                 n.statusnota = :new.statusnota,
                 n.statusnfe  = :new.statusnfe
           where numlote = lig.nuchaveorig
             and n.nunota = :new.nunota;
        exception
          when others then
            raise;
        end;
      
      elsif lig.nometaborig = 'AD_TSFFCPREF' then
      
        begin
          update ad_tsffcpref r set r.statusnfe = :new.statusnfe where r.nunota = :new.nunota;
        exception
          when others then
            raise;
        end;
      
      end if;
    
    end if;
  
  elsif deleting then
    begin
      delete from ad_tblcmf
       where nuchavedest = :old.nunota
          or nuchaveorig = :old.nunota;
    exception
      when others then
        ad_set.insere_msglog('Erro ao desfazer ligação do NUNOTA ' || :old.nunota);
    end;
  end if;

end;
/
