Create Or Replace Procedure "AD_STP_FRE_CALCVLROC_SF"(p_codusu Number, p_idsessao Varchar2, p_qtdlinhas Number,
																											p_mensagem Out Varchar2) As
	v_Codemp     Number;
	v_OrdemCarga Number;
	v_Distancia  Float;
	v_VlrRota    Float;
	v_Recalcula  Boolean;
Begin
	/* Autor: M. Rangel
  * Processo: Frete por Ordem de Carga 
  * Objetivo: Calcular o valor da ordem de carga, botão de ação na tela de ordem de carga.
  */

	If p_qtdlinhas > 1 Then
		p_mensagem := 'Por favor, selecione apenas uma Ordem de Carga por vez!';
		Return;
	End If;

	v_Codemp     := ACT_INT_FIELD(P_IDSESSAO, 1, 'CODEMP');
	v_OrdemCarga := ACT_INT_FIELD(P_IDSESSAO, 1, 'ORDEMCARGA');

	Begin
	
		-- Busca a distância e o valor da tabela de valores
		Select v.distrota, v.vlrrota
			Into v_Distancia, v_VlrRota
			From ad_tsfrfv v
		 Where v.codemp = v_Codemp
			 And v.ordemcarga = v_OrdemCarga;
	
	Exception
		When no_data_found Then
			v_Distancia := 0;
			v_VlrRota   := 0;
	End;

	-- se já existe valor e distância calculadas
	If v_Distancia > 0 Or v_VlrRota > 0 Then
		-- pergunta se deseja recalcular
		v_Recalcula := act_confirmar(p_titulo    => 'Dados existentes',
																 p_texto     => 'Já existem valores calculados para essa Ordem de Carga.\n Deseja recalcular esses valores?',
																 p_chave     => p_idsessao,
																 p_sequencia => 1);
	
		If Not v_Recalcula Then
			p_mensagem := 'Não foi calculado nenhum valor';
			Return;
		End If;
	End If;

	-- verifica se é carona
	If ad_pkg_fre.check_carona(v_codemp, v_ordemcarga) Then
		ad_pkg_fre.set_dist_vlr_carona(v_codemp, v_ordemcarga);
	Else
		ad_pkg_fre.set_distancia_rota(v_codemp, v_ordemcarga);
		ad_pkg_fre.set_valor_rota(v_codemp, v_OrdemCarga);
	End If;

	p_mensagem := 'Operação realizada com sucesso.';

End;
/
