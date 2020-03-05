Select i.sequencia,
							c.statusvei,
							c.datasaidatrans,
							i.codprod,
							i.codparc,
							i.numnota,
							i.nunota,
							i.nunotaorig,
							i.qtde
		From ad_itecargto i
		Join ad_contcargto c
				On i.sequencia = c.sequencia
	Where i.codparc = &codparc
			And codprod = 10001
			And c.status <> 'CANCELADO'
			And i.cancelado = 'NÃO';

Select c.numcontrato As contrarmz, n.ad_objcontrato, n.nunota pedcap, c2.numcontrato contcpa
		From tgfcab c
		Join tcscon n
				On c.numcontrato = n.numcontrato
		Left Join tgfcab c2
				On c2.nunota = n.nunota
	Where c.nunota In (&listanunota);

Select * From tcscon Where numcontrato = 6865;

Select numcontrato From tgfcab Where nunota = 30011958;

Select c.numcontrato
		From tcscon c
		Join tcspsc p
				On c.numcontrato = p.numcontrato
	Where c.codparc = &codparc
			And p.codprod = &codprod
			And c.ad_objcontrato = 'Insumo'
			And c.ativo = 'S'
			And c.ad_dtinicio <= &dtcargto;
