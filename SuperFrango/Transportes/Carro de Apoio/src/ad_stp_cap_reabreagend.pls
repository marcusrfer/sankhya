create or replace procedure ad_stp_cap_reabreagend(p_codusu    number,
                                                   p_idsessao  varchar2,
                                                   p_qtdlinhas number,
                                                   p_mensagem  out varchar2) as
  r_cap ad_tsfcap%rowtype;
begin
  /*
  * Autor: Marcus Rangel
  * Processo: Carro de Apoio
  * Objetivo: Reabrir o agendamento para correção, o procedimento defaz todas as ações 
              realizadas no fechamento do agendamento
  */

  -- Log de alterações
  -- m.rangel - 6/3/20 - adequação para locação de veículos

  for i in 1 .. p_qtdlinhas
  loop
    r_cap.nuap := act_int_field(p_idsessao, i, 'NUAP');
  
    select * into r_cap from ad_tsfcap where nuap = r_cap.nuap;
  
    r_cap.motivoreabre := act_txt_param(p_idsessao, 'MOTIVO');
  
    if r_cap.status not in ('R', 'C') then
      p_mensagem := 'Somente agendamentos finalizados/cancelados podem ser reabertos.';
      return;
    end if;
  
    if length(r_cap.motivoreabre) < 15 then
      p_mensagem := 'Motivo informado incompleto. Detalhe mais o motiva da reabertura.';
      return;
    end if;
  
    -- encontra o acerto do agendamento em questão, verifica se o acerto ainda está pendente
    if r_cap.status = 'R' and nvl(r_cap.temacerto, 'N') = 'S' and r_cap.tipo = 'CAP' then
      ad_pkg_cap.exclui_acerto(p_nroagend => r_cap.nuap, p_errmsg => p_mensagem);
      if p_mensagem is not null then
        return;
      end if;
    end if;
  
    -- atualiza o status do agendamento de origem
    begin
      update ad_tsfcap cap
         set cap.status = case
                            when r_cap.status = 'R' then
                             'A'
                            else
                             'P'
                          end,
             cap.dtreabre     = sysdate,
             cap.codusureabre = p_codusu,
             cap.motivoreabre = r_cap.motivoreabre
       where nuap = r_cap.nuap;
    
      ad_pkg_cap.atualiza_statussol(p_nroagendamento => r_cap.nuap,
                                    p_statussolicit => case
                                                          when r_cap.status = 'R' then
                                                           'A'
                                                          else
                                                           'E'
                                                        end, p_enviaemail => 'N', p_enviaaviso => 'N',
                                    p_errmsg => p_mensagem);
      if p_mensagem is not null then
        return;
      end if;
    exception
      when others then
        p_mensagem := 'Erro ao atualizar o status do agendamento ' || r_cap.nuap || '. - ' ||
                      sqlerrm;
        return;
    end;
  
  end loop i;

  p_mensagem := 'Agendamento reaberto com sucesso!';

end;
/
