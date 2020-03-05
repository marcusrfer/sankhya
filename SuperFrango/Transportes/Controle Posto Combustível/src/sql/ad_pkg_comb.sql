create or replace package ad_pkg_comb as
 /****************************************************************************
 Autor: 
 Objetivo: 
 *****************************************************************************/

 ajuste_bomba boolean default false;

 type ty_comb is record(
  codprod   number,
  descrprod varchar2(300),
  codemp    number,
  dtini     date,
  dtfim     date,
  saldoini  float,
  entradas  float,
  saidas    float,
  saldofim  float);

 type tb_comb is table of ty_comb;

 type t_refcursor is ref cursor;

 type ty_aferebomba is record(
  dtreferencia date,
  codprod      number,
  descrprod    varchar2(400),
  bomba        number,
  qtd_aferida  float,
  saidas       float,
  diferenca    float);

 type rc_bomba is table of ty_aferebomba;

 type ty_abastecimento is record(
  nunota     number,
  dtneg      date,
  codemp     number,
  codveiculo number,
  ordemcarga number,
  codcat     int,
  codparc    number,
  qtdneg     float);

 type tb_abastecimento is table of ty_abastecimento;

 type type_rec_dist_oc is record(
  dtneg         date,
  codmep        int,
  codcat        int,
  categoria     varchar2(100),
  coveiculo     number,
  codparctransp number,
  codreg        number,
  distancia     number);

 type type_tab_dist_oc is table of type_rec_dist_oc;

 function distancia(p_dataini date, p_datafin date, p_codcat int) return float;

 function distancia(p_dataini date, p_datafin date, p_codcat int, p_codvei number) return float;

 function veiculo(p_codvei number) return number;

 function get_ordemcarga(p_nunota number) return number;

 function get_codreg(p_codemp number, p_ordcarga number) return number;

 function get_qtdlitros_reg(p_dataini date, p_datafin date, p_codreg number, p_grau int)
  return float;

 function abast(p_dataini date, p_datafin date) return tb_abastecimento
 pipelined;

 function temp_retorna_regiao(p_codreg number, p_grau number) return number;

 function get_codreg_acima(p_codreg_origem number, p_grau_desejado int) return number;

 function get_peso_ordcarga(p_codemp number, p_ordemcarga number) return float;

 /*  Function SaldoIni(p_codprod Number, p_codemp Number, p_dtini Date) Return Float;
 Function Entradas(p_codprod Number, p_codemp Number, p_dtini Date, p_DtFim Date) Return Float;
 Function Saidas(p_codprod Number, p_codemp Number, p_dtini Date, p_DtFim Date) Return Float;*/

 function movestoque(p_codprod number, p_codemp number, p_dtini date, p_dtfim date) return tb_comb
 pipelined;
 /****************************************************************************
 Autor: 
 Objetivo: 
 *****************************************************************************/

 function afericao_bomba(p_dtreferencia date) return rc_bomba
 pipelined;
 /****************************************************************************
 Autor: 
 Objetivo: 
 *****************************************************************************/

 function saldo_estoque(p_codemp   number,
                        p_codprod  number,
                        p_codlocal number,
                        p_controle varchar2,
                        p_dtini    date,
                        p_dtfim    date,
                        p_tipo     char) return float;
 /****************************************************************************
 Autor: 
 Objetivo: 
 *****************************************************************************/

 function saldo_estoque(p_codemp   number,
                        p_codprod  number,
                        p_codlocal number,
                        p_controle varchar2,
                        p_nrobomba number,
                        p_dtini    date,
                        p_dtfim    date,
                        p_tipo     char) return float;
 /****************************************************************************
 Autor: 
 Objetivo: 
 *****************************************************************************/

 function saldo_estoque_turno(p_codemp   number,
                              p_codprod  number,
                              p_codlocal number,
                              p_controle varchar2,
                              p_dtini    date,
                              p_dtfim    date,
                              p_tipo     char) return float;

 /****************************************************************************
 Autor: 
 Objetivo: 
 *****************************************************************************/

 function qtd_aferida(p_data date, p_codprod number, p_tipo char, bomba_tanque int) return float;
 /****************************************************************************
 Autor: 
 Objetivo: 
 *****************************************************************************/

 function resultadoposto(p_codemp int default null,
                         
                         p_dtini date default null,
                         p_dtfin date default null,
                         p_tipo  char) return float;
 --Function Resultadoposto(p_codemp Int, p_dtini Date, p_dtfin Date, p_tipo Char) Return Float;
 /****************************************************************************
 Autor: 
 Objetivo: 
 *****************************************************************************/

 function diferenca_posto(p_codemp number, p_codprod number, p_dtnegini date, p_dtnegfin date)
  return float;
 /****************************************************************************
 Autor: Marcus Rangel
 Objetivo: Obter a diferença entre o preço de venda e o custo do produto
 *****************************************************************************/

 function kmporveiculo(p_codvei number, p_dtini date, p_dtfin date) return float;

 function kmporcategoriavei(p_codcat number, p_dtini date, p_dtfin date) return float;

 function kmporregiao(p_codreg number, p_dtini date, p_dtfin date) return float;

 procedure ajusta_controle_comb(p_codprod number, p_tanque number, p_msg out varchar2);

