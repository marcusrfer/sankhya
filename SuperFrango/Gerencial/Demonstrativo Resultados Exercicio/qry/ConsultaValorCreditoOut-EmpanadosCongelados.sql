-- Empanados Congelados
-- noFormat start
Select codemp,
							ad_sigla,
							uf,
							nunota, sequencia,
							codgrupoprod,
							vlrunit,
							qtdneg,
							vlrtot,
							vlripi,
							vlrdesc,
							ad_vlrtrx,
							
       Case 
        When CODEMP = 7 And AD_SIGLA = ' PA' 
        Then NVL(AD_VLRTRX, 0) * 0.14 * (Case When TIPMOV = 'V' Then QTDNEG Else 0 End)
       Else
         0
        End v1,
         ((NVL(AD_Vlrtrx, 0) * 0.02 * (Case When TIPMOV = 'V' Then QTDNEG Else 0 End)) * 
        (Case When AD_SIGLA In ('BSB', 'GRE') And CODEMP = 5 And DTNEG >= '01/10/2010' Then 1 Else 0 End)) As "VlrTrx * 2%",
        
         ((NVL(AD_Vlrtrx, 0) * 0.12 * Case When TIPMOV = 'V' Then QTDNEG Else 0 End) * 
        (Case When AD_SIGLA In ('BSB', 'GRE') And CODEMP = 5 And DTNEG >= '01/11/2014' Then 1 Else 0 End)) As "VlrTrx * 12%",

         (Case When AD_SIGLA In ('BSB', 'GRE') And CODEMP = 5  and TIPMOV='V' 
         Then (VLRTOT + VLRIPI - VLRDESC - 0) * 0.05            -- CRÉDITO PRESUMIDO DF
        Else 0 End) "Presumido 5%",
								 
        ((NVL(AD_Vlrtrx, 0) * 0.02 * Case When TIPMOV = 'V' Then QTDNEG Else 0 End) * 
								Case When CODEMP = 14 Then 1 Else 0 End) "VlrTrx * 2%",
								 
								 (Case When CODEMP = 1 And DESCRICAO <> 'GOIAS' Then
         (Case When TIPMOV = 'V' 
										Then QTDNEG Else 0 End) * (VLRUNIT + VLRIPI - VLRDESC) * 0.02 Else 0 End) "VlrUnit * 2%",
       (Case 
							 When CODEMP = 7 And AD_SIGLA = ' PA' 
							 Then NVL(AD_VLRTRX, 0) * 0.14 * (Case When TIPMOV = 'V' Then QTDNEG Else 0 End)
       Else
         0
        End 
								+ 
        ((NVL(AD_Vlrtrx, 0) * 0.02 * (Case When TIPMOV = 'V' Then QTDNEG Else 0 End)) * 
								(Case When AD_SIGLA In ('BSB', 'GRE') And CODEMP = 5 And DTNEG >= '01/10/2010' Then 1 Else 0 End)) 
        +
        ((NVL(AD_Vlrtrx, 0) * 0.12 * Case When TIPMOV = 'V' Then QTDNEG Else 0 End) * 
								(Case When AD_SIGLA In ('BSB', 'GRE') And CODEMP = 5 And DTNEG >= '01/11/2014' Then 1 Else 0 End)) 
        +
        (Case When AD_SIGLA In ('BSB', 'GRE') And CODEMP = 5  and TIPMOV='V' 
								 Then (VLRTOT + VLRIPI - VLRDESC - 0) * 0.05            -- CRÉDITO PRESUMIDO DF
        Else 0 End)
								+ 
        ((NVL(AD_Vlrtrx, 0) * 0.02 * Case When TIPMOV = 'V' Then QTDNEG Else 0 End) * 
								Case When CODEMP = 14 Then 1 Else 0 End) 
								+
        (Case When CODEMP = 1 And DESCRICAO <> 'GOIAS' Then
         (Case When TIPMOV = 'V' 
										Then QTDNEG Else 0 End) * (VLRUNIT + VLRIPI - VLRDESC) * 0.02 Else 0 End))/QTDNEG "Vlr Calc DRE",
										 

										 vlrunit * ad_fnc_getValorMetaDre(Nunota,sequencia,'CREDOUTVDA') As "Vlr Out. Venda",
											nvl(ad_vlrtrx,0) * ad_fnc_getValorMetaDre(Nunota,sequencia,'CREDOUTTRX') As "Vlr Out. Transf",
           vlrunit * ad_fnc_getValorMetaDre(Nunota,sequencia,'CREDPRESMD') As "Vlr CrédPres"									
																								
		From basedre_dev
	Where codgrupoprod = 3020200
	And codemp = 7;
