Create Or Replace Procedure "AD_STP_CRIABASE_ESTGE_SF"(p_codusu    Number,
																																																							p_idsessao  Varchar2,
																																																							p_qtdlinhas Number,
																																																							p_mensagem  Out Varchar2) As
		p_dtini      Date;
		p_dtfin      Date;
		p_codprod    Varchar2(4000);
		field_codeee Number;
Begin

		/* 
  * Dt. Criação: 07/03/2019
  * Autor: M. Rangel
  * Processo: Estoque Estratégico 
  * Objetivo: Botão de ação que realiza o cálculo dos indicadores no período
  */

		p_dtini   := act_dta_param(p_idsessao, 'DTINI');
		p_dtfin   := act_dta_param(p_idsessao, 'DTFIN');
		p_codprod := act_txt_param(p_idsessao, 'CODPROD');

		ad_pkg_est.set_base_est(p_dtini, p_dtfin, p_codprod, Null, Null);

		p_mensagem := 'Valores calculados com sucesso!';

Exception
		When Others Then
				p_mensagem := 'Erro ao calcular os valores - ' || Sqlerrm;
		
End;
/
