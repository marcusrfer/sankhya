CREATE OR REPLACE TRIGGER "TRG_INC_UPT_PARRENOVAR_SF"
BEFORE INSERT OR UPDATE
ON SANKHYA.AD_ADTSSAPARRENOVAR 
REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW
DECLARE

BEGIN
         IF  Tsiusu_Log_Pkg.V_CODUSULOG NOT IN (114,825) THEN
            Raise_Application_Error(-20101, 'Somente a integração (Sebastião Henrique e equipe) pode usar essa aba');

         END IF;


         IF NVL(:NEW.NUFINDESP,0) > 0 AND (UPDATING('DTVENC') OR UPDATING('VLRDESDOB') ) THEN
            Raise_Application_Error(-20101, 'Depois de gerado, proibida alteração!!!!');

         END IF; 



END TRG_INC_UPT_PARRENOVAR_SF;
/
