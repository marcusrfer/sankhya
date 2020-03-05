create or replace view ad_vw_carregmp as
(
Select
 cc.codemp As codemp,
 cc.nunota As nunotaped,
 cc.Sequencia,
 cc.statusvei,
 ad_get.opcoescampo(cc.statusvei, 'STATUSVEI', 'AD_CONTCARGTO') descrstatus,
 V.Codveiculo,
 Ad_get.Formataplaca(V.placa) placa,
 v.Codparc codmot,
 mot.Nomeparc motorista,
 ic.codparc codparcprod,
 pai.nomeparc nomeparcprod,
 nce.Codparc codparcarmz,
 PAR.Nomeparc nomeparcarmz,
	cc.codlocal,
	loc.descrlocal descrlocal,
 cc.Datahoralanc,
 cc.Datasaidatrans,
 cc.Datachegadapatio,
 cc.Dataentradadesc,
 cc.Datafimdescarga,
	ic.codprod,
	pro.descrprod,
 Decode(ic.Qtde, 0, V.Pesomax, ic.Qtde) qtdneg,
 nvl(ic.vlrfrete,0) vlrfrete,
 ic.numnota,
 nvl(ic.vlrcte,0) vlrcte,
 ic.nfe_ssa
  From Ad_contcargto cc
  Join Ad_itecargto ic On cc.Sequencia = ic.Sequencia
  Join Tgfpro pro On ic.Codprod = pro.Codprod
  Left Join Tgfpar pai On ic.Codparc = pai.Codparc
  Left Join Tgfvei V On cc.Codveiculo = V.Codveiculo
  Left Join Tgfpar fnd On ic.Codparc = fnd.Codparc
  Left Join Tgfpar mot On V.Codmotorista = mot.Codparc
  Left Join Tsicid C On fnd.Codcid = C.Codcid
  Left Join Tgfcab cab On cc.Nunota = cab.Nunota
  Left Join Tgfnce nce On cab.Nunota = nce.Nunota
  Left Join Tgfpar PAR On nce.Codparc = PAR.Codparc
  Left Join Tsicid cpa On PAR.Codcid = cpa.Codcid
  Left Join Tgfloc loc On cc.Codlocal = loc.Codlocal
 Where cc.status Not In (/*'FECHADO',*/'CANCELADO' ) And cc.nunota Is Not Null And ic.nunota Is Not Null
);
