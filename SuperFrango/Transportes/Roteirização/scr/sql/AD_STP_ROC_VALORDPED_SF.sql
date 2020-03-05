Create Or Replace Procedure "AD_STP_ROC_VALORDPED_SF"(p_tipoevento Int,
                                                      p_idsessao   Varchar2,
                                                      p_codusu     Int) As
  before_insert Int;
  after_insert  Int;
  before_delete Int;
  after_delete  Int;
  before_update Int;
  after_update  Int;
  before_commit Int;

  cab ad_tsfrocc%Rowtype;
  ped ad_tsfrocp%Rowtype;
  ord tgford%Rowtype;

Begin
  /* 
  * Autor: M. Rangel
  * Processo: Roteirizador/sequenciador de ordens de carga (subprocesso frete OC)
  * Objetivo: 
  */

  -- obsoleto, substitu�do por trigger

  before_insert := 0;
  after_insert  := 1;
  before_delete := 2;
  after_delete  := 3;
  before_update := 4;
  after_update  := 5;
  before_commit := 10;

  cab.numrocc := evp_get_campo_int(p_idsessao, 'NUMROCC');

  Begin
    Select *
      Into cab
      From ad_tsfrocc
     Where numrocc = cab.numrocc;
  Exception
    When Others Then
      Null;
  End;

  ped.numrocp := evp_get_campo_int(p_idsessao, 'NUMROCP');

  Begin
    Select *
      Into ped
      From ad_tsfrocp
     Where numrocc = cab.numrocc
       And numrocp = ped.numrocp;
  Exception
    When Others Then
      Null;
  End;

  Begin
    Select *
      Into ord
      From tgford o
     Where o.codemp = cab.codemp
       And o.ordemcarga = cab.ordemcarga;
  Exception
    When Others Then
      Null;
  End;

  /*******************************************************************************
     � poss�vel obter o valor dos campos atrav�s das functions:
     
    evp_get_campo_dta(p_idsessao, 'NOMECAMPO') -- para campos de data
    evp_get_campo_int(p_idsessao, 'NOMECAMPO') -- para campos num�ricos inteiros
    evp_get_campo_dec(p_idsessao, 'NOMECAMPO') -- para campos num�ricos decimais
    evp_get_campo_texto(p_idsessao, 'NOMECAMPO')   -- para campos texto
    
    o primeiro argumento � uma chave para esta execu��o. o segundo � o nome do campo.
    
    para os eventos before update, before insert e after delete todos os campos estar�o dispon�veis.
    para os demais, somente os campos que pertencem � pk
    
    * os campos clob/text ser�o enviados convertidos para varchar(4000)
    
    tamb�m � poss�vel alterar o valor de um campo atrav�s das stored procedures:
    
    evp_set_campo_dta(p_idsessao,  'NOMECAMPO', valor) -- valor deve ser uma data
    evp_set_campo_int(p_idsessao,  'NOMECAMPO', valor) -- valor deve ser um n�mero inteiro
    evp_set_campo_dec(p_idsessao,  'NOMECAMPO', valor) -- valor deve ser um n�mero decimal
    evp_set_campo_texto(p_idsessao,  'NOMECAMPO', valor) -- valor deve ser um texto
  ********************************************************************************/

  If p_tipoevento = before_insert Then
    If cab.status = 'C' Then
      Raise_Application_Error(-20105, ad_fnc_formataerro('Sequenciamento j� conclu�do'));
    End If;
  End If;
  /*     if p_tipoevento = after_insert then
        --descomente este bloco para programar o "AFTER INSERT"
  end if;*/

  If p_tipoevento = before_delete Then
    If (cab.codemp = ped.codemp And cab.ordemcarga = ped.ordemcarga) And ord.situacao = 'F' Then
      Raise_Application_Error(-20105,
                              ad_fnc_formataerro('Ordem de carga j� fechada, n�o � poss�vel alterar o lan�amento.'));
    End If;
  End If;

  /*     if p_tipoevento = after_delete then
        --descomente este bloco para programar o "AFTER DELETE"
  end if;*/

  If p_tipoevento = before_update Then
    If cab.status = 'C' Then
      Raise_Application_Error(-20105, ad_fnc_formataerro('Sequenciamento j� conclu�do'));
    End If;
  End If;
  /*     if p_tipoevento = after_update then
        --descomente este bloco para programar o "AFTER UPDATE"
  end if;*/

  /*     if p_tipoevento = before_commit then
        --descomente este bloco para programar o "BEFORE COMMIT"
  end if;*/

End;
/
