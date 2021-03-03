create or replace procedure ad_stp_cap_confagend(p_codusu    number,
                                                 p_idsessao  varchar2,
                                                 p_qtdlinhas int,
                                                 p_mensagem  out varchar2) is

  cap             ad_tsfcap%rowtype;
  v_count         int := 0;
  v_valqtdpessoas boolean := false;
  v_valagenda     boolean := false;
  v_titulo        varchar2(200);
  v_mensagem      varchar2(2000);
  v_msgvalqtd     varchar2(200);
  v_msgvalagd     varchar2(200);
  v_incluir       boolean := false;
  v_lotacao       number := 0;

begin
  /*
  autor: marcus rangel
  processo: carro de apoio
  objetivo: validar as informações do agendamento, retornar as informações para solicitaçao
  */

  /*
  log de alterações:
  23/11/2016 - correção nro aviso linha 101
  28/11/2016 - inserida validação por passageiros
  04/03/2020 - m.rangel - adequação para atender as locações
  */

  if p_qtdlinhas > 1 then
    p_mensagem := 'Selecione apenas 1 registro.';
    return;
  end if;

  cap.nuap := act_int_field(p_idsessao, 1, 'NUAP');

  select * into cap from ad_tsfcap where nuap = cap.nuap;

  /* validações */
  begin
  
    /* valida status do agendamento */
    if cap.status = 'A' then
      p_mensagem := 'Agendamento já realizado';
      return;
    elsif cap.status = 'C' then
      p_mensagem := 'Agendamento cancelada!!!';
      return;
    elsif cap.status = 'R' then
      p_mensagem := 'Agendamento já realizado!!!';
      return;
    end if;
  
    /* validações específicas para o tipo do agendamento,  se carro de apoio ou locação de veiculos*/
    if cap.tipo = 'CAP' then
    
      /* valida o veículo do agendamento */
      if cap.codveiculo is null or cap.codveiculo = 0 and p_codusu != 0 then
        p_mensagem := 'Informe um veículo válido para realizar a confirmação.';
        return;
      end if;
    
      /* valida quantidade de passageiros */
      select nvl(v.maxlotacao, 0) into v_lotacao from tgfvei v where v.codveiculo = cap.codveiculo;
      if v_lotacao is null or v_lotacao = 0 then
        v_msgvalqtd     := 'Lotação não informada no cadasto do veículo!';
        v_valqtdpessoas := false;
      end if;
    
      if cap.qtdpassageiros <= v_lotacao then
        v_valqtdpessoas := true;
      else
        v_msgvalqtd     := 'Veículo com problemas de excesso de lotação (' || v_lotacao || '/' ||
                           cap.qtdpassageiros || '). <br>Deseja continuar?';
        v_valqtdpessoas := false;
      
      end if;
    
      begin
        /* valida o conflito de agendamento */
        for c_agend in (select *
                          from ad_tsfcap c
                         where c.status = 'A'
                           and c.codparctransp = cap.codparctransp
                           and c.codveiculo = cap.codveiculo
                         order by c.dtagend desc)
        loop
          if cap.dtagend between c_agend.dtagend and c_agend.dtagendfim then
            v_count     := 1;
            v_msgvalagd := 'Veículo com conflito de agenda nessa data/horário (' ||
                           to_char(cap.dtagend, 'dd/mm/yyyy') || ' das ' ||
                           to_char(cap.dtagend, 'HH24:mi') || ' às ' ||
                           to_char(cap.dtagendfim, 'HH24:mi') || ')';
          end if;
          exit when v_count = 1;
        end loop;
      
        if v_count = 0 then
          v_valagenda := true;
        else
          v_valagenda := false;
        end if;
      
        if v_valagenda = false and v_valqtdpessoas = false then
          v_mensagem := v_msgvalqtd || chr(13) || v_msgvalagd;
        elsif v_valagenda = true and v_valqtdpessoas = false then
          v_mensagem := v_msgvalqtd;
        elsif v_valagenda = false and v_valqtdpessoas = true then
          v_mensagem := v_msgvalagd;
        end if;
      
        if v_mensagem is not null then
          v_titulo := 'Problemas Encontrados';
        
          v_incluir := act_escolher_simnao(v_titulo, v_mensagem, p_idsessao, 1) = 'S';
        
          if v_incluir then
            null;
          else
            return;
          end if;
        
        end if;
      
      end;
    
      -- valida se o motorista possui voucher pendentes de validação
      -- 'M' de motorista, V de veículo
      --p_mensagem := ad_pkg_cap.voucher_pendentes(v_nuap, 'M');
      p_mensagem := ad_pkg_cap.voucher_pendentes(cap.nuap, 'V');
    
      if p_mensagem is not null then
        return;
      end if;
    
    else
      -- se LOCAÇÃO
      null;
    end if;
  
    /* valida se as datas de agendamento estão preenchidas */
    if (cap.dtagend is null or cap.dtagendfim is null) then
      p_mensagem := 'Informe as datas de agendamento para realizar a confirmação.';
      return;
    end if;
  
    /*valida as datas de inicio e término, impedir que agende com data retroativa*/
    /*      
    if to_date(cap.dtagend, 'DD/MM/YYYY HH24:MI:SS') < to_date(sysdate, 'DD/MM/YYYY HH24:MI:SS') then
      p_mensagem := 'Não é permitido agendamento retroativo.';
      return;
    end if;
    */
  
  end; -- validaçao

  /* atualiza o status das solicitações */
  begin
  
    ad_pkg_cap.atualiza_statussol(p_nroagendamento => cap.nuap, p_statussolicit => 'A',
                                  p_enviaemail => 'S', p_enviaaviso => 'S', p_errmsg => p_mensagem);
  
    if p_mensagem is not null then
      return;
    end if;
  
  end;

  /* atualiza o status do agendamento */
  begin
    update ad_tsfcap c set c.status = 'A' where nuap = cap.nuap;
  exception
    when others then
      p_mensagem := 'Erro ao atualizar o status do agendamento. ' || sqlerrm;
      return;
  end;

  p_mensagem := 'Agendamento confirmado com suscesso!!!';

end;
/
