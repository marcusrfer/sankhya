Create Or Replace View AD_VW_EXTVIAGENS
As
Select r.codemp, r.ordemcarga, r.dtinic, r.codparctransp, ad_get.Nome_Parceiro(r.codparctransp, 'completo') nomeparc, r.codveiculo,
			 vei.marcamodelo, ad_get.Formataplaca(r.codveiculo) placa, cat.categoria, par.ad_codregfre codregfre, reg.descrregfre,
			 Min(cab.dtfatur) mindtfatur, Count(cab.nunota) qtdentregas, Sum(cab.peso) peso, r.distrota, Round(r.vlrrota, 2) vlrrota,
			 round(r.vlrrota * 0.95,2) vlrfrete,
			 round(r.vlrrota * 0.05,2) vlrmkt,
			 Sum(cab.vlrnota) vlrnota
	From ad_tsfrocc r
	Join tgfcab cab
		On r.codemp = cab.codemp
	 And r.ordemcarga = cab.ordemcarga
	Join tgfpar par
		On cab.codparc = par.codparc
	Join tgfvei vei
		On r.codveiculo = vei.codveiculo
	Join ad_tsfcat cat
		On vei.ad_codcat = cat.codcat
	Join ad_tsfrfc reg
		On par.ad_codregfre = reg.codregfre
 Where cab.statusnota = 'L' 
   --And r.codveiculo = 13542
	 --And r.dtinic Between &dataini And &datafin
	 And r.ordemcarga > 0
--And r.status = 'C'
  And Exists (Select 1 From ad_centparamemp cpe Where cpe.codemp = cab.codemp And cpe.nupar = 15)
  And Exists (Select 1 From ad_centparammov cpm Where cpm.tipmov = cab.tipmov And cpm.nupar = 15)
  And Exists (Select 1 From ad_centparamtop cpt Where cpt.codtipoper = cab.codtipoper And cpt.nupar = 15)
 Group By r.codemp, r.ordemcarga, r.dtinic, r.codparctransp, ad_get.Nome_Parceiro(r.codparctransp, 'completo'), r.codveiculo,
					vei.marcamodelo, ad_get.Formataplaca(r.codveiculo), cat.categoria, par.ad_codregfre, reg.descrregfre, r.distrota,
					Round(r.vlrrota, 2), round(r.vlrrota * 0.95,2), round(r.vlrrota * 0.05,2)
