Create Or Replace Procedure "AD_STP_RENEGACERTO"(pCodUsu Number, pIdSessao Varchar2, pQtdLinhas Number,
																								 pMensagem Out Varchar2) As
	pDtVenc  Date;
	vNuChave Number;
	vTabela  Varchar2(20);
	Error Exception;
Begin
	/*
  Autor: Marcus Rangel
  Dt. Cria��o: 31/08/2016
  Objetivo: Atender o processo de autoriza��o de pagamento de acerto. Alterar data de vencimento do t�tulo.                                                                       
  */
	pDtVenc := ACT_DTA_PARAM(pIdSessao, 'DTVENC');

	For I In 1 .. pQtdLinhas
	Loop
		vNuChave := ACT_INT_FIELD(pIdSessao, I, 'NUCHAVE');
		vTabela  := act_txt_field(pIdSessao, I, 'TABELA');
	
		If vtabela <> 'TGFFIN' Then
			pMensagem := 'Somente libera��es com financeiro gerado podem alterar a data de vencimento.';
		
			Raise error;
		End If;
	
		Update tgffin Set dtvenc = pDtVenc Where nufin = vNuChave;
		If Sql%Rowcount = 0 Then
			pMensagem := 'O lan�amento ' || vNuChave || ' n�o foi encontrado no financeiro.';
			Raise error;
		End If;
	
	End Loop;

	pMensagem := 'Data de vencimento alterada para ' || to_char(pdtvenc, 'dd/mm/yyyy') || ', ' || vNuChave;

Exception
	When error Then
		Return;
	When Others Then
		pMensagem := 'Erro ao atualizar a data de vencimento do t�tulo ' || vNuChave || '. ' || Sqlerrm;
End;
/
