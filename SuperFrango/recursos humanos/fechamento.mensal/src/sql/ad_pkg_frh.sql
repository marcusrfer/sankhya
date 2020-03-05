create or replace package ad_pkg_frh authid definer as
 /*
        * Autor: M. Rangel
        * Objetivo: Armazenar os principais objetos utilizados no processo,
        * Processo: Dashboards do fechamento mensal do RH
         
 */

 procedure cria_basefunc_fpw(p_dtref date, p_qtdmeses int);

 procedure cria_relacao_lotacao_fpw;

 procedure cria_ligacoes_lotacao_fpw;

 -- M. rangel: retorna a lotacao no nível desejado
 function get_lotacao_grau(p_codlot number, p_grau pls_integer) return number;

 type tab_basefunc is table of ad_basefunc_fpw%rowtype;

 /*
   Autor: MARCUS.RANGEL 19/09/2019 14:34:29
   Objetivos: retornar os dados para apresentação do dash de  critérios por mês .
 */
 function valores_mensais(p_dtref date, p_tipo varchar2) return tab_basefunc
 pipelined;

 function valores_mensais_lot(p_dtref date, p_grupolot varchar2, p_tipo varchar2) return tab_basefunc
 pipelined;

 function valores_mensais_lot(p_dtref   date,
                              p_tipo    varchar2,
                              p_unidade varchar2 default null,
                              p_depto   varchar2 default null,
                              p_setor   varchar2 default null,
                              p_divisao varchar2 default null) return tab_basefunc
 pipelined;

 procedure exec_agendamento;

