prompt Importing table dre_excecoes...
set feedback off
set define off
insert into dre_excecoes (CODEXC, DESCREXC, TIPOEXC, CODINDPAD, CODEMP, CODUNE, CODGRUPOPROD, CODPROD, CODUF, TIPOVLR, FORMEXC, VLRPERC, DTINCLUSAO, CODUSUINC, ATIVO, DHVIGOR, OBS)
values (35, null, 'R', 2, 5, 3, 3010100, 0, 7, 'F', 'SUM ( ( (VLRTOT + VLRIPI - VLRDESC ) * 0.13 ) + VLRTRX * 0.04 * QTDNEG) / SUM( QTDNEG )', 0, to_date('25-04-2018 08:58:18', 'dd-mm-yyyy hh24:mi:ss'), 0, 'S', to_date('01-01-2018', 'dd-mm-yyyy'), null);

insert into dre_excecoes (CODEXC, DESCREXC, TIPOEXC, CODINDPAD, CODEMP, CODUNE, CODGRUPOPROD, CODPROD, CODUF, TIPOVLR, FORMEXC, VLRPERC, DTINCLUSAO, CODUSUINC, ATIVO, DHVIGOR, OBS)
values (39, null, 'E', 2, 5, 11, 3030200, 0, 7, 'F', 'FC_DIVIDE(SUM( (((VLRUNIT + VLRIPI - VLRDESC) * 0.18) + (VLRTRX * 0.12) * QTDNEG) * QTDNEG ) , SUM(QTDNEG))', 0, to_date('25-04-2018 08:58:18', 'dd-mm-yyyy hh24:mi:ss'), 0, 'S', to_date('01-01-2018', 'dd-mm-yyyy'), null);

insert into dre_excecoes (CODEXC, DESCREXC, TIPOEXC, CODINDPAD, CODEMP, CODUNE, CODGRUPOPROD, CODPROD, CODUF, TIPOVLR, FORMEXC, VLRPERC, DTINCLUSAO, CODUSUINC, ATIVO, DHVIGOR, OBS)
values (42, null, 'E', 2, 14, 5, 3030200, 0, 13, 'F', 'SUM( (((VLRUNIT + VLRIPI - VLRDESC) * 0.02) + (CASE
				WHEN CODGRUPOPROD = 3020300 THEN
				 0
				ELSE
				 (VLRTRX * 0.12)
			END) * QTDNEG
			) * QTDNEG) / SUM(QTDNEG)', 0, to_date('25-04-2018 10:12:30', 'dd-mm-yyyy hh24:mi:ss'), 0, 'S', to_date('01-01-2018', 'dd-mm-yyyy'), null);

insert into dre_excecoes (CODEXC, DESCREXC, TIPOEXC, CODINDPAD, CODEMP, CODUNE, CODGRUPOPROD, CODPROD, CODUF, TIPOVLR, FORMEXC, VLRPERC, DTINCLUSAO, CODUSUINC, ATIVO, DHVIGOR, OBS)
values (43, null, 'R', 2, 14, 5, 3010100, 0, 13, 'F', 'SUM( ( ( (VLRUNIT + VLRIPI - VLRDESC) * 0.02) + (VLRTRX * 0.04) * QTDNEG) * QTDNEG ) / SUM(QTDNEG)', 0, to_date('25-04-2018 10:12:30', 'dd-mm-yyyy hh24:mi:ss'), 0, 'S', to_date('01-01-2018', 'dd-mm-yyyy'), null);

insert into dre_excecoes (CODEXC, DESCREXC, TIPOEXC, CODINDPAD, CODEMP, CODUNE, CODGRUPOPROD, CODPROD, CODUF, TIPOVLR, FORMEXC, VLRPERC, DTINCLUSAO, CODUSUINC, ATIVO, DHVIGOR, OBS)
values (45, null, 'R', 2, 14, 5, 3030200, 0, 13, 'F', 'SUM( ( ( (VLRUNIT + VLRIPI - VLRDESC) * 0.02) + (VLRTRX * 0.04) * QTDNEG) * QTDNEG ) / SUM(QTDNEG)', 0, to_date('25-04-2018 10:12:30', 'dd-mm-yyyy hh24:mi:ss'), 0, 'S', to_date('01-01-2018', 'dd-mm-yyyy'), null);

insert into dre_excecoes (CODEXC, DESCREXC, TIPOEXC, CODINDPAD, CODEMP, CODUNE, CODGRUPOPROD, CODPROD, CODUF, TIPOVLR, FORMEXC, VLRPERC, DTINCLUSAO, CODUSUINC, ATIVO, DHVIGOR, OBS)
values (48, null, 'R', 3, 5, 3, 3020200, 0, 7, 'F', 'SUM( ROUND((VLRTRX * 0.02 * QTDNEG)+(VLRTRX * 0.12 * QTDNEG)+((VLRUNIT + VLRIPI - VLRDESC) * 0.07),4) * QTDNEG) / SUM(QTDNEG)', 0, to_date('25-04-2018 17:43:44', 'dd-mm-yyyy hh24:mi:ss'), 0, 'S', to_date('01-01-2018', 'dd-mm-yyyy'), null);

insert into dre_excecoes (CODEXC, DESCREXC, TIPOEXC, CODINDPAD, CODEMP, CODUNE, CODGRUPOPROD, CODPROD, CODUF, TIPOVLR, FORMEXC, VLRPERC, DTINCLUSAO, CODUSUINC, ATIVO, DHVIGOR, OBS)
values (49, null, 'R', 3, 5, 11, 3020200, 0, 7, 'F', 'AVG(VLRICMS)', 0, to_date('26-04-2018 08:26:56', 'dd-mm-yyyy hh24:mi:ss'), 0, 'S', to_date('01-01-2018', 'dd-mm-yyyy'), null);

insert into dre_excecoes (CODEXC, DESCREXC, TIPOEXC, CODINDPAD, CODEMP, CODUNE, CODGRUPOPROD, CODPROD, CODUF, TIPOVLR, FORMEXC, VLRPERC, DTINCLUSAO, CODUSUINC, ATIVO, DHVIGOR, OBS)
values (51, null, 'R', 3, 5, 3, 3020300, 0, 7, 'F', 'SUM(
 (NVL(VLRTRX, 0) * 0.02)
 ) / SUM( QTDNEG )', 0, to_date('26-04-2018 10:02:01', 'dd-mm-yyyy hh24:mi:ss'), 0, 'S', to_date('01-01-2018', 'dd-mm-yyyy'), null);

insert into dre_excecoes (CODEXC, DESCREXC, TIPOEXC, CODINDPAD, CODEMP, CODUNE, CODGRUPOPROD, CODPROD, CODUF, TIPOVLR, FORMEXC, VLRPERC, DTINCLUSAO, CODUSUINC, ATIVO, DHVIGOR, OBS)
values (75, null, 'R', 19, 1, 8, 0, 0, 33, 'F', 'FC_DIVIDE(
 AD_PKG_DRE.GET_RESINDGER(DTREF, 52, CODEMP, CODUNE, CODUF) ,
 AD_PKG_DRE.GET_RESINDGER(DTREF, 63, CODEMP, CODUNE, CODUF)
)', 0, to_date('02-05-2018 14:37:00', 'dd-mm-yyyy hh24:mi:ss'), 0, 'S', to_date('01-01-2018', 'dd-mm-yyyy'), null);

