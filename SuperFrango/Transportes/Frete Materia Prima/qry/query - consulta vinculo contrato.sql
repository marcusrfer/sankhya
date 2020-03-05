Select c.numcontrato,
							Nvl(c.ad_dtinicio, c.dtcontrato) dtcontrato,
							c.codemp,
							c.codparc,
							ad_get.Nome_Parceiro(c.codparc, 'razaosocial') razaoparc,
							p.codprod,
							p.qtdeprevista,
							(Select Count(*)
										From ad_itecargto i2
									Where i2.codprod = p.codprod
											And i2.codparc = c.codparc
											And i2.dataalt >= Nvl(c.ad_dtinicio, c.dtcontrato)) qtdparc,
							Sum(i.qtde)
		From tcscon c
		Join tcspsc p
				On c.numcontrato = p.numcontrato
		Left Join ad_itecargto i
				On i.nunotaorig = c.numcontrato
	Where c.ativo = 'S'
			And c.ad_objcontrato = 'Insumo'
			And c.codparc != 38
			And p.codprod = 10001
			And p.qtdeprevista > 1
	Group By c.numcontrato, Nvl(c.ad_dtinicio, c.dtcontrato), c.codemp, c.codparc, p.codprod, p.qtdeprevista
	Order By 1;
