Create Or Replace Trigger AD_TRG_BIUD_DRE_CADINDPAD_LOG
	Before Insert Or Update Or Delete On dre_CADINDPAD
	For Each Row
Declare
	host_name Varchar2(40);
Begin

	Select host_name
		Into host_name
		From v$instance;

	If inserting Then
		Insert Into dre_cadindpad_log
			(operacao, machine, codusu, dhalter, codindpad, descrindpad, ativo, totalizador)
		Values
			('INSERT', host_name, stp_get_codusulogado, Sysdate, :new.Codindpad, :new.Descrindpad, :New.Ativo, :new.Totalizador);
	Elsif updating Then
	
		Insert Into dre_cadindpad_log
			(operacao, machine, codusu, dhalter, codindpad, descrindpad, ativo, totalizador)
		Values
			('UPDATE NEW VALUES', host_name, stp_get_codusulogado, Sysdate, :new.Codindpad, :new.Descrindpad, :New.Ativo,
			 :new.Totalizador);
	
		Insert Into dre_cadindpad_log
			(operacao, machine, codusu, dhalter, codindpad, descrindpad, ativo, totalizador)
		Values
			('UPDATE OLD VALUES', host_name, stp_get_codusulogado, Sysdate, :old.Codindpad, :old.Descrindpad, :old.Ativo,
			 :old.Totalizador);
	
	Elsif deleting Then
	
		Insert Into dre_cadindpad_log
			(operacao, machine, codusu, dhalter, codindpad, descrindpad, ativo, totalizador)
		Values
			('UPDATE OLD VALUES', host_name, stp_get_codusulogado, Sysdate, :old.Codindpad, :old.Descrindpad, :old.Ativo,
			 :old.Totalizador);
	
	End If;

End AD_TRG_BIUD_DRE_CADINDPAD_LOG;
/
