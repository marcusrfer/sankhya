create or replace trigger ad_trg_cmp_tsffcpref_sf
  for insert or update or delete on ad_tsffcpref
  compound trigger

  /*before statement is
  begin
    null;
  end before statement;*/

  before each row is
  begin
    if inserting then
      null;
    elsif updating then
      
      /* recalcula valores */
    
      --- receita bonus checklist
      if :new.vlrcomclist > 0 and :new.pontuacao > 0 then
        :new.recbonus := :new.vlrcomclist * (:new.pontuacao / 100);
      end if;
    
      -- total comiss�o por ave
      :new.totcomave := :new.recbonus + :new.vlrcomfixa + :new.vlrcomatrat;
      -- percentual de participacao
      :new.percparticipovo := ((:new.qtdovosinc * :new.totcomave) /
                              (:new.qtdovosinc * :new.vlrunitcom)) * 100;
    
      -- participacao
      :new.qtdparticipovo := ((:new.qtdovosinc * :new.percparticipovo) / 100);
      -- comiss�o    
      :new.vlrcom := (:new.qtdparticipovo * :new.vlrunitcom);
      
      
      If :new.Statusnfe In ('A', 'D') Then
        :new.Statuslote := 'L';
      End If;
      
      if :old.nunota is Not null  then
         raise_application_error(-20105, 'Erro! Nro �nico j� gerado, altera��es n�o s�o permitidas'); 
      end if;  
    
    elsif deleting then
      null;
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
