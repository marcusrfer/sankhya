prompt Importing table dre_cadindpad...
set feedback off
set define off
insert into dre_cadindpad (CODINDPAD, DESCRINDPAD, FORMINDPAD, ATIVO, TOTALIZADOR, OBS)
values (12, '(C) Total Crédito PIS/COFINS', 'VALOR_INDICADOR(8) + VALOR_INDICADOR(9) - VALOR_INDICADOR(10) * VALOR_INDICADOR(1)', 'S', 'S', null);

insert into dre_cadindpad (CODINDPAD, DESCRINDPAD, FORMINDPAD, ATIVO, TOTALIZADOR, OBS)
values (0, null, null, 'N', 'N', null);

insert into dre_cadindpad (CODINDPAD, DESCRINDPAD, FORMINDPAD, ATIVO, TOTALIZADOR, OBS)
values (1, '(A) Preço de Venda', 'FC_DIVIDE(SUM(VLRTOT + VLRIPI + VLRSUBST - VLRDESC), SUM(QTDNEG))', 'S', 'N', '25/04/18 - FC_DIVIDE(SUM(VLRTOT + VLRIPI + VLRSUBST - VLRDESC - VLRREPRED),SUM(QTDNEG-QTDDEV)) - FC_DIVIDE(SUM(FC_DIVIDE(VLRDESCTOT,PESO)*QTDNEG),SUM(QTDNEG-QTDDEV))');

insert into dre_cadindpad (CODINDPAD, DESCRINDPAD, FORMINDPAD, ATIVO, TOTALIZADOR, OBS)
values (2, 'ICMS sobre Venda', 'SUM(VLRICMS*QTDNEG)/SUM(QTDNEG)', 'S', 'N', null);

insert into dre_cadindpad (CODINDPAD, DESCRINDPAD, FORMINDPAD, ATIVO, TOTALIZADOR, OBS)
values (3, 'Crédito Outorgado sobre Venda', 'ROUND(FC_DIVIDE(SUM(VLRUNIT + VLRIPI - VLRDESC) * 0.07 , SUM(QTDNEG)),4)', 'S', 'N', null);

insert into dre_cadindpad (CODINDPAD, DESCRINDPAD, FORMINDPAD, ATIVO, TOTALIZADOR, OBS)
values (4, 'Crédito Outorgado sobre Transf.', 'FC_DIVIDE(SUM(VLRTRX)*SUM(QTDNEG),SUM(QTDNEG))', 'S', 'N', null);

insert into dre_cadindpad (CODINDPAD, DESCRINDPAD, FORMINDPAD, ATIVO, TOTALIZADOR, OBS)
values (5, 'Crédito Presumido', 'FC_DIVIDE(SUM(VLRUNIT) *SUM(QTDNEG),SUM(QTDNEG))* 0.02', 'S', 'N', null);

insert into dre_cadindpad (CODINDPAD, DESCRINDPAD, FORMINDPAD, ATIVO, TOTALIZADOR, OBS)
values (6, 'Icms sobre Transf.', 'FC_DIVIDE(SUM(VLRTRX),SUM(QTDNEG))', 'S', 'N', null);

insert into dre_cadindpad (CODINDPAD, DESCRINDPAD, FORMINDPAD, ATIVO, TOTALIZADOR, OBS)
values (7, '(B) ICMS SOBRE VENDA A REC.', 'VALOR_INDICADOR(2) + VALOR_INDICADOR(3) + VALOR_INDICADOR(4) + VALOR_INDICADOR(5) + VALOR_INDICADOR(6)', 'S', 'S', null);

insert into dre_cadindpad (CODINDPAD, DESCRINDPAD, FORMINDPAD, ATIVO, TOTALIZADOR, OBS)
values (8, 'PIS', 'FC_DIVIDE(SUM( VLR_IMP(NUNOTA, SEQUENCIA, ''PIS'', ''D'') * QTDNEG) , SUM(QTDNEG) )', 'S', 'N', null);

insert into dre_cadindpad (CODINDPAD, DESCRINDPAD, FORMINDPAD, ATIVO, TOTALIZADOR, OBS)
values (9, 'COFINS', 'FC_DIVIDE(SUM( VLR_IMP(NUNOTA, SEQUENCIA, ''COFINS'', ''D'') * QTDNEG) , SUM(QTDNEG) )', 'S', 'N', null);

insert into dre_cadindpad (CODINDPAD, DESCRINDPAD, FORMINDPAD, ATIVO, TOTALIZADOR, OBS)
values (10, 'Crédito PIS/COFINS', 'FC_DIVIDE(SUM(VLR_IMP(NUNOTA, SEQUENCIA, ''PIS'', ''C'') + VLR_IMP(NUNOTA, SEQUENCIA, ''COFINS'', ''C'')),(FC_DIVIDE(SUM(VLRTOT + VLRIPI + VLRSUBST - VLRDESC),SUM(QTDNEG))) * 100)', 'S', 'N', null);

insert into dre_cadindpad (CODINDPAD, DESCRINDPAD, FORMINDPAD, ATIVO, TOTALIZADOR, OBS)
values (11, 'Quantidade Total', 'SUM(QTDNEG)', 'S', 'N', null);

