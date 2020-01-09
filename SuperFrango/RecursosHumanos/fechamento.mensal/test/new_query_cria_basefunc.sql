--Create Table ad_basefunc As
select distinct t.dtref,
                t.codemp,
                t.matfunc,
                t.nomefunc,
                t.sexo,
                t.nomecid,
                t.uf,
                t.dtnasc,
                t.dtadmiss,
                t.dtinisit,
                t.dtfimsit,
                t.dtrescisao,
                t.dtafast,
                t.grauisnstr,
                t.descrgrauisnstr,
                t.codsit,
                s.stdescsitu as descrsit,
                t.codlot,
                t.descrlot,
                t.divisao,
                t.setor,
                t.depto,
                t.unidade,
                t.tiposal,
                t.codcargo,
                t.descrcargo,
                t.codcencus

  from (with maior_data as (select f.fuhistcodemp codemp,
                                   f.fuhistmatfunc matfunc,
                                   max(fmt.number_to_date(f.fuhistdataini)) dataini
                              from fpwpower.funcionahist f
                             where &dtref between trunc(fmt.number_to_date(f.fuhistdataini), 'fmmm') and
                                   trunc(fmt.number_to_date(f.fuhistdatafim), 'fmmm')
                             group by f.fuhistcodemp, f.fuhistmatfunc)
         select to_date(&dtref, 'dd/mm/yyyy') as dtref,
                f.fucodemp codemp,
                f.fumatfunc matfunc,
                f.funomfunc nomefunc,
                f.fusexfunc sexo,
                nvl(substr(trim(replace(a.afvalor, '/', '-')), 1, instr(trim(replace(a.afvalor, '/', '-')), '-') - 1),
                    'Erro no cadastro') nomecid,
                nvl(substr(trim(substr(trim(replace(a.afvalor, '/', '-')),
                                       instr(trim(replace(a.afvalor, '/', '-')), '-') + 1,
                                       length(trim(replace(a.afvalor, '/', '-'))))), 1, 2), 'ER') uf,
                fmt.number_to_date(f.fudtnasc) dtnasc,
                fmt.number_to_date(f.fudtadmis) dtadmiss,
                fmt.number_to_date(h.fuhistdataini) dtinisit,
                fmt.number_to_date(h.fuhistdatafim) dtfimsit,
                case
                  when exists (select 1
                          from ad_prhsit p
                         where p.nuprh = 1
                           and h.fuhistcodsitu = p.codsit
                           and p.gruporel = 'R') then
                   fmt.number_to_date(h.fuhistdataini)
                end as dtrescisao,
                case
                  when exists (select 1
                          from ad_prhsit p
                         where p.nuprh = 1
                           and h.fuhistcodsitu = p.codsit
                           and p.gruporel = 'A'
                           and p.subgruporel = 'AF') then
                   fmt.number_to_date(h.fuhistdataini)
                end as dtafast,
                h.fuhistgrauinst grauisnstr,
                ad_pkg_func.get_descr_escolaridade(h.fuhistgrauinst) descrgrauisnstr,
                case
                  when exists (select 1
                          from ad_prhsit sit
                         where sit.codsit = h.fuhistcodsitu
                           and sit.gruporel = 'A'
                           and sit.subgruporel is null) then
                   1
                  else
                   h.fuhistcodsitu
                end codsit,
                h.fuhistcodlot codlot,
                l.lodesclot descrlot,
                lig.divisao,
                lig.setor,
                lig.depto,
                lig.unidade,
                h.fuhisttiposal tiposal,
                h.fuhistcodcargo codcargo,
                c.cadescargo descrcargo,
                h.fuhistcentrcus codcencus
           from fpwpower.funciona f
           join fpwpower.funcionahist h
             on f.fucodemp = h.fuhistcodemp
            and f.fumatfunc = h.fuhistmatfunc
           join fpwpower.situacao s
             on s.stcodemp = f.fucodemp
            and s.stcodsitu = h.fuhistcodsitu
           join fpwpower.municip m
             on m.mucodmunic = h.fuhistcodmunic
           join fpwpower.lotacoes l
             on l.locodemp = f.fucodemp
            and l.locodlot = h.fuhistcodlot
           join fpwpower.cargos c
             on c.cacodemp = f.fucodemp
            and c.cacodcargo = h.fuhistcodcargo
            and c.catiposal = h.fuhisttiposal
           left join fpwpower.atribfun a
             on a.afcodemp = f.fucodemp
            and a.afmatfunc = f.fumatfunc
            and a.afcodatrib = 1002
           left join fpw_lotacoes_lig lig
             on lig.codemp = f.fucodemp
            and h.fuhistcodlot = lig.codlot
           join maior_data md
             on md.codemp = h.fuhistcodemp
            and md.matfunc = h.fuhistmatfunc
            and fmt.number_to_date(h.fuhistdataini) = md.dataini
          where f.fucodemp = 1
         --and f.fumatfunc = 1
         
          ) t
           join fpwpower.situacao s
             on s.stcodemp = t.codemp
            and s.stcodsitu = t.codsit
          where trunc(dtadmiss, 'fmmm') <= &dtref
            and (dtrescisao is null or dtrescisao > last_day(&dtref))
          order by 1, 2, 3