insert into dre_excecoes (CODEXC, DESCREXC, TIPOEXC, CODINDPAD, CODEMP, CODUNE, CODGRUPOPROD, CODPROD, CODUF, TIPOVLR, FORMEXC, VLRPERC, DTINCLUSAO, CODUSUINC, ATIVO, DHVIGOR, OBS)
values (28, 'Icms sobre venda Pará Frango', 'R', 2, 7, 6, 3020200, 0, 14, 'F', 'SUM ( VLRICMS + ((VLRTRX * 0.12 + VLRTRX * 0.114)*QTDNEG) * QTDNEG ) / SUM( QTDNEG)', 0, to_date('24-04-2018 13:35:07', 'dd-mm-yyyy hh24:mi:ss'), 0, 'S', to_date('01-01-2018', 'dd-mm-yyyy'), null);

insert into dre_excecoes (CODEXC, DESCREXC, TIPOEXC, CODINDPAD, CODEMP, CODUNE, CODGRUPOPROD, CODPROD, CODUF, TIPOVLR, FORMEXC, VLRPERC, DTINCLUSAO, CODUSUINC, ATIVO, DHVIGOR, OBS)
values (7, 'Icms sobre venda Pará Apresuntado', 'R', 2, 7, 6, 0, 44684, 14, 'F', 'SUM ( VLRICMS + ((VLRTRX * 0.12)*QTDNEG) * QTDNEG ) / SUM( QTDNEG)', 0, to_date('24-04-2018 13:35:07', 'dd-mm-yyyy hh24:mi:ss'), 0, 'S', to_date('01-01-2018', 'dd-mm-yyyy'), null);

insert into dre_excecoes (CODEXC, DESCREXC, TIPOEXC, CODINDPAD, CODEMP, CODUNE, CODGRUPOPROD, CODPROD, CODUF, TIPOVLR, FORMEXC, VLRPERC, DTINCLUSAO, CODUSUINC, ATIVO, DHVIGOR, OBS)
values (13, 'Icms sobre venda Pará Congelados Temperados', 'R', 2, 7, 6, 1020300, 0, 14, 'F', 'SUM ( VLRICMS + ((VLRTRX * 0.12 + VLRTRX * 0.044)*QTDNEG) * QTDNEG ) / SUM( QTDNEG)', 0, to_date('24-04-2018 13:35:07', 'dd-mm-yyyy hh24:mi:ss'), 0, 'S', to_date('01-01-2018', 'dd-mm-yyyy'), null);

insert into dre_excecoes (CODEXC, DESCREXC, TIPOEXC, CODINDPAD, CODEMP, CODUNE, CODGRUPOPROD, CODPROD, CODUF, TIPOVLR, FORMEXC, VLRPERC, DTINCLUSAO, CODUSUINC, ATIVO, DHVIGOR, OBS)
values (1, 'Somente Batata emp 5 Icms Trx', 'R', 6, 5, 0, 3010100, 0, 0, 'F', 'FC_DIVIDE(SUM((VLRTOT + VLRIPI - VLRDESC) * 13/100 + VLRTRX + 4/100 * QTDNEG),SUM(QTDNEG))', 0, to_date('10-07-2017 14:49:28', 'dd-mm-yyyy hh24:mi:ss'), 0, 'S', to_date('01-07-2017', 'dd-mm-yyyy'), null);

insert into dre_excecoes (CODEXC, DESCREXC, TIPOEXC, CODINDPAD, CODEMP, CODUNE, CODGRUPOPROD, CODPROD, CODUF, TIPOVLR, FORMEXC, VLRPERC, DTINCLUSAO, CODUSUINC, ATIVO, DHVIGOR, OBS)
values (27, 'Icms Transf Batata Frita Pará', 'E', 6, 7, 6, 3010100, 0, 14, 'F', 'FC_DIVIDE(SUM(VLRTRX * 12/100 + VLRTRX*0.03459*QTDNEG), SUM(QTDNEG))', 0, to_date('11-07-2017 14:52:49', 'dd-mm-yyyy hh24:mi:ss'), 0, 'S', to_date('01-07-2017', 'dd-mm-yyyy'), null);

insert into dre_excecoes (CODEXC, DESCREXC, TIPOEXC, CODINDPAD, CODEMP, CODUNE, CODGRUPOPROD, CODPROD, CODUF, TIPOVLR, FORMEXC, VLRPERC, DTINCLUSAO, CODUSUINC, ATIVO, DHVIGOR, OBS)
values (29, 'ICMS Transf. Vegetais Congelados', 'E', 6, 7, 6, 3020300, 0, 14, 'F', 'SUM(VLRTRX * 12/100 + VLRTRX*0.03459*QTDNEG)/SUM(QTDNEG)', 0, to_date('11-07-2017 14:53:00', 'dd-mm-yyyy hh24:mi:ss'), 0, 'S', to_date('01-07-2017', 'dd-mm-yyyy'), null);

insert into dre_excecoes (CODEXC, DESCREXC, TIPOEXC, CODINDPAD, CODEMP, CODUNE, CODGRUPOPROD, CODPROD, CODUF, TIPOVLR, FORMEXC, VLRPERC, DTINCLUSAO, CODUSUINC, ATIVO, DHVIGOR, OBS)
values (3, 'Somente Vegetais', 'R', 6, 5, 0, 3020300, 0, 0, 'F', 'FC_DIVIDE(SUM((VLRTOT + VLRIPI - VLRSUBST - VLRDESC) * 0.18 + VLRTRX * 0.12 * QTDNEG),SUM(QTDNEG) )', 0, to_date('11-07-2017 14:52:11', 'dd-mm-yyyy hh24:mi:ss'), 0, 'N', to_date('01-07-2017', 'dd-mm-yyyy'), null);

insert into dre_excecoes (CODEXC, DESCREXC, TIPOEXC, CODINDPAD, CODEMP, CODUNE, CODGRUPOPROD, CODPROD, CODUF, TIPOVLR, FORMEXC, VLRPERC, DTINCLUSAO, CODUSUINC, ATIVO, DHVIGOR, OBS)
values (30, 'Todos menos Vegetais', 'E', 6, 14, 0, 3020300, 0, 0, 'F', 'SUM(VLRUNIT + VLRIPI - VLRSUBST - VLRDESC) * 0.02 + SUM(VLRTRX) * 12/100', 0, to_date('11-07-2017 14:53:59', 'dd-mm-yyyy hh24:mi:ss'), 0, 'S', to_date('01-07-2017', 'dd-mm-yyyy'), null);

insert into dre_excecoes (CODEXC, DESCREXC, TIPOEXC, CODINDPAD, CODEMP, CODUNE, CODGRUPOPROD, CODPROD, CODUF, TIPOVLR, FORMEXC, VLRPERC, DTINCLUSAO, CODUSUINC, ATIVO, DHVIGOR, OBS)
values (2, 'Tudo menos Vegetais', 'E', 6, 5, 0, 3020300, 0, 0, 'F', 'FC_DIVIDE(SUM((VLRTOT + VLRIPI - VLRDESC) * 13/100 + VLRTRX * 12/100),SUM(QTDNEG))', 0, to_date('11-07-2017 14:51:40', 'dd-mm-yyyy hh24:mi:ss'), 0, 'S', to_date('01-07-2017', 'dd-mm-yyyy'), null);