insert into dre_cadindpad (CODINDPAD, DESCRINDPAD, FORMINDPAD, ATIVO, TOTALIZADOR, OBS)
values (13, 'Custos Produção/Aquisição', 'AD_PKG_DRE.GET_VLRCUSTO_DRE(DTREF,CODPROD,CODEMP,''S'')', 'S', 'N', null);

insert into dre_cadindpad (CODINDPAD, DESCRINDPAD, FORMINDPAD, ATIVO, TOTALIZADOR, OBS)
values (14, 'CrossDock', null, 'S', 'N', null);

insert into dre_cadindpad (CODINDPAD, DESCRINDPAD, FORMINDPAD, ATIVO, TOTALIZADOR, OBS)
values (15, 'Overhead Administrativo', 'FC_DIVIDE(SUM(AD_PKG_DRE.GET_RESINDGER(DTREF, 43, CODEMP, CODUNE, CODUF)) * SUM(QTDNEG),SUM(QTDNEG))', 'S', 'N', null);

insert into dre_cadindpad (CODINDPAD, DESCRINDPAD, FORMINDPAD, ATIVO, TOTALIZADOR, OBS)
values (16, 'Overhead Produção', 'FC_DIVIDE(
 AD_PKG_DRE.GET_RESINDGER(DTREF, 45, CODEMP, CODUNE, CODUF) ,SUM(QTDNEG)
)', 'S', 'N', 'ind ger 45 - Apoio - PROD');

insert into dre_cadindpad (CODINDPAD, DESCRINDPAD, FORMINDPAD, ATIVO, TOTALIZADOR, OBS)
values (17, 'Overhead Unid. Negócio', null, 'N', 'N', null);

insert into dre_cadindpad (CODINDPAD, DESCRINDPAD, FORMINDPAD, ATIVO, TOTALIZADOR, OBS)
values (18, 'Frete Terrestre', 'SUM( FC_DIVIDE(VLRFRETE , PESO) * QTDNEG ) / SUM( QTDNEG )', 'S', 'N', null);

insert into dre_cadindpad (CODINDPAD, DESCRINDPAD, FORMINDPAD, ATIVO, TOTALIZADOR, OBS)
values (19, 'Frete Marítmo', 'FC_DIVIDE(AD_PKG_DRE.GET_RESINDGER(DTREF, 52, CODEMP, CODUNE, CODUF) * SUM(QTDNEG) , SUM(QTDNEG))', 'S', 'N', null);

insert into dre_cadindpad (CODINDPAD, DESCRINDPAD, FORMINDPAD, ATIVO, TOTALIZADOR, OBS)
values (20, 'Comissões', 'SUM( ((VLRUNIT + VLRIPI - VLRDESC) * QTDNEG) * (0.015) ) / SUM( QTDNEG )', 'S', 'N', null);

insert into dre_cadindpad (CODINDPAD, DESCRINDPAD, FORMINDPAD, ATIVO, TOTALIZADOR, OBS)
values (21, 'Total Desp. Comerciais', 'VALOR_INDICADOR(18) + VALOR_INDICADOR(19) + VALOR_INDICADOR(20)', 'S', 'S', null);

insert into dre_cadindpad (CODINDPAD, DESCRINDPAD, FORMINDPAD, ATIVO, TOTALIZADOR, OBS)
values (22, 'Resultado Líquido antes Desp. Acessórias', null, 'N', 'S', null);

insert into dre_cadindpad (CODINDPAD, DESCRINDPAD, FORMINDPAD, ATIVO, TOTALIZADOR, OBS)
values (23, 'Protege Goiás Venda', 'SUM(
  (AD_PKG_DRE.GET_RESINDPAD(DTREF, 3, CODPROD, CODEMP, CODUNE, CODUF) * 0.15) * QTDNEG
 ) / SUM(QTDNEG)', 'S', 'N', null);

insert into dre_cadindpad (CODINDPAD, DESCRINDPAD, FORMINDPAD, ATIVO, TOTALIZADOR, OBS)
values (24, 'Protege Goiás Transf.', null, 'N', 'N', null);

insert into dre_cadindpad (CODINDPAD, DESCRINDPAD, FORMINDPAD, ATIVO, TOTALIZADOR, OBS)
values (25, 'Proteção Educ.Trib (DF)', '0', 'S', 'N', null);

insert into dre_cadindpad (CODINDPAD, DESCRINDPAD, FORMINDPAD, ATIVO, TOTALIZADOR, OBS)
values (26, 'Fundo Geração de Emprego (DF)', '0', 'S', 'N', null);

