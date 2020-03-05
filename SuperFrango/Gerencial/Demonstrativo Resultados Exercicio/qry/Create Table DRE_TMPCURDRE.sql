Create Table DRE_TMPCURDRE
As
Select Distinct ITE.nunota, ITE.sequencia, ite.codprod, Nvl(ite.ad_vlrtrx, 0) vlrtrx,
        cab.tipmov, ite.qtdneg, cab.codemp, cab.dtneg, cab.ordemcarga, cab.codvend,
        cus1.codcencus, pro.codgrupoprod, cus1.descrcencus, pro.descrprod,
        pro.credmp1, pro.credmp2, pro.codvol, ufs.descricao, cab.codparc, cus1.ad_clacus,
        cus1.ad_sigla, cus1.ad_codune, ufs.uf, ite.vlrtot, ite.vlripi,
        ite.vlrdesc, ite.vlrsubst, cab.vlrdesctot, cab.peso, ite.vlrrepred
 From tgfcab cab, tgfpar par, tsicid cid, tsiufs ufs, tgfite ite, tgfpro pro, tsicus cus1,
    tsiemp emp1, tgfemp emp, tgftop tpo, tgford ord
 Where cab.codparc = par.codparc
  And cab.codemp = ord.codemp
  And cab.ordemcarga = ord.ordemcarga
  And par.codcid = cid.codcid
  And cab.statusnota = 'L'
  And ufs.coduf = cid.uf
  And cab.nunota = ite.nunota
  And ite.codprod = pro.codprod
  And cus1.codcencus = cab.codcencus
  And emp1.codemp = cab.codemp
  And emp.codemp = cab.codemp
  And cab.codcencus = cus1.codcencus
  And cab.codtipoper = tpo.codtipoper
  And cab.dhtipoper = tpo.dhalter
  And cab.codemp <> 8
  And (cab.dtfatur >= '01/01/2018')
  And (cab.dtfatur <= '31/01/2018')
  And (tpo.grupo In ('Venda', 'Dev. Venda'));
