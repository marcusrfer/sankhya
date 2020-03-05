Create Or Replace Trigger AD_TRG_BIUD_TSFSSTM_SF
	Before Insert Or Update Or Delete On ad_tsfsstm
	For Each Row
Declare
	i      ad_tsfssti%Rowtype;
	ErrMsg Varchar2(4000);

Begin
	/*
  Rotina: Solicita��o de Servi�os de Transporte
  Dt. Cria��o: 2811/2016
  Autor: Marcus Rangel
  Obejtivo: Efetuar o controle de altera��o baseados no status das solicita��es.
  */

	If inserting Then
	
		Select *
			Into i
			From ad_tsfssti
		 Where codsolst = Nvl(:new.Codsolst, :old.Codsolst)
			 And codserv = Nvl(:new.Codserv, :old.Codserv);
	
		If :new.Codvol <> i.codvol Then
			errmsg := ' Utilize a mesma unidade de medida do servi�o principal - ' || i.codvol;
			Raise_Application_Error(-20105, ad_fnc_formataerro(errmsg));
		End If;
	
		/* Tratativa para quando o usu�rio informar o valor no servi�o principal, impossibilitar o mesmo de inserir sub item */
		If (i.vlrunit <> 0 And Nvl(i.automatico, 'N') = 'S') Then
			errmsg := 'Os valores do servi�o j� foram informardos, indicando que o mesmo n�o possui sub itens,' ||
								' por favor, exclua o servi�os e lan�e novamente informando valor 0, em seguinda lan�e os sub itens.' ||
								chr(13);
			Raise_Application_Error(-20105, ad_fnc_formataerro(errmsg));
		End If;
	
	End If;

	If updating Then
		If :old.Numcontrato Is Not Null And :new.Numcontrato Is Not Null Then
			ERRMSG := 'Altera��o n�o pode ser realizada. O registro j� possui contrato gerado. <br> Exclua o contrato e/ou entre em contato com o respons�vel.';
			Raise_Application_Error(-20105, ad_fnc_formataerro(errmsg));
		End If;
	End If;

	/*  Atualiza o horario de altera��o no cabe�alho da solicita��o, disparando a valida��o*/
	Begin
		Update ad_tsfsstc c
			 Set c.dhalter = Sysdate, c.codusu = stp_get_codusulogado, c.origem = 1
		 Where c.codsolst = Nvl(:old.Codsolst, :new.Codsolst);
	Exception
		When Others Then
			errmsg := 'Erro ao atualiza o horario de altera��o no cabe�alho da solicita��o, disparando a valida��o. ' ||
								Sqlerrm;
			Raise_Application_Error(-20105, ad_fnc_formataerro(errmsg));
	End;
	--Exception
	--When Others Then
	--ad_set.insere_msglog('Erro ao atualizar cabe�alho da solicita��o nro ' || :new.Codsolst);
	--    raise_application_error(-20105, Sqlerrm);
End;
/
