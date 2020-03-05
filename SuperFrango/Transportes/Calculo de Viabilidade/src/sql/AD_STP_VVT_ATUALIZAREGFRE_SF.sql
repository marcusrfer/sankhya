Create Or Replace Procedure "AD_STP_VVT_ATUALIZAREGFRE_SF"(p_codusu    Number,
                                                           p_idsessao  Varchar2,
                                                           P_Qtdlinhas Number,
                                                           p_mensagem  Out Nocopy Varchar2) As
  p_numvvt     Number;
  vvt          ad_tsfvvt%Rowtype;
  v_Nurfr      Number;
  v_Numrfi     Number;
  v_ValorSaida Float;
  v_valorKm    Float;
  v_Count      Int Default 0;
Begin

  /*
  * Autor: Marcus Rangel
  * Processo: Viabilidade de Veículos de Transporte
  * Objetivo: Atualizar os valores na tela de região de frete
  */

  For i In 1 .. p_qtdlinhas
  Loop
    p_numvvt := act_int_field(p_idsessao, i, 'NUMVVT');
  
    --- para fins de depuração
    If Lower(p_idsessao) = 'debug' Then
      p_numvvt := 4;
    End If;
  
    -- popula record
    Select * Into vvt From ad_tsfvvt Where numvvt = p_numvvt;
  
    -- verifica se ativo
    If Nvl(vvt.ativo, 'N') = 'N' Then
      p_mensagem := 'Configuração não está ativa, não pode ser utilizada.';
      Return;
    End If;
  
    -- popupa variáveis de valores
    -- saida + Km
    If vvt.formaprecif = 'S' Then
    
      v_ValorSaida := Case
                        When vvt.vlrsaida = 0 Then
                         vvt.vlrsaidasug
                        Else
                         vvt.vlrsaida
                      End;
    
      v_valorKm := Case
                     When vvt.vlrkmsaida = 0 Then
                      vvt.vlrkmsaidasug
                     Else
                      vvt.vlrkmsaida
                   End;
    
    Elsif vvt.formaprecif = 'K' Then
      -- Km
      v_ValorSaida := 0;
    
      v_valorKm := Case
                     When vvt.custokm = 0 Then
                      vvt.custosugerido
                     Else
                      vvt.custokm
                   End;
    
    Elsif vvt.formaprecif = 'V' Then
      -- Saida apenas
      v_ValorSaida := Case
                        When vvt.vlrsaida = 0 Then
                         vvt.vlrsaidasug
                        Else
                         vvt.vlrsaida
                      End;
    
      V_Valorkm := 0;
    
    End If;
  
    -- verifica se existe a categoria na região
    Begin
      Select Count(*)
        Into v_count
        From ad_tsfrfr r
       Where r.codregfre = vvt.codregfre
         And r.codcat = vvt.codcat
         And r.dtvigor = vvt.dtref;
    
      -- se existir, atualiza os valores e faz o link
      If v_count > 0 Then
        Begin
          Update ad_tsfrfr r
             Set r.vlrsaida = v_ValorSaida,
                 numvvt     = p_numvvt
           Where r.codregfre = vvt.codregfre
             And r.codcat = vvt.codcat
             And r.dtvigor = vvt.dtref
          Returning r.nurfr Into v_Nurfr;
        Exception
          When Others Then
            p_mensagem := 'Não foi possível atualizar o valor de saída na região ' || vvt.codregfre || ', categoria ' ||
                          vvt.codcat || ', na referência ' || vvt.dtref || Chr(13) || Sqlerrm;
            Return;
        End;
      
        Begin
        
          Select Max(i.numrfi) + 1 Into v_Numrfi From ad_tsfrfi i Where nurfr = v_Nurfr;
        
          Merge Into ad_tsfrfi i
          Using (Select v_Numrfi As numrfi,
                        v_Nurfr As nurfr,
                        vvt.codregfre As codregfre,
                        0 As inicioint,
                        4000 As finalint,
                        v_valorKm As vlrkm,
                        'N' As vlrfixo,
                        p_numvvt As numvvt
                   From dual) d
          On (i.nurfr = d.Nurfr And i.codregfre = d.codregfre)
          When Matched Then
            Update
               Set i.vlrkm = v_valorKm,
                   numvvt  = p_numvvt
          When Not Matched Then
            Insert Values (d.numrfi, d.nurfr, d.codregfre, d.inicioint, d.finalint, d.vlrkm, d.vlrfixo, d.numvvt);
        Exception
          When Others Then
            p_mensagem := 'Não foi possível atualizar o valor na região ' || vvt.codregfre || ', categoria ' ||
                          vvt.codcat || ', na referência ' || vvt.dtref || Chr(13) || Sqlerrm;
        End;
      
      Else
        -- se não existir, insere uma nova categoria
      
        -- insere categoria
        Begin
          Select Nvl(Max(nurfr), 0) + 1 Into v_nurfr From Ad_Tsfrfr Where codregfre = vvt.codregfre;
        
          Insert Into ad_tsfrfr
            (nurfr, codregfre, vlrsaida, codcat, dtvigor, numvvt)
          Values
            (v_Nurfr, vvt.codregfre, v_ValorSaida, vvt.codcat, vvt.dtref, vvt.numvvt);
        Exception
          When Others Then
            p_mensagem := 'Não foi possível inserir a categoria ' || vvt.codcat || ' com referência ' || vvt.dtref ||
                          ' na região ' || vvt.codregfre || Chr(13) || Sqlerrm;
            Return;
        End;
      
        -- insere faixa de valores
        Begin
          Select Nvl(Max(Numrfi), 0) + 1
            Into v_Numrfi
            From ad_tsfrfi
           Where nurfr = v_Nurfr
             And codregfre = vvt.codregfre;
        
          Insert Into ad_tsfrfi
            (numrfi, nurfr, codregfre, inicioint, finalint, vlrkm, vlrfixo, numvvt)
          Values
            (v_Numrfi, v_Nurfr, vvt.codregfre, 0, 4000, v_valorKm, 'S', p_numvvt);
        Exception
          When Others Then
            p_mensagem := 'Não foi possível inserir a faixa de valor na categoria ' || vvt.codcat || ' com referência ' ||
                          vvt.dtref || ' na região ' || vvt.codregfre || Chr(13) || Sqlerrm;
        End;
      
      End If;
    End;
  
  End Loop;

  p_mensagem := 'Valores atualizados com sucesso!!!';

End;
/
