create or replace package ad_pkg_fci is

 -- Author  : MARCUS.RANGEL
 -- Created : 04/11/2019 17:24:19
 -- Purpose : agrupar os objetos utilizados na rotina de fechamento de comissão de integrado

 lote lote_ave%rowtype;

 c_prodfemeabnf  number := 3602; -- FRANGO VIVO FEMEA (BNF)
 c_prodmachobnf  number := 3603; -- FRANGO VIVO MACHO (BNF)
 c_prodsexadobnf number := 3604; -- FRANGO VIVO SEXADO (BNF)

 c_codprodfemea  number := 3607; -- FRANGO VIVO FEMEA (VND)
 c_codprodmacho  number := 3606; -- FRANGO VIVO MACHO (VND)
 c_codprodsexado number := 3605; -- FRANGO VIVO SEXADO (VND)

 c_mortfemea  number := 21196;
 c_mortmacho  number := 21197;
 c_mortsexado number := 15054;

 type t_dados_notas is table of ad_tsffcinf%rowtype;

 -- M. Rangel - Busca as informações da LOTE_AVE
 function get_dados_lote(p_nrolote number) return lote_ave%rowtype;

 function get_dados_tabela(p_nrolote number, p_tipo varchar2) return number deterministic;
 procedure get_dados_tabela(p_nrolote number,
                            p_codemp  number,
                            p_tabela  out ad_tsftci%rowtype);

 procedure get_dados_fechamento(p_nrolote number,
                                p_lote    out ad_tsffci%rowtype,
                                p_conf    out ad_tsffciconf%rowtype);

 -- M. Rangel, retorna as notas de ração
 function get_notas_racao(p_nrolote number) return t_dados_notas
 pipelined;

 function get_notas_transp(p_nrolote number) return t_dados_notas
 pipelined;

 function get_notas_fin(p_nrolote number) return t_dados_notas
 pipelined;

 -- total de ração transf para integrado no periodo do lote tops 331,334
 function get_total_racao_lote(p_nrolote number) return float deterministic;

 function get_config(p_nrolote number) return int;
 procedure get_config(p_dtref in date, conf out ad_tsffciconf%rowtype);

 -- total transp top 27 de frango do integrado
 function get_qtd_transp_lote(p_nrolote number) return float deterministic;

 function get_codemp_lote(p_nrolote number) return int deterministic;

 function get_qtd_sexo_lote(p_nrolote number, p_sexo varchar2) return float deterministic;

 function get_qtd_abatida(p_nrolote number) return float deterministic;

 function get_pesoliq_balanca(p_nrolote number) return float deterministic;

 function get_total_despesas(p_nrolote number) return float;

 function get_perc_com(p_ipsul float, p_ipsum float) return float;

 -- calcula/recalcula valores básicos da tela de comissão por lote
 procedure set_dados_lote(p_nrolote number, p_errmsg out varchar2);

 -- popula a aba financeiro da tela de fechamento de comissao
 procedure set_dados_financeiro(p_nrolote number, p_errmsg out varchar2);

 procedure set_dados_notas(p_nrolote number, p_errmsg out varchar2);

 procedure set_bnf_lotereal(p_nrolote number, p_errmsg out varchar2);

 procedure set_bnf_carcaca(p_nrolote number, p_errmsg out varchar2);

 procedure set_bnf_mortalidade(p_nrolote in number,
                               p_sem1    in number,
                               p_sem2    in number,
                               p_sem3    in number,
                               p_sem4    in number,
                               p_errmsg  out varchar2);

