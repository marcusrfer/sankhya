create or replace view ad_vw_cmp as
select c.nunota, c.codemp, c.numnota, c.dtfatur, c.codparc, c.numcontrato numcontratoarmz,
       c.ordemcarga, i.codprod,
       --i.qtdneg,
       round(nvl(cl.pesobruto - cl.tara, i.qtdneg), 2) qtdneg,
       --round(i.qtdneg / 60,2) qtdsacas,
       round(nvl(cl.pesobruto - cl.tara, i.qtdneg) / 60, 2) qtdsacas, i.vlrunit,
       i.vlrunit * 60 vlrsaca,
       ad_pkg_cmp.get_vlrcontrato(ic.numcontrato, ic.codprod) * 60 vlrsacacontrato, c.vlrnota,
       c.vlrfrete, round((c.vlrfrete / i.qtdneg) * 60, 4) vlrfretesaca, ic.sequencia, ic.umidade,
       ic.numcontrato contratocpa,
       nvl(ad_pkg_cmp.get_vlrdescumidade(ic.numcontrato, ic.codprod), 0) vlrdescumid,
       ad_pkg_cmp.get_vlrsecagem(c.numcontrato, ic.umidade) vlrsecagem
  from tgfcab c
  join tgfite i
    on c.nunota = i.nunota
  left join ad_itecargto ic
    on ic.nunota = c.nunota
  join tcscon con
    on con.numcontrato = nvl(ic.numcontrato, c.numcontrato)
  left join tgacll cl
    on cl.notaromaneio = c.nunota
 where c.codtipoper in (622, 604)
   and c.codparc not in (57)
   and c.dtfatur >= trunc(sysdate, 'yyyy')
   and i.qtdneg > 0
 group by c.nunota, c.codemp, c.numnota, c.dtfatur, c.codparc, c.numcontrato, c.ordemcarga,
          i.codprod, nvl(cl.pesobruto - cl.tara, i.qtdneg),
          nvl(cl.pesobruto - cl.tara, i.qtdneg) / 60, i.vlrunit, i.vlrunit * 60,
          ad_pkg_cmp.get_vlrcontrato(ic.numcontrato, ic.codprod) * 60, c.vlrnota, c.vlrfrete,
          round((c.vlrfrete / i.qtdneg) * 60, 4), ic.sequencia, ic.umidade, ic.numcontrato,
          nvl(ad_pkg_cmp.get_vlrdescumidade(ic.numcontrato, ic.codprod), 0),
          ad_pkg_cmp.get_vlrsecagem(c.numcontrato, ic.umidade);
