Create Or Replace Procedure "AD_STP_TFF_SHOWMEMO"(P_CODUSU    Number,
																									P_IDSESSAO  Varchar2,
																									P_QTDLINHAS Number,
																									P_MENSAGEM  Out Varchar2) As
	v_Nunota Number;
Begin
	/* Autor: M.Rangel
  * Processo: C�lculo de Frete FOB
  * Objetivo: Exibir a mem�ria de c�lculo no dashboard de acomapanhamento
  * da varia��o entre o sugerido e o realizado
  */
	For I In 1 .. P_QTDLINHAS
	Loop
		v_Nunota   := ACT_INT_FIELD(P_IDSESSAO, I, 'NUNOTA');
		p_mensagem := ad_pkg_fob.show_memo_calculo(v_Nunota, Null);
	End Loop;

End;
/
