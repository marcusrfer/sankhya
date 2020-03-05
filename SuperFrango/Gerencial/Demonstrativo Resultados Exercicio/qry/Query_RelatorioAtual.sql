SELECT 
NVL((select PAR11.NUMDEC from tsipar par11 where  PAR11.CHAVE='SF_' || TO_CHAR(:DAT1,'YYYYMM') || '_VDMTZ' AND PAR11.CODUSU=0),0)  As "VD1",
NVL((select PAR11.NUMDEC from tsipar par11 where  PAR11.CHAVE='SF_' || TO_CHAR(:DAT1,'YYYYMM') || '_VDGYN' AND PAR11.CODUSU=0),0)  As "VD2",
NVL((select PAR11.NUMDEC from tsipar par11 where  PAR11.CHAVE='SF_' || TO_CHAR(:DAT1,'YYYYMM') || '_VDBSB' AND PAR11.CODUSU=0),0)  As "VD3",
NVL((select PAR11.NUMDEC from tsipar par11 where  PAR11.CHAVE='SF_' || TO_CHAR(:DAT1,'YYYYMM') || '_VDANP' AND PAR11.CODUSU=0),0)  As "VD4",
NVL((select PAR11.NUMDEC from tsipar par11 where  PAR11.CHAVE='SF_' || TO_CHAR(:DAT1,'YYYYMM') || '_VDUDI' AND PAR11.CODUSU=0),0)  As "VD5",
NVL((select PAR11.NUMDEC from tsipar par11 where  PAR11.CHAVE='SF_' || TO_CHAR(:DAT1,'YYYYMM') || '_VD PA' AND PAR11.CODUSU=0),0)  As "VD6",
NVL((select PAR11.NUMDEC from tsipar par11 where  PAR11.CHAVE='SF_' || TO_CHAR(:DAT1,'YYYYMM') || '_VDGRE' AND PAR11.CODUSU=0),0)  As "VD7",
NVL((select PAR11.NUMDEC from tsipar par11 where  PAR11.CHAVE='SF_' || TO_CHAR(:DAT1,'YYYYMM') || '_VDEXT' AND PAR11.CODUSU=0),0)  As "VD8",
-NVL((select PAR11.NUMDEC from tsipar par11 where  PAR11.CHAVE='SF_' || TO_CHAR(:DAT1 ,'YYYYMM') || '_OP'  AND PAR11.CODUSU=0),0) /NVL((select PAR11.NUMDEC from tsipar par11 where  PAR11.CHAVE='SF_' || TO_CHAR(:DAT1 ,'YYYYMM') || '_KG'  AND PAR11.CODUSU=0),01)  As "OP",
CASE WHEN UNNEG='MTZ'THEN CASE WHEN SUM(QTPROD-QTDDEV) = 0 THEN 0 ELSE SUM(VLMED*(QTPROD-QTDDEV))/SUM(QTPROD-QTDDEV) END ELSE 0  END As "VLMED_1",
CASE WHEN UNNEG='GYN'THEN SUM(VLMED*(QTPROD-QTDDEV))/SUM(QTPROD-QTDDEV) ELSE 0 END As "VLMED_2",
CASE WHEN UNNEG='BSB'THEN SUM(VLMED*(QTPROD-QTDDEV))/SUM(QTPROD-QTDDEV) ELSE 0 END As "VLMED_3",
CASE WHEN UNNEG='ANP'THEN SUM(VLMED*(QTPROD-QTDDEV))/SUM(QTPROD-QTDDEV) ELSE 0 END As "VLMED_4",
CASE WHEN UNNEG='UDI'THEN SUM(VLMED*(QTPROD-QTDDEV))/SUM(QTPROD-QTDDEV) ELSE 0 END As "VLMED_5",
CASE WHEN UNNEG='PA'THEN SUM(VLMED*(QTPROD-QTDDEV))/SUM(QTPROD-QTDDEV) ELSE 0 END As "VLMED_6",
CASE WHEN UNNEG='GRE'THEN SUM(VLMED*(QTPROD-QTDDEV))/SUM(QTPROD-QTDDEV) ELSE 0 END As "VLMED_7",
CASE WHEN UNNEG='EXT'THEN SUM(VLMED*(QTPROD-QTDDEV))/SUM(QTPROD-QTDDEV) ELSE 0 END As "VLMED_8",
CASE WHEN UNNEG='ENT' THEN SUM(VLMED*(QTPROD-QTDDEV))/SUM(QTPROD-QTDDEV) ELSE 0 END As "VLMED_9",
CASE WHEN UNNEG='MTZ'THEN SUM(VLRICMSCID*QTPROD)/SUM(QTPROD) ELSE 0 END As "VLR ICMS_1",
CASE WHEN UNNEG='GYN'THEN SUM(VLRICMSCID*QTPROD)/SUM(QTPROD) ELSE 0 END As "VLR ICMS_2",
CASE WHEN UNNEG='BSB'THEN SUM(VLRICMSCID*QTPROD)/SUM(QTPROD) ELSE 0 END As "VLR ICMS_3",
CASE WHEN UNNEG='UDI'THEN SUM(VLRICMSCID*QTPROD)/SUM(QTPROD) ELSE 0 END As "VLR ICMS_5",
CASE WHEN UNNEG='PA'THEN SUM(VLRICMSCID*QTPROD)/SUM(QTPROD) ELSE 0 END As "VLR ICMS_6",
CASE WHEN UNNEG='GRE'THEN SUM(VLRICMSCID*QTPROD)/SUM(QTPROD) ELSE 0 END As "VLR ICMS_7",
CASE WHEN UNNEG='ANP'THEN SUM(VLRICMSCID*QTPROD)/SUM(QTPROD) ELSE 0 END As "VLR ICMS_4",
CASE WHEN UNNEG='MTZ'THEN SUM(CREDOUT*QTPROD)/SUM(QTPROD) ELSE 0 END As "CREDOUT_1",
CASE WHEN UNNEG='GYN'THEN SUM(CREDOUT*QTPROD)/SUM(QTPROD) ELSE 0 END As "CREDOUT_2",
CASE WHEN UNNEG='BSB'THEN SUM(CREDOUT*QTPROD)/SUM(QTPROD) ELSE 0 END As "CREDOUT_3",
CASE WHEN UNNEG='ANP'THEN SUM(CREDOUT*QTPROD)/SUM(QTPROD) ELSE 0 END As "CREDOUT_4",
CASE WHEN UNNEG='UDI'THEN SUM(CREDOUT*QTPROD)/SUM(QTPROD) ELSE 0 END As "CREDOUT_5",
CASE WHEN UFPARC='PA-7' THEN SUM(CREDOUT*QTPROD)/SUM(QTPROD) WHEN UNNEG='PA' THEN SUM(CREDOUT*QTPROD)/SUM(QTPROD) ELSE 0 END As "CREDOUT_6",
CASE WHEN UNNEG='GRE'THEN SUM(CREDOUT*QTPROD)/SUM(QTPROD) ELSE 0 END As "CREDOUT_7",
CASE WHEN UNNEG='MTZ'THEN SUM(ICMS_REC*QTPROD)/SUM(QTPROD) ELSE 0 END As "VLR ICMSREC_1",
CASE WHEN UNNEG='GYN'THEN SUM(ICMS_REC*QTPROD)/SUM(QTPROD) ELSE 0 END As "VLR ICMSREC_2",
CASE WHEN UNNEG='BSB'THEN SUM(ICMS_REC*QTPROD)/SUM(QTPROD) ELSE 0 END As "VLR ICMSREC_3",
CASE WHEN UNNEG='ANP'THEN SUM(ICMS_REC*QTPROD)/SUM(QTPROD) ELSE 0 END As "VLR ICMSREC_4",
CASE WHEN UNNEG='UDI'THEN SUM(ICMS_REC*QTPROD)/SUM(QTPROD) ELSE 0 END As "VLR ICMSREC_5",
CASE WHEN UNNEG='PA'THEN SUM(ICMS_REC*QTPROD)/SUM(QTPROD) ELSE 0 END As "VLR ICMSREC_6",
CASE WHEN UNNEG='GRE'THEN SUM(ICMS_REC*QTPROD)/SUM(QTPROD) ELSE 0 END As "VLR ICMSREC_7",
CASE WHEN UNNEG='MTZ'THEN SUM(PISCID*QTPROD)/SUM(QTPROD) ELSE 0 END As "PIS_1",
CASE WHEN UNNEG='GYN'THEN SUM(PISCID*QTPROD)/SUM(QTPROD) ELSE 0 END As "PIS_2",
CASE WHEN UNNEG='BSB'THEN SUM(PISCID*QTPROD)/SUM(QTPROD) ELSE 0 END As "PIS_3",
CASE WHEN UNNEG='ANP'THEN SUM(PISCID*QTPROD)/SUM(QTPROD) ELSE 0 END As "PIS_4",
CASE WHEN UNNEG='UDI'THEN SUM(PISCID*QTPROD)/SUM(QTPROD) ELSE 0 END As "PIS_5",
CASE WHEN UNNEG='GRE'THEN SUM(PISCID*QTPROD)/SUM(QTPROD) ELSE 0 END As "PIS_7",
CASE WHEN UNNEG='EXT'THEN SUM(PISCID*QTPROD)/SUM(QTPROD) ELSE 0 END As "PIS_8",
CASE WHEN UNNEG='MTZ'THEN SUM(COFINS*QTPROD)/SUM(QTPROD) ELSE 0 END As "COFINS_1",
CASE WHEN UNNEG='MTZ'THEN SUM(FRETE*QTPROD)/SUM(QTPROD) ELSE 0 END As "FRETE_1",
CASE WHEN UNNEG='MTZ'THEN SUM(PIS_COFINS_REC*QTPROD)/SUM(QTPROD) ELSE 0 END As "PIS_COFINS_REC_1",
CASE WHEN UNNEG='GYN'THEN SUM(COFINS*QTPROD)/SUM(QTPROD) ELSE 0 END As "COFINS_2",
CASE WHEN UNNEG='BSB'THEN SUM(COFINS*QTPROD)/SUM(QTPROD) ELSE 0 END As "COFINS_3",
CASE WHEN UNNEG='UDI'THEN SUM(COFINS*QTPROD)/SUM(QTPROD) ELSE 0 END As "COFINS_5",
CASE WHEN UNNEG='PA'THEN SUM(COFINS*QTPROD)/SUM(QTPROD) ELSE 0 END As "COFINS_6",
CASE WHEN UNNEG='GRE'THEN SUM(COFINS*QTPROD)/SUM(QTPROD) ELSE 0 END As "COFINS_7",
CASE WHEN UNNEG='EXT'THEN SUM(COFINS*QTPROD)/SUM(QTPROD) ELSE 0 END As "COFINS_8",
CASE WHEN UNNEG='GYN'THEN SUM(FRETE*QTPROD)/SUM(QTPROD) ELSE 0 END As "FRETE_2",
CASE WHEN UNNEG='ANP'THEN SUM(FRETE*QTPROD)/SUM(QTPROD) ELSE 0 END As "FRETE_4",
CASE WHEN UNNEG='UDI'THEN SUM(FRETE*QTPROD)/SUM(QTPROD) ELSE 0 END As "FRETE_5",
CASE WHEN UNNEG='PA'THEN SUM(FRETE*QTPROD)/SUM(QTPROD) ELSE 0 END As "FRETE_6",
CASE WHEN UNNEG='GRE'THEN SUM(FRETE*QTPROD)/SUM(QTPROD) ELSE 0 END As "FRETE_7",
CASE WHEN UNNEG='EXT'THEN SUM((FRETE+FRETE_MARITIMO)*QTPROD)/SUM(QTPROD) ELSE 0 END As "FRETE_8",
CASE WHEN UNNEG='BSB'THEN SUM(PIS_COFINS_REC*QTPROD)/SUM(QTPROD) ELSE 0 END As "PIS_COFINS_REC_3",
CASE WHEN UNNEG='ANP'THEN SUM(PIS_COFINS_REC*QTPROD)/SUM(QTPROD) ELSE 0 END As "PIS_COFINS_REC_4",
CASE WHEN UNNEG='PA'THEN SUM(PIS_COFINS_REC*QTPROD)/SUM(QTPROD) ELSE 0 END As "PIS_COFINS_REC_6",
CASE WHEN UNNEG='GRE'THEN SUM(PIS_COFINS_REC*QTPROD)/SUM(QTPROD) ELSE 0 END As "PIS_COFINS_REC_7",
CASE WHEN UNNEG='EXT'THEN SUM(PIS_COFINS_REC*QTPROD)/SUM(QTPROD) ELSE 0 END As "PIS_COFINS_REC_8",
CASE WHEN UNNEG='MTZ'THEN SUM(RECLIQ*QTPROD)/SUM(QTPROD) ELSE 0 END As "RECLIQ_1",
CASE WHEN UNNEG='GYN'THEN SUM(RECLIQ*QTPROD)/SUM(QTPROD) ELSE 0 END As "RECLIQ_2",
CASE WHEN UNNEG='BSB'THEN SUM(RECLIQ*QTPROD)/SUM(QTPROD) ELSE 0 END As "RECLIQ_3",
CASE WHEN UNNEG='ANP'THEN SUM(RECLIQ*QTPROD)/SUM(QTPROD) ELSE 0 END As "RECLIQ_4",
CASE WHEN UNNEG='UDI'THEN SUM(RECLIQ*QTPROD)/SUM(QTPROD) ELSE 0 END As "RECLIQ_5",
CASE WHEN UNNEG='PA'THEN SUM(RECLIQ*QTPROD)/SUM(QTPROD) ELSE 0 END As "RECLIQ_6",
CASE WHEN UNNEG='GRE'THEN SUM(RECLIQ*QTPROD)/SUM(QTPROD) ELSE 0 END As "RECLIQ_7",
CASE WHEN UNNEG='EXT'THEN SUM(RECLIQ*QTPROD)/SUM(QTPROD) ELSE 0 END As "RECLIQ_8",
CASE WHEN UNNEG='MTZ'THEN SUM(ST*QTPROD)/SUM(QTPROD) ELSE 0 END As "ST_1",
CASE WHEN UNNEG='GYN'THEN SUM(ST*QTPROD)/SUM(QTPROD) ELSE 0 END As "ST_2",
CASE WHEN UNNEG='BSB'THEN SUM(ST*QTPROD)/SUM(QTPROD) ELSE 0 END As "ST_3",
CASE WHEN UNNEG='ANP'THEN SUM(ST*QTPROD)/SUM(QTPROD) ELSE 0 END As "ST_4",
CASE WHEN UNNEG='UDI'THEN SUM(ST*QTPROD)/SUM(QTPROD) ELSE 0 END As "ST_5",
CASE WHEN UNNEG='PA'THEN SUM(ST*QTPROD)/SUM(QTPROD) ELSE 0 END As "ST_6",
CASE WHEN UNNEG='GRE'THEN SUM(ST*QTPROD)/SUM(QTPROD) ELSE 0 END As "ST_7",
CASE WHEN UNNEG='EXT'THEN SUM(ST*QTPROD)/SUM(QTPROD) ELSE 0 END As "ST_8",
OA1 As "OA_1",
OA2 As "OA_2",
OA3 As "OA_3",
OA4 As "OA_4",
OA5 As "OA_5",
OA6 As "OA_6",
OA8 As "OA_8",
UFEXTENSO As "UFEXTENSO_",
DRE.CODPROD As "CODPROD_",
DRE.DESCRPROD As "DESCRPROD_",
DRE.UN As "UN_",
UNNEG As "UNNEG_",
CASE WHEN UNNEG='MTZ'THEN SUM(COMISS*QTPROD)/SUM(QTPROD) ELSE 0 END As "COMIS_1",
CASE WHEN UNNEG='GYN'THEN SUM(COMISS*QTPROD)/SUM(QTPROD) ELSE 0 END As "COMIS_2",
CASE WHEN UNNEG='BSB'THEN SUM(COMISS*QTPROD)/SUM(QTPROD) ELSE 0 END As "COMIS_3",
CASE WHEN UNNEG='ANP'THEN SUM(COMISS*QTPROD)/SUM(QTPROD) ELSE 0 END As "COMIS_4",
CASE WHEN UNNEG='UDI'THEN SUM(COMISS*QTPROD)/SUM(QTPROD) ELSE 0 END As "COMIS_5",
CASE WHEN UNNEG='PA'THEN SUM(COMISS*QTPROD)/SUM(QTPROD) ELSE 0 END As "COMIS_6",
CASE WHEN UNNEG='GRE'THEN SUM(COMISS*QTPROD)/SUM(QTPROD) ELSE 0 END As "COMIS_7",
CASE WHEN UNNEG='EXT'THEN SUM(COMISS*QTPROD)/SUM(QTPROD) ELSE 0 END As "COMIS_8",
CASE WHEN UNNEG='MTZ'THEN SUM(VLDESC*QTPROD)/SUM(QTPROD) ELSE 0 END As "VLDESC_1",
CASE WHEN UNNEG='GYN'THEN SUM(VLDESC*QTPROD)/SUM(QTPROD) ELSE 0 END As "VLDESC_2",
CASE WHEN UNNEG='BSB'THEN SUM(VLDESC*QTPROD)/SUM(QTPROD) ELSE 0 END As "VLDESC_3",
CASE WHEN UNNEG='UDI'THEN SUM(VLDESC*QTPROD)/SUM(QTPROD) ELSE 0 END As "VLDESC_5",
CASE WHEN UNNEG='PA'THEN SUM(VLDESC*QTPROD)/SUM(QTPROD) ELSE 0 END As "VLDESC_6",
CASE WHEN UNNEG='GRE'THEN SUM(VLDESC*QTPROD)/SUM(QTPROD) ELSE 0 END As "VLDESC_7",
CASE WHEN UNNEG='EXT'THEN SUM(VLDESC*QTPROD)/SUM(QTPROD) ELSE 0 END As "VLDESC_8",
CASE WHEN UNNEG='ANP'THEN SUM(VLDESC*QTPROD)/SUM(QTPROD) ELSE 0 END As "VLDESC_4",
UFPARC As "UFPARC_",
DRE.CODEMP As "CODEMP_",
max(CRED_PIS_COFINS)
 As "CRED_PIS_COFINS_1",
