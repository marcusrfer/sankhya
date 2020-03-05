Create Or Replace Procedure "AD_STP_IMPORTACIDREG"(pCodUsu Number, pSessao Varchar2, pQtdLinhas Number,
																									 pMsg Out Varchar2) As
	pCodRegIni Varchar2(4000);
	pCodRegFin Varchar2(4000);
	vNutab     Number;
	vNurff     Number;
	vNucrf     Number;
Begin

	pCodRegIni := ACT_TXT_PARAM(pSessao, 'CODREGINI');
	pCodRegFin := ACT_TXT_PARAM(pSessao, 'CODREGFIN');

	vNutab := ACT_INT_FIELD(pSessao, 0, 'MASTER_NUTAB');
	vNurff := ACT_INT_FIELD(pSessao, 0, 'MASTER_NURFF');

	/*  vNutab     := 2;
    vNurff     := 1;
    pCodRegIni := 2021201;
    pCodRegFin := 2021307;
  */

	Select nvl(Max(nucrf), 0) + 1
		Into vNucrf
		From ad_tsfcrff f
	 Where nutab = vNutab
		 And f.nurff = vNurff;

	For Cid In (Select codcid
								From tsicid c
							 Where c.codreg >= pCodRegIni
								 And c.codreg <= pCodRegFin)
	Loop
		Begin
			Insert Into AD_TSFCRFF (NUTAB, NURFF, NUCRF, CODCID) Values (vNutab, vNurff, vNucrf, cid.codcid);
			vNucrf := vNucrf + 1;
		Exception
			When Others Then
				Continue;
		End;
	End Loop;

End;
/
