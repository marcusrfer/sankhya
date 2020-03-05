create materialized view AD_VW_MOVCOMB
refresh force on demand
as
(Select
		'0' As TIPO, -- entradas e saídas normais
	cab.nunota,
	cab.Codparc,
	cab.Codtipoper,
		ite.Codemp,
	cab.Tipmov,
		ite.Codprod,
		pro.Descrprod,
		cab.Dtneg,
		ite.QTDNEG,
		ite.Atualestoque,
		'N' perdaent,
	'N' perdasai,
		ite.VLRUNIT,
		ite.VLRTOT
	From Tgfite ite
		Join Tgfpro pro On ite.Codprod = pro.Codprod
		Join Tgfcab cab On ite.Nunota = cab.Nunota
		Join Tgftop top On cab.Codtipoper = top.Codtipoper And cab.Dhtipoper = top.Dhalter
		Join Ad_tsfppce pce On ite.Codemp = pce.Codemp And pce.Nuppc = 1
		Join Ad_tsfppcp pcp On pce.Nuppc = pcp.Nuppc And ite.Codprod = pcp.Codprod
		Join Ad_tsfppct pct On pce.Nuppc = pct.Nuppc And cab.Codtipoper = pct.Codtipoper And (pct.perdaent Is Null And pct.perdasai Is Null)
	Where top.Tipmov In ('Q', 'C')
		And ite.Atualestoque In (1, -1)
		And cab.statusnota = 'L'
		Union All
		Select'1' As TIPO,
			 cab.nunota, cab.Codparc, cab.Codtipoper, ite.Codemp, top.Tipmov, ite.Codprod, pro.Descrprod, cab.Dtneg,
			 ite.QTDNEG, ite.Atualestoque, pct.Perdaent, pct.Perdasai, ite.VLRUNIT, ite.VLRTOT
	From tgfcab cab
	Join Tgftop top On cab.Codtipoper = top.Codtipoper
								 And cab.Dhtipoper = top.Dhalter
	Join tgfite ite On cab.nunota = ite.nunota
	Join tgfpro pro On ite.codprod = pro.codprod
	Join Ad_tsfppce pce On ite.Codemp = pce.Codemp
										 And pce.Nuppc = 1
	Join Ad_tsfppcp pcp On pce.Nuppc = pcp.Nuppc
										 And ite.Codprod = pcp.Codprod
	Join Ad_tsfppct pct On pce.Nuppc = pct.Nuppc
										 And cab.Codtipoper = pct.Codtipoper
										 And nvl(pct.perdaent, 'N') = 'S'
 Where cab.tipmov = 'Q'
 And ite.atualestoque = -1
 		And cab.statusnota = 'L');
