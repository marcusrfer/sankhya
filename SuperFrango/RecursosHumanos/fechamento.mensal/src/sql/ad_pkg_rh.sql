CREATE OR REPLACE package ad_pkg_rh is

  -- Author  : MARCUS.RANGEL
  -- Created : 27/05/2019 15:45:43
  -- Purpose : 
  function get_descrcargo_func(p_codemp  number,
                               p_matfunc number) return varchar2 deterministic;

  function get_grauinstr_periodo(p_dtref   date,
                                 p_matfunc number) return number;

  function get_descricao_grauinstr(p_codgrau int) return varchar2 deterministic;

  function get_descricao_grauinstr(p_dtref   date,
                                   p_matfunc number) return varchar2 deterministic;

  function get_descricao_estcivil(p_estcivil int) return varchar2;

  function get_totalfunc(p_dtref date,
                         p_tipo  varchar2) return number;

  procedure calcula_saldo_func(p_dtref date);

  procedure calcula_saldo_func(p_dtref date,
                               p_force boolean);

  procedure calcula_totais_acumulado(p_dtref date);

  procedure cria_relacao_lotacao_fpw;

end ad_pkg_rh;
/


CREATE OR REPLACE package body ad_pkg_rh is

  /*
    Author: MARCUS.RANGEL 28/06/2019 13:44:43
    retorna a descrição do cargo mais reccente do funcionário considerando se ativo ou inativo
  */
  function get_descrcargo_func(p_codemp  number,
                               p_matfunc number) return varchar2 deterministic is
    i        int;
    v_result varchar2(200);
  
    cursor cur_cargo(p_codemp  number,
                     p_matfunc number) is
      select c.cadescargo
      --Into v_result
        from fpwpower.funciona f
        join fpwpower.cargos c
          on f.fucodcargo = c.cacodcargo
         and f.fucodemp = c.cacodemp
       where f.fumatfunc = p_matfunc
         and f.fucodemp = p_codemp;
  
    c cur_cargo%rowtype;
  begin
  
    open cur_cargo(p_codemp, p_matfunc);
    fetch cur_cargo
      into c;
    i := cur_cargo%rowcount;
    close cur_cargo;
  
    if (i = 1) then
      open cur_cargo(p_codemp, p_matfunc);
      fetch cur_cargo
        into v_result;
      close cur_cargo;
    
    else
      select c.cadescargo
        into v_result
        from fpwpower.funciona f
        join fpwpower.cargos c
          on f.fucodcargo = c.cacodcargo
         and f.fucodemp = c.cacodemp
       where f.fumatfunc = p_matfunc
         and f.fucodemp = p_codemp
         and c.castatus = 'A'
         and rownum = 1;
    
    end if;
  
    return(v_result);
  
  exception
    when no_data_found then
      return 'Sem Cargo informado';
    when others then
      return 'Sem cargo';
      --dbms_output.put_line( 'erro: ' || sqlerrm ||' - '||p_matfunc); 
  end get_descrcargo_func;

  function get_descricao_estcivil(p_estcivil int) return varchar2 is
    v_descricao varchar2(4000);
  begin
  
    v_descricao := case
                     when p_estcivil = '1' then
                      'Solteiro'
                     when p_estcivil = '2' then
                      'Casado'
                     when p_estcivil = '3' then
                      'Sep. Judicialmente'
                     when p_estcivil = '4' then
                      'Divorciado'
                     when p_estcivil = '5' then
                      'Viuvo'
                     when p_estcivil = '6' then
                      'Outros'
                     when p_estcivil = '7' then
                      'Ignorado'
                   end;
  
    return v_descricao;
  
  end get_descricao_estcivil;

  function get_grauinstr_periodo(p_dtref   date,
                                 p_matfunc number) return number is
    v_result number;
  begin
    select grauinstr
      into v_result
      from (with maior_data as (select f.fuhistcodemp codemp,
                                       f.fuhistmatfunc matfunc,
                                       max(fmt.number_to_date(f.fuhistdataini)) dataini
                                  from fpwpower.funcionahist f
                                 where to_date(p_dtref,'dd/mm/yyyy') between to_date(trunc(fmt.number_to_date(f.fuhistdataini), 'mm'),'dd/mm/yyyy') and
                                       to_date(trunc(fmt.number_to_date(f.fuhistdatafim), 'mm'),'dd/mm/yyyy')
                                   and f.fuhistmatfunc = p_matfunc
                                 group by f.fuhistcodemp, f.fuhistmatfunc)
             select --fh.*
              fh.fuhistcodemp codemp,
              fh.fuhistmatfunc matfunc,
              f.fudtadmis dtadmiss,
              f.funomfunc nomefunc,
              fmt.number_to_date(fh.fuhistdataini) dtini,
              fmt.number_to_date(fh.fuhistdatafim) dtfim,
              fh.fuhistgrauinst grauinstr
               from fpwpower.funcionahist fh
               join fpwpower.funciona f
                 on f.fumatfunc = fh.fuhistmatfunc
               join maior_data md
                 on md.codemp = fh.fuhistcodemp
                and md.matfunc = fh.fuhistmatfunc
                and fmt.number_to_date(fh.fuhistdataini) = md.dataini
              where fh.fuhistcodemp = 1
                and to_number(fh.fuhistmatfunc) = p_matfunc)
              where 1 = 1
                and p_dtref between trunc(dtini, 'mm') and trunc(dtfim, 'mm')
                and (trunc(dtfim, 'mm') >= p_dtref)
                and rownum = 1;
  
  
    return v_result;
  
  end get_grauinstr_periodo;

  function get_descricao_grauinstr(p_dtref   date,
                                   p_matfunc number) return varchar2 is
    v_result  varchar2(100);
    v_codgrau int;
  begin
    v_codgrau := get_grauinstr_periodo(p_dtref, p_matfunc);
    v_result  := get_descricao_grauinstr(v_codgrau);
    return v_result;
  end get_descricao_grauinstr;

  function get_descricao_grauinstr(p_codgrau int) return varchar2 is
    v_result varchar2(100);
  begin
    v_result := case
                  when p_codgrau = 1 then
                   'Analfabeto'
                  when p_codgrau = 2 then
                   'Primeiro Grau Incompleto'
                  when p_codgrau = 3 then
                   'Primeiro grau completo'
                  when p_codgrau = 4 then
                   'Ens. Fundamental Incompleto'
                  when p_codgrau = 5 then
                   'Ens. Fundamental Completo'
                  when p_codgrau = 6 then
                   'Ensino Médio Incompleto'
                  when p_codgrau = 7 then
                   'Ensino Médio Completo'
                  when p_codgrau = 8 then
                   'Superior Incompleto'
                  when p_codgrau = 9 then
                   'Superior Completo'
                  when p_codgrau = 10 then
                   'Pós-Graduação/Especialização'
                  when p_codgrau = 11 then
                   'Doutorado Completo'
                  when p_codgrau = 12 then
                   'Segundo grau técnico incompleto'
                  when p_codgrau = 13 then
                   'Segundo grau técnico completo'
                  when p_codgrau = 14 then
                   'Mestrado'
                  when p_codgrau = 15 then
                   'Pós-Doutorado'
                  else
                   'Não informado'
                end;
  
    return v_result;
  
  end get_descricao_grauinstr;

  /*
    Autor: MARCUS.RANGEL 05/06/2019 14:35:41
    Objetivo: retorna o total de funcionário tendo o FPW como base.  
  */
  function get_totalfunc(p_dtref date,
                         p_tipo  varchar2) return number is
    totalfunc number;
  begin
    -- tipo A = Admissoes
    -- tipo R = Rescições
    select count(*)
      into totalfunc
      from fpwpower.funciona t
     inner join fpwpower.situacao s
        on s.stcodsitu = t.fucodsitu
     where t.fucodemp = 1
       and fmt.number_to_date(t.fudtadmis) <= last_day(p_dtref)
       and (exists (select 1
                      from ad_prhsit p
                     where p.nuprh = 1
                       and fucodsitu = p.codsit
                       and p.gruporel = p_tipo) or fmt.number_to_date(t.fudtinisit) > last_day(p_dtref));
  
    return totalfunc;
  exception
    when others then
      return 0;
  end get_totalfunc;

  procedure calcula_saldo_func(p_dtref date,
                               p_force boolean) is
  begin
  
    /*
      Autor: MARCUS.RANGEL 05/06/2019 14:36:11
      Objetivo: Calcula o total de funcionários ativos,
                total de admissões e demissões em um internvalo 
                de 12 meses a partir da data informada e grava na
                tabela AD_TSFSFC
    */
  
    for l in (with adm as
                 (select trunc(dtadmiss, 'mm') dtref, count(*) totadm
                   from ad_mw_basefunc f
                  where dtadmiss between trunc(add_months(p_dtref, -12), 'mm') and last_day(p_dtref)
                    and (dtrescisao is null or dtrescisao > dtadmiss)
                  group by trunc(dtadmiss, 'mm')),
                dem as
                 (select trunc(dtrescisao, 'mm') dtref, count(*) totdem
                   from ad_mw_basefunc f
                  where dtrescisao between trunc(add_months(p_dtref, -12), 'mm') and last_day(p_dtref)
                  group by trunc(dtrescisao, 'mm'))
                
                select a.dtref,
                       a.totadm,
                       d.totdem,
                       (select count(*)
                          from ad_mw_basefunc
                         where dtadmiss <= to_date(last_day(a.dtref), 'dd/mm/yyyy')
                           and (dtrescisao is null or dtrescisao > last_day(a.dtref))) totfunc
                  from adm a
                  join dem d
                    on d.dtref = a.dtref
                 where a.dtref between add_months(p_dtref, -12) and p_dtref
                 order by 1)
    loop
    
      if p_force then
        merge into ad_tsfsfc s
        using (select l.dtref dtref, l.totadm totadm, l.totdem totdem, l.totfunc totfunc from dual) d
        on (s.dtref = d.dtref)
        when matched then
          update
             set totadm  = d.totadm,
                 totdem  = d.totdem,
                 totfunc = d.totfunc
        when not matched then
          insert (dtref, totadm, totdem, totfunc) values (l.dtref, l.totadm, l.totdem, l.totfunc);
      
      else
      
        begin
          insert into ad_tsfsfc (dtref, totadm, totdem, totfunc) values (l.dtref, l.totadm, l.totdem, l.totfunc);
        exception
          when dup_val_on_index then
            continue;
        end;
      end if;
    
    end loop;
  end calcula_saldo_func;

  procedure calcula_saldo_func(p_dtref date) is
  begin
    /*
      Autor: MARCUS.RANGEL 05/06/2019 14:37:48
      Objetivo: Chamada mínima para a proc calcula_saldo_func.  
    */
    calcula_saldo_func(p_dtref, false);
  
  end calcula_saldo_func;

  procedure calcula_totais_acumulado(p_dtref date) is
  
    type ty_tab_media_idade is table of ad_tsfsfc%rowtype;
  
    t ty_tab_media_idade := ty_tab_media_idade();
  
    i integer;
  
  begin
  
    --  for m in (select add_months(p_dtref, - (rownum - 1)) as dtref from dba_objects o where rownum <= 13 order by 1 desc)
    --loop
    t.extend;
    i := t.last;
  
    select dtref,
           avg(ageh) ageh,
           avg(agem) agem,
           sum(g1) fund,
           sum(g2) med,
           sum(g3) sup,
           count(ageh) qtdh,
           count(agem) qtdm,
           sum(fx_1) fx1,
           sum(fx_2) fx2,
           sum(fx_3) fx3,
           sum(fx_4) fx4,
           sum(fx_5) fx5,
           sum(fx_6) fx6,
           sum(t1) t1,
           sum(t2) t2,
           sum(t3) t3,
           sum(t4) t4,
           sum(t5) t5,
           sum(t6) t6
      into t(i).dtref,
           t(i).idadeh,
           t(i).idadem,
           t(i).qtdfund,
           t(i).qtdmed,
           t(i).qtdsup,
           t(i).qtdh,
           t(i).qtdm,
           t(i).fx1,
           t(i).fx2,
           t(i).fx3,
           t(i).fx4,
           t(i).fx5,
           t(i).fx6,
           t(i).t1,
           t(i).t2,
           t(i).t3,
           t(i).t4,
           t(i).t5,
           t(i).t6
      from (select p_dtref dtref,
                   case
                     when sexo = 'M' then
                      (round(ad_get.meses_entre_datas(dtnasc, last_day(p_dtref)) / 12))
                   end as ageh,
                   case
                     when sexo = 'F' then
                      (round(ad_get.meses_entre_datas(dtnasc, last_day(p_dtref)) / 12))
                   end as agem,
                   case
                     when ad_pkg_rh.get_grauinstr_periodo(p_dtref, matfunc) in (1, 2, 3, 4, 5) then
                      1
                     else
                      0
                   end as g1,
                   case
                     when ad_pkg_rh.get_grauinstr_periodo(p_dtref, matfunc) in (6, 7, 12, 13) then
                      1
                     else
                      0
                   end as g2,
                   case
                     when ad_pkg_rh.get_grauinstr_periodo(p_dtref, matfunc) in (8, 9, 10, 11, 14, 15) then
                      1
                     else
                      0
                   end as g3,
                   case
                     when round(ad_get.meses_entre_datas(f.dtnasc, last_day(p_dtref)) / 12) between 18 and 20 then
                      1
                     else
                      0
                   end as fx_1,
                   case
                     when round(ad_get.meses_entre_datas(f.dtnasc, last_day(p_dtref)) / 12) between 21 and 25 then
                      1
                     else
                      0
                   end as fx_2,
                   case
                     when round(ad_get.meses_entre_datas(f.dtnasc, last_day(p_dtref)) / 12) between 26 and 30 then
                      1
                     else
                      0
                   end as fx_3,
                   case
                     when round(ad_get.meses_entre_datas(f.dtnasc, last_day(p_dtref)) / 12) between 31 and 35 then
                      1
                     else
                      0
                   end as fx_4,
                   case
                     when round(ad_get.meses_entre_datas(f.dtnasc, last_day(p_dtref)) / 12) between 36 and 40 then
                      1
                     else
                      0
                   end as fx_5,
                   case
                     when round(ad_get.meses_entre_datas(f.dtnasc, last_day(p_dtref)) / 12) > 40 then
                      1
                     else
                      0
                   end as fx_6,
                   case
                     when ad_get.meses_entre_datas(dtadmiss, dtinisit) between 0 and 3 then
                      1
                     else
                      0
                   end as t1,
                   case
                     when ad_get.meses_entre_datas(dtadmiss, dtinisit) between 4 and 6 then
                      1
                     else
                      0
                   end as t2,
                   case
                     when ad_get.meses_entre_datas(dtadmiss, dtinisit) between 7 and 12 then
                      1
                     else
                      0
                   end as t3,
                   case
                     when ad_get.meses_entre_datas(dtadmiss, dtinisit) between 13 and 24 then
                      1
                     else
                      0
                   end as t4,
                   case
                     when ad_get.meses_entre_datas(dtadmiss, dtinisit) between 25 and 60 then
                      1
                     else
                      0
                   end as t5,
                   case
                     when ad_get.meses_entre_datas(dtadmiss, dtinisit) > 60 then
                      1
                     else
                      0
                   end as t6
              from ad_mw_basefunc f
             where dtadmiss <= last_day(p_dtref)
               and (dtrescisao is null or trunc(dtrescisao, 'fmmm') > last_day(p_dtref))
            --and (f.statuscargo = 'A' or Trunc(f.dtinatcargo,'mm') > m.Dtref)
            )
     group by dtref;
  
    --end loop;
  
    forall l in t.first .. t.last
      update ad_tsfsfc
         set idadeh  = t(l).idadeh,
             idadem  = t(l).idadem,
             qtdfund = t(l).qtdfund,
             qtdmed  = t(l).qtdmed,
             qtdsup  = t(l).qtdsup,
             qtdh    = t(l).qtdh,
             qtdm    = t(l).qtdm,
             fx1     = t(l).fx1,
             fx2     = t(l).fx2,
             fx3     = t(l).fx3,
             fx4     = t(l).fx4,
             fx5     = t(l).fx5,
             fx6     = t(l).fx6,
             t1      = t(l).t1,
             t2      = t(l).t2,
             t3      = t(l).t3,
             t4      = t(l).t4,
             t5      = t(l).t5,
             t6      = t(l).t6
       where dtref = t(l).dtref;
  
  end calcula_totais_acumulado;


  procedure cria_relacao_lotacao_fpw
  as
   v_last_codlot varchar2(10);
   v_codpai varchar2(10);
   
   type t_lotacoes is table of fpw_lotacoes_rel%rowtype;
   
   t t_lotacoes := t_lotacoes();
   
  begin
  
   for lot in (
   
   with base as 
  (select locodemp codemp,
    lpad(l.locodlot,10,'0') codlot, 
    l.lodesclot descricao
  from FPWPOWER.lotacoes l
   where locodemp = 1
  order by 1,2),
   lot as 
   (select codemp, codlot, descricao,
    to_number(substr(codlot,1,3)) as avo,
    to_number(substr(codlot,4,2)) as pai,
    to_number(substr(codlot,6,3)) as filho,
    to_number(substr(codlot,9,2)) as neto
   from base),
   main as 
    (select codemp, codlot, descricao,
      case 
        when avo > 0 and pai = 0 and filho = 0 and neto = 0 then 1
        when avo > 0 and pai > 0 and filho = 0 and neto = 0 then 2
        when avo > 0 and pai > 0 and filho > 0 and neto = 0 then 3
        when avo > 0 and pai > 0 and filho > 0 and neto > 0 then 4
      end as grau
      from lot)
    select * from main
   
    ) 
    loop
     if lot.grau = 1 then 
      v_codpai := null;
     else
      v_codpai := v_last_codlot;
     end if;
     
     v_last_codlot := lot.codlot;
     
     t.extend;
     t(t.last).codemp := lot.codemp;
     t(t.last).codlot := lot.codlot;
     t(t.last).grau := lot.grau;
     t(t.last).codlotpai := v_codpai;
     
     --Dbms_Output.put_line( lot.codemp ||' - '||lot.codlot ||' - '|| lot.grau ||' - '|| v_codpai );
         
    
    end loop;
    
       forall i in t.first .. t.last
      merge into fpw_lotacoes_rel l
      using (select t(i).codemp as codemp,
              t(i).codlot as codlot,
              t(i).grau as grau,
              t(i).codlotpai codlotpai
            from dual )d 
      on (l.codemp = d.codemp and l.codlot = d.codlot)
      when matched then
      update set codlotpai = d.codlotpai
      when not matched then
      insert values (d.codemp, d.codlot, d.grau, d.codlotpai); 
      
      commit;
  
  end cria_relacao_lotacao_fpw;
  
end ad_pkg_rh;
/
