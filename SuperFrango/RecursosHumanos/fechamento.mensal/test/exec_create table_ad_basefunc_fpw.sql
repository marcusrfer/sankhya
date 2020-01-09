PL/SQL Developer Test script 3.0
227
declare
  v_dtini   date;
  v_dtatual date;
  v_dtfim   date;

  type tab_dados is table of ad_basefunc_fpw%rowtype;
  t tab_dados := tab_dados();

begin

  v_dtfim   := '01/06/2019';
  v_dtini   := add_months(v_dtfim, -12);
  v_dtatual := v_dtini;

  while v_dtatual <= v_dtfim
  loop
  
    t.extend;
  
    select *
      bulk collect
      into t
      from (with func as (select fu.fucodemp codemp,
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
             select to_date(v_dtatual, 'dd/mm/yyyy') as dtref,
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
                    i.divisao,
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
                and v_dtatual between trunc(h.dtinisit, 'fmmm') and trunc(h.dtfimsit, 'fmmm')
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
                and trunc(f.dtadmiss, 'mm') <= v_dtatual
                and (f.dtdemiss is null or trunc(f.dtdemiss, 'mm') >= v_dtatual)
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
                    
                      select to_date(v_dtatual, 'dd/mm/yyyy') as dtref,
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
                             nvl(i.divisao, h.codlot) divisao,
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
                         and trunc(f.dtadmiss, 'mm') <= v_dtatual
                         and (f.dtdemiss is null or trunc(f.dtdemiss, 'mm') >= v_dtatual)
                      
                       );
  
  
  
    forall x in t.first .. t.last
      merge into ad_basefunc_fpw bf
      using (select t(x).dtref dtref,
                    t(x).codemp codemp,
                    t(x).matfunc matfunc,
                    t(x).nomefunc nomefunc,
                    t(x).sexo sexo,
                    t(x).dtnasc dtnasc,
                    t(x).codsit codsit,
                    t(x).descrsit descrsit,
                    t(x).cidade cidade,
                    t(x).uf uf,
                    t(x).dtadmiss dtadmiss,
                    t(x).dtdemiss dtdemiss,
                    t(x).dtinisit dtinisit,
                    t(x).divisao divisao,
                    t(x).lodesclot lodesclot,
                    t(x).setor setor,
                    t(x).depto depto,
                    t(x).unidade unidade,
                    t(x).grauinstr grauinstr,
                    t(x).escolaridade escolaridade,
                    t(x).cargo cargo,
                    t(x).descrcargo descrcargo
               from dual) d
      on (bf.dtref = d.dtref and bf.codemp = d.codemp and bf.matfunc = d.matfunc)
      when not matched then
        insert values t (x);
  
    commit;
  
    t.delete;
  
    v_dtatual := add_months(v_dtatual, 1);
  end loop;

end;
0
0
