--Create Or Replace View AD_VW_CUSTOMP
--As
Select Distinct cpa.numcontrato numcontratocpa,
                cpa.nunota As nunotacpa,
                cpa.codparc,
                cpa.dtentsai,
                cpa.codtipoper,
                ad_get.Nometop(cpa.codtipoper) top,
				icp.codprod,
				icp.qtdneg qtdnegcpa,
                Round((icp.qtdneg / 60)) sacascpa,
                Round(icp.vlrtot / (icp.qtdneg / 60), 2) vlrsaca,
                amz.numcontrato numcontratoamz,
                ict.sequencia nucargto,
                Round(ict.qtde) qtdtransp,
				Round(ict.qtde /60) sacastransp,
                ict.nunota nunotaamz,
				cabamz.dtentsai dttransp,
                ict.umidade,
                rdc.descontar,
				nvl(frt.vlrfreteton,0) vlrfreteton,
				(ict.qtde / 1000) * nvl(frt.vlrfreteton,0) vlrfrete
  From tgfcab cpa
  Join tgfite icp
    On cpa.nunota = icp.nunota
  Left Join ad_tcsamz amz
    On amz.numcontratocpa = cpa.numcontrato
  Join tgfcab cabamz
    On cabamz.numcontrato = amz.numcontrato
  Join ad_itecargto ict
    On ict.nunota = cabamz.nunota
  Left Join tgardc rdc
    On rdc.codtdc = amz.codtdc
   And rdc.vlrobtido = ict.umidade
	Left Join ad_tabfretemp frt
	 On frt.codemp = cpa.codemp
	 And frt.codparc = cpa.codparc
	 And frt.codprod = ict.codprod
 Where cpa.codtipoper In (28, 86, 188) and cpa.Tipmov = 'C' and icp.Qtdneg > 0
   And cpa.dtentsai Between &dataini And &datafin
   And icp.codprod = 10001
 Order By cpa.dtentsai

