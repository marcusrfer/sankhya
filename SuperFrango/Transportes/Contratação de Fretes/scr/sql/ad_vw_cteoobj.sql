create or replace view ad_vw_cteoobj as
Select xml_autorizacao,mr.chave_acesso, mr.num_doc_fiscal,
Extractvalue(Xmltype(mr.xml_autorizacao), 'cteProc/CTe/infCte/emit/CNPJ','xmlns="http://www.portalfiscal.inf.br/cte"') cnpj_emitente,
Extractvalue(Xmltype(mr.xml_autorizacao), 'cteProc/CTe/infCte/rem/enderReme/cMun','xmlns="http://www.portalfiscal.inf.br/cte"') codmun_Remetente,
Extractvalue(Xmltype(mr.xml_autorizacao), 'cteProc/CTe/infCte/dest/enderDest/cMun','xmlns="http://www.portalfiscal.inf.br/cte"') codmun_Recebedor,
Extractvalue(Xmltype(mr.xml_autorizacao),'cteProc/CTe/infCte/infCTeNorm/infCarga/vCarga','xmlns="http://www.portalfiscal.inf.br/cte"') vlr_carga,
Extractvalue(xmltype(mr.xml_autorizacao), 'cteProc/CTe/infCte/vPrest/vTPrest','xmlns="http://www.portalfiscal.inf.br/cte"') vlrcte,
Extractvalue(xmltype(mr.xml_autorizacao),'cteProc/CTe/infCte/infCTeNorm/infCarga/infQ[tpMed = ''PESO BASE DE CALCULO'' or tpMed = ''PESO INFORMADO'' or tpMed = ''PESO TAXADO'' or tpMed = ''PESO BRUTO'' or tpMed = ''PESO CUBADO'']/qCarga','xmlns="http://www.portalfiscal.inf.br/cte"')  peso
	From oobj.Me_recebida mr
	Where xml_autorizacao Is Not Null And modelo = 57
 --Where mr.num_doc_fiscal = 329528
;
