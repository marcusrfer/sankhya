Create Or Replace Procedure "AD_STP_FRE_COORDPARC_SF"(p_CodUsu Number, p_idsessao Varchar2, p_qtdlinhas Number,
																											p_mensagem Out Varchar2) As
	v_CodParc Number;
	v_Coord   Varchar2(30);
	v_Link    Varchar2(1000);
	v_erros   Int := 0;
	v_sucess  Int := 0;
	errmsg    Varchar2(4000);
	error Exception;
Begin

	/* Autor: M. Rangel
  * Processo: Frete por Ordem de Carga
  * Objetivo: Buscar a localização do parceiro para o cálculo da distância da rota, 
              ação "Pesquisa Coordenadas" na tela de cadastro do parceiro
  */

	For I In 1 .. P_QTDLINHAS
	Loop
		v_CodParc := ACT_INT_FIELD(P_IDSESSAO, I, 'CODPARC');
	
		ad_pkg_fre.atualiza_coord_parc(v_CodParc, v_coord, v_link, errmsg);
	
		If P_QTDLINHAS = 1 And errmsg Is Not Null Then
			Raise error;
		Elsif P_QTDLINHAS > 1 And errmsg Is Not Null Then
			v_erros := v_erros + 1;
		Elsif p_qtdlinhas > 1 And errmsg Is Null Then
			v_sucess := v_sucess + 1;
		End If;
	
	End Loop;

	If p_qtdlinhas = 1 Then
		p_Mensagem := '<a align="center" target="_blank" href="' || v_Link ||
									'">Localização encontrada com sucesso.<br>Lat/Lng:<font color="#0000FF">' || v_Coord || '</font></a>';
	Elsif p_qtdlinhas > 1 And v_erros < 1 Then
		p_Mensagem := 'Operação realizada com sucesso';
	Elsif p_qtdlinhas > 1 And v_erros > 1 Then
		p_mensagem := 'Operação concluída, mas nem todos obtiveram sucesso.<br>' || '(' || p_qtdlinhas || ' selecionados, ' ||
									v_sucess || ' processados com sucesso, ' || v_erros || ' processados com erro)';
	End If;

Exception
	When error Then
		P_MENSAGEM := 'Não foi possível encontrar a posição geográfica. Verifique o endereço cadastrado.';
	When Others Then
		p_Mensagem := Sqlerrm;
End;
/