end ad_pkg_fci;
/
create or replace package body ad_pkg_fci is

 cd int := 3;
 -- retorna os dados da lote_ave
 function get_dados_lote(p_nrolote number) return lote_ave%rowtype is
 begin
  select *
    into ad_pkg_var.lote
    from lote_ave
   where numlote = p_nrolote
     and status = 'F';
 
  return ad_pkg_var.lote;
 exception
  when no_data_found then
   raise_application_error(-20105, 'Lote não existe ou não está fechado!');
 end get_dados_lote;

 procedure get_dados_fechamento(p_nrolote number,
                                p_lote    out ad_tsffci%rowtype,
                                p_conf    out ad_tsffciconf%rowtype) as
 begin
 
  select * into p_lote from ad_tsffci where numlote = p_nrolote;
 
  select * into p_conf from ad_tsffciconf where nuconf = get_config(p_nrolote);
 
 exception
  when others then
   raise;
 end;

 -- retorna a quantidade separndo por sexo do animal
 function get_qtd_sexo_lote(p_nrolote number, p_sexo varchar2) return float deterministic is
 begin
 
  lote := get_dados_lote(p_nrolote);
 
  select sum(qtdfem), sum(qtdmac)
    into ad_pkg_var.qtd1, ad_pkg_var.qtd2
    from (select (case
                   when p.descrprod like ('%FEM%') then
                    (i.qtdneg)
                   else
                    0
                  end) as qtdfem,
                  (case
                   when p.descrprod like ('%MACH%') then
                    (i.qtdneg)
                   else
                    0
                  end) as qtdmac
             from tgfcab c
             join tgfite i
               on i.nunota = c.nunota
             join tgfpro p
               on i.codprod = p.codprod
             join tgfgru g
               on g.codgrupoprod = p.codgrupoprod
            where c.codparc = lote.codparc
              and c.statusnota = 'L'
              and i.statusnota = 'L'
              and c.codtipoper = 27
              and c.dtfatur between lote.dataini and lote.datafim
              and i.sequencia > 0);
 
  if p_sexo = 'F' then
   return ad_pkg_var.qtd1;
  elsif p_sexo = 'M' then
   return ad_pkg_var.qtd2;
  else
   return 0;
  end if;
 
 exception
  when others then
   return 0;
 end get_qtd_sexo_lote;

 -- busca o codemp das notas do período
 function get_codemp_lote(p_nrolote number) return int deterministic is
 begin
 
  lote := get_dados_lote(p_nrolote);
 
  select c.codemp
    into ad_pkg_var.resulti
    from tgfcab c
   where c.codparc = lote.codparc
     and c.statusnota = 'L'
     and c.codtipoper in (331, 334, 27)
     and c.dtfatur between lote.dataini and lote.datafim
   group by c.codemp;
 
  return ad_pkg_var.resulti;
 
 exception
  when others then
   return 0;
 end get_codemp_lote;

 -- função que retorna as notas de transporte do parceiro no período
 function get_notas_transp(p_nrolote number) return t_dados_notas
 pipelined as
  notas t_dados_notas := t_dados_notas();
 begin
  lote := get_dados_lote(p_nrolote);
 
  select p_nrolote, null, c.codemp, c.nunota, null, c.numnota, c.serienota, c.dtneg,
         c.dtfatur, c.vlrnota, c.codtipoper, c.tipmov, c.statusnota, c.statusnfe, i.qtdneg
    bulk collect
    into notas
    from tgfcab c
    join tgfite i
      on i.nunota = c.nunota
    join tgfpro p
      on i.codprod = p.codprod
    join tgfgru g
      on g.codgrupoprod = p.codgrupoprod
   where c.codparc = lote.codparc
     and c.statusnota = 'L'
     and i.statusnota = 'L'
     and c.codtipoper = 27
     and c.dtfatur between lote.dataini and lote.datafim
     and i.sequencia > 0;
 
  for i in notas.first .. notas.last
  loop
   pipe row(notas(i));
  end loop;
 
 end get_notas_transp;

 -- retorna as notas de transferência de ração para o parceiro no período
 function get_notas_racao(p_nrolote number) return t_dados_notas
 pipelined is
  notas t_dados_notas := t_dados_notas();
 begin
 
  lote := get_dados_lote(p_nrolote);
 
  select p_nrolote, null, c.codemp, c.nunota, null, c.numnota, c.serienota, c.dtneg,
         c.dtfatur, c.vlrnota, c.codtipoper, c.tipmov, c.statusnota, c.statusnfe, i.qtdneg
    bulk collect
    into notas
    from tgfcab c
    join tgfite i
      on i.nunota = c.nunota
    join tgfpro p
      on i.codprod = p.codprod
    join tgfgru g
      on g.codgrupoprod = p.codgrupoprod
   where c.codparc = lote.codparc
     and c.statusnota = 'L'
     and i.statusnota = 'L'
     and c.codtipoper in (331, 334)
     and c.dtfatur between lote.dataini and lote.datafim
     and p.descrprod like ('%RACAO%')
     and i.sequencia > 0
     and i.atualestoque <> 0;
 
  for i in notas.first .. notas.last
  loop
   pipe row(notas(i));
  end loop;
 
 end get_notas_racao;

 -- retorna a movimentação financeira do parceiro no período
 function get_notas_fin(p_nrolote number) return t_dados_notas
 pipelined as
  notas t_dados_notas := t_dados_notas();
 begin
  lote := get_dados_lote(p_nrolote);
 
  select p_nrolote, null, f.codemp, null, f.nufin, f.numnota, f.serienota, f.dtneg,
         f.dtvenc, f.vlrdesdob, f.codtipoper, 'I', null, null, 1
    bulk collect
    into notas
    from tgffin f
   where f.codparc = lote.codparc
     and dtneg between lote.dataini and lote.datafim
     and recdesp = 1;
 
  for i in notas.first .. notas.last
  loop
   pipe row(notas(i));
  end loop;
 
 end get_notas_fin;

 -- função auxiliar que retorna o total de ração transferida no período
 function get_total_racao_lote(p_nrolote number) return float deterministic is
 begin
  select sum(qtdneg) into ad_pkg_var.resultf from table(get_notas_racao(p_nrolote));
  return ad_pkg_var.resultf;
 exception
  when others then
   return 0;
 end get_total_racao_lote;

 -- função auxiliar que retorna o total de aves transferidas no período
 function get_qtd_transp_lote(p_nrolote number) return float deterministic is
 begin
  select sum(qtdneg) into ad_pkg_var.resultf from table(get_notas_transp(p_nrolote));
  return ad_pkg_var.resultf;
 exception
  when others then
   return 0;
 end get_qtd_transp_lote;

 -- função auxiliar que retorna o total dos adiantamentos do integrado
 function get_total_despesas(p_nrolote number) return float as
 begin
  select sum(vlrnota) into ad_pkg_var.resultf from table(get_notas_fin(p_nrolote));
  return ad_pkg_var.resultf;
 exception
  when others then
   return - 1;
 end get_total_despesas;

 -- função que retorna o total de aves abatidas e o peso líquido no período
 function get_dados_balanca(p_nrolote number, p_tipo varchar2) return float as
 begin
  lote := get_dados_lote(p_nrolote);
 
  select sum(peg.qtdavesabat), sum(peg.pesoliq)
    into ad_pkg_var.resultf, ad_pkg_var.resultn
    from tgfpeg peg
    join tgfcab cab
      on peg.numnota = cab.numnota
     and cab.codtipoper = 27
   where 1 = 1
     and peg.dhiniciopega between lote.dataini and lote.datafim
     and cab.codparc = lote.codparc
     and peg.produto = 'FRANGO VIVO';
 
  if lower(p_tipo) = 'qtdaves' then
   return ad_pkg_var.resultf;
  elsif lower(p_tipo) = 'peso' then
   return ad_pkg_var.resultn;
  end if;
 exception
  when others then
   return - 1;
 end get_dados_balanca;

 -- função auxiliar retorna a quantidade de aves
 function get_qtd_abatida(p_nrolote number) return float deterministic is
 begin
  ad_pkg_var.resultf := get_dados_balanca(p_nrolote, 'qtdaves');
  return ad_pkg_var.resultf;
 end get_qtd_abatida;

 -- função auxiliar retorna o peso líquido total
 function get_pesoliq_balanca(p_nrolote number) return float deterministic is
 begin
  ad_pkg_var.resultf := get_dados_balanca(p_nrolote, 'peso');
  return ad_pkg_var.resultf;
 end get_pesoliq_balanca;

 -- função que retorna dados da tabela de comissão do integrado
 function get_dados_tabela(p_nrolote number, p_tipo varchar2) return number deterministic as
  lote lote_ave%rowtype;
 begin
  lote := get_dados_lote(p_nrolote);
 
  select tci.codtab, tci.percom, tci.preco
    into ad_pkg_var.resulti, ad_pkg_var.resultn, ad_pkg_var.resultf
    from ad_tsftci tci
   where tci.codemp = get_codemp_lote(p_nrolote)
     and tci.dtvigor = (select max(dtvigor)
                          from ad_tsftci i
                         where i.codtab = tci.codtab
                           and i.codemp = tci.codemp
                           and dtvigor <= lote.datafim);
 
  if lower(p_tipo) = 'codtab' then
   return ad_pkg_var.resulti;
  elsif lower(p_tipo) = 'percom' then
   return ad_pkg_var.resultn;
  elsif lower(p_tipo) = 'preco' then
   return ad_pkg_var.resultf;
  else
   return 0;
  end if;
 
 exception
  when others then
   return 0;
 end get_dados_tabela;

 procedure get_dados_tabela(p_nrolote number,
                            p_codemp  number,
                            p_tabela  out ad_tsftci%rowtype) as
  lote lote_ave%rowtype;
 begin
  lote := get_dados_lote(p_nrolote);
 
  select *
    into p_tabela
    from ad_tsftci tci
   where tci.codemp = p_codemp
     and tci.dtvigor = (select max(dtvigor)
                          from ad_tsftci i
                         where i.codtab = tci.codtab
                           and i.codemp = tci.codemp
                           and dtvigor <= lote.datafim);
 exception
  when others then
   raise;
 end get_dados_tabela;

 -- métodos get da tabela
 function get_codtab_int(p_nrolote number) return number as
 begin
  return get_dados_tabela(p_nrolote, 'codtab');
 end;

 function get_percom_tab(p_nrolote number) return number as
 begin
  return get_dados_tabela(p_nrolote, 'percom');
 end;

 function get_preco_tab(p_nrolote number) return number as
 begin
  return get_dados_tabela(p_nrolote, 'preco');
 end;
 ---

 function get_config(p_nrolote number) return int is
  v_datafim date;
  v_nuconf  int;
 begin
  begin
   select datafim into v_datafim from lote_ave where numlote = p_nrolote;
  exception
   when others then
    return - 1;
  end;
 
  -- busca set de parametros
  begin
   select nuconf
     into v_nuconf
     from ad_tsffciconf c
    where c.dtvigor = (select max(dtvigor)
                         from ad_tsffciconf c2
                        where c2.nuconf = c.nuconf
                          and c2.dtvigor <= v_datafim);
  exception
   when no_data_found then
    return - 1;
  end;
 
  return(v_nuconf);
 end get_config;

 procedure get_config(p_dtref in date, conf out ad_tsffciconf%rowtype) as
 begin
  -- busca set de parametros
  begin
   select *
     into conf
     from ad_tsffciconf c
    where c.dtvigor = (select max(dtvigor)
                         from ad_tsffciconf c2
                        where c2.nuconf = c.nuconf
                          and c2.dtvigor <= p_dtref);
  exception
   when no_data_found then
    raise_application_error(-20105,
                            'Erro! Não há parametrização válida nessa ' ||
                            'referência.<br>');
  end;
 end get_config;

 function get_perc_com(p_ipsul float, p_ipsum float) return float is
  v_result float;
 begin
  v_result := (p_ipsul - p_ipsum) * case
               when p_ipsul - p_ipsum > 0 then
                0.11
               else
                0.16
              end + (power((p_ipsul - p_ipsum), 2) * 0.000027) +
              (power((p_ipsul - p_ipsum), 3) * 0.000018) + 10.5;
 
  return(v_result);
 end get_perc_com;

 -- método que popula a tabela principal da comissão
 procedure set_dados_lote(p_nrolote number, p_errmsg out varchar2) as
  lote ad_tsffci%rowtype;
  conf ad_tsffciconf%rowtype;
  tab  ad_tsftci%rowtype;
  i    int;
 begin
 
  begin
   /*conf.nuconf := get_config(p_nrolote);
   select * into conf from ad_tsffciconf where nuconf = conf.nuconf;*/
   get_config(p_dtref => sysdate, conf => conf);
  exception
   when others then
    p_errmsg := 'Erro ao buscar as informações da tela de parâmetros. ' || sqlerrm;
    return;
  end;
 
  for dados in (
                
                select distinct lt.codparc, l.codprod, lt.qtdavesaloj qtdaves,
                                 l.descrabrevave, l.dtalojamento, l.qtdmortes, l.pesofinal,
                                 l.dtabate, l.numlote, fv.idade, fv.sexo, lt.status,
                                 fv.codlote
                  from ad_tsflfv l
                  join lote_ave lt
                    on lt.numlote = l.numlote
                  join ad_tsftfv fv
                    on fv.numlote = l.numlote
                 where 1 = 1
                   and lt.status = 'F'
                   and l.numlote = p_nrolote
                
                )
  loop
  
   /* if dados.sexo = 'F' then
    ad_pkg_var.stmt := 'Select i.fpfemea, i.ipsufemea From ad_tsftci i Where i.codtab = :tabela';
   elsif dados.sexo = 'M' then
    ad_pkg_var.stmt := 'Select i.fpmacho, i.ipsumacho From ad_tsftci i Where i.codtab = :tabela';
   elsif dados.sexo = 'X' then
    ad_pkg_var.stmt := 'Select i.fpsexado, i.ipsusexado From ad_tsftci i Where i.codtab = :tabela';
   end if;
   
   declare
    c sys_refcursor;
   begin
    lote.tabela := get_codtab_int(dados.numlote);
    open c for ad_pkg_var.stmt
    using lote.tabela;
    fetch c
    into lote.fpmedio, lote.ipsumedio;
    close c;
   end;*/
  
   lote.tipocom     := 'FV';
   lote.numlote     := dados.numlote;
   lote.codlote     := dados.codlote;
   lote.codemp      := ad_pkg_fci.get_codemp_lote(dados.numlote);
   lote.codparc     := dados.codparc;
   lote.dtaloj      := dados.dtalojamento;
   lote.dtsaida     := dados.dtabate;
   lote.idade       := dados.idade;
   lote.statuslote  := 'P';
   lote.tipobonif   := 'N';
   lote.statusbonif := 'P';
   lote.qtdaves     := dados.qtdaves;
   lote.qtdfem      := ad_pkg_fci.get_qtd_sexo_lote(dados.numlote, 'F');
   lote.percfem     := snk_dividir(lote.qtdfem, lote.qtdaves) * 100;
   lote.qtdmachos   := ad_pkg_fci.get_qtd_sexo_lote(dados.numlote, 'M');
   lote.percmachos  := snk_dividir(lote.qtdmachos, lote.qtdaves) * 100;
  
   get_dados_tabela(p_nrolote => p_nrolote, p_codemp => lote.codemp, p_tabela => tab);
  
   lote.tabela := tab.codtab;
  
   if dados.sexo = 'F' then
    lote.ipsumedio := tab.ipsufemea;
    lote.fpmedio   := tab.fpfemea;
   elsif dados.sexo = 'M' then
    lote.ipsumedio := tab.ipsumacho;
    lote.fpmedio   := tab.fpmacho;
   elsif dados.sexo = 'X' then
    lote.ipsumedio := tab.ipsusexado;
    lote.fpmedio   := tab.fpsexado;
   end if;
  
   --tipo do preço
   if lote.percfem >= conf.percprecofem then
    lote.tipopreco := 'F';
   elsif lote.percmachos >= conf.percprecomac then
    lote.tipopreco := 'M';
   elsif (lote.percfem between 50 - conf.percdifprecosex and 50) and
         (lote.percmachos between 50 - conf.percdifprecosex and 50) then
    lote.tipopreco := 'X';
   else
    lote.tipopreco := 'P';
   end if;
  
   lote.qtdabat     := nvl(ad_pkg_fci.get_qtd_abatida(lote.numlote), 0);
   lote.qtdracao    := round(ad_pkg_fci.get_total_racao_lote(lote.numlote), cd);
   lote.peso        := round(ad_pkg_fci.get_pesoliq_balanca(lote.numlote), cd);
   lote.vlrunit     := round(get_preco_tab(dados.numlote), cd);
   lote.viabilidade := round(snk_dividir(lote.qtdabat, lote.qtdaves) * 100, cd);
   lote.pesolote    := round(lote.peso / lote.qtdabat, cd);
   lote.ganholote   := trunc((lote.pesolote / lote.idade) * 1000, 2);
   lote.calote      := round(snk_dividir(lote.qtdracao, lote.peso), cd);
   lote.fplote      := round(snk_dividir((lote.viabilidade * lote.ganholote),
                                         (lote.calote * 10)),
                             2);
   lote.vlrdespesas := get_total_despesas(lote.numlote);
   lote.qtdmortes   := lote.qtdaves - lote.qtdabat; -- dados.qtdmortes;
   lote.ipsulote    := round((lote.viabilidade * 0.1) * (lote.ganholote * 0.35) /
                             (lote.calote * 0.55),
                             2);
   lote.percom      := round(get_perc_com(lote.ipsulote, lote.ipsumedio), 2);
   lote.pesocom     := round(lote.peso * (lote.percom / 100), cd);
   lote.vlrcom      := round(lote.pesocom * lote.vlrunit, cd);
   lote.vlrcomliq   := round(lote.vlrcom - lote.vlrdespesas, cd);
   lote.dhinclusao  := sysdate;
  
   delete from ad_tsffci where numlote = dados.numlote;
  
   insert into ad_tsffci values lote;
   i := sql%rowcount;
  
  end loop dados;
 
  if nvl(i, 0) = 0 then
   p_errmsg := 'O lote não consta nas tabelas acessórias de integração com o Avecom.';
   return;
  end if;
 
 exception
  when others then
   p_errmsg := sqlerrm;
   return;
 end set_dados_lote;

 -- método que popula a aba financeiro
 procedure set_dados_financeiro(p_nrolote number, p_errmsg out varchar2) as
  conf ad_tsffciconf%rowtype;
  i    int := 0;
 begin
  conf.nuconf := get_config(p_nrolote);
  select * into conf from ad_tsffciconf c where c.nuconf = conf.nuconf;
 
  for fin in (select f.numlote, f.vlrdespesas, 1 recdesp
                from ad_tsffci f
               where numlote = p_nrolote
              union
              select f.numlote, f.vlrcomliq, -1
                from ad_tsffci f
               where numlote = p_nrolote)
  loop
   i := i + 1;
   insert into ad_tsffcifin
    (numlote, nufcifin, desdobramento, dtvenc, vlrdesdob, codnat, codcencus, codtiptit,
     historico, origem)
   values
    (p_nrolote, i, i, null, fin.vlrdespesas, 2050000, 30201100,
     case when fin.recdesp = 1 then conf.codtiptitcomp else conf.codtiptitcom end,
     case when fin.recdesp = 1 then 'Valor a compensar' else 'Comissão Integrado' end,
     'COM');
  end loop;
 exception
  when others then
   p_errmsg := sqlerrm;
 end set_dados_financeiro;

 -- método que popula a aba notas fiscais 
 procedure set_dados_notas(p_nrolote number, p_errmsg out varchar2) as
  notas t_dados_notas := t_dados_notas();
  stmt  varchar2(4000);
  cur   sys_refcursor;
  i     int := 0;
 begin
 
  for z in 1 .. 3
  loop
   if z = 1 then
    stmt := 'Select * From Table(ad_pkg_fci.get_notas_racao(:nrolote))';
   elsif z = 2 then
    stmt := 'Select * From Table(ad_pkg_fci.get_notas_transp(:nrolote))';
   else
    stmt := 'Select * From Table(ad_pkg_fci.get_notas_fin(:nrolote))';
   end if;
  
   open cur for stmt
   using p_nrolote;
   loop
    notas.extend;
    i := notas.last;
    fetch cur
    into notas(i);
    exit when cur%notfound;
   end loop;
   notas.trim;
   close cur;
  
  end loop;
 
  select count(*) into i from ad_tsffci where numlote = p_nrolote;
 
  dbms_output.put_line('lotes existentes: ' || i);
 
  for x in notas.first .. notas.last
  loop
   notas(x).nufcinf := x;
   notas(x).numlote := p_nrolote;
   begin
    insert into ad_tsffcinf
     (nufcinf, numlote, codemp, nunota, nufin, numnota, serienota, dtneg, dtfatur,
      vlrnota, codtipoper, tipmov, statusnota, statusnfe, qtdneg)
    values
     (x, notas(x).numlote, notas(x).codemp, notas(x).nunota, notas(x).nufin,
      notas(x).numnota, notas(x).serienota, notas(x).dtneg, notas(x).dtfatur,
      notas(x).vlrnota, notas(x).codtipoper, notas(x).tipmov, notas(x).statusnota,
      notas(x).statusnfe, notas(x).qtdneg);
   exception
    when others then
     p_errmsg := 'erro ao inserir a linha ' || x || ' - ' || sqlerrm;
     return;
   end;
  
  end loop;
 
 end;

 /*M. Rangel - insere lançamentos da bonificação quando for mortalidade
 o método não realiza validações de status e outras, logo, tais validações
 devem estar presente na chamada e nas triggers */

 procedure set_bnf_lotereal(p_nrolote number, p_errmsg out varchar2) as
  conf ad_tsffciconf%rowtype;
  l    ad_tsffci%rowtype;
  i    int;
 begin
 
  get_dados_fechamento(p_nrolote, l, conf);
 
  begin
   select count(*)
     into i
     from ad_tsffcibnf b
    where numlote = l.numlote
      and b.tipobonif = 'LR';
   if i > 0 then
    delete from ad_tsffcibnf b
     where numlote = l.numlote
       and b.tipobonif = 'LR';
   end if;
  exception
   when others then
    p_errmsg := 'Erro ao excluir lote real existente. ' || sqlerrm;
    return;
  end;
 
  begin
   insert into ad_tsffcibnf
    (numlote, nufcibnf, tipobonif, percmortprev, qtdmortprev, saldoprev, percmortreal,
     qtdmortreal, saldoreal, qtdavesbnf, percavesbnf, viabilidade, percmortlote, perccom,
     vlrcom, vlrunitcom, vlrbonific, vlrunitbnf, aprovado)
   values
    (l.numlote, 1, 'LR', conf.percmortprev, l.qtdaves * (conf.percmortprev / 100),
     l.qtdaves - (l.qtdaves * (conf.percmortprev / 100)), (l.qtdmortes / l.qtdaves) * 100,
     l.qtdmortes, l.qtdaves - l.qtdmortes, 0, 0, l.viabilidade, 100 - l.viabilidade,
     l.percom, l.vlrcom, l.vlrcom / l.qtdabat, 0, 0, 'NNA');
  exception
   when others then
    p_errmsg := 'Erro ao inserir os dados do lote real. ' || sqlerrm;
    return;
  end;
 end;

 procedure set_bnf_mortalidade(p_nrolote in number,
                               p_sem1    in number,
                               p_sem2    in number,
                               p_sem3    in number,
                               p_sem4    in number,
                               p_errmsg  out varchar2) as
 
  type bonificacoes is table of ad_tsffcibnf%rowtype;
  v_qtdmortsem  number;
  v_percmortsem float;
  v_sem         varchar2(10);
  conf          ad_tsffciconf%rowtype;
  b             bonificacoes := bonificacoes();
  l             ad_tsffci%rowtype;
  i             int;
 begin
  /*  -- busca os dados do lote
    select * into l from ad_tsffci where numlote = p_nrolote;
   
    -- busca parametros do processso ativos
    select * into conf from ad_tsffciconf where nuconf = ad_pkg_fci.get_config(l.numlote);
  */
 
  get_dados_fechamento(p_nrolote, l, conf);
 
  -- verifica se já possui lançamentos calculados
  select count(*) into i from ad_tsffcibnf where numlote = l.numlote;
  if i > 0 then
   delete from ad_tsffcibnf
    where numlote = l.numlote
      and tipobonif = 'M';
  end if;
 
  -- inicia o set value dos campos
  for m in 1 .. 4
  loop
   if m = 1 then
    v_qtdmortsem  := p_sem1;
    v_percmortsem := conf.percmortprevs1;
    v_sem         := 'Sem 1';
   elsif m = 2 then
    v_qtdmortsem  := p_sem2;
    v_percmortsem := conf.percmortprevs2;
    v_sem         := 'Sem 2';
   elsif m = 3 then
    v_qtdmortsem  := p_sem3;
    v_percmortsem := conf.percmortprevs3;
    v_sem         := 'Sem 3';
   elsif m = 4 then
    v_qtdmortsem  := p_sem4;
    v_percmortsem := conf.percmortprevs4;
    v_sem         := 'Sem 4';
   else
    v_qtdmortsem := l.qtdmortes;
   end if;
  
   -- insere os dados das semanas
   b.extend;
   b(m).numlote := l.numlote;
   select max(nufcibnf) + 1
     into b(m).nufcibnf
     from ad_tsffcibnf
    where numlote = l.numlote;
   b(m).tipobonif := 'M';
   b(m).percmortprev := v_percmortsem;
   b(m).qtdmortprev := l.qtdaves * (b(m).percmortprev / 100);
   b(m).saldoprev := l.qtdaves - b(m).qtdmortprev;
   b(m).percmortreal := snk_dividir(v_qtdmortsem, l.qtdaves) * 100;
   b(m).qtdmortreal := v_qtdmortsem;
   b(m).saldoreal := l.qtdaves - b(m).qtdmortreal;
   b(m).qtdavesbnf := greatest(0, b(m).qtdmortreal - b(m).qtdmortprev);
   b(m).percavesbnf := snk_dividir(b(m).qtdavesbnf, l.qtdaves) * 100;
   b(m).viabilidade := (l.qtdabat / (l.qtdaves - b(m).qtdavesbnf)) * 100;
   b(m).percmortlote := 100 - b(m).viabilidade;
   l.ipsulote := snk_dividir((b(m).viabilidade * 0.1) * (l.ganholote * 0.35),
                             (l.calote * 0.55));
   b(m).perccom := trunc(ad_pkg_fci.get_perc_com(l.ipsulote, l.ipsumedio), cd);
   b(m).vlrcom := l.peso * (b(m).perccom / 100) * l.vlrunit;
   b(m).vlrunitcom := b(m).vlrcom / l.qtdabat;
   b(m).vlrbonific := case
                       when b(m).vlrcom - l.vlrcom < 0 then
                        0
                       else
                        b(m).vlrcom - l.vlrcom
                      end;
   b(m).vlrunitbnf := b(m).vlrbonific / l.qtdabat;
   b(m).aprovado := 'N';
   b(m).obs := v_sem;
  
   -- insere os dados da semana
   begin
    insert into ad_tsffcibnf values b (m);
   exception
    when others then
     p_errmsg := 'Erro ao inserir os dados semanais. ' || sqlerrm;
     return;
   end;
  
  end loop;
 
 end set_bnf_mortalidade;

 -- calcula bonificação GPA 
 procedure set_bnf_carcaca(p_nrolote number, p_errmsg out varchar2) as
  v_sexo      varchar2(1);
  v_codprod   number;
  v_vlrcommed float := 0;
  i           integer := 0;
  l           ad_tsffci%rowtype;
  b           ad_tsffcibnf%rowtype;
  c           ad_tsffciconf%rowtype;
 begin
 
  get_dados_fechamento(p_nrolote, l, c);
 
  select count(*)
    into i
    from ad_tsffcibnf bnf
   where numlote = l.numlote
     and bnf.tipobonif = 'C';
 
  if i > 0 then
   begin
    delete from ad_tsffcibnf
     where numlote = l.numlote
       and tipobonif = 'C';
   exception
    when others then
     p_errmsg := 'Erro ao excluir bonificações existentes. ' || sqlerrm;
     return;
   end;
  
  end if;
 
  begin
   select max(nufcibnf) + 1 into i from ad_tsffcibnf where numlote = l.numlote;
   insert into ad_tsffcibnf
    (numlote, nufcibnf, tipobonif, percmortprev, qtdmortprev, saldoprev, percmortreal,
     qtdmortreal, saldoreal, qtdavesbnf, percavesbnf, viabilidade, percmortlote, perccom,
     vlrcom, vlrunitcom, vlrbonific, vlrunitbnf, aprovado)
   values
    (l.numlote, i, 'C', c.percmortprev, l.qtdaves * (c.percmortprev / 100),
     l.qtdaves - (l.qtdaves * (c.percmortprev / 100)), (l.qtdmortes / l.qtdaves) * 100,
     l.qtdmortes, l.qtdaves - l.qtdmortes, 0, 0, l.viabilidade, 100 - l.viabilidade,
     l.percom, l.vlrcom, l.vlrcom / l.qtdabat, 0, 0, 'N');
  exception
   when others then
    p_errmsg := 'Erro ao inserir os dados do lote real. ' || sqlerrm;
    rollback;
    return;
  end;
 
  -- calcula o valor médio de comissões pagas por lote e sexo
  begin
   select sexo into v_sexo from ad_tsftfv f where f.numlote = l.numlote;
  
   if v_sexo = 'F' then
    v_codprod := ad_pkg_fci.c_codprodfemea;
   elsif v_sexo = 'M' then
    v_codprod := ad_pkg_fci.c_codprodmacho;
   else
    v_codprod := ad_pkg_fci.c_codprodsexado;
   end if;
  
   i := 0;
   for med in (select cab.codtipoper, cab.nunota, cab.dtfatur, cab.vlrnota, ite.codprod,
                      ad_get.descrproduto(ite.codprod) prod, ite.qtdneg, ite.vlrtot
                 from tgfcab cab
                 join tgfite ite
                   on ite.nunota = cab.nunota
                where 1 = 1
                  and cab.codparc = l.codparc
                  and cab.codtipoper = 329
                  and ite.codprod = v_codprod
                order by cab.dtfatur desc)
   loop
    if i < 3 then
     v_vlrcommed := v_vlrcommed + med.vlrtot;
     i           := i + 1;
    end if;
   end loop;
  
   v_vlrcommed := v_vlrcommed / i;
  
  exception
   when others then
    p_errmsg := 'Erro no calculo do vlr. médio de comissões. ' || sqlerrm;
    rollback;
    return;
  end;
 
  begin
   update ad_tsffcibnf bnf
      set bnf.vlrbonific = greatest(v_vlrcommed - l.vlrcom, 0),
          bnf.vlrunitcom = bnf.vlrcom / l.qtdabat,
          bnf.obs        = 'Foram analisados ' || c.permedvlrcom || ' lotes. Média: ' ||
                           v_vlrcommed
    where bnf.numlote = l.numlote
      and bnf.tipobonif = 'C';
  exception
   when others then
    p_errmsg := 'Erro ao atualizar os valores da bonificação - carcaça GPA. ' || sqlerrm;
    rollback;
    return;
  end;
 
 end set_bnf_carcaca;

 -- método auxiliar para criação de ligação entre lote_ave e tsflfv
 procedure aux_fix_lig_numlote as
  i integer;
 begin
 
  for lote in (select distinct l.numlfv, l.codparc, l.codprod, l.qtdaves, l.dtalojamento,
                               l.qtdmortes, l.pesofinal, l.dtabate, l.dhpega, l.dhracao,
                               l.gta, l.numlote, tl.nro_lote
                 from ad_tsflfv l
                 join tmp_lotes_avecom tl
                   on tl.cod_criador = to_char(l.codparc)
                  and to_char(tl.gta) = l.gta
                where l.gta is not null)
  loop
   update ad_tsflfv f set f.numlote = lote.nro_lote where f.numlfv = lote.numlfv;
  
   update ad_tsfpfv2 t set t.numlote = lote.nro_lote where t.numlfv = lote.numlfv;
  
  end loop;
 
 end aux_fix_lig_numlote;

end ad_pkg_fci;
/
