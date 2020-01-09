PL/SQL Developer Test script 3.0
188
declare
  lanc        ad_tsffcpref%rowtype;
  p_codcencus number;
  p_codusu    int := stp_get_codusulogado;
  p_dataini   date;
  p_datafin   date;
  p_codemp    int;
  p_numlote   number;
  p_pontuacao number;
  p_dtvenc    date;
  p_mensagem  varchar2(4000);

  type tab_notas is table of ad_tsffcpnfe%rowtype;
  t tab_notas;

begin
  p_codcencus := 110400401;
  p_dataini   := :dataini;
  p_datafin   := :datafin;

  lanc.codcencus := p_codcencus;
  lanc.dtref     := trunc(sysdate, 'fmmm');

  begin
    select codparc into lanc.codparc from tgfpar p where p.ad_codcencus = lanc.codcencus;
  exception
    when no_data_found then
    
      select codparc
        into lanc.codparc
        from tgfcab
       where codcencus = lanc.codcencus
         and codtipoper in (332, 777)
       fetch first 1 rows only;
    
    when others then
      raise;
  end;

  lanc.statuslote := 'A';

  -- busca tabela
  begin
    select distinct c.codtabpos
      into lanc.codtabpos
      from ad_tsftcpcus c
     where c.codcencus = lanc.codcencus;
  exception
    when others then
      raise;
  end;

  -- busca valores da referencia da tabela

  begin
    select r.recoper, r.recatrat, r.recbonus, r.rectotal
      into lanc.vlrcomfixa, lanc.vlrcomatrat, lanc.vlrcomclist, lanc.totcomfixa
      from ad_tsftcpref r
     where r.codtabpos = lanc.codtabpos
       and r.dtref = (select max(dtref)
                        from ad_tsftcpref r2
                       where r2.codtabpos = r.codtabpos
                         and r2.dtref <= lanc.dtref);
  exception
    when others then
      raise;
  end;

  -- quantidade de ovos incubaveis
  begin
    select nvl(sum(case
                     when cab.codtipoper in (777) then
                      ite.qtdneg * -1
                     else
                      ite.qtdneg
                   end),
               0)
      into lanc.qtdovosinc
      from tgfcab cab, tgfite ite
     where cab.nunota = ite.nunota
       and cab.codtipoper in (332, 777)
       and cab.dtneg >= p_dataini
       and cab.dtneg <= p_datafin
       and cab.codcencus = lanc.codcencus
       and cab.codparc = lanc.codparc
       and ite.codprod = 72124;
  exception
    when others then
      raise;
  end;

  -- quantidade ovos incubaveis granja
  begin
    select nvl(sum(case
                     when cab.codtipoper in (19, 777) or cab.codparc = 615964 then
                      ite.qtdneg * -1
                     else
                      ite.qtdneg
                   end),
               0)
      into lanc.qtdovosgrj
      from tgfcab cab, tgfite ite
     where cab.nunota = ite.nunota
       and cab.codtipoper in (197, 777)
       and cab.dtneg >= p_dataini
       and cab.dtneg <= p_datafin
       and cab.codcencus = lanc.codcencus
       and ite.sequencia > 0
       and ite.codprod = 72124;
  exception
    when others then
      raise;
  end;

  -- custo ovo 
  begin
    select c.vlrovo
      into lanc.vlrunitcom
      from ad_tsftcpovo c
     where c.codtabpos = lanc.codtabpos
       and c.dtref = (select max(dtref)
                        from ad_tsftcpovo o2
                       where o2.codtabpos = c.codtabpos
                         and o2.dtref <= lanc.dtref);
  exception
    when others then
      raise;
  end;

  lanc.codemp          := p_codemp;
  lanc.nunota          := null;
  lanc.statusnfe       := null;
  lanc.numlote         := p_numlote;
  lanc.pontuacao       := p_pontuacao;
  lanc.recbonus        := lanc.vlrcomclist * (lanc.pontuacao / 100);
  lanc.totcomave       := lanc.recbonus + lanc.vlrcomfixa + lanc.vlrcomatrat;
  lanc.percparticipovo := ((lanc.qtdovosinc * lanc.totcomave) / (lanc.qtdovosinc * lanc.vlrunitcom)) * 100;

  lanc.qtdparticipovo := ((lanc.qtdovosinc * lanc.percparticipovo) / 100);
  lanc.vlrcom         := lanc.qtdparticipovo * lanc.vlrunitcom;
  lanc.dtvenc         := p_dtvenc;
  lanc.dhalter        := sysdate;
  lanc.codusu         := p_codusu;

  begin
    delete from ad_tsffcpref r
     where r.codcencus = lanc.codcencus
       and r.dtref = lanc.dtref;
  
    insert into ad_tsffcpref values lanc;
  exception
    when others then
      raise;
  end;

  select lanc.codcencus, lanc.dtref, cab.nunota, ite.sequencia, cab.numnota, cab.dtneg, ite.codprod,
         case
           when cab.codtipoper in (777) then
            ite.qtdneg * -1
           else
            ite.qtdneg
         end, ite.vlrunit, ite.vlrtot
    bulk collect
    into t
    from tgfcab cab, tgfite ite
   where cab.nunota = ite.nunota
     and cab.codtipoper in (332, 777)
     and cab.dtneg >= p_dataini
     and cab.dtneg <= p_datafin
     and cab.codcencus = lanc.codcencus
     and cab.codparc = lanc.codparc
     and ite.codprod = 72124;
     
     
     Forall x In t.first .. t.last
      Merge Into ad_tsffcpnfe p
      using (Select t(x).codcencus codcencus,
            t(x).dtref dtref,
             t(x).nunota nunota, 
             t(x).sequencia sequencia From dual ) d
      on (p.nunota = d.nunota And p.sequencia = d.sequencia
       And p.codcencus = d.codcencus And p.dtref = d.dtref)       
      when not matched Then
        Insert Values t(x);



End;
2
dataini
1
01/09/2019
12
datafin
1
30/09/2019
12
0
