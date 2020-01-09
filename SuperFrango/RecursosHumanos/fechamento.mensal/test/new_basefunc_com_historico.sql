select fh.fuhistcodemp codemp,
       fh.fuhistmatfunc matfunc,
       fh.fuhistnomfunc nomefunc,
       f.fusexfunc sexo,
       m.mudesmunic,
       case
         when ad_pkg_func.get_descricao_atributo(f.fucodemp, f.fumatfunc, 1002) = null then
          m.muuf
         else
          ad_pkg_func.get_descricao_atributo(f.fucodemp, f.fumatfunc, 1002)
       end as uf,
       fmt.number_to_date(f.fudtnasc) dtnasc,
			 f.fudtnasc,
       fmt.number_to_date(fh.fuhistdtadmis) dtadmiss,
       fuhistdtadmis,
       fh.fuhistdtresc dtrescisao,
       fuhistdataini,
       fuhistdatafim,
       trunc(fmt.number_to_date(fh.fuhistdataini), 'fmmm') dtinisit,
       trunc(fmt.number_to_date(fh.fuhistdatafim), 'fmmm') dtfimsit,
       fh.fuhistgrauinst grauisnstr,
       ad_pkg_func.get_descr_escolaridade(fh.fuhistgrauinst) descrgrauisnstr,
       fh.fuhisttipoadms tipoadms,
       fh.fuhistcodsitu codsit,
       st.stdescsitu descrsit,
       fh.fuhistcodlot codlot,
       lt.lodesclot descrlot,
       ll.codlot3 setor,
       ll.codlot2 depto,
       ll.codlot unidade,
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
/*left join tsicus cus
on cus.codcencus = to_number(fh.fuhistcentrcus)*/
  left join fpw_lotacoes_lig ll
    on ll.codemp = f.fucodemp
   and ll.matfunc = f.fumatfunc
 where 1 = 1
   and f.fucodemp = 1
      --and f.fumatfunc = &codfunc
   and trunc(fmt.number_to_date(fh.fuhistdatafim), 'fmmm') =
       (select max(trunc(fmt.number_to_date(fh2.fuhistdatafim), 'fmmm'))
          from fpwpower.funcionahist fh2
         where fh2.fuhistcodemp = fh.fuhistcodemp
           and fh2.fuhistmatfunc = fh.fuhistmatfunc
           and trunc(fmt.number_to_date(fh2.fuhistdataini), 'fmmm') <= &dtref)