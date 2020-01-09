Create Or Replace Trigger AD_TRG_BIUD_DRE_CADINDGER_LOG
	Before Insert Or Update Or Delete On DRE_CADINDGER
	For Each Row
Declare
	host_name Varchar2(40);
Begin
	Select host_name
		Into host_name
		From v$instance;

	If inserting Then
		Insert Into dre_cadindger_log
			(operacao, machine, codusu, dhalter, codindger, descrindger)
		Values
			('INSERT', host_name, stp_get_codusulogado, Sysdate, :new.CODINDGER, :new.DESCRINDGER);
	
	Elsif updating Then
	
		Insert Into dre_cadindger_log
			(operacao, machine, codusu, dhalter, codindger, descrindger)
		Values
			('UPDATE NEW VALUES', host_name, stp_get_codusulogado, Sysdate, :new.CODINDGER, :new.DESCRINDGER);
	
		Insert Into dre_cadindger_log
			(operacao, machine, codusu, dhalter, codindger, descrindger)
		Values
			('UPDATE OLD VALUES', host_name, stp_get_codusulogado, Sysdate, :old.CODINDGER, :old.DESCRINDGER);
	
	Elsif deleting Then
	
		Insert Into dre_cadindger_log
			(operacao, machine, codusu, dhalter, codindger, descrindger)
		Values
			('UPDATE OLD VALUES', host_name, stp_get_codusulogado, Sysdate, :old.CODINDGER, :old.DESCRINDGER);
	
	End If;

End AD_TRG_BIUD_DRE_CADINDGER_LOG;
/
