SELECT fcfspav0.data_real_descarte as DTDESCARTE,
fcfspav0.hora_pega HORAPEGA,
fcfsend0.cod_granja UNIDADE,
fcfsend0.cod_grupo NUCLEO,
fcfsgal0.cod_galpao AVIARIO,
fcfspav0.idade IDADE,
fcfspav0.cod_sexo SEXO,
fcfspav0.peso PESO,
fcfsloc0.nom_abrev LOCALIDADE,
fcfsgru0.dist_abatedouro KM,
fcfscpe0.nom_pegador PEGA,
fcfsres0.nom_responsavel TECNICO,
fcfspav0.qtd_ajustada QTDPEGA 
FROM DBFC.UFC.fcfscpe0 fcfscpe0,
DBFC.UFC.fcfscri0 fcfscri0,
DBFC.UFC.fcfsend0 fcfsend0,
DBFC.UFC.fcfsgal0 fcfsgal0,
DBFC.UFC.fcfsgra0 fcfsgra0,
DBFC.UFC.fcfsgru0 fcfsgru0,
DBFC.UFC.fcfsloc0 fcfsloc0,
DBFC.UFC.fcfslot0 fcfslot0,
DBFC.UFC.fcfspav0 fcfspav0,
DBFC.UFC.fcfsres0 fcfsres0,
DBFC.UFC.fcfstra0 fcfstra0,
DBFC.UFC.FCFVPesosAbate FCFVPesosAbate 
WHERE fcfsgru0.cod_local = fcfsloc0.cod_local 
AND fcfspav0.equipe_pegador = fcfscpe0.cod_pegador 
AND fcfsend0.nro_lote = fcfspav0.nro_lote 
AND fcfsgra0.cod_granja = fcfsend0.cod_granja 
AND fcfsgra0.cod_local = fcfsend0.cod_local 
AND fcfsgra0.cod_criador_proprietario = fcfscri0.cod_criador 
AND FCFVPesosAbate.nro_lote = fcfsend0.nro_lote 
AND FCFVPesosAbate.cod_granja = fcfsgra0.cod_granja 
AND FCFVPesosAbate.cod_granja = fcfsgru0.cod_granja 
AND FCFVPesosAbate.nro_lote = fcfspav0.nro_lote 
AND fcfsres0.cod_responsavel = fcfsgra0.cod_responsavel 
AND fcfslot0.nro_lote = fcfsend0.nro_lote 
AND fcfslot0.nro_lote = fcfspav0.nro_lote 
AND fcfslot0.nro_lote = FCFVPesosAbate.nro_lote 
AND fcfslot0.cod_criador = fcfscri0.cod_criador 
AND fcfstra0.cod_tratamento = fcfslot0.cod_tratamento 
AND fcfsgal0.cod_granja = fcfsgru0.cod_granja 
AND fcfsgru0.cod_grupo = fcfsgal0.cod_grupo 
AND fcfsgru0.cod_local = fcfsgal0.cod_local 
AND fcfsend0.cod_galpao = fcfsgal0.cod_galpao 
AND ((fcfspav0.data_real_descarte >= '03/03/2020' 
And fcfspav0.data_real_descarte <= '03/03/2020')) 
ORDER BY fcfspav0.hora_pega 




