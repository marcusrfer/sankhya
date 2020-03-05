Create Or Replace Procedure "AD_STP_RKM_VALSTATUS_SF"(p_tipoevento Int,
                                                      p_idsessao   Varchar2,
                                                      p_codusu     Int) As
  before_insert Int;
  after_insert  Int;
  before_delete Int;
  after_delete  Int;
  before_update Int;
  after_update  Int;
  before_commit Int;
  r             ad_tsfrkmc%Rowtype;
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

  r.nureemb := evp_get_campo_int(p_idsessao, 'NUREEMB');

  Begin
    Select *
      Into r
      From ad_tsfrkmc
     Where nureemb = r.nureemb;
  Exception
    When no_data_found Then
      Raise_Application_Error(-20105, 'Não capturou o número do reembolso');
    When Others Then
      Raise_Application_Error(-20105, Sqlerrm);
  End;

  If p_tipoevento = before_update Then
  
    If r.status <> 'P' Then
      Raise_Application_Error(-20105,
                              'reembolsos confirmados ou aguardando liberação não podem ser alterados!!!');
    End If;
  
  End If;

End;
/