insert into dre_excecoes (CODEXC, DESCREXC, TIPOEXC, CODINDPAD, CODEMP, CODUNE, CODGRUPOPROD, CODPROD, CODUF, TIPOVLR, FORMEXC, VLRPERC, DTINCLUSAO, CODUSUINC, ATIVO, DHVIGOR, OBS)
values (32, 'Todos menos Vegetais', 'R', 6, 14, 0, 3020300, 0, 0, 'F', 'FC_DIVIDE(SUM(VLRUNIT + VLRIPI - VLRSUBST - VLRDESC) * 0.02 * SUM(QTDNEG),SUM(QTDNEG))', 0, to_date('11-07-2017 14:53:27', 'dd-mm-yyyy hh24:mi:ss'), 0, 'N', to_date('01-07-2017', 'dd-mm-yyyy'), null);

insert into dre_excecoes (CODEXC, DESCREXC, TIPOEXC, CODINDPAD, CODEMP, CODUNE, CODGRUPOPROD, CODPROD, CODUF, TIPOVLR, FORMEXC, VLRPERC, DTINCLUSAO, CODUSUINC, ATIVO, DHVIGOR, OBS)
values (26, 'ICMS TRANSF BATATAS', 'R', 6, 7, 6, 3010100, 0, 14, 'F', 'FC_DIVIDE(SUM(VLRTRX * 4/100 * QTDNEG),SUM(QTDNEG))', 0, to_date('11-07-2017 14:52:30', 'dd-mm-yyyy hh24:mi:ss'), 0, 'N', to_date('01-07-2017', 'dd-mm-yyyy'), null);

insert into dre_excecoes (CODEXC, DESCREXC, TIPOEXC, CODINDPAD, CODEMP, CODUNE, CODGRUPOPROD, CODPROD, CODUF, TIPOVLR, FORMEXC, VLRPERC, DTINCLUSAO, CODUSUINC, ATIVO, DHVIGOR, OBS)
values (15, 'Icms sobre venda Pará Cortes Resfriado para Acougue', 'R', 2, 7, 6, 1020500, 0, 14, 'F', 'SUM ( VLRICMS + ((VLRTRX * 0.12 + VLRTRX * 0.044)*QTDNEG) * QTDNEG ) / SUM( QTDNEG)', 0, to_date('24-04-2018 13:35:07', 'dd-mm-yyyy hh24:mi:ss'), 0, 'S', to_date('01-01-2018', 'dd-mm-yyyy'), null);

insert into dre_excecoes (CODEXC, DESCREXC, TIPOEXC, CODINDPAD, CODEMP, CODUNE, CODGRUPOPROD, CODPROD, CODUF, TIPOVLR, FORMEXC, VLRPERC, DTINCLUSAO, CODUSUINC, ATIVO, DHVIGOR, OBS)
values (17, 'Icms sobre venda Pará Frango', 'R', 2, 7, 6, 1020700, 0, 14, 'F', 'SUM ( VLRICMS + ((VLRTRX * 0.12 + VLRTRX * 0.044)*QTDNEG) * QTDNEG ) / SUM( QTDNEG)', 0, to_date('24-04-2018 13:35:07', 'dd-mm-yyyy hh24:mi:ss'), 0, 'S', to_date('01-01-2018', 'dd-mm-yyyy'), null);

insert into dre_excecoes (CODEXC, DESCREXC, TIPOEXC, CODINDPAD, CODEMP, CODUNE, CODGRUPOPROD, CODPROD, CODUF, TIPOVLR, FORMEXC, VLRPERC, DTINCLUSAO, CODUSUINC, ATIVO, DHVIGOR, OBS)
values (18, 'Icms sobre venda Pará Frango', 'R', 2, 7, 6, 1020800, 0, 14, 'F', 'SUM ( VLRICMS + ((VLRTRX * 0.12 + VLRTRX * 0.044)*QTDNEG) * QTDNEG ) / SUM( QTDNEG)', 0, to_date('24-04-2018 13:35:07', 'dd-mm-yyyy hh24:mi:ss'), 0, 'S', to_date('01-01-2018', 'dd-mm-yyyy'), null);

insert into dre_excecoes (CODEXC, DESCREXC, TIPOEXC, CODINDPAD, CODEMP, CODUNE, CODGRUPOPROD, CODPROD, CODUF, TIPOVLR, FORMEXC, VLRPERC, DTINCLUSAO, CODUSUINC, ATIVO, DHVIGOR, OBS)
values (16, 'Icms sobre venda Pará Frango', 'R', 2, 7, 6, 1020600, 0, 14, 'F', 'SUM ( VLRICMS + ((VLRTRX * 0.12 + VLRTRX * 0.044)*QTDNEG) * QTDNEG ) / SUM( QTDNEG)', 0, to_date('24-04-2018 13:35:07', 'dd-mm-yyyy hh24:mi:ss'), 0, 'S', to_date('01-01-2018', 'dd-mm-yyyy'), null);

insert into dre_excecoes (CODEXC, DESCREXC, TIPOEXC, CODINDPAD, CODEMP, CODUNE, CODGRUPOPROD, CODPROD, CODUF, TIPOVLR, FORMEXC, VLRPERC, DTINCLUSAO, CODUSUINC, ATIVO, DHVIGOR, OBS)
values (21, 'Icms sobre venda Pará Frango', 'R', 2, 7, 6, 1030200, 0, 14, 'F', 'SUM ( VLRICMS + ((VLRTRX * 0.12 + VLRTRX * 0.044)*QTDNEG) * QTDNEG ) / SUM( QTDNEG)', 0, to_date('24-04-2018 13:35:07', 'dd-mm-yyyy hh24:mi:ss'), 0, 'S', to_date('01-01-2018', 'dd-mm-yyyy'), null);

insert into dre_excecoes (CODEXC, DESCREXC, TIPOEXC, CODINDPAD, CODEMP, CODUNE, CODGRUPOPROD, CODPROD, CODUF, TIPOVLR, FORMEXC, VLRPERC, DTINCLUSAO, CODUSUINC, ATIVO, DHVIGOR, OBS)
values (8, 'Icms sobre venda Pará Resfriados', 'R', 2, 7, 6, 1010100, 0, 14, 'F', 'SUM ( VLRICMS + ((VLRTRX * 0.12 + VLRTRX * 0.044)*QTDNEG) * QTDNEG ) / SUM( QTDNEG)', 0, to_date('24-04-2018 13:35:07', 'dd-mm-yyyy hh24:mi:ss'), 0, 'S', to_date('01-01-2018', 'dd-mm-yyyy'), null);

insert into dre_excecoes (CODEXC, DESCREXC, TIPOEXC, CODINDPAD, CODEMP, CODUNE, CODGRUPOPROD, CODPROD, CODUF, TIPOVLR, FORMEXC, VLRPERC, DTINCLUSAO, CODUSUINC, ATIVO, DHVIGOR, OBS)
values (9, 'Icms sobre venda Pará Congelados', 'R', 2, 7, 6, 1010200, 0, 14, 'F', 'SUM ( VLRICMS + ((VLRTRX * 0.12 + VLRTRX * 0.044)*QTDNEG) * QTDNEG ) / SUM( QTDNEG)', 0, to_date('24-04-2018 13:35:07', 'dd-mm-yyyy hh24:mi:ss'), 0, 'S', to_date('01-01-2018', 'dd-mm-yyyy'), null);

