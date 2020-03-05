Create Or Replace Procedure "AD_STP_CAP_GERASOLSERV_SF"(p_codusu    Number,
                                                        p_idsessao  Varchar2,
                                                        p_qtdlinhas Number,
                                                        p_mensagem  Out Varchar2) As
  a          ad_tsfcap%Rowtype;
  r          ad_tsfcapfrt%Rowtype;
  v_Codsolst Number;
Begin

  /* Autor: M. Rangel
  * Processo: Carro de Apoio
  * Objetivo: Gerar solicita��es de servi�os de transporte (aluguel de Van, ex)
  */

  For i In 1 .. p_qtdlinhas
  Loop
  
    a.nuap := act_int_field(p_idsessao, i, 'NUAP');
  
    -- busca os dados do agendamento  
    Begin
      Select *
        Into a
        From ad_tsfcap
       Where nuap = a.nuap;
    Exception
      When Others Then
        p_mensagem := Sqlerrm;
        Return;
    End;
  
    --- busca os dados do rateio
    Begin
      Select *
        Into r
        From ad_tsfcapfrt
       Where nuap = a.nuap Fetch First 1 rows Only;
    Exception
      When Others Then
        p_mensagem := Sqlerrm;
        Return;
    End;
  
    Begin
      stp_keygen_tgfnum('AD_TSFSSTC', 1, 'AD_TSFSSTC', 'CODSOLST', 0, v_codsolst);
    
      -- insert o cabe�alho da solicita��o
      Begin
        Insert Into ad_tsfsstc
          (codsolst, codsol, dhsolicit, codemp, codnat, codcencus, codproj, dtinicio, dtfim,
           codparc, status, numcontrato, dhalter, codusu, obs, nunotaorig, origem)
        Values
          (v_codsolst, a.codususol, Sysdate, 1, r.codnat, r.codcencus, r.codproj, a.dtagend,
           a.dtagend, Null, 'P', Null, Sysdate, p_codusu, a.rota, Null, Null);
      Exception
        When Others Then
          p_mensagem := 'Erro ao criar o cabe�alho da solicita��o. <br>' || Sqlerrm;
          Return;
      End;
    
      -- insert do servi�o
      Begin
        Insert Into ad_tsfssti
          (codserv, codsolst, qtdneg, codvol, vlrunit, vlrtot, numcontrato, codparc, nussti,
           descrserv)
        Values
          (7102, v_codsolst, 1, 'UN', 0, 0, Null, 0, 1, ad_get.Descrproduto(7102));
      Exception
        When Others Then
          p_mensagem := 'Erro ao inserir o servi�o na solicita��o! <br>' || Sqlerrm;
          Return;
      End;
    
      -- envia a solicita��o para an�lise da �rea de transporte
      -- cancela o agendamento
      Declare
        v_sessao Varchar2(100);
        v_msg    Varchar2(4000);
      Begin
        ad_set.Inseresessao('CODSOLST', 1, 'I', v_codsolst, v_sessao);
        ad_stp_sst_envanalise(p_codusu, v_sessao, 1, v_msg);
        ad_set.Inseresessao('NUAP', 1, 'I', a.nuap, v_sessao);
        ad_set.Inseresessao('MOTIVO', 0, 'S',
                            'Solicita��o enviada � �rea de transporte para contrata��o do mesmo!',
                            v_sessao);
        AD_STP_CAP_CANCAGEND(p_codusu, v_sessao, 1, v_msg);
        ad_set.Remove_Sessao(v_sessao);
      Exception
        When Others Then
          p_mensagem := Sqlerrm;
          Return;
      End;
    
    Exception
      When Others Then
        p_mensagem := Sqlerrm;
        Return;
    End;
  
  End Loop i;

  p_mensagem := 'Opera��o realizada com sucesso, gerada a solicita��o n� ' || v_codsolst;

End;
/
