Select codemp, codune, codparc, codvend, codcencus, coduf, codprod, Sum(vlrdesc) vlrdesc
		From (Select f.nunota,
															f.dhbaixa,
															f.codemp,
															u.ad_codune As codune,
															c.codparc,
															c.codvend,
															c.codcencus,
															ufs.coduf,
															i.codprod,
															f.vlrdesdob,
															c.vlrnota,
															(i.vlrtot + i.vlrsubst) vlrtot,
															Round(fc_divide(i.vlrtot + i.vlrsubst, c.vlrnota), 4) perc,
															Round(f.vlrdesdob * fc_divide(i.vlrtot + i.vlrsubst, c.vlrnota), 4) vlrdesc
										From tgffin f
										Join tgfcab c
												On f.nunota = c.nunota
										Join tgfite i
												On i.nunota = c.nunota
										Join tsicus u
												On f.codcencus = u.codcencus
										Join tgfncc n
												On n.codcencus = f.codcencus
											And n.codnat = f.codnat
										Join tgfpar p
												On f.codparc = p.codparc
										Join tsicid cid
												On p.codcid = cid.codcid
										Join tsiufs ufs
												On ufs.coduf = cid.uf
										Join tgfmbc m
												On f.nubco = m.nubco
									Where m.codctabcoint In (46, 44, 45, 47, 50, 122, 121, 43, 49, 48, 51, 86, 34)
											And Upper(u.ad_clacus) Like 'COMERCIAL%'
								Union
								Select f.nunota,
															f.dhbaixa,
															f.codemp,
															u.ad_codune codune,
															c.codparc,
															c.codvend,
															c.codcencus,
															ufs.coduf,
															i.codprod,
															f.vlrdesc,
															c.vlrnota,
															(i.vlrtot + i.vlrsubst),
															Round(fc_divide(i.vlrtot + i.vlrsubst, c.vlrnota), 4),
															Round(f.vlrdesc * fc_divide(i.vlrtot + i.vlrsubst, c.vlrnota), 4)
										From tgffin f
					     Join tgfcab c
            On f.nunota = c.nunota
          Join tgfite i
            On i.nunota = c.nunota
          Join tsicus u
            On f.codcencus = u.codcencus
          Join tgfpar p
            On f.codparc = p.codparc
          Join tsicid cid
            On p.codcid = cid.codcid
          Join tsiufs ufs
            On ufs.coduf = cid.uf
         Where f.vlrdesc > 0
           And f.recdesp = 1
           And Upper(u.ad_clacus) Like 'COMERCIAL%'
           And f.origem = 'E')
 Where Trunc(dhbaixa, 'mm') = '01/12/2018'
 Group By codemp, codune, codparc, codvend, codcencus, coduf, codprod;
