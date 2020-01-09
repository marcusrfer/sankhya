Create Or Replace Procedure AD_STP_JUR_DESFAZREEMB_SF(p_codusu    Number,
                                                      p_idsessao  Varchar2,
                                                      p_qtdlinhas Int,
                                                      p_mensagem  Out Nocopy Varchar2) As
  p_nupasta Number;
  p_seq Int;
  v_SeqCascata Int;
  v_Nueventoreemb Number;
  i Int := 0;
Begin
  --percorre o log dos registros do reembolso

  For l In (Select *
              From ad_jurlog Log
             Where log.Nupasta = p_Nupasta
               And log.Seq = p_Seq
               And log.Tipo != 'A'
             Order By nubco Desc)
  Loop
    --verifica se possui nufin baixado e pergunta se desfaz ou não
    If l.nufin Is Not Null Then
      Select Count(*)
        Into i
        From tgffin
       Where nufin = l.nufin
         And dhbaixa Is Not Null;
    
      Begin
        ad_set.estorna_financeiro(l.nufin);
        Delete From tgffin Where nufin = l.nufin;
      Exception
        When Others Then
          p_Mensagem := 'Erro ao realizar o estorno do lançamento financeiro nro único ' || l.nufin || '. ' ||
                        Sqlerrm;
          --Raise_Application_Error(-20105, ad_fnc_formataerro(p_mensagem));
          Return;
      End;
    
    Else
      -- se nufin is null
      --desfaz as transferências
      Begin
        Delete From tgfmbc Where nubco = l.nubco;
      Exception
        When Others Then
          p_Mensagem := 'Erro ao realizar o estorno do lançamento bancário nro único ' || l.nubco || '. ' ||
                        Sqlerrm;
          Return;
      End;
    
    End If;
  End Loop;

  --ao sair do laço, exclui os lançamentos do log
  Begin
    Delete From ad_jurlog Log
     Where log.Nupasta = p_Nupasta
       And log.Seq = p_Seq
       And log.Tipo != 'A';
  Exception
    When Others Then
      p_mensagem := 'Erro ao excluir os lançamentos da aba "Lançamentos". ' || Sqlerrm;
      --Raise_Application_Error(-20105, ad_fnc_formataerro(p_mensagem));
      Return;
  End;

  --exclui da lib
  Begin
    Select j.nueventolibreemb Into v_Nueventoreemb From ad_jurparam j Where j.nujurpar = 1;
  
    Delete From tsilib
     Where nuchave = p_Nupasta
       And tabela = 'AD_JURITE'
       And sequencia = p_Seq
       And evento = v_Nueventoreemb
    Returning seqcascata Into v_Seqcascata;
  
  Exception
    When Others Then
      p_mensagem := 'Erro ao excluir liberações pendentes para reprocessamento do reembolso. ' || Sqlerrm;
      --Raise_Application_Error(-20105, ad_fnc_formataerro(p_mensagem));
      Return;
  End;

  -- exclui os valores do reembolso
  ad_pkg_jur.exclui_reembolso_tmp(p_Nupasta, p_Seq, v_Seqcascata);

  --exclui a liberação do log
  ad_pkg_jur.exclui_reembolso_lib(p_Nupasta, p_Seq, v_Seqcascata);

  --voltar pro inicio do método
  Begin
    Update ad_jurite
       Set libreembolso = 'N'
     Where nupasta = p_nupasta
       And seq = p_seq;
  Exception
    When Others Then
      p_mensagem := 'Erro ao atualizar o status do processo. ' || Sqlerrm;
      --Raise_Application_Error(-20105, 'Erro ao atualizar o status do processo. ' || Sqlerrm);
      Return;
  End;

End;
/
