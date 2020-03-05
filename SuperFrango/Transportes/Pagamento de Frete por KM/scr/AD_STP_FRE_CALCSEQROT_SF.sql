Create Or Replace Procedure "AD_STP_FRE_CALCSEQROT_SF"(p_codusu Number, p_idsessao Varchar2, p_qtdlinhas Number,
																											 p_mensagem Out Varchar2) As
	v_codemp     Number;
	v_ordemcarga Number;
	Confirma     Boolean;
	Errmsg       Varchar2(4000);
	Error Exception;

Begin
	/* 
  Autor: M. Rangel
  Processo: Frete por Ordem de Carga
  Objetivo: Calcular a sequencia da rota, botão de ação na tela de Ordem de Carga.
  */

	If p_qtdlinhas > 1 Then
		errmsg := 'Selecione apenas 1 Ordem de Carga';
		Raise error;
	End If;

	v_codemp     := act_int_field(p_idsessao, 1, 'CODEMP');
	v_ordemcarga := act_int_field(p_idsessao, 1, 'ORDEMCARGA');

	confirma := act_confirmar(p_titulo    => 'Atenção',
														p_texto     => 'Somente as notas com sequência iguais a 0 (zero) serão atualizadas.<br>Deseja Continuar?',
														p_chave     => p_idsessao,
														p_sequencia => 1);

	If confirma Then
	
		ad_pkg_fre.set_sequencia_rota(p_codemp => v_codemp, p_ordemcarga => v_ordemcarga, p_errmsg => Errmsg);
		If Errmsg Is Not Null Then
			Raise error;
		End If;
	
		p_mensagem := 'Sequência atualizada com Sucesso!!!';
	
	Else
		p_mensagem := 'Operação cancelada com sucesso!';
	End If;

Exception
	When error Then
		p_mensagem := errmsg;
End;
/
