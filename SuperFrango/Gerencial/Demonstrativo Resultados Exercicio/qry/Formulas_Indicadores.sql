/*
Select chave, numdec
 From tsipar 
Where Descricao Like '%INDICADORES%SF%' 
 And CHAVE Like '%SF_201606%' 
Order By 1;
*/



/*queFRMTZ*/
Select
	UFS.Uf,
	Round(Sum(Vlrfrete) / Sum(Peso), 4) total
From	Tgfcab CAB,
					Tsicid CID,
					Tsiufs UFS,
					Tgfpar PAR,
					Tsicus CUS,
					Tgftop TPO
Where To_Char(CAB.Dtneg, 'YYYYMM') = :Periodo
	And CUS.Codcencus = CAB.Codcencus
	And Right(CUS.Ad_clacus, 3) = 'MTZ'
	And PAR.Codparc = CAB.Codparc
	And CID.Codcid = PAR.Codcid
	And UFS.Coduf = CID.Uf
	And TPO.Codtipoper = CAB.Codtipoper
	And CAB.Peso > 0
	And TPO.Dhalter = CAB.Dhtipoper
	And TPO.Grupo In ('Venda', 'Dev. Venda')
	And CAB.Statusnota = 'L'
Group By UFS.Uf;


/*queFRTRX*/
Select * From (
	Select
		Round(Sum(Case When Codempnegoc = 5 Then Vlrfrete Else 0 End) / Sum(Case When Codempnegoc = 5 Then Peso Else 0 End), 4) As FR5,
		Round(Sum(Case When Codempnegoc = 7 Then Vlrfrete Else 0 End) / Sum(Case When Codempnegoc = 7 Then Peso Else 0 End), 4) As FR7,
		Round(Sum(Case When Codempnegoc = 14 Then Vlrfrete Else 0 End) / Sum(Case When Codempnegoc = 14 Then Peso Else 0 End), 4) As FR14,
		Round(Sum(Case When Codempnegoc = 5 Then Peso Else 0 End), 4) As QT5,
		Round(Sum(Case When Codempnegoc = 7 Then Peso Else 0 End), 4) As QT7,
		Round(Sum(Case When Codempnegoc = 14 Then Peso Else 0 End), 4) As QT14
	From Tgfcab CAB
	Where Bom(CAB.Dtfatur) = Bom(&Dat1)
		And Codtipoper = 46
		And Codempnegoc In (5, 7, 14)
);



/*queFR_CO*/
Select
	SubStr(NCC.Ad_clacus, 1, 2) As PREFIXO,
	Case When Right(CUS.Ad_clacus, 3) Not In ('GYN', 'BSB', 'ANP', 'UDI', ' PA', 'GRE', 'EXT', 'ENT') Then 'MTZ' Else Right(CUS.Ad_clacus, 3) End As UNNEG,
	Round(Sum(RAT.Vlrdesdob - RAT.Vlrdesc + RAT.Vlrjuro + RAT.Vlrmulta), 4) VALOR
From	Finreqrat_old RAT,
					Tgfncc NCC,
					Tsicus CUS
Where NCC.Codcencus = RAT.Codcencus
	And CUS.Codcencus = RAT.Codcencus
	And NCC.Codnat = RAT.Codnat
	And To_Char(Dtentsai, 'YYYYMM') = &Periodo
	And (NCC.Ad_clacus = 'FRETE S/ VENDA'
	And RAT.Recdesp = -1
	Or NCC.Ad_clacus = 'COMISSOES S/ VENDA'
	Or NCC.Ad_clacus = 'DESPESAS FINANCEIRAS'
	Or NCC.Ad_clacus = 'RECEITAS FINANCEIRAS'
	Or NCC.Ad_clacus = 'DIRETORIA'
	Or NCC.Ad_clacus = 'OUTRAS DESPESAS'
	)
Group By SubStr(NCC.Ad_clacus, 1, 2), Case When Right(CUS.Ad_clacus, 3) Not In ('GYN', 'BSB', 'ANP', 'UDI', ' PA', 'GRE', 'EXT', 'ENT') Then 'MTZ' Else Right(CUS.Ad_clacus, 3) End
;


