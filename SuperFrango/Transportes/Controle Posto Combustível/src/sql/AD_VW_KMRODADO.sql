create materialized view AD_VW_KMRODADO
refresh force on demand
start with to_date('02-03-2017 19:43:00', 'dd-mm-yyyy hh24:mi:ss') next Sysdate + 6/24 
as
(
Select Distinct
	Dtneg,
	cab.Codemp,
	cat.Codcat,
	cat.Categoria,
	cab.Codveiculo,
	cab.Ordemcarga,
	Nvl(r.distancia, Ad_get.Distanciacidade(e.Codcid, p.Codcid) * 2) distancia
From Tgfcab cab
	Inner Join Tgfvei vei On cab.Codveiculo = vei.Codveiculo And Nvl(Ad_controlakm,'N') = 'S'
	Left Join Ad_tsfcat CAT On vei.Ad_codcat = CAT.Codcat
	Inner Join Tgford o On cab.Ordemcarga = o.Ordemcarga And cab.Codemp = o.Codemp And cab.Ordemcarga <> 0
	Left Join Tgfrot r On o.Codrota = r.Codrota
	Inner Join Tgfpar p On cab.Codparc = p.Codparc
	Inner Join Tsiemp e On cab.Codemp = e.Codemp
Where Tipmov In ('V', 'T', 'N', 'C')
 And dtneg >= '01/01/2017'
);
