Create Or Replace Procedure "AD_STP_ROC_VALORDCAB_SF"(p_tipoevento Int,
                                                      p_idsessao   Varchar2,
                                                      p_codusu     Int) As
  before_insert Int;
  after_insert  Int;
  before_delete Int;
  after_delete  Int;
  before_update Int;
  after_update  Int;
  before_commit Int;

  r_roc ad_tsfrocc%Rowtype;
  r_ord tgford%Rowtype;

  x Int;
Begin
  before_insert := 0;
  after_insert  := 1;
  before_delete := 2;
  after_delete  := 3;
  before_update := 4;
  after_update  := 5;
  before_commit := 10;

  /* 
  * autor: M. Rangel
  * processo: roteirizador/sequenciador de ordens de carga (subprocesso frete oc)
  * objetivo: Realizar validações 
  */

  -- obsoleto, substituído por trigger

  r_roc.numrocc    := evp_get_campo_int(p_idsessao, 'NUMROCC');
  r_roc.codemp     := evp_get_campo_int(p_idsessao, 'CODEMP');
  r_roc.ordemcarga := evp_get_campo_int(p_idsessao, 'ORDEMCARGA');

  If stp_get_atualizando Then
    Return;
  End If;

  Begin
    Select *
      Into r_roc
      From ad_tsfrocc
     Where (numrocc = r_roc.numrocc Or ordemcarga = r_roc.ordemcarga);
  Exception
    When too_many_rows Then
      Select *
        Into r_roc
        From ad_tsfrocc
       Where (numrocc = r_roc.numrocc Or ordemcarga = r_roc.ordemcarga)
         And rownum = 1;
    When Others Then
      Null;
      --raise_application_error(-20105, ad_fnc_formataerro('Erro ao buscar detalhes da OC. ' || sqlerrm));
  End;

  Begin
    Select *
      Into r_ord
      From tgford o
     Where o.codemp = r_roc.codemp
       And o.ordemcarga = r_roc.ordemcarga;
  Exception
    When no_data_found Then
      Null;
    When Others Then
      Raise;
  End;

  If p_tipoevento = before_insert Then
  
    Select Count(*)
      Into x
      From ad_tsfrocc
     Where numrocc = r_roc.numrocc
       And codemp = r_roc.codemp;
  
    If x > 0 Then
      Raise_Application_Error(-20105,
                              ad_fnc_formataerro('Já existe sequenciamento gerado para esta ordem de carga!'));
    End If;
  
  End If;

  If p_tipoevento = before_delete Then
    If r_ord.situacao = 'F' Then
      Raise_Application_Error(-20105,
                              ad_fnc_formataerro('Ordem de carga fechada! Não é possível excluir esse lançamento.'));
    End If;
  
    If Nvl(r_ord.ad_liberado, 'N') = 'S' Then
      Raise_Application_Error(-20105,
                              ad_fnc_formataerro('Ordem de carga liberada! Não é possível excluir esse lançamento.'));
    End If;
  End If;

  If p_tipoevento = before_update Then
    /*If r_roc.status = 'C' Then
      Raise_Application_Error(-20105, ad_fnc_formataerro('Sequenciamento já concluído'));
    End If;*/
    If Nvl(r_ord.ad_liberado, 'N') = 'S' Then
      Raise_Application_Error(-20105,
                              ad_fnc_formataerro('Ordem de carga liberada! Não é possível alterar esse lançamento.'));
    End If;
  End If;

End;
/
