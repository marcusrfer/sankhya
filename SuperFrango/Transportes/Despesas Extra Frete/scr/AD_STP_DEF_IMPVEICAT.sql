Create Or Replace Procedure "AD_STP_DEF_IMPVEICAT"(P_CODUSU    Number,
																									 P_IDSESSAO  Varchar2,
																									 P_QTDLINHAS Number,
																									 P_MENSAGEM  Out Varchar2) As
	PARAM_CATEGORIA Varchar2(4000);
	FIELD_NUTABELA  Number;
	FIELD_SEQVEI    Number;
	Errmsg          Varchar2(4000);
	Error Exception;
Begin

	/* Autor: M. Rangel 
  * Processo: Despesas Extras de Frete
  * Objetivo: Realizar a importação de veículo de acordo com a categoria. Disponível na rotina Tabela de preços de despesas extras de frete
  */

	PARAM_CATEGORIA := ACT_TXT_PARAM(P_IDSESSAO, 'CATEGORIA');
	FIELD_NUTABELA  := ACT_INT_FIELD(P_IDSESSAO, 0, 'MASTER_NUTABELA');

	Select Nvl(Max(seqvei), 0) + 1
		Into FIELD_SEQVEI
		From ad_tsfdeftv
	 Where nutabela = FIELD_NUTABELA;

	For c_Vei In (Select codveiculo
									From tgfvei v
								 Where v.ativo = 'S'
									 And Upper(v.categoria) = Upper(PARAM_CATEGORIA))
	Loop
		Insert Into ad_tsfdeftv
			(nutabela, seqvei, codveiculo, valor)
		Values
			(FIELD_NUTABELA, FIELD_SEQVEI, c_vei.codveiculo, 0);
	
		FIELD_SEQVEI := FIELD_SEQVEI + 1;
	
	End Loop;

	P_MENSAGEM := FIELD_SEQVEI || ' Veículos inseridos!';
Exception
	When error Then
		P_MENSAGEM := errmsg;
	When Others Then
		P_MENSAGEM := Sqlerrm;
	
End;
/
