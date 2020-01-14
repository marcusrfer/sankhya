Create Or Replace Procedure AD_STP_RKM_INSLIBKM_SF(p_nureemb Number) Is
  c          ad_tsfrkmc%Rowtype;
  p          ad_tsfelt%Rowtype;
  con        tcscon%Rowtype;
  v_dtvencto Date;
  v_Nufin    Number;
  v_totalkm  Float;
  v_vlrtot   Float;
  --errmsg     Varchar2(4000);
Begin
  /* 
  * Autor: M. Rangel
  * Processo: Reembolso de KM
  * Objetivo: Gerar a despesa e a solicitação de liberação
  */

  variaveis_pkg.v_atualizando := True;

  -- cabeçalho do reembolso
  Begin
    Select *
      Into c
      From ad_tsfrkmc
     Where nureemb = p_nureemb;
  Exception
    When Others Then
      Raise;
  End;

  -- parametros
  Begin
    Select *
      Into p
      From ad_tsfelt
     Where nuelt = 1;
  Exception
    When Others Then
      Raise;
  End;

  -- contrato
  Begin
    Select *
      Into con
      From tcscon
     Where numcontrato = p.numcontratokm;
  Exception
    When Others Then
      Raise;
  End;

  -- total de km
  Begin
    Select Sum(totalkm), Sum(vlrtotal)
      Into v_totalkm, v_vlrtot
      From ad_tsfrkmi
     Where nureemb = c.nureemb;
  Exception
    When Others Then
      Raise;
  End;

  -- valor do km  
  --v_vlrkm := ad_get.ultimo_valor_contrato(p.numcontratokm, c.codprod, Sysdate);

  --v_vlrtot := v_vlrkm * v_totalkm;

  -- insere provisão de despesa 
  <<ins_financeiro>>
  Begin
    If v_dtvencto Is Null Then
      v_dtvencto := Trunc(Sysdate) + 5;
    End If;
  
    While To_Char(v_dtvencto, 'd') In (1, 7)
    Loop
      v_dtvencto := v_dtvencto + 1;
    End Loop;
  
    If v_nufin Is Null Then
      stp_keygen_nufin(v_nufin);
    End If;
  
    Insert Into tgffin
      (nufin, codemp, numnota, dtneg, dtvenc, codparc, codtipoper, dhtipoper, codctabcoint, codnat,
       codcencus, codproj, codtiptit, origem, vlrdesdob, provisao, recdesp, historico, dhmov,
       dtalter, ad_variacao, ad_conferido, codusu)
    Values
      (v_Nufin, c.codemp, To_Number(con.numcontrato || c.nureemb), Trunc(Sysdate), v_dtvencto,
       c.codparc, p.codtopreembkm, ad_get.Maxdhtipoper(p.codtopreembkm), 999, c.codnat, c.codcencus,
       c.codproj, con.tipotitulo, 'F', v_vlrtot, 'S', 0, 'Ref. reembolso de Km nº ' || c.nureemb,
       Sysdate, Sysdate, 'movtofinanceiro', 'N', stp_get_codusulogado);
  
  Exception
    When Others Then
      v_dtvencto := v_dtvencto + 1;
      Goto ins_financeiro;
  End;

  -- insere a ligação
  /*Begin
    Insert Into ad_tblcmf
      (nometaborig, nuchaveorig, nometabdest, nuchavedest)
    Values
      ('AD_TSFRKMC', C.NUREEMB, 'TGFFIN', v_Nufin);
  Exception
    When Others Then
      ad_set.Insere_Msglog('TBLCMF - Erro ao inserir a ligação da tabela origem com a destino. ' ||
                           Sqlerrm);
  End;*/

  For rat In (Select f.codemp, f.codcencus, f.codnat, Nvl(f.codproj, 0) codproj, f.percentual
                From ad_tsfrkmr f
                Join ad_tsfrkmc cab
                  On f.nureemb = cab.nureemb
               Where f.nureemb = c.nureemb)
  Loop
  
    Begin
      Insert Into tgfrat
        (origem, nufin, codnat, codcencus, codproj, percrateio, digitado, codusu, dtalter)
      Values
        ('F', v_nufin, rat.codnat, rat.codcencus, rat.codproj, rat.percentual, 'N',
         stp_get_codusulogado, Sysdate);
    
    Exception
      When Others Then
        Raise_Application_Error(-20105,
                                ad_fnc_formataerro('Erro ao inserir o rateio do reembolso. - ' ||
                                                    Sqlerrm));
    End;
  
  End Loop;

  /*Begin
    ad_set.Ins_Liberacao(p_Tabela => 'TGFFIN', p_Nuchave => v_nufin, p_Evento => 1035,
                         p_Valor => v_vlrtot, p_Codusulib => 950,
                         p_Obslib => 'Ref. reembolso de Km nº ' || c.nureemb, p_Errmsg => errmsg);
  
    If errmsg Is Not Null Then
      Raise_Application_Error(-20105, 'Erro ao inserir a liberação do pagamento!<br>' || Sqlerrm);
    End If;
  
  Exception
    When Others Then
      Raise_Application_Error(-20105, 'Erro ao inserir a liberação do pagamento!<br>' || Sqlerrm);
  End;*/

  Insert Into ad_tblcmf
    (nometaborig, nuchaveorig, nometabdest, nuchavedest)
  Values
    ('AD_TSFRKMC', c.nureemb, 'TGFFIN', v_nufin);

  -- atualiza status na origem
  Begin
    Update ad_tsfrkmc
       Set nufin = v_nufin
    --status = 'PLT'
     Where nureemb = c.nureemb;
  Exception
    When Others Then
      Raise_Application_Error(-20105, Sqlerrm);
    
  End;

End;
/