/*queOAdm*/
Select
	CUS.Ad_clacus,
	Round(
	Sum(FRR.Vlrdesdob - FRR.Vlrdesc + FRR.Vlrjuro + FRR.Vlrmulta) -
	Sum(Case When FRR.Codemp In (1, 2, 501, 5, 8, 9, 14) And
			FRR.Codnat = 4052700 And
			NCC.Ad_clacus In ('OVERHEAD ADM_ PA', 'OVERHEAD ADM_BSB', 'OVERHEAD ADM_UDI', 'OVERHEAD ADM_ENT') Then FRR.Vlrdesdob - FRR.Vlrdesc + FRR.Vlrjuro + FRR.Vlrmulta Else 0 End), 4) VALOR
From	Finreqrat_old FRR,
					Tgfncc NCC,
					Tsicus CUS
Where To_Number(To_Char(FRR.Dtneg, 'MM')) = &P_mes
	And To_Number(To_Char(FRR.Dtneg, 'YYYY')) = &P_ano
	And FRR.Codemp In (1, 2, 501, 5, 8, 9, 14)
	And NCC.Codnat = FRR.Codnat
	And NCC.Codcencus = FRR.Codcencus
	And NCC.Ad_clacus Like 'OVERHEAD ADM%'
	And NCC.Codnat = FRR.Codnat
	And NCC.Codcencus = FRR.Codcencus
	And FRR.Recdesp = -1
	And FRR.Codnat Not Like '401%'
	And FRR.Codnat Not In (4091800)
	And Nvl(FRR.Codctabcoint, 0) <> 72  -- NOTAS DE ABASTECIMENTO EXTERNO CTF, PARA OS INDICADORES CONSIDERAMOS A TOP DE REQUISICAO
	And CUS.Codcencus = FRR.Codcencus
	And CUS.Ad_clacus Not In ('Fab Rações', 'Armz Milho', 'Armz Soja', 'Incubatorio', 'Agrícola', 'Armz Milho ADM'
	, 'Armz Milho PROD',
	'Armz Soja ADM', 'Armz Soja PROD', 'Aviários', 'Bovino', 'Expansao', 'Fab Farinha', 'Fazenda', 'Refloresta'
	, 'Frialto', 'Almox - Recep. Merc.', 'Processo Judicial', 'Frango do Terreiro', 'Armz Milho', 'Armz Soja'
	)
Group By CUS.Ad_clacus;

/*queOP*/
SELECT round(FC_OVER_PROD(&P_DATA),4) FROM DUAL;

/*queProcessa*/
SELECT FC_QTPROD(1, &dataproc),0,
FC_QTPROD(3, &dataproc) 
FROM DUAL;


/* queQTDVDA*/
Select
	Ad_clacus,
	Sum((Case When ITE.Atualestoque = -1 Then 1 Else -1 End) * ITE.Qtdneg) As "Vlr Total Produto (V-D)",
	Sum((Case When ITE.Atualestoque = -1 Then 1 Else -1 End) * Case When ITE.Codemp In (1, 5, 7, 14) Then ITE.Qtdneg Else 0 End) As "Vlr Total Produto EMP7"
From	Tgfpro PRO,
					Tgfcab CAB,
					Tgfite ITE,
					Tsicus CC,
					Tgftop TPO
Where CAB.Nunota = ITE.Nunota
	And ITE.Codprod = PRO.Codprod
	And PRO.Usoprod = 'V'
	And CC.Codcencus (+) = CAB.Codcencus
	And To_Number(To_Char(CAB.Dtfatur, 'MM')) = &P_mes
	And To_Number(To_Char(CAB.Dtfatur, 'YYYY')) = &P_ano
	And TPO.Codtipoper = CAB.Codtipoper
	And TPO.Dhalter = CAB.Dhtipoper
	And TPO.Grupo In ('Venda', 'Dev. Venda')
	And ((PRO.Codgrupoprod >= 1000000
	And PRO.Codgrupoprod <= 1989999)
	Or (PRO.Codgrupoprod >= 3000000
	And PRO.Codgrupoprod <= 3999999)
	)
	And PRO.Codgrupoprod <> 3020100  -- FREEZERS
	And CAB.Codemp Not In (8)
	And CAB.Statusnota = 'L'
Group By Ad_clacus

