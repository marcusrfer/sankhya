create or replace trigger ad_trg_biud_tsffcr_sf
  before insert or update or delete on ad_tsffcr
  for each row
declare
  e varchar2(4000);

begin

  /*
    Autor: MARCUS.RANGEL 20/12/2019 11:14:36
    Processo: Fechamento de Comissáo Recria
    Objetivo: Validação exigidas pelo processo
  */

  if stp_get_atualizando then
    return;
  end if;

  /*if inserting then
   null;
  end if;*/
  if updating then
  
    -- se alterando e o status continua diferente de pendente
    if :old.status != 'P' and :new.status != 'P' then
      e := ad_fnc_formataerro('Somente fechamentos com status ' ||
                              '"Pendente" podem ser alterados!');
      raise_application_error(-20105, e);
    end if;
  
    -- se limpando o nunota da tela (fk da tgfcab)
    if :old.nunota is not null and :new.nunota is null then
      :new.status := 'A';
    end if;
  
  end if;

  if deleting then
  
    if :old.status != 'P' then
      e := ad_fnc_formataerro('Somente fechamentos com status ' ||
                              '"Pendente" podem ser excluídos!');
      raise_application_error(-20105, e);
    end if;
  
  end if;

end;
/
