Select  /* +RULE+ */ Cab.Codvend,
																Case
																		When Cab.Codemp >= 500 Then
																			Cab.Codemp - 500
																		Else
																			Cab.Codemp
																End As Codemp,
																Cab.Dtneg,
																Cab.Dtfatur,
																Cab.Codparc,
																Ite.Nunota,
																Ite.Sequencia,
																Decode(Cab.Tipmov, 'D', Ite.Qtdneg, 0) As Qtddev,
																Trim(Cus.Ad_Sigla) As Unneg,
																Cus.Codcencus,
																Cus.Descrcencus,
																Ufs.Uf || '-' || To_Char(Case
																																											When Cab.Codemp > 500 Then
																																												Cab.Codemp - 500
																																											Else
																																												Cab.Codemp
																																									End) As Ufparc,
																Decode(Cab.Tipmov, 'V', Ite.Qtdneg, 0) As Qtdneg,
																Fc_Divide((Ite.Vlrtot + Ite.Vlripi + Ite.Vlrsubst - Ite.Vlrdesc), (Ite.Qtdneg)) As Vlrmed,
																Ite.Vlrunit,
																Ite.Vlrtot,
																Ite.Vlripi / Qtdneg As Vlripi,
																Ite.Vlrsubst / Qtdneg As Vlrsubst,
																((Fc_Desc(Cab.Codparc, Ite.Codprod) *
																Decode(Cab.Tipmov, 'V', (Ite.Vlrtot + Ite.Vlripi + Ite.Vlrsubst - Ite.Vlrdesc), 0)) *
																Decode(Cab.Tipmov, 'V', 1, -1) / Qtdneg) / 100 As Vlrdesc,
																Ite.Vlrrepred / Ite.Qtdneg As Vlrrepend,
																Round(Ite.Vlricms / Qtdneg, 4) As Vlricms,
																Nvl(Ite.Ad_Icmstrx, 0) / Qtdneg Icmstrx,
																Emp.Ad_Credoutorg Credoutorgemp,
																Ite.Codprod,
																Pro.Descrprod,
																Pro.Codvol,
																Cab.Vlrdesctot,
																Cab.Peso,
																Cab.Tipmov,
																Nvl(Ite.Ad_Vlrtrx, 0) / Qtdneg As Vlrtrx,
																Pro.Codgrupoprod,
																Ufs.Coduf,
																Ufs.Uf,
																Ufs.Descricao Descruf,
																Pro.Credmp1,
																Pro.Credmp2,
																0 As Credpiscofins,
																0 As Pisorig,
																0 As Cofins,
																0 As Credoutvda,
																0 As Credouttrx,
																0 As Icmspresum,
																Cus.Ad_Codune As Codune,
																0 As Vlrmed,
																0 As Cusger,
																0 As Cussemicms,
																0 As Vlrcomissao,
																0 As St,
																((Fc_Divide(Decode(Cab.Tipmov, 'V', Cab.Vlrfrete, 0), Cab.Peso) * Ite.Qtdneg) /
																Ite.Qtdneg) Frete,
																0 As Fretemar,
																0 As Cross,
																0 As Crossqt,
																0 As Crossbsb,
																0 As Crosspa,
																0 As Crosqtdpa,
																0 As Icmsrec,
																0 As Piscofinsrec,
																0 As Recliquida,
																0 As Vlrprotege,
																0 As Vlrprotdf,
																0 As Vricmsorig,
																Par.Codcid,
																Ad_Get.Cidtransbordo(Cab.Ordemcarga) As Cidcross
		From Tgfcab Cab
		Join Tgfite Ite On Cab.Nunota = Ite.Nunota
		Join Tgfpar Par On Cab.Codparc = Par.Codparc
		Join Tgfpro Pro On Ite.Codprod = Pro.Codprod
		Join Tsiemp Emp On Cab.Codemp = Emp.Codemp
		Join Tsicus Cus On Cab.Codcencus = Cus.Codcencus
		Join Tsicid Cid On Par.Codcid = Cid.Codcid
		Join Tsiufs Ufs On Cid.Uf = Ufs.Coduf
		Join Tgftop Top On Cab.Codtipoper = Top.Codtipoper
																	And Cab.Dhtipoper = Top.Dhalter
		Join Tgford Ord On Cab.Ordemcarga = Ord.Ordemcarga
																	And Cab.Codemp = Ord.Codemp
		Join Ad_Centparamtop Prt On Cab.Codtipoper = Prt.Codtipoper
	Where Trunc(Cab.Dtfatur, 'mm') = Trunc(To_Date(&Dataini))
			And (Cab.Ordemcarga Is Not Null Or Cab.Ordemcarga <> 0)
			And Cab.Ordemcarga = 685223
			And Cab.Codemp <> 8;

