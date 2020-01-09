Create Or Replace Trigger AD_TRG_AIUD_FORINDPAD_SF
	After Insert Or Update Or Delete On DRE_FORINDPAD
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
		Insert Into dre_forindpad_log
			(operacao, machine, codusu, dhalter, codindpad, codforpad, formindpad, dhvigor)
		Values
			('Insert', host_name, stp_get_codusulogado, Sysdate, :new.Codindpad, :new.Codforpad, :new.Formindpad, :new.Dhvigor);
	Elsif updating Then
		Insert Into dre_forindpad_log
			(operacao, machine, codusu, dhalter, codindpad, codforpad, formindpad, dhvigor)
		Values
			('Update - New values', host_name, stp_get_codusulogado, Sysdate, :new.Codindpad, :new.Codforpad, :new.Formindpad,
			 :new.Dhvigor);
	
		Insert Into dre_forindpad_log
			(operacao, machine, codusu, dhalter, codindpad, codforpad, formindpad, dhvigor)
		Values
			('Update - Old Values', host_name, stp_get_codusulogado, Sysdate, :old.Codindpad, :old.Codforpad, :old.Formindpad,
			 :old.Dhvigor);
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