insert into dre_excecoes (CODEXC, DESCREXC, TIPOEXC, CODINDPAD, CODEMP, CODUNE, CODGRUPOPROD, CODPROD, CODUF, TIPOVLR, FORMEXC, VLRPERC, DTINCLUSAO, CODUSUINC, ATIVO, DHVIGOR, OBS)
values (10, 'Icms sobre venda Pará Congeladas Temperadas', 'R', 2, 7, 6, 1010300, 0, 14, 'F', 'SUM ( VLRICMS + ((VLRTRX * 0.12 + VLRTRX * 0.044)*QTDNEG) * QTDNEG ) / SUM( QTDNEG)', 0, to_date('24-04-2018 13:35:07', 'dd-mm-yyyy hh24:mi:ss'), 0, 'S', to_date('01-01-2018', 'dd-mm-yyyy'), null);

insert into dre_excecoes (CODEXC, DESCREXC, TIPOEXC, CODINDPAD, CODEMP, CODUNE, CODGRUPOPROD, CODPROD, CODUF, TIPOVLR, FORMEXC, VLRPERC, DTINCLUSAO, CODUSUINC, ATIVO, DHVIGOR, OBS)
values (11, 'Icms sobre venda Pará Cortes Resfriados', 'R', 2, 7, 6, 1020100, 0, 14, 'F', 'SUM ( VLRICMS + ((VLRTRX * 0.12 + VLRTRX * 0.044)*QTDNEG) * QTDNEG ) / SUM( QTDNEG)', 0, to_date('24-04-2018 13:35:07', 'dd-mm-yyyy hh24:mi:ss'), 0, 'S', to_date('01-01-2018', 'dd-mm-yyyy'), null);

insert into dre_excecoes (CODEXC, DESCREXC, TIPOEXC, CODINDPAD, CODEMP, CODUNE, CODGRUPOPROD, CODPROD, CODUF, TIPOVLR, FORMEXC, VLRPERC, DTINCLUSAO, CODUSUINC, ATIVO, DHVIGOR, OBS)
values (12, 'Icms sobre venda Pará Cortes Congelados', 'R', 2, 7, 6, 1020200, 0, 14, 'F', 'SUM ( VLRICMS + ((VLRTRX * 0.12 + VLRTRX * 0.044)*QTDNEG) * QTDNEG ) / SUM( QTDNEG)', 0, to_date('24-04-2018 13:35:07', 'dd-mm-yyyy hh24:mi:ss'), 0, 'S', to_date('01-01-2018', 'dd-mm-yyyy'), null);

insert into dre_excecoes (CODEXC, DESCREXC, TIPOEXC, CODINDPAD, CODEMP, CODUNE, CODGRUPOPROD, CODPROD, CODUF, TIPOVLR, FORMEXC, VLRPERC, DTINCLUSAO, CODUSUINC, ATIVO, DHVIGOR, OBS)
values (14, 'Icms sobre venda Pará Cortes Congelados', 'R', 2, 7, 6, 1020400, 0, 14, 'F', 'SUM ( VLRICMS + ((VLRTRX * 0.12 + VLRTRX * 0.044)*QTDNEG) * QTDNEG ) / SUM( QTDNEG)', 0, to_date('24-04-2018 13:35:07', 'dd-mm-yyyy hh24:mi:ss'), 0, 'S', to_date('01-01-2018', 'dd-mm-yyyy'), null);

insert into dre_excecoes (CODEXC, DESCREXC, TIPOEXC, CODINDPAD, CODEMP, CODUNE, CODGRUPOPROD, CODPROD, CODUF, TIPOVLR, FORMEXC, VLRPERC, DTINCLUSAO, CODUSUINC, ATIVO, DHVIGOR, OBS)
values (19, 'Icms sobre venda Pará Frango', 'R', 2, 7, 6, 1020900, 0, 14, 'F', 'SUM( VLRICMS + (NVL(VLRTRX, 0) * 0.12 + NVL(VLRTRX, 0) * 0.044) * QTDNEG ) / SUM( QTDNEG )', 0, to_date('24-04-2018 13:35:07', 'dd-mm-yyyy hh24:mi:ss'), 0, 'S', to_date('01-01-2018', 'dd-mm-yyyy'), null);

insert into dre_excecoes (CODEXC, DESCREXC, TIPOEXC, CODINDPAD, CODEMP, CODUNE, CODGRUPOPROD, CODPROD, CODUF, TIPOVLR, FORMEXC, VLRPERC, DTINCLUSAO, CODUSUINC, ATIVO, DHVIGOR, OBS)
values (20, 'Icms sobre venda Pará Frango', 'R', 2, 7, 6, 1030100, 0, 14, 'F', 'SUM ( VLRICMS + ((VLRTRX * 0.12 + VLRTRX * 0.044)*QTDNEG) * QTDNEG ) / SUM( QTDNEG)', 0, to_date('24-04-2018 13:35:07', 'dd-mm-yyyy hh24:mi:ss'), 0, 'S', to_date('01-01-2018', 'dd-mm-yyyy'), null);

insert into dre_excecoes (CODEXC, DESCREXC, TIPOEXC, CODINDPAD, CODEMP, CODUNE, CODGRUPOPROD, CODPROD, CODUF, TIPOVLR, FORMEXC, VLRPERC, DTINCLUSAO, CODUSUINC, ATIVO, DHVIGOR, OBS)
values (4, 'Icms sobre venda Pará Linguiça', 'R', 2, 7, 6, 0, 44681, 14, 'F', 'SUM ( VLRICMS + ((VLRTRX * 0.12 + VLRTRX * 0.114)*QTDNEG) * QTDNEG ) / SUM( QTDNEG)', 0, to_date('24-04-2018 13:35:07', 'dd-mm-yyyy hh24:mi:ss'), 0, 'S', to_date('01-01-2018', 'dd-mm-yyyy'), null);

insert into dre_excecoes (CODEXC, DESCREXC, TIPOEXC, CODINDPAD, CODEMP, CODUNE, CODGRUPOPROD, CODPROD, CODUF, TIPOVLR, FORMEXC, VLRPERC, DTINCLUSAO, CODUSUINC, ATIVO, DHVIGOR, OBS)
values (22, 'Icms sobre venda Pará Frango', 'R', 2, 7, 6, 1040301, 0, 14, 'F', 'SUM ( VLRICMS + ((VLRTRX * 0.12 + VLRTRX * 0.114)*QTDNEG) * QTDNEG ) / SUM( QTDNEG)', 0, to_date('24-04-2018 13:35:07', 'dd-mm-yyyy hh24:mi:ss'), 0, 'S', to_date('01-01-2018', 'dd-mm-yyyy'), null);

insert into dre_excecoes (CODEXC, DESCREXC, TIPOEXC, CODINDPAD, CODEMP, CODUNE, CODGRUPOPROD, CODPROD, CODUF, TIPOVLR, FORMEXC, VLRPERC, DTINCLUSAO, CODUSUINC, ATIVO, DHVIGOR, OBS)
values (24, 'Icms sobre venda Pará Frango', 'R', 2, 7, 6, 1040500, 0, 14, 'F', 'SUM ( VLRICMS + ((VLRTRX * 0.12 + VLRTRX * 0.114)*QTDNEG) * QTDNEG ) / SUM( QTDNEG)', 0, to_date('24-04-2018 13:35:07', 'dd-mm-yyyy hh24:mi:ss'), 0, 'S', to_date('01-01-2018', 'dd-mm-yyyy'), null);

