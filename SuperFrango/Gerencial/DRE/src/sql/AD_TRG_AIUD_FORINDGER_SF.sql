Create Or Replace Trigger AD_TRG_AIUD_FORINDGER_SF
	After Insert Or Update Or Delete On DRE_FORINDGER
	For Each Row
Declare
	host_name Varchar2(40);
Begin
	/* Autor: M. Rangel
  * Processo: DRE
  * Objetivo: Armazenar o lastro de alterações nas fórmulas
  */
	Select host_name
		Into host_name
		From v$instance;

	If inserting Then
		Insert Into dre_forindger_log
			(operacao, machine, codusu, dhalter, codindger, codforger, sigla, codemp, codune, coduf, formindger, clacus, clacuscont,
			 codform, dhvigor)
		Values
			('Insert', host_name, stp_get_codusulogado, Sysdate, :new.Codindger, :new.Codforger, :new.Sigla, :new.Codemp, :new.codune,
			 :new.coduf, :new.Formindger, :new.Clacus, :new.Clacuscont, :new.Codform, :new.Dhvigor);
	Elsif updating Then
		Insert Into dre_forindger_log
			(operacao, machine, codusu, dhalter, codindger, codforger, sigla, codemp, codune, coduf, formindger, clacus, clacuscont,
			 codform, dhvigor)
		Values
			('Update - New Values', host_name, stp_get_codusulogado, Sysdate, :new.Codindger, :new.Codforger, :new.Sigla, :new.Codemp,
			 :new.codune, :new.coduf, :new.Formindger, :new.Clacus, :new.Clacuscont, :new.Codform, :new.Dhvigor);
	
		Insert Into dre_forindger_log
			(operacao, machine, codusu, dhalter, codindger, codforger, sigla, codemp, codune, coduf, formindger, clacus, clacuscont,
			 codform, dhvigor)
		Values
			('Update - Old Values', host_name, stp_get_codusulogado, Sysdate, :old.Codindger, :old.Codforger, :old.Sigla, :old.Codemp,
			 :old.codune, :old.coduf, :old.Formindger, :old.Clacus, :old.Clacuscont, :old.Codform, :old.Dhvigor);
	
	Elsif deleting Then
		-- a ideia é que não se exclua nada dessa tabela
		Raise_Application_Error(-20105,
														fc_formatahtml_sf(P_MENSAGEM => 'Não é possível excluir lançamentos dessa rotina',
																							P_MOTIVO   => 'Para garantir que a lastro de alterações não seja perdido.',
																							P_SOLUCAO  => 'Insira um novo registro.',
																							P_ERROR    => Sqlerrm));
	End If;

End AD_TRG_AIUD_FORINDPAD_SF;
/
