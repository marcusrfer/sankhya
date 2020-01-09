create or replace package ad_pkg_qdf as

 -- Author  : MARCUS.RANGEL
 -- Created : 28/08/2019 08:54:20
 -- Purpose : agrupar os objetos utilizados no processo de montagem do quadro de funcionários

 --- tornou-se obleto em 10/09/19 com a mudança para o componente html5
 type rec_quantidades is record(
  codpai    number,
  codigo    number,
  descricao varchar2(250),
  grau      int,
  numet     number default null,
  codlot    number default null,
  codcencus number default null,
  ideal     number,
  ativos    number,
  efetivos  number,
  afastados number,
  faltosos  number);

 type tab_quantidades is table of rec_quantidades;

 function quadro_func return tab_quantidades
 pipelined;

 ---

 type rec_quadro is record(
  nvl1      varchar2(300),
  nvl2      varchar2(300),
  nvl3      varchar2(300),
  nvl4      varchar2(300),
  grau      integer,
  numet     number default null,
  codlot    number default null,
  ideal     number,
  ativos    number,
  efetivos  number,
  afastados number,
  faltas    number,
  dif       number,
  vagas     number);

 type tab_quadro is table of rec_quadro;

 function retorna_quadro return tab_quadro
 pipelined;

end ad_pkg_qdf;
/
create or replace package body ad_pkg_qdf is

 /*
   Autor: MARCUS.RANGEL 03/09/2019 17:22:06
   Objetivos: Agrupar os métodos utilizados na montagem do quadro de func.
 */

 --> Função que retorna o quadro
 --- tornou-se obleto em 10/09/19 com a mudança para o componente html5
 function quadro_func return tab_quantidades
 pipelined is
  t rec_quantidades;
 begin
  for l in (
            
             with metas as
              (select p.*
                 from ad_tsfpqf p
                where p.dtquadro = (select max(dtquadro)
                                      from ad_tsfpqf p2
                                     where p2.codemp = p.codemp
                                       and p2.codlot = p.codlot
                                       and p2.dtquadro < trunc(sysdate)))
             
             select h.codhqfpai, h.codhqf, /*lpad(' ', h.grau * 3, '.') || */ h.descricao descricao, h.grau,
                    h.analitico, q.numet, q.codlot, q.codcencus, nvl(m.qtdfunc, 0) ideal,
                    nvl(sum(q.ativos), 0) ativos, nvl(sum(q.efetivos), 0) efetivos,
                    nvl(sum(q.afastados), 0) afastados, nvl(sum(f.qtdfaltas), 0) faltosos
               from ad_tsfhqf h
               left join ad_vw_basequadro q
                 on q.codemp = h.codemp
                and q.codlot = h.codlot
               left join ad_vw_basefaltas_func f
                 on f.empresa = q.codemp
                and f.matricula = q.matricula
                and f.codlot = q.codlot
               left join metas m
                 on m.codemp = q.codemp
                and m.codlot = q.codlot
              group by h.codhqfpai, h.codhqf, /*lpad(' ', h.grau * 3, '.') ||*/ h.descricao, h.grau, h.analitico,
                       q.numet, q.codlot, q.codcencus, nvl((m.qtdfunc), 0)
              order by h.codhqf
             
            )
  
  loop
   t.codpai    := l.codhqfpai;
   t.codigo    := l.codhqf;
   t.descricao := l.descricao;
   t.grau      := l.grau;
  
   if l.analitico = 'N' then
   
    with faltosos as
     (select f.empresa, f.codlot, nvl(sum(f.qtdfaltas), 0) faltas
        from ad_vw_basefaltas_func f
       group by f.empresa, f.codlot),
    metas as
     (select p.dtquadro, p.codemp, p.codlot, p.numet, p.qtdfunc
        from ad_tsfpqf p
       where p.dtquadro = (select max(p2.dtquadro)
                             from ad_tsfpqf p2
                            where p2.codemp = p.codemp
                              and p.codlot = p2.codlot
                              and p2.dtquadro < trunc(sysdate))),
    totais as
     (select q.codlot, q.numet, sum(ativos) ativos, sum(efetivos) efetivos, sum(afastados) afastados,
             m.qtdfunc previsto, count(f.faltas) faltosos
        from ad_vw_basequadro q
        left join metas m
          on m.codemp = q.codemp
         and m.codlot = q.codlot
        left join faltosos f
          on f.empresa = q.codemp
         and f.codlot = q.codlot
       where q.codlot in (select codlot
                            from (select level, q.codhqfpai, q.codhqf, codlot, connect_by_isleaf folha
                                     from ad_tsfhqf q
                                    start with q.codhqf = l.codhqf
                                   connect by prior q.codhqf = q.codhqfpai)
                           where folha = 1)
         and q.numet in (select numet
                           from (select level, q.codhqfpai, q.codhqf, numet, connect_by_isleaf folha
                                    from ad_tsfhqf q
                                   start with q.codhqf = l.codhqf
                                  connect by prior q.codhqf = q.codhqfpai)
                          where folha = 1)
       group by q.codlot, q.numet, m.qtdfunc)
    select sum(previsto) ideal, sum(ativos) ativos, sum(efetivos) efetivos, sum(afastados) afastados,
           sum(faltosos) faltosos
      into t.ideal, t.ativos, t.efetivos, t.afastados, t.faltosos
      from totais;
   
   else
    t.numet     := l.numet;
    t.codlot    := l.codlot;
    t.codcencus := l.codcencus;
    t.ideal     := l.ideal;
    t.ativos    := l.ativos;
    t.efetivos  := l.efetivos;
    t.afastados := l.afastados;
    t.faltosos  := l.faltosos;
   end if;
  
   pipe row(t);
  
  end loop;
 end;

 function retorna_quadro return tab_quadro
 pipelined is
  tq rec_quadro;
  type new_temp_type is table of rec_quadro;
  tx new_temp_type := new_temp_type();
 begin
  with ativos as
   (select codemp, codlot, sum(bq.ativos) ativos, sum(bq.afastados) afastados, sum(bq.efetivos) efetivos
      from ad_vw_basequadro bq
     group by codemp, codlot),
  
  metas as
   (select p.*
      from ad_tsfpqf p
     where p.dtquadro = (select max(dtquadro)
                           from ad_tsfpqf p2
                          where p2.codemp = p.codemp
                            and p2.codlot = p.codlot
                            and p2.dtquadro < trunc(sysdate))),
  
  faltosos as
   (select f.empresa, f.codlot, nvl(sum(f.qtdfaltas), 0) faltas
      from ad_vw_basefaltas_func f
     group by f.empresa, f.codlot),
  
  vagas as
   (select codemp, codlot, count(*) vagas from ad_vw_vagasdisp_fpw group by codemp, codlot),
  
  base as
   (select hq.codhqf,
           last_value(nivel1) ignore nulls over(order by codhqf rows between unbounded preceding and current row) nvl1,
           last_value(nivel2) ignore nulls over(order by codhqf rows between unbounded preceding and current row) nvl2,
           last_value(nivel3) /*ignore nulls*/ over(order by codhqf rows between unbounded preceding and current row) nvl3,
           last_value(nivel4) /*ignore nulls*/ over(order by codhqf rows between unbounded preceding and current row) nvl4,
           hq.grau, hq.codemp, hq.codlot, hq.numet
      from (select codhqf, grau,
                    case
                     when q.grau = 1 then
                      q.descricao
                    end nivel1,
                    case
                     when q.grau = 2 then
                      q.descricao
                    end nivel2,
                    case
                     when q.grau = 3 then
                      q.descricao
                    end nivel3,
                    case
                     when q.grau = 4 then
                      q.descricao
                    end nivel4, codlot, codemp, codcencus, numet
               from ad_tsfhqf q) hq
    
    ),
  totais as
   (select b.*,
           case
            when grau = 1 then
             sum(nvl(m.qtdfunc, 0)) over(partition by nvl1 order by b.codlot)
            when grau = 2 then
             sum(nvl(m.qtdfunc, 0)) over(partition by nvl2 order by b.codlot)
            when grau = 3 then
             sum(nvl(m.qtdfunc, 0)) over(partition by nvl3 order by b.codlot)
            when grau = 4 then
             sum(nvl(m.qtdfunc, 0)) over(partition by nvl4 order by b.codlot)
           end ideal,
           case
            when grau = 1 then
             sum(nvl(at.ativos, 0)) over(partition by nvl1 order by b.codlot)
            when grau = 2 then
             sum(nvl(at.ativos, 0)) over(partition by nvl2 order by b.codlot)
            when grau = 3 then
             sum(nvl(at.ativos, 0)) over(partition by nvl3 order by b.codlot)
            when grau = 4 then
             sum(nvl(at.ativos, 0)) over(partition by nvl4 order by b.codlot)
           end ativos,
           case
            when grau = 1 then
             sum(nvl(at.afastados, 0)) over(partition by nvl1 order by b.codlot)
            when grau = 2 then
             sum(nvl(at.afastados, 0)) over(partition by nvl2 order by b.codlot)
            when grau = 3 then
             sum(nvl(at.afastados, 0)) over(partition by nvl3 order by b.codlot)
            when grau = 4 then
             sum(nvl(at.afastados, 0)) over(partition by nvl4 order by b.codlot)
           end afastados,
           case
            when grau = 1 then
             sum(nvl(at.efetivos, 0)) over(partition by nvl1 order by b.codlot)
            when grau = 2 then
             sum(nvl(at.efetivos, 0)) over(partition by nvl2 order by b.codlot)
            when grau = 3 then
             sum(nvl(at.efetivos, 0)) over(partition by nvl3 order by b.codlot)
            when grau = 4 then
             sum(nvl(at.efetivos, 0)) over(partition by nvl4 order by b.codlot)
           end efetivos,
           case
            when grau = 1 then
             sum(nvl(f.faltas, 0)) over(partition by nvl1 order by b.codlot)
            when grau = 2 then
             sum(nvl(f.faltas, 0)) over(partition by nvl2 order by b.codlot)
            when grau = 3 then
             sum(nvl(f.faltas, 0)) over(partition by nvl3 order by b.codlot)
            when grau = 4 then
             sum(nvl(f.faltas, 0)) over(partition by nvl4 order by b.codlot)
           end faltas,
           case
            when grau = 1 then
             sum(nvl(v.vagas, 0)) over(partition by nvl1 order by b.codlot)
            when grau = 2 then
             sum(nvl(v.vagas, 0)) over(partition by nvl2 order by b.codlot)
            when grau = 3 then
             sum(nvl(v.vagas, 0)) over(partition by nvl3 order by b.codlot)
            when grau = 4 then
             sum(nvl(v.vagas, 0)) over(partition by nvl4 order by b.codlot)
           end vagas
      from base b
      left join ativos at
        on at.codemp = b.codemp
       and at.codlot = b.codlot
      left join metas m
        on m.codemp = b.codemp
       and m.codlot = b.codlot
      left join faltosos f
        on f.empresa = b.codemp
       and f.codlot = b.codlot
      left join vagas v
        on v.codemp = b.codemp
       and v.codlot = b.codlot
     order by codhqf)
  
  select t.nvl1, t.nvl2, t.nvl3, t.nvl4, grau, numet, codlot, ideal, ativos, efetivos, afastados, faltas,
         (ideal - efetivos) as dif, vagas
    bulk collect
    into tx
    from totais t;
 
  for l in tx.first .. tx.last
  loop
   tq.nvl1      := tx(l).nvl1;
   tq.nvl2      := tx(l).nvl2;
   tq.nvl3      := tx(l).nvl3;
   tq.nvl4      := tx(l).nvl4;
   tq.numet     := tx(l).numet;
   tq.grau      := tx(l).grau;
   tq.codlot    := tx(l).codlot;
   tq.ideal     := tx(l).ideal;
   tq.ativos    := tx(l).ativos;
   tq.efetivos  := tx(l).efetivos;
   tq.afastados := tx(l).afastados;
   tq.faltas    := tx(l).faltas;
   tq.dif       := tx(l).dif;
   tq.vagas     := tx(l).vagas;
  
   pipe row(tq);
  end loop;
 
 end retorna_quadro;
end ad_pkg_qdf;
/