insert into dre_excecoes (CODEXC, DESCREXC, TIPOEXC, CODINDPAD, CODEMP, CODUNE, CODGRUPOPROD, CODPROD, CODUF, TIPOVLR, FORMEXC, VLRPERC, DTINCLUSAO, CODUSUINC, ATIVO, DHVIGOR, OBS)
values (23, 'Icms sobre venda Pará Frango', 'R', 2, 7, 6, 1040302, 0, 14, 'F', 'SUM ( VLRICMS + ((VLRTRX * 0.12 + VLRTRX * 0.114)*QTDNEG) * QTDNEG ) / SUM( QTDNEG)', 0, to_date('24-04-2018 13:35:07', 'dd-mm-yyyy hh24:mi:ss'), 0, 'S', to_date('01-01-2018', 'dd-mm-yyyy'), null);

insert into dre_excecoes (CODEXC, DESCREXC, TIPOEXC, CODINDPAD, CODEMP, CODUNE, CODGRUPOPROD, CODPROD, CODUF, TIPOVLR, FORMEXC, VLRPERC, DTINCLUSAO, CODUSUINC, ATIVO, DHVIGOR, OBS)
values (25, 'Icms sobre venda Pará Frango', 'R', 2, 7, 6, 1090100, 0, 14, 'F', 'SUM ( VLRICMS + ((VLRTRX * 0.12 + VLRTRX * 0.114)*QTDNEG) * QTDNEG ) / SUM( QTDNEG)', 0, to_date('24-04-2018 13:35:07', 'dd-mm-yyyy hh24:mi:ss'), 0, 'S', to_date('01-01-2018', 'dd-mm-yyyy'), null);

insert into dre_excecoes (CODEXC, DESCREXC, TIPOEXC, CODINDPAD, CODEMP, CODUNE, CODGRUPOPROD, CODPROD, CODUF, TIPOVLR, FORMEXC, VLRPERC, DTINCLUSAO, CODUSUINC, ATIVO, DHVIGOR, OBS)
values (5, 'Icms sobre venda Pará Linguiça', 'R', 2, 7, 6, 0, 44682, 14, 'F', 'SUM ( VLRICMS + ((VLRTRX * 0.12 + VLRTRX * 0.044)*QTDNEG) * QTDNEG ) / SUM( QTDNEG)', 0, to_date('24-04-2018 13:35:07', 'dd-mm-yyyy hh24:mi:ss'), 0, 'S', to_date('01-01-2018', 'dd-mm-yyyy'), null);

insert into dre_excecoes (CODEXC, DESCREXC, TIPOEXC, CODINDPAD, CODEMP, CODUNE, CODGRUPOPROD, CODPROD, CODUF, TIPOVLR, FORMEXC, VLRPERC, DTINCLUSAO, CODUSUINC, ATIVO, DHVIGOR, OBS)
values (6, 'Icms sobre venda Pará Presunto', 'R', 2, 7, 6, 0, 44683, 14, 'F', 'SUM ( VLRICMS + ((VLRTRX * 0.12)*QTDNEG) * QTDNEG ) / SUM( QTDNEG)', 0, to_date('24-04-2018 13:35:07', 'dd-mm-yyyy hh24:mi:ss'), 0, 'S', to_date('01-01-2018', 'dd-mm-yyyy'), null);

insert into dre_excecoes (CODEXC, DESCREXC, TIPOEXC, CODINDPAD, CODEMP, CODUNE, CODGRUPOPROD, CODPROD, CODUF, TIPOVLR, FORMEXC, VLRPERC, DTINCLUSAO, CODUSUINC, ATIVO, DHVIGOR, OBS)
values (34, 'ICMS sobre Venda Pará Batatas Pre-Fritas Cong', 'R', 2, 7, 6, 3030200, 0, 14, 'F', 'SUM ( VLRICMS + ((VLRTRX * 0.04)*QTDNEG) * QTDNEG ) / SUM( QTDNEG)', 0, to_date('24-04-2018 15:12:09', 'dd-mm-yyyy hh24:mi:ss'), 0, 'S', to_date('01-01-2018', 'dd-mm-yyyy'), null);

insert into dre_excecoes (CODEXC, DESCREXC, TIPOEXC, CODINDPAD, CODEMP, CODUNE, CODGRUPOPROD, CODPROD, CODUF, TIPOVLR, FORMEXC, VLRPERC, DTINCLUSAO, CODUSUINC, ATIVO, DHVIGOR, OBS)
values (37, null, 'E', 2, 5, 3, 3030200, 0, 7, 'F', 'FC_DIVIDE(SUM( (((VLRUNIT + VLRIPI - VLRDESC) * 0.18) + (VLRTRX * 0.12) * QTDNEG) * QTDNEG ) , SUM(QTDNEG))', 0, to_date('25-04-2018 08:58:18', 'dd-mm-yyyy hh24:mi:ss'), 0, 'S', to_date('01-01-2018', 'dd-mm-yyyy'), null);

insert into dre_excecoes (CODEXC, DESCREXC, TIPOEXC, CODINDPAD, CODEMP, CODUNE, CODGRUPOPROD, CODPROD, CODUF, TIPOVLR, FORMEXC, VLRPERC, DTINCLUSAO, CODUSUINC, ATIVO, DHVIGOR, OBS)
values (40, null, 'E', 2, 14, 5, 3010100, 0, 13, 'F', 'SUM( (((VLRUNIT + VLRIPI - VLRDESC) * 0.02) + (CASE
				WHEN CODGRUPOPROD = 3020300 THEN
				 0
				ELSE
				 (VLRTRX * 0.12)
			END) * QTDNEG
			) * QTDNEG) / SUM(QTDNEG)', 0, to_date('25-04-2018 10:12:30', 'dd-mm-yyyy hh24:mi:ss'), 0, 'S', to_date('01-01-2018', 'dd-mm-yyyy'), null);

insert into dre_excecoes (CODEXC, DESCREXC, TIPOEXC, CODINDPAD, CODEMP, CODUNE, CODGRUPOPROD, CODPROD, CODUF, TIPOVLR, FORMEXC, VLRPERC, DTINCLUSAO, CODUSUINC, ATIVO, DHVIGOR, OBS)
values (50, null, 'R', 5, 5, 3, 3020300, 0, 7, 'F', '(FC_DIVIDE(SUM(I.VLRUNIT + I.VLRIPI - I.VLRSUBST - I.VLRDESC), SUM(I.QTDNEG)) * 0.05)', 0, to_date('26-04-2018 10:00:34', 'dd-mm-yyyy hh24:mi:ss'), 0, 'S', to_date('01-01-2018', 'dd-mm-yyyy'), null);

insert into dre_excecoes (CODEXC, DESCREXC, TIPOEXC, CODINDPAD, CODEMP, CODUNE, CODGRUPOPROD, CODPROD, CODUF, TIPOVLR, FORMEXC, VLRPERC, DTINCLUSAO, CODUSUINC, ATIVO, DHVIGOR, OBS)
values (59, null, 'E', 27, 1, 1, 1040302, 0, 5, 'F', 'SUM(VLRSUBST * QTDNEG) / SUM(QTDNEG) + NVL( SUM(((VLRSUBST + VLRIPI - VLRDESC + VLRUNIT) * QTDNEG) * 0.1592) / SUM(QTDNEG), 0)', 0, to_date('27-04-2018 11:43:37', 'dd-mm-yyyy hh24:mi:ss'), 0, 'S', to_date('01-01-2018', 'dd-mm-yyyy'), null);