Select Ordemcargapai From Tgford Where Ordemcarga = 685223;

Select Par.Codcid, Sum(Vlrfrete), Sum(Peso), Fc_Divide(Sum(Vlrfrete), Sum(Peso)) Vlr_Peso
		From Tgfcab Cab
		Join Ad_Centparamtop Prt On Cab.Codtipoper = Prt.Codtipoper
		Join Tgfpar Par On Cab.Codparc = Par.Codparc
	Where Trunc(Cab.Dtfatur, 'mm') = Trunc(To_Date(&Dataini))
			And Cab.Codemp <> 8
			And Cab.Codtipoper In (46, 460)
	Group By Par.Codcid;

Select Codtipoper, c.Codparc, p.Codcid
		From Tgfcab c
		Join Tgfpar p On c.Codparc = p.Codparc
	Where Ordemcarga In (684036, 685223);

Select Codcid From Tgfpar p Where Codparc = 17281;
Select Ad_Get.Ordemcargapai(685223) From Dual;

Select Distinct Codtipoper, Descroper, Tipmov, Grupo From Tgftop Where Codtipoper In (51, 61, 103);

Select * From Vgfcross Where Referencia = Trunc(To_Date(&Dataini));















Select Cab.Codvend,
							Sum(Case
													When Cab.Tipmov = 'D' Then
														Ite.Qtdneg
													Else
														0
											End) As Qtddev,
							Trim(Cus1.Ad_Sigla) As Unneg,
							Cus1.Codcencus,
							Cus1.Descrcencus,
							Ufs.Uf || '-' || To_Char(Case
																																		When Cab.Codemp > 500 Then
																																			Cab.Codemp - 500
																																		Else
																																			Cab.Codemp
																																End) As Ufparc,
							Ite.Codprod As Codprod,
							Pro.Descrprod As Descrprod,
							Pro.Codvol As Un,
							Fc_Divide(Sum(Ite.Vlrtot + Ite.Vlripi + Ite.Vlrsubst - Ite.Vlrdesc), Sum(Ite.Qtdneg)) As Vlmed,
							Fc_Divide(Sum(Ite.Ad_Vlrtrx * Ite.Qtdneg), Sum(Ite.Qtdneg)) As Vlrtrx,
							
							Case
									When Pro.Codgrupoprod = 1040200 Then -- EMBUTIDOS: SALSICHAS
										Pro.Credmp2
									Else
										Fc_Divide((Vlr_Imp(Ite.Nunota, Ite.Sequencia, 'PIS', 'C') +
																				Vlr_Imp(Ite.Nunota, Ite.Sequencia, 'COFINS', 'C')),
																				(Fc_Divide(Sum(Ite.Vlrtot + Ite.Vlripi + Ite.Vlrsubst - Ite.Vlrdesc),
																															Sum(Ite.Qtdneg))) * 100)
							End As Cred_Pis_Cofins, -- NOVO METODO
							
							Vlr_Imp(Ite.Nunota, Ite.Sequencia, 'PIS', 'D') As Piscid,
							Vlr_Imp(Ite.Nunota, Ite.Sequencia, 'COFINS', 'D') As Cofins,
							Ufs.Descricao As Ufextenso,
							
							Fc_Divide(Sum((Case
																							When Cab.Tipmov = 'V' Then
																								Ite.Qtdneg
																							Else
																								0
																					End * (Ite.Vlrunit + Ite.Vlripi /*+ ITE.VLRSUBST */
																						-ite.Vlrdesc)) * 1.5 / 100 * Case
																							When Cab.Codemp = 1 And Ufs.Uf = 'PA' Or Cus1.Ad_Sigla = 'EXT' Or Cus1.Ad_Sigla = 'GRE' Then
																								0
																							Else
																								1
																					End),
																	Sum(Case
																							When Cab.Tipmov = 'V' Then
																								Ite.Qtdneg
																							Else
																								0
																					End)) As Comiss,
							
							Cus1.Ad_Clacus As Clacus,
							
							Fc_Divide(Sum(Fc_Divide(Cab.Vlrfrete, Cab.Peso) * Case
																							When Cab.Tipmov = 'V' Then
																								Ite.Qtdneg
																							Else
																								0
																					End),
																	Sum(Case
																							When Cab.Tipmov = 'V' Then
																								Ite.Qtdneg
																							Else
																								0
																					End)) As Frete,
							
							Fc_Divide(Sum(Fc_Desc(Cab.Codparc, Ite.Codprod) * (Case
																																																												When Cab.Tipmov = 'V' Then
																																																													Ite.Vlrtot + Ite.Vlripi + Ite.Vlrsubst - Ite.Vlrdesc
																																																												Else
																																																													0
																																																										End) * Case
																							When Cab.Tipmov = 'V' Then
																								1
																							Else
																								-1
																					End),
																	Sum(Case
																							When Cab.Tipmov = 'V' Then
																								Ite.Qtdneg
																							Else
																								0
																					End)) / 100 As Vldesc,
							
							Sum(Case
													When Cab.Tipmov = 'V' Then
														Ite.Qtdneg
													Else
														0
											End * Case
													When Cab.Tipmov = 'V' Then
														1
													Else
														-1
											End) As Qtprod,
							Case
									When Cab.Codemp > 500 Then
										Cab.Codemp - 500
									Else
										Cab.Codemp
							End As Codemp,
							
							Cab.Dtfatur - To_Number(To_Char(Cab.Dtfatur, 'DD')) + 1 As Dtfatur,
							
							Cid.Codcid,
							Parpai.Codcid    As Cidcross,
							Cid.Nomecid,
							Cab.Codtipoper,
							Tpo.Grupo,
							Cab.Codparc,
							Cro.Frete,
							Cro.Peso,
							Pro.Codgrupoprod
		From Tgfcab Cab,
							Tgfpar Par,
							Tsicid Cid,
							Tsiufs Ufs,
							Tgfite Ite,
							Tgfpro Pro,
							Tsicus Cus1,
							Tsiemp Emp1
							--, TSIPAR PAR1
						,
							Tgfemp   Emp,
							Tgftop   Tpo,
							Tgford   Ord,
							Tgfcab   Pai,
							Tgfpar   Parpai,
							Gfscross Cro
	Where Cab.Codparc = Par.Codparc
			And Cab.Codemp = Ord.Codemp
			And Cab.Ordemcarga = Ord.Ordemcarga
			And Ord.Ordemcargapai = Pai.Ordemcarga(+)
			And Ord.Codemp = Pai.Codemp(+)
			And Pai.Codparc = Parpai.Codparc(+)
			And Par.Codcid = Cid.Codcid
			And Cab.Statusnota = 'L'
			And Ufs.Coduf = Cid.Uf
			And Cab.Nunota = Ite.Nunota
			And Ite.Codprod = Pro.Codprod
			And Cus1.Codcencus = Cab.Codcencus
			And Emp1.Codemp = Cab.Codemp
						--AND PAR1.CHAVE = 'SF_' || TO_CHAR(&FIM,'YYYYMM') || '_PP'
						--AND PAR1.CODUSU = 0
						--AND ITE.CODPROD = 11348
			And Emp.Codemp = Cab.Codemp
			And Cab.Codcencus = Cus1.Codcencus
			And Cro.Codcid(+) = Parpai.Codcid
			And Cro.Referencia(+) = &Ini
			And Cab.Codtipoper = Tpo.Codtipoper
			And Cab.Dhtipoper = Tpo.Dhalter
			And Cab.Codemp <> 8
			And Cab.Ordemcarga = 685223
			And (Cab.Dtfatur >= &Ini)
			And (Cab.Dtfatur <= &Fim)
			And (Tpo.Grupo In ('Venda', 'Dev. Venda'))
						
						-- ADD BY RODRIGO 20/11/2013 DEVIOD O NOVO PROCESSO DE TRANSBORDO MULT EMPRESAS TOPS 46 E 460
						
			And Cab.Nunota In
							(Case When Nvl(Pai.Codtipoper, 0) = 0 Then Cab.Nunota Else Case When
								Tpo.Grupo In ('Dev. Venda') Then Cab.Nunota Else (Select Distinct v.Nunotaorig
											From Tgfvar v, Tgfcab c
										Where v.Nunota = c.Nunota
												And c.Codtipoper = Pai.Codtipoper
												And c.Ordemcarga = Ord.Ordemcargapai
												And v.Nunotaorig = Cab.Nunota) End End)
	Group By Ufs.Uf || '-' || To_Char(Case
																																					When Cab.Codemp > 500 Then
																																						Cab.Codemp - 500
																																					Else
																																						Cab.Codemp
																																			End),
										Ite.Codprod,
										Ite.Ad_Vlrtrx,
										Cab.Tipmov,
										Ite.Qtdneg,
										Cab.Codemp,
										Cab.Dtneg -- ADD BY RODRIGO
									,
										Cab.Codvend,
										Cus1.Codcencus,
										Pro.Codgrupoprod,
										Cus1.Descrcencus,
										Pro.Descrprod,
										Pro.Codprod,
										Pro.Credmp1,
										Pro.Credmp2,
										Pro.Codvol,
										Ufs.Descricao,
										0,
										Cab.Codparc,
										Cus1.Ad_Clacus,
										Cus1.Ad_Sigla,
	Right(Cus1.Ad_Clacus, 3),Case
		When Cab.Codemp > 500 Then
			Cab.Codemp - 500
		Else
			Cab.Codemp