max(CRED_PIS_COFINS) As "CRED_PIS_COFINS_2",
max(CRED_PIS_COFINS) As "CRED_PIS_COFINS_3",
max(CRED_PIS_COFINS) As "CRED_PIS_COFINS_4",
max(CRED_PIS_COFINS) As "CRED_PIS_COFINS_5",
max(CRED_PIS_COFINS) As "CRED_PIS_COFINS_6",
max(CRED_PIS_COFINS) As "CRED_PIS_COFINS_7",
CASE WHEN UNNEG='PA'THEN SUM(PISCID*QTPROD)/SUM(QTPROD) ELSE 0 END As "PIS_6",
CASE WHEN UNNEG='ANP'THEN SUM(COFINS*QTPROD)/SUM(QTPROD) ELSE 0 END As "COFINS_4",
CASE WHEN UNNEG='GYN'THEN SUM(PIS_COFINS_REC*QTPROD)/SUM(QTPROD) ELSE 0 END As "PIS_COFINS_REC_2",
CASE WHEN UNNEG='UDI'THEN SUM(PIS_COFINS_REC*QTPROD)/SUM(QTPROD) ELSE 0 END As "PIS_COFINS_REC_5",
CASE WHEN UNNEG='BSB' THEN CROSSBSB ELSE 0 END As "CROSSBSB_",
CASE WHEN UNNEG='PA' THEN CROSSPA ELSE 0 END As "CROSSPA_",
CASE WHEN UNNEG='BSB'THEN SUM(FRETE*QTPROD)/SUM(QTPROD) ELSE 0 END As "FRETE_3",
CUSGER As "CUSGER_",
OA7 As "OA_7",
0 As "RECFIN",
NVL((select SUM(PAR11.NUMDEC) from tsipar par11 where  PAR11.CHAVE LIKE 'SF_' || TO_CHAR(:DAT1,'YYYYMM') || '_DI%' AND PAR11.CODUSU=0),0)  As "DESPDIR",
NVL((select SUM(PAR11.NUMDEC) from tsipar par11 where  PAR11.CHAVE LIKE 'SF_' || TO_CHAR(:DAT1,'YYYYMM') || '_DE%' AND PAR11.CODUSU=0),0)  As "DESPFIN",
NVL((select SUM(PAR11.NUMDEC) from tsipar par11 where  PAR11.CHAVE LIKE 'SF_' || TO_CHAR(:DAT1,'YYYYMM') || '_OU%' AND PAR11.CODUSU=0),0)  As "DESPOUTRAS",
CASE WHEN UNNEG='MTZ'THEN FC_DIVIDE(SUM(CROSS*CROSSQT),SUM(CROSSQT)) ELSE 0 END As "CROSS_1",
CASE WHEN UNNEG='GYN'THEN FC_DIVIDE(SUM(CROSS*CROSSQT),SUM(CROSSQT)) ELSE 0 END As "CROSS_2",
CASE WHEN UNNEG='BSB'THEN FC_DIVIDE(SUM(CROSS*CROSSQT),SUM(CROSSQT)) ELSE 0 END As "CROSS_3",
CASE WHEN UNNEG='ANP'THEN FC_DIVIDE(SUM(CROSS*CROSSQT),SUM(CROSSQT))  ELSE 0 END As "CROSS_4",
CASE WHEN UNNEG='UDI'THEN FC_DIVIDE(SUM(CROSS*CROSSQT),SUM(CROSSQT)) ELSE 0 END As "CROSS_5",
CASE WHEN UNNEG='PA'THEN FC_DIVIDE(SUM(CROSS*CROSSQT),SUM(CROSSQT)) ELSE 0 END As "CROSS_6",
CASE WHEN UNNEG='GRE'THEN FC_DIVIDE(SUM(CROSS*CROSSQT),SUM(CROSSQT))ELSE 0 END As "CROSS_7",
CASE WHEN UNNEG='EXT'THEN FC_DIVIDE(SUM(CROSS*CROSSQT),SUM(CROSSQT)) ELSE 0 END As "CROSS_8",
PRO.CODGRUPOPROD As "GRUPOPR",
CUSSEMICM As "CUSSEMICM_",
CASE WHEN UNNEG='ENT'THEN SUM(VLRICMSCID*QTPROD)/SUM(QTPROD) ELSE 0 END As "VLR ICMS_9",
CASE WHEN UNNEG='ENT'THEN SUM(CREDOUT*QTPROD)/SUM(QTPROD) ELSE 0 END As "CREDOUT_9",
CASE WHEN UNNEG='ENT'THEN SUM(ICMS_REC*QTPROD)/SUM(QTPROD) ELSE 0 END As "VLR ICMSREC_9",
CASE WHEN UNNEG='ENT'THEN SUM(PISCID*QTPROD)/SUM(QTPROD) ELSE 0 END As "PIS_9",
CASE WHEN UNNEG='ENT'THEN SUM(COFINS*QTPROD)/SUM(QTPROD) ELSE 0 END As "COFINS_9",
CASE WHEN UNNEG='ENT'THEN SUM(FRETE*QTPROD)/SUM(QTPROD) ELSE 0 END As "FRETE_9",
CASE WHEN UNNEG='ENT'THEN SUM(PIS_COFINS_REC*QTPROD)/SUM(QTPROD) ELSE 0 END As "PIS_COFINS_REC_9",
CASE WHEN UNNEG='ENT'THEN SUM(RECLIQ*QTPROD)/SUM(QTPROD) ELSE 0 END As "RECLIQ_9",
CASE WHEN UNNEG='ENT'THEN SUM(ST*QTPROD)/SUM(QTPROD) ELSE 0 END As "ST_9",
OA9 As "OA_9",
CASE WHEN UNNEG='ENT'THEN SUM(COMISS*QTPROD)/SUM(QTPROD) ELSE 0 END As "COMIS_9",
CASE WHEN UNNEG='ENT'THEN SUM(VLDESC*QTPROD)/SUM(QTPROD) ELSE 0 END As "VLDESC_9",
max(CRED_PIS_COFINS)
 As "CRED_PIS_COFINS_9",
