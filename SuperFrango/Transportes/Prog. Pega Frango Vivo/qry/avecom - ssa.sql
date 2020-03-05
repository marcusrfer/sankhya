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