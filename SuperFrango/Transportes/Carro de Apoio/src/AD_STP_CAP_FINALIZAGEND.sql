Create Or Replace Procedure "AD_STP_CAP_FINALIZAGEND"(p_codusu    Number,
                                                      p_idsessao  Varchar2,
                                                      p_qtdlinhas Int,
                                                      p_mensagem  Out Varchar2) Is
  v_nuAp      Number;
  r_cap       ad_tsfcap%Rowtype;
  v_nuAcerto  Number;
  v_seqAcerto Int := 0;
  v_Existe    Int := 0;
  errmsg      Varchar2(4000);
  error Exception;
Begin
  /*
   * Autor: Marcus Rangel
   * Processo: Carro de Apoio
   * Objetivo: Concluir a corrida do carro de apoio e gerar a informação na rotina de acerto de veículos de apoio
  */

  For I In 1 .. p_qtdlinhas
  Loop
    v_nuAp := act_int_field(p_idsessao, I, 'NUAP');
  
    Select *
      Into r_cap
      From ad_tsfcap
     Where nuap = v_nuap;
  
    /* Se não gera acerto, vai para o fim da execução, atualiza status da solicitação e do agendamento e sai*/
    If Nvl(r_cap.temacerto, 'N') = 'N' Then
      Goto fim_processo;
    End If;
  
    Select Count(*)
      Into v_Existe
      From ad_diaacertotransp d
      Join ad_cabacertotransp t
        On d.nuacerto = t.nuacerto
     Where t.codparc = r_cap.codparctransp
       And t.referencia = Trunc(r_cap.dtagendfim, 'mm')
       And d.nuap = r_cap.nuap
       And Exists (Select 1
              From ad_ratacertotransp r
             Where r.nuacerto = d.nuacerto
               And r.seqacertodia = d.seqacertodia);
  
    If r_cap.status = 'R' And v_existe > 0 Then
      errmsg := 'Agendamento já Realizado.';
      Raise error;
    Elsif r_cap.status = 'P' Then
      errmsg := 'Somenete agendamentos confirmados podem ser finalizados.';
      Raise error;
    End If;
  
    If r_cap.kminicial = 0 Or r_cap.kmfinal = 0 Then
      errmsg := 'Para concluir o agendamento é necessário que a quilometragem inicial e final sejam informadas.';
      Raise error;
    End If;
  
    If r_cap.taxi = 'S' And r_cap.vlrcorrida = 0 Then
      errmsg := 'Por favor informe o valor da corrida de táxi.';
      Raise error;
    End If;
  
    -- valida rateio
    Begin
      For rat In (Select *
                    From ad_tsfcapfrt r
                   Where r.nuap = r_cap.nuap)
      Loop
      
        ad_stp_valida_natcrproj_sf(rat.codemp, 0, rat.codnat, rat.codcencus, rat.codproj, 0,
                                   p_Mensagem);
      
        If p_mensagem Is Not Null Then
          Return;
        End If;
      
      End Loop;
    End;
    -- fim valida rateio
  
    /* envia para a tela de acerto */
    Begin
    
      v_nuAcerto := ad_pkg_cap.get_nroacerto(v_nuAp);
    
      --se não existe, inserir o registro
      If Nvl(v_nuAcerto, 0) = 0 Then
      
        --stp_obtemid('AD_CABACERTOTRANSP', v_nuAcerto);
        stp_keygen_tgfnum('AD_CABACERTOTRANSP', 1, 'AD_CABACERTOTRANSP', 'NUACERTO', 0, v_nuAcerto);
      
        --- insere o cabeçalho
        Begin
          --Execute Immediate 'ALTER TRIGGER TRG_INC_UPT_CABACERTOTRANSP_SF DISABLE';
        
          Insert Into ad_cabacertotransp c
            (nuacerto, codparc, referencia, ordemcarga, codveiculo, tipo, vlrcomb)
          Values
            (v_nuAcerto, r_cap.codparctransp, Trunc(r_cap.dtagend, 'mm'), r_cap.ordemcarga,
             r_cap.codveiculo, (Case When r_cap.taxi = 'S' Then 'TAXI' Else 'OUTROS' End),
             Case When r_cap.codparctransp = 365883 Then 0.001 Else 0 End);
          -- verificar o conteúdo da trigger commentada acima, 
          -- verificar com Rodrigo sobre essa validação, se alí é o melhor lugar
          -- ao invés do momento de gerar o pedido
        
          --Execute Immediate 'ALTER TRIGGER TRG_INC_UPT_CABACERTOTRANSP_SF ENABLE';
        Exception
          When Others Then
            Rollback;
            errmsg := 'Erro ao inserir o cabeçalho do acerto. ' || Sqlerrm;
            --Execute Immediate 'ALTER TRIGGER TRG_INC_UPT_CABACERTOTRANSP_SF ENABLE';
            Raise error;
        End;
      
        -- insere a viagem
        Begin
          v_seqAcerto := v_seqAcerto + 1;
        
          Insert Into AD_DIAACERTOTRANSP
            (NUACERTO, SEQACERTODIA, DIA, KM, NUAP)
          Values
            (v_nuAcerto, v_seqAcerto, Trunc(r_cap.dtagendfim), r_cap.totalkm, r_cap.nuap);
        Exception
          When Others Then
            Rollback;
            errmsg := 'Erro ao inserir a dia da viagem no acerto. ' || Sqlerrm;
            Raise error;
        End;
      
        /* RATEIO */
        Begin
          ad_pkg_cap.insere_rateio_acerto(p_nroagend => v_nuap, p_nroacerto => v_nuAcerto,
                                          p_seqacerto => v_seqAcerto, p_errmsg => errmsg);
          If errmsg Is Not Null Then
            Raise error;
          End If;
        End;
      
        -- o cabeçalho do acerto já existe, inserir somente o data da viagem
      Else
      
        Declare
          v_AcertoFechado Int := 0;
        Begin
          Select Count(*)
            Into v_AcertoFechado
            From ad_cabacertotransp t
           Where t.codparc = r_cap.codparctransp
             And Trunc(t.referencia, 'mm') = Trunc(r_cap.dtagendfim, 'mm')
             And t.nunota Is Not Null;
        
          If v_AcertoFechado > 0 Then
            errmsg := 'O Acerto para este parceiro, referente este mês, já está encerrado,' ||
                      ' não sendo possível incluir esse lançamento ao mesmo. <br>' ||
                      'Favor entrar em contato com a área de transportes para a reabertura do acerto para que essa corrida possa ser incluída.';
            Raise error;
          End If;
        End;
      
        Select Count(*)
          Into v_Existe
          From ad_diaacertotransp dat
         Where dat.dia = Trunc(r_cap.dtagendfim)
           And dat.km = r_cap.totalkm
           And dat.nuap = r_cap.nuap;
      
        If v_existe > 0 Then
          /* errmsg := 'Agendamento já consta no acerto ' || v_nuAcerto;
          Raise error;*/
          Begin
            Delete From ad_diaacertotransp dat
             Where dat.dia = Trunc(r_cap.dtagendfim)
               And dat.km = r_cap.totalkm
               And dat.nuap = r_cap.nuap;
          Exception
            When Others Then
              p_mensagem := 'Não foi possível remover o lançamento no acerto do veículo, devido o seguinte erro: ' ||
                            Sqlerrm;
              Raise error;
          End;
        End If;
      
        Select Nvl(Max(seqacertodia), 0) + 1
          Into v_seqAcerto
          From ad_diaacertotransp
         Where nuacerto = v_nuAcerto;
      
        Begin
          Insert Into AD_DIAACERTOTRANSP
            (NUACERTO, SEQACERTODIA, DIA, KM, NUAP)
          Values
            (v_nuAcerto, v_seqAcerto, Trunc(r_cap.dtagendfim), r_cap.totalkm, r_cap.nuap);
        Exception
          When Others Then
            errmsg := 'Erro ao inserir o dia da viagem. ' || Chr(13) || Sqlerrm;
        End;
      
        /* INSERE O RATEIO */
        Begin
        
          ad_pkg_cap.insere_rateio_acerto(p_nroagend => v_nuap, p_nroacerto => v_nuAcerto,
                                          p_seqacerto => v_seqAcerto, p_errmsg => errmsg);
          If errmsg Is Not Null Then
            Raise error;
          End If;
        End;
      
      End If;
    
    End;
    <<fim_processo>>
  /*Atualiza o status das solicitações de origem, envia e-mail para os solicitantes e aviso via sistema*/
    Begin
      ad_pkg_cap.atualiza_statussol(p_nroagendamento => r_cap.nuap, p_statussolicit => 'R',
                                    p_enviaemail => 'S', p_enviaaviso => 'S', p_errmsg => Errmsg);
    
      If errmsg Is Not Null Then
        Raise error;
      End If;
    
    End;
  
    Begin
      Update ad_tsfcap c
         Set c.status = 'R'
       Where nuap = r_cap.nuap;
    End;
  
  End Loop;

  p_mensagem := 'Realização da corrida registrada com sucesso!!!';

Exception
  When error Then
    p_mensagem := errmsg;
  When Others Then
    P_mensagem := Sqlerrm();
End;
/