end ad_pkg_frh;
/
create or replace package body ad_pkg_frh is

 /*
   Autor: MARCUS.RANGEL 13/08/2019 11:02:38
   Objetivos: criar base de funcioários considerando o fator de posição temporal.
 */
 procedure cria_basefunc_fpw(p_dtref date, p_qtdmeses int) is
  v_dtini   date;
  v_dtatual date;
  v_dtfim   date;
 
  type tab_dados is table of ad_basefunc_fpw%rowtype;
  t tab_dados := tab_dados();
 
  isdemitido boolean default false;
  v_matfunc  number;
  v_count    int := 0;
 
 begin
 
  v_dtfim   := trunc(p_dtref, 'fmmm');
  v_dtini   := add_months(v_dtfim, -p_qtdmeses);
  v_dtatual := v_dtini;
 
  while v_dtatual <= v_dtfim
  loop
  
   t.extend;
  
   select *
     bulk collect
     into t
     from (
            
            select *
              from (
                    
                    with hist as (
                                  
                                  select fh.fuhistcodemp codemp, fh.fuhistmatfunc matfunc,
                                          fmt.number_to_date(fh.fuhistdataini) dtinisit,
                                          fmt.number_to_date(fh.fuhistdatafim) dtfimsit, fh.fuhistcodsitu codsit,
                                          fh.fuhistcodcargo codcargo, fh.fuhistcodlot codlot,
                                          fh.fuhistgrauinst grauinstr
                                    from fpwpower.funcionahist fh
                                   where case
                                          when fmt.number_to_date(fh.fuhistdatafim) > last_day(v_dtatual) then
                                           fmt.number_to_date(fh.fuhistdatafim)
                                          else
                                           fmt.number_to_date(fh.fuhistdataini)
                                         end =
                                         (select max(case
                                                      when fmt.number_to_date(fh2.fuhistdatafim) > last_day(v_dtatual) then
                                                       fmt.number_to_date(fh2.fuhistdatafim)
                                                      else
                                                       fmt.number_to_date(fh2.fuhistdataini)
                                                     end)
                                            from fpwpower.funcionahist fh2
                                           where fh2.fuhistcodemp = fh.fuhistcodemp
                                             and fh2.fuhistmatfunc = fh.fuhistmatfunc)
                                  
                                  ),
                    
                    func as (
                             
                             select fu.fucodemp codemp, fu.fumatfunc matfunc, fu.funomfunc nomefunc, fu.fucpf cpf,
                                     fu.fusexfunc sexo, fmt.number_to_date(fu.fudtnasc) dtnasc, futelefone telefone,
                                     fucelular celular, fuidentnum rg, fuidentuf ufrg,
                                     fmt.number_to_date(fu.fudtadmis) dtadmiss,
                                     case
                                      when exists (select 1
                                              from ad_prhsit p
                                             where p.codsit = fu.fucodsitu
                                               and p.gruporel = 'R') then
                                       fmt.number_to_date(fu.fudtinisit)
                                     end as dtdemiss, fu.futipoadms tipadm, fu.futiposal tiposal
                               from fpwpower.funciona fu
                              where fu.fucodemp = 1
                                and fmt.number_to_date(fu.fudtadmis) <= last_day(v_dtatual)
                             
                             ),
                    
                    cargos as (
                               
                               select ch.cacodemp codemp, ch.cacodcargo codcargo, ch.cadescargo descrcargo,
                                       max(fmt.number_to_date(ch.cavigencia)) vigencia
                                 from fpwpower.cargoshist ch
                                where ch.cacodemp = 1
                                  and fmt.number_to_date(ch.cavigencia) <= last_day(v_dtatual)
                                group by ch.cacodemp, ch.cacodcargo, ch.cadescargo
                               
                               )
                    
                     select to_date(to_char(v_dtatual, 'dd/mm/yyyy'), 'dd/mm/yyyy') as dtref, f.codemp, f.matfunc,
                            f.nomefunc, f.sexo, f.dtnasc, h.codsit, s.stdescsitu descrsit,
                            ad_pkg_func.get_cidade_uf(f.codemp, f.matfunc, 'C') cidade,
                            ad_pkg_func.get_cidade_uf(f.codemp, f.matfunc, 'U') uf, f.dtadmiss, f.dtdemiss,
                            h.dtinisit, i.divisao, l.lodesclot descrlot, i.setor, i.depto, i.unidade, h.grauinstr,
                            ad_pkg_func.get_descr_escolaridade(h.grauinstr) escolaridade, h.codcargo, ca.descrcargo
                       from func f
                       join hist h
                         on h.codemp = f.codemp
                        and h.matfunc = f.matfunc
                       join fpwpower.situacao s
                         on s.stcodemp = f.codemp
                        and s.stcodsitu = h.codsit
                       left join fpw_lotacoes_lig i
                         on i.codemp = f.codemp
                        and i.codlot = h.codlot
                       left join fpwpower.lotacoes l
                         on l.locodemp = i.codemp
                        and l.locodlot = i.codlot
                       left join cargos ca
                         on ca.codemp = f.codemp
                        and ca.codcargo = h.codcargo
                      where 1 = 1
                           --And Trunc(f.dtadmiss,'fmmm') <= v_dtatual
                        and (f.dtdemiss is null or f.dtdemiss >= v_dtatual)
                        and f.codemp = 1
                     
                      )
                     
                     union all
                     
                     select *
                       from (with func as (select fu.fucodemp codemp, fu.fumatfunc matfunc, fu.funomfunc nomefunc,
                                                  fu.fucpf cpf, fu.fusexfunc sexo,
                                                  trunc(fmt.number_to_date(fu.fudtnasc), 'fmmm') dtnasc,
                                                  futelefone telefone, fucelular celular, fuidentnum rg,
                                                  fuidentuf ufrg,
                                                  trunc(fmt.number_to_date(fu.fudtadmis), 'fmmm') dtadmiss,
                                                  fu.fucodsitu codsit,
                                                  case
                                                   when exists (select 1
                                                           from ad_prhsit p
                                                          where p.codsit = fu.fucodsitu
                                                            and p.gruporel = 'R') then
                                                    fmt.number_to_date(fu.fudtinisit)
                                                  end as dtdemiss, fu.fucodstant codsitant, fu.futipoadms tipadm,
                                                  fu.futiposal tiposal, fu.fucodcargo codcargo,
                                                  fu.fugrauinst grauinstr, fmt.number_to_date(fu.fudtinisit) dtinisit,
                                                  fu.fucodlot codlot
                                             from folha.funciona fu
                                            where fu.fucodemp = 10
                                              and (fu.fucodsitu in (4, 5, 100) or fu.fucodstant in (4, 5, 100)))
                            
                             select to_date(to_char(v_dtatual, 'dd/mm/yyyy'), 'dd/mm/yyyy') as dtref, f.codemp,
                                    f.matfunc, f.nomefunc, f.sexo, f.dtnasc, f.codsit, s.stdescsitu descrsit,
                                    ad_pkg_func.get_cidade_uf(f.codemp, f.matfunc, 'C') cidade,
                                    ad_pkg_func.get_cidade_uf(f.codemp, f.matfunc, 'U') uf, f.dtadmiss, f.dtdemiss,
                                    f.dtinisit, nvl(i.divisao, f.codlot) divisao, l.lodesclot, i.setor, i.depto,
                                    i.unidade, f.grauinstr,
                                    ad_pkg_func.get_descr_escolaridade(f.grauinstr) escolaridade, f.codcargo,
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
                                and f.dtadmiss <= last_day(v_dtatual)
                                and (f.dtdemiss is null or f.dtdemiss >= v_dtatual)
                             
                              )
                             
            
            
            )
   --where matfunc = 23925
    order by dtref, codemp, matfunc, dtinisit;
  
   forall x in t.first .. t.last
    merge into ad_basefunc_fpw bf
    using (select t(x).dtref dtref,t(x).codemp codemp,t(x).matfunc matfunc,t(x).nomefunc nomefunc,
                  t(x).sexo sexo,t(x).dtnasc dtnasc,t(x).codsit codsit,t(x).descrsit descrsit,
                  t(x).cidade cidade,t(x).uf uf,t(x).dtadmiss dtadmiss,t(x).dtdemiss dtdemiss,
                  t(x).dtinisit dtinisit,t(x).divisao divisao,t(x).lodesclot lodesclot,t(x).setor setor,
                  t(x).depto depto,t(x).unidade unidade,t(x).grauinstr grauinstr,t(x).escolaridade escolaridade,
                  t(x).cargo cargo,t(x).descrcargo descrcargo
             from dual) d
    on (bf.dtref = d.dtref and bf.codemp = d.codemp and bf.matfunc = d.matfunc)
    when matched then
     update
        set codsit    = t(x).codsit,
            descrsit  = t(x).descrsit,
            dtdemiss  = t(x).dtdemiss,
            dtinisit  = t(x).dtinisit,
            divisao   = t(x).divisao,
            lodesclot = t(x).lodesclot,
            setor     = t(x).setor,
            depto     = t(x).depto,
            unidade   = t(x).unidade,
            grauinstr = t(x).grauinstr
    when not matched then
     insert values t (x);
   commit;
  
   t.delete;
  
   v_dtatual := add_months(v_dtatual, 1);
  
  end loop;
 
 end cria_basefunc_fpw;

 /* 
 * M. Rangel 
 * Criar a ligação de niveis entre as lotações do fpw para utilização no fechamento
 */
 procedure cria_relacao_lotacao_fpw as
  v_last_codlot varchar2(10);
  v_codavo      number;
  v_codpai      number;
  v_codfilho    number;
  v_codneto     number;
 
  o fpw_lotacoes_rel%rowtype;
 
  type t_lotacoes is table of fpw_lotacoes_rel%rowtype;
 
  t t_lotacoes := t_lotacoes();
 
 begin
 
  for lot in (
              
               with base as
                (select locodemp codemp, lpad(l.locodlot, 10, '0') codlot, l.lodesclot descricao
                   from fpwpower.lotacoes l
                  where locodemp = 1
                 --and locodlot < 10200000
                  order by 1, 2),
               lot as
                (select codemp, codlot, descricao, to_number(substr(codlot, 1, 3)) as avo,
                        to_number(substr(codlot, 4, 2)) as pai, to_number(substr(codlot, 6, 3)) as filho,
                        to_number(substr(codlot, 9, 2)) as neto
                   from base),
               main as
                (select codemp, codlot, descricao,
                        case
                         when avo > 0 and pai = 0 and filho = 0 and neto = 0 then
                          1
                         when avo > 0 and pai > 0 and filho = 0 and neto = 0 then
                          2
                         when avo > 0 and pai > 0 and filho > 0 and neto = 0 then
                          3
                         when avo > 0 and pai > 0 and filho > 0 and neto > 0 then
                          4
                        end as grau
                   from lot)
               select * from main)
  loop
  
   if lot.grau = 1 then
    v_codavo    := lot.codlot;
    o.codlotpai := null;
   elsif lot.grau = 2 then
    v_codpai    := lot.codlot;
    o.codlotpai := v_codavo;
   elsif lot.grau = 3 then
    v_codfilho  := lot.codlot;
    o.codlotpai := v_codpai;
   elsif lot.grau = 4 then
    v_codneto   := lot.codlot;
    o.codlotpai := v_codfilho;
   end if;
  
   o.codemp := lot.codemp;
   o.codlot := lot.codlot;
   o.grau   := lot.grau;
  
   t.extend;
   t(t.last) := o;
  
  --Dbms_Output.put_line( lot.codemp ||' - '||lot.codlot ||' - '|| lot.grau ||' - '|| v_codpai );
  
  end loop;
 
  forall i in t.first .. t.last
   merge into fpw_lotacoes_rel l
   using (select t(i).codemp as codemp,t(i).codlot as codlot,t(i).grau as grau,t(i).codlotpai codlotpai
            from dual) d
   on (l.codemp = d.codemp and l.codlot = d.codlot)
   when matched then
    update set codlotpai = d.codlotpai
   when not matched then
    insert values (d.codemp, d.codlot, d.grau, d.codlotpai);
 
  commit;
 
 end cria_relacao_lotacao_fpw;

 -- M. rangel: retorna a lotacao no nível desejado
 function get_lotacao_grau(p_codlot number, p_grau pls_integer) return number as
  stmt     varchar2(4000);
  c        sys_refcursor;
  l        fpw_lotacoes_rel%rowtype;
  v_result number;
 begin
 
  if p_grau = 4 then
   return p_codlot;
  end if;
 
  select distinct chain
    into stmt
    from (select ltrim(sys_connect_by_path(codlot, ','), ',') chain
             from fpw_lotacoes_rel
            where codlot = p_codlot
            start with codlotpai is null
           connect by codlotpai = prior codlot
            order siblings by codlot);
 
  open c for 'Select * from fpw_lotacoes_rel where codemp = 1 and codlot in (' || stmt || ') order by 1';
  loop
   exit when c%notfound;
   fetch c
   into l;
   if l.grau = p_grau then
    v_result := l.codlot;
   end if;
  end loop;
 
  return v_result;
 exception
  when others then
   dbms_output.put_line('Erro:' || sqlerrm);
   return 0;
 end get_lotacao_grau;

 /*
 * m. rangel
 * disponibilizar no msm regiestro, toda a cadeia para cada lotação
 */
 procedure cria_ligacoes_lotacao_fpw is
  type lotacoes_lig is table of fpw_lotacoes_lig%rowtype;
  lig lotacoes_lig := lotacoes_lig();
 begin
 
  select codemp, codlot, ad_pkg_frh.get_lotacao_grau(codlot, 4) as divisao,
         ad_pkg_frh.get_lotacao_grau(codlot, 3) as setor, ad_pkg_frh.get_lotacao_grau(codlot, 2) as depto,
         ad_pkg_frh.get_lotacao_grau(codlot, 1) as unidade
    bulk collect
    into lig
    from fpw_lotacoes_rel
   where codemp = 1
     and grau in (3, 4)
   order by codlot;
 
  forall i in lig.first .. lig.last
   merge into fpw_lotacoes_lig l
   using (select lig(i).codemp codemp,lig(i).codlot codlot,lig(i).divisao,lig(i).setor,lig(i).depto,
                 lig(i).unidade
            from dual) d
   on (l.codemp = d.codemp and l.codlot = d.codlot)
   when not matched then
    insert values lig (i)
   when matched then
    update
       set divisao = lig(i).divisao,
           setor   = lig(i).setor,
           depto   = lig(i).depto,
           unidade = lig(i).unidade;
 
 end cria_ligacoes_lotacao_fpw;

 /*
   Autor: MARCUS.RANGEL 19/09/2019 14:34:29
   Objetivos: retornar os dados para apresentação do dash de  critérios por mês .
 */
 function valores_mensais(p_dtref date, p_tipo varchar2) return tab_basefunc
 pipelined is
 
  t ad_basefunc_fpw%rowtype;
 begin
  for l in (select f.*
              from ad_basefunc_fpw f
             where dtref = p_dtref
               and case
                    when p_tipo = 'A' then
                     trunc(f.dtadmiss, 'fmmm')
                    when p_tipo = 'D' then
                     trunc(f.dtdemiss, 'fmmm')
                    when p_tipo in ('T', 'TA') then
                     dtref
                   end = dtref
               and case
                    when (p_tipo in ('A', 'D')) then
                     0
                    when p_tipo = 'T' then
                     case
                      when exists (select 1
                              from ad_prhsit s
                             where s.codsit = f.codsit
                               and trunc(f.dtinisit, 'fmmm') <= p_dtref
                               and s.gruporel = 'R') then
                       1
                      else
                       0
                     end
                    when p_tipo = 'TA' then
                     case
                      when exists (select 1
                              from ad_prhsit s
                             where s.codsit = f.codsit
                               and s.gruporel = 'A'
                               and s.subgruporel = 'AF') or exists
                       (select 1
                              from ad_prhsit s2
                             where s2.codsit = f.codsit
                               and s2.gruporel = 'R'
                               and trunc(f.dtinisit, 'fmmm') <= p_dtref) then
                       1
                      else
                       0
                     end
                   end = 0
             order by dtref)
  loop
   t := l;
   pipe row(t);
  end loop;
 
 end valores_mensais;

 function valores_mensais_lot(p_dtref date, p_grupolot varchar2, p_tipo varchar2) return tab_basefunc
 pipelined is
 
  t ad_basefunc_fpw%rowtype;
 begin
  for l in (select f.*
              from ad_basefunc_fpw f
              left join ad_prhlot dd
                on dd.codlot = f.divisao
              left join ad_fpwlot ld
                on ld.codlot = f.divisao
              left join ad_prhlot ds
                on ds.codlot = f.setor
              left join ad_fpwlot ls
                on ls.codlot = f.setor
              left join ad_fpwlot de
                on de.codlot = f.depto
              left join ad_prhlot dl
                on dl.codlot = f.depto
              left join ad_fpwlot u
                on u.codlot = f.unidade
              left join ad_prhlot lu
                on lu.codlot = f.unidade
             where dtref = p_dtref
               and case
                    when p_tipo = 'A' then
                     trunc(f.dtadmiss, 'fmmm')
                    when p_tipo = 'D' then
                     trunc(f.dtdemiss, 'fmmm')
                    when p_tipo in ('T', 'TA') then
                     dtref
                   end = dtref
               and case
                    when (p_tipo in ('A', 'D')) then
                     0
                    when p_tipo = 'T' then
                     case
                      when exists (select 1
                              from ad_prhsit s
                             where s.codsit = f.codsit
                               and trunc(f.dtinisit, 'fmmm') <= p_dtref
                               and s.gruporel = 'R') then
                       1
                      else
                       0
                     end
                    when p_tipo = 'TA' then
                     case
                      when exists (select 1
                              from ad_prhsit s
                             where s.codsit = f.codsit
                               and s.gruporel = 'A'
                               and s.subgruporel = 'AF') or exists
                       (select 1
                              from ad_prhsit s2
                             where s2.codsit = f.codsit
                               and s2.gruporel = 'R'
                               and trunc(f.dtinisit, 'fmmm') <= p_dtref) then
                       1
                      else
                       0
                     end
                   end = 0
               and (nvl(lu.grupolot, u.descrlot) = p_grupolot or nvl(dl.grupolot, de.descrlot) = p_grupolot or
                   nvl(ds.grupolot, ls.descrlot) = p_grupolot or nvl(dd.grupolot, ld.descrlot) = p_grupolot)
             order by dtref)
  loop
   t := l;
   pipe row(t);
  end loop;
 
 end valores_mensais_lot;

 function valores_mensais_lot(p_dtref   date,
                              p_tipo    varchar2,
                              p_unidade varchar2 default null,
                              p_depto   varchar2 default null,
                              p_setor   varchar2 default null,
                              p_divisao varchar2 default null) return tab_basefunc
 pipelined is
  t ad_basefunc_fpw%rowtype;
 begin
  for l in (select f.*
              from ad_basefunc_fpw f
              left join ad_prhlot dd
                on dd.codlot = f.divisao
              left join ad_fpwlot ld
                on ld.codlot = f.divisao
              left join ad_prhlot ds
                on ds.codlot = f.setor
              left join ad_fpwlot ls
                on ls.codlot = f.setor
              left join ad_fpwlot de
                on de.codlot = f.depto
              left join ad_prhlot dl
                on dl.codlot = f.depto
              left join ad_fpwlot u
                on u.codlot = f.unidade
              left join ad_prhlot lu
                on lu.codlot = f.unidade
             where dtref = p_dtref
               and case
                    when p_tipo = 'A' then
                     trunc(f.dtadmiss, 'fmmm')
                    when p_tipo = 'D' then
                     trunc(f.dtdemiss, 'fmmm')
                    when p_tipo in ('T', 'TA') then
                     dtref
                   end = dtref
               and case
                    when (p_tipo in ('A', 'D')) then
                     0
                    when p_tipo = 'T' then
                     case
                      when exists (select 1
                              from ad_prhsit s
                             where s.codsit = f.codsit
                               and trunc(f.dtinisit, 'fmmm') <= p_dtref
                               and s.gruporel = 'R') then
                       1
                      else
                       0
                     end
                    when p_tipo = 'TA' then
                     case
                      when exists (select 1
                              from ad_prhsit s
                             where s.codsit = f.codsit
                               and s.gruporel = 'A'
                               and s.subgruporel = 'AF') or exists
                       (select 1
                              from ad_prhsit s2
                             where s2.codsit = f.codsit
                               and s2.gruporel = 'R'
                               and trunc(f.dtinisit, 'fmmm') <= p_dtref) then
                       1
                      else
                       0
                     end
                   end = 0
               and ((lu.grupolot = p_unidade or nvl(p_unidade, '0') = '0') and
                   (dl.grupolot = p_depto or nvl(p_depto, '0') = '0') and
                   (ds.grupolot = p_setor or nvl(p_setor, '0') = '0') and
                   (dd.grupolot = p_divisao or nvl(p_divisao, '0') = '0'))
             order by dtref)
  loop
   t := l;
   pipe row(t);
  end loop;
 
 end valores_mensais_lot;

 procedure exec_agendamento is
 begin
  cria_relacao_lotacao_fpw;
  cria_ligacoes_lotacao_fpw;
  cria_basefunc_fpw(trunc(add_months(sysdate, -1), 'fmmm'), 0);
 end exec_agendamento;

end ad_pkg_frh;
/
