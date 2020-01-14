Create Or Replace Procedure "AD_STP_CAP_VALRATEIO"(P_CODUSU    Number,
																									 P_IDSESSAO  Varchar2,
																									 P_QTDLINHAS Number,
																									 P_MENSAGEM  Out Varchar2) As
	v_NuAcerto Number;
	Error Exception;
Begin
	/*
  * Autor: Marcus Rangel
  * Processo: Acerto de Carro de apoio
  * Objetivo: Realizar correções nos lançamentos contidos na aba de rateio
  */

	For I In 1 .. P_QTDLINHAS
	Loop
		v_NuAcerto := ACT_INT_FIELD(P_IDSESSAO, I, 'NUACERTO');
	
		For cur_Rat In (Select nuap, nuacerto, seqacertodia
											From ad_diaacertotransp
										 Where nuacerto = v_NuAcerto)
		Loop
		
			ad_pkg_cap.insere_rateio_acerto(p_nroagend  => cur_rat.nuap,
																			p_nroacerto => cur_rat.nuacerto,
																			p_seqacerto => cur_rat.seqacertodia,
																			p_errmsg    => P_MENSAGEM);
		
		End Loop cur_rat;
	End Loop I;
	P_MENSAGEM := 'Revalidação concluída com sucesso!!!';
Exception
	When error Then
		Null;
	When Others Then
		P_MENSAGEM := Sqlerrm;
End;
/
