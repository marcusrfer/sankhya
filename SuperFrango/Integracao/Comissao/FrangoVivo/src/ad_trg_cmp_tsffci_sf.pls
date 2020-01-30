create or replace trigger ad_trg_cmp_tsffci_sf
  for insert or update or delete on ad_tsffci
  compound trigger

  i int;
  e varchar2(4000);

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
        e := 'Lotes <b>"Finalizados"</b> ou <b>"Em faturamento"</b> ' ||
             'não podem ser editados';
        raise_application_error(-20105, ad_fnc_formataerro(e));
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
         where n.codtipoper in (152, 329, 401, 365)
           and n.statusnota != 'L';
      
        if i = 4 then
          :new.statuslote := 'L';
        elsif i = 0 then
          :new.statuslote := 'A';
        end if;
      end if;
    
      if updating('QTDAVES') or updating('QTDABAT') or updating('QTDRACAO') or
         updating('PESO') or updating('IDADE') then
      
        :new.viabilidade := round(snk_dividir(:new.qtdabat, :new.qtdaves) * 100,
                                  3);
        :new.pesolote    := round(:new.peso / :new.qtdabat, 3);
        :new.ganholote   := round((:new.pesolote / :new.idade) * 1000, 2);
        :new.calote      := round(snk_dividir(:new.qtdracao, :new.peso), 3);
        :new.fplote      := round(snk_dividir((:new.viabilidade *
                                              :new.ganholote),
                                              (:new.calote * 10)),
                                  2);
        :new.qtdmortes   := :new.qtdaves - :new.qtdabat;
        :new.ipsulote    := round((:new.viabilidade * 0.1) *
                                  (:new.ganholote * 0.35) /
                                  (:new.calote * 0.55),
                                  3);
        :new.percom      := round(ad_pkg_fci.get_perc_com(:new.ipsulote,
                                                          :new.ipsumedio),
                                  2);
        :new.pesocom     := round(:new.peso * (:new.percom / 100), 3);
        :new.vlrcom      := round(:new.pesocom * :new.vlrunit, 3);
        :new.vlrcomliq   := round(:new.vlrcom - :new.vlrdespesas, 3);
        :new.dhinclusao  := sysdate;
      end if;
    
    elsif deleting then
    
      if :old.statuslote in ('F', 'L') then
        e := 'Lotes <b>"Finalizados"</b> ou <b>"Em faturamento"</b> ' ||
             'não podem ser editados';
        raise_application_error(-20105, ad_fnc_formataerro(e));
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
