create or replace procedure ad_stp_fcp_getdata_sf(p_codusu    number,
                                                  p_idsessao  varchar2,
                                                  p_qtdlinhas number,
                                                  p_mensagem  out varchar2) as

  p_dataini  date;
  p_datafin  date;
  v_confirma boolean;
  --v_dreftab  date;

  type tab_notas is table of ad_tsffcpnfe%rowtype;
  t tab_notas;

  lanc ad_tsffcpref%rowtype;
  conf ad_tsftcpref%rowtype;

  cd int := 5;
  i  int;

begin

  /*
  * Autor: M. Rangel
  * Processo: Fechamento de Comissão Integrado - Postura
  * Objetivo: Ler os dados da tabela, popular e calcular os campos da tela de 
              fechamento da comissão postura
  */
  lanc.codcencus := act_int_field(p_idsessao, 0, 'MASTER_CODCENCUS');
  lanc.codemp    := to_number(act_txt_param(p_idsessao, 'CODEMP'));
  lanc.codtabpos := to_number(act_txt_param(p_idsessao, 'CODTAB'));
  lanc.numlote   := act_int_param(p_idsessao, 'NUMLOTE');
  lanc.pontuacao := act_int_param(p_idsessao, 'PONTUACAO');
  lanc.dtvenc    := act_dta_param(p_idsessao, 'DTVENC');
  p_dataini      := act_dta_param(p_idsessao, 'DATAINI');
  p_datafin      := act_dta_param(p_idsessao, 'DATAFIN');

  if lanc.pontuacao is null then
    lanc.pontuacao := 0;
  end if;

  select count(*)
    into i
    from ad_tsftcpcus c
   where c.codtabpos = lanc.codtabpos
     and c.codcencus = lanc.codcencus;

  if i = 0 then
    p_mensagem := 'Essa tabela não pode ser utilizada com este CR!';
    return;
  end if;

  /*  lanc.codcencus := 110400401;
  lanc.codemp    := 1;
  lanc.codtabpos := 3;
  lanc.numlote   := 35;
  lanc.pontuacao := 0;
  lanc.dtvenc    := '30/01/2020';
  p_dataini      := '01/08/2019';
  p_datafin      := '31/08/2019';*/

  if p_qtdlinhas > 1 then
    v_confirma := act_confirmar(p_titulo    => 'Preparação para Fechamento',
                                p_texto     => 'Deseja recalcular os valores para todas as linhas ' ||
                                               'selecionadas?',
                                p_chave     => p_idsessao,
                                p_sequencia => 0);
  end if;

  if not v_confirma then
    return;
  end if;

  lanc.dtref      := add_months(trunc(sysdate, 'fmmm'), -1);
  lanc.statuslote := 'A';

  select count(*)
    into i
    from ad_tsffcpref r
   where r.codcencus = lanc.codcencus
     and r.dtref = lanc.dtref;

  if i > 0 then
    p_mensagem := 'já existe cálculo para essa referência! ' ||
                  'Exclua a mesma e refaça os cálculos.';
    return;
    /*begin
      delete from ad_tsffcpref
       where codcencus = lanc.codcencus
         and dtref = lanc.dtref;
    exception
      when others then
        p_mensagem := 'Erro ao substituir lançamento existente. ' || sqlerrm;
        return;
    end;*/
  end if;

  -- busca o parceiro pelo centro d resultados
  begin
    select codparc
      into lanc.codparc
      from tgfpar p
     where p.ad_codcencus = lanc.codcencus;
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

  -- busca tabela e os valores da referencia e do custo
  begin
  
    select r.dtref, r.recoper, r.recatrat, r.recbonus, r.rectotal
      into lanc.dtreftab, lanc.vlrcomfixa, lanc.vlrcomatrat, lanc.vlrcomclist,
           lanc.totcomfixa
      from ad_tsftcpref r
     where r.codtabpos = lanc.codtabpos
       and r.dtref = (select max(dtref)
                        from ad_tsftcpref r2
                       where r2.codtabpos = lanc.codtabpos
                         and r2.dtref <= lanc.dtref);
  
    select c.vlrovo
      into lanc.vlrunitcom
      from ad_tsftcpovo c
     where c.codtabpos = lanc.codtabpos
       and c.dtref = (select max(dtref)
                        from ad_tsftcpovo o2
                       where o2.codtabpos = lanc.codtabpos
                         and o2.dtref <= lanc.dtref);
  
  exception
    when others then
      p_mensagem := 'Erro ao buscar os valores da referencia da tabela. ' ||
                    sqlerrm;
      return;
  end;

  -- quantidade de ovos incubaveis no incubatorio
  begin
    select nvl(sum(case
                     when cab.codtipoper in (777) then
                      ite.qtdneg * -1
                     else
                      ite.qtdneg
                   end),
               0)
      into lanc.qtdovosinc
      from tgfcab cab, tgfite ite, tgfpro pro
     where cab.nunota = ite.nunota
       and ite.codprod = pro.codprod
       and cab.codtipoper in (332, 777)
       and cab.dtneg >= p_dataini
       and cab.dtneg <= p_datafin
       and cab.codcencus = lanc.codcencus
       and cab.codparc = lanc.codparc
       and pro.descrprod like ('OVOS INCUBAVEIS%')
    --and ite.codprod = 72124
    ;
  exception
    when others then
      p_mensagem := 'Erro ao buscar a quantidade de ovos incubaveis no incubatório. ' ||
                    sqlerrm;
      return;
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
      from tgfcab cab, tgfite ite, tgfpro pro
     where cab.nunota = ite.nunota
       and pro.codprod = ite.codprod
       and cab.codtipoper in (197, 777)
       and cab.dtneg >= p_dataini
       and cab.dtneg <= p_datafin
       and cab.codcencus = lanc.codcencus
       and ite.sequencia > 0
          --and ite.codprod = 72124
       and pro.descrprod like ('OVOS INCUBAVEIS%');
  exception
    when others then
      p_mensagem := 'Erro ao buscar a quantidade de ovos incubaveis na granja. ' ||
                    sqlerrm;
      return;
  end;

  if lanc.qtdovosinc is null then
    lanc.qtdovosinc := 0;
  end if;

  if lanc.qtdovosgrj is null then
    lanc.qtdovosgrj := 0;
  end if;

  lanc.nunota    := null;
  lanc.statusnfe := null;

  if nvl(lanc.vlrcomclist, 0) > 0 and nvl(lanc.pontuacao, 0) > 0 then
    lanc.recbonus := round(lanc.vlrcomclist * (lanc.pontuacao / 100), cd);
  else
    lanc.recbonus := 0;
  end if;

  lanc.totcomave := round(lanc.recbonus + lanc.vlrcomfixa + lanc.vlrcomatrat,
                          cd);

  if nvl(lanc.qtdovosinc, 0) > 0 then
    lanc.percparticipovo := round((lanc.qtdovosinc * lanc.totcomave) /
                                  (lanc.qtdovosinc * lanc.vlrunitcom) * 100,
                                  cd);
  
    lanc.qtdparticipovo := round((lanc.qtdovosinc * lanc.percparticipovo) / 100,
                                 0);
  else
    lanc.percparticipovo := 0;
    lanc.qtdparticipovo  := 0;
  end if;

  lanc.vlrcom := round(lanc.qtdparticipovo * lanc.vlrunitcom, 2);

  lanc.dhalter := sysdate;
  lanc.codusu  := p_codusu;

  -- insere os valores da referencia
  begin
    stp_set_atualizando('S');
    delete from ad_tsffcpref r
     where r.codcencus = lanc.codcencus
       and r.dtref = lanc.dtref;
  
    insert into ad_tsffcpref values lanc;
    stp_set_atualizando('N');
  exception
    when others then
      raise;
  end;

  -- fetch das notas
  select cab.nunota, ite.sequencia, lanc.codcencus, lanc.dtref, cab.numnota,
         cab.dtneg, ite.codprod,
         case
           when cab.codtipoper in (777) then
            ite.qtdneg * -1
           else
            ite.qtdneg
         end qtdneg, ite.vlrunit, ite.vlrtot
    bulk collect
    into t
    from tgfcab cab, tgfite ite, tgfpro pro
   where cab.nunota = ite.nunota
     and pro.codprod = ite.codprod
     and cab.codtipoper in (332, 777)
     and cab.dtneg >= p_dataini
     and cab.dtneg <= p_datafin
     and cab.codcencus = lanc.codcencus
     and cab.codparc = lanc.codparc
        --and ite.codprod = 72124
     and pro.descrprod like ('OVOS INCUBAVEIS%');

  -- Insert das notas
  stp_set_atualizando('S');
  forall x in t.first .. t.last
    merge into ad_tsffcpnfe p
    using (select t(x).codcencus codcencus,t(x).dtref dtref,t(x).nunota nunota,
                  t(x).sequencia sequencia
             from dual) d
    on (p.nunota = d.nunota and p.sequencia = d.sequencia and p.codcencus = d.codcencus and p.dtref = d.dtref)
    when matched then
      update
         set numnota = t(x).numnota,
             dtneg   = t(x).dtneg,
             codprod = t(x).codprod,
             qtdneg  = t(x).qtdneg,
             vlrunit = t(x).vlrunit,
             vlrtot  = t(x).vlrtot
    when not matched then
      insert values t (x);

  stp_set_atualizando('N');

  p_mensagem := 'Valores populados com sucesso!';

end;
/
