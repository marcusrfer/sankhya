Create Or Replace Trigger AD_TRG_BIUD_TSFSSTC_SF
	Before Insert Or Update Or Delete On ad_tsfsstc
	For Each Row
Declare
	v_codUsuAlter Number := stp_get_codusulogado;
	errmsg        Varchar2(4000);
	error Exception;
Begin
	/*
  Dt. Criação:
  Autor:
  Objetvo: Efetuar o controle de alteração baseados no status das solicitações.
  */
	-- retirar após homologação
	/*If v_codusualter = 0 Then
   Return;
  End If;*/

	-- excluir em produção
	If v_codusualter = 0 Then
		Return;
	End If;

	If updating Then
		If :old.Numcontrato Is Not Null And :new.Numcontrato Is Null Then
			:new.Status := 'A';
		End If;
	
		If (:old.Status = 'A' And :new.Status = 'A') And v_codusualter = :new.Codsol Then
			errmsg := 'Lançamento em análise não pode ser alterado.';
			Raise error;
		Elsif :old.Status = 'L' And :new.Status = 'L' Then
			errmsg := 'Lançamento confirmados não pode ser alterado.';
			Raise error;
		End If;
	
	Elsif deleting Then
	
		If (:old.Status = 'A') And v_codusualter = :old.Codsol Then
			errmsg := 'Lançamento em análise não pode ser excluído.';
			Raise error;
		Elsif :old.Status = 'L' Then
			errmsg := 'Lançamento confirmado não pode ser excluído.';
			Raise error;
		End If;
	
	End If;

Exception
	When error Then
		raise_application_error(-20105, ad_fnc_formataerro(errmsg));
	When Others Then
		raise_application_error(-20105, ad_fnc_formataerro(Sqlerrm));
End AD_TRG_BIUD_TSFSSTC_SF;
/
