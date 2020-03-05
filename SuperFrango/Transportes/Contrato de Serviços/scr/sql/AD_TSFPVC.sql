create or replace view ad_tsfpvc 
as
(Select 0 As NUPVC,
 con.numcontrato As NUMCONTRATO,
 stm.codserv As CODSERV ,
 pro.descrprod As DESCRPROD,
 stm.codmaq As CODMAQ,
 maq.descrmaq As DESCRMAQ,
 stm.qtdneg As QTDNEG,
 vol.descrvol As DESCRVOL,
 stm.vlrunit As VLRUNIT,
 stm.vlrtot As VLRTOT
From tcscon con
 Left Join ad_tsfsstm stm On con.numcontrato = stm.numcontrato
 Left Join tgfvol vol On (vol.codvol = stm.codvol)
 Left Join tgfpro pro On (pro.codprod = stm.codserv)
 Left Join ad_tsfcme maq On (maq.codmaq = stm.codmaq)
 Where con.Ambiente Like 'TRANSPORT%');
