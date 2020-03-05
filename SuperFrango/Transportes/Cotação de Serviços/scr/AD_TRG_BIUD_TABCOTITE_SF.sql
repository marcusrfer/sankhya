Create Or Replace Trigger AD_TRG_BIUD_TABCOTITE_SF
	Before Insert Or Update Or Delete On AD_TABCOTITE
	For Each Row
Begin
	/* Autor: M.Rangel
  * Processo: Cotação de serviços de transporte
  * Objetivo: Ao atualizar, dispara a atualização do cabeçalho, dependendo do status,
  * a operação prossegue ou não
  */

	If inserting Or updating Or deleting Then
		Update ad_tabcotcab c
			 Set c.dtalter = Sysdate
		 Where numcotacao = Nvl(:new.Numcotacao, :old.Numcotacao);
	End If;

End AD_TRG_BIUD_TABCOTITE_SE;
/
