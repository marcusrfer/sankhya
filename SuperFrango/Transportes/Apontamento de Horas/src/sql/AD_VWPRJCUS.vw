CREATE OR REPLACE VIEW AD_VWPRJCUS AS
SELECT
	 Rownum AS CHAVE,
	 CODCENCUS,
	 DESCRCENCUS ,
	 0 As NUAPONT,
	 0 As NUMCONTRATO,
	 0 As CODPROJ,
	 0 As CODPROD,
	 0 As CODMAQ
	From TSICUS Where ATIVO = 'S' And codcencus <> 0 And ANALITICO = 'S'
	 Union
	Select
	 Rownum ,
	 	 nvl(pc.codcencus, con.codcencus) CODCENCUS,
		 	 (Select DESCRCENCUS From TSICUS Where CODCENCUS = (	 nvl(pc.codcencus, con.codcencus))) Descrcencus,
	 M.NUAPONT,
	 M.NUMCONTRATO,
	 CON.CODPROJ,
   M.CODPROD,
	 M.CODMAQ
  From AD_TSFAHMMAQ M
	Left Join tcscon con On m.numcontrato = con.numcontrato
															 And nvl(con.ativo, 'N') = 'S'
															 And upper(con.ambiente) Like 'TRANSPORTE%'
															 And nvl(CON.DTTERMINO, '31/12/9999') > Trunc(Sysdate)
 Left Join ad_tcsprjcus pc On pc.codproj = con.codproj;
