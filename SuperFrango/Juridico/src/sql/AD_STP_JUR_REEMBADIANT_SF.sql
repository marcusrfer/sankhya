Create Or Replace Procedure "AD_STP_JUR_REEMBADIANT_SF"(p_Codusu    Number,
                                                        p_Idsessao  Varchar2,
                                                        p_Qtdlinhas Number,
                                                        p_Mensagem  Out Varchar2) As
  Jur Ad_Jurite%Rowtype;
  Par Ad_Jurparam%Rowtype;
  Tmp ad_jurtmp%Rowtype;

  v_Obscompl Varchar2(4000);
  v_Valor Float;
  i Int Default 0;
  p Ad_Pkg_Jur.Type_Rec_Desp_Jur;
  v_Confirmado Boolean := False;

  jur_exception Exception;
  --Pragma exception_init(jur_exception);

Begin
  /*
  ** Autor: M.Rangel
  ** Processo: Adiantamentos Jur�dicos
  ** Objetivo: Processo o reembolso depois da decis�o do processo
  */

  Ad_Pkg_Jur.Processo_Juridico := True;

  --p_idsessao := 'debug';

  /* populando par�metros */
  tmp.Favorecido := Act_Txt_Param(p_Idsessao, 'FAVORECIDO');
  tmp.Conta := To_Number(Act_Txt_Param(p_Idsessao, 'CONTA'));
  tmp.Ctadeb := To_Number(Act_Txt_Param(p_Idsessao, 'CTADEB'));
  tmp.Valor := Nvl(Act_Dec_Param(p_Idsessao, 'VALOR'), 0);
  tmp.Parcial := Nvl(Act_Txt_Param(p_Idsessao, 'PARCIAL'), 'N');
  tmp.Parcelafinal := Nvl(Act_Txt_Param(p_Idsessao, 'PARCELAFINAL'), 'S');
  tmp.Vlrdesp := Nvl(Act_Dec_Param(p_Idsessao, 'VLRDESP'), 0);
  tmp.Vlrjuros := Nvl(Act_Dec_Param(p_Idsessao, 'VLRJUROS'), 0);
  tmp.Vlrdespjur := Nvl(Act_Dec_Param(p_Idsessao, 'VLRDESPJUR'), 0);
  tmp.Codnat := Nvl(Act_Int_Param(p_Idsessao, 'CODNAT'), 0);
  tmp.Nupasta := Act_Int_Field(p_Idsessao, 1, 'NUPASTA');
  tmp.Seq := Act_Int_Field(p_Idsessao, 1, 'SEQ');

  If Upper(p_Idsessao) = 'DEBUG' Then
    tmp.Nupasta := 999999;
    Tmp.Seq := 268;
  
    Begin
      Select *
        Into tmp
        From ad_jurtmp t
       Where t.nupasta = tmp.Nupasta
         And t.seq = Tmp.Seq;
    
    Exception
      When no_data_found Then
        p_mensagem := 'Reembolso n�o pode ser realizado, verifique se o adiantamento foi realizado previamente!';
        Dbms_Output.put_line(p_Mensagem);
        --Raise jur_exception;
    End;
  
  End If;

  -- popula record com valores da jurite
  Select *
    Into Jur
    From Ad_Jurite
   Where Nupasta = tmp.Nupasta
     And Seq = Tmp.Seq;

  -- busca os valores dos par�metros
  Select * Into Par From Ad_Jurparam Where Nujurpar = 1;

  -- se conta do d�bito � nula
  If tmp.Ctadeb Is Null Then
  
    --busca a contra partida do cadastro da conta
    Select Ad_Codctabcocp
      Into tmp.Ctadeb
      From Tsicta
     Where Codctabcoint = tmp.Conta
       And Ativa = 'S';
  
    -- se tem contra no cadastro, pergunta se deseja usar  
    If tmp.Ctadeb Is Not Null And
       Act_Escolher_Simnao('Valida��o de par�metro',
                           'A conta de d�bito n�o foi informada, deseja utilizar a contra contra partida (' ||
                            tmp.Ctadeb || ')?', p_Idsessao, 1) = 'N' Then
      Raise jur_exception;
    End If;
  
  End If;

  -- busca os parametros da tela de parametros
  Ad_Pkg_Jur.Get_Param_Jur(tmp.Nupasta, Tmp.Seq, p.Codtopdesp, p.Codtoprec, p.Codtopbxrec, p.Codtopbxdesp,
                           p.Codtoptransf, p.Codtiptit, p.Nueventojur, p.Nueventofin, p.Nueventoreemb,
                           p.Usulibjur, p.Usulibfin, p.Codnatdesp, p.Codnatrec);

  /*fim preenchimento vari�veis*/

  /* valida��es */

  -- se selecionado apenas um registro
  If p_Qtdlinhas > 1 Then
    p_Mensagem := Ad_Fnc_Formataerro('Selecione apenas um registro para efetuar o reembolso');
    Raise jur_exception;
  End If;

  -- se possui adiantamento 
  If Jur.Nufin Is Null Then
    p_Mensagem := Ad_Fnc_Formataerro('Lan�amento n�o possui despesa gerada previamente!!');
    Raise jur_exception;
  End If;

  -- se n�o � parcial e consta reembolso realizado
  If Nvl(tmp.Parcial, 'N') = 'N' And Jur.Reembfeito = 'S' Then
    p_Mensagem := Ad_Fnc_Formataerro('Reembolso j� foi realizado, verifique os lan�amentos vinculados a este processo para identificar o reembolso.');
    Raise jur_exception;
  End If;

  If Nvl(tmp.Parcial, 'N') = 'S' And Nvl(tmp.Parcelafinal, 'N') = 'N' And Nvl(tmp.Vlrjuros, 0) > 0 Then
    p_Mensagem := Ad_Fnc_Formataerro('Se o valor � parcial, os valores de despesas/receitas extras s� podem ser informados na �ltima parcela do reembolso');
    Raise jur_exception;
  End If;

  /* M. Rangel
  -- comentado em 04/12/18
  If Nvl(tmp.Parcial, 'N') = 'N' And
     jur.valor + Nvl(tmp.Vlrjuros, 0) - Nvl(tmp.Vlrdesp, 0) - Nvl(tmp.Vlrdespjur, 0) <> tmp.Valor Then
    p_mensagem := ad_fnc_formataerro('A soma dos valores n�o batem!!! Por favor, verifique os valores de reembolso e despesas/receitas!<br>' ||
                                     tmp.Valor || ' + ' || tmp.Vlrdesp || ' + ' || tmp.Vlrdespjur ||
                                     ' <> ' || jur.valor);
    Raise jur_exception;
  End If;
  
  
  -- M. Rangel
  -- comentado em 04/12/18 pois foi encontrada uma ocorr�ncia
  -- pasta 3386 em que houve condena��o e houve rendimento pelo tempo
  -- que demorou a decis�o.
  If tmp.Favorecido = '2' And tmp.Vlrjuros > 0 Then
    p_mensagem := ad_fnc_formataerro('N�o � permitido informar rendimentos do valor quando a decis�o do processo favorece o <b>Reaclamante</b>');
    Raise jur_exception;
  End If;*/

  /*fim valida��es*/

  /* libera��o */
  Savepoint inicio_transacao;
  <<inicio_liberacao>>
  If Nvl(Jur.Libreembolso, 'N') = 'N' Then
  
    -- se n�o possui libera��es pendentes
    If ad_get.Temlib(tmp.Nupasta, 'AD_JURITE', Tmp.Seq, par.NUEVENTOLIBREEMB) = 0 Then
    
      If tmp.Valor > 0 Then
        v_Valor := tmp.Valor;
      Else
        v_valor := tmp.Vlrdespjur;
      End If;
    
      -- get /set seqcascata
      Begin
        Select Nvl(Max(Seqcascata), 0) + 1
          Into tmp.seqcascata
          From Tsilib l
         Where l.Tabela = 'AD_JURITE'
           And l.Nuchave = tmp.Nupasta
           And l.Sequencia = Tmp.Seq;
      Exception
        When Others Then
          tmp.Seqcascata := 0;
      End;
    
      v_Obscompl := 'Favorecido: ' || Case
                      When tmp.Favorecido = 1 Then
                       'Reclamada'
                      Else
                       'Reclamante'
                    End || Chr(13) || 'Vlr. Reembolso: ' || Ad_Get.Formatavalor(tmp.Valor) || Chr(13) ||
                    'Vlr. Desp. Fin: ' || Ad_Get.Formatavalor(tmp.Vlrdesp) || Chr(13) || 'Vlr. Desp. Jur: ' ||
                    Ad_Get.Formatavalor(tmp.Vlrdespjur) || Chr(13) || 'Natureza Desp. Jur: ' ||
                    Ad_Get.Descrnatureza(tmp.Codnat) || Chr(13) || 'Vlr. Juros: ' ||
                    Ad_Get.Formatavalor(tmp.Vlrjuros) || Chr(13) || 'Parcial?: ' || Case
                      When tmp.Parcial = 'S' Then
                       'Sim'
                      Else
                       'N�o'
                    End || Chr(13) || '�ltima parcela?:' || Case
                      When tmp.Parcelafinal = 'S' Then
                       'Sim'
                      Else
                       'N�o'
                    End;
    
      <<insere_Lib>>
      Begin
      
        Select Nvl(Max(l.Numlinha), 0) + 1
          Into i
          From Ad_Jurlib l
         Where l.Nupasta = tmp.Nupasta
           And l.Seq = Tmp.Seq;
      
        -- insere a solicita��o da libera��o
        Insert Into Tsilib
          (Tabela, Nuchave, Sequencia, Seqcascata, Dhsolicit, Codususolicit, Codusulib, Evento, Vlratual,
           Vlrlimite, Obslib, Observacao, Obscompl)
        Values
          ('AD_JURITE', tmp.Nupasta, Tmp.Seq, tmp.Seqcascata, Sysdate, p_Codusu, Par.Codusulib,
           par.NUEVENTOLIBREEMB, v_Valor, v_Valor, 'Ref. Reembolso do processo ' || Jur.Numprocesso,
           'Ref. Reembolso do processo ' || Jur.Numprocesso, v_Obscompl);
      
        -- popula a aba "libera��es" da tela de desp. juridicas
        Insert Into Ad_Jurlib
          (Nupasta, Seq, Numlinha, Dhsolicit, Vlrsolicit, Codususolicit, Nuevento, Status, Dhlib, Vlrliberado,
           Codusulib, Obslib, Obscompl, Seqcascata)
        Values
          (tmp.Nupasta, Tmp.Seq, i, Sysdate, v_Valor, p_Codusu, par.NUEVENTOLIBREEMB, 'P', Null, 0,
           Par.Codusulib, Null, 'Ref. Reembolso do processo ' || Jur.Numprocesso || Chr(13) || v_Obscompl,
           tmp.Seqcascata);
      
      Exception
        When Others Then
          Rollback;
          p_Mensagem := Ad_Fnc_Formataerro('Erro ao inserir a solicita��o de libera��o! Erro:' || Sqlerrm);
          Raise jur_exception;
      End;
    
      --grava os dados temporarios para execu��o autom�tica da procedure ap�s a libera��o
      Begin
        Insert Into Ad_Jurtmp
          (Nupasta, Seq, Seqcascata, Favorecido, Conta, Ctadeb, Valor, Parcial, Parcelafinal, Vlrdesp,
           Vlrjuros, Vlrdespjur, Codnat, Codusuinc, Dhinc)
        Values
          (tmp.Nupasta, Tmp.Seq, tmp.Seqcascata, tmp.Favorecido, tmp.Conta, tmp.Ctadeb, tmp.Valor,
           tmp.Parcial, tmp.Parcelafinal, tmp.Vlrdesp, tmp.Vlrjuros, tmp.vlrdespjur, tmp.Codnat, p_Codusu,
           Sysdate);
      
      Exception
        When Others Then
          Rollback;
          p_Mensagem := Ad_Fnc_Formataerro('Erro ao gravar os dados para salvar os dados para automatizar' ||
                                           ' a execu��o ap�s libera��o! Erro:' || Sqlerrm);
          Raise jur_exception;
      End;
    
      -- atualiza��o do status da despesa juridica
      Begin
        Update Ad_Jurite i
           Set i.Libreembolso = 'N', Situacao = 'J'
         Where Nupasta = tmp.Nupasta
           And i.Seq = Tmp.Seq;
      Exception
        When Others Then
          p_Mensagem := 'Erro ao atualizar o status do processo! <br>' || Dbms_Utility.Format_Error_Backtrace;
          Raise jur_exception;
        
      End;
    
    Else
      -- se processando o reembolso, libreembolso = N com lib pendente
      If Lower(p_idsessao) != 'debug' Then
        v_Confirmado := act_confirmar(p_titulo => 'Processamento de Reembolso',
                                      p_texto => 'J� existe uma solicita��o de libera��o para esse reembolso, confirma a sobreescri��o do mesmo?',
                                      p_chave => p_idsessao, p_sequencia => 2);
      Else
        v_confirmado := True;
      End If;
    
      If v_confirmado Then
        -- delete da lib
        Delete From tsilib
         Where tabela = 'AD_JURITE'
           And nuchave = tmp.Nupasta
           And sequencia = Tmp.Seq
           And dhlib Is Null
           And evento = par.NUEVENTOLIBREEMB
        Returning seqcascata Into tmp.seqcascata;
      
        ad_pkg_jur.exclui_reembolso_tmp(tmp.nupasta, tmp.seq, tmp.seqcascata);
      
        ad_pkg_jur.exclui_reembolso_lib(tmp.nupasta, tmp.seq, tmp.seqcascata);
      
        Goto inicio_liberacao;
      
      Else
        p_Mensagem := 'Aguardando libera��o do Reembolso!!!';
        Raise jur_exception;
      End If;
    
    End If;
  
  Else
    --p_mensagem := 'Reembolso j� processado anteriormente!';
    --Raise jur_exception;
  
    -- tratativas para reembolso j� realizado
    If ad_get.Temlib(tmp.Nupasta, 'AD_JURITE', Tmp.Seq, p.Nueventoreemb) > 0 Then
      --se pendente
    
      --exclui libera��es
      Begin
        Delete From tsilib
         Where nuchave = tmp.Nupasta
           And tabela = 'AD_JURITE'
           And sequencia = Tmp.Seq
           And evento = p.Nueventoreemb
        Returning seqcascata Into tmp.Seqcascata;
      Exception
        When Others Then
          p_mensagem := 'Erro ao excluir libera��es pendentes para reprocessamento do reembolso. ' || Sqlerrm;
          Raise jur_exception;
      End;
    
      -- exclui os valores do reembolso
      ad_pkg_jur.exclui_reembolso_tmp(tmp.Nupasta, Tmp.Seq, tmp.Seqcascata);
    
      --exclui a libera��o do log
      ad_pkg_jur.exclui_reembolso_lib(tmp.Nupasta, Tmp.Seq, tmp.Seqcascata);
    
      --altera o libreembolso para 'N'
      Begin
        Update ad_jurite
           Set libreembolso = 'N'
         Where nupasta = tmp.Nupasta
           And seq = Tmp.Seq;
      Exception
        When Others Then
          p_mensagem := 'Erro ao disponibilizar o reembolso para nova libera��o. ' || Sqlerrm;
          Raise jur_exception;
      End;
    
      --volta pro in�cio do m�todo
      jur.libreembolso := 'N';
      Goto inicio_liberacao;
    
    Else
      --j� liberado
    
      Begin
        --percorre o log dos registros do reembolso
        For l In (Select *
                    From ad_jurlog Log
                   Where log.Nupasta = tmp.Nupasta
                     And log.Seq = Tmp.Seq
                     And log.Tipo != 'A'
                   Order By nubco Desc)
        Loop
          --verifica se possui nufin baixado e pergunta se desfaz ou n�o
          If l.nufin Is Not Null Then
            Select Count(*)
              Into i
              From tgffin
             Where nufin = l.nufin
               And dhbaixa Is Not Null;
          
            If Lower(p_idsessao) != 'debug' Then
              v_confirmado := act_confirmar('Encontrado lan�amento baixado',
                                            'O lan�amento referente ' ||
                                             ad_get.Opcoescampo(l.tipo, 'TIPO', 'AD_JURLOG') || ' no valor de ' ||
                                             ad_get.Formatanumero(l.vlrdesdob) ||
                                             ', j� se encontra baixado, confirma o estorno e exclus�o do mesmo?',
                                            p_Idsessao, 3);
            Else
              v_confirmado := True;
            End If;
          
            If v_Confirmado Then
              --se sim, estorna e exclui da fin
              Begin
                ad_set.estorna_financeiro(l.nufin);
                Delete From tgffin Where nufin = l.nufin;
              Exception
                When Others Then
                  p_Mensagem := 'Erro ao realizar o estorno do lan�amento nro �nico ' || l.nufin || '. ' ||
                                Sqlerrm;
                  Raise jur_exception;
              End;
            
            Else
              --se n�o confirmou, sai do procedimento
              p_Mensagem := 'Procedimento abortado.';
              Raise jur_exception;
            End If;
          
          Else
            -- se nufin is null
            --desfaz as transfer�ncias
            Declare
              p_atualizou Varchar2(1);
              p_referencia Date;
              mbc tgfmbc%Rowtype;
            Begin
              Select * Into mbc From tgfmbc Where nubco = l.nubco;
            
              stp_atualiza_tgfsbc_dlt(mbc.recdesp, mbc.vlrlanc, mbc.conciliado, mbc.dtlanc, mbc.dhconciliacao,
                                      mbc.codctabcoint, p_atualizou);
            
              If p_atualizou = 'N' Then
              
                p_referencia := Last_Day(mbc.dtlanc) + 1;
              
                Merge Into TGFSBC SBC
                Using (Select * From tgfmbc Where nubco = l.nubco) m
                On (sbc.codctabcoint = m.codctabcoint And sbc.referencia = p_referencia)
                When Matched Then
                  Update
                     Set SALDOREAL =
                         (SALDOREAL - m.vlrlanc)
                When Not Matched Then
                  Insert
                    (codctabcoint, referencia, saldoreal, saldobco)
                  Values
                    (m.codctabcoint, p_referencia, fc_saldo_conta(m.codctabcoint, p_referencia, 'R'),
                     fc_saldo_conta(m.codctabcoint, p_referencia, 'B'));
              
              End If;
            
              Delete From tgfmbc Where nubco = l.nubco;
            
            Exception
              When Others Then
                Raise;
            End;
          
          End If;
        End Loop;
      
        --ao sair do la�o, exclui os lan�amentos do log
        Begin
          Delete From ad_jurlog Log
           Where log.Nupasta = tmp.Nupasta
             And log.Seq = Tmp.Seq
             And log.Tipo != 'A';
        Exception
          When Others Then
            p_mensagem := 'Erro ao excluir os lan�amentos da aba "Lan�amentos". ' || Sqlerrm;
            Raise jur_exception;
        End;
      
        --exclui da lib
        Begin
          Delete From tsilib
           Where nuchave = tmp.Nupasta
             And tabela = 'AD_JURITE'
             And sequencia = Tmp.Seq
             And evento = p.Nueventoreemb
          Returning seqcascata Into tmp.Seqcascata;
        Exception
          When Others Then
            p_mensagem := 'Erro ao excluir libera��es pendentes para reprocessamento do reembolso. ' ||
                          Sqlerrm;
            Raise jur_exception;
        End;
      
        -- exclui os valores do reembolso
        ad_pkg_jur.exclui_reembolso_tmp(tmp.Nupasta, Tmp.Seq, tmp.Seqcascata);
      
        --exclui a libera��o do log
        ad_pkg_jur.exclui_reembolso_lib(tmp.Nupasta, Tmp.Seq, tmp.Seqcascata);
      
        --voltar pro inicio do m�todo
        jur.libreembolso := 'N';
        Goto inicio_liberacao;
      
      End;
    
    End If;
  
    Null;
  End If;
  /* fim libera��es*/

  p_Mensagem := 'Opera��o realizada com sucesso!!!<br>Verifique os lan�amentos associados ao processo para confer�ncia';

Exception
  When jur_exception Then
    Rollback To inicio_transacao;
End;
/
