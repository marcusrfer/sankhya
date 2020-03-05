create or replace view ad_vw_fmpctbz as
Select
 fin.nunota,
 cab.codusu /*fin.codusu */ As codusufin,
 usu.nomeusucplt nomeusufin,
 --ad_get.nomeusu($P{Codusu},'completo') nomeusuprmt,
 fin.codemp,
 ad_get.nometop(fin.codtipoper) descroper,
 Fin.Numnota,
 fin.provisao,
 cab.ad_dtconfnota dhmov,
 fin.dtneg,
 Fin.Codparc,
 Par.Razaosocial,
 Fin.Vlrdesdob ,
 Fin.Vlrdesc,
 Fin.Vlrdesdob - Fin.Vlrdesc Vlr_Liquido,
 Fin.Dtvenc
From Tgffin Fin, Tgfpar Par, Tsiusu Usu, Tgfcab Cab
 Where  fin.nunota = cab.nunota
 And Fin.Codparc = Par.Codparc
 And   Fin.Codtipoper In (173,171,404, 503,501,3,284,437)
 And cab.Codusu = Usu.Codusu
 --And fin.dhmov Between $P{Dat1} and $P{Dat2}
 --And Fin.Codusu = Nvl($P{Codusu},Fin.Codusu)
 And Fin.Codparc = Fin.Codparc
And Fin.Recdesp = -1
--And Fin.Provisao ='N'
Order By Fin.Dtvenc, Fin.Codparc
;
