select *
  from (
       
       with func as (select fu.fucodemp codemp,
                            fu.fumatfunc matfunc,
                            fu.funomfunc nomefunc,
                            fu.fucpf cpf,
                            fu.fusexfunc sexo,
                            trunc(fmt.number_to_date(fu.fudtnasc), 'fmmm') dtnasc,
                            futelefone telefone,
                            fucelular celular,
                            fuidentnum rg,
                            fuidentuf ufrg,
                            trunc(fmt.number_to_date(fu.fudtadmis), 'fmmm') dtadmiss,
                            fu.fucodsitu codsit,
                            trunc(fmt.number_to_date(fu.fudtinisit), 'fmmm') dtinisit,
                            case
                              when exists (select 1
                                      from ad_prhsit p
                                     where p.codsit = fu.fucodsitu
                                       and p.gruporel = 'R') then
                               fmt.number_to_date(fu.fudtinisit)
                            end as dtdemiss,
                            --fucodstant codsitant,
                            fu.futipoadms tipadm,
                            fu.futiposal tiposal
                       from fpwpower.funciona fu), hist as (select fh.fuhistcodemp codemp,
                                                                   fh.fuhistmatfunc matfunc,
                                                                   fmt.number_to_date(fh.fuhistdataini) dtinisit,
                                                                   fmt.number_to_date(fh.fuhistdatafim) dtfimsit,
                                                                   fh.fuhistcodsitu codsit,
                                                                   fh.fuhistgrauinst grauinstr,
                                                                   fh.fuhistcodlot codlot,
                                                                   fh.fuhistcodcargo cargo
                                                              from fpwpower.funcionahist fh
                                                             group by fh.fuhistcodemp,
                                                                      fh.fuhistmatfunc,
                                                                      fmt.number_to_date(fh.fuhistdataini),
                                                                      fmt.number_to_date(fh.fuhistdatafim),
                                                                      fh.fuhistcodsitu,
                                                                      fh.fuhistgrauinst,
                                                                      fh.fuhistcodlot,
                                                                      fh.fuhistcodcargo)
         select to_date(&dtref, 'dd/mm/yyyy') as dtref,
                f.codemp,
                f.matfunc,
                f.nomefunc,
                f.sexo,
                f.dtnasc,
                h.codsit,
                s.stdescsitu descrsit,
                ad_pkg_func.get_cidade_uf(f.codemp, f.matfunc, 'C') cidade,
                ad_pkg_func.get_cidade_uf(f.codemp, f.matfunc, 'U') uf,
                f.dtadmiss,
                f.dtdemiss,
                h.dtinisit,
                nvl(i.divisao, h.codlot) divisao,
                l.lodesclot,
                i.setor,
                i.depto,
                i.unidade,
                h.grauinstr,
                ad_pkg_func.get_descr_escolaridade(h.grauinstr) escolaridade,
                h.cargo,
                c.cadescargo descrcargo
           from func f
           join hist h
             on h.codemp = f.codemp
            and h.matfunc = f.matfunc
            and &dtref between trunc(h.dtinisit, 'fmmm') and trunc(h.dtfimsit, 'fmmm')
           join fpwpower.situacao s
             on s.stcodemp = f.codemp
            and s.stcodsitu = h.codsit
           join fpwpower.lotacoes l
             on l.locodemp = f.codemp
            and l.locodlot = h.codlot
           join fpwpower.cargos c
             on c.cacodemp = f.codemp
            and c.cacodcargo = h.cargo
            and c.catiposal = f.tiposal
            and c.castatus = 'A'
            and c.cadatainativacao = 0
           left join fpw_lotacoes_lig i
             on i.codemp = f.codemp
            and i.codlot = h.codlot
          where 1 = 1
            and trunc(f.dtadmiss, 'mm') <= &dtref
            and (f.dtdemiss is null or trunc(f.dtdemiss, 'mm') >= &dtref)
            and f.codemp = 1)
         
         union all
         
         select *
           from (
                
                with func as (select fu.fucodemp codemp,
                                     fu.fumatfunc matfunc,
                                     fu.funomfunc nomefunc,
                                     fu.fucpf cpf,
                                     fu.fusexfunc sexo,
                                     trunc(fmt.number_to_date(fu.fudtnasc), 'fmmm') dtnasc,
                                     futelefone telefone,
                                     fucelular celular,
                                     fuidentnum rg,
                                     fuidentuf ufrg,
                                     trunc(fmt.number_to_date(fu.fudtadmis), 'fmmm') dtadmiss,
                                     fu.fucodsitu codsit,
                                     case
                                       when exists (select 1
                                               from ad_prhsit p
                                              where p.codsit = fu.fucodsitu
                                                and p.gruporel = 'R') then
                                        fmt.number_to_date(fu.fudtinisit)
                                     end as dtdemiss,
                                     fu.fucodstant codsitant,
                                     fu.futipoadms tipadm,
                                     fu.futiposal tiposal,
                                     fu.fucodcargo codcargo,
                                     fu.fugrauinst grauinstr,
                                     fmt.number_to_date(fu.fudtinisit) dtinisit,
                                     fu.fucodlot codlot
                                from folha.funciona fu
                               where fu.fucodemp = 10
                                 and (fu.fucodsitu in (4, 5, 100) or fu.fucodstant in (4, 5, 100)))
                
                  select to_date(&dtref, 'dd/mm/yyyy') as dtref,
                         f.codemp,
                         f.matfunc,
                         f.nomefunc,
                         f.sexo,
                         f.dtnasc,
                         f.codsit,
                         s.stdescsitu descrsit,
                         ad_pkg_func.get_cidade_uf(f.codemp, f.matfunc, 'C') cidade,
                         ad_pkg_func.get_cidade_uf(f.codemp, f.matfunc, 'U') uf,
                         f.dtadmiss,
                         f.dtdemiss,
                         f.dtinisit,
                         i.divisao,
                         l.lodesclot,
                         i.setor,
                         i.depto,
                         i.unidade,
                         f.grauinstr,
                         ad_pkg_func.get_descr_escolaridade(f.grauinstr) escolaridade,
                         f.codcargo,
                         c.cadescargo descrcargo
                    from func f
                    join folha.situacao s
                      on s.stcodemp = f.codemp
                     and s.stcodsitu = f.codsit
                    join folha.lotacoes l
                      on l.locodemp = f.codemp
                     and l.locodlot = f.codlot
                    join folha.cargos c
                      on c.cacodemp = f.codemp
                     and c.cacodcargo = f.codcargo
                     and c.catiposal = f.tiposal
                     and c.castatus = 'A'
                     and c.cadatainativacao = 0
                    left join fpw_lotacoes_lig i
                      on i.codemp = f.codemp
                     and i.codlot = f.codlot
                   where 1 = 1
                     and trunc(f.dtadmiss, 'mm') <= &dtref
                     and (f.dtdemiss is null or trunc(f.dtdemiss, 'mm') >= &dtref)
                  
                   )
