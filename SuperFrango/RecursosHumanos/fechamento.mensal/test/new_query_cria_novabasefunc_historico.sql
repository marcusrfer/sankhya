with maior_data as
 (select max(h.fuhistdatafim) dtfim from fpwpower.funcionahist h where max(h.fuhistdatafim) <= &dtref)
select fh.fuhistcodemp codemp,
       fh.fuhistmatfunc matfunc,
       fh.fuhistnomfunc nomefunc,
       f.fusexfunc sexo,
       m.mudesmunic,
       nvl(case
             when length(ad_pkg_func.get_descricao_atributo(f.fucodemp, f.fumatfunc, 1002)) = 0 then
              m.muuf
             else
              ad_pkg_func.get_descricao_atributo(f.fucodemp, f.fumatfunc, 1002)
           end, m.muuf) as uf,
       fmt.number_to_date(f.fudtnasc) dtnasc,
       fmt.number_to_date(fh.fuhistdtadmis) dtadmiss,
       case
         when exists (select 1
                 from ad_prhsit p
                where p.nuprh = 1
                  and fh.fuhistcodsitu = p.codsit
                  and p.gruporel = 'R') then
          fmt.number_to_date(fh.fuhistdataini)
       end as dtrescisao,
       case
         when exists (select 1
                 from ad_prhsit p
                where p.nuprh = 1
                  and fh.fuhistcodsitu = p.codsit
                  and p.gruporel = 'A'
                  and p.subgruporel = 'AF') then
          fmt.number_to_date(fh.fuhistdataini)
       end as dtafast,
       trunc(fmt.number_to_date(fh.fuhistdataini), 'fmmm') dtinisit,
       trunc(fmt.number_to_date(fh.fuhistdatafim), 'fmmm') dtfimsit,
       fh.fuhistgrauinst grauisnstr,
       ad_pkg_func.get_descr_escolaridade(fh.fuhistgrauinst) descrgrauisnstr,
       --fh.fuhisttipoadms tipoadms,
       fh.fuhistcodsitu,
       st.stdescsitu descrsit,
       case
         when nvl(sit.subgruporel, sit.gruporel) = 'A' then
          'Admitidos'
         when nvl(sit.subgruporel, sit.gruporel) = 'R' then
          'Demitidos'
         when nvl(sit.subgruporel, sit.gruporel) = 'AF' then
          'Afastados'
         when nvl(sit.subgruporel, sit.gruporel) = 'AP' then
          'Aposentados'
       end as grupo,
       fh.fuhistcodlot codlot,
       lt.lodesclot descrlot,
       ll.setor,
       ll.depto,
       ll.unidade,
       fh.fuhisttiposal tiposal,
       fh.fuhistcodcargo codcargo,
       ca.cadescargo descrcargo,
       fh.fuhistcentrcus codcencus
  from fpwpower.funciona f
  join fpwpower.funcionahist fh
    on f.fucodemp = fh.fuhistcodemp
   and f.fumatfunc = fh.fuhistmatfunc
  join fpwpower.situacao st
    on st.stcodemp = fh.fuhistcodemp
   and st.stcodsitu = fh.fuhistcodsitu
  join fpwpower.lotacoes lt
    on lt.locodemp = fh.fuhistcodemp
   and lt.locodlot = fh.fuhistcodlot
  join fpwpower.cargos ca
    on ca.cacodemp = fh.fuhistcodemp
   and ca.cacodcargo = fh.fuhistcodcargo
  join fpwpower.municip m
    on m.mucodmunic = fh.fuhistcodmunic
  left join ad_prhsit sit
    on sit.codsit = fh.fuhistcodsitu
/*left join tsicus cus
on cus.codcencus = to_number(fh.fuhistcentrcus)*/
  left join fpw_lotacoes_lig ll
    on ll.codemp = f.fucodemp
 where 1 = 1
   and f.fucodemp = 1
   and f.fumatfunc = &codfunc
   and trunc(fmt.number_to_date(f.fudtadmis), 'fmmm') <= &dtref

--and (trunc(fmt.number_to_date(fh.fuhistdataini), 'fmmm') != trunc(fmt.number_to_date(fh.fuhistdatafim), 'fmmm'))
/* and trunc(fmt.number_to_date(fh.fuhistdatafim), 'fmmm') =
       (select max(trunc(fmt.number_to_date(fh2.fuhistdatafim), 'fmmm'))
          from fpwpower.funcionahist fh2
         where fh2.fuhistcodemp = fh.fuhistcodemp
           and fh2.fuhistmatfunc = fh.fuhistmatfunc
           and trunc(fmt.number_to_date(fh2.fuhistdataini), 'fmmm') <= &dtref)
*/
