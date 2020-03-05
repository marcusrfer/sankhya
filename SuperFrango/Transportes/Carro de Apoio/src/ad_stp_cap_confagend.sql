create or replace procedure ad_stp_cap_confagend(p_codusu    number,
                                                 p_idsessao  varchar2,
                                                 p_qtdlinhas int,
                                                 p_mensagem  out varchar2) is
  v_nuap          number;
  r_cap           ad_tsfcap%rowtype;
  v_count         int := 0;
  v_valqtdpessoas boolean := false;
  v_valagenda     boolean := false;
  v_titulo        varchar2(200);
  v_mensagem      varchar2(2000);
  v_msgvalqtd     varchar2(200);
  v_msgvalagd     varchar2(200);
  v_incluir       boolean := false;
  v_lotacao       number := 0;
  errmsg          varchar2(4000);
  error exception;
begin
  /*
  autor: marcus rangel
  processo: carro de apoio
  objetivo: validar as informações do agendamento, retornar as informações para solicitaçao
  
  log de alterações:
  23/11/2016 - correção nro aviso linha 101
  28/11/2016 - inserida validação por passageiros
  
  */

  for i in 1 .. p_qtdlinhas
  loop
  
    v_nuap := act_int_field(p_idsessao, i, 'NUAP');
  
    select * into r_cap from ad_tsfcap where nuap = v_nuap;
  
    /* validações */
    begin
    
      /* valida status do agendamento */
      if r_cap.status = 'A' then
        errmsg := 'Agendamento já realizado';
        raise error;
      elsif r_cap.status = 'C' then
        errmsg := 'Agendamento cancelada!!!';
        raise error;
      elsif r_cap.status = 'R' then
        errmsg := 'Agendamento já realizado!!!';
        raise error;
      end if;
    
      /* valida o veículo do agendamento */
      if r_cap.codveiculo is null or r_cap.codveiculo = 0 and p_codusu != 0 then
        errmsg := 'Informe um veículo válido para realizar a confirmação.';
        raise error;
      end if;
    
      /* valida se as datas de agendamento estão preenchidas */
      if (r_cap.dtagend is null or r_cap.dtagendfim is null) then
        errmsg := 'Informe as datas de agendamento para realizar a confirmação.';
        raise error;
      end if;
    
      /*valida as datas de inicio e término, impedir que agende com data retroativa*/
      /*      
      if to_date(r_cap.dtagend, 'DD/MM/YYYY HH24:MI:SS') < to_date(sysdate, 'DD/MM/YYYY HH24:MI:SS') then
        errmsg := 'Não é permitido agendamento retroativo.';
        raise error;
      end if;
      */
    
      /* valida quantidade de passageiros */
    
      select nvl(v.maxlotacao, 0)
        into v_lotacao
        from tgfvei v
       where v.codveiculo = r_cap.codveiculo;
      if v_lotacao is null or v_lotacao = 0 then
        v_msgvalqtd     := 'Lotação não informada no cadasto do veículo!';
        v_valqtdpessoas := false;
      end if;
    
      if r_cap.qtdpassageiros <= v_lotacao then
        v_valqtdpessoas := true;
      else
        v_msgvalqtd     := 'Veículo com problemas de excesso de lotação (' || v_lotacao || '/' ||
                           r_cap.qtdpassageiros || '). <br>Deseja continuar?';
        v_valqtdpessoas := false;
      
      end if;
    
      /* valida o conflito de agendamento */
    
      for c_agend in (select *
                        from ad_tsfcap c
                       where c.status = 'A'
                         and c.codparctransp = r_cap.codparctransp
                         and c.codveiculo = r_cap.codveiculo
                       order by c.dtagend desc)
      loop
        if r_cap.dtagend between c_agend.dtagend and c_agend.dtagendfim then
          v_count     := 1;
          v_msgvalagd := 'Veículo com conflito de agenda nessa data/horário (' ||
                         to_char(r_cap.dtagend, 'dd/mm/yyyy') || ' das ' ||
                         to_char(r_cap.dtagend, 'HH24:mi') || ' às ' ||
                         to_char(r_cap.dtagendfim, 'HH24:mi') || ')';
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
      
        v_incluir := act_escolher_simnao(v_titulo, v_mensagem, p_idsessao, i) = 'S';
      
        if v_incluir then
          null;
        else
          return;
        end if;
      
      end if;
    
      -- valida se o motorista possui voucher pendentes de validação
      -- 'M' de motorista
      -- v de veículo
      --errmsg := ad_pkg_cap.voucher_pendentes(v_nuap, 'M');
      errmsg := ad_pkg_cap.voucher_pendentes(v_nuap, 'V');
    
      if errmsg is not null then
        raise error;
      end if;
    
    end; -- validaçao
  
    /* atualiza o status das solicitações */
    begin
    
      ad_pkg_cap.atualiza_statussol(p_nroagendamento => v_nuap,
                                    p_statussolicit  => 'A',
                                    p_enviaemail     => 'S',
                                    p_enviaaviso     => 'S',
                                    p_errmsg         => errmsg);
    
      if errmsg is not null then
        raise error;
      end if;
    
    end;
  
    /* atualiza numeração da pk da tabela */
  
    /* atualiza o status do agendamento */
    begin
      update ad_tsfcap c set c.status = 'A' where nuap = v_nuap;
    exception
      when others then
        errmsg := 'Erro ao atualizar o status do agendamento. ' || sqlerrm;
        raise error;
    end;
  
  end loop i;

  p_mensagem := 'Agendamento confirmado com suscesso!!!';

exception

  when error then
    rollback;
    p_mensagem := '<p><font color="#FF0000" size="14"><b>Atenção!!!</b></font></p>' ||
                  '<img src="http://www.freeiconspng.com/uploads/error-icon-21.png" height="42" width="42">' ||
                  errmsg || '</img>';
end;
/