insert into dre_cadindpad (CODINDPAD, DESCRINDPAD, FORMINDPAD, ATIVO, TOTALIZADOR, OBS)
values (27, 'Substituição Tributária', 'SUM(VLRSUBST * QTDNEG) / SUM(QTDNEG) +
SUM(CASE
		WHEN CODUNE = 1 AND CODUF = 5 AND CODGRUPOPROD NOT IN (3010100, 3020200, 3020300) AND CODGRUPOPROD NOT LIKE ''104%'' THEN
			(((VLRSUBST + VLRIPI - VLRDESC + VLRUNIT) * QTDNEG) * 0.1592)
		ELSE
		     0
		END) / SUM(QTDNEG) - 
SUM(CASE
	WHEN CODEMP = 14 AND CODGRUPOPROD IN (3020300) AND VLRSUBST > 0 THEN
		(((VLRTOT + VLRIPI - VLRSUBST - VLRDESC) * QTDNEG) * 0.12)
	ELSE
		0
	END) / SUM(QTDNEG)', 'S', 'N', null);

insert into dre_cadindpad (CODINDPAD, DESCRINDPAD, FORMINDPAD, ATIVO, TOTALIZADOR, OBS)
values (28, 'Antecipação de ICMS', 'FC_DIVIDE(SUM(ABS((VLRUNIT+VLRIPI-VLRDESC-VLRREPRED)-(FC_DIVIDE(VLRDESCTOT,NVL(PESO,0))))), SUM(QTDNEG))', 'S', 'N', null);

insert into dre_cadindpad (CODINDPAD, DESCRINDPAD, FORMINDPAD, ATIVO, TOTALIZADOR, OBS)
values (29, 'Total de Despesas Acessórias', 'VALOR_INDICADOR(23) + VALOR_INDICADOR(24) + VALOR_INDICADOR(25) + VALOR_INDICADOR(26) + VALOR_INDICADOR(27) + VALOR_INDICADOR(28)', 'S', 'S', null);

insert into dre_cadindpad (CODINDPAD, DESCRINDPAD, FORMINDPAD, ATIVO, TOTALIZADOR, OBS)
values (30, 'Resultado Líquido após Desp. Acessórias', null, 'N', 'N', null);

insert into dre_cadindpad (CODINDPAD, DESCRINDPAD, FORMINDPAD, ATIVO, TOTALIZADOR, OBS)
values (31, 'Despesas Financeiras', 'SUM(FC_DIVIDE(AD_PKG_DRE.GET_RESINDGER(DTREF, 30, 1 , 0, 0 ),AD_PKG_DRE.GET_RESINDGER(DTREF, 53, 1, 0, 0)))', 'S', 'N', null);

insert into dre_cadindpad (CODINDPAD, DESCRINDPAD, FORMINDPAD, ATIVO, TOTALIZADOR, OBS)
values (32, 'Receitas Financeiras', 'SUM(FC_DIVIDE(AD_PKG_DRE.GET_RESINDGER(DTREF, 31, 1 , 0, 0 ),AD_PKG_DRE.GET_RESINDGER(DTREF, 53, 1, 0, 0)))', 'S', 'N', null);

insert into dre_cadindpad (CODINDPAD, DESCRINDPAD, FORMINDPAD, ATIVO, TOTALIZADOR, OBS)
values (33, 'Descontos Concedidos', 'SUM(FC_DESC(CODPARC, CODPROD) * ((VLRUNIT + VLRIPI + VLRSUBST - VLRDESC) * QTDNEG)) / SUM(QTDNEG) / 100', 'S', 'N', null);

insert into dre_cadindpad (CODINDPAD, DESCRINDPAD, FORMINDPAD, ATIVO, TOTALIZADOR, OBS)
values (34, 'Total Despesas/Receitas Financeiras', null, 'N', 'N', null);

insert into dre_cadindpad (CODINDPAD, DESCRINDPAD, FORMINDPAD, ATIVO, TOTALIZADOR, OBS)
values (35, 'Despesas com Diretoria', 'SUM(FC_DIVIDE(AD_PKG_DRE.GET_RESINDGER(DTREF, 33, 1 , 0, 0 ),AD_PKG_DRE.GET_RESINDGER(DTREF, 53, 1, 0, 0)))', 'S', 'N', null);

insert into dre_cadindpad (CODINDPAD, DESCRINDPAD, FORMINDPAD, ATIVO, TOTALIZADOR, OBS)
values (36, 'Outras Despesas', null, 'N', 'N', null);

insert into dre_cadindpad (CODINDPAD, DESCRINDPAD, FORMINDPAD, ATIVO, TOTALIZADOR, OBS)
values (37, 'Total de Despesas com Diretoria', null, 'N', 'N', null);

insert into dre_cadindpad (CODINDPAD, DESCRINDPAD, FORMINDPAD, ATIVO, TOTALIZADOR, OBS)
values (38, 'Resultado Líquido Geral', null, 'N', 'N', null);

insert into dre_cadindpad (CODINDPAD, DESCRINDPAD, FORMINDPAD, ATIVO, TOTALIZADOR, OBS)
values (39, 'Margem de Contribuição(%)', null, 'N', 'N', null);

insert into dre_cadindpad (CODINDPAD, DESCRINDPAD, FORMINDPAD, ATIVO, TOTALIZADOR, OBS)
values (40, 'Receita Líquida (A-B-C)', 'VALOR_INDICADOR(1) - VALOR_INDICADOR(7) - VALOR_INDICADOR(12)', 'S', 'S', null);

prompt Done.
