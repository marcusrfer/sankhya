create or replace view ad_vw_rentabcom as
select b.dtref,
       b.codemp,
       b.codune,
       une.sigla,
       b.coduf,
       ufs.uf,
       b.codgrupoprod,
       b.codprod,
       sum(qtdtotal) as qtdtotal,
       round(snk_dividir(sum(d.precovenda * d.qtdtotal), sum(d.qtdtotal)), 4) precovenda,
       round(snk_dividir(sum(d.precovdasemst * d.qtdtotal), sum(d.qtdtotal)), 4) precovdasemst,
       round(snk_dividir(sum(d.icmsvenda * d.qtdtotal), sum(d.qtdtotal)), 4) icmsvenda,
       round(snk_dividir(sum(d.credoutvenda * d.qtdtotal), sum(d.qtdtotal)), 4) credoutvenda,
       round(snk_dividir(sum(d.credpresumido * d.qtdtotal), sum(d.qtdtotal)), 4) credpresumido,
       round(snk_dividir(sum(d.credicmtransf * d.qtdtotal), sum(d.qtdtotal)), 4) credicmtransf,
       round(snk_dividir(sum(d.vlrtransf * d.qtdtotal), sum(d.qtdtotal)), 4) vlrtransf,
       round(snk_dividir(sum(d.icmstransf * d.qtdtotal), sum(d.qtdtotal)), 4) icmstransf,
       round(snk_dividir(sum(d.credouttransf * d.qtdtotal), sum(d.qtdtotal)), 4) credouttransf,
       round(snk_dividir(sum(d.toticms * d.qtdtotal), sum(d.qtdtotal)), 4) toticms,
       round(snk_dividir(sum(d.pis * d.qtdtotal), sum(d.qtdtotal)), 4) pis,
       round(snk_dividir(sum(d.cofins * d.qtdtotal), sum(d.qtdtotal)), 4) cofins,
       round(snk_dividir(sum(d.credpiscofins * d.qtdtotal), sum(d.qtdtotal)), 4) credpiscofins,
       round(snk_dividir(sum(d.totcredpiscof * d.qtdtotal), sum(d.qtdtotal)), 4) totcredpiscof,
       round(snk_dividir(sum(d.recliq * d.qtdtotal), sum(d.qtdtotal)), 4) recliq,
       round(snk_dividir(sum(d.custoprod * d.qtdtotal), sum(d.qtdtotal)), 4) custoprod,
       round(snk_dividir(sum(d.crossdock * d.qtdtotal), sum(d.qtdtotal)), 4) crossdock,
       round(snk_dividir(sum(d.overadm * d.qtdtotal), sum(d.qtdtotal)), 4) overadm,
       round(snk_dividir(sum(d.overprod * d.qtdtotal), sum(d.qtdtotal)), 4) overprod,
       round(snk_dividir(sum(d.overun * d.qtdtotal), sum(d.qtdtotal)), 4) overun,
       round(snk_dividir(sum(d.totcustos * d.qtdtotal), sum(d.qtdtotal)), 4) totcustos,
       round(snk_dividir(sum(d.resoper * d.qtdtotal), sum(d.qtdtotal)), 4) resoper,
       round(snk_dividir(sum(d.freteterra * d.qtdtotal), sum(d.qtdtotal)), 4) freteterra,
       round(snk_dividir(sum(d.fretemar * d.qtdtotal), sum(d.qtdtotal)), 4) fretemar,
       round(snk_dividir(sum(d.comissao * d.qtdtotal), sum(d.qtdtotal)), 4) comissao,
       round(snk_dividir(sum(d.descontos * d.qtdtotal), sum(d.qtdtotal)), 4) descontos,
       round(snk_dividir(sum(d.descconced * d.qtdtotal), sum(d.qtdtotal)), 4) descconced,
       round(snk_dividir(sum(d.totdespcom * d.qtdtotal), sum(d.qtdtotal)), 4) totdespcom,
       round(snk_dividir(sum(d.resliqantdespace * d.qtdtotal), sum(d.qtdtotal)), 4) resliqantdespace,
       round(snk_dividir(sum(d.protgovenda * d.qtdtotal), sum(d.qtdtotal)), 4) protgovenda,
       round(snk_dividir(sum(d.protgotrans * d.qtdtotal), sum(d.qtdtotal)), 4) protgotrans,
       round(snk_dividir(sum(d.protedutribdf * d.qtdtotal), sum(d.qtdtotal)), 4) protedutribdf,
       round(snk_dividir(sum(d.fungerempdf * d.qtdtotal), sum(d.qtdtotal)), 4) fungerempdf,
       round(snk_dividir(sum(d.substtrib * d.qtdtotal), sum(d.qtdtotal)), 4) substtrib,
       round(snk_dividir(sum(d.antecipicms * d.qtdtotal), sum(d.qtdtotal)), 4) antecipicms,
       round(snk_dividir(sum(d.totdespace * d.qtdtotal), sum(d.qtdtotal)), 4) totdespace,
       round(snk_dividir(sum(d.resliqposdespace * d.qtdtotal), sum(d.qtdtotal)), 4) resliqposdespace,
       round(snk_dividir(sum(d.despfin * d.qtdtotal), sum(d.qtdtotal)), 4) despfin,
       round(snk_dividir(sum(d.recfin * d.qtdtotal), sum(d.qtdtotal)), 4) recfin,
       round(snk_dividir(sum(d.totdespfin * d.qtdtotal), sum(d.qtdtotal)), 4) totdespfin,
       round(snk_dividir(sum(d.despdir * d.qtdtotal), sum(d.qtdtotal)), 4) despdir,
       round(snk_dividir(sum(d.outrasdesp * d.qtdtotal), sum(d.qtdtotal)), 4) outrasdesp,
       round(snk_dividir(sum(d.totdespdir * d.qtdtotal), sum(d.qtdtotal)), 4) totdespdir,
       round(snk_dividir(sum(d.resliqgeral * d.qtdtotal), sum(d.qtdtotal)), 4) resliqgeral,
       round(snk_dividir(sum(d.margemcontrib * d.qtdtotal), sum(d.qtdtotal)), 4) margemcontrib
  from dre_rentabcom d
  join dre_baseindpad b
    on d.dtref = b.dtref
   and d.nunota = b.nunota
   and d.sequencia = b.sequencia
  join tsiufs ufs
    on ufs.coduf = b.coduf
  join ad_tsfune une
    on une.codune = b.codune
 where 1 = 1
 group by b.dtref, b.codemp, b.codune, b.coduf, une.sigla, b.codprod, ufs.uf, b.codgrupoprod;
