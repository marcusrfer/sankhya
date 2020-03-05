Create Or Replace Procedure "AD_STP_ROC_VERPESO_SF"(P_CODUSU    Number,
																										P_IDSESSAO  Varchar2,
																										P_QTDLINHAS Number,
																										P_MENSAGEM  Out Varchar2) As
	FIELD_NUMROCC Number;
	FIELD_NUMROCP Number;
	peso          Float := 0;
	pesoSel       Float := 0;
	pesoTot       Float := 0;
	pesoResidual  Float;
	qtdSel        Int := 0;
	qtdTot        Int;
	qtdRes        Int;
Begin

	/* 
  Autor: M. Rangel
  Processo: Sequencia pela distância
  Objetivo: Botão de ação "Ver peso dos Selecionados" na tela de sequenciamento por distância
            Exibe na tela o peso total das linhas selecionadas.
  */

	For I In 1 .. P_QTDLINHAS
	Loop
		FIELD_NUMROCC := ACT_INT_FIELD(P_IDSESSAO, I, 'NUMROCC');
		FIELD_NUMROCP := ACT_INT_FIELD(P_IDSESSAO, I, 'NUMROCP');
	
		Select peso
			Into peso
			From ad_tsfrocp
		 Where numrocc = FIELD_NUMROCC
			 And numrocp = FIELD_NUMROCP;
	
		pesoSel := pesoSel + peso;
		qtdSel  := QtdSel + 1;
	
	End Loop;

	Select Sum(peso), Count(*)
		Into pesoTot, qtdTot
		From ad_tsfrocp
	 Where numrocc = FIELD_NUMROCC;

	pesoResidual := pesoTot - pesoSel;
	qtdRes       := qtdTot - qtdSel;

	p_mensagem := 'Total: <b>' || Ltrim(ad_get.Formatanumero(pesotot)) || '</b> kg | Qtd: <b>' ||
								qtdTot || '</b><br>' || 'Selecionados: <b>' || Ltrim(ad_get.Formatanumero(pesoSel)) ||
								'</b> kg | Qtd: <b>' || qtdSel || '</b><br>' || 'Residual: <b>' ||
								Ltrim(ad_get.Formatanumero(pesoResidual)) || '</b> kg | Qtd: <b>' || qtdRes ||
								'</b>';

End;
/
