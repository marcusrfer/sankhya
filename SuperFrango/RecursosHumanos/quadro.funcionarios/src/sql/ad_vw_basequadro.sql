Create Or Replace View ad_vw_basequadro As
select f.fucodemp codemp, ad_pkg_func.get_descr_lotacao(f.fucodlot, 1) unidade,
       ad_pkg_func.get_descr_lotacao(f.fucodlot, 3) setor, f.fucodlot codlot,
       ad_pkg_func.get_descr_lotacao(f.fucodlot, 4) descrlot, f.fucentrcus codcencus,
       ad_get.descrcencus(f.fucentrcus) descrcencus, gh.ghcodgrphierarquicosuperior codgrupopai,
       gh.ghcodgrphie codgrupo, lpad(' ', gh.ghnumeronivelhierarquico / 2, '*') || gh.ghdesc descrpos,
       gh.ghnumeronivelhierarquico lvl, gh.ghstatus, f.fumatfunc matricula, f.funomfunc nome, met.numet,
       f.fucodsitu codsit, f.fudtinisit dtinisit, 1 as ativos,
       case
         when exists (select 1s
                 from sankhya.ad_prhsit ss
                where ss.codsit = f.fucodsitu
                  and ss.nuprh = 1
                  and ss.gruporel = 'A'
                  and ss.subgruporel is null) then
          1
       end efetivos,
       case
         when exists (select 1
                 from sankhya.ad_prhsit ss
                where ss.nuprh = 1
                  and ss.codsit = f.fucodsitu
                  and ss.subgruporel = 'AF') then
          1
       end afastados
  from fpwpower.grphierarquico gh
  join fpwpower.funciona f
    on f.fucodgrphie = gh.ghcodgrphie
   and f.fucodemp = gh.ghcodemp
  join ad_sfvincmetaindgcr cr
    on cr.codcencus = f.fucentrcus
  join ad_sfvincmetaindg mi
    on mi.codmeta = cr.codmeta
  join tmimet met
    on met.numet = mi.numet
 where gh.ghcodemp = 1
   and gh.ghstatus = 'A'
   and ((f.fucodemp = 1 and
       f.fucodsitu not in (select ss.codsit
                               from ad_prhsit ss
                              where ss.nuprh = 1
                                and ss.gruporel = 'A')) or (f.fucodemp = 10 and f.fucodsitu in (100, 4, 5)))
   and mi.ativo = 'S'
   and met.codind = 49
   and met.codung = 192
 order by f.fucodemp, f.fucodlot
