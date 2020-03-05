Create Or Replace Procedure "AD_STP_DEF_IMPORTREG"(P_CODUSU    Number,
																									 P_IDSESSAO  Varchar2,
																									 P_QTDLINHAS Number,
																									 P_MENSAGEM  Out Varchar2) As
	p_Codregini Varchar2(4000);
	p_CodRegFin Varchar2(4000);
	v_NuTabela  Number;
	v_SeqReg    Number;
	Errmsg      Varchar2(4000);
	Error Exception;
Begin

	/* Autor: M. Rangel 
  * Processo: Despesas Extras de Frete
  * Objetivo: Realizar a importação das regiões de acordo com o intervalo informado nos parâmetros.
  * Disponível na rotina Tabela de preços de despesas extras de frete.
  */

	p_Codregini := ACT_TXT_PARAM(P_IDSESSAO, 'CODREGINI');
	p_CodRegFin := ACT_TXT_PARAM(P_IDSESSAO, 'CODREGFIN');

	For I In 1 .. P_QTDLINHAS
	Loop
		v_NuTabela := ACT_INT_FIELD(P_IDSESSAO, 1, 'NUTABELA');
		Select Nvl(Max(seqreg), 0) + 1
			Into v_SeqReg
			From ad_tsfdeftr r
		 Where r.nutabela = v_NuTabela;
	
		For c_Reg In (Select *
										From tsireg r
									 Where r.ativa = 'S'
										 And r.analitica = 'S'
										 And r.codreg Between p_codregini And p_codregfin)
		Loop
			Begin
				Insert Into ad_tsfdeftr
					(nutabela, seqreg, codreg, valor)
				Values
					(v_NuTabela, v_SeqReg, c_reg.codreg, 0);
			Exception
				When Others Then
					Errmsg := 'Erro ao inserir as regiões. \n \n' || Sqlerrm;
			End;
			v_SeqReg := v_SeqReg + 1;
		End Loop;
	End Loop;
Exception
	When error Then
		P_MENSAGEM := errmsg;
	When Others Then
		P_MENSAGEM := Sqlerrm;
End;
/
