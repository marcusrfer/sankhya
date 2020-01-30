create or replace trigger ad_trg_biud_tsffcradt_sf
  before insert or update or delete on ad_tsffcradt
  for each row
declare
  e varchar2(4000);
begin
  /*
    Autor: MARCUS.RANGEL 20/12/2019 11:18:00
    Processo: Fechamento de comissão do integrado - Recria
    Objetivo: Validações
  */

  if stp_get_atualizando then
    return;
  end if;

  if updating then
  
    -- permitir alterar o vencimento de adiantamentos pendentes
    if updating('DTVENC') and :new.nuacerto is null then
      return;
    end if;
  
    -- se acerto for desfeito
    if :old.nuacerto is not null and :new.nuacerto is null then
      :new.vlradiant := 0;
    end if;
  
  end if;

  if deleting then
  
    if :old.nuacerto is not null then
      e := ad_fnc_formataerro('Não é possível excluir adiantamentos que já foram gerados');
      raise_application_error(-20105, e);
    end if;
  
  end if;

  -- atualiza a dh alter do mainform em qualquer dml
  begin
    update ad_tsffcr r
       set r.dhalter   = sysdate,
           r.codusualt = stp_get_codusulogado
     where r.codcencus = nvl(:old.codcencus, :new.codcencus)
       and r.codparc = nvl(:old.codparc, :new.codparc)
       and r.numlote = nvl(:old.numlote, :new.numlote)
       and r.sexo = nvl(:old.sexo, :new.sexo);
  exception
    when others then
      e := ad_fnc_formataerro(sqlerrm);
      raise_application_error(-20105, e);
  end;

end ad_trg_biud_tsffcradt_sf;
/
