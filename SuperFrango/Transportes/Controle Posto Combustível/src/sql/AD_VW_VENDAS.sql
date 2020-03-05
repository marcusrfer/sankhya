create materialized view AD_VW_VENDAS
refresh force on demand
start with to_date('18-07-2017 21:44:47', 'dd-mm-yyyy hh24:mi:ss') next null
as
(Select
			t.Grupo,
			t.Tipmov,
			c.nunota,
			i.sequencia,
			C.Codemp,
			C.Codtipoper,
			Descroper,
			f.codnat,
			n.Descrnat,
			C.Dtneg,
			P.Codgrupoprod,
			g.Descrgrupoprod,
			I.Codprod,
			P.Descrprod,
			i.qtdneg, -- Sum(I.Qtdneg) qtdneg,
			I.Codvol,
			(Case When I.Codvol <> P.Codvol And V.Dividemultiplica = 'M' Then  /*Sum(Qtdneg)*/ i.qtdneg * V.Quantidade When
					I.Codvol <> P.Codvol And
					V.Dividemultiplica = 'D' Then /*Sum(Qtdneg)*/ i.qtdneg / V.Quantidade Else /*Sum(Qtdneg)*/ i.qtdneg End) QtdVolAlt,
			P.Codvol codvolpad,
			/*Sum(Vlrnota)*/ (i.vlrtot - i.vlrdesc) * (Case When t.Tipmov = 'V' Then 1 Else -1 End) VLRTOT
		From Tgfcab C
			Join Tgfite I On C.Nunota = I.Nunota
			Join Tgffin f On C.Nunota = f.Nunota
			Join Tgfnat n On f.codnat = n.codnat
			Join Tgfpro P On I.Codprod = P.Codprod
			Join Tgftop t On C.Codtipoper = t.Codtipoper And C.Dhtipoper = t.Dhalter
			Join Tgfgru g On P.Codgrupoprod = g.Codgrupoprod
			Left Join Tgfvoa V On I.Codprod = V.Codprod
			Join Ad_tsfpfe pfe On C.Codemp = pfe.Codemp And pfe.Nupfc = 1
			Join Ad_tsfpft pft On t.Codtipoper = pft.Codtipoper And pft.Nupfc = 1
			Join Ad_tsfpfn pfn On n.codnat = pfn.codnat And pfn.Nupfc = 1
		Where C.Dtneg >= '01/01/2017'
			And c.tipmov In ('V', 'D')
			And upper(t.grupo) In ('VENDA','DEV. VENDA')
/*		Group By t.Grupo, t.Tipmov, C.Codemp, C.Codtipoper, Descroper, f.codnat, n.Descrnat, C.Dtneg,
		P.Codgrupoprod, g.Descrgrupoprod, I.Codprod, P.Descrprod, I.Codvol, V.Dividemultiplica, V.Quantidade, P.Codvol*/
		);
