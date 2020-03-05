Create Or Replace Procedure "AD_STP_COT_GERAPEDCPA"(p_Codusu    Number,
                                                    p_Idsessao  Varchar2,
                                                    p_Qtdlinhas Number,
                                                    p_Mensagem  Out Varchar2) As
  r_Cot         ad_tabcotcab%Rowtype;
  r_Forn        ad_tabcotforn%Rowtype;
  r_Top         tgftop%Rowtype;
  v_Pedido      Boolean;
  v_Dhtipvenda  Date;
  v_Nunota      Int;
  v_Tipatualest Int;
  v_Provisao    Char(1);
  v_Vlrfrete    Float := 0;
  v_Vlrnota     Float := 0;
  v_Vlrtotdesc  Float := 0;
  v_Nufin       Int;
  v_Titulo      Varchar(4000);
  v_Mensagem    Varchar(4000);
  v_Incluir     Boolean;
  v_Count       Int := 0;

Begin

  /****************************************************************************************************************
  Autor: Marcus Rangel - SNk
  Rotina: Cotação de serviços de Transportes
  Objetivo: Gerar um pedido de compras para o fornecedor vencedor da cotação ou atualizar o pedido d compras de origem
  com os valores e os dados do fornecedor vencedor;
  Dt. Criação/Alteração: 10/04/2017
  ******************************************************************************************************************/

  For i In 1 .. p_Qtdlinhas
  Loop
    r_Cot.Numcotacao := Act_Int_Field(p_Idsessao, i, 'NUMCOTACAO');
  
    /* Busca os dados do registro na tela */
    Select *
      Into r_Cot
      From Ad_Tabcotcab Cab
     Where Cab.Numcotacao = r_Cot.NumCotacao;
  
    If r_Cot.Situacao Not In ('C', 'L') Then
      p_Mensagem := 'Somente cotações concluídas/liberadas podem gerar pedidos.';
      Return;
    End If;
  
    If r_Cot.Nunota Is Null Then
      --p_Mensagem := 'Cotação já possui pedido de compra gerado. Nro. Único: ' || r_Cot.Nunota;
      --Return;
      v_Pedido := True;
    End If;
  
    /* Busca os dados do fornecedor vencedor */
    Begin
      Select *
        Into r_Forn
        From Ad_Tabcotforn f
       Where f.Numcotacao = r_Cot.Numcotacao
         And f.Vencedor = 'S';
    Exception
      /* Tratativa para quando houver mais de um fornecedor marcado como vencedor */
      When Too_Many_Rows Then
        v_Titulo   := 'Alerta! Mais de um fornecedor  vencedor';
        v_Mensagem := 'Existem mais de um Fornecedor vencedor. O primeiro registro será utilizado como forncedor da cotação. \n Confirma?';
        If p_Idsessao Is Null Then
          v_Incluir := True;
        Else
          v_Incluir := Act_Confirmar(v_Titulo, v_Mensagem, p_Idsessao, i);
        End If;
      
        /* Busca o primeiro registro */
        If v_Incluir Then
          Select f.Codparc, f.Codcontato
            Into r_Forn.Codparc, r_Forn.Codcontato
            From Ad_Tabcotforn f
           Where f.Numcotacao = r_Cot.Numcotacao
             And f.Vencedor = 'S'
             And Rownum = 1;
        End If;
      
      /* Tratativa para quando não houver fornecedor vencedor */
      When No_Data_Found Then
        p_Mensagem := 'Nenhum fornecedor Vencedor encontrado';
        Return;
    End;
  
    If v_Pedido Then
      /* Busca as datas da TOP e do TIPNEG */
      Begin
        Select *
          Into r_Top
          From Tgftop t
         Where t.Codtipoper = r_Cot.Codtipoper
           And t.dhalter = ad_get.maxdhtipoper(r_Cot.Codtipoper);
      Exception
        When No_Data_Found Then
          p_Mensagem := 'Não foi informada nenhuma TOP para gerar o pedido de compras';
          Return;
      End;
    
      If r_Top.AtualEst = 'N' Then
        v_Tipatualest := 0;
      Elsif r_Top.AtualEst = 'E' Then
        v_Tipatualest := 1;
      Elsif r_Top.AtualEst = 'B' Then
        v_Tipatualest := -1;
      Elsif r_Top.AtualEst = 'R' Then
        v_Tipatualest := 0;
      End If;
    
      If r_Top.Tipatualfin = 'I' Then
        v_Provisao := 'N';
      Elsif r_Top.Tipatualfin = 'P' Then
        v_Provisao := 'S';
      End If;
    
      v_Dhtipvenda := ad_get.maxdhtipvenda(r_Cot.Codtipvenda);
    
      /* Busca o Próximo NUNOTA*/
      /*stp_obtemid('TGFCAB', v_Nunota);*/
    
      /* Busca o comprador */
      If r_cot.codvend Is Null Then
        Begin
          Select codvend
            Into r_cot.codvend
            From tsiusu u
           Where codusu = stp_get_codusulogado;
        Exception
          When no_data_found Then
            Select g.codvend
              Into r_cot.codvend
              From tsiusu u
              Join tsicus c
                On u.codcencuspad = c.codcencus
              Join tsiusu g
                On g.codusu = c.codusuresp
             Where u.codusu = stp_get_codusulogado;
        End;
      End If;
    
      If r_cot.codvend Is Null Then
        p_mensagem := 'Por favor informe o código do comprador na aba preferências do pedido!';
        Return;
      End If;
    
      -- valida cr nat proj
      Begin
        ad_stp_valida_natcrproj_sf(p_codemp => r_cot.codemp, p_Codtipoper => r_cot.codtipoper,
                                   p_codnat => r_cot.codnat, p_codcencus => r_cot.codcencus,
                                   p_codproj => r_cot.codproj, p_tipoSaida => 0,
                                   p_p_Mensagem => p_Mensagem);
        If p_Mensagem Is Not Null Then
          Return;
        End If;
      
      End;
    
      /* Insere o cabeçalho do pedido de compras */
      ad_set.Ins_Pedidocab(p_Codemp => r_Cot.codemp, p_Codparc => r_Forn.Codparc,
                           p_Codvend => r_cot.codvend, p_Codtipoper => r_Cot.Codtipoper,
                           p_Codtipvenda => r_Cot.Codtipvenda, p_Dtneg => Trunc(Sysdate),
                           p_Vlrnota => r_Forn.Vlrtot, p_Codnat => r_cot.codnat,
                           p_Codcencus => r_Cot.Codcencus, p_codproj => 0,
                           p_Obs => 'Cotação: ' || To_Char(r_Cot.Numcotacao), p_Nunota => v_Nunota);
    
      /*      If p_Mensagem Is Not Null Then
        Return;
      End If;*/
    
      Begin
        Update tgfcab
           Set tipfrete = r_Forn.Tipfrete, cif_fob = r_Forn.Cif_Fob, vlrfrete = r_forn.vlrfrete
         Where nunota = v_Nunota;
      Exception
        When Others Then
          p_Mensagem := Sqlerrm;
          Return;
      End;
    
      /*      Begin
        Insert Into Tgfcab
          (Nunota, Codemp, codnat, Codcencus, codproj, Numnota, Dtneg, Dtmov, Codempnegoc, Codparc, Codtipoper,
           Dhtipoper, Tipmov, Codtipvenda, Dhtipvenda, observacao, Pendente, Vlrnota, Tipfrete, Cif_Fob, Statusnota,
           Vlrfrete, dtalter)
        Values
          (v_Nunota, r_Cot.Codemp, r_Cot.Codnat, r_Cot.Codcencus, r_Cot.Codproj, 0, Trunc(Sysdate), Sysdate,
           r_Cot.Codemp, r_Forn.Codparc, r_Cot.Codtipoper, r_Top.Dhalter, r_Top.Tipmov, r_Cot.Codtipvenda, v_Dhtipvenda,
           'Cotação: ' || To_Char(r_Cot.Numcotacao), 'S', r_Forn.Vlrtot, r_Forn.Tipfrete, r_Forn.Cif_Fob, 'A',
           r_forn.Vlrfrete, Sysdate);
      Exception
        When Others Then
          p_Mensagem := 'Erro ao inserir o cabeçalho do pedido. ' || chr(13) || Sqlerrm;
          Return;
      End;*/
    
      /* Busca os dados dos produtos do fornecedor vencedor */
      For c_Prod In (Select *
                       From Ad_Tabcotite Ite
                      Where Ite.Numcotacao = r_Cot.Numcotacao
                        And Ite.Nuregforn = r_Forn.Nuregforn)
      Loop
      
        /* Insere os produtos */
      
        ad_set.ins_pedidoitens(v_Nunota, c_Prod.Codprod, c_prod.qtdneg, c_Prod.Vlrunit,
                               c_Prod.Vlrtotal, p_Mensagem);
      
        If p_Mensagem Is Not Null Then
          Return;
        End If;
      
        v_Vlrnota    := v_Vlrnota + c_Prod.Vlrtotal;
        v_Vlrfrete   := v_Vlrfrete + c_Prod.Vlrfrete;
        v_Vlrtotdesc := v_Vlrtotdesc + c_Prod.Vlrdesconto;
      
        /* Atualiza a solicitação */
        Begin
          Update ad_tsfsstm m
             Set m.vlrunit = c_Prod.Vlrunit
           Where m.codsolst = r_Cot.Codsolst
             And m.codserv = c_prod.codprod
             And m.codmaq = c_Prod.Codmaq;
        Exception
          When Others Then
            p_Mensagem := 'Erro ao atualizar a solicitação. ' || Chr(13) || Sqlerrm;
            Return;
        End;
      
      End Loop;
    
      /* Atualiza os valores da nota, do desconto e do frete no cabeçalho */
      Begin
        Update Tgfcab c
           Set c.Vlrnota = v_Vlrnota, c.Vlrdesctot = v_Vlrtotdesc, c.Vlrfrete = v_Vlrfrete
         Where Nunota = v_Nunota;
      Exception
        When Others Then
          p_Mensagem := 'Erro ao atualizar os totais do pedido. ' || Chr(13) || Sqlerrm;
          Return;
      End;
    
      /* Insere o Financeiro */
    
      /* Verifica se a TOP atualiza o financeiro */
      If r_Top.Atualfin <> 0 Then
      
        /* Conta as parcelas do tipneg */
        For c_Tpv In (Select *
                        From Tgfppg Ppg
                       Where Codtipvenda = r_Cot.Codtipvenda
                       Order By Codtipvenda, Sequencia)
        Loop
        
          Begin
          
            stp_keygen_nufin(p_ultcod => v_nufin);
          
            Insert Into Tgffin
              (Nufin, Codemp, Numnota, Dtneg, Desdobramento, Dhmov, Dtvenc, Codparc, Codtipoper,
               Dhtipoper, Codctabcoint, Codnat, Codcencus, Codproj, Codtiptit, Vlrdesdob, Recdesp,
               Provisao, Origem, Nunota, Codusu, dtalter)
            Values
              (v_Nufin, r_Cot.Codemp, 0, Trunc(Sysdate), c_Tpv.Sequencia, Sysdate,
               Trunc(Sysdate + c_Tpv.Prazo), r_Forn.Codparc, r_Cot.Codtipoper, r_Top.Dhalter,
               c_Tpv.Codctabcoint, r_Cot.Codnat, r_Cot.Codcencus, r_Cot.Codproj, c_Tpv.Codtiptitpad,
               (v_Vlrnota * (c_Tpv.Percentual / 100)), r_Top.Atualfin, v_Provisao, 'E', v_Nunota,
               r_Cot.Codusu, Sysdate);
          
          Exception
            When Others Then
              p_Mensagem := 'Erro na inclusão das parcelas do financeiro. ' || Chr(13) || Sqlerrm;
              Return;
          End;
        
        End Loop c_Tpv;
      Else
        Null;
      End If;
    
      Begin
      
        Update ad_tabcotcab c
           Set c.nunota = v_Nunota, c.situacao = 'C'
         Where c.numcotacao = r_Cot.Numcotacao;
      
      Exception
        When Others Then
          p_Mensagem := 'Erro ao atualizar numeração. ' || Chr(13) || Sqlerrm;
          Return;
      End;
    
      v_Mensagem := 'Foi gerado o Pedido de Compras número: <a target="_parent" href="' ||
                    ad_fnc_urlskw('TGFCAB', v_Nunota) || '"><b><font color="#0000FF">' || v_Nunota ||
                    '</font></b></a>';
    
    Else
    
      v_Count := 0;
    
      Select Count(*)
        Into v_Count
        From tgfcab c
       Where c.nunota = r_Cot.Nunota
         And c.pendente = 'S'
         And Nvl(c.ad_cotfrete, 'N') = 'S';
    
      If v_Count != 0 Then
        p_Mensagem := 'Atualização de valores já realizada.';
        Return;
      End If;
    
      -- Verifica se existe na TGFVAR
      v_Count := 0;
    
      Select Count(*)
        Into v_Count
        From tgfvar v
       Where v.nunotaorig = r_Cot.Nunota
         And v.nunota <> v.nunotaorig;
    
      -- Se existir, usa o NUNOTA da nota
      If v_count <> 0 Then
        Select nunota
          Into r_Cot.Nunota
          From tgfvar v
         Where v.nunotaorig = r_Cot.Nunota
           And v.nunota <> v.nunotaorig;
      End If;
    
      -- Devolve o valor vencedor da cotação para o lançamento de origem.
      -- se o pedido estiver faturado, o valor do frete será atualizado na nota de compra
      Update tgfcab c
         Set c.vlrfrete = r_Forn.Vlrtot, c.vlrfretetotal = r_Forn.Vlrtot,
             c.codparctransp = r_forn.codparc, c.tipfrete = r_Forn.Tipfrete, c.ad_cotfrete = 'N',
             c.cif_fob = r_Forn.Cif_Fob, c.vencfrete = Sysdate + 5
       Where c.nunota = r_Cot.Nunota;
    
      --Update ad_tsfsstc c Set c.codparc = r_Forn.Codparc Where c.codsolst = r_Cot.Codsolst;
    
      For c_Itens In (Select *
                        From ad_tabcotite i
                       Where i.numcotacao = r_Cot.Numcotacao
                         And i.nuregforn = r_Forn.Nuregforn)
      Loop
        Update ad_tsfssti si
           Set si.vlrunit = c_Itens.Vlrtotal, si.qtdneg = c_Itens.Qtdneg,
               si.vlrtot = c_Itens.Qtdneg * c_Itens.Vlrtotal
         Where si.codsolst = r_Cot.Codsolst
           And si.codserv = c_Itens.Codprod;
      End Loop;
    
      Begin
        ad_set.Ins_Liberacao(p_Tabela => 'TGFCAB', p_Nuchave => r_Cot.Nunota, p_Evento => 1011,
                             p_Valor => v_Vlrnota, p_Codusulib => 950,
                             p_Obslib => 'Ref. Cotação de serviços nº ' || r_cot.numcotacao,
                             p_p_Mensagem => p_Mensagem);
        If p_Mensagem Is Not Null Then
          Rollback;
          p_mensagem := p_Mensagem;
          Return;
        End If;
      
      Exception
        When Others Then
          p_mensagem := 'Erro ao inserir o pedido de liberação para o pedido nº único ' ||
                        r_cot.nunota || '. <br>' || Sqlerrm;
          Return;
      End;
    
      v_Mensagem := 'O pedido de compras <a target="_parent" href="' ||
                    ad_fnc_urlskw('TGFCAB', r_Cot.Nunota) || '"><b><font color="#0000FF">' ||
                    r_Cot.Nunota || '</font></b></a> foi atualizado com sucesso!!!';
    
    End If;
  
  End Loop i;

  p_Mensagem := v_Mensagem;


End;
/