insert into dre_excecoes (CODEXC, DESCREXC, TIPOEXC, CODINDPAD, CODEMP, CODUNE, CODGRUPOPROD, CODPROD, CODUF, TIPOVLR, FORMEXC, VLRPERC, DTINCLUSAO, CODUSUINC, ATIVO, DHVIGOR, OBS)
values (60, null, 'E', 27, 1, 1, 1040500, 0, 5, 'F', 'SUM(VLRSUBST * QTDNEG) / SUM(QTDNEG) + NVL( SUM(((VLRSUBST + VLRIPI - VLRDESC + VLRUNIT) * QTDNEG) * 0.1592) / SUM(QTDNEG), 0)', 0, to_date('27-04-2018 11:43:37', 'dd-mm-yyyy hh24:mi:ss'), 0, 'S', to_date('01-01-2018', 'dd-mm-yyyy'), null);

insert into dre_excecoes (CODEXC, DESCREXC, TIPOEXC, CODINDPAD, CODEMP, CODUNE, CODGRUPOPROD, CODPROD, CODUF, TIPOVLR, FORMEXC, VLRPERC, DTINCLUSAO, CODUSUINC, ATIVO, DHVIGOR, OBS)
values (61, null, 'E', 27, 1, 1, 1040400, 0, 5, 'F', 'SUM(VLRSUBST * QTDNEG) / SUM(QTDNEG) + NVL( SUM(((VLRSUBST + VLRIPI - VLRDESC + VLRUNIT) * QTDNEG) * 0.1592) / SUM(QTDNEG), 0)', 0, to_date('27-04-2018 11:43:37', 'dd-mm-yyyy hh24:mi:ss'), 0, 'S', to_date('01-01-2018', 'dd-mm-yyyy'), null);

insert into dre_excecoes (CODEXC, DESCREXC, TIPOEXC, CODINDPAD, CODEMP, CODUNE, CODGRUPOPROD, CODPROD, CODUF, TIPOVLR, FORMEXC, VLRPERC, DTINCLUSAO, CODUSUINC, ATIVO, DHVIGOR, OBS)
values (62, null, 'R', 20, 1, 0, 0, 0, 14, 'V', '0', 0, to_date('27-04-2018 14:03:27', 'dd-mm-yyyy hh24:mi:ss'), 0, 'S', to_date('01-01-2018', 'dd-mm-yyyy'), null);

insert into dre_excecoes (CODEXC, DESCREXC, TIPOEXC, CODINDPAD, CODEMP, CODUNE, CODGRUPOPROD, CODPROD, CODUF, TIPOVLR, FORMEXC, VLRPERC, DTINCLUSAO, CODUSUINC, ATIVO, DHVIGOR, OBS)
values (63, null, 'R', 20, 1, 8, 0, 0, 0, 'V', null, 0, to_date('27-04-2018 14:03:27', 'dd-mm-yyyy hh24:mi:ss'), 0, 'S', to_date('01-01-2018', 'dd-mm-yyyy'), null);

insert into dre_excecoes (CODEXC, DESCREXC, TIPOEXC, CODINDPAD, CODEMP, CODUNE, CODGRUPOPROD, CODPROD, CODUF, TIPOVLR, FORMEXC, VLRPERC, DTINCLUSAO, CODUSUINC, ATIVO, DHVIGOR, OBS)
values (67, null, 'R', 23, 7, 6, 0, 0, 14, 'F', 'SUM((VLRTRX * 0.02 * 0.15 * QTDNEG) * QTDNEG) / SUM(QTDNEG)', 0, to_date('02-05-2018 09:36:07', 'dd-mm-yyyy hh24:mi:ss'), 0, 'S', to_date('01-01-2018', 'dd-mm-yyyy'), null);

insert into dre_excecoes (CODEXC, DESCREXC, TIPOEXC, CODINDPAD, CODEMP, CODUNE, CODGRUPOPROD, CODPROD, CODUF, TIPOVLR, FORMEXC, VLRPERC, DTINCLUSAO, CODUSUINC, ATIVO, DHVIGOR, OBS)
values (68, null, 'R', 23, 5, 3, 0, 0, 7, 'F', 'SUM((VLRTRX * 0.02 * 0.15 * QTDNEG) * QTDNEG) / SUM(QTDNEG)', 0, to_date('02-05-2018 09:36:07', 'dd-mm-yyyy hh24:mi:ss'), 0, 'S', to_date('01-01-2018', 'dd-mm-yyyy'), null);

insert into dre_excecoes (CODEXC, DESCREXC, TIPOEXC, CODINDPAD, CODEMP, CODUNE, CODGRUPOPROD, CODPROD, CODUF, TIPOVLR, FORMEXC, VLRPERC, DTINCLUSAO, CODUSUINC, ATIVO, DHVIGOR, OBS)
values (74, null, 'R', 26, 5, 11, 0, 0, 7, 'F', '335 * 25 / AD_PKG_DRE.GET_RESINDGER(DTREF,58,CODEMP, CODUNE, CODUF)', 0, to_date('02-05-2018 14:21:17', 'dd-mm-yyyy hh24:mi:ss'), 0, 'S', to_date('01-01-2018', 'dd-mm-yyyy'), null);

insert into dre_excecoes (CODEXC, DESCREXC, TIPOEXC, CODINDPAD, CODEMP, CODUNE, CODGRUPOPROD, CODPROD, CODUF, TIPOVLR, FORMEXC, VLRPERC, DTINCLUSAO, CODUSUINC, ATIVO, DHVIGOR, OBS)
values (38, null, 'R', 2, 5, 3, 3020300, 0, 7, 'F', 'SUM((((VLRUNIT + VLRIPI - VLRSUBST - VLRDESC) * 0.18) * QTDNEG) * QTDNEG) / SUM(QTDNEG)', 0, to_date('25-04-2018 08:58:18', 'dd-mm-yyyy hh24:mi:ss'), 0, 'S', to_date('01-01-2018', 'dd-mm-yyyy'), null);

insert into dre_excecoes (CODEXC, DESCREXC, TIPOEXC, CODINDPAD, CODEMP, CODUNE, CODGRUPOPROD, CODPROD, CODUF, TIPOVLR, FORMEXC, VLRPERC, DTINCLUSAO, CODUSUINC, ATIVO, DHVIGOR, OBS)
values (41, null, 'E', 2, 14, 5, 3030100, 0, 13, 'F', 'SUM( (((VLRUNIT + VLRIPI - VLRDESC) * 0.02) + (CASE
				WHEN CODGRUPOPROD = 3020300 THEN
				 0
				ELSE
				 (VLRTRX * 0.12)
			END) * QTDNEG
			) * QTDNEG) / SUM(QTDNEG)', 0, to_date('25-04-2018 10:12:30', 'dd-mm-yyyy hh24:mi:ss'), 0, 'S', to_date('01-01-2018', 'dd-mm-yyyy'), null);

insert into dre_excecoes (CODEXC, DESCREXC, TIPOEXC, CODINDPAD, CODEMP, CODUNE, CODGRUPOPROD, CODPROD, CODUF, TIPOVLR, FORMEXC, VLRPERC, DTINCLUSAO, CODUSUINC, ATIVO, DHVIGOR, OBS)
values (54, null, 'E', 27, 1, 1, 3010100, 0, 5, 'F', 'SUM(VLRSUBST * QTDNEG) / SUM(QTDNEG) + NVL( SUM(((VLRSUBST + VLRIPI - VLRDESC + VLRUNIT) * QTDNEG) * 0.1592) / SUM(QTDNEG), 0)', 0, to_date('27-04-2018 11:43:37', 'dd-mm-yyyy hh24:mi:ss'), 0, 'S', to_date('01-01-2018', 'dd-mm-yyyy'), null);

