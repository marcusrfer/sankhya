create or replace Trigger AD_TRG_BIUD_DRE_FORMULAS_LOG
	After Insert Or Update Or Delete On dre_formulas
	For Each Row
Declare
	v_seqHist Number;
Begin
	/* Autor: Marcus Rangel
  * Processo: DRE
  * Objetivo: Gravar as alterações na tabela de fórmulas
  */

	Begin
		Select Nvl(Max(seqhist), 0)
			Into v_seqHist
			From dre_formulas_log
		 Where codform = Nvl(:new.Codform, :old.Codform);
	Exception
		When Others Then
			Raise;
	End;

	v_seqHist := v_seqHist + 1;

	If inserting Then
		Insert Into dre_formulas_log
			(seqhist, operacao, codusu, dhalter, codform, tipoind, query, base)
		Values
			(v_seqHist, 'INSERT', stp_get_codusulogado, Sysdate, :new.Codform, :new.Tipoind, :new.Query, :new.Base);
	Elsif updating Then
		Insert Into dre_formulas_log
			(seqhist, operacao, codusu, dhalter, codform, tipoind, query, base)
		Values
			(v_seqhist, 'UPDATE NEW VALUES', stp_get_codusulogado, Sysdate, :new.Codform, :new.Tipoind, :new.Query, :new.Base);
	
		Insert Into dre_formulas_log
			(seqhist, operacao, codusu, dhalter, codform, tipoind, query, base)
		Values
			(v_seqhist + 1, 'UPDATE OLD VALUES', stp_get_codusulogado, Sysdate, :old.Codform, :old.Tipoind, :old.Query, :old.Base);
	Elsif deleting Then
		Raise_Application_Error(-20105,
														fc_formatahtml_sf(P_MENSAGEM => 'Fórmulas não podem ser excluídas.',
																							P_MOTIVO   => 'Para garantir o histórico de alterações.',
																							P_SOLUCAO  => 'Cadastre uma nova fórmula e a vincule ao indicador desejado.',
																							P_ERROR    => Sqlerrm));
		/*Insert Into dre_formulas_log
      (operacao, machine, codusu, dhalter, codform, descrfor, tipoind, query, base)
    Values
      ('DELETE', sys_context('USERENV', 'HOST'), stp_get_codusulogado, Sysdate, :old.Codform, :old.Codform, :old.Tipoind,
       :old.Query, :old.Base);*/
	End If;

End;
