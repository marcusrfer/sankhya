Create Table ad_basefunc As
select *
  from (with historico as (select to_date(&dtref, 'dd/mm/yyyy') dtref,
                                  fh.fuhistcodemp codemp,
                                  fh.fuhistmatfunc matfunc,
                                  fmt.number_to_date(fh.fuhistdtadmis) dtadmiss,
                                  case
                                    when exists (select 1
                                            from ad_prhsit s
                                           where s.codsit = fh.fuhistcodsitu
                                             and s.gruporel = 'R') then
                                     fmt.number_to_date(fh.fuhistdataini)
                                    else
                                     null
                                  end as dtrescisao,
                                  case
                                    when exists (select 1
                                            from ad_prhsit p
                                           where p.codsit = fh.fuhistcodsitu
                                             and p.gruporel = 'A'
                                             and p.subgruporel = 'AF') then
                                     fmt.number_to_date(fh.fuhistdataini)
                                    else
                                     null
                                  end as dtafast,
                                  case
                                    when exists (select 1
                                            from ad_prhsit p
                                           where p.codsit = fh.fuhistcodsitu
                                             and p.gruporel = 'A'
                                             and p.subgruporel is null) then
                                     1
                                    else
                                     fh.fuhistcodsitu
                                  end as codsit,
                                  --@fmt.number_to_date(fh.fuhistdataini) dtinisit,
                                  --@fmt.number_to_date(fh.fuhistdatafim) dtfimsit,
                                  fh.fuhistcodlot codlot,
                                  fh.fuhisttipoadms tipoadms,
                                  fh.fuhisttiposal tiposal,
                                  fh.fuhistgrauinst grauinstr,
                                  fh.fuhistcentrcus codcencus,
                                  fh.fuhistcodcargo codcargo,
                                  max(fmt.number_to_date(fh.fuhistdataini)) dtini
                             from fpwpower.funcionahist fh
                            where 1 = 1
                                 -- And fh.fuhistcodemp = 1
                              and trunc(fmt.number_to_date(fh.fuhistdataini), 'fmmm') <= &dtref
                              and trunc(fmt.number_to_date(fh.fuhistdatafim), 'fmmm') >= &dtref
                              and exists (select 1 from ad_prhsit s where s.codsit = fh.fuhistcodsitu)
                            group by fh.fuhistcodemp,
                                     fh.fuhistmatfunc,
                                     fmt.number_to_date(fh.fuhistdtadmis),
                                     case
                                       when exists (select 1
                                               from ad_prhsit s
                                              where s.codsit = fh.fuhistcodsitu
                                                and s.gruporel = 'R') then
                                        fmt.number_to_date(fh.fuhistdataini)
                                       else
                                        null
                                     end,
                                     case
                                       when exists (select 1
                                               from ad_prhsit p
                                              where p.codsit = fh.fuhistcodsitu
                                                and p.gruporel = 'A'
                                                and p.subgruporel = 'AF') then
                                        fmt.number_to_date(fh.fuhistdataini)
                                       else
                                        null
                                     end,
                                     case
                                       when exists (select 1
                                               from ad_prhsit p
                                              where p.codsit = fh.fuhistcodsitu
                                                and p.gruporel = 'A'
                                                and p.subgruporel is null) then
                                        1
                                       else
                                        fh.fuhistcodsitu
                                     end,
                                     fh.fuhistcodlot,
                                     fh.fuhistgrauinst,
                                     fh.fuhistcentrcus,
                                     fh.fuhisttipoadms,
                                     fh.fuhisttiposal,
                                     fh.fuhistcodcargo
                           --@fmt.number_to_date(fh.fuhistdataini),
                           --@fmt.number_to_date(fh.fuhistdatafim)
                           
                           )
         select distinct h.dtref,
                         h.codemp,
                         h.matfunc,
                         f.funomfunc nomefunc,
                         f.fusexfunc sexo,
                         nvl(substr(trim(replace(a.afvalor, '/', '-')), 1,
                                    instr(trim(replace(a.afvalor, '/', '-')), '-') - 1),
                             --'Erro no cadastro') nomecid,
                             m.mudesmunic) nomecid,
                         nvl(substr(trim(substr(trim(replace(a.afvalor, '/', '-')),
                                                instr(trim(replace(a.afvalor, '/', '-')), '-') + 1,
                                                length(trim(replace(a.afvalor, '/', '-'))))), 1, 2), m.muuf) uf,
                         --'ER') uf,
                         fmt.number_to_date(f.fudtnasc) dtnasc,
                         trunc(h.dtadmiss, 'fmmm') dtadmiss,
                         trunc(h.dtrescisao, 'fmmm') dtrescisao,
                         trunc(h.dtafast, 'fmmm') dtafast,
                         h.grauinstr,
                         ad_pkg_func.get_descr_escolaridade(h.grauinstr) descrgrauisnstr,
                         h.codsit,
                         st.stdescsitu descrsit,
                         h.codlot,
                         lo.lodesclot descrlot,
                         ll.divisao,
                         ll.setor,
                         ll.depto,
                         ll.unidade,
                         h.codcargo,
                         h.codcencus
           from fpwpower.funciona f
           join historico h
             on f.fucodemp = codemp
            and f.fumatfunc = h.matfunc
           join fpwpower.situacao st
             on st.stcodemp = h.codemp
            and st.stcodsitu = h.codsit
           join fpwpower.lotacoes lo
             on lo.locodemp = h.codemp
            and lo.locodlot = h.codlot
           left join fpw_lotacoes_lig ll
             on ll.codemp = h.codemp
            and ll.codlot = h.codlot
           left join fpwpower.atribfun a
             on a.afcodemp = f.fucodemp
            and a.afmatfunc = f.fumatfunc
            and a.afcodatrib = 1002
           join fpwpower.municip m
             on m.mucodmunic = f.fucodmunic
          where 1 = 1
               --and h.matfunc = 698
            and f.fucodemp = 1
            and (h.dtrescisao is null or trunc(dtrescisao, 'fmmm') = h.dtref or trunc(dtrescisao, 'fmmm') > &dtref)
         -- order by 1, 2, 3
         
         union all
         
         select trunc(fmt.number_to_date(f.fudtinisit), 'mm') referencia,
                1 codemp,
                f.fumatfunc matfunc,
                f.funomfunc nomefunc,
                f.fusexfunc sexo,
                m.mudesmunic cidade,
                m.muuf uf,
                fmt.number_to_date(fudtnasc) dtnasc,
                fmt.number_to_date(f.fudtadmis) dtadmiss,
                case
                  when exists (select 1
                          from ad_prhsit p
                         where p.nuprh = 1
                           and f.fucodsitu = p.codsit
                           and p.gruporel = 'R') then
                   fmt.number_to_date(f.fudtinisit)
                end as dtrescisao,
                case
                  when f.fucodsitu in (select 1
                                         from ad_prhsit p
                                        where p.nuprh = 1
                                          and fucodsitu = p.codsit
                                          and p.gruporel = 'A'
                                          and p.subgruporel = 'AF') then
                   fmt.number_to_date(f.fudtinisit)
                end as dtafast,
                f.fugrauinst grauinst,
                ad_pkg_func.get_descr_escolaridade(f.fugrauinst),
                f.fucodsitu,
                st.stdescsitu,
                f.fucodlot,
                l.lodesclot,
                ll.divisao,
                ll.setor,
                ll.depto,
                ll.unidade,
                f.fucodcargo,
                f.fucentrcus
           from folha.funciona f
           left join tsicus cw
             on to_char(cw.codcencus) = to_char(f.fucentrcus)
           join folha.municip m
             on f.fucodmunic = m.mucodmunic
           join folha.situacao st
             on f.fucodsitu = st.stcodsitu
            and f.fucodemp = st.stcodemp
           join folha.lotacoes l
             on l.locodemp = f.fucodemp
            and l.locodlot = f.fucodlot
           join fpw_lotacoes_lig ll
             on ll.codlot = f.fucodlot
          where f.fucodemp = 10
            and f.fucodlot not in (10201503)
            and trunc(fmt.number_to_date(f.fudtinisit), 'mm') <= &dtref
            and (f.fucodsitu in (4, 5, 100) or f.fucodstant in (4, 5, 100)));
