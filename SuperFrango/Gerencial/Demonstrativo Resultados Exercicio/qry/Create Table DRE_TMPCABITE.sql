Drop Table dre_tmpcabite;
/

Create Table DRE_TMPCABITE
As
  Select Trunc(dtfatur, 'mm') As Dtref, cab.nunota, ite.sequencia,
             Case
                When Cab.Codemp > 500 Then
                 Cab.Codemp - 500
                Else
                 Cab.Codemp
              End As Codemp, Cab.Tipmov, Cab.Codtipoper, Cab.Dtneg, Cab.Dtfatur, Cab.Codvend,
             Cab.Codparc, Par.Codcid, Cab.Vlrfrete, Cab.Peso, Cab.Vlrdesctot,
             Ad_Get.Cidtransbordo(Cab.Ordemcarga) As Cidcross, Ufs.Coduf, Ufs.Descricao Descruf,
             Cab.Codcencus, Cus.Descrcencus, Cus.Ad_Sigla Unneg, Cus.Ad_Codune Codune,
             -- item
             Ite.Codprod, Pro.Descrprod, Pro.Codgrupoprod, Pro.Codvol,
             Decode(Cab.Tipmov, 'V', 1, 0) * Ite.Qtdneg As Qtdneg,
             Decode(Cab.Tipmov, 'D', 1, 0) * Ite.Qtdneg As Qtddev, Ite.Vlrunit, Ite.Vlrtot,
             ite.Vlrdesc, Round(Nvl(Ite.Ad_Vlrtrx, 0) / Qtdneg, 4) As Vlrtrx,
             Nvl(Pro.Credmp1, 0) As Credmp1, Nvl(Pro.Credmp2, 0) As Credmp2,
             --impostos
             Round(Ite.Vlripi / Qtdneg, 4) As Vlripi, Round(Ite.Vlrsubst / Qtdneg, 4) As Vlrsubst,
             Round(Ite.Vlrrepred / Ite.Qtdneg, 4) As Vlrrepred,
             Round(Ite.Vlricms / Qtdneg, 4) As Vlricms,
             Round(Nvl(Ite.Ad_Icmstrx, 0) / Qtdneg, 4) vlrIcmstrx,
             Nvl(Emp.Ad_Credoutorg, 0) As Credoutgemp, Cab.Codempnegoc As Codempneg
        From Tgfcab Cab
        Join Tgfite Ite
          On Cab.Nunota = Ite.Nunota
        Join Tgfpar Par
          On Cab.Codparc = Par.Codparc
        Join Tgfpro Pro
          On Ite.Codprod = Pro.Codprod
        Join Tsiemp Emp
          On Cab.Codemp = Emp.Codemp
        Join Tsicus Cus
          On Cab.Codcencus = Cus.Codcencus
        Join Tsicid Cid
          On Par.Codcid = Cid.Codcid
        Join Tsiufs Ufs
          On Cid.Uf = Ufs.Coduf
        Join Tgftop Top
          On Cab.Codtipoper = Top.Codtipoper
         And Cab.Dhtipoper = Top.Dhalter
        Join Tgford Ord
          On Cab.Ordemcarga = Ord.Ordemcarga
         And Cab.Codemp = Ord.Codemp
       Where Cab.Statusnota = 'L'
         And Trunc(Cab.Dtfatur, 'mm') = '01/01/2018'
         And (Cab.Ordemcarga Is Not Null Or Cab.Ordemcarga <> 0)
         And Upper(top.grupo) In ('VENDA', 'DEV. VENDA')
         And Cab.Codemp <> 8
/*				 And cab.codemp = 1
				 And ufs.coduf = 9
				 And cus.ad_codune = 4*/;
