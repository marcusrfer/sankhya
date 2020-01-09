select *
  from ad_mw_basefunc
 where trunc(dtadmiss, 'mm') <= &dtref
   and (dtrescisao is null or dtrescisao > last_day(&dtref));

create table fpw_lotacoes_lig as
  select codemp,
         codlot,
         ad_pkg_rh.get_lotacao_grau(codlot, 4) as divisao,
         ad_pkg_rh.get_lotacao_grau(codlot, 3) as setor,
         ad_pkg_rh.get_lotacao_grau(codlot, 2) as depto,
         ad_pkg_rh.get_lotacao_grau(codlot, 1) as unidade
    from fpw_lotacoes_rel
   where codemp = 1
     and grau in (3, 4)
   order by codlot;

create table fpw_lotacoes_lig2 as
  select * from fpw_lotacoes_lig;

drop table fpw_lotacoes_lig purge;
