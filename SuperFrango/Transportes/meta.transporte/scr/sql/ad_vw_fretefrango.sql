create or replace view ad_vw_fretefrango as
with vendas_subprodutos as
 (select c.codemp, c.ordemcarga
    from tgfcab c
    join tgfite i
      on c.nunota = i.nunota
    join tgfpro p
      on i.codprod = p.codprod
   where p.codgrupoprod in (62010000, 81040000)
     and c.statusnota = 'L'
     and c.tipmov = 'V'
     and c.ordemcarga > 0
     and c.vlrfrete > 0)
select trunc(o.dtinic, 'mm') dtref,
       ger.codvend as codger,
       ger.apelido nomeger,
       -- c.ordemcarga,
       t.categoria,
       t.codcatpai codcat,
       round(sum(c.vlrfrete), 2) vlrfrete,
       count(distinct c.ordemcarga) qtdordenscarga,
       round(avg(v.pesomax), 2) pesomediocat,
       round(count(distinct c.ordemcarga) * avg(v.pesomax), 2) capacidade,
       round(avg(c.ad_km), 2) mediakm,
       round(sum(nvl(c.ad_km, 0)), 2) kmtotal,
       round(sum(c.peso), 2) pesototal,
       round(sum(c.vlrfrete) / sum(round(nvl(c.ad_km, 1), 2)), 2) vlrkm,
       round(sum(c.peso) / (count(distinct c.ordemcarga) * avg(v.pesomax)) * 100, 2) perc_ocupacao,
       count(distinct c.ordemcarga) qtdentregas
--count( Distinct c.codparc) qtdentregas
  from tgfcab c
--join tgfite i on c.nunota = i.nunota
--join tgfpro p on p.codprod = i.codprod
  join tgford o
    on c.codemp = o.codemp
   and c.ordemcarga = o.ordemcarga
  join tgfvei v
    on c.codveiculo = v.codveiculo
  join tgfven ven
    on ven.codvend = c.codvend
  join tgfven ger
    on ven.codger = ger.codvend
  left join ad_tsfcat t
    on v.ad_codcat = t.codcat
 where c.statusnota = 'L'
   and (c.tipmov = 'V' or ((c.codtipoper = 519 and c.tipmov = 'C') or (c.codtipoper = 532 and c.tipmov = 'T')))
   and c.ordemcarga > 0
   and c.vlrfrete > 0
      --And c.codtipoper Not In (81, 27, 352)
   and not exists (select 1
          from ad_centparamtop ctop
         where ctop.codtipoper = c.codtipoper
           and nvl(ctop.utilizacao, 'X') = 'PROIBIDO'
           and ctop.nupar = 21)
   and not exists
 (select 1
          from vendas_subprodutos vsp
         where to_char(c.codemp) || to_char(c.ordemcarga) = to_char(vsp.codemp) || to_char(vsp.ordemcarga))
 group by trunc(o.dtinic, 'mm'), /* c.ordemcarga,*/ ger.codvend, ger.apelido, t.categoria, t.codcatpai;