end ad_pkg_comb;
/
create or replace package body ad_pkg_comb is

 function movestoque(p_codprod number, p_codemp number, p_dtini date, p_dtfim date) return tb_comb
 pipelined is
  r_mov      ty_comb;
  v_saldoini float;
  v_entradas float;
  v_saidas   float;
  v_saldofim float;
 begin
  select sum(qtdneg * atualestoque)
    into v_saldoini
    from tgfite i
    join tgfcab cab
      on cab.nunota = i.nunota
   where cab.codemp = p_codemp
     and i.atualestoque <> 0
     and cab.dtneg < p_dtini
     and i.codprod = p_codprod;
 
  select sum(qtdneg * atualestoque)
    into v_entradas
    from tgfite i
    join tgfcab cab
      on cab.nunota = i.nunota
   where cab.codemp = p_codemp
     and i.atualestoque = 1
     and cab.dtneg >= p_dtini
     and cab.dtneg <= p_dtfim
     and i.codprod = p_codprod;
 
  select sum(qtdneg * atualestoque)
    into v_saidas
    from tgfite i
    join tgfcab cab
      on cab.nunota = i.nunota
   where cab.codemp = p_codemp
     and i.atualestoque = -1
     and cab.dtneg >= p_dtini
     and cab.dtneg <= p_dtfim
     and i.codprod = p_codprod;
 
  select sum(qtdneg * atualestoque)
    into v_saldofim
    from tgfite i
    join tgfcab cab
      on cab.nunota = i.nunota
   where cab.codemp = p_codemp
     and i.atualestoque <> 0
     and cab.dtneg < p_dtfim
     and i.codprod = p_codprod;
 
  r_mov.codprod   := p_codprod;
  r_mov.descrprod := ad_get.descrproduto(p_codprod);
  r_mov.codemp    := p_codemp;
  r_mov.dtini     := p_dtini;
  r_mov.dtfim     := p_dtfim;
  r_mov.saldoini  := v_saldoini;
  r_mov.entradas  := v_entradas;
  r_mov.saidas    := v_saidas;
  r_mov.saldofim  := v_saldofim;
 
  pipe row(r_mov);
 
 end movestoque;

 function saldo_estoque(p_codemp   number,
                        p_codprod  number,
                        p_codlocal number,
                        p_controle varchar2,
                        p_dtini    date,
                        p_dtfim    date,
                        p_tipo     char) return float is
  v_result float;
 begin
 
  if p_tipo = 'I' then
  
   /*Select Sum(i.Qtdneg * i.Atualestoque)
    Into v_Result
    From Tgfite i
    Join Tgfcab c
      On c.Nunota = i.Nunota
   Where i.Codprod = p_Codprod
     And i.Codemp = p_Codemp
     And i.Codlocalorig = P_codlocal
     And (i.Controle = P_controle Or ' ' = ' ')
     And c.Dtentsai < p_DtIni
     And c.Statusnota = 'L'
     And i.Atualestoque <> 0
     And i.Reserva = 'N';*/
  
   select sum(e.qtdentradas) - sum(e.qtdsaidas)
     into v_result
     from tgfese e
    where e.codprod = p_codprod
      and e.codemp = p_codemp
      and e.controle = p_controle
      and e.dtreferencia < p_dtini
      and e.codlocalorig = p_codlocal;
  
  elsif p_tipo = 'E' then
  
   /*   Select Sum(i.Qtdneg * i.Atualestoque)
    Into v_Result
    From Tgfite i
    Join Tgfcab c
      On c.Nunota = i.Nunota
   Where i.Codprod = p_Codprod
     And i.Codemp = p_Codemp
     And i.Codlocalorig = P_codlocal
     And (i.Controle = P_controle Or ' ' = ' ')
     And i.Atualestoque = 1
     And c.Dtentsai Between p_DtIni And p_DtFim
     And c.Statusnota = 'L'
     And i.Atualestoque <> 0
     And i.Reserva = 'N';*/
  
   select sum(e.qtdentradas)
     into v_result
     from tgfese e
    where e.codprod = p_codprod
      and e.codemp = p_codemp
      and e.controle = p_controle
      and e.dtreferencia between p_dtini and p_dtfim
      and e.codlocalorig = p_codlocal;
  
  elsif p_tipo = 'S' then
  
   /*Select Sum(i.Qtdneg * i.Atualestoque)
    Into v_Result
    From Tgfite i
    Join Tgfcab c
      On c.Nunota = i.Nunota
   Where i.Codprod = p_Codprod
     And i.Codemp = p_Codemp
     And i.Codlocalorig = P_codlocal
     And (i.Controle = P_controle Or ' ' = ' ')
     And i.Atualestoque = -1
     And c.Dtentsai Between p_DtIni And p_DtFim
     And c.Statusnota = 'L'
     And i.Atualestoque <> 0
     And i.Reserva = 'N';*/
  
   select sum(e.qtdsaidas)
     into v_result
     from tgfese e
    where e.codprod = p_codprod
      and e.codemp = p_codemp
      and e.controle = p_controle
      and e.dtreferencia between p_dtini and p_dtfim
      and e.codlocalorig = p_codlocal;
  
  elsif p_tipo = 'F' then
  
   /*Select Sum(i.Qtdneg * i.Atualestoque)
    Into v_Result
    From Tgfite i
    Join Tgfcab c
      On c.Nunota = i.Nunota
   Where i.Codprod = p_Codprod
     And i.Codemp = p_Codemp
     And i.Codlocalorig = P_codlocal
     And (i.Controle = P_controle Or ' ' = ' ')
     And c.Dtentsai < p_DtFim + 1
     And c.Statusnota = 'L'
     And i.Atualestoque <> 0
     And i.Reserva = 'N';*/
  
   select sum(e.qtdentradas) - sum(qtdsaidas)
     into v_result
     from tgfese e
    where e.codprod = p_codprod
      and e.codemp = p_codemp
      and e.controle = p_controle
      and e.dtreferencia < p_dtfim + 1
      and e.codlocalorig = p_codlocal;
  
  end if;
 
  return nvl(v_result, 0);
 
 end saldo_estoque;

 function saldo_estoque(p_codemp   number,
                        p_codprod  number,
                        p_codlocal number,
                        p_controle varchar2,
                        p_nrobomba number,
                        p_dtini    date,
                        p_dtfim    date,
                        p_tipo     char) return float is
  v_result float;
  v_bomba  char(1);
 begin
  v_bomba := to_char(p_nrobomba);
 
  if p_tipo = 'S' then
  
   select sum(i.qtdneg * i.atualestoque)
     into v_result
     from tgfite i
     join tgfcab c
       on c.nunota = i.nunota
     join ad_tsfppcp p
       on i.codprod = p.codprod
      and p.nuppc = 1
    where i.codprod = p_codprod
      and c.codemp = p_codemp
      and i.codlocalorig = p_codlocal
      and (i.controle = p_controle or ' ' = ' ')
      and i.atualestoque = -1
      and c.dtentsai between p_dtini and p_dtfim
      and c.statusnota = 'L'
      and c.ad_dadosimport = v_bomba
      and i.reserva = 'N';
  
  end if;
 
  return nvl(v_result, 0);
 
 end saldo_estoque;

 function resultadoposto(p_codemp int default null,
                         p_dtini  date default null,
                         p_dtfin  date default null,
                         p_tipo   char) return float is
  v_totentsai     float := 0;
  v_totaldespesa  float := 0;
  v_totalperdaent float := 0;
  v_totalperdasai float := 0;
  v_resultado     float := 0;
  v_despesames    float := 0;
  v_deprecmes     float := 0;
  v_dtref         date;
  i               int := 0;
 begin
 
  i := round(months_between(p_dtfin, p_dtini));
 
  if i is null then
   v_resultado := 0;
   return v_resultado;
  end if;
 
  if i < 0 then
   i := i * -1;
  end if;
 
  for m in 1 .. i
  loop
  
   v_dtref := add_months(p_dtini, m - 1);
  
   select nvl(rme.vlrreal, rme.vlrprev)
     into v_despesames
     from tmimet met
    inner join tmirme rme
       on (rme.numet = met.numet)
    where rme.codexe = to_number(to_char(v_dtref, 'yy'))
      and rme.numet = 8614
      and met.codung = 175
      and rme.perini = v_dtref;
  
   --> depreciação
   select nvl(sum(vlrlanc), 0)
     into v_deprecmes
     from tcblan
    where codctactb = 11109
      and trunc(dtmov) between trunc(p_dtini, 'mm') and p_dtfin
      and codcencus = 90300100;
  
   v_totaldespesa := v_totaldespesa + v_despesames;
  
  end loop;
  -- total de despesas do período
  if p_tipo = 'D' then
   return v_totaldespesa;
  end if;
 
  /* Busca as perdas na entrada no período
  
  Select Nvl(Sum(Vlrtot * Atualestoque), 0)
    Into v_TotalPerdaEnt
    From ad_vw_comb c
   Where c.Tipmov = 'Q'
     And Codemp = p_codemp
     And c.Dtneg Between p_dtfin And p_dtfin;*/
 
  if p_tipo = 'E' then
   return v_totalperdaent;
  end if;
 
  -- Busca as perdas na saída no período
  /*Select Nvl(Sum(Vlrtot * Atualestoque), 0)
   Into v_TotalPerdaSai
   From ad_vw_comb c
  Where Tipmov = 'Q'
    And Codemp = p_codemp
    And Dtneg Between p_dtini And p_dtfin;*/
 
  if p_tipo = 'S' then
   return v_totalperdasai;
  end if;
 
  if p_tipo = 'R' then
  
   for c_posto in (select distinct codemp, codprod
                     from ad_vw_comb c
                    where c.dtneg between p_dtini and p_dtfin)
   loop
    v_totentsai := v_totentsai + diferenca_posto(c_posto.codemp, c_posto.codprod, p_dtini, p_dtfin);
   end loop;
  
   v_resultado := v_totentsai - v_totaldespesa - v_deprecmes;
  
  end if;
 
  return v_resultado;
 
 end resultadoposto;

 function diferenca_posto(p_codemp number, p_codprod number, p_dtnegini date, p_dtnegfin date)
  return float is
  v_customedio  float;
  v_qtdsaidas   float;
  v_vlrsaidas   float;
  v_difvlrcusto float;
 begin
  /* O intuito desta função é retornar a diferença entre o preço de vendo e o custo do produto */
 
  --> busca o valor do custo médio do produto
  begin
   select round(sum(qtdneg * vlrunit) / sum(qtdneg), 4)
     into v_customedio
     from ad_vw_comb
    where codemp = p_codemp
      and codprod = p_codprod
      and dtneg between p_dtnegini and p_dtnegfin
      and atualestoque = 1
      and tipmov = 'C';
  exception
   when others then
    v_customedio := 0;
   
  end;
 
  --> busca o valor total das movimentações de saída, 
  --> ignorando os veículos que não participam de acerto
  begin
  
   /*      Select Sum(qtdneg), Sum(vlrtot)
    Into v_QtdSaidass, v_VlrSaidas
    From ad_vw_comb c
    Join tgfvei v
      On c.codveiculo = v.codveiculo
   Where c.codprod = p_codprod
     And c.codemp = p_codemp
     And Trunc(c.dtneg) Between p_DtNegIni And p_DtNegFin
     And c.atualestoque = -1
     And c.tipmov = 'Q'
     And v.ad_codveictf Is Not Null
     And v.empparc = 'P'
     And c.codparc <> 38
     And Nvl(c.codparc, 0) <> 0
     And Not Exists (Select 1
            From tgfvei v2
           Where v.codveiculo = v2.codveiculo
             And codparc In (Select codparc
                               From tgfpar
                              Where nomeparc Like '%LOCALIZA%'));*/
  
   select sum(qtdneg), sum(vlrtot)
     into v_qtdsaidas, v_vlrsaidas
     from ad_vw_comb c
     join tgfvei v
       on c.codveiculo = v.codveiculo
    where c.codemp = p_codemp
      and c.codprod = p_codprod
      and c.dtneg between p_dtnegini and p_dtnegfin
      and c.atualestoque = -1
         --And nvl(v.ad_codveictf,0) = (Case When v.Ad_Tpeqpabast = 'IBUTTON' Or v.ad_tpeqpabast = 'TAG' Then 0 Else v.ad_codveictf End)
      and v.empparc = 'P'
      and c.codparc <> 38
      and nvl(v.codparc, 0) != 0
      and not exists
    (select 1
             from tgfvei v2
            where v.codveiculo = v2.codveiculo
              and codparc in (select codparc from tgfpar where nomeparc like '%LOCALIZA%'));
  
  exception
   when no_data_found then
    v_qtdsaidas := 0;
    v_vlrsaidas := 0;
  end;
 
  v_difvlrcusto := v_vlrsaidas - (v_qtdsaidas * v_customedio);
 
  return nvl(v_difvlrcusto, 0);
 
 end diferenca_posto;

 function kmporveiculo(p_codvei number, p_dtini date, p_dtfin date) return float is
  v_totalkm float;
 begin
 
  select sum(distancia)
    into v_totalkm
    from (select distinct dtneg, cab.codemp, cab.codtipoper, ad_get.nometop(codtipoper), cab.codparc,
                           cab.codveiculo, cab.ordemcarga,
                           nvl(r.distancia, ad_get.distanciacidade(e.codcid, p.codcid) * 2) distancia
             from tgfcab cab
            inner join tgfvei vei
               on cab.codveiculo = vei.codveiculo
             left join ad_tsfcat cat
               on vei.ad_codcat = cat.codcat
            inner join tgford o
               on cab.ordemcarga = o.ordemcarga
              and cab.codemp = o.codemp
              and cab.ordemcarga <> 0
             left join tgfrot r
               on o.codrota = r.codrota
            inner join tgfpar p
               on cab.codparc = p.codparc
            inner join tsiemp e
               on cab.codemp = e.codemp
            where cab.dtneg between p_dtini and p_dtfin
              and tipmov in ('V', 'T', 'N', 'C')
              and vei.codveiculo = p_codvei);
 
  return nvl(v_totalkm, 1);
 
 exception
  when others then
   return null;
 end kmporveiculo;

 function kmporcategoriavei(p_codcat number, p_dtini date, p_dtfin date) return float is
  v_totalkm float;
 begin
  select sum(distancia)
    into v_totalkm
    from (select distinct dtneg, cab.codemp, cab.codtipoper, ad_get.nometop(codtipoper), cab.codparc,
                           cab.codveiculo, cab.ordemcarga,
                           nvl(r.distancia, ad_get.distanciacidade(e.codcid, p.codcid) * 2) distancia
             from tgfcab cab
            inner join tgfvei vei
               on cab.codveiculo = vei.codveiculo
             left join ad_tsfcat cat
               on vei.ad_codcat = cat.codcat
            inner join tgford o
               on cab.ordemcarga = o.ordemcarga
              and cab.codemp = o.codemp
              and cab.ordemcarga <> 0
             left join tgfrot r
               on o.codrota = r.codrota
            inner join tgfpar p
               on cab.codparc = p.codparc
            inner join tsiemp e
               on cab.codemp = e.codemp
            where cab.dtneg between p_dtini and p_dtfin
              and tipmov in ('V', 'T', 'N', 'C')
              and vei.ad_codcat = p_codcat);
 
  return nvl(v_totalkm, 1);
 
 end kmporcategoriavei;

 function kmporregiao(p_codreg number, p_dtini date, p_dtfin date) return float is
 
  v_distancia float;
 begin
 
  select sum(distancia)
    into v_distancia
    from (select distinct c.codemp, c.dtneg, v.categoria, c.codveiculo, v.marcamodelo, c.ordemcarga,
                           o.codrota, r.descrrota,
                           nvl(r.distancia, ad_get.distanciacidade(e.codcid, p.codcid)) distancia
             from tgfcab c
             join tgfvei v
               on c.codveiculo = v.codveiculo
             join tgford o
               on c.ordemcarga = o.ordemcarga
              and c.codemp = o.codemp
             left join tgfrot r
               on o.codrota = r.codrota
             join tgfpar p
               on c.codparc = p.codparc
             join tsiemp e
               on c.codemp = e.codemp
            where statusnota = 'L'
              and dtneg between p_dtini and p_dtfin
              and c.tipmov in ('V', 'T', 'N', 'C')
              and p.codreg = p_codreg
               or p.codreg in (select codreg
                                 from tsireg r
                                where r.codreg = p_codreg
                                   or r.codregpai = p_codreg)) reg;
 
  return v_distancia;
 end kmporregiao;

 function qtd_aferida(p_data date, p_codprod number, p_tipo char, bomba_tanque int) return float is
  v_qtd float;
 begin
  if p_tipo = 'B' then
   select nvl(sum(case
                   when tipo = 'A' then
                    qtdlits * -1
                   else
                    qtdlits
                  end),
              0)
     into v_qtd
     from ad_tsfadc a
    where a.codprod = p_codprod
      and a.categoria = 'B'
      and to_number(a.bomba) = bomba_tanque
      and trunc(a.dtreferencia) = p_data;
  elsif p_tipo = 'T' then
   select nvl(sum(case
                   when tipo = 'A' then
                    qtdlits * -1
                   else
                    qtdlits
                  end),
              0)
     into v_qtd
     from ad_tsfadc a
    where a.codprod = p_codprod
      and a.categoria = 'T'
      and to_number(a.nrotanque) = bomba_tanque
      and trunc(a.dtreferencia) = p_data;
  else
   v_qtd := 0;
  end if;
 
  return v_qtd;
 
 end qtd_aferida;

 function afericao_bomba(p_dtreferencia date) return rc_bomba
 pipelined is
  v_inicioturno date;
  v_fimturno    date;
  v_qtdsaidas   float;
  v_qtddif      float;
  x             ty_aferebomba;
 begin
  for c_mov in (select adc.dtreferencia, pcp.codprod, pro.descrprod, to_number(adc.bomba) bomba,
                       sum(case
                            when tipo = 'A' then
                             adc.qtdlits * -1
                            else
                             qtdlits
                           end) qtd_aferida
                  from ad_tsfppcp pcp
                  join tgfpro pro
                    on pcp.codprod = pro.codprod
                  join ad_tsfadc adc
                    on pcp.codprod = adc.codprod
                   and adc.categoria = 'B'
                   and dtreferencia = p_dtreferencia
                 group by adc.dtreferencia, pcp.codprod, pro.descrprod, adc.bomba
                 order by adc.dtreferencia, pcp.codprod, adc.bomba)
  loop
   select min(dhafericao), max(dhafericao)
     into v_inicioturno, v_fimturno
     from ad_tsfadc
    where dtreferencia = p_dtreferencia
      and codprod = c_mov.codprod
      and bomba = c_mov.bomba;
  
   v_qtdsaidas := round(abs(saldo_estoque(2,
                                          c_mov.codprod,
                                          3300,
                                          'POSTOABAST',
                                          nvl(c_mov.bomba, 0),
                                          v_inicioturno,
                                          v_fimturno,
                                          'S')),
                        0);
  
   v_qtddif := c_mov.qtd_aferida - v_qtdsaidas;
  
   dbms_output.put_line(c_mov.dtreferencia || ', ' || c_mov.codprod || ', ' || c_mov.descrprod || ', ' ||
                        c_mov.bomba || ', ' || c_mov.qtd_aferida || ', ' || v_qtdsaidas || ', ' ||
                        v_qtddif);
  
   x.dtreferencia := c_mov.dtreferencia;
   x.codprod      := c_mov.codprod;
   x.descrprod    := c_mov.descrprod;
   x.bomba        := nvl(c_mov.bomba, 0);
   x.qtd_aferida  := c_mov.qtd_aferida;
   x.saidas       := v_qtdsaidas;
   x.diferenca    := v_qtddif;
  
   pipe row(x);
  
  end loop;
 
 end afericao_bomba;

 function saldo_estoque_turno(p_codemp   number,
                              p_codprod  number,
                              p_codlocal number,
                              p_controle varchar2,
                              p_dtini    date,
                              p_dtfim    date,
                              p_tipo     char) return float is
  v_result float;
 begin
 
  if p_tipo = 'I' then
  
   select sum(i.qtdneg * i.atualestoque)
     into v_result
     from tgfite i
     join tgfcab c
       on c.nunota = i.nunota
    where i.codprod = p_codprod
      and i.codemp = p_codemp
      and i.codlocalorig = p_codlocal
      and (i.controle = p_controle or ' ' = ' ')
      and c.dtentsai < p_dtini
      and c.statusnota = 'L'
      and i.atualestoque <> 0
      and i.reserva = 'N';
  
  elsif p_tipo = 'E' then
  
   select sum(i.qtdneg * i.atualestoque)
     into v_result
     from tgfite i
     join tgfcab c
       on c.nunota = i.nunota
    where i.codprod = p_codprod
      and i.codemp = p_codemp
      and i.codlocalorig = p_codlocal
      and (i.controle = p_controle or ' ' = ' ')
      and i.atualestoque = 1
      and c.dtentsai between p_dtini and p_dtfim
      and c.statusnota = 'L'
      and i.atualestoque <> 0
      and i.reserva = 'N';
  
  elsif p_tipo = 'S' then
  
   select sum(i.qtdneg * i.atualestoque)
     into v_result
     from tgfite i
     join tgfcab c
       on c.nunota = i.nunota
    where i.codprod = p_codprod
      and i.codemp = p_codemp
      and i.codlocalorig = p_codlocal
      and (i.controle = p_controle or ' ' = ' ')
      and i.atualestoque = -1
      and c.dtentsai between p_dtini and p_dtfim
      and c.statusnota = 'L'
      and i.atualestoque <> 0
      and i.reserva = 'N';
  
  elsif p_tipo = 'F' then
  
   select sum(i.qtdneg * i.atualestoque)
     into v_result
     from tgfite i
     join tgfcab c
       on c.nunota = i.nunota
    where i.codprod = p_codprod
      and i.codemp = p_codemp
      and i.codlocalorig = p_codlocal
      and (i.controle = p_controle or ' ' = ' ')
      and c.dtentsai < p_dtfim + 1
      and c.statusnota = 'L'
      and i.atualestoque <> 0
      and i.reserva = 'N';
  
  end if;
 
  return nvl(v_result, 0);
 
 end saldo_estoque_turno;

 --- importado da pkg posto

 function distancia(p_dataini date, p_datafin date, p_codcat int) return float is
  v_distancia float;
 begin
 
  begin
   select sum(distancia)
     into v_distancia
     from ad_tsfkmr
    where trunc(dtentsai) between p_dataini and p_datafin
      and codcat = p_codcat;
  
  exception
   when others then
    v_distancia := 0;
  end;
 
  return nvl(v_distancia, 0);
 end;

 function distancia(p_dataini date, p_datafin date, p_codcat int, p_codvei number) return float is
  v_distancia float;
 begin
 
  begin
   select sum(distancia)
     into v_distancia
     from ad_tsfkmr
    where trunc(dtentsai) between p_dataini and p_datafin
      and codcat = p_codcat
      and codveiculo = p_codvei;
  
  exception
   when others then
    v_distancia := 0;
  end;
 
  return nvl(v_distancia, 0);
 end;

 /* retorna sempre o código do cavalo do conjunto vinculado */
 function veiculo(p_codvei number) return number is
  v_nuconj number;
  v_codvei number;
 begin
  begin
   select nuconjvei into v_nuconj from ad_itemconjvei where codveiculo = p_codvei;
  
  exception
   when others then
    v_nuconj := 0;
  end;
 
  if v_nuconj <> 0 then
   select codveiculo
     into v_codvei
     from ad_itemconjvei icv
    where nuconjvei = v_nuconj
      and icv.tipo = 'V';
  else
   v_codvei := p_codvei;
  end if;
 
  return v_codvei;
 
 end veiculo;

 function get_codreg(p_codemp number, p_ordcarga number) return number is
  v_codreg number;
 begin
 
  -- busca na ordem de carga
  begin
   select codreg
     into v_codreg
     from tgford o
    where o.ordemcarga = p_ordcarga
      and o.codemp = p_codemp;
  exception
   when no_data_found then
    select codreg
      into v_codreg
      from tgford o
     where o.ordemcarga = p_ordcarga
       and o.codemp <> p_codemp
       and rownum = 1;
   when too_many_rows then
    select codreg
      into v_codreg
      from tgford o
     where o.ordemcarga = p_ordcarga
       and o.codemp = p_codemp
       and rownum = 1;
   when others then
    v_codreg := 0;
  end;
 
  if v_codreg = 0 then
  
   begin
    select distinct p.codreg
      into v_codreg
      from tgfcab c
      join tgfpar p
        on c.codparc = p.codparc
     where c.ordemcarga = p_ordcarga
       and c.codemp = p_codemp
       and rownum = 1;
   exception
    when no_data_found then
     select distinct p.codreg
       into v_codreg
       from tgfcab c
       join tgfpar p
         on c.codparc = p.codparc
      where c.ordemcarga = p_ordcarga
        and c.codemp <> p_codemp
        and rownum = 1;
    when too_many_rows then
     select distinct r.codregpai
       into v_codreg
       from tgfcab c
       join tgfpar p
         on c.codparc = p.codparc
       join tsireg r
         on p.codreg = r.codreg
      where c.ordemcarga = p_ordcarga
        and c.codemp <> p_codemp
        and rownum = 1;
   end;
  
  end if;
 
  if v_codreg = 0 then
   select distinct r.codregpai
     into v_codreg
     from tgfcab c
     join tgfpar p
       on c.codparc = p.codparc
     join tsireg r
       on p.codreg = r.codreg
    where c.ordemcarga = p_ordcarga
      and c.codemp <> p_codemp
      and rownum = 1;
  end if;
 
  return nvl(v_codreg, 0);
 
 end get_codreg;

 /* Busca a ordem de carga da entrega para vincular com o abastecimento */
 function get_ordemcarga(p_nunota number) return number is
  cab          tgfcab % rowtype;
  v_ordemcarga number;
 begin
 
  v_ordemcarga := null;
 
  select * into cab from tgfcab where nunota = p_nunota;
 
  cab.codveiculo := veiculo(cab.codveiculo);
 
  begin
   -- pesquisa a ordem de carga olhando para trás (antes do abastecimento)
  
   select ordemcarga
     into v_ordemcarga
     from ad_tsfkmr k
    where trunc(k.dtentsai, 'mm') = trunc(cab.dtentsai, 'mm')
      and k.codveiculo = cab.codveiculo
      and k.codemp in (1, 2, 3, 5, 14, 16)
      and k.codparc = cab.codparc
      and k.dtentsai = (select max(k2.dtentsai)
                          from ad_tsfkmr k2
                         where k2.codemp = k.codemp
                           and k2.codparc = k.codparc
                           and k.codveiculo = k2.codveiculo
                           and k2.dtentsai <= cab.dtentsai);
  
  exception
   when too_many_rows then
    select ordemcarga
      into v_ordemcarga
      from ad_tsfkmr k
     where trunc(k.dtentsai, 'mm') = trunc(cab.dtentsai, 'mm')
       and k.codveiculo = cab.codveiculo
       and k.codemp in (1, 2, 3, 5, 14, 16)
       and k.codparc = cab.codparc
       and k.dtentsai = (select max(k2.dtentsai)
                           from ad_tsfkmr k2
                          where k2.codemp = k.codemp
                            and k2.codparc = k.codparc
                            and k.codveiculo = k2.codveiculo
                            and k2.dtentsai <= cab.dtentsai)
       and rownum = 1
     order by ordemcarga;
   when no_data_found then
    -- se não encontrar nada buscando pra trás, busca pra frente dentro do mês, visa contornar a questão do inicio/final do mês
    begin
     select ordemcarga
       into v_ordemcarga
       from ad_tsfkmr k
      where trunc(k.dtentsai, 'mm') = trunc(cab.dtentsai, 'mm')
        and k.codveiculo = cab.codveiculo
        and k.codemp in (1, 2, 3, 5, 14, 16)
        and k.codparc = cab.codparc
        and k.dtentsai = (select min(k2.dtentsai)
                            from ad_tsfkmr k2
                           where k2.codemp = k.codemp
                             and k2.codparc = k.codparc
                             and k.codveiculo = k2.codveiculo
                             and k2.dtentsai >= cab.dtentsai);
    
    exception
     when no_data_found then
      -- se entrar aqui, phodeu, não há ordem de carga para esse veículo / parceiro.
      dbms_output.put_line('no data found - ' || cab.nunota);
      v_ordemcarga := 0;
     
     when too_many_rows then
     
      select ordemcarga
        into v_ordemcarga
        from ad_tsfkmr k
       where trunc(k.dtentsai, 'mm') = trunc(cab.dtentsai, 'mm')
         and k.codveiculo = cab.codveiculo
         and k.codemp in (1, 2, 3, 5, 14, 16)
         and k.codparc = cab.codparc
         and k.dtentsai = (select min(k2.dtentsai)
                             from ad_tsfkmr k2
                            where k2.codemp = k.codemp
                              and k2.codparc = k.codparc
                              and k.codveiculo = k2.codveiculo
                              and k2.dtentsai >= cab.dtentsai)
         and rownum = 1;
    end;
   
   when others then
    dbms_output.put_line(cab.nunota);
    dbms_output.put_line(cab.codparc);
    dbms_output.put_line(cab.codveiculo);
    dbms_output.put_line(to_date(cab.dtentsai, 'dd/mm/yyyy hh24:mi:ss'));
    v_ordemcarga := 0;
  end;
 
  return nvl(v_ordemcarga, 0);
 
  dbms_output.put_line(v_ordemcarga);
 
 end get_ordemcarga;

 /*############ Busca a quantidade de litros por região Avô ###################*/
 function get_qtdlitros_reg(p_dataini date, p_datafin date, p_codreg number, p_grau int)
  return float is
  v_qtdlitros float;
 begin
 
  /*    Select Sum(a.Qtdlitros)
   Into v_qtdlitros
   From Ad_tsfabast a
   Join Tsireg r On a.Codreg = r.Codreg
   Join Tsireg rp On r.Codregpai = rp.Codreg
   Join Tsireg ra On rp.Codregpai = ra.Codreg
  Where Dtneg Between p_dataini And p_datafin
    And (Case
          When p_grau = 1 Then
           ra.Codreg
          When p_grau = 2 Then
           rp.Codreg
          When p_grau = 3 Then
           r.Codreg
        End) = p_codreg;*/
 
  select sum(a.qtdlitros)
    into v_qtdlitros
    from ad_vw_abast a
   where trunc(dtentsai) between p_dataini and p_datafin
     and (case
           when p_grau = 1 then
            a.codreg_a
           when p_grau = 2 then
            a.codreg_p
           when p_grau = 3 then
            a.codreg_n
          end) = p_codreg;
 
  return nvl(v_qtdlitros, 0);
 
 end get_qtdlitros_reg;

 function abast(p_dataini date, p_datafin date) return tb_abastecimento
 pipelined is
  t ty_abastecimento;
 begin
 
  for a in (select cab.nunota, cab.dtneg, cab.codemp, cab.codtipoper, cab.codveiculo, cat.codcat,
                   cab.codparc, ite.qtdneg
              from tgfite ite
              join tgfcab cab
                on ite.nunota = cab.nunota
              join tgfvei vei
                on cab.codveiculo = vei.codveiculo
               and nvl(ad_controlakm, 'N') = 'S'
              left join ad_tsfcat cat
                on vei.ad_codcat = cat.codcat
              join ad_tsfppcp ppc
                on ite.codprod = ppc.codprod
              join ad_tsfppct ppt
                on cab.codtipoper = ppt.codtipoper
             where tipmov = 'Q'
               and cab.codemp = 2
               and cab.codveiculo <> 0
               and cab.dtneg between p_dataini and p_datafin)
  loop
   t.nunota     := a.nunota;
   t.dtneg      := a.dtneg;
   t.codemp     := a.codemp;
   t.codveiculo := a.codveiculo;
   t.codcat     := a.codcat;
   t.codparc    := a.codparc;
   t.qtdneg     := a.qtdneg;
   t.ordemcarga := get_ordemcarga(a.nunota);
  
   pipe row(t);
  
  end loop;
 
 end abast;

 function temp_retorna_regiao(p_codreg number, p_grau number) return number is
  v_codreg number;
 begin
  for c_reg in (select reg4.codreg codreg_4, reg3.codreg codreg_3, reg2.codreg codreg_2,
                       reg1.codreg codreg_1
                  from tsireg reg4
                  left join tsireg reg3
                    on reg4.codregpai = reg3.codreg
                  left join tsireg reg2
                    on reg3.codregpai = reg2.codreg
                  left join tsireg reg1
                    on reg2.codregpai = reg1.codreg
                 where (reg4.codreg = p_codreg or reg3.codreg = p_codreg or reg2.codreg = p_codreg or
                       reg1.codreg = p_codreg))
  loop
   if p_grau = 1 then
    v_codreg := c_reg.codreg_1;
   elsif p_grau = 2 then
    v_codreg := c_reg.codreg_2;
   elsif p_grau = 3 then
    v_codreg := c_reg.codreg_3;
   elsif p_grau = 4 then
    v_codreg := c_reg.codreg_4;
   end if;
  
  end loop;
 
  if v_codreg is null then
   v_codreg := p_codreg;
  end if;
 
  return nvl(v_codreg, 0);
 
 end temp_retorna_regiao;

 function get_codreg_acima(p_codreg_origem number, p_grau_desejado int) return number is
  v_grau   int;
  p_codreg number;
  v_codreg number;
 begin
  p_codreg := p_codreg_origem;
 
  select grau into v_grau from tsireg where codreg = p_codreg;
 
  -- decrescente do nivel 4 pro nivel 1
 
  if v_grau > p_grau_desejado then
   for r in p_grau_desejado .. v_grau - 1
   loop
    begin
     select codregpai
       into v_codreg
       from tsireg
      where codreg = p_codreg
        and codregpai > 0;
    exception
     when no_data_found then
      exit;
    end;
    p_codreg := v_codreg;
   end loop;
  else
   v_codreg := p_codreg;
  end if;
 
  dbms_output.put_line(v_codreg);
 
  return nvl(v_codreg, p_codreg_origem);
 
 end get_codreg_acima;

 function get_peso_ordcarga(p_codemp number, p_ordemcarga number) return float is
  functionresult float;
 begin
  select sum(nvl(cab.pesobruto, cab.peso))
    into functionresult
    from tgfcab cab
   where cab.codemp = p_codemp
     and cab.ordemcarga = p_ordemcarga;
  return functionresult;
 exception
  when others then
   functionresult := 0;
 end get_peso_ordcarga;

 function get_distancia_ordcarga_cat(p_data date) return type_tab_dist_oc
 pipelined is
 begin
  null;
 end get_distancia_ordcarga_cat;

 procedure ajusta_controle_comb(p_codprod number, p_tanque number, p_msg out varchar2) is
  i         int := 0;
  v_sql     varchar2(4000);
  v_codprod number;
  v_tanque  char(1);
  v_erro    varchar2(4000);
 begin
  begin
   v_sql := 'Alter Trigger Trg_inc_upd_tgfest_sf Disable';
   execute immediate v_sql;
  
   v_sql := 'Alter Trigger Trg_upt_tgfite Disable';
   execute immediate v_sql;
  exception
   when others then
    p_msg := sqlerrm;
  end;
 
  for c_ite in (select c.nunota, sequencia, controle
                  from tgfite i
                  join tgfcab c
                    on i.nunota = c.nunota
                 where codprod = v_codprod
                   and controle <> to_char(v_tanque)
                   and dtneg >= '01/01/2017')
  loop
   update tgfite
      set controle = to_char(v_tanque)
    where nunota = c_ite.nunota
      and sequencia = c_ite.sequencia
      and codprod = v_codprod;
  
   i := i + 1;
  
   if i = 100 then
    commit;
   end if;
  
  end loop;
 
  begin
   v_sql := 'Alter Trigger Trg_inc_upd_tgfest_sf enable';
   execute immediate v_sql;
  
   v_sql := 'Alter Trigger Trg_upt_tgfite enable';
   execute immediate v_sql;
  exception
   when others then
    p_msg := sqlerrm;
  end;
 
 end;

end;
/
