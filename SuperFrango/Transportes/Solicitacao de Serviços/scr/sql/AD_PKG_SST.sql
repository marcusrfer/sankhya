Create Or Replace Package AD_PKG_SST As
  /****************************************************************************
  Autor: 
  Objetivo: 
  *****************************************************************************/
  Type rec_origem Is Record(
    origem Varchar2(4000));

  Type ty_origem Is Table Of rec_origem;

  Procedure Insere_Contrato(p_CodSol      Number,
                            p_CodParc     Number,
                            p_Nussti      Number,
                            p_Codserv     Number,
                            p_Qtdneg      Number,
                            p_Vlrtot      Float,
                            p_Temmed      Char,
                            v_NumContrato Out Number,
                            errmsg        Out Varchar2);
  /****************************************************************************
  Autor: Marcus Rangel
  Objetivo: Insere Contrato de serviços de transportes.
  *****************************************************************************/
  Procedure exclui_contrato(p_NumContrato Number);
  /****************************************************************************
  Autor: Marcus Rangel
  Objetivo: Exclui contrato
  *****************************************************************************/

End;
/
Create Or Replace Package Body AD_PKG_SST Is

  Procedure Insere_Contrato(p_CodSol      Number,
                            p_CodParc     Number,
                            p_Nussti      Number,
                            p_Codserv     Number,
                            p_Qtdneg      Number,
                            p_Vlrtot      Float,
                            p_Temmed      Char,
                            v_NumContrato Out Number,
                            errmsg        Out Varchar2) Is
    r_Sol        ad_tsfsstc%Rowtype;
    v_CodContato Number;
    v_NomeParc   Varchar2(250);
    v_QtdNeg     Float;
    c            Int := 0;
    v_NuSeqPmc   Int := 0;
  
  Begin
  
    Select *
      Into r_Sol
      From ad_tsfsstc
     Where codsolst = p_Codsol;
  
    If Nvl(p_Temmed, 'N') = 'N' Then
      v_QtdNEg := 1;
    Else
      v_QtdNeg := p_Qtdneg;
    End If;
  
    Begin
    
      /*      
      v_NumContrato := ad_get.ultcod(p_tabela => 'TCSCON', p_codemp => 1, p_serie => 'E');
      v_Numcontrato := v_NumContrato + 1;
      */
    
      stp_keygen_tgfnum(p_arquivo => 'TCSCON', p_codemp => 1, p_tabela => 'TCSCON',
                        p_campo => 'NUMCONTRATO', p_dsync => 0, p_ultcod => v_NumContrato);
    
      /*      Update tgfnum
        Set ultcod = v_numcontrato
      Where arquivo = 'TCSCON'
        And codemp = 1
        And serie = 'E';*/
    Exception
      When Others Then
        Raise;
    End;
  
    Begin
      Select codcontato
        Into v_CodContato
        From tgfctt c
       Where codparc = p_Codparc
         And rownum = 1;
    Exception
      When no_data_found Then
        Insert Into tgfctt
          (codparc, codcontato, nomecontato)
        Values
          (p_codparc, 1, v_NomeParc);
        v_CodContato := 1;
    End;
  
    Select nomeparc
      Into v_NomeParc
      From tgfpar
     Where codparc = p_Codparc;
  
    Insert Into Tcscon
      (Numcontrato, Ambiente, Codparc, Codcontato, Ativo, Dtcontrato, Codemp, Codnat, Codcencus,
       Codproj, Imprime, Temmed, Recdesp, Ad_situacao, Codusu, Dtbasereaj, Ad_codsolst, Equipamento,
       codtipvenda, parcelaqtd, ad_objcontrato)
    Values
      (v_Numcontrato, 'TRANSPORTES', p_Codparc, v_CodContato, 'S', Trunc(Sysdate), r_sol.codemp,
       r_sol.codnat, r_sol.codcencus, r_sol.codproj, 'S', p_Temmed, -1, 'P', Stp_get_codusulogado,
       Sysdate + 12, r_sol.codsolst, v_NomeParc, 101, Decode(p_temmed, 'S', 0, p_QtdNeg),
       'servTransp');
  
    -- insere o produto
    Insert Into Tcspsc
      (Numcontrato, Codprod, Sitprod, Qtdeprevista, Vlrunit, Dtalter)
    Values
      (v_Numcontrato, p_Codserv, 'A', v_Qtdneg, (p_Vlrtot / p_Qtdneg), Sysdate);
  
    -- insere o preço
    Insert Into Tcspre
      (Numcontrato, Codprod, Referencia, Valor, Codserv)
    Values
      (V_numcontrato, p_Codserv, Sysdate, (p_Vlrtot / p_Qtdneg), p_Codserv);
  
    -- insere a ocorrencia
    Insert Into Tcsocc
      (Numcontrato, Codprod, Dtocor, Codusu, Codparc, Codcontato, Codocor, Descricao)
    Values
      (V_numcontrato, p_Codserv, Sysdate, Stp_get_codusulogado, p_Codparc, V_codcontato, 1,
       'Ativação do serviço');
  
    -- Insere os valores informados nas máquinas/equipamentos/veículos
  
    For m In (Select *
                From ad_tsfsstm
               Where codsolst = r_sol.codsolst
                 And nussti = p_Nussti
                 And codparc = p_CodParc
                 And Nvl(temmed, 'N') = p_Temmed)
    Loop
      v_NuSeqPmc := v_NuSeqPmc + 1;
      Insert Into ad_tsfpmc
        (numcontrato, codprod, nuseqpmc, dtvigor, vlrunit, codsolst, nussti, seqmaq, codmaq, id,
         codvol, dhalter, codusu, motivo)
      Values
        (v_Numcontrato, p_Codserv, v_NuSeqPmc, Trunc(Sysdate), m.vlrunit, r_sol.codsolst, m.nussti,
         m.seqmaq, m.codmaq, m.id, m.codvol, Trunc(Sysdate), stp_get_codusulogado,
         'Inserção do valor original.');
    End Loop;
  
  Exception
    When dup_val_on_index Then
      Rollback;
      errmsg := 'Erro ao inserir as máquinas ao contrato. <br> Por favor, aguarde enquanto esse erro é corrigido';
    When Others Then
      Rollback;
      errmsg := Sqlerrm;
  End insere_contrato;

  Procedure exclui_contrato(p_NumContrato Number) Is
  Begin
    Delete From tcsocc
     Where numcontrato = p_numcontrato;
    Delete From tcspre
     Where numcontrato = p_numcontrato;
    Delete From ad_tsfpmc
     Where numcontrato = p_numcontrato;
    Delete From tcspsc
     Where numcontrato = p_numcontrato;
    Update ad_tsfsstm m
       Set numcontrato = Null
     Where m.numcontrato = p_numcontrato;
    Delete From tcscon
     Where numcontrato = p_numcontrato;
  End exclui_contrato;

End AD_PKG_SST;
/
