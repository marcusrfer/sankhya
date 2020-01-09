Create or replace Procedure Ad_stp_mkt_updsolicit_sf (
       P_tipoevento Int,
       P_idsessao Varchar2,
       P_codusu Int
) As
       BEFORE_INSERT Int;
       AFTER_INSERT  Int;
       BEFORE_DELETE Int;
       AFTER_DELETE  Int;
       BEFORE_UPDATE Int;
       AFTER_UPDATE  Int;
       BEFORE_COMMIT Int;
Begin
       BEFORE_INSERT := 0;
       AFTER_INSERT  := 1;
       BEFORE_DELETE := 2;
       AFTER_DELETE  := 3;
       BEFORE_UPDATE := 4;
       AFTER_UPDATE  := 5;
       BEFORE_COMMIT := 10;
       
/*******************************************************************************
   É possível obter o valor dos campos através das Functions:
   
  EVP_GET_CAMPO_DTA(P_IDSESSAO, 'NOMECAMPO') -- PARA CAMPOS DE DATA
  EVP_GET_CAMPO_INT(P_IDSESSAO, 'NOMECAMPO') -- PARA CAMPOS NUMÉRICOS INTEIROS
  EVP_GET_CAMPO_DEC(P_IDSESSAO, 'NOMECAMPO') -- PARA CAMPOS NUMÉRICOS DECIMAIS
  EVP_GET_CAMPO_TEXTO(P_IDSESSAO, 'NOMECAMPO')   -- PARA CAMPOS TEXTO
  
  O primeiro argumento é uma chave para esta execução. O segundo é o nome do campo.
  
  Para os eventos BEFORE UPDATE, BEFORE INSERT e AFTER DELETE todos os campos estarão disponíveis.
  Para os demais, somente os campos que pertencem à PK
  
  * Os campos CLOB/TEXT serão enviados convertidos para VARCHAR(4000)
  
  Também é possível alterar o valor de um campo através das Stored procedures:
  
  EVP_SET_CAMPO_DTA(P_IDSESSAO,  'NOMECAMPO', VALOR) -- VALOR DEVE SER UMA DATA
  EVP_SET_CAMPO_INT(P_IDSESSAO,  'NOMECAMPO', VALOR) -- VALOR DEVE SER UM NÚMERO INTEIRO
  EVP_SET_CAMPO_DEC(P_IDSESSAO,  'NOMECAMPO', VALOR) -- VALOR DEVE SER UM NÚMERO DECIMAL
  EVP_SET_CAMPO_TEXTO(P_IDSESSAO,  'NOMECAMPO', VALOR) -- VALOR DEVE SER UM TEXTO
********************************************************************************/

/*     IF P_TIPOEVENTO = BEFORE_INSERT THEN
             --DESCOMENTE ESTE BLOCO PARA PROGRAMAR O "BEFORE INSERT"
       END IF;*/
/*     IF P_TIPOEVENTO = AFTER_INSERT THEN
             --DESCOMENTE ESTE BLOCO PARA PROGRAMAR O "AFTER INSERT"
       END IF;*/

/*     IF P_TIPOEVENTO = BEFORE_DELETE THEN
             --DESCOMENTE ESTE BLOCO PARA PROGRAMAR O "BEFORE DELETE"
       END IF;*/
/*     IF P_TIPOEVENTO = AFTER_DELETE THEN
             --DESCOMENTE ESTE BLOCO PARA PROGRAMAR O "AFTER DELETE"
       END IF;*/

/*     IF P_TIPOEVENTO = BEFORE_UPDATE THEN
             --DESCOMENTE ESTE BLOCO PARA PROGRAMAR O "BEFORE UPDATE"
       END IF;*/
/*     IF P_TIPOEVENTO = AFTER_UPDATE THEN
             --DESCOMENTE ESTE BLOCO PARA PROGRAMAR O "AFTER UPDATE"
       END IF;*/

/*     IF P_TIPOEVENTO = BEFORE_COMMIT THEN
             --DESCOMENTE ESTE BLOCO PARA PROGRAMAR O "BEFORE COMMIT"
       END IF;*/

End;
/