End,Case
		When Cab.Codemp = 5 Then
			' '
		Else
			'*'
End
--, PAR1.NUMDEC
, Cab.Dtfatur - To_Number(To_Char(Cab.Dtfatur, 'DD')) + 1, Cid.Codcid, Cid.Nomecid, Cab.Codtipoper, Tpo.Grupo, Parpai.Codcid, Cro.Frete, Cro.Peso,(Vlr_Imp(Ite.Nunota, Ite.Sequencia, 'PIS', 'C') + Vlr_Imp(Ite.Nunota, Ite.Sequencia, 'COFINS', 'C')), Vlr_Imp(Ite.Nunota, Ite.Sequencia, 'PIS', 'D'), Vlr_Imp(Ite.Nunota, Ite.Sequencia, 'COFINS', 'D');










----cross docking
SELECT   /*+RULE*/ 1 As tipo,
            par.codcid,  CAB.DTFATUR - TO_NUMBER(TO_CHAR(CAB.DTFATUR,'DD')) + 1 AS referencia,
            sum(vlrfrete), SUM (peso) AS peso, SUM (vlrfrete) / SUM (peso) AS frete
       FROM tgfcab cab, tgfpar par
      WHERE (codtipoper = 46 OR codtipoper = 460)
        AND cab.codparc = par.codparc
        AND cab.dtfatur >= '01/01/2010'
        And Trunc(Cab.Dtfatur, 'mm') = Trunc(To_Date(&Dataini))
   GROUP BY par.codcid, CAB.DTFATUR - TO_NUMBER(TO_CHAR(CAB.DTFATUR,'DD')) + 1
Union All
Select 2, par.codcid, Trunc(Cab.Dtfatur, 'mm'), Sum(Vlrfrete), Sum(Peso), fc_divide(Sum(Vlrfrete),Sum(Peso)) Vlr_Peso
		From Tgfcab Cab
		Join Ad_Centparamtop Prt On Cab.Codtipoper = Prt.Codtipoper
		Join Tgfpar Par On Cab.Codparc = Par.Codparc
	Where Trunc(Cab.Dtfatur, 'mm') = Trunc(To_Date(&Dataini))
			And Cab.Codemp <> 8
   And cab.codtipoper  In (46,460)
Group By par.codcid,Trunc(Cab.Dtfatur, 'mm')
;










