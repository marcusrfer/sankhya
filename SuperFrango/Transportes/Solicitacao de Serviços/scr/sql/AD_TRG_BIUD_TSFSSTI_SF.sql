Create Or Replace Trigger AD_TRG_BIUD_TSFSSTI_SF
	Before Insert Or Update Or Delete On SANKHYA.AD_TSFSSTI
	For Each Row
Declare
	ErrMsg       Varchar2(4000);
	v_TemServ    Int := 0;
	v_TemServFat Int := 0;
Begin

	/*****************************************************************************
  Rotina: Solicitação de Serviços de Transporte
  Dt. Criação: 2811/2016
  Autor: Marcus Rangel
  Obejtivo: Efetuar o controle de alteração baseados no status das solicitações.
  *******************************************************************************/

	If updating Then
	
		Select Count(*)
			Into v_temserv
			From ad_tsfsstm m
		 Where m.codsolst = :new.Codsolst
					--And m.codserv = :new.Codserv
			 And m.nussti = :new.Nussti;
	
		Select Count(*)
			Into v_temservFat
			From ad_tsfsstm m
		 Where m.codsolst = :new.Codsolst
					--And m.codserv = :new.Codserv
			 And m.nussti = :new.Nussti
			 And Nvl(m.numcontrato, 0) <> 0;
	
		/* If :old.Numcontrato Is Not Null And :new.Numcontrato Is Not Null Then
      ERRMSG := 'Alteração não pode ser realizada. O registro já possui contrato gerado. Exclua o contrato e/ou entre em contato com o responsável.';
      Raise_Application_Error(-20105, ad_fnc_formataerro(errmsg));
    End If;*/
	
		/*   If v_temservfat <> 0 Then
      errmsg := 'Já existem máquinas/equipamentos/serviços que geraram contratos, alteração proibida';
      Raise_Application_Error(-20105, ad_fnc_formataerro(errmsg));
    End If;
    */
	
		If (updating('VLRUNIT') And :old.Vlrunit <> :new.Vlrunit) Or
			 (updating('VLRTOT') And :old.Vlrtot <> :new.Vlrtot) Then
			If Nvl(:new.Automatico, 'N') = 'N' Then
				-- se atualização possui sub serviços, se tiver, bloqueia e informa
				If v_temserv <> 0 Then
					errmsg := '<b>Alteração proibida!</b> O valor do serviço está sendo composto pela <u>soma dos valores dos equipamentos.</u>';
					Raise_Application_Error(-20105, ad_fnc_formataerro(errmsg));
				End If;
			End If;
		End If;
	
	End If;

	Begin
		Update ad_tsfsstc c
			 Set c.dhalter = Sysdate, c.codusu = stp_get_codusulogado, c.origem = 1
		 Where c.codsolst = Nvl(:old.Codsolst, :new.Codsolst);
	Exception
		When Others Then
			errmsg := '(' || stp_get_codusulogado ||
								') Erro ao atulizar os dados no cabeçalho da solicitação. ' || Sqlerrm;
			Raise_Application_Error(-20105, errmsg);
	End;

	-- sempre que sair, altera para N, para o controle de origem da alteaçao
	If Not deleting Then
		:new.Automatico := 'N';
	End If;

End;
/