CASE WHEN UNNEG='ENT'THEN FC_DIVIDE(SUM(CROSS*CROSSQT),SUM(CROSSQT)) ELSE 0 END As "CROSS_9",
NVL((select PAR11.NUMDEC from tsipar par11 where  PAR11.CHAVE='SF_' || TO_CHAR(:DAT1,'YYYYMM') || '_VDENT' AND PAR11.CODUSU=0),0)  As "VD9",
CASE WHEN UNNEG='MTZ'THEN SUM(PROTEGE*QTPROD)/SUM(QTPROD) ELSE 0 END As "PROTEGE_1",
CASE WHEN UNNEG='GYN'THEN SUM(PROTEGE*QTPROD)/SUM(QTPROD) ELSE 0 END As "PROTEGE_2",
CASE WHEN UNNEG='BSB'THEN SUM(PROTEGE*QTPROD)/SUM(QTPROD) ELSE 0 END As "PROTEGE_3",
CASE WHEN UNNEG='ANP' THEN SUM(PROTEGE*QTPROD)/SUM(QTPROD) ELSE 0 END As "PROTEGE_4",
CASE WHEN UNNEG='UDI' THEN SUM(PROTEGE*QTPROD)/SUM(QTPROD) ELSE 0 END As "PROTEGE_5",
CASE WHEN UNNEG='PA' THEN SUM(PROTEGE*QTPROD)/SUM(QTPROD) ELSE 0 END As "PROTEGE_6",
CASE WHEN UNNEG='GRE' THEN SUM(PROTEGE*QTPROD)/SUM(QTPROD) ELSE 0 END As "PROTEGE_7",
CASE WHEN UNNEG='EXT' THEN SUM(PROTEGE*QTPROD)/SUM(QTPROD) ELSE 0 END As "PROTEGE_8",
CASE WHEN UNNEG='ENT' THEN SUM(PROTEGE*QTPROD)/SUM(QTPROD) ELSE 0 END As "PROTEGE_9" 
FROM DRE
, TGFPRO PRO
WHERE DRE.CODPROD = PRO.CODPROD
 AND (1 = 0
 )
Group by OA1
, OA2
, OA3
, OA4
, OA5
, OA6
, OA8
, UFEXTENSO
, DRE.CODPROD
, DRE.DESCRPROD
, DRE.UN
, UNNEG
, UFPARC
, DRE.CODEMP
, CASE WHEN UNNEG='BSB' THEN CROSSBSB ELSE 0 END
, CASE WHEN UNNEG='PA' THEN CROSSPA ELSE 0 END
, CUSGER
, OA7
, 0
, PRO.CODGRUPOPROD
, CUSSEMICM
, OA9
 ORDER BY "CODPROD_", "UFPARC_", "UNNEG_"
