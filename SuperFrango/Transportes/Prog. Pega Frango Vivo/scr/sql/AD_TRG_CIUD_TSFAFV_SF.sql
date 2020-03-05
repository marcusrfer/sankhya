Create Or Replace Trigger AD_TRG_CIUD_TSFAFV_SF
	For Insert Or Update Or Delete On ad_tsfafv
	Compound Trigger

	/* 
  Autor: M. Rangel
  Processo: Pega Frango vivo
  Objetivo: Atualização de status
  */

	gerandoPedido Varchar2(1);

	Before Statement Is
	Begin
		If ad_pkg_pfv.v_GeraPedido Then
			gerandoPedido := 'S';
		Else
			gerandoPedido := 'N';
		End If;
	End Before Statement;

	Before Each Row Is
	Begin
	
		If updating And gerandoPedido = 'N' Then
			If :old.Codveiculo Is Null And :new.Codveiculo Is Not Null And :old.Statusvei Is Null Then
				:new.Statusvei := 'P';
			End If;
		
			If :old.Codveiculo Is Not Null And :new.Codveiculo Is Null Then
				:new.Codparctransp := Null;
				:new.Codmotorista  := Null;
				:new.Statusvei     := Null;
			End If;
		
		End If;
	End Before Each Row;

	After Each Row Is
	Begin
		If updating Then
			Begin
				Update ad_tsfpfv p
					 Set codusu = stp_get_codusulogado, dhalter = Sysdate
				 Where p.nupfv = :new.Nupfv;
			Exception
				When Others Then
					Raise;
			End;
		
			If :new.Statusvei Is Not Null And :new.Codveiculo Is Not Null And gerandoPedido = 'N' Then
				Begin
					Update ad_tsfpfv p
						 Set p.status = 'A'
					 Where p.nupfv = :NEW.Nupfv;
				Exception
					When Others Then
						Raise;
				End;
			End If;
		End If;
	End After Each Row;

End AD_TRG_CIUD_TSFAFV_SF;
/
