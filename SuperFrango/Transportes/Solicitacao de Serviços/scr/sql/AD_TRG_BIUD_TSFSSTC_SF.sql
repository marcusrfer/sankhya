Create Or Replace Trigger AD_TRG_BIUD_TSFSSTC_SF
	Before Insert Or Update Or Delete On ad_tsfsstc
	For Each Row
Declare
	v_codUsuAlter Number := stp_get_codusulogado;
	liberador     Int := 0;
	errmsg        Varchar2(4000);
	error Exception;
Begin
	/*****************************************************************************
  Rotina: Solicitação de Serviços de Transporte
  Dt. Criação:
  Autor: Marcus Rangel
  Objetvo: Efetuar o controle de alteração baseados no status das solicitações.
  ******************************************************************************/

	/*Controle de atualização manual - algumas rotinas atualizam dtalter e codusualter 
  1 é proveniente de alguma procedure que realiza alguma alteração */
	If :new.origem = 1 And Nvl(:old.origem, 0) = 0 Then
		:new.origem := 0;
		Return;
	End If;

	If updating Then
	
		/* Para não ficar sem solicitação, as vezes o Suelto lança a mesma e ele é o aprovador
    * então para garantir que ele possa alterar quando em análise e o usuário normal
    * não possa, verifica-se que o usuário da alteração é liberador, se for permite
    * se não, proíbe.
    */
		Begin
			Select Count(*)
				Into liberador
				From ad_centparamusu u
			 Where nupar = 4
				 And u.codusu = v_codusualter
					Or v_codusualter = 0;
		Exception
			When no_data_found Then
				liberador := 0;
		End;
	
		If (:old.Status = 'A' And :new.Status = 'A') And (v_codusualter = :old.Codsol Or liberador = 0) Then
			errmsg := 'Lançamento em análise não pode ser alterado pelo usuário solicitante.';
			Raise error;
		Elsif :old.Status = 'L' And :new.Status = 'L' And liberador = 0 Then
			errmsg := 'Lançamento confirmados não podem ser alterados.';
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
		Raise_Application_Error(-20105, ad_fnc_formataerro(errmsg));
	When Others Then
		Raise_Application_Error(-20105, ad_fnc_formataerro(Sqlerrm));
End AD_TRG_BIUD_TSFSSTC_SF;
/
