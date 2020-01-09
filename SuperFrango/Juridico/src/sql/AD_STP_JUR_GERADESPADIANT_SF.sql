Create Or Replace Procedure Ad_Stp_Jur_Geradespadiant_Sf(p_Codusu    Number,
                                                         p_Idsessao  Varchar2,
                                                         p_Qtdlinhas Number,
                                                         p_Mensagem  Out Varchar2) As
    p_Conta Varchar2(4000);
    Jur     Ad_Jurite%Rowtype;
    Fin     Tgffin%Rowtype;
    p       Ad_Pkg_Jur.Type_Rec_Desp_Jur;
    i       Int := 0;
    Msg     Varchar2(4000);
    Error Exception;
Begin

    -- %autor  M. Rangel
    /* * Processo: Despesas Jurídicas
    --%usage Essa procedure serÁ responsÁvel pela geração das liberações quando o processo
                 Ã© do tipo adiantamento ou despesa. Deverão ser geradas 2 liberações, para o financeiro
                 e para o jurídico, usando os valores da tela de parÃ¢metros.
                 SerÁ inserida uma linha na movimentação financeira com o recdesp de acordo com o tipo
                 (boleto = -1 e adiantamento = 0).
     */

    /********** VALIDAÃ‡Ã•ES ***********/
    If p_Qtdlinhas > 1 Then
        p_Mensagem := 'Selecione apenas um registro de cada vez';
        Return;
    End If;

    Jur.Nupasta := Act_Int_Field(p_Idsessao, 1, 'NUPASTA');
    Jur.Seq     := Act_Int_Field(p_Idsessao, 1, 'SEQ');
    p_Conta     := Act_Txt_Param(p_Idsessao, 'CONTA');

    Begin
        Select *
          Into Jur
          From Ad_Jurite j
         Where j.Nupasta = Jur.Nupasta
           And j.Seq = Jur.Seq;
    Exception
        When Others Then
            p_Mensagem := 'Não foi possível buscar os dados do lançamento selecionado';
            Return;
    End;

    -- valida se despesa/adiantamento não foi gerado
    If Nvl(Jur.Adto, 'N') = 'N' And Jur.Nufin Is Not Null Then
    
        Msg := 'Despesa para esse lançamento já gerada.' || '<br>Nro Único Financeiro: <a href="' ||
               Ad_Fnc_Urlskw('TGFFIN', Jur.Nufin) || '" target="_parent" title="Clique para visualizar">' ||
               Jur.Nufin || '</a>' || '<br> Consulte a aba ligações para verificar o lançamento.';
    
        -- questiona usuário se deseja continuar
        If Act_Escolher_Simnao(p_Titulo    => 'Gerar novo lançamento financeiro',
                               p_Texto     => Msg || '<br><br><h3>Deseja gerar nova despesa?</h3>',
                               p_Chave     => p_Idsessao,
                               p_Sequencia => 1) = 'N' Then
        
            Return;
        End If;
    
    End If;

    If Nvl(Jur.Adto, 'N') = 'S' And p_Conta Is Null Then
        p_Mensagem := 'Necessário informar o código da conta destino para adiantamentos';
        Return;
    End If;

    -- popula paramentros
    Ad_Pkg_Jur.Get_Param_Jur(Jur.Nupasta,
                             Jur.Seq,
                             p.Codtopdesp,
                             p.Codtoprec,
                             p.Codtopbxrec,
                             p.Codtopbxdesp,
                             p.Codtoptransf,
                             p.Codtiptit,
                             p.Nueventojur,
                             p.Nueventofin,
                             p.Nueventoreemb,
                             p.Usulibjur,
                             p.Usulibfin,
                             p.Codnatdesp,
                             p.Codnatrec);

    /*Gera o financeiro*/
    Begin
    
        Stp_Keygen_Nufin(Fin.Nufin);
    
        Ad_Pkg_Jur.v_Reclamante := Ad_Pkg_Jur.Get_Nome_Reclamante(Jur.Nupasta);
    
        If Nvl(Jur.Numdoc, '0') = '0' Then
        
            Fin.Numnota := Ad_Pkg_Jur.Gera_Numdoc(Jur.Nupasta, Jur.Seq);
        
            Update Ad_Jurite i
               Set Numdoc = Fin.Numnota
             Where Nupasta = Jur.Nupasta
               And Seq = Jur.Seq;
        
        Else
        
            Fin.Numnota := Jur.Numdoc;
        
        End If;
    
        Fin.Historico := Substr('Despesa no valor de ' || Ad_Get.Formatavalor(Jur.Valor) || ' do processo ' ||
                                Jur.Numprocesso || ' - ' || Ad_Pkg_Jur.v_Reclamante || ', Venc.: ' ||
                                To_Char(Jur.Dtvenc, 'dd/mm/yyyy'),
                                1,
                                255);
    
        If Nvl(Jur.Adto, 'N') = 'N' Then
            Fin.Recdesp  := -1;
            Fin.Provisao := 'N';
        Else
            Fin.Recdesp  := 0;
            Fin.Provisao := 'S';
        End If;
    
        -- insere lançamento no financeiro
        Insert Into Tgffin
            (Nufin, Codemp, Numnota, Dtneg, Desdobramento, Dhmov, Dtvencinic, Dtvenc, Codparc, Codtipoper,
             Dhtipoper, Codbco, Codnat, Codcencus, Codproj, Codvend, Codmoeda, Vlrdesdob, Recdesp, Provisao,
             Origem, Nunota, Rateado, Dtentsai, Dtalter, Codusu, Codtiptit, Codctabcoint, Sequencia, Historico)
        Values
            (Fin.Nufin, Jur.Codemp, Fin.Numnota, Trunc(Sysdate), 1, Sysdate, Jur.Dtvenc, Jur.Dtvenc,
             Jur.Codparc, p.Codtopdesp, Ad_Get.Maxdhtipoper(p.Codtopdesp), Nvl(Jur.Codbco, 0), Jur.Codnat,
             Jur.Codcencus, 0, 0, 0, Jur.Valor, Fin.Recdesp, Fin.Provisao, 'F', Null, 'N', Trunc(Sysdate),
             Sysdate, p_Codusu, p.Codtiptit, p_Conta, 1, Fin.Historico);
    
        Insert Into Ad_Tblcmf
            (Nometaborig, Nuchaveorig, Nometabdest, Nuchavedest)
        Values
            ('AD_JURITE', Jur.Nupasta || Jur.Seq, 'TGFFIN', Fin.Nufin);
    
    Exception
        When Others Then
            p_Mensagem := Fc_Formatahtml_Sf('Não foi possível gerar a despesa.',
                                            Sqlerrm,
                                            'Contate o suporte com essas informações');
            Return;
    End;
    /* Fim Gera o financeiro */

    /* Insere as liberações */
    Begin
    
        /* 
           Insert Into tsilib
          (nuchave, tabela, evento, codususolicit, dhsolicit, codusulib, vlrlimite, vlratual, sequencia,
           observacao)
        Values
          (Fin.nufin, 'TGFFIN', p.nueventofin, p_codusu, Sysdate, p.usulibfin, jur.valor, jur.valor,
           jur.Seq, Substr(Fin.historico, 1, 255));
           */
        Ad_Pkg_Var.Historico := Fin.Historico || ' - ' || Ad_Pkg_Jur.v_Reclamante;
    
        Select Nvl(Max(Seqcascata), 0) + 1
          Into i
          From Tsilib
         Where Tabela = 'AD_JURITE'
           And Nuchave = Jur.Nupasta
           And Sequencia = Jur.Seq;
    
        Insert Into Tsilib
            (Nuchave, Tabela, Evento, Codususolicit, Dhsolicit, Codusulib, Vlrlimite, Vlratual, Sequencia,
             Seqcascata, Observacao, Codparc, Codnat, Obscompl)
        Values
            (Jur.Nupasta, 'AD_JURITE', p.Nueventojur, p_Codusu, Sysdate, p.Usulibjur, Jur.Valor, Jur.Valor,
             Jur.Seq, i, Substr(Fin.Historico, 1, 255), Jur.Codparc, Jur.Codnat, Ad_Pkg_Var.Historico);
    
        Insert Into Ad_Jurlib
            (Nupasta, Seq, Numlinha, Dhsolicit, Vlrsolicit, Codususolicit, Nuevento, Status, Dhlib,
             Vlrliberado, Codusulib, Obslib, Obscompl, Seqcascata)
        Values
            (Jur.Nupasta, Jur.Seq, 1, Sysdate, Jur.Valor, p_Codusu, p.Nueventojur, 'P', Null, 0, p.Usulibjur,
             Null, Ad_Pkg_Var.Historico, i);
    
    Exception
        When Dup_Val_On_Index Then
            p_Mensagem := 'Já existe uma liberação para este processo';
            Return;
        When Others Then
            Rollback;
            p_Mensagem := Fc_Formatahtml_Sf('Não foi possível gerar as solicitações de liberação',
                                            Sqlerrm,
                                            'Procure o suporte');
            Return;
    End;

    /* Fim Insere as liberações */

    /* Atualiza dados na origem */
    Begin
        Update Ad_Jurite
           Set Situacao = 'J',
               -- aprovado pelo jurídico
               Status = 'A',
               -- Em andamento
               Codusudesp = p_Codusu,
               Dhdesp     = Sysdate,
               Codcta     = p_Conta,
               Codusujur  = p.Usulibjur,
               Codusufin  = p.Usulibfin,
               Nufin      = Fin.Nufin
         Where Nupasta = Jur.Nupasta
           And Seq = Jur.Seq;
    Exception
        When Others Then
            p_Mensagem := 'Não foi possível atualizar as informações no lançamento selecionado';
            Raise Error;
    End;
    /* fim atualização dados na origem */

    /* Atualiza as informações na aba lançamentos */
    Declare
        v_Nulog Int;
    Begin
    
        If Fin.Recdesp <> 0 Then
        
            v_Nulog := Ad_Pkg_Jur.Get_Nulog_Ultcod(Jur.Nupasta, Jur.Seq);
        
            Insert Into Ad_Jurlog
                (Nupasta, Seq, Nulog, Dhmov, Nufin, Nubco, Codctabcoint, Descroper, Recdesp, Vlrdesdob)
            Values
                (Jur.Nupasta, Jur.Seq, v_Nulog, Sysdate, Fin.Nufin, Fin.Nubco, p_Conta, 'Despesa Pagamento',
                 To_Char(Fin.Recdesp), Jur.Valor);
        
        End If;
    
    Exception
        When Others Then
            p_Mensagem := 'Erro ao atualizar o rastreio de lançamento para o registro selecionado. ' ||
                          Sqlerrm;
            Return;
    End;
    /* Fim atualizações lançamento*/

    p_Mensagem := 'Despesa no valor de ' || Ad_Get.Formatavalor(Jur.Valor) || ' e nro Único ' || Fin.Nufin ||
                  ' gerada com Sucesso.<br>A mesma aguarda liberação da Área.';

End;
/
