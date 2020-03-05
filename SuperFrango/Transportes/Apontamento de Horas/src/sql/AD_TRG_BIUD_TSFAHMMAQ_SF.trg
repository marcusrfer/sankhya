Create Or Replace Trigger AD_TRG_BIUD_TSFAHMMAQ_SF
	Before Insert Or Update Or Delete On AD_TSFAHMMAQ
	For Each Row
Declare
	v_Count Pls_Integer := 0;
	Errmsg  Varchar2(4000);
	Error Exception;
Begin
	/*
  Dt criaçao: 23/11/2016
  Autor: Marcus Rangel
  Objetivo: Impedir alterações em lançamentos cujo apontamento gerou pedido
  */
	If Updating Or deleting Then
		Select Count(*)
			Into v_count
			From ad_tsfahmapd a
		 Where a.nuapont = Nvl(:new.nuapont, :old.Nuapont)
			 And a.nuseqmaq = Nvl(:new.Nuseqmaq, :old.Nuseqmaq)
			 And a.faturado = 'S';
	
		If v_count <> 0 Then
			errmsg := 'Máquina não pode ser editada/excluída, pois o apontamento já gerou pedido. ';
			Raise error;
		End If;
	End If;
Exception
	When error Then
		Raise_Application_Error(-20105, ad_fnc_formataerro(errmsg));
	When Others Then
		errmsg := Sqlerrm;
		Raise_Application_Error(-20105, ad_fnc_formataerro(errmsg));
End Ad_Trg_Biud_Tsfahmm_Sf;
/
