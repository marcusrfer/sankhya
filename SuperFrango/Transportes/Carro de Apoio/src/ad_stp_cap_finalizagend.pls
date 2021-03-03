create or replace procedure ad_stp_cap_finalizagend(p_codusu    number,
                                                    p_idsessao  varchar2,
                                                    p_qtdlinhas int,
                                                    p_mensagem  out varchar2) is
  cap         ad_tsfcap%rowtype;
  v_nuacerto  number;
  v_seqacerto int := 0;
  v_existe    int := 0;
begin
  /*
   * Autor: Marcus Rangel
   * Processo: Carro de Apoio
   * Objetivo: Concluir a corrida do carro de apoio e gerar a informação na rotina de 
               acerto de veículos de apoio
  */

  for i in 1 .. p_qtdlinhas
  loop
    cap.nuap := act_int_field(p_idsessao, i, 'NUAP');
  
    select * into cap from ad_tsfcap where nuap = cap.nuap;
  
    /* Se não gera acerto, vai para o fim da execução, atualiza status da solicitação e do agendamento e sai*/
    if nvl(cap.temacerto, 'N') = 'N' then
      goto fim_processo;
    end if;
  
    select count(*)
      into v_existe
      from ad_diaacertotransp d
      join ad_cabacertotransp t
        on d.nuacerto = t.nuacerto
     where t.codparc = cap.codparctransp
       and t.referencia = trunc(cap.dtagendfim, 'mm')
       and d.nuap = cap.nuap
       and exists (select 1
              from ad_ratacertotransp r
             where r.nuacerto = d.nuacerto
               and r.seqacertodia = d.seqacertodia);
  
    if cap.status = 'R' and v_existe > 0 then
      p_mensagem := 'Agendamento já Realizado.';
      return;
    elsif cap.status = 'P' then
      p_mensagem := 'Somenete agendamentos confirmados podem ser finalizados.';
      return;
    end if;
  
    if cap.kminicial = 0 or cap.kmfinal = 0 then
      p_mensagem := 'Para concluir o agendamento é necessário que a ' ||
                    'quilometragem inicial e final sejam informadas.';
      return;
    end if;
  
    if cap.taxi = 'S' and cap.vlrcorrida = 0 then
      p_mensagem := 'Por favor informe o valor da corrida de táxi.';
      return;
    end if;
  
    -- valida rateio
    begin
      for rat in (select * from ad_tsfcapfrt r where r.nuap = cap.nuap)
      loop
      
        ad_stp_valida_natcrproj_sf(rat.codemp, 0, rat.codnat, rat.codcencus, rat.codproj, 0,
                                   p_mensagem);
      
        if p_mensagem is not null then
          return;
        end if;
      
      end loop;
    end;
    -- fim valida rateio
  
    /* envia para a tela de acerto */
    begin
    
      v_nuacerto := ad_pkg_cap.get_nroacerto(cap.nuap);
    
      --se não existe, inserir o registro
      if nvl(v_nuacerto, 0) = 0 then
      
        --stp_obtemid('AD_CABACERTOTRANSP', v_nuAcerto);
        stp_keygen_tgfnum('AD_CABACERTOTRANSP', 1, 'AD_CABACERTOTRANSP', 'NUACERTO', 0, v_nuacerto);
      
        --- insere o cabeçalho
        begin
          --Execute Immediate 'ALTER TRIGGER TRG_INC_UPT_CABACERTOTRANSP_SF DISABLE';
        
          insert into ad_cabacertotransp c
            (nuacerto, codparc, referencia, ordemcarga, codveiculo, tipo, vlrcomb)
          values
            (v_nuacerto, cap.codparctransp, trunc(cap.dtagend, 'mm'), cap.ordemcarga,
             cap.codveiculo, (case when cap.taxi = 'S' then 'TAXI' else 'OUTROS' end),
             case when cap.codparctransp = 365883 then 0.001 else 0 end);
          -- verificar o conteúdo da trigger commentada acima, 
          -- verificar com Rodrigo sobre essa validação, se alí é o melhor lugar
          -- ao invés do momento de gerar o pedido
        
          --Execute Immediate 'ALTER TRIGGER TRG_INC_UPT_CABACERTOTRANSP_SF ENABLE';
        exception
          when others then
            rollback;
            p_mensagem := 'Erro ao inserir o cabeçalho do acerto. ' || sqlerrm;
            --Execute Immediate 'ALTER TRIGGER TRG_INC_UPT_CABACERTOTRANSP_SF ENABLE';
            return;
        end;
      
        -- insere a viagem
        begin
          v_seqacerto := v_seqacerto + 1;
        
          insert into ad_diaacertotransp
            (nuacerto, seqacertodia, dia, km, nuap)
          values
            (v_nuacerto, v_seqacerto, trunc(cap.dtagendfim), cap.totalkm, cap.nuap);
        exception
          when others then
            rollback;
            p_mensagem := 'Erro ao inserir a dia da viagem no acerto. ' || sqlerrm;
            return;
        end;
      
        /* RATEIO */
        begin
          ad_pkg_cap.insere_rateio_acerto(p_nroagend => cap.nuap, p_nroacerto => v_nuacerto,
                                          p_seqacerto => v_seqacerto, p_errmsg => p_mensagem);
          if p_mensagem is not null then
            return;
          end if;
        end;
      
        -- o cabeçalho do acerto já existe, inserir somente o data da viagem
      else
      
        declare
          v_acertofechado int := 0;
        begin
          select count(*)
            into v_acertofechado
            from ad_cabacertotransp t
           where t.codparc = cap.codparctransp
             and trunc(t.referencia, 'mm') = trunc(cap.dtagendfim, 'mm')
             and t.nunota is not null;
        
          if v_acertofechado > 0 then
            p_mensagem := 'O Acerto para este parceiro, referente este mês, já está encerrado,' ||
                          ' não sendo possível incluir esse lançamento ao mesmo. <br>' ||
                          'Favor entrar em contato com a área de transportes para a ' ||
                          'reabertura do acerto para que essa corrida possa ser incluída.';
            return;
          end if;
        end;
      
        select count(*)
          into v_existe
          from ad_diaacertotransp dat
         where dat.dia = trunc(cap.dtagendfim)
           and dat.km = cap.totalkm
           and dat.nuap = cap.nuap;
      
        if v_existe > 0 then
          /* p_mensagem := 'Agendamento já consta no acerto ' || v_nuAcerto;
          return;*/
          begin
            delete from ad_diaacertotransp dat
             where dat.dia = trunc(cap.dtagendfim)
               and dat.km = cap.totalkm
               and dat.nuap = cap.nuap;
          exception
            when others then
              p_mensagem := 'Não foi possível remover o lançamento no acerto do veículo, ' ||
                            'devido o seguinte erro: ' || sqlerrm;
              return;
          end;
        end if;
      
        select nvl(max(seqacertodia), 0) + 1
          into v_seqacerto
          from ad_diaacertotransp
         where nuacerto = v_nuacerto;
      
        begin
          insert into ad_diaacertotransp
            (nuacerto, seqacertodia, dia, km, nuap)
          values
            (v_nuacerto, v_seqacerto, trunc(cap.dtagendfim), cap.totalkm, cap.nuap);
        exception
          when others then
            p_mensagem := 'Erro ao inserir o dia da viagem. ' || chr(13) || sqlerrm;
        end;
      
        /* INSERE O RATEIO */
        begin
        
          ad_pkg_cap.insere_rateio_acerto(p_nroagend => cap.nuap, p_nroacerto => v_nuacerto,
                                          p_seqacerto => v_seqacerto, p_errmsg => p_mensagem);
          if p_mensagem is not null then
            return;
          end if;
        end;
      
      end if;
    
    end;
    <<fim_processo>>
  
    if cap.tipo = 'LOC' then
    
      if cap.numloc is null then
        p_mensagem := 'Número do localizador não informado!';
        return;
      end if;
    
    end if;
  
    /*Atualiza o status das solicitações de origem, envia e-mail para os solicitantes e aviso via sistema*/
    begin
      ad_pkg_cap.atualiza_statussol(p_nroagendamento => cap.nuap, p_statussolicit => 'R',
                                    p_enviaemail => 'S', p_enviaaviso => 'S', p_errmsg => p_mensagem);
    
      if p_mensagem is not null then
        return;
      end if;
    
    end;
  
    begin
      update ad_tsfcap c set c.status = 'R' where nuap = cap.nuap;
    end;
  
    p_mensagem := 'Realização da corrida registrada com sucesso!!!';
  
  end loop;

end;
/
