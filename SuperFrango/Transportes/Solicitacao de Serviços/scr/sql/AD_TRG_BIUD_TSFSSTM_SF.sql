Create Or Replace Trigger AD_TRG_BIUD_TSFSSTM_SF
	Before Insert Or Update Or Delete On ad_tsfsstm
	For Each Row
Declare
	i      ad_tsfssti%Rowtype;
	ErrMsg Varchar2(4000);

Begin
	/*
  Rotina: Solicitação de Serviços de Transporte
  Dt. Criação: 2811/2016
  Autor: Marcus Rangel
  Obejtivo: Efetuar o controle de alteração baseados no status das solicitações.
  */

	If inserting Then
	
		Select *
			Into i
			From ad_tsfssti
		 Where codsolst = Nvl(:new.Codsolst, :old.Codsolst)
			 And codserv = Nvl(:new.Codserv, :old.Codserv);
	
		If :new.Codvol <> i.codvol Then
			errmsg := ' Utilize a mesma unidade de medida do serviço principal - ' || i.codvol;
			Raise_Application_Error(-20105, ad_fnc_formataerro(errmsg));
		End If;
	
		/* Tratativa para quando o usuário informar o valor no serviço principal, impossibilitar o mesmo de inserir sub item */
		If (i.vlrunit <> 0 And Nvl(i.automatico, 'N') = 'S') Then
			errmsg := 'Os valores do serviço já foram informardos, indicando que o mesmo não possui sub itens,' ||
								' por favor, exclua o serviços e lançe novamente informando valor 0, em seguinda lançe os sub itens.' ||
								chr(13);
			Raise_Application_Error(-20105, ad_fnc_formataerro(errmsg));
		End If;
	
	End If;

	If updating Then
		If :old.Numcontrato Is Not Null And :new.Numcontrato Is Not Null Then
			ERRMSG := 'Alteração não pode ser realizada. O registro já possui contrato gerado. <br> Exclua o contrato e/ou entre em contato com o responsável.';
			Raise_Application_Error(-20105, ad_fnc_formataerro(errmsg));
		End If;
	End If;

	/*  Atualiza o horario de alteração no cabeçalho da solicitação, disparando a validação*/
	Begin
		Update ad_tsfsstc c
			 Set c.dhalter = Sysdate, c.codusu = stp_get_codusulogado, c.origem = 1
		 Where c.codsolst = Nvl(:old.Codsolst, :new.Codsolst);
	Exception
		When Others Then
			errmsg := 'Erro ao atualiza o horario de alteração no cabeçalho da solicitação, disparando a validação. ' ||
								Sqlerrm;
			Raise_Application_Error(-20105, ad_fnc_formataerro(errmsg));
	End;
	--Exception
	--When Others Then
	--ad_set.insere_msglog('Erro ao atualizar cabeçalho da solicitação nro ' || :new.Codsolst);
	--    raise_application_error(-20105, Sqlerrm);
End;
/
