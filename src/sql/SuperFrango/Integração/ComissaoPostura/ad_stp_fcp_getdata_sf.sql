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

 lanc.dtref      := trunc(sysdate, 'fmmm');
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
 
  ad_stp_fcp_getreftabela_sf(p_codcencus => lanc.codcencus,
                             p_dtref     => lanc.dtref,
                             p_codtab    => lanc.codtabpos,
                             p_dtreftab  => v_dreftab,
                             p_recoper   => lanc.vlrcomfixa,
                             p_recatrat  => lanc.vlrcomatrat,
                             p_recbonus  => lanc.vlrcomclist,
                             p_rectotal  => lanc.totcomfixa,
                             p_custo     => lanc.vlrunitcom);
 
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
   p_mensagem := 'Erro ao buscar a quantidade de ovos incubaveis na granja. ' || sqlerrm;
   return;
 end;

 lanc.nunota          := null;
 lanc.statusnfe       := null;
 lanc.recbonus        := lanc.vlrcomclist * (lanc.pontuacao / 100);
 lanc.totcomave       := lanc.recbonus + lanc.vlrcomfixa + lanc.vlrcomatrat;
 lanc.percparticipovo := snk_dividir((lanc.qtdovosinc * lanc.totcomave),
                                     (lanc.qtdovosinc * lanc.vlrunitcom)) * 100;

 lanc.qtdparticipovo := ((lanc.qtdovosinc * lanc.percparticipovo) / 100);
 lanc.vlrcom         := lanc.qtdparticipovo * lanc.vlrunitcom;
 lanc.dhalter        := sysdate;
 lanc.codusu         := p_codusu;

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
   from tgfcab cab, tgfite ite
  where cab.nunota = ite.nunota
    and cab.codtipoper in (332, 777)
    and cab.dtneg >= p_dataini
    and cab.dtneg <= p_datafin
    and cab.codcencus = lanc.codcencus
    and cab.codparc = lanc.codparc
    and ite.codprod = 72124;

 -- Insert das notas
 forall x in t.first .. t.last
  merge into ad_tsffcpnfe p
  using (select t(x).codcencus codcencus,t(x).dtref dtref,t(x).nunota nunota,t(x).sequencia sequencia
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
