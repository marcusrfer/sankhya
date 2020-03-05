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
  Rotina: Solicita��o de Servi�os de Transporte
  Dt. Cria��o:
  Autor: Marcus Rangel
  Objetvo: Efetuar o controle de altera��o baseados no status das solicita��es.
  ******************************************************************************/

	/*Controle de atualiza��o manual - algumas rotinas atualizam dtalter e codusualter 
  1 � proveniente de alguma procedure que realiza alguma altera��o */
	If :new.origem = 1 And Nvl(:old.origem, 0) = 0 Then
		:new.origem := 0;
		Return;
	End If;

	If updating Then
	
		/* Para n�o ficar sem solicita��o, as vezes o Suelto lan�a a mesma e ele � o aprovador
    * ent�o para garantir que ele possa alterar quando em an�lise e o usu�rio normal
    * n�o possa, verifica-se que o usu�rio da altera��o � liberador, se for permite
    * se n�o, pro�be.
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
			errmsg := 'Lan�amento em an�lise n�o pode ser alterado pelo usu�rio solicitante.';
			Raise error;
		Elsif :old.Status = 'L' And :new.Status = 'L' And liberador = 0 Then
			errmsg := 'Lan�amento confirmados n�o podem ser alterados.';
			Raise error;
		End If;
	
	Elsif deleting Then
	
		If (:old.Status = 'A') And v_codusualter = :old.Codsol Then
			errmsg := 'Lan�amento em an�lise n�o pode ser exclu�do.';
			Raise error;
		Elsif :old.Status = 'L' Then
			errmsg := 'Lan�amento confirmado n�o pode ser exclu�do.';
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
