create or replace procedure ad_stp_fcp_getdata_sf(p_codusu    number,
                                                  p_idsessao  varchar2,
                                                  p_qtdlinhas number,
                                                  p_mensagem  out varchar2) as

  p_dataini  date;
  p_datafin  date;
  v_confirma boolean;
  v_dreftab  date;

  type tab_notas is table of ad_tsffcpnfe%rowtype;
  t tab_notas;

  lanc ad_tsffcpref%rowtype;
  conf ad_tsftcpref%rowtype;

  cd int := 5;

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

  if lanc.pontuacao = 0 then
    lanc.pontuacao := 1;
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

  -- busca o parceiro pelo centro d resultados
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

  -- busca tabela e os valores da referencia e do custo
  begin
  
    select r.dtref, r.recoper, r.recatrat, r.recbonus, r.rectotal
      into v_dreftab, lanc.vlrcomfixa, lanc.vlrcomatrat, lanc.vlrcomclist, lanc.totcomfixa
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
      p_mensagem := 'Erro ao buscar os valores da referencia da tabela. ' || sqlerrm;
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
      And ite.codprod = pro.codprod
       and cab.codtipoper in (332, 777)
       and cab.dtneg >= p_dataini
       and cab.dtneg <= p_datafin
       and cab.codcencus = lanc.codcencus
       and cab.codparc = lanc.codparc
       And pro.descrprod Like ('OVOS INCUUBAVEIS%') 
       --and ite.codprod = 72124
       ;
  exception
    when others then
      p_mensagem := 'Erro ao buscar a quantidade de ovos incubaveis no incubatório. ' || sqlerrm;
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
      And pro.codprod = ite.codprod
       and cab.codtipoper in (197, 777)
       and cab.dtneg >= p_dataini
       and cab.dtneg <= p_datafin
       and cab.codcencus = lanc.codcencus
       and ite.sequencia > 0
       --and ite.codprod = 72124
       And pro.descrprod Like ('OVOS INCUBAVEIS%')       ;
  exception
    when others then
      p_mensagem := 'Erro ao buscar a quantidade de ovos incubaveis na granja. ' || sqlerrm;
      return;
  end;
  
  If LANC.QTDOVOSINC = 0 Then
   lanc.qtdovosinc := 1;
  End If;
  
  if lanc.qtdovosgrj = 0 then
     lanc.qtdovosgrj := 1;
  end if; 

  lanc.nunota          := null;
  lanc.statusnfe       := null;
  lanc.recbonus        := round(lanc.vlrcomclist * (lanc.pontuacao / 100), cd);
  lanc.totcomave       := round(lanc.recbonus + lanc.vlrcomfixa + lanc.vlrcomatrat, cd);
  lanc.percparticipovo := round((lanc.qtdovosinc * lanc.totcomave) /
                                (lanc.qtdovosinc * lanc.vlrunitcom) * 100,
                                cd);

  lanc.qtdparticipovo := round((lanc.qtdovosinc * lanc.percparticipovo) / 100, 0);
  --lanc.vlrcom         := Round(lanc.qtdparticipovo * lanc.vlrunitcom,2);
  lanc.vlrcom  := round(lanc.qtdovosinc * lanc.totcomave, 2);
  lanc.dhalter := sysdate;
  lanc.codusu  := p_codusu;

  -- insere os valores da referencia
  begin
    delete from ad_tsffcpref r
     where r.codcencus = lanc.codcencus
       and r.dtref = lanc.dtref;
  
    insert into ad_tsffcpref values lanc;
  exception
    when others then
      raise;
  end;

  -- fetch das notas
  select lanc.codcencus, lanc.dtref, cab.nunota, ite.sequencia, cab.numnota, cab.dtneg, ite.codprod,
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
     And pro.codprod = ite.codprod
     and cab.codtipoper in (332, 777)
     and cab.dtneg >= p_dataini
     and cab.dtneg <= p_datafin
     and cab.codcencus = lanc.codcencus
     and cab.codparc = lanc.codparc
     --and ite.codprod = 72124
     And pro.descrprod Like ('OVOS INCUBAVEIS%') 
     ;

  -- Insert das notas
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

  p_mensagem := 'Valores populados com sucesso!';

end;
/
