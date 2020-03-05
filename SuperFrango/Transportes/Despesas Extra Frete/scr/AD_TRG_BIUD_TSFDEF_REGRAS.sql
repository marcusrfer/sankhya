Create Or Replace Trigger AD_TRG_BIUD_TSFDEF_REGRAS
	Before Insert Or Update Or Delete On AD_TSFDEF
	For Each Row
Declare
	v_Count Int := 0;
	Errmsg  Varchar2(4000);
Begin
	/*
   Autor: Marcus Rangel
   Processo: Despesas Extras de Frete
   Objetivo: Realizar validações no cabeçalho do lançamento de despesa extra de frete
  */

	If updating Then
		-- voltar o status quando o pedido de compras é excluido/cancelado
		If :new.Nunota Is Null And :Old.Status = 'P' Then
			:new.status := 'L';
		End If;
	End If;

	-- verificar situação da liberação antes da exclusão
	If deleting Then
		If :old.status = 'AL' Or :old.Status = 'L' Then
			If v_count <> 0 Then
				Select Count(*)
					Into v_count
					From tsilib l
				 Where l.nuchave = :old.Nudef
					 And tabela = 'AD_TSFDEF';
				errmsg := 'Não é possível excluir lançamento que possuem liberação.';
				Raise_Application_Error(-20105, ad_fnc_formataerro(errmsg));
			End If;
		Else
			If :old.status = 'P' Then
				v_count := 0;
				Select Count(*)
					Into v_count
					From tgfcab c
				 Where c.nunota = :old.Nunota;
				If v_count <> 0 Then
					errmsg := 'Não é possível excluir lançamento com pedido gerado.';
					Raise_Application_Error(-20105, ad_fnc_formataerro(errmsg));
				End If;
			End If;
		End If;
	End If;
End;
/
