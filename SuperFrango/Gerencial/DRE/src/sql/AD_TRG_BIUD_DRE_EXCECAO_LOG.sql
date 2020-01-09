Create Or Replace Trigger AD_TRG_BIUD_DRE_EXCECAO_LOG
	Before Insert Or Update Or Delete On dre_excecoes
	For Each Row
Declare
	host_name Varchar2(100);
Begin

	Select host_name
		Into host_name
		From v$instance;

	If inserting Then
	
		Insert Into dre_excecoes_log
			(operacao, machine, codusu, dhalter, codexc, descrexc, codemp, codune, codgrupoprod, codprod,
			 coduf, tipoexc, tipovlr, formexc, codindpad, vlrperc, dtinclusao, codusuinc, ativo)
		Values
			('INSERT', host_name, stp_get_codusulogado(), Sysdate, :new.Codexc, :New.Descrexc,
			 :New.Codemp, :new.Codune, :new.Codgrupoprod, :New.Codprod, :new.Coduf, :new.Tipoexc,
			 :new.Tipovlr, :new.Formexc, :new.Codindpad, :new.Vlrperc, :new.Dtinclusao, :new.Codusuinc,
			 :new.Ativo);
	
	Elsif updating Then
	
		Insert Into dre_excecoes_log
			(operacao, machine, codusu, dhalter, codexc, descrexc, codemp, codune, codgrupoprod, codprod,
			 coduf, tipoexc, tipovlr, formexc, codindpad, vlrperc, dtinclusao, codusuinc, ativo)
		Values
			('UPDATE NEW VALUES', host_name, stp_get_codusulogado(), Sysdate, :new.Codexc, :New.Descrexc,
			 :New.Codemp, :new.Codune, :new.Codgrupoprod, :New.Codprod, :new.Coduf, :new.Tipoexc,
			 :new.Tipovlr, :new.Formexc, :new.Codindpad, :new.Vlrperc, :new.Dtinclusao, :new.Codusuinc,
			 :new.Ativo);
	
		Insert Into dre_excecoes_log
			(operacao, machine, codusu, dhalter, codexc, descrexc, codemp, codune, codgrupoprod, codprod,
			 coduf, tipoexc, tipovlr, formexc, codindpad, vlrperc, dtinclusao, codusuinc, ativo)
		Values
			('UPDATE OLD VALUES', host_name, stp_get_codusulogado(), Sysdate, :old.Codexc, :OLD.Descrexc,
			 :OLd.Codemp, :old.Codune, :old.Codgrupoprod, :New.Codprod, :old.Coduf, :old.Tipoexc,
			 :old.Tipovlr, :old.Formexc, :old.Codindpad, :old.Vlrperc, :old.Dtinclusao, :old.Codusuinc,
			 :old.Ativo);
	
	Elsif deleting Then
	
		Insert Into dre_excecoes_log
			(operacao, machine, codusu, dhalter, codexc, descrexc, codemp, codune, codgrupoprod, codprod,
			 coduf, tipoexc, tipovlr, formexc, codindpad, vlrperc, dtinclusao, codusuinc, ativo)
		Values
			('DELETE', host_name, stp_get_codusulogado(), Sysdate, :old.Codexc, :OLD.Descrexc,
			 :OLd.Codemp, :old.Codune, :old.Codgrupoprod, :old.Codprod, :old.Coduf, :old.Tipoexc,
			 :old.Tipovlr, :old.Formexc, :old.Codindpad, :old.Vlrperc, :old.Dtinclusao, :old.Codusuinc,
			 :old.Ativo);
	
	End If;

End AD_TRG_BIUD_DRE_EXCECAO_LOG;
/
