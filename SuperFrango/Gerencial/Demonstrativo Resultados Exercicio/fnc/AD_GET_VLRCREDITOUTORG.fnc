CREATE OR REPLACE Function SANKHYA.Ad_get_vlrcreditoutorg(p_nunota Number, p_seq Int, p_sigla Varchar2) Return Float Is
	v_Sigla       Varchar2(4000);
	cab           Tgfcab % Rowtype;
	ite           Tgfite % Rowtype;
	pro           Tgfpro % Rowtype;
	v_Result      Float;
	v_QtdMov      Int;
	v_Codemp14    Int;
	v_BsbGre      Int;
	v_UF          Char(2);
	v_UfDescricao Varchar2(2000);
	v_CredOutEmp  Float;
	v_Aux1        Float;
	v_Aux2        Float;
	v_Aux3        Float;
	v_Aux4        Float;
	v_Aux5        Float;
	Error Exception;
Begin
	v_Sigla := Upper(Ltrim(Rtrim(p_sigla)));
	Select * Into cab From Tgfcab Where Nunota = p_nunota;
	Select e.ad_credoutorg Into v_CredOutEmp From tsiemp e Where codemp = cab.codemp;

	Begin
		Select *
			Into ite
			From Tgfite
		 Where Nunota = p_nunota
			 And Sequencia = p_seq
			 And qtdneg <> 0;
	Exception
		When no_data_found Then
			v_Result := 0;
	End;

	Select * Into pro From Tgfpro Where Codprod = ite.Codprod;

	Select Upper(u.Descricao), u.uf
		Into v_UfDescricao, v_UF
		From Tgfpar p
		Join Tsicid c On c.Codcid = p.Codcid
		Join Tsiufs u On u.Coduf = c.Uf
	 Where p.Codparc = cab.Codparc;

	If cab.Tipmov = 'V' Then
		v_QtdMov := ite.Qtdneg;
	Else
		v_QtdMov := 1;
	End If;

	If v_QtdMov = 0 Then
		v_QtdMov := 1;
	End If;

	If cab.Codemp = 14 Then
		v_Codemp14 := 1;
	Else
		v_Codemp14 := 0;
	End If;

	If v_Sigla In ('BSB', 'GRE') And cab.Codemp = 5 And
		 (cab.Dtneg >= To_Date('01/10/2010', 'DD/MM/YYYY') Or cab.Dtneg >= To_Date('01/11/2014', 'DD/MM/YYYY')) Then
		v_BsbGre := 1;
	Else
		v_BsbGre := 0;
	End If;

	If pro.Codgrupoprod = 3020200 Then
	
		If cab.Codemp = 1 And v_UfDescricao <> 'GOIAS' Then
			v_Aux3 := v_QtdMov * (ite.Vlrunit + ite.Vlripi - ite.Vlrdesc) * 0.02;
		Else
			v_Aux3 := (ite.Vlrunit + ite.Vlripi - ite.Vlrdesc) * 0.07;
		End If;
	
		If cab.Codemp = 7 And v_Sigla = 'PA' Then
			v_Result := Nvl(ite.Ad_vlrtrx, 0) * 0.02 * v_QtdMov;
		Else
			v_Result := 0;
		End If;
	
		v_Result := ((v_Result + Nvl(ite.Ad_vlrtrx, 0) * 0.02 * v_QtdMov * v_BsbGre +
								((Nvl(ite.Ad_vlrtrx, 0) * 0.12 * v_QtdMov) * v_BsbGre) +
								((Nvl(ite.Ad_vlrtrx, 0) * 0.02 * v_QtdMov) * v_Codemp14) + v_Aux3) / ite.Qtdneg);
	
		v_Result := Nvl(v_Result, 0);
	
	Elsif pro.Codgrupoprod = 1040200 Then
	
		If cab.Codemp = 7 And v_Sigla = 'PA' Then
			v_Result := Nvl(ite.Ad_vlrtrx, 0) * 0.02 * v_QtdMov;
		Else
			v_Result := 0;
		End If;
	
		v_Result := ((v_Result + ((Nvl(ite.Ad_vlrtrx, 0) * 0.02 * v_QtdMov * v_Aux1) +
								((Nvl(ite.Ad_vlrtrx, 0) * 0.12 * v_QtdMov) * v_Aux1) +
								((Nvl(ite.Ad_vlrtrx, 0) * 0.02 * v_QtdMov) * v_codemp14) + v_Aux3)) / ite.Qtdneg);
	
		v_Result := Nvl(v_Result, 0);
	
	Elsif PRO.CODGRUPOPROD Like '10403%' Then
		-- GRUPO LINGUIÇA RESFRIADA E CONGELADA
	
		If CAB.CODEMP = 1 And v_UfDescricao Not In ('GOIAS', 'AMAZONAS') Then
			v_aux1 := (v_qtdmov) * (ITE.VLRUNIT + ITE.VLRIPI - ITE.VLRDESC) * 0.09;
		Else
			v_aux1 := 0;
		End If;
	
		If v_UF = 'GO' And CAB.CODEMP = 1 And CAB.DTNEG >= '01/11/2014' Then
			v_aux2 := 1;
		Else
			v_aux2 := 0;
		End If;
	
		If CAB.CODEMP = 7 And v_SIGLA = 'PA' Then
			v_result := NVL(ITE.AD_VLRTRX, 0) * 0.09 * v_qtdmov;
		Else
			v_result := 0;
		End If;
	
		v_result := ((v_result + ((NVL(ITE.AD_Vlrtrx, 0) * 0.21 * v_qtdmov) * v_BsbGre) +
								((NVL(ITE.AD_Vlrtrx, 0) * 0.09 * v_qtdmov) * v_Codemp14) + v_aux1 +
								(v_qtdmov * (ITE.VLRUNIT + ITE.VLRIPI - ITE.VLRDESC)) * 0.09 * v_aux2) / ITE.QTDNEG);
	
	Elsif pro.Codgrupoprod = 3010100 Then
	
		If v_Sigla In ('BSB', 'PA', 'GRE') And cab.Codemp In (5, 7) Then
			v_Aux1 := 1;
		Else
			v_Aux1 := 0;
		End If;
	
		If v_Sigla In ('PA') And cab.Codemp In (7) Then
			v_Aux2 := 1;
		Else
			v_Aux2 := 0;
		End If;
	
		If v_Sigla In ('BSB') And cab.Codemp = 8 And cab.Dtneg >= '01/10/2010' Then
			v_Aux3 := 1;
		Else
			v_Aux3 := 0;
		End If;
	
		v_Result := (((Nvl(ite.Ad_vlrtrx, 0) * 0.04 * v_QtdMov) * v_Aux1 +
								(Nvl(ite.Ad_vlrtrx, 0) * 0.02 * v_QtdMov) * v_Aux2 +
								(v_QtdMov * (ite.Vlrunit + ite.Vlripi - ite.Vlrdesc)) * 0.17 * v_Aux3) / v_QtdMov);
	
	Elsif pro.Codgrupoprod = 3020300 Then
		--  VEGETAIS 
	
		If cab.Codemp = 5 Then
			v_Result := (Nvl(ite.Ad_vlrtrx, 0) * 0.12) + (Nvl(ite.Ad_vlrtrx, 0) * 0.02) +
									(((ite.Vlrtot + ite.Vlripi - ite.Vlrsubst - ite.Vlrdesc) / ite.Qtdneg) * 0.05);
		Else
			v_Result := 0;
		End If;
	
	Elsif pro.Codgrupoprod = 1040400 Then
		--  Embutidos Castrolanda  - o.s 8799 by rodrigo
	
		If cab.Codemp = 1 And v_UfDescricao <> 'GOIAS' Then
			v_aux4 := (v_QtdMov) * (ite.Vlrunit + ite.Vlripi - ite.Vlrdesc) * 0.02;
		Else
			V_aux4 := 0;
		End If;
	
		If cab.Codemp = 7 And v_Sigla = 'PA' Then
			v_Result := Nvl(ite.Ad_vlrtrx, 0) * 0.14 * v_QtdMov;
		Else
			v_Result := 0;
		End If;
	
		v_Result := ((v_Result + ((Nvl(ite.Ad_vlrtrx, 0) * 0.02 * v_QtdMov) * v_BsbGre) +
								((Nvl(ite.Ad_vlrtrx, 0) * 0.12 * v_QtdMov) * v_BsbGre) +
								((Nvl(ite.Ad_vlrtrx, 0) * 0.02 * v_QtdMov) * v_Codemp14) + (V_aux4)) / ite.Qtdneg);
	
	Elsif 0 = 0 Then
	
		If v_SIGLA = 'BA' And CAB.DTNEG >= '01/12/2012' Then
			v_aux1 := 3;
		Else
			v_aux1 := v_CredOutEmp;
		End If;
	
		If CAB.CODEMP > 500 Then
			v_aux2 := 0;
		Else
			v_aux2 := 1;
		End If;
	
		If v_SIGLA In ('BSB', ' PA', 'GRE', 'UDI') And CAB.CODEMP In (5, 7, 14) Then
			v_aux3 := 1;
		Else
			v_aux3 := 0;
		End If;
	
		If v_SIGLA In ('BSB') And CAB.CODEMP = 8 And CAB.DTNEG >= TO_DATE('01/10/2010', 'DD/MM/YYYY') Then
			v_aux5 := 1;
		Else
			v_aux5 := 0;
		End If;
	
		--CALCULO DO CREDITO OUTORGADO SOBRE VENDA                                                               
		v_result := (((v_qtdmov * (ITE.VLRUNIT + ITE.VLRIPI - ITE.VLRDESC)) * (v_aux1 / 100) * v_aux2 +
								(NVL(ITE.AD_Vlrtrx, 0) * 0.09 * v_qtdmov) * v_aux3 +
								(NVL(ITE.AD_Vlrtrx, 0) * 0.12 * v_qtdmov) * v_BsbGre +
								(v_qtdmov * (ITE.VLRUNIT + ITE.VLRIPI - ITE.VLRDESC)) * 0.17 * v_aux5) / v_qtdmov);
	
	End If;

	Return v_Result;

Exception
	When no_data_found Then
		v_result := 0;
		Return v_Result;
	When Others Then
		raise_application_error(-20105, p_nunota || ' - ' || Sqlerrm);
End;