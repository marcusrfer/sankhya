Create Or Replace View AD_VW_VOUCHERRAT
As
Select s.nucapsol,
       r.codemp,
       e.razaosocial,
       Nvl(r.codnat, 4051300) codnat,
       n.descrnat,
       Nvl(r.codcencus, s.codcencus) codcencus,
       c.descrcencus,
							r.percentual
  From ad_tsfcapsol s
  Left Join ad_tsfcaprat r On r.nucapsol = s.nucapsol
  Left Join tsiemp e On r.codemp = e.codemp
  Left Join tgfnat n On nvl(r.codnat,4051300) = n.codnat
  Left Join tsicus c On nvl(r.codcencus,s.codcencus) = c.codcencus
