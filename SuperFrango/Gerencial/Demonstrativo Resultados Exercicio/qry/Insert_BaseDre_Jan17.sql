Begin

Insert Into Ad_basedre (CODVEND	,CODEMP	,DTNEG	,DTFATUR,CODPARC	,NUNOTA	,SEQUENCIA	,QTDDEV,CODCENCUS	,DESCRCENCUS	,UFPARC,VLRUNIT	,VLRTOT	,VLRIPI	,VLRSUBST	,VLRDESC	,VLRREPRED	,ALIQICMS	,VLRICMS	,ICMSTRX	,CREDOUTORGEMP	,QTDNEG	,CODPROD	,DESCRPROD	,CODVOL	,VLRDESCTOT	,PESO	,TIPMOV	,vlrtrx	,CODGRUPOPROD	,CODUF,UF	,DESCRUF	,CREDMP1	,CREDMP2	,CREDPISCOFINS, PISORIG, COFINS	,CREDOUTVDA,CREDOUTTRX,ICMSPRESUM,CODUNE)
Select
	Codvend,
	Codemp,
	Dtneg,
	bd.Dtentsai DTFATUR,
	Codparc,
	Nunota,
	Sequencia,
	(Case When Tipmov = 'D' Then Qtdneg Else 0 End) As QTDDEV,
	Codcencus,
	Descrcencus,
	bd.Uf || '-' || To_Char(Case When bd.Codemp > 500 Then bd.Codemp - 500 Else bd.Codemp End) UFPARC,
	Vlrunit,
	Vlrtot,
	Vlripi,
	Vlrsubst,
	Vlrdesc,
	0 VLRREPRED,
	0 ALIQICMS,
	Vlricms,
	0 ICMSTRX,
	bd.Ad_credoutorg CREDOUTORGEMP,
	Qtdneg,
	Codprod,
	Descrprod,
	Codvol,
	Vlrdesctot,
	Peso,
	Tipmov,
	bd.Ad_vlrtrx As vlrtrx,
	Codgrupoprod,
	(
				Select
						Coduf
					From Tsiufs u
					Where u.Uf = bd.Uf) CODUF,
	Uf,
	bd.Descricao DESCRUF,
	Credmp1,
	Credmp2,
	bd.Cred_pis_cofins As CREDPISCOFINS,
	bd.Piscid As PISORIG,
	Cofins,
	0 CREDOUTVDA,
	0 CREDOUTTRX,
	0 ICMSPRESUM,
	(
				Select
						Ad_codune
					From Tsicus c2
					Where bd.Codcencus = c2.Codcencus) As CODUNE
From Basedre_dev bd;

End;
