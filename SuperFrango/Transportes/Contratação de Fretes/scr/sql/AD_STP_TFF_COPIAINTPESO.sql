Create Or Replace Procedure "AD_STP_TFF_COPIAINTPESO"(P_CODUSU    Number,
																											P_IDSESSAO  Varchar2,
																											P_QTDLINHAS Number,
																											P_MENSAGEM  Out Varchar2) As
	p_Nutab Varchar2(4000);
	p_NuReg Varchar2(4000);
	vNuTab  Number;
	vNuRff  Number;
	vNuPff  Number;
Begin
	/*
   * Autor: Marcus Rangel
   * Processo: Tabela de preços de frete
   * Objetivo: Copiar as faixas de peso e seus valores
  */

	p_Nutab := ACT_TXT_PARAM(P_IDSESSAO, 'NUTAB');
	p_NuReg := ACT_TXT_PARAM(P_IDSESSAO, 'NUREG');
	vNuTab  := ACT_INT_FIELD(P_IDSESSAO, 0, 'NUTAB');
	vNuRff  := ACT_INT_FIELD(P_IDSESSAO, 0, 'MASTER_NURFF');
	vNuPff  := ACT_INT_FIELD(P_IDSESSAO, 0, 'MASTER_NUPFF');

	For P In (Select nupff, faixaini, faixafim, pff.valor, pff.vlrexc
							From ad_tsfpff pff
						 Where pff.nutab = P_NUTAB
							 And pff.nurff = p_NuReg
						 Order By 1)
	Loop
		Insert Into ad_tsfpff
			(nutab, nurff, nupff, faixaini, faixafim, valor, vlrexc)
		Values
			(vNuTab, vNuRff, p.nupff, p.faixaini, p.faixafim, p.valor, p.vlrexc);
	End Loop;
	P_MENSAGEM := 'Registros copiados.';
End;
/