insert into dre_excecoes (CODEXC, DESCREXC, TIPOEXC, CODINDPAD, CODEMP, CODUNE, CODGRUPOPROD, CODPROD, CODUF, TIPOVLR, FORMEXC, VLRPERC, DTINCLUSAO, CODUSUINC, ATIVO, DHVIGOR, OBS)
values (55, null, 'E', 27, 1, 1, 3020200, 0, 5, 'F', 'SUM(VLRSUBST * QTDNEG) / SUM(QTDNEG) + NVL( SUM(((VLRSUBST + VLRIPI - VLRDESC + VLRUNIT) * QTDNEG) * 0.1592) / SUM(QTDNEG), 0)', 0, to_date('27-04-2018 11:43:37', 'dd-mm-yyyy hh24:mi:ss'), 0, 'S', to_date('01-01-2018', 'dd-mm-yyyy'), null);

insert into dre_excecoes (CODEXC, DESCREXC, TIPOEXC, CODINDPAD, CODEMP, CODUNE, CODGRUPOPROD, CODPROD, CODUF, TIPOVLR, FORMEXC, VLRPERC, DTINCLUSAO, CODUSUINC, ATIVO, DHVIGOR, OBS)
values (56, null, 'E', 27, 1, 1, 3020300, 0, 5, 'F', 'SUM(VLRSUBST * QTDNEG) / SUM(QTDNEG) + NVL( SUM(((VLRSUBST + VLRIPI - VLRDESC + VLRUNIT) * QTDNEG) * 0.1592) / SUM(QTDNEG), 0)', 0, to_date('27-04-2018 11:43:37', 'dd-mm-yyyy hh24:mi:ss'), 0, 'S', to_date('01-01-2018', 'dd-mm-yyyy'), null);

insert into dre_excecoes (CODEXC, DESCREXC, TIPOEXC, CODINDPAD, CODEMP, CODUNE, CODGRUPOPROD, CODPROD, CODUF, TIPOVLR, FORMEXC, VLRPERC, DTINCLUSAO, CODUSUINC, ATIVO, DHVIGOR, OBS)
values (65, null, 'R', 23, 1, 0, 3020200, 0, 9, 'F', 'SUM(
 (AD_PKG_DRE.GET_RESINDPAD(DTREF, 1, CODPROD, CODEMP, CODUNE, CODUF) * 0.07 * 0.15) * QTDNEG
) / SUM(QTDNEG)', 0, to_date('02-05-2018 09:33:29', 'dd-mm-yyyy hh24:mi:ss'), 0, 'S', to_date('01-01-2018', 'dd-mm-yyyy'), null);

insert into dre_excecoes (CODEXC, DESCREXC, TIPOEXC, CODINDPAD, CODEMP, CODUNE, CODGRUPOPROD, CODPROD, CODUF, TIPOVLR, FORMEXC, VLRPERC, DTINCLUSAO, CODUSUINC, ATIVO, DHVIGOR, OBS)
values (66, null, 'R', 23, 1, 1, 0, 0, 14, 'F', 'SUM((VLRTRX * 0.02 * 0.15 * QTDNEG) * QTDNEG) / SUM(QTDNEG)', 0, to_date('02-05-2018 09:36:07', 'dd-mm-yyyy hh24:mi:ss'), 0, 'N', to_date('01-01-2018', 'dd-mm-yyyy'), '- 02/05/2018 - Desabilitado por Marcus após comparação dos valores');

insert into dre_excecoes (CODEXC, DESCREXC, TIPOEXC, CODINDPAD, CODEMP, CODUNE, CODGRUPOPROD, CODPROD, CODUF, TIPOVLR, FORMEXC, VLRPERC, DTINCLUSAO, CODUSUINC, ATIVO, DHVIGOR, OBS)
values (69, null, 'R', 23, 5, 11, 0, 0, 7, 'F', 'SUM((VLRTRX * 0.02 * 0.15 * QTDNEG) * QTDNEG) / SUM(QTDNEG)', 0, to_date('02-05-2018 09:36:07', 'dd-mm-yyyy hh24:mi:ss'), 0, 'S', to_date('01-01-2018', 'dd-mm-yyyy'), null);

insert into dre_excecoes (CODEXC, DESCREXC, TIPOEXC, CODINDPAD, CODEMP, CODUNE, CODGRUPOPROD, CODPROD, CODUF, TIPOVLR, FORMEXC, VLRPERC, DTINCLUSAO, CODUSUINC, ATIVO, DHVIGOR, OBS)
values (70, null, 'R', 23, 14, 5, 0, 0, 13, 'F', 'SUM((VLRTRX * 0.02 * 0.15 * QTDNEG) * QTDNEG) / SUM(QTDNEG)', 0, to_date('02-05-2018 09:36:07', 'dd-mm-yyyy hh24:mi:ss'), 0, 'S', to_date('01-01-2018', 'dd-mm-yyyy'), null);

insert into dre_excecoes (CODEXC, DESCREXC, TIPOEXC, CODINDPAD, CODEMP, CODUNE, CODGRUPOPROD, CODPROD, CODUF, TIPOVLR, FORMEXC, VLRPERC, DTINCLUSAO, CODUSUINC, ATIVO, DHVIGOR, OBS)
values (73, null, 'R', 26, 5, 3, 0, 0, 7, 'F', '335 * 25 / AD_PKG_DRE.GET_RESINDGER(DTREF,58,CODEMP, CODUNE, CODUF)', 0, to_date('02-05-2018 14:21:17', 'dd-mm-yyyy hh24:mi:ss'), 0, 'S', to_date('01-01-2018', 'dd-mm-yyyy'), null);

insert into dre_excecoes (CODEXC, DESCREXC, TIPOEXC, CODINDPAD, CODEMP, CODUNE, CODGRUPOPROD, CODPROD, CODUF, TIPOVLR, FORMEXC, VLRPERC, DTINCLUSAO, CODUSUINC, ATIVO, DHVIGOR, OBS)
values (36, null, 'R', 2, 5, 3, 3030200, 0, 7, 'F', 'SUM ( ( (VLRTOT + VLRIPI - VLRDESC ) * 0.13 ) + VLRTRX * 0.04 * QTDNEG) / SUM( QTDNEG )', 0, to_date('25-04-2018 08:58:18', 'dd-mm-yyyy hh24:mi:ss'), 0, 'S', to_date('01-01-2018', 'dd-mm-yyyy'), null);

insert into dre_excecoes (CODEXC, DESCREXC, TIPOEXC, CODINDPAD, CODEMP, CODUNE, CODGRUPOPROD, CODPROD, CODUF, TIPOVLR, FORMEXC, VLRPERC, DTINCLUSAO, CODUSUINC, ATIVO, DHVIGOR, OBS)
values (44, null, 'R', 2, 14, 5, 3030100, 0, 13, 'F', 'SUM( ( ( (VLRUNIT + VLRIPI - VLRDESC) * 0.02) + (VLRTRX * 0.04) * QTDNEG) * QTDNEG ) / SUM(QTDNEG)', 0, to_date('25-04-2018 10:12:30', 'dd-mm-yyyy hh24:mi:ss'), 0, 'S', to_date('01-01-2018', 'dd-mm-yyyy'), null);

