Create Or Replace View ad_tsfpnc As
Select   0 As numpnc, cab.numcontrato, cab.tipmov As codtipmov,
					ad_get.opcoescampo (cab.tipmov, 'TIPMOV', 'TGFCAB') As tipmov,
					cab.nunota, cab.numnota, cab.dtentsai, cab.dtneg,
					ad_get.opcoescampo (cab.statusnota,'STATUSNOTA','TGFCAB') As status,
					(Case
							When cab.tipmov = 'C' And top.atualfin = -1
								 Then Sum (ite.vlrtot - ite.vlrdesc)
							Else 0
					 End
					) As vlrnota,
					(Case
							When cab.tipmov = 'O' And top.atualfin = -1
								 Then Sum (ite.vlrtot - ite.vlrdesc)
							Else 0
					 End
					) As vlrpedido,
					(Case
							When cab.tipmov = 'O' And top.atualfin = -1
								 Then Sum (ite.vlrtot - ite.vlrdesc)
							When cab.tipmov = 'C' And top.atualfin = -1
								 Then Sum (ite.vlrtot - ite.vlrdesc) * (-1)
							Else 0
					 End
					) As valor,
					ad_get.sitpedido (cab.nunota) As situacao,
					Sum (ite.vlrtot - ite.vlrdesc) As vlrtotal, top.atualfin
		 From tgfcab cab 
		  Join tgfite ite On cab.nunota = ite.nunota
			Join tgftop top On cab.codtipoper = top.codtipoper And cab.dhtipoper = top.dhalter
		Where cab.numcontrato > 0
			And Not Exists (
						 Select 1
							 From tgfcab cao 
							  Join tgfvar Var On cao.nunota = var.nunotaorig
								Join tgfcab cad  On cad.nunota = var.nunota
									And cad.tipmov = cao.tipmov
									And cad.codtipoper = cao.codtipoper
							Where cao.numcontrato = cab.numcontrato
								And cao.nunota = cab.nunota)
 Group By cab.numcontrato,
					cab.tipmov,
					ad_get.opcoescampo (cab.tipmov, 'TIPMOV', 'TGFCAB'),
					cab.nunota,
					cab.numnota,
					cab.dtentsai,
					cab.dtneg,
					ad_get.opcoescampo (cab.statusnota, 'STATUSNOTA', 'TGFCAB'),
					ad_get.sitpedido (cab.nunota),
					top.atualfin
 Order By cab.dtentsai
;
