-- DRE
Select d.codemp, d.unneg, d.ufparc, d.codprod, d.descrprod,
							Round(
       fc_divide( Sum(d.oa1), sum(qtprod) )
							, 4) vlrind
		From dre d
		Join tgfpro p
				On p.codprod = d.codprod
	Where trunc(d.dtfatur, 'mm') = '01/01/2018'
			And p.codprod = &prod
	Group By d.codemp, d.unneg, d.ufparc, d.codprod, d.descrprod
	Order By codemp, unneg, ufparc;

--New DRE
Select p.codemp, u.codune, u.descrune, p.coduf, f.uf, p.codprod, p.codgrupoprod,
							Round(p.vlrindpad, 4) vlrindpad
		From dre_resindpad p
		Join ad_tsfune u
				On p.codune = u.codune
		Join tgfgru g
				On p.codgrupoprod = g.codgrupoprod
		Join tsiufs f
				On p.coduf = f.coduf
	Where p.codindpad = 23
			And codprod = &prod
			And dtref = '01/01/2018'
	Order By codemp, u.descrune, f.uf;
------------------------------------------------------------------------------------------


Select d.codemp, d.unneg, d.ufparc, d.codprod, d.descrprod, qtprod, d.despoutras, d.vlroutros
 From dre d
Where d.dtfatur Between '01/01/2018' And '31/01/2018'
 And d.codprod = &prod
--	And d.codemp = &codemp
--	And d.unneg = &uneg
--	And d.ufparc = &ufparc
 Order By codemp, unneg, ufparc;
	
	Select d.codemp, d.unneg, d.ufparc, d.codprod, d.descrprod,  sum(st*qtprod)/Sum(qtprod)
 From dre d
Where d.dtfatur Between '01/01/2018' And '31/01/2018'
 And d.codprod = &prod
	And d.codemp = &emp
	And d.unneg = 'MTZ'
	And d.ufparc = 'TO-1'
	Group By d.codemp, d.unneg, d.ufparc, d.codprod, d.descrprod
 Order By codemp, unneg, ufparc;
	
	
	

Select fc_divide(Sum(vlrsubst),Sum(qtdneg)) As st
 From dre_tmpcurdre d
 Where trunc(d.dtneg  ,'mm') = &dat1
	 And d.codprod = &prod
		And d.codemp = &emp
		And d.ad_codune = &une
		And d.uf = 'TO';
		
	Select codemp, codune, d.coduf, fc_divide(Sum(vlrsubst*qtdneg), Sum(d.qtdneg))
 From dre_tmpcabite d
 Where trunc(d.dtneg  ,'mm') = &dat1
	 And d.codprod = &prod
--		And d.codemp = &emp
		And d.codune = &une
		And d.coduf = &coduf
		And d.tipmov = 'V'  
Group By codemp, codune, coduf;
----------------------------------------------------------------------------------------
Select 27 As codindpad, dtref, nunota, sequencia, codemp, Nvl(codune, 0) As codune, coduf,
							codgrupoprod, codprod, qtdneg, vlrunit, vlripi, vlrdesc, vlrfrete, peso,
							Round(((VLRFRETE / PESO) * QTDNEG) / (QTDNEG), 4) As vlrind,
							Round((((VLRFRETE / PESO) * QTDNEG) / (QTDNEG)) * qtdneg, 4) As vlridntot
		From dre_baseindpad_012018
	Where tipmov = 'V'
			And dtref = '01/01/18'
			And codemp = &emp
			And Nvl(codune, 0) = &une
			And codprod = &prod
			And Nvl(coduf, 0) = &coduf;

Select 18 As codindpad, dtref, codemp, Nvl(codune, 0) As codune, codgrupoprod, codprod, coduf,
							qtdneg,
							Round(Round(Case
																						When d.coduf In (14, 7) Then
																							Sum((d.vlrtrx * 0.02 * 0.15) * qtdneg) / Sum(qtdneg)
																						Else
																							Case
																									When codgrupoprod = 3020200 And coduf = 9 Then -- embutidos goias
																									-- ((vlrunit + vlripi + vlrsubst - vlrdesc) * qtdneg) * 0.07 * 0.15
																										Sum((ad_pkg_dre.get_ResIndPad(dtref, 1, codprod, codemp, codune, coduf) * 0.07 * 0.15) *
																														qtdneg) / Sum(qtdneg)
																									Else
																										Sum((ad_pkg_dre.get_ResIndPad(dtref, 3, codprod, codemp, codune, coduf) * 0.15) * qtdneg) /
																										Sum(qtdneg)
																							End
																				End,
																				3),
														4) As vlrindpad
		From DRE_BASEINDPAD_012018 d
	Where tipmov = 'V'
			And dtref = '01/01/18'
			And codemp = 1
			And Nvl(codune, 0) = 4
			And codprod = &prod
			And Nvl(coduf, 0) = 9

	Group By dtref, codemp, codune, codprod, codgrupoprod, coduf;

Select Round(Case
																When d.coduf In (14, 7) Then
																	Sum((d.vlrtrx * 0.02 * 0.15) * qtdneg) / Sum(qtdneg)
																Else
																	Case
																			When codgrupoprod = 3020200 And coduf = 9 Then -- embutidos goias
																			-- ((vlrunit + vlripi + vlrsubst - vlrdesc) * qtdneg) * 0.07 * 0.15
																				Sum((ad_pkg_dre.get_ResIndPad(dtref, 1, codprod, codemp, codune, coduf) * 0.07 * 0.15) *
																								qtdneg) / Sum(qtdneg)
																			Else
																				Sum((ad_pkg_dre.get_ResIndPad(dtref, 3, codprod, codemp, codune, coduf) * 0.15) * qtdneg) /
																				Sum(qtdneg)
																	End
														End,
														4) As vlrindpad
		From DRE_BASEINDPAD_012018 d
	Where tipmov = 'V'
			And dtref = '01/01/18'
			And codemp = 1
			And Nvl(codune, 0) = 4
			And codprod = &prod
			And Nvl(coduf, 0) = 9
	Group By dtref, codemp, codune, codprod, codgrupoprod, coduf;

--New DRE
Select p.codemp, u.codune, u.descrune, p.coduf, f.uf, p.codprod, p.codgrupoprod,
							Round(p.vlrindpad, 4) vlrindpad
		From dre_resindpad p
		Join ad_tsfune u
				On p.codune = u.codune
		Join tgfgru g
				On p.codgrupoprod = g.codgrupoprod
		Join tsiufs f
				On p.coduf = f.coduf
	Where p.codindpad = 23
			And p.codprod = &prod
			And p.codune = &une
			And p.coduf = &coduf
			And p.codemp = &emp
			And dtref = '01/01/2018'
	Order By codemp, u.descrune, f.uf;
