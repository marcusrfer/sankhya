create or replace view ad_vw_vismanut as
select /*+ RESULT_CACHE */
 vis.codemp,
 initcap(emp.nomefantasia) empresa,
 vis.matfunc,
 initcap(fu.funomfunc) nomefunc,
 fu.fucodlot codlot,
 initcap(lot.lodesclot) descrlot,
 vis.codcargo,
 ca.cadescargo descrcargo,
 vis.codcid,
 fc_nome_cidade_sf(vis.codcid) cidade,
 vis.coduf,
 ufs.uf,
 vis.dtultvis,
 (vis.dtultvis + vsm.prazovis) prox_visita,
 (vis.dtultvis + vsm.prazovis) - trunc(sysdate) dias_prox_visita
  from ad_tsfprgvis vis
  join tsiemp emp
    on emp.codemp = vis.codemp
   and emp.codempmatriz = 1
  join fpw_lotacoes_lig lig
    on lig.codlot = vis.codlot
   and lig.codemp = vis.codemp
  join ad_tsfprhvsm vsm
    on vsm.codlot = lig.setor
  join ad_tsfprh prh
    on vsm.nuprh = prh.nuprh
  join fpwpower.funciona fu
    on fu.fucodemp = vis.codemp
   and fu.fumatfunc = vis.matfunc
  join fpwpower.lotacoes lot
    on lot.locodemp = vis.codemp
   and lot.locodlot = vis.codlot
  Join fpwpower.cargos ca 
    On ca.CACODEMP = vis.codemp
    And ca.cacodcargo = vis.codcargo
  Join tsiufs ufs On ufs.coduf = vis.coduf
 where 1 = 1
   and prh.ativo = 'S'
   and vis.ativo = 'S'
   and prh.dtvigor = (select max(p2.dtvigor) from ad_tsfprh p2 where p2.nuprh = p2.nuprh)
   And Not Exists (Select 1 
                  From ad_tsfavs a 
                  Where a.codemp = vis.codemp
                  And a.matfunc = vis.matfunc
                  And a.tipovisita = 'M'
                  And a.dhprevis Between (vis.dtultvis + vsm.prazovis)-7 And (vis.dtultvis + vsm.prazovis) + 7 )
 order by fu.funomfunc
;