SELECT FCFSEND0.COD_GRANJA + ' AVIARIO ' + FCFSGAL0.COD_GALPAO AS UNIDADE,
        FCFSCRI0.NOM_CRIADOR AS PROPRIETARIO,
        FCFSGRA0.ENDERECO AS PROPRIEDADE,
        FCFSGRA0.MUNICIPIO,
        FCFSLOT0.QTD_AVES_ALOJADAS,
        FCFSGRA0.ESTADO,
        FCFSLIN0.DES_ABREV,
        FCFSLOT0.DAT_INICIAL_ALOJAMENTO, 
        FCFSSEX0.DES_SEXO, 
        FCFSABS0.QTD_AVES AS AVES_FINAL,
        convert(varchar,FCFSABS0.PESO) AS PESO_FINAL,
        convert(varchar,FCFSABS0.PERC_01) AS RISCO,
        convert(varchar,FCFSABS0.PERC_02) AS DERMATOSE,
        convert(varchar,FCFSABS0.PERC_03) AS AEROSACULITE,
        convert(varchar,FCFSABS0.PERC_04) AS CALO,
        convert(varchar,FCFSABS0.PERC_05) AS IRRITACAO,
        FCFSABS0.DATA AS DATA_ABATE,
        FCFSABS0.DATA_PEGA,
        FCFSABS0.HORA_PEGA,
        FCFSABS0.DATA_RACAO,
        FCFSABS0.HORA_RACAO,
        SUBSTRING(FCFSABS0.CAMPO_1, 1, 70) AS OBS_1,
        SUBSTRING(FCFSABS0.CAMPO_1, 71, 70) AS OBS_2,
        SUBSTRING(FCFSABS0.CAMPO_1, 141, 70) AS OBS_3,
        SUBSTRING(FCFSABS0.CAMPO_2, 1, 30) AS OBS_MEDICAMENTO,
        SUBSTRING(FCFSABS0.CAMPO_3, 1, 20) AS OBS_CARENCIA,
        FCFSLOT0.DAT_INICIAL_ALOJAMENTO + FCFSABS0.IDADE + 1 AS SUSPENSAO_MEDICAMENTO,
        FCFSALO0.GTA,
        FCFSALO0.COD_FORNECEDOR, 
        FCFSFOR0.NOM_FORNECEDOR, 
        FCFSGRA0.CGC_CPF_CRIADOR, 
        FCFSLOT0.NRO_LOTE, 
        FCFSEND0.COD_GRANJA, 
        FCFSGAL0.COD_GALPAO AS GALPAO 
        FROM DBFC.UFC.FCFSABS0 FCFSABS0,
        DBFC.UFC.FCFSALO0 FCFSALO0, 
        DBFC.UFC.FCFSCRI0 FCFSCRI0, 
        DBFC.UFC.FCFSEND0 FCFSEND0, 
        DBFC.UFC.FCFSFOR0 FCFSFOR0, 
        DBFC.UFC.FCFSGAL0 FCFSGAL0, 
        DBFC.UFC.FCFSGRA0 FCFSGRA0, 
        DBFC.UFC.FCFSGRU0 FCFSGRU0, 
        DBFC.UFC.FCFSLIN0 FCFSLIN0, 
        DBFC.UFC.FCFSLOT0 FCFSLOT0, 
        DBFC.UFC.FCFSSEX0 FCFSSEX0, 
        DBFC.UFC.FCFVLOTES_NAO_FECHADOS FCFVLOTES_NAO_FECHADOS, 
        DBFC.UFC.FCFVMAIORFORNECEDORLOTE FCFVMAIORFORNECEDORLOTE 
        WHERE FCFSLOT0.NRO_LOTE = FCFSEND0.NRO_LOTE 
        AND FCFSEND0.COD_LOCAL = FCFSGRU0.COD_LOCAL 
        AND FCFSEND0.COD_GRANJA = FCFSGRU0.COD_GRANJA 
        AND FCFSEND0.COD_GRUPO = FCFSGRU0.COD_GRUPO 
        AND FCFSEND0.COD_LOCAL = FCFSGRA0.COD_LOCAL 
        AND FCFSEND0.COD_GRANJA = FCFSGRA0.COD_GRANJA 
        AND FCFSGRA0.COD_CRIADOR_PROPRIETARIO = FCFSCRI0.COD_CRIADOR 
        AND FCFSLOT0.COD_SEXO = FCFSSEX0.COD_SEXO 
        AND FCFSLOT0.COD_LINHAGEM = FCFSLIN0.COD_LINHAGEM 
        AND FCFSLOT0.NRO_LOTE = FCFVMAIORFORNECEDORLOTE.NRO_LOTE 
        AND FCFVMAIORFORNECEDORLOTE.COD_FORNECEDOR = FCFSFOR0.COD_FORNECEDOR 
        AND FCFSABS0.NRO_LOTE = FCFSEND0.NRO_LOTE 
        AND FCFSABS0.NRO_LOTE = FCFSLOT0.NRO_LOTE 
        AND FCFSABS0.NRO_LOTE = FCFVMAIORFORNECEDORLOTE.NRO_LOTE 
        AND FCFVLOTES_NAO_FECHADOS.NRO_LOTE = FCFSABS0.NRO_LOTE 
        AND FCFVLOTES_NAO_FECHADOS.NRO_LOTE = FCFSEND0.NRO_LOTE 
        AND FCFVLOTES_NAO_FECHADOS.NRO_LOTE = FCFSLOT0.NRO_LOTE 
        AND FCFSALO0.NRO_LOTE = FCFSABS0.NRO_LOTE 
        AND FCFSALO0.NRO_LOTE = FCFSEND0.NRO_LOTE 
        AND FCFSALO0.NRO_LOTE = FCFSLOT0.NRO_LOTE 
        AND FCFSALO0.NRO_LOTE = FCFVLOTES_NAO_FECHADOS.NRO_LOTE 
        AND FCFSALO0.NRO_LOTE = FCFVMAIORFORNECEDORLOTE.NRO_LOTE 
        AND FCFSGAL0.COD_GALPAO = FCFSEND0.COD_GALPAO 
        AND FCFSGAL0.COD_GRANJA = FCFSGRA0.COD_GRANJA 
        AND FCFSGAL0.COD_GRANJA = FCFSGRU0.COD_GRANJA 
        AND FCFSGAL0.COD_GRUPO = FCFSEND0.COD_GRUPO 
        AND FCFSGAL0.COD_GRUPO = FCFSGRU0.COD_GRUPO 
        AND FCFSGAL0.COD_LOCAL = FCFSGRU0.COD_LOCAL 