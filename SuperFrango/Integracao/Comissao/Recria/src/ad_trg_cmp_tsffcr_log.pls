create or replace trigger ad_trg_cmp_tsffcr_log
  for insert or update or delete on ad_tsffcr
  compound trigger

  -- criada dinamicamente pela rotina de log
  -- por: Supervisor de Sistema
  -- em: 29/01/2020

  type l_tipo_log is table of ad_tsffcr_log%rowtype;
  l l_tipo_log := l_tipo_log();

  v_osuser   varchar2(100) := sys_context(' USERENV ', 'OS_USER');
  v_terminal varchar2(200) := sys_context('USERENV', 'TERMINAL');
  v_oper     varchar2(100);
  v_dhoper   date := sysdate;

  i int;

  procedure inserir_registros_log is
  begin
    forall x in 1 .. l.count
      insert into ad_tsffcr_log values l (x);
    l.delete;
  end;

  before statement is
  begin
    l.delete;
  end before statement;

  after each row is
  begin
    l.extend;
    i := l.last;
  
    if inserting or updating then
    
      if inserting then
        v_oper := 'Insert';
      else
        v_oper := 'Update';
      end if;
    
      l(i).codcencus := :new.codcencus;
      l(i).codparc := :new.codparc;
      l(i).numlote := :new.numlote;
      l(i).status := :new.status;
      l(i).codemp := :new.codemp;
      l(i).dtaloj := :new.dtaloj;
      l(i).qtdmeses := :new.qtdmeses;
      l(i).qtdaves := :new.qtdaves;
      l(i).percmortprev := :new.percmortprev;
      l(i).codtabprev := :new.codtabprev;
      l(i).dreftabprev := :new.dreftabprev;
      l(i).statuslote := :new.statuslote;
      l(i).vlrunitprev := :new.vlrunitprev;
      l(i).vlrtotprev := :new.vlrtotprev;
      l(i).vlrmesprev := :new.vlrmesprev;
      l(i).codtabreal := :new.codtabreal;
      l(i).dreftabreal := :new.dreftabreal;
      l(i).vlrcomfixa := :new.vlrcomfixa;
      l(i).vlrcomatrat := :new.vlrcomatrat;
      l(i).pontuacao := :new.pontuacao;
      l(i).vlrcomclist := :new.vlrcomclist;
      l(i).totremave := :new.totremave;
      l(i).totremmes := :new.totremmes;
      l(i).percparticip := :new.percparticip;
      l(i).participacao := :new.participacao;
      l(i).vlrcomave := :new.vlrcomave;
      l(i).qtdavesliq := :new.qtdavesliq;
      l(i).qtdmortperm := :new.qtdmortperm;
      l(i).qtdmortgranja := :new.qtdmortgranja;
      l(i).qtdavesvda := :new.qtdavesvda;
      l(i).qtdaveselim := :new.qtdaveselim;
      l(i).totavestransf := :new.totavestransf;
      l(i).vlrmedreal := :new.vlrmedreal;
      l(i).vlrtotreal := :new.vlrtotreal;
      l(i).vlrtotadiant := :new.vlrtotadiant;
      l(i).saldo := :new.saldo;
      l(i).nunota := :new.nunota;
      l(i).statusnota := :new.statusnota;
      l(i).codusuinc := :new.codusuinc;
      l(i).dhinc := :new.dhinc;
      l(i).codusualt := :new.codusualt;
      l(i).dhalter := :new.dhalter;
      l(i).qtdmortransp := :new.qtdmortransp;
      l(i).qtdenvlab := :new.qtdenvlab;
      l(i).sexo := :new.sexo;
      l(i).username := v_osuser;
      l(i).terminal := v_terminal;
      l(i).operacao := v_oper;
      l(i).dhoper := v_dhoper;
    
    elsif deleting then
      v_oper := 'Delete';
    
      l(i).codcencus := :old.codcencus;
      l(i).codparc := :old.codparc;
      l(i).numlote := :old.numlote;
      l(i).status := :old.status;
      l(i).codemp := :old.codemp;
      l(i).dtaloj := :old.dtaloj;
      l(i).qtdmeses := :old.qtdmeses;
      l(i).qtdaves := :old.qtdaves;
      l(i).percmortprev := :old.percmortprev;
      l(i).codtabprev := :old.codtabprev;
      l(i).dreftabprev := :old.dreftabprev;
      l(i).statuslote := :old.statuslote;
      l(i).vlrunitprev := :old.vlrunitprev;
      l(i).vlrtotprev := :old.vlrtotprev;
      l(i).vlrmesprev := :old.vlrmesprev;
      l(i).codtabreal := :old.codtabreal;
      l(i).dreftabreal := :old.dreftabreal;
      l(i).vlrcomfixa := :old.vlrcomfixa;
      l(i).vlrcomatrat := :old.vlrcomatrat;
      l(i).pontuacao := :old.pontuacao;
      l(i).vlrcomclist := :old.vlrcomclist;
      l(i).totremave := :old.totremave;
      l(i).totremmes := :old.totremmes;
      l(i).percparticip := :old.percparticip;
      l(i).participacao := :old.participacao;
      l(i).vlrcomave := :old.vlrcomave;
      l(i).qtdavesliq := :old.qtdavesliq;
      l(i).qtdmortperm := :old.qtdmortperm;
      l(i).qtdmortgranja := :old.qtdmortgranja;
      l(i).qtdavesvda := :old.qtdavesvda;
      l(i).qtdaveselim := :old.qtdaveselim;
      l(i).totavestransf := :old.totavestransf;
      l(i).vlrmedreal := :old.vlrmedreal;
      l(i).vlrtotreal := :old.vlrtotreal;
      l(i).vlrtotadiant := :old.vlrtotadiant;
      l(i).saldo := :old.saldo;
      l(i).nunota := :old.nunota;
      l(i).statusnota := :old.statusnota;
      l(i).codusuinc := :old.codusuinc;
      l(i).dhinc := :old.dhinc;
      l(i).codusualt := :old.codusualt;
      l(i).dhalter := :old.dhalter;
      l(i).qtdmortransp := :old.qtdmortransp;
      l(i).qtdenvlab := :old.qtdenvlab;
      l(i).sexo := :old.sexo;
      l(i).username := v_osuser;
      l(i).terminal := v_terminal;
      l(i).operacao := v_oper;
      l(i).dhoper := v_dhoper;
    
    end if;
  
    if l.count > 1000 then
      inserir_registros_log;
    end if;
  
  end after each row;

  after statement is
  begin
    if l.count > 0 then
      inserir_registros_log;
    end if;
  end after statement;

end;
/
