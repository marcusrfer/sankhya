create or replace trigger ad_trg_cmp_tsffcpref_sf
  for insert or update or delete on ad_tsffcpref
  compound trigger

  before each row is
    e varchar2(4000);
  begin
  
    if inserting then
    
      if not stp_get_atualizando then
        e := 'Utilize o botão de ação "Buscar Dados" para ' ||
             'inserir dados nesse formulário';
        raise_application_error(-20105, ad_fnc_formataerro(e));
      else
        null;
      end if;
    
    elsif updating then
    
      if :old.nunota is not null and :new.nunota is null then
        :new.statuslote := 'A';
      end if;
    
      /* recalcula valores */
    
      --- receita bonus checklist
      if :new.vlrcomclist > 0 and :new.pontuacao > 0 then
        :new.recbonus := :new.vlrcomclist * (:new.pontuacao / 100);
      end if;
    
      -- total comissão por ave
      :new.totcomave := :new.recbonus + :new.vlrcomfixa + :new.vlrcomatrat;
      -- percentual de participacao
      :new.percparticipovo := ((:new.qtdovosinc * :new.totcomave) /
                              (:new.qtdovosinc * :new.vlrunitcom)) * 100;
    
      -- participacao
      :new.qtdparticipovo := ((:new.qtdovosinc * :new.percparticipovo) / 100);
      -- comissão    
      :new.vlrcom := (:new.qtdparticipovo * :new.vlrunitcom);
    
      -- o lote será finalizado pela confirmação do nunota
      if :new.statusnfe in ('A', 'D') then
        :new.statuslote := 'L';
      end if;
    
      -- se está alterando mas não o nunota
      if :old.nunota is not null and :new.nunota is not null then
        e := ad_fnc_formataerro('Erro! Lote já possui nota gerada,' ||
                                ' alterações não são permitidas!');
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
        e := ad_fnc_formataerro('Erro! Já possui nota gerada!');
        raise_application_error(-20105, e);
      end if;
    
    end if;
  
  end before each row;

end;
/
