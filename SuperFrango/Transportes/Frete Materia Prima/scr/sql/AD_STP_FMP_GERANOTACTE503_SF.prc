Create Or Replace Procedure AD_STP_FMP_GERANOTACTE503_SF(p_codusu    Number,
                                                         p_idsessao  Varchar2,
                                                         p_qtdlinhas Number,
                                                         p_mensagem  Out Varchar2) Is
  v_sequencia Number;
  p_nunota    Number;
  p_count     Number;
  ult_nufin   Number;
  i           Number;
  p_codcfop   Int;
  p_codtrib   Int;
  v_nuvinc    Number;

  vei tgfvei%Rowtype;
  cab tgfcab%Rowtype;

Begin

  /* 
  Autor: M. Rangel - 22/11/2018
  Processo: Frete matéria prima
  Objetivo: Substituir a proc STP_GERA_LANC_TOP_503_SF, basicamente faz o mesmo de antes, porém com correções 
            e implementar o método de correção do vencimento.
  */

  --p_codusu    := 0;
  --p_qtdlinhas := 1;
  --v_sequencia := 36;

  If p_qtdlinhas > 1 Then
    p_mensagem := 'Selecione apenas 1 perído por vez!';
    Return;
  End If;

  v_sequencia := act_int_field(p_idsessao, 1, 'SEQUENCIA');

  Select Count(*)
    Into p_count
    From ad_cabctefab
   Where sequencia = v_sequencia
     And gerou = 'SIM';

  /*     
  if P_COUNT > 0 then  
       raise_application_error(-20101,'Essa sequência foi gerada - INTERROMPENDO!!!! ');  
  end If;
  */

  Select Count(*)
    Into p_count
    From ad_itectefab
   Where sequencia = v_sequencia
     And Nvl(gerar, 'NÃO') = 'SIM'
     And (codnat = 0 Or placa Is Null);

  If p_count > 0 Then
    p_mensagem := 'Existem lançamentos com natureza 0 (zero) ou veículo sem placa - INTERROMPENDO!!!! ';
    Return;
  End If;

  i := 0;

  For cur_notas In
  
   (Select ite.seqite,
           Trunc(ite.dataemissao) dataemissao,
           ite.numcte,
           ite.serie,
           ite.codparc,
           ite.qtde,
           ite.vlrcte,
           To_Number(Replace(ite.icms, '.', ',')) icms,
           ite.chavecte,
           ite.codnat,
           Round(ite.vlrcte / ite.qtde, 6) As vlrunit,
           placa,
           ite.seqcargto,
           ite.seqnota,
           ite.codcidinicte,
           ite.codcidfimcte
      From ad_cabctefab c, ad_itectefab ite
     Where c.sequencia = ite.sequencia
       And c.sequencia = v_sequencia
       And Nvl(ite.gerar, 'NÃO') = 'SIM'
       And Nvl(ite.nunota, 0) = 0
    --And ite.seqite = :seqcargto
    )
  Loop
  
    -- M. Rangel 21/11/18
    Begin
      Select *
        Into vei
        From tgfvei
       Where codparc = cur_notas.codparc
         And placa = Trim(cur_notas.placa)
         And ativo = 'S';
    Exception
      When no_data_found Then
        p_mensagem := 'O veículo placa: ' || cur_notas.placa || ' O código do parceiro: ' ||
                      cur_notas.codparc || '  não está cadastrado ou ativo !!!!';
        Return;
      When too_many_rows Then
        p_mensagem := 'O veículo placa: ' || cur_notas.placa || ' tem mais de um cadastro !!!!';
        Return;
      When Others Then
        p_mensagem := 'Erro desconhecido - ' || Sqlerrm;
        Return;
    End;
    --
  
    -- AJUSTA CASO O PARCEIRO NÃO SEJA EMITENTE DE NFE
    For p In (Select *
                From tgfpar
               Where codparc = cur_notas.codparc
                 And Nvl(ad_nfe, 'N') = 'N')
    Loop
      Begin
        Update tgfpar par
           Set par.ad_nfe = 'S'
         Where par.codparc = p.codparc;
        --Commit;
      Exception
        When Others Then
          p_mensagem := 'Erro ao corrigir cadastro do parceiro! ' || Sqlerrm;
          Return;
      End;
    End Loop;
  
    Begin
    
      stp_keygen_tgfnum('TGFCAB', 1, 'TGFCAB', 'NUNOTA', 0, p_nunota);
    
      -- modelo de nota
      Select *
        Into cab
        From tgfcab
       Where nunota = 31658398;
    
      Select tipmov, codmoddoc, dhalter
        Into cab.tipmov, cab.codmoddocnota, cab.dhtipoper
        From tgftop
       Where codtipoper = cab.codtipoper
         And dhalter = ad_get.Maxdhtipoper(cab.codtipoper);
    
      Begin
        Insert Into tgfcab
          (codparc, nunota, numnota, serienota, dtalter, dtmov, dtneg, dtfatur, dtentsai,
           statusnota, tipmov, codusu, codcencus, codnat, codtipoper, dhtipoper, codtipvenda,
           dhtipvenda, codemp, pendente, codempnegoc, vlrnota, rateado, issretido, irfretido,
           codvend, ad_chavenfe, chavenfe, codveiculo, codparctransp, codmoddocnota, codcidinicte,
           codcidfimcte)
        Values
          (cur_notas.codparc, p_nunota, cur_notas.numcte, cur_notas.serie, Sysdate, Trunc(Sysdate),
           cur_notas.dataemissao, cur_notas.dataemissao, Trunc(Sysdate), cab.statusnota, cab.tipmov,
           p_codusu, cab.codcencus, cur_notas.codnat, cab.codtipoper, cab.dhtipoper, cab.codtipvenda,
           ad_get.Maxdhtipvenda(cab.codtipvenda), cab.codemp, cab.pendente, cab.codempnegoc,
           Cur_Notas.Vlrcte, 'N', 'N', 'N', cab.codvend, cur_notas.chavecte, cur_notas.chavecte,
           vei.codveiculo, Cur_Notas.codparc, cab.codmoddocnota, cur_notas.codcidinicte,
           cur_notas.codcidfimcte);
      Exception
        When Others Then
          p_mensagem := 'Erro ao inserir o cabeçalho da nota!<br>' ||
                        dbms_utility.format_error_stack;
          Return;
      End;
    
      For u In (Select ad_get.Ufparcemp(cur_notas.codparc, 'P') coduf
                  From dual)
      Loop
        Select Case
                 When u.coduf = 9 Then
                  t.codcfo_entrada
                 Else
                  t.codcfo_entrada_fora
               End,
               (Select codtrib
                  From tgficm
                 Where codrestricao = cab.codtipoper
                   And ufdest = 9
                   And uforig = u.coduf)
          Into p_codcfop, p_codtrib
          From tgftop t
         Where t.codtipoper = cab.codtipoper
           And t.dhalter = cab.dhtipoper;
      End Loop;
    
      Begin
        Insert Into tgfite
          (nunota, codemp, sequencia, codprod, usoprod, qtdneg, atualestoque, qtdconferida,
           vlrsubst, vlripi, vlrdescbonif, dtalter, codvol, codlocalorig, controle, qtdformula,
           statusnota, basesubstit, codusu, atualestterc, terceiros, vlrretencao, vlrunit, vlrtot,
           baseicms, vlricms, aliqicms, codcfo, codtrib, cstipi)
        Values
          (p_nunota, cab.codemp, 1, 35815, 'S', cur_notas.qtde, 0, 0, 0, 0, 0, Sysdate,
           (Select codvol
               From tgfpro
              Where codprod = 35815), 0, ' ', 0, 'A', 0, p_codusu, 'N', 'N', 0, cur_notas.vlrunit,
           cur_notas.vlrcte, Case When p_count > 0 Then 0 Else cur_notas.vlrcte End,
           Case When p_count > 0 Then 0 Else cur_notas.icms End,
           Case When p_count > 0 Then 0 Else Trunc(cur_notas.icms / cur_notas.vlrcte * 100) End,
           p_codcfop, p_codtrib, 49);
      Exception
        When Others Then
          p_mensagem := 'Erro ao inserir o serviço da nota!<br>' || dbms_utility.format_call_stack;
          Return;
      End;
    
      Begin
        stp_keygen_nufin(ult_nufin);
      
        Insert Into tgffin
          (nufin, nunota, codemp, numnota, dtneg, dhmov, dtvencinic, dtvenc, codparc, codtipoper,
           dhtipoper, codnat, codcencus, codtiptit, vlrdesdob, codtipoperbaixa, dhtipoperbaixa,
           provisao, origem, dtentsai, dtalter, codveiculo, recdesp, desdobramento, codusu)
        Values
          (ult_nufin, p_nunota, cab.codemp, cur_notas.numcte, Trunc(cur_notas.dataemissao),
           Trunc(Sysdate), Trunc(Sysdate) + 2000, Trunc(Sysdate) + 2000, cur_notas.codparc,
           cab.codtipoper, cab.dhtipoper, cur_notas.codnat, cab.codcencus, 8, cur_notas.vlrcte, 0,
           ad_get.Maxdhtipoper(0), 'S', 'E', Trunc(Sysdate), Sysdate, 0, -1, 1, p_codusu);
      Exception
        When Others Then
          p_mensagem := 'Erro ao inserir o financeiro da nota!<br>' ||
                        dbms_utility.format_error_stack;
          Return;
      End;
    
      -- Atualiza vencimento de acordo com Teto
      Begin
        ad_pkg_fmp.set_vlrdesconto_quebra(v_sequencia, cur_notas.seqite, ad_pkg_var.ErrMsg);
        If ad_pkg_var.ErrMsg Is Not Null Then
          ad_pkg_var.ErrMsg := ad_pkg_var.ErrMsg ||
                               '<br>Ocorreu um erro ao calcular a quebra/desconto do Cte ' ||
                               cur_notas.numcte;
        End If;
      End;
    
      --- INSERE NA TABELA DE VINCULAÇÃO COMBUSTIVEIS CTE
      If Nvl(cur_notas.seqcargto, 0) > 0 Then
      
        Select Count(Distinct(ordem))
          Into p_count
          From ad_abastvincordem
         Where sequencia = cur_notas.seqcargto;
        --- MAIS DE UM CONHECIMENTO NA ORDEM DE CARREGAMENTO
        If p_count > 1 And Nvl(cur_notas.seqnota, 0) = 0 Then
          p_mensagem := 'Existem mais de um conhecimento na ordem de carregamento, deve ser informada a ordem que pertence ao conhecimento!!';
          Return;
        
        End If;
      
        ---- UM CONHECIMENTO NA ORDEM
        If p_count >= 1 Then
        
          Select nuvinv.nextval
            Into v_nuvinc
            From dual;
        
          Begin
            Insert Into tb_vinc_ctrc_abast_sf
              (nuvinc, nunotactrc, datavinc)
            Values
              (v_nuvinc, p_nunota, Trunc(Sysdate));
          Exception
            When Others Then
              p_mensagem := 'Erro ao atualizar vinculação de abastecimento!<br>' ||
                            dbms_utility.format_error_stack;
              Return;
          End;
        
          --- insere abastecimento
          For cur_abast In (Select abast.nunota, abast.sequencia
                              From ad_abastvincordem abast
                             Where abast.sequencia = cur_notas.seqcargto
                               And abast.ordem = Nvl(cur_notas.seqnota, abast.ordem))
          Loop
          
            -- corrigir quando não houver vinculação                        
            If Nvl(cur_abast.nunota, 0) = 0 Then
              p_mensagem := 'O cte está com problema sem vinculação de abastecimento, ' ||
                            'Tela Controle de carregamento matéria prima sequência:  CTE: ' ||
                            cur_notas.numcte || ' Sequência: ' || cur_abast.sequencia;
              Return;
            End If;
          
            Begin
              Insert Into tb_iten_ctrc_abast_sf
                (nuvinc, nunotaabast)
              Values
                (v_nuvinc, cur_abast.nunota);
            Exception
              When Others Then
                p_mensagem := 'Erro ao atualizar vinculação de abastecimento!<br>' ||
                              dbms_utility.format_error_stack;
                Return;
            End;
          
          End Loop;
        
        End If;
      
      End If;
    
      ---FIM INSERE NA TABELA DE VINCULAÇÃO COMBUSTIVEIS CTE
      Begin
        variaveis_pkg.v_atualizando := True;
      
        Update ad_itectefab
           Set nunota = p_nunota,
               nuvinc = v_nuvinc
         Where sequencia = v_sequencia
           And seqite = cur_notas.seqite;
      
        variaveis_pkg.v_atualizando := False;
      
      Exception
        When Others Then
          variaveis_pkg.v_atualizando := False;
      End;
    
      --Commit;
    
      i := i + 1;
    
    End Loop;
  
    Begin
      Update ad_cabctefab
         Set gerou  = 'SIM',
             codusu = p_codusu
       Where sequencia = v_sequencia;
    Exception
      When Others Then
        p_mensagem := 'Erro ao atualizar a informação sobre a geração do registro atual.<br>' ||
                      Sqlerrm;
        Return;
    End;
  
  End Loop;

  If ad_pkg_var.ErrMsg Is Null Then
    p_mensagem := 'Gerado com sucesso, CONFIRA!!! Lançamentos gerados: ' || i;
  Else
    p_mensagem := 'Gerado com sucesso, CONFIRA!!! Lançamentos gerados: ' || i || '<br>' ||
                  ad_pkg_var.ErrMsg;
  End If;

End;
/
