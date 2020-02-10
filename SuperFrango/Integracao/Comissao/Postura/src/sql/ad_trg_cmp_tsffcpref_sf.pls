create or replace trigger ad_trg_cmp_tsffcpref_sf
  for insert or update or delete on ad_tsffcpref
  compound trigger

  before each row is
    e  varchar2(4000);
    cd int := 5;
  begin
  
    if inserting then
    
      if not stp_get_atualizando then
        e := 'Utilize o bot�o de a��o "Buscar Dados" para ' ||
             'inserir dados nesse formul�rio';
        raise_application_error(-20105, ad_fnc_formataerro(e));
      else
        null;
      end if;
    
    elsif updating then
    
      if (:old.nunotaent is not null or :old.nunotasai is not null) and
         (:new.nunotaent is null or :new.nunotaent is null) then
        :new.statuslote := 'A';
      end if;
    
      if (:old.nunotaent is null or :old.nunotasai is null) and
         (:new.nunotaent is not null or :new.nunotaent is not null) then
        :new.statuslote := 'F';
      end if;
    
      if :new.nunotaent is not null and :new.nunotasai is not null then
        :new.statuslote := 'L';
      end if;
    
      /* recalcula valores */
    
      --- receita bonus checklist
      if :new.vlrcomclist > 0 and :new.pontuacao > 0 then
        :new.recbonus := round(:new.vlrcomclist * (:new.pontuacao / 100), cd);
      end if;
    
      -- total comiss�o por ave
      :new.totcomave := round(:new.recbonus + :new.vlrcomfixa +
                              :new.vlrcomatrat,
                              cd);
    
      -- percentual de participacao
      if nvl(:new.qtdovosinc, 0) > 0 then
        :new.percparticipovo := round(:new.qtdovosinc * :new.totcomave, cd) /
                                round(:new.qtdovosinc * :new.vlrunitcom, cd) * 100;
      
        :new.qtdparticipovo := round((:new.qtdovosinc * :new.percparticipovo) / 100,
                                     cd);
      else
        :new.percparticipovo := 0;
        :new.qtdparticipovo  := 0;
      end if;
    
      -- comiss�o    
      :new.vlrcom := round(:new.qtdparticipovo * :new.vlrunitcom, 2);
    
      -- o lote ser� finalizado pela confirma��o do nunota
      /* if :new.statusnfe in ('A', 'D') then
        :new.statuslote := 'L';
      end if;*/
    
      -- se est� alterando mas n�o o nunota
      if not updating('STATUSLOTE') and not updating('NUNOTAENT') and
         not updating('NUNOTASAI') and :old.statuslote = 'L' then
        e := ad_fnc_formataerro('Erro! Lote j� possui notas geradas,' ||
                                ' altera��es n�o s�o permitidas!');
        raise_application_error(-20105, e);
      end if;
    
      begin
        update ad_tsffcp p
           set p.codusualter = stp_get_codusulogado,
               p.dhalter     = sysdate
         where p.codcencus = :new.codcencus;
      exception
        when others then
          raise;
      end;
    
    elsif deleting then
      if :old.nunota is not null then
        e := ad_fnc_formataerro('Erro! J� possui nota gerada!');
        raise_application_error(-20105, e);
      end if;
    
    end if;
  
  end before each row;

end;
/
