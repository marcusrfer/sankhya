Create Or Replace Procedure "AD_STP_RKM_DESFAZLIB_SF"(p_codusu    Number,
                                                      p_idsessao  Varchar2,
                                                      p_qtdlinhas Number,
                                                      p_mensagem  Out Varchar2) As
  r ad_tsfrkmc%Rowtype;
Begin
  variaveis_pkg.v_atualizando := True;

  For i In 1 .. p_qtdlinhas
  Loop
    r.nureemb := act_int_field(p_idsessao, i, 'NUREEMB');
    Select *
      Into r
      From ad_tsfrkmc
     Where nureemb = r.nureemb;
  
    If r.nufin Is Not Null Then
      Begin
        Delete From tgffin
         Where nufin = r.nufin;
      
        Delete From tsilib
         Where tabela = 'TGFFIN'
           And nuchave = r.nufin;
      
        Delete From ad_tblcmf
         Where nometaborig = 'AD_TSFRKMC'
           And nometabdest = 'TGFFIN'
           And nuchaveorig = r.nureemb
           And nuchavedest = r.nufin;
      
      Exception
        When Others Then
          p_mensagem := 'Não foi possível excluir a movimentação financeira do reembolso. <br>Motivo: ' ||
                        Sqlerrm;
          Return;
      End;
    End If;
  
    Begin
      Delete From tsilib
       Where tabela = 'AD_TSFRKMC'
         And nuchave = r.nureemb;
    Exception
      When Others Then
        p_mensagem := 'Não foi possível desfazer a liberação do reembolso. <br>Motivo: ' || Sqlerrm;
        Return;
    End;
  
    Begin
      variaveis_pkg.v_atualizando := True;
    
      Update ad_tsfrkmc
         Set status = 'P'
       Where nureemb = r.nureemb;
    Exception
      When Others Then
        p_mensagem := 'Não foi possível atualizar o status do reembolso para pendente. <br>Motivo: ' ||
                      Sqlerrm;
        Return;
    End;
  
  End Loop;

  p_mensagem := 'Liberações desfeitas com sucesso!';

End;
/
