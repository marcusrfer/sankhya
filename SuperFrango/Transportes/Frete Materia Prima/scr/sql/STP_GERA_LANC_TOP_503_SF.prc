Create Or Replace Procedure "STP_GERA_LANC_TOP_503_SF"(P_CODUSU    Number, -- Código do usuário logado
                                                       P_IDSESSAO  Varchar2, -- Identificador da execução. Serve para buscar informações dos parâmetros/campos da execução.
                                                       P_QTDLINHAS Number, -- Informa a quantidade de registros selecionados no momento da execução.
                                                       P_MENSAGEM  Out Varchar2 -- Caso seja passada uma mensagem aqui, ela será exibida como uma informação ao usuário.
                                                       ) As
  FIELD_SEQUENCIA Number;
  P_NUNOTA        Number;
  P_COUNT         Number;
  ULT_NUFIN       Number;
  I               Number;
  P_CODCFOP       Int;
  P_CODVEICULO    Int;
  P_CODTRIB       Int;
  P_CODUF         Int;
  P_NUVINC        Int;

Begin

  For I In 1 .. P_QTDLINHAS -- Este loop permite obter o valor de campos dos registros envolvidos na execução.
  Loop
  
    FIELD_SEQUENCIA := ACT_INT_FIELD(P_IDSESSAO, I, 'SEQUENCIA');
  
  -- <ESCREVA SEU CÓDIGO AQUI (SERÁ EXECUTADO PARA CADA REGISTRO SELECIONADO)> --
  
  End Loop;

  Select Count(*)
    Into P_COUNT
    From AD_CABCTEFAB
   Where SEQUENCIA = FIELD_SEQUENCIA
     And GEROU = 'SIM';

  /*     IF P_COUNT > 0 THEN
  
       RAISE_APPLICATION_ERROR(-20101,'Essa sequência foi gerada - INTERROMPENDO!!!! ');
  
  
  END IF;*/

  Select Count(*)
    Into P_COUNT
    From AD_ITECTEFAB
   Where SEQUENCIA = FIELD_SEQUENCIA
     And GERAR = 'SIM'
     And (CODNAT = 0 Or PLACA Is Null);

  If P_COUNT > 0 Then
  
    Raise_Application_Error(-20101,
                            'Existem lançamentos com natureza 0 (zero) ou veículo sem placa - INTERROMPENDO!!!! ');
  
  End If;

  I := 0;

  For CUR_NOTAS In (Select I.SEQITE,
                           Trunc(I.DATAEMISSAO) DATAEMISSAO,
                           I.NUMCTE,
                           I.SERIE,
                           I.CODPARC,
                           I.QTDE,
                           I.VLRCTE,
                           To_Number(Replace(I.ICMS, '.', ',')) ICMS,
                           I.CHAVECTE,
                           I.CODNAT,
                           Round(I.VLRCTE / I.QTDE, 6) As VLRUNIT,
                           PLACA,
                           I.SEQCARGTO,
                           I.SEQNOTA,
                           I.CODCIDINICTE,
                           I.CODCIDFIMCTE
                    
                      From AD_CABCTEFAB C, AD_ITECTEFAB I
                     Where C.SEQUENCIA = I.SEQUENCIA
                       And C.SEQUENCIA = FIELD_SEQUENCIA
                       And Nvl(I.GERAR, 'NÃO') = 'SIM'
                       And Nvl(I.NUNOTA, 0) = 0)
  Loop
  
    Loop
      Select Max(ULTCOD + 1)
        Into P_NUNOTA
        From TGFNUM
       Where NOMEARQ = 'TGFCAB';
    
      Update TGFNUM
         Set ULTCOD = P_NUNOTA
       Where NOMEARQ = 'TGFCAB';
    
      Select Count(1)
        Into P_COUNT
        From TGFCAB
       Where NUNOTA = P_NUNOTA;
      Exit When P_COUNT = 0;
    End Loop;
  
    --- BUSCA O VEICULO
  
    Select Count(*)
      Into P_COUNT
      From TGFVEI VEI
     Where VEI.CODPARC = CUR_NOTAS.CODPARC
       And VEI.PLACA = Trim(CUR_NOTAS.PLACA)
       And VEI.ATIVO = 'S';
  
    If P_COUNT = 0 Then
    
      Raise_Application_Error(-20101,
                              'O veículo placa: ' || CUR_NOTAS.PLACA || ' O código do parceiro: ' ||
                               CUR_NOTAS.CODPARC || '  não está cadastrado ou ativo !!!!');
    Elsif P_COUNT > 1 Then
      Raise_Application_Error(-20101,
                              'O veículo placa: ' || CUR_NOTAS.PLACA ||
                               ' tem mais de um cadastro !!!!');
    
    End If;
  
    -- AJUSTA CASO O PARCEIRO NÃO SEJE EMITENTE DE NFE
    Update TGFPAR PAR
       Set PAR.AD_NFE = 'S'
     Where PAR.CODPARC = CUR_NOTAS.CODPARC;
    Commit;
  
    Select CODVEICULO
      Into P_CODVEICULO
      From TGFVEI VEI
     Where VEI.PLACA = Trim(CUR_NOTAS.PLACA)
       And VEI.CODPARC = CUR_NOTAS.CODPARC
       And VEI.ATIVO = 'S';
  
    Insert Into TGFCAB
      (CODPARC, NUNOTA, NUMNOTA, SERIENOTA, DTALTER, DTMOV, DTNEG, DTFATUR, DTENTSAI, STATUSNOTA,
       TIPMOV, CODUSU, CODCENCUS, CODNAT, CODTIPOPER, DHTIPOPER, CODTIPVENDA, DHTIPVENDA, CODEMP,
       PENDENTE, CODEMPNEGOC, VLRNOTA, RATEADO, ISSRETIDO, IRFRETIDO, CODVEND, AD_CHAVENFE, CHAVENFE,
       CODVEICULO, CODPARCTRANSP, CODMODDOCNOTA, CODCIDINICTE, CODCIDFIMCTE)
    Values
      (CUR_NOTAS.CODPARC,
       -- CODPARC
       P_NUNOTA, CUR_NOTAS.NUMCTE, CUR_NOTAS.SERIE, Sysdate,
       -- DTALTER
       Trunc(Sysdate),
       -- DTMOV
       CUR_NOTAS.DATAEMISSAO,
       -- DTNEG
       CUR_NOTAS.DATAEMISSAO,
       -- DTFATUR
       Trunc(Sysdate),
       -- DTENTSAI
       'A',
       -- STATUSNOTA
       'C',
       -- TIPMVO
       P_CODUSU,
       -- CODUSU
       20200100,
       -- CODCENCUS
       CUR_NOTAS.CODNAT,
       -- CODNAT
       503,
       -- TOP
       (Select Max(DHALTER)
           From TGFTOP
          Where CODTIPOPER = 503),
       -- CODTIPOPER
       74,
       -- CODTIPVENDA
       (Select Max(DHALTER)
           From TGFTPV TVP
          Where CODTIPVENDA = 74),
       
       2,
       -- CODEMP
       'N',
       -- PENDENTE
       2,
       --CODEMPNEGOC
       CUR_NOTAS.VLRCTE,
       -- VLRNOTA
       'N', 'N',
       -- ISSRETIDO
       'N', 0,
       -- COMPRADOR 
       CUR_NOTAS.CHAVECTE,
       -- AD_CHAVECTE
       CUR_NOTAS.CHAVECTE,
       -- CHAVENFE
       P_CODVEICULO, CUR_NOTAS.CODPARC, 57,
       -- CODMODDOCNOTA,
       CUR_NOTAS.CODCIDINICTE, CUR_NOTAS.CODCIDFIMCTE);
  
    Select Count(*)
      Into P_COUNT
      From TGFPAR P, TSICID C, TSIUFS UF
     Where P.CODCID = C.CODCID
       And C.UF = UF.CODUF
       And P.CODPARC = CUR_NOTAS.CODPARC
       And UF.UF = 'GO';
  
    If P_COUNT > 0 Then
      -- GOIAS
      Select T.CODCFO_ENTRADA
        Into P_CODCFOP
        From TGFTOP T
       Where T.CODTIPOPER = 503
         And T.DHALTER = (Select Max(T.DHALTER)
                            From TGFTOP T
                           Where T.CODTIPOPER = 503);
    Else
      Select T.CODCFO_ENTRADA_FORA
        Into P_CODCFOP
        From TGFTOP T
       Where T.CODTIPOPER = 503
         And T.DHALTER = (Select Max(T.DHALTER)
                            From TGFTOP T
                           Where T.CODTIPOPER = 503);
    End If;
  
    -- PARCEIRO GOIAS CODTRIB
    If P_COUNT > 0 Then
      Select CODTRIB
        Into P_CODTRIB
        From TGFICM
       Where CODRESTRICAO = 503
         And UFORIG = 9
         And UFDEST = 9;
    Else
    
      Select CODUF
        Into P_CODUF
        From TGFPAR P, TSICID C, TSIUFS UF
       Where P.CODCID = C.CODCID
         And C.UF = UF.CODUF
         And P.CODPARC = CUR_NOTAS.CODPARC;
    
      Select CODTRIB
        Into P_CODTRIB
        From TGFICM
       Where CODRESTRICAO = 503
         And UFORIG = P_CODUF
         And UFDEST = 9;
    
    End If;
  
    Insert Into TGFITE
      (NUNOTA, CODEMP, SEQUENCIA, CODPROD, USOPROD, QTDNEG, ATUALESTOQUE, QTDCONFERIDA, VLRSUBST,
       VLRIPI, VLRDESCBONIF, DTALTER, CODVOL, CODLOCALORIG, CONTROLE, QTDFORMULA, STATUSNOTA,
       BASESUBSTIT, CODUSU, ATUALESTTERC, TERCEIROS, VLRRETENCAO, VLRUNIT, VLRTOT, BASEICMS, VLRICMS,
       ALIQICMS, CODCFO, CODTRIB, CSTIPI)
    Values
      (P_NUNOTA,
       --NUNOTA,
       2,
       --CODEMP,
       1,
       --SEQUENCIA,
       35815,
       --CODPROD,
       'S',
       --USOPROD,
       CUR_NOTAS.QTDE,
       --QTDNEG,
       0,
       --ATUALESTOQUE,
       0,
       --QTDCONFERIDA,
       0,
       --VLRSUBST,
       0,
       --VLRIPI,
       0,
       --VLRDESCBONIF,
       Sysdate,
       --DTALTER,
       (Select CODVOL
           From TGFPRO
          Where CODPROD = 35815),
       --CODVOL
       0,
       --CODLOCALORIG,
       ' ',
       --CONTROLE,
       0,
       --QTDFORMULA,
       'A',
       --STATUSNOTA)
       0,
       --BASESUBSTIT,
       P_CODUSU,
       --CODUSU,
       'N',
       --ATUALESTTERC
       'N',
       --TERCEIROS,
       0,
       --VLRRETENCAO)
       CUR_NOTAS.VLRUNIT,
       -- VLRUNIT
       CUR_NOTAS.VLRCTE,
       -- VLRTOT  -- maior q zero goias
       Case When P_COUNT > 0 Then 0 Else CUR_NOTAS.VLRCTE End,
       --BASE_ICMS
       Case When P_COUNT > 0 Then 0 Else CUR_NOTAS.ICMS End,
       --VLRICMS
       Case When P_COUNT > 0 Then 0 Else Trunc(CUR_NOTAS.ICMS / CUR_NOTAS.VLRCTE * 100) End,
       --ALIQICMS
       P_CODCFOP, P_CODTRIB,
       -- CODTRIB
       49);
  
    Select SEQ_TGFFIN_NUFIN.NEXTVAL
      Into ULT_NUFIN
      From DUAL;
  
    Insert Into TGFFIN
      (NUFIN, NUNOTA, CODEMP, NUMNOTA, SERIENOTA, DTNEG, DHMOV, DTVENCINIC, DTVENC, CODPARC,
       CODTIPOPER, DHTIPOPER, CODNAT, CODCENCUS, CODTIPTIT, VLRDESDOB, CODTIPOPERBAIXA,
       DHTIPOPERBAIXA, PROVISAO, ORIGEM, DTENTSAI, DTALTER, CODVEICULO, RECDESP, DESDOBRAMENTO,
       HISTORICO, CODUSU)
    Values
      (ULT_NUFIN,
       -- NUFIN
       P_NUNOTA,
       -- NUNOTA
       2,
       -- EMPRESA
       CUR_NOTAS.NUMCTE,
       -- NOTA FISCAL
       '',
       -- SERIE NOTA
       Trunc(CUR_NOTAS.DATAEMISSAO),
       -- DTNEG
       Trunc(Sysdate),
       -- DHMOV
       Trunc(Sysdate) + 2000,
       -- DTVENCINIC
       Trunc(Sysdate) + 2000,
       --DTVENC
       CUR_NOTAS.CODPARC,
       -- PARCEIRO
       503,
       -- TOP
       (Select Max(DHALTER)
           From TGFTOP
          Where CODTIPOPER = 503),
       -- DHALTER
       CUR_NOTAS.CODNAT,
       -- NATUREZA
       20200100,
       -- CENTRO RESULTADO
       8,
       -- inserido ted  os. 6253 by rodrigo 26/09/2016
       CUR_NOTAS.VLRCTE,
       --VLRDESDOB
       0,
       (Select Max(DHALTER)
           From TGFTOP
          Where CODTIPOPER = 0),
       -- CODTIPOPERBAIXA
       'S',
       -- PROVISAO
       'E',
       --ORIGEM
       Trunc(Sysdate),
       --DTENTSAI
       Sysdate,
       -- DTALTER
       0,
       -- VEICULO
       -1,
       --RECDESP
       1,
       -- DESDOBRAMENTO
       '', P_CODUSU); --
  
    --- INSERE NA TABELA DE VINCULAÇÃO COMBUSTIVEIS CTE
    If Nvl(CUR_NOTAS.SEQCARGTO, 0) > 0 Then
    
      Select Count(Distinct(ORDEM))
        Into P_COUNT
        From AD_ABASTVINCORDEM
       Where SEQUENCIA = CUR_NOTAS.SEQCARGTO;
      --- MAIS DE UM CONHECIMENTO NA ORDEM DE CARREGAMENTO
      If P_COUNT > 1 And Nvl(CUR_NOTAS.SEQNOTA, 0) = 0 Then
        Raise_Application_Error(-20101,
                                'Existem mais de um conhecimento na ordem de carregamento, deve ser informada a ordem que pertence ao conhecimento!!');
      
      End If;
    
      ---- UM CONHECIMENTO NA ORDEM
      If P_COUNT >= 1 Then
      
        Select NUVINV.NEXTVAL
          Into P_NUVINC
          From DUAL;
      
        --     SELECT NVL(MAX(NUVINC),0) + 1 INTO P_NUVINC FROM TB_VINC_CTRC_ABAST_SF;
      
        Insert Into TB_VINC_CTRC_ABAST_SF
          (NUVINC, NUNOTACTRC, DATAVINC)
        Values
          (P_NUVINC, P_NUNOTA, Trunc(Sysdate));
      
        --- insere abastecimento
        For CUR_ABAST In (Select ABAST.NUNOTA, ABAST.SEQUENCIA
                            From AD_ABASTVINCORDEM ABAST
                           Where ABAST.SEQUENCIA = CUR_NOTAS.SEQCARGTO
                             And ABAST.ORDEM = Nvl(CUR_NOTAS.SEQNOTA, ABAST.ORDEM))
        Loop
        
          -- corrigir quando não houver vinculação                        
          If Nvl(CUR_ABAST.NUNOTA, 0) = 0 Then
            Raise_Application_Error(-20101,
                                    ' O cte está com problema sem vinculação de abastecimento, Tela Controle de carregamento matéria prima sequência:  CTE: ' ||
                                     CUR_NOTAS.NUMCTE || ' Sequência: ' || CUR_ABAST.SEQUENCIA);
          End If;
        
          Insert Into TB_ITEN_CTRC_ABAST_SF
            (NUVINC, NUNOTAABAST)
          Values
            (P_NUVINC, CUR_ABAST.NUNOTA);
        
        End Loop;
      
      End If;
    
    End If; ---  FIM INSERE NA TABELA DE VINCULAÇÃO COMBUSTIVEIS CTE
  
    Begin
    
      Execute Immediate 'ALTER TRIGGER TRG_UPT_AD_ITECTEFAB_SF DISABLE';
    
      Update AD_ITECTEFAB
         Set NUNOTA = P_NUNOTA,
             NUVINC = P_NUVINC
       Where SEQUENCIA = FIELD_SEQUENCIA
         And SEQITE = CUR_NOTAS.SEQITE;
    
      Execute Immediate 'ALTER TRIGGER TRG_UPT_AD_ITECTEFAB_SF ENABLE';
    
    Exception
      When Others Then
      
        Execute Immediate 'ALTER TRIGGER TRG_UPT_AD_ITECTEFAB_SF ENABLE';
      
    End;
  
    Commit;
  
    I := I + 1;
  
  End Loop;

  Update AD_CABCTEFAB
     Set GEROU  = 'SIM',
         CODUSU = P_CODUSU
   Where SEQUENCIA = FIELD_SEQUENCIA;

  P_MENSAGEM := 'Gerado com sucesso, CONFIRA!!! Lançamentos gerados: ' || I;

  -- <ESCREVA SEU CÓDIGO DE FINALIZAÇÃO AQUI> --

End;
/
