Create Or Replace Procedure "AD_STP_FRE_CALCFRETEFORM_SF"(p_codusu Number, p_idsessao Varchar2,
																													p_qtdlinhas Number, p_mensagem Out Varchar2) As
	c tgfcab%Rowtype;
Begin
	/* 
  * Autor: M. Rangel
  * Processo: Calculo de Frete 
  * Objetivo: Realizar o cálculo de frete para ordens de carga que usam o TIPCALCFRETE = 1, 
              até o momento, somente este tipo está contemplado.
  */
	For i In 1 .. p_qtdlinhas
	Loop
		c.nunota := act_int_field(p_idsessao, i, 'NUNOTA');
	
		Select *
			Into c
			From tgfcab
		 Where nunota = c.nunota;
	
		ad_pkg_fre.set_vlrfrete_formula(p_Nunota     => c.nunota,
																		p_codemp     => c.codemp,
																		p_codparc    => c.codparc,
																		p_OrdemCarga => c.ordemcarga,
																		p_codveiculo => c.codveiculo,
																		p_errmsg     => p_mensagem);
	
		If p_mensagem Is Not Null Then
			Return;
		End If;
	End Loop;

	p_mensagem := 'Frete calculado com sucesso!';

End;
/
