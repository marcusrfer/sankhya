Create Or Replace Trigger "AD_TRG_BIUD_TABCOTITE_PRECO"
	Before Insert Or Update Or Delete On Ad_Tabcotite
	For Each Row
Declare
	v_Nuregforn  Int;
	v_Numcotacao Int;
	v_Oldvalor   Float;
	v_Newvalor   Float;
	v_Olddesc    Float;
	v_Newdesc    Float;
	v_Tipoper    Char(1);
	v_Valortotal Float;
	v_Vlrtot     Float;
	v_VlrFrete   Float;
	Var_VlrFrete Float;
Begin

	/* Autor: M.Rangel
  * Processo: Cotação de serviços de transporte
  * Objetivo: Atualizar os totais do fornecedor ao manipular os itens.
  */
	If inserting Then
		v_Numcotacao := :New.Numcotacao;
		v_Nuregforn  := :New.Nuregforn;
		Begin
			Select Nvl(f.Vlrtot, 0), Nvl(f.vlrfrete, 0)
				Into v_Valortotal, Var_VlrFrete
				From Ad_Tabcotforn f
			 Where f.Numcotacao = v_Numcotacao
				 And f.Nuregforn = v_Nuregforn;
		
			If v_Valortotal Is Null Then
				v_Valortotal := 0;
			End If;
		
			If Var_VlrFrete Is Null Then
				Var_VlrFrete := 0;
			End If;
		
		End;
	
		v_Vlrtot      := (:New.Qtdneg * :New.Vlrunit) - :New.Vlrdesconto;
		:New.Vlrtotal := v_Vlrtot;
		v_Oldvalor    := :Old.Vlrtotal;
		v_Newvalor    := :New.Vlrtotal;
		v_Olddesc     := :Old.Vlrdesconto;
		v_Newdesc     := :New.Vlrdesconto;
		v_VlrFrete    := :new.Vlrfrete;
		v_Valortotal  := v_Valortotal + (v_Newvalor);
		Var_VlrFrete  := Var_VlrFrete + v_VlrFrete;
	
		Begin
			Update Ad_Tabcotforn f
				 Set f.Vlrtot = v_Valortotal, f.vlrfrete = Var_VlrFrete
			 Where f.Numcotacao = v_Numcotacao
				 And f.Nuregforn = v_Nuregforn;
		End;
	
	End If;

	If updating Then
	
		v_Numcotacao := :New.Numcotacao;
		v_Nuregforn  := :New.Nuregforn;
	
		Begin
			Select f.Vlrtot, f.vlrfrete
				Into v_Valortotal, Var_VlrFrete
				From Ad_Tabcotforn f
			 Where f.Numcotacao = v_Numcotacao
				 And f.Nuregforn = v_Nuregforn;
		
			If v_Valortotal Is Null Then
				v_Valortotal := 0;
			End If;
		
			If Var_VlrFrete Is Null Then
				Var_VlrFrete := 0;
			End If;
		
		End;
		v_Vlrtot      := (:New.Qtdneg * :New.Vlrunit) - :New.Vlrdesconto;
		:New.Vlrtotal := v_Vlrtot;
		v_Oldvalor    := :Old.Vlrtotal;
		v_Newvalor    := :New.Vlrtotal;
		v_Olddesc     := :Old.Vlrdesconto;
		v_Newdesc     := :New.Vlrdesconto;
		v_VlrFrete    := :new.Vlrfrete;
		v_Valortotal  := v_Valortotal - v_Oldvalor;
		v_Valortotal  := v_Valortotal + v_Newvalor;
		Var_VlrFrete  := Var_VlrFrete + v_VlrFrete - :old.Vlrfrete;
	
		Begin
			Update Ad_Tabcotforn f
				 Set f.Vlrtot = v_Valortotal, f.vlrfrete = Var_VlrFrete
			 Where f.Numcotacao = v_Numcotacao
				 And f.Nuregforn = v_Nuregforn;
		End;
	
	End If;

	If deleting Then
		Begin
			v_Numcotacao := :Old.Numcotacao;
			v_Nuregforn  := :Old.Nuregforn;
			v_Oldvalor   := :Old.Vlrtotal;
			v_Olddesc    := :Old.Vlrdesconto;
			v_VlrFrete   := :old.Vlrfrete;
		
			Select f.Vlrtot, f.vlrfrete
				Into v_Valortotal, Var_VlrFrete
				From Ad_Tabcotforn f
			 Where f.Numcotacao = v_Numcotacao
				 And f.Nuregforn = v_Nuregforn;
		
			If v_Valortotal Is Null Then
				v_Valortotal := 0;
			End If;
		
			If Var_VlrFrete Is Null Then
				Var_VlrFrete := 0;
			End If;
		
		End;
	
		v_Valortotal := v_Valortotal - (v_Oldvalor);
		Var_VlrFrete := Var_VlrFrete - v_VlrFrete;
	
	End If;

	Update Ad_Tabcotforn f
		 Set f.Vlrtot = v_Valortotal, f.vlrfrete = Var_VlrFrete
	 Where f.Numcotacao = v_Numcotacao
		 And f.Nuregforn = v_Nuregforn;

	--Raise_Application_Error(-20101, v_Tipoper);
End;
/
