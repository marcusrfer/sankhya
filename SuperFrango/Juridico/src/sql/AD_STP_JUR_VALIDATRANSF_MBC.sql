Create Or Replace Procedure "AD_STP_JUR_VALIDATRANSF_MBC"(p_tipoevento Int,
																													-- identifica o tipo de evento
																													p_idsessao Varchar2,
																													-- identificador da execução. serve para buscar informações dos campos da execução.
																													p_codusu Int
																													-- código do usuário logado
																													) As
	before_insert Int;
	after_insert  Int;
	before_delete Int;
	after_delete  Int;
	before_update Int;
	after_update  Int;
	before_commit Int;

	r_mbc  ad_jurmbctr%Rowtype;
	errmsg Varchar2(4000);
Begin
	before_insert := 0;
	after_insert  := 1;
	before_delete := 2;
	after_delete  := 3;
	before_update := 4;
	after_update  := 5;
	before_commit := 10;

	/*******************************************************************************
     é possível obter o valor dos campos através das functions:
     
    evp_get_campo_dta(p_idsessao, 'NOMECAMPO') -- para campos de data
    evp_get_campo_int(p_idsessao, 'NOMECAMPO') -- para campos numéricos inteiros
    evp_get_campo_dec(p_idsessao, 'NOMECAMPO') -- para campos numéricos decimais
    evp_get_campo_texto(p_idsessao, 'NOMECAMPO')   -- para campos texto
    
    o primeiro argumento é uma chave para esta execução. o segundo é o nome do campo.
    
    para os eventos before update, before insert e after delete todos os campos estarão disponíveis.
    para os demais, somente os campos que pertencem à pk
    
    * os campos clob/text serão enviados convertidos para varchar(4000)
    
    também é possível alterar o valor de um campo através das stored procedures:
    
    evp_set_campo_dta(p_idsessao,  'NOMECAMPO', valor) -- valor deve ser uma data
    evp_set_campo_int(p_idsessao,  'NOMECAMPO', valor) -- valor deve ser um número inteiro
    evp_set_campo_dec(p_idsessao,  'NOMECAMPO', valor) -- valor deve ser um número decimal
    evp_set_campo_texto(p_idsessao,  'NOMECAMPO', valor) -- valor deve ser um texto
  ********************************************************************************/
	r_mbc.nujurmbc   := evp_get_campo_int(p_idsessao, 'NUJURMBC');
	r_mbc.nujurmbctr := evp_get_campo_int(p_idsessao, 'NUJURMBCTR');

	Select *
		Into r_mbc
		From ad_jurmbctr
	 Where nujurmbc = r_mbc.nujurmbc
		 And nujurmbctr = r_mbc.nujurmbctr;

	If p_tipoevento = before_delete Then
		If r_mbc.numtransf Is Not Null Then
			errmsg := ad_fnc_formataerro('Não é possível excluir o lançamento. ' ||
																	 'Existe uma transferência gerada a partir deste lançamento. ' ||
																	 'Entre em contato com a área responsável para avaliar a possível exclusão da transferência.');
		
			/*      (P_MENSAGEM => 'Não é possível excluir o lançamento.',
      P_MOTIVO   => 'Existe uma transferência gerada a partir deste lançamento',
      P_SOLUCAO  => 'Entre em contato com a área responsável para avaliar a possível exclusão da transferência.');*/
		
			Raise_Application_Error(-20105, errmsg);
		
		End If;
	End If;

End;
/
