SELECT MAX(NUCAMPO) FROM TDDCAM WHERE NUCAMPO >= ?
Params:
  1 = 9999990000
-------------------------------------------------------------------------------------------------------
##ID_58## tempo: 55 (ms)
SELECT MAX(ORDEM) FROM TDDCAM WHERE NOMETAB = ?
Params:
  1 = TSICUS
-------------------------------------------------------------------------------------------------------
##ID_59## tempo: 33 (ms)
INSERT INTO TDDCAM ( ADICIONAL,APRESENTACAO,CALCULADO,DESCRCAMPO,EXPRESSAO,MASCARA,NOMECAMPO,NOMETAB,NUCAMPO,ORDEM,PERMITEPADRAO,PERMITEPESQUISA,SISTEMA,TIPCAMPO,TIPOAPRESENTACAO,VISIVELGRIDPESQUISA ) VALUES ( ?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,? )
Params:
  1 = S
  2 = N
  3 = N
  4 = CÃ³d. Un. NegÃ³cio
  5 = null
  6 = null
  7 = AD_CODUNE
  8 = TSICUS
  9 = 9999995631
  10 = 58
  11 = S
  12 = S
  13 = null
  14 = I
  15 = P
  16 = S
-------------------------------------------------------------------------------------------------------
##ID_60## tempo: 24 (ms)
INSERT INTO TDDLIG ( ADICIONAL,ALTERAR,EXCLUIR,EXPRESSAO,INSERIR,NOMELIGACAO,NUINSTDEST,NUINSTORIG,TIPLIGACAO ) VALUES ( ?,?,?,?,?,?,?,?,? )
Params:
  1 = S
  2 = N
  3 = N
  4 = null
  5 = N
  6 = AD_FK_F0E0515AD1DCED1238229
  7 = 9999990660
  8 = 37
  9 = I
-------------------------------------------------------------------------------------------------------
##ID_61## tempo: 2 (ms)
SELECT TDDLIG.ADICIONAL AS adicional,TDDLIG.ALTERAR AS alterar,TDDLIG.EXCLUIR AS excluir,TDDLIG.EXPRESSAO AS expressao,TDDLIG.INSERIR AS inserir,TDDLIG.NOMELIGACAO AS nome,TDDLIG.NUINSTDEST AS numInstanciaDestino,TDDLIG.NUINSTORIG AS numInstanciaOrigem,TDDLIG.TIPLIGACAO AS tipo FROM TDDLIG /*SQL_92_JOINED_TABLES*/  WHERE (TDDLIG.NUINSTORIG = ? AND TDDLIG.NUINSTDEST = ?)
Params:
  1 = 37
  2 = 9999990660
-------------------------------------------------------------------------------------------------------
##ID_62## tempo: 35 (ms)
INSERT INTO TDDLGC ( NUCAMPODEST,NUCAMPOORIG,NUINSTDEST,NUINSTORIG,ORIG_OBRIGATORIA ) VALUES ( ?,?,?,?,? )
Params:
  1 = 9999995626
  2 = 9999995631
  3 = 9999990660
  4 = 37
  5 = S