insert into dre_excecoes (CODEXC, DESCREXC, TIPOEXC, CODINDPAD, CODEMP, CODUNE, CODGRUPOPROD, CODPROD, CODUF, TIPOVLR, FORMEXC, VLRPERC, DTINCLUSAO, CODUSUINC, ATIVO, DHVIGOR, OBS)
values (64, null, 'R', 20, 1, 7, 0, 0, 0, 'V', '0', 0, to_date('27-04-2018 14:03:27', 'dd-mm-yyyy hh24:mi:ss'), 0, 'S', to_date('01-01-2018', 'dd-mm-yyyy'), null);

insert into dre_excecoes (CODEXC, DESCREXC, TIPOEXC, CODINDPAD, CODEMP, CODUNE, CODGRUPOPROD, CODPROD, CODUF, TIPOVLR, FORMEXC, VLRPERC, DTINCLUSAO, CODUSUINC, ATIVO, DHVIGOR, OBS)
values (72, null, 'R', 25, 5, 11, 0, 0, 7, 'F', 'SUM((VLRUNIT + VLRIPI + VLRSUBST - VLRDESC) * 0.05 * QTDNEG / 100) / SUM(QTDNEG)', 0, to_date('02-05-2018 11:30:16', 'dd-mm-yyyy hh24:mi:ss'), 0, 'S', to_date('01-01-2018', 'dd-mm-yyyy'), null);

insert into dre_excecoes (CODEXC, DESCREXC, TIPOEXC, CODINDPAD, CODEMP, CODUNE, CODGRUPOPROD, CODPROD, CODUF, TIPOVLR, FORMEXC, VLRPERC, DTINCLUSAO, CODUSUINC, ATIVO, DHVIGOR, OBS)
values (31, 'ICMS sobre Venda Pará Batatas Pre-Fritas Cong', 'R', 2, 7, 6, 3010100, 0, 14, 'F', 'SUM ( VLRICMS + ((VLRTRX * 0.04)*QTDNEG) * QTDNEG ) / SUM( QTDNEG)', 0, to_date('24-04-2018 15:12:09', 'dd-mm-yyyy hh24:mi:ss'), 0, 'S', to_date('01-01-2018', 'dd-mm-yyyy'), null);

insert into dre_excecoes (CODEXC, DESCREXC, TIPOEXC, CODINDPAD, CODEMP, CODUNE, CODGRUPOPROD, CODPROD, CODUF, TIPOVLR, FORMEXC, VLRPERC, DTINCLUSAO, CODUSUINC, ATIVO, DHVIGOR, OBS)
values (33, 'ICMS sobre Venda Pará Batatas Pre-Fritas Cong', 'R', 2, 7, 6, 3030100, 0, 14, 'F', 'SUM ( VLRICMS + ((VLRTRX * 0.04)*QTDNEG) * QTDNEG ) / SUM( QTDNEG)', 0, to_date('24-04-2018 15:12:09', 'dd-mm-yyyy hh24:mi:ss'), 0, 'S', to_date('01-01-2018', 'dd-mm-yyyy'), null);

insert into dre_excecoes (CODEXC, DESCREXC, TIPOEXC, CODINDPAD, CODEMP, CODUNE, CODGRUPOPROD, CODPROD, CODUF, TIPOVLR, FORMEXC, VLRPERC, DTINCLUSAO, CODUSUINC, ATIVO, DHVIGOR, OBS)
values (52, null, 'R', 4, 5, 3, 3020300, 0, 7, 'F', 'SUM ( (NVL(VLRTRX, 0) * 0.12) ) / SUM(QTDNEG)', 0, to_date('26-04-2018 10:03:39', 'dd-mm-yyyy hh24:mi:ss'), 0, 'S', null, null);

insert into dre_excecoes (CODEXC, DESCREXC, TIPOEXC, CODINDPAD, CODEMP, CODUNE, CODGRUPOPROD, CODPROD, CODUF, TIPOVLR, FORMEXC, VLRPERC, DTINCLUSAO, CODUSUINC, ATIVO, DHVIGOR, OBS)
values (47, null, 'R', 3, 1, 0, 3020200, 0, 0, 'F', 'CASE WHEN CODUF <> 9 THEN
 SUM( (((VLRUNIT + VLRIPI - VLRDESC) * 0.02) * QTDNEG) ) / SUM( QTDNEG )
ELSE
 0
END', 0, to_date('25-04-2018 16:06:10', 'dd-mm-yyyy hh24:mi:ss'), 0, 'S', to_date('01-01-2018', 'dd-mm-yyyy'), null);

insert into dre_excecoes (CODEXC, DESCREXC, TIPOEXC, CODINDPAD, CODEMP, CODUNE, CODGRUPOPROD, CODPROD, CODUF, TIPOVLR, FORMEXC, VLRPERC, DTINCLUSAO, CODUSUINC, ATIVO, DHVIGOR, OBS)
values (53, null, 'R', 10, 1, 0, 1040200, 0, 0, 'F', 'CREDMP2', 0, to_date('26-04-2018 16:36:42', 'dd-mm-yyyy hh24:mi:ss'), 0, 'S', to_date('01-01-2018', 'dd-mm-yyyy'), null);

insert into dre_excecoes (CODEXC, DESCREXC, TIPOEXC, CODINDPAD, CODEMP, CODUNE, CODGRUPOPROD, CODPROD, CODUF, TIPOVLR, FORMEXC, VLRPERC, DTINCLUSAO, CODUSUINC, ATIVO, DHVIGOR, OBS)
values (57, null, 'R', 27, 14, 5, 3020300, 0, 13, 'F', 'SUM(VLRSUBST * QTDNEG) / SUM(QTDNEG) - NVL( SUM(((VLRTOT + VLRIPI - VLRSUBST - VLRDESC) * QTDNEG) * 0.12) / SUM( QTDNEG ),0)', 0, to_date('27-04-2018 11:47:42', 'dd-mm-yyyy hh24:mi:ss'), 0, 'S', to_date('01-01-2018', 'dd-mm-yyyy'), null);

insert into dre_excecoes (CODEXC, DESCREXC, TIPOEXC, CODINDPAD, CODEMP, CODUNE, CODGRUPOPROD, CODPROD, CODUF, TIPOVLR, FORMEXC, VLRPERC, DTINCLUSAO, CODUSUINC, ATIVO, DHVIGOR, OBS)
values (58, null, 'E', 27, 1, 1, 1040301, 0, 5, 'F', 'SUM(VLRSUBST * QTDNEG) / SUM(QTDNEG) + NVL( SUM(((VLRSUBST + VLRIPI - VLRDESC + VLRUNIT) * QTDNEG) * 0.1592) / SUM(QTDNEG), 0)', 0, to_date('27-04-2018 11:43:37', 'dd-mm-yyyy hh24:mi:ss'), 0, 'S', to_date('01-01-2018', 'dd-mm-yyyy'), null);

insert into dre_excecoes (CODEXC, DESCREXC, TIPOEXC, CODINDPAD, CODEMP, CODUNE, CODGRUPOPROD, CODPROD, CODUF, TIPOVLR, FORMEXC, VLRPERC, DTINCLUSAO, CODUSUINC, ATIVO, DHVIGOR, OBS)
values (71, null, 'R', 25, 5, 3, 0, 0, 7, 'F', 'SUM((VLRUNIT + VLRIPI + VLRSUBST - VLRDESC) * 0.05 * QTDNEG / 100) / SUM(QTDNEG)', 0, to_date('02-05-2018 11:30:16', 'dd-mm-yyyy hh24:mi:ss'), 0, 'S', to_date('01-01-2018', 'dd-mm-yyyy'), null);

prompt Done.
