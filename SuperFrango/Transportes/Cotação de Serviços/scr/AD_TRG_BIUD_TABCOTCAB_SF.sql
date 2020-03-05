Create Or Replace Trigger AD_TRG_BIUD_TABCOTCAB_SF
	Before Insert Or Update Or Delete On ad_tabcotcab
	For Each Row
Declare
	v_Count Int := 0;
	ErrMsg  Varchar2(4000);
	Error Exception;
Begin

	If :old.Situacao = 'C' Then
		ErrMsg := 'Cotações confirmadas (' || :Old.Numcotacao || ') não podem ser alteradas!';
		Raise error;
	Elsif Nvl(:old.Situacao, 'N') = 'AL' And Nvl(:new.Situacao, 'N') <> 'L' Then
		ErrMsg := 'Cotações aguardando liberação não podem ser alteradas!';
		Raise error;
	End If;

	If updating Then
	
		/* Se confirmando a cotação */
		If (:old.Situacao = 'L' And :new.Situacao = 'C') Then
		
			/* Valida se TOP foi informada*/
			If :new.Nunota Is Null And :new.Codtipoper Is Null Then
				Errmsg := 'TOP do pedido de compras não foi informada';
				Raise error;
			End If;
		
			/* Valida se tipo de negociação foi informado*/
			If :new.Nunota Is Null And :new.Codtipvenda Is Null Then
				Errmsg := 'Tipo de Negociação do pedido de compras não foi informado';
				Raise error;
			End If;
		
			/* Verifica se possui fornecedor marcado como vencedor */
			Select Count(*)
				Into v_Count
				From ad_tabcotforn f
			 Where f.numcotacao = :new.Numcotacao
				 And Nvl(f.vencedor, 'N') = 'S';
		
			If v_Count = 0 Then
				errmsg := 'Nenhum fornecedor Vencedor encontrado.';
				Raise error;
			End If;
		
			/* VErifica se possui itens lançados*/
			Select Count(1) Into v_Count From Ad_Tabcotite Ite Where Ite.Numcotacao = :new.Numcotacao;
		
			If v_Count = 0 Then
				Errmsg := 'Não foram encontrados produtos / serviços';
				Raise Error;
			End If;
		
		End If;
	
	End If;

Exception
	When error Then
		Raise_Application_Error(-20105, ad_fnc_formataerro(errmsg));
	When Others Then
		errmsg := Sqlerrm;
		Raise_Application_Error(-20105, ad_fnc_formataerro(errmsg));
End;
/
