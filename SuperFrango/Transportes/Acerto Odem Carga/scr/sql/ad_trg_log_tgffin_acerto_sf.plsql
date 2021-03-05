Create Or Replace Trigger AD_TRG_LOG_TGFFIN_ACERTO_SF
	Before Insert Or Update Or Delete On tgffin
	For Each Row
Declare
	v_AprovAcerto Char(1);
Begin

	Begin
		Select t.ad_aprovbaixaacerto
			Into v_AprovAcerto
			From tgftop t
		 Where t.codtipoper = nvl(:new.codtipoper, :old.codtipoper)
			 And t.dhalter = nvl(:new.dhtipoper, :old.dhtipoper);
	Exception
		When no_data_found Then
			v_AprovAcerto := 'N';
		When Others Then
			v_AprovAcerto := 'N';
	End;

	/* sai se não encontra */
	If nvl(v_AprovAcerto, 'N') = 'N' Then
		Return;
	End If;

	If inserting Then
		Insert Into ad_logacerto
		Values
			(Sysdate, 'Insert', :new.nufin, :new.recdesp, :new.provisao, :new.codtipoper, :new.dhbaixa, :new.codtipoperbaixa,
			 :new.vlrdesdob, :new.codctabcoint);
	End If;

	If updating Then
		Insert Into ad_logacerto
		Values
			(Sysdate, 'Update Old', :old.nufin, :old.recdesp, :old.provisao, :old.codtipoper, :old.dhbaixa,
			 :old.codtipoperbaixa, :old.vlrdesdob, :old.codctabcoint);
	
		Insert Into ad_logacerto
		Values
			(Sysdate, 'Update New', :new.nufin, :new.recdesp, :new.provisao, :new.codtipoper, :new.dhbaixa,
			 :new.codtipoperbaixa, :new.vlrdesdob, :new.codctabcoint);
	
	End If;

	If deleting Then
		Insert Into ad_logacerto
		Values
			(Sysdate, 'Delete', :old.nufin, :old.recdesp, :old.provisao, :old.codtipoper, :old.dhbaixa, :old.codtipoperbaixa,
			 :old.vlrdesdob, :old.codctabcoint);
	End If;
Exception
	When Others Then
		Null;
End;
/
