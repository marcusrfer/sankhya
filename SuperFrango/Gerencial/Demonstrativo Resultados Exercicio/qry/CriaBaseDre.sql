PL/SQL Developer Test script 3.0
128
Declare
	p_dataini Date;
	p_datafin Date;

	Cursor c_Dre(p_dataini Date, p_datafin Date) Is
		Select CAB.CODVEND,
									CAB.CODEMP,
									CAB.DTNEG,
									CAB.DTFATUR,
									CAB.CODPARC,
									ITE.NUNOTA,
									ITE.SEQUENCIA,
									(Case
										When CAB.TIPMOV = 'D' Then
											ITE.QTDNEG
										Else
											0
									End) As QTDDEV,
									Trim(CUS1.AD_SIGLA) As UNNEG,
									CUS1.CODCENCUS,
									CUS1.DESCRCENCUS,
									UFS.UF || '-' || To_Char(Case
																																			When CAB.CODEMP > 500 Then
																																				CAB.CODEMP - 500
																																			Else
																																				CAB.CODEMP
																																		End) As UFPARC,
									ITE.VLRTOT,
									ITE.VLRIPI,
									ITE.VLRSUBST,
									ITE.VLRDESC,
									ITE.VLRREPRED,
									ITE.ALIQICMS,
									ITE.VLRICMS,
									ITE.AD_ICMSTRX ICMSTRX,
									EMP1.AD_CREDOUTORG CREDOUTORGEMP,
									ITE.QTDNEG,
									ITE.CODPROD As CODPROD,
									PRO.DESCRPROD As DESCRPROD,
									PRO.CODVOL,
									CAB.VLRDESCTOT,
									CAB.PESO,
									CAB.TIPMOV,
									ITE.AD_VLRTRX As VLRTRX,
									PRO.CODGRUPOPROD,
									UFS.CODUF,
									UFS.UF,
									UFS.DESCRICAO DESCRUF,
									PRO.CREDMP1,
									PRO.CREDMP2,
									FC_DIVIDE((VLR_IMP(ITE.NUNOTA, ITE.SEQUENCIA, 'PIS', 'C') +
																			VLR_IMP(ITE.NUNOTA, ITE.SEQUENCIA, 'COFINS', 'C')),
																			(FC_DIVIDE((ITE.VLRTOT + ITE.VLRIPI + ITE.VLRSUBST - ITE.VLRDESC), (ITE.QTDNEG))) * 100) As CREDPISCOFINS,
									VLR_IMP(ITE.NUNOTA, ITE.SEQUENCIA, 'PIS', 'D') As PISORIG,
									VLR_IMP(ITE.NUNOTA, ITE.SEQUENCIA, 'COFINS', 'D') As COFINS
				From TGFCAB   CAB,
									TGFPAR   PAR,
									TSICID   CID,
									TSIUFS   UFS,
									TGFITE   ITE,
									TGFPRO   PRO,
									TSICUS   CUS1,
									TSIEMP   EMP1,
									TGFEMP   EMP,
									TGFTOP   TPO,
									TGFORD   ORD,
									TGFCAB   PAI,
									TGFPAR   PARPAI,
									GFSCROSS CRO
			Where CAB.CODPARC = PAR.CODPARC
					And CAB.CODEMP = ORD.CODEMP
					And CAB.ORDEMCARGA = ORD.ORDEMCARGA
					And ORD.ORDEMCARGAPAI = PAI.ORDEMCARGA(+)
					And ORD.CODEMP = PAI.CODEMP(+)
					And PAI.CODPARC = PARPAI.CODPARC(+)
					And PAR.CODCID = CID.CODCID
					And CAB.STATUSNOTA = 'L'
					And UFS.CODUF = CID.UF
					And CAB.NUNOTA = ITE.NUNOTA
					And ITE.CODPROD = PRO.CODPROD
					And CUS1.CODCENCUS = CAB.CODCENCUS
					And EMP1.CODEMP = CAB.CODEMP
					And EMP.CODEMP = CAB.CODEMP
					And CAB.CODCENCUS = CUS1.CODCENCUS
					And CRO.CODCID(+) = PARPAI.CODCID
					And CRO.REFERENCIA(+) = p_dataini
					And CAB.CODTIPOPER = TPO.CODTIPOPER
					And CAB.DHTIPOPER = TPO.DHALTER
					And CAB.CODEMP <> 8
					And (CAB.DTFATUR >= p_dataini)
					And (CAB.DTFATUR <= p_datafin)
					And tpo.tipmov In ('V', 'D')
					And tpo.atualfin <> 0
					And CAB.NUNOTA In
									(Case When Nvl(PAI.CODTIPOPER, 0) = 0 Then CAB.NUNOTA Else Case When
										tpo.grupo = 'Dev. Venda' Then CAB.NUNOTA Else (Select Distinct V.NUNOTAORIG
													From TGFVAR V, TGFCAB C
												Where V.NUNOTA = C.NUNOTA
														And C.CODTIPOPER = PAI.CODTIPOPER
														And C.ORDEMCARGA = ORD.ORDEMCARGAPAI
														And V.NUNOTAORIG = CAB.NUNOTA) End End);

	Type tpBaseDados Is Table Of c_Dre%Rowtype;
	tbBaseDados tpBaseDados;

Begin

	p_dataini := :dataini;
	p_datafin := :datafin;
	Delete From ad_basedre Where dtneg Between p_dataini And p_datafin;
	Open c_Dre(p_dataini, p_datafin);
	Loop
		Fetch c_Dre Bulk Collect
		Into tbBaseDados Limit 1000;
	
		Begin
			Forall i In 1 .. tbBaseDados.count 
				Insert Into ad_basedre Values tbBaseDados (i);
					Commit;
		Exception
			When dup_val_on_index Then
				Continue;
		End;
	
		Exit When c_Dre%Notfound;
	End Loop;
	Close c_Dre;
End;
2
dataini
1
01/07/2016
12
datafin
1
01/07/2016
12
0
