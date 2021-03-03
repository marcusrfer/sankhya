create or replace procedure ad_stp_cap_cancagend(p_codusu    number,
                                                 p_idsessao  varchar2,
                                                 p_qtdlinhas int,
                                                 p_mensagem  out varchar2) is
  v_nrounico number;
  v_motivo   varchar2(400);
  r_sol      ad_tsfcapsol%rowtype;
  r_cap      ad_tsfcap%rowtype;
  v_msg      varchar2(4000);

begin
  /*
   Autor: Marcus Rangel
   Processo: Carro de Apoio
   Objetivo: Realizar o processo de solicitação e cancelamento tanto da solicitação 
   quanto do agendamento, verificando se existe fechamento e tratando o mesmo.
  */

  stp_set_atualizando('S');

  for i in 1 .. p_qtdlinhas
  loop
    v_nrounico := act_int_field(p_idsessao, i, 'NUCAPSOL');
    v_motivo   := act_txt_param(p_idsessao, 'MOTIVO');
  
    if v_nrounico is not null then
    
      select * into r_sol from ad_tsfcapsol where nucapsol = v_nrounico;
    
      /*If r_sol.status Not In ('E', 'A') Then
        p_Mensagem := 'Somente solicitações com status "<font color="#FF0000">Enviada</font>"' ||
                      'ou "<font color="#FF0000">Agendada</font>" podem ser canceladas.<br><br>' ||
                      'Procure o responsável pelo agendamento para corrgir essa situação.';
        Return;
      End If;*/
    
      begin
        select * into r_cap from ad_tsfcap where nuap = r_sol.nuap;
      exception
        when no_data_found then
          -- se não tem agendamento, só cancela
          update ad_tsfcapsol set status = 'C' where nucapsol = r_sol.nucapsol;
        
          p_mensagem := 'Cancelamento efetuado com sucesso!';
          return;
      end;
    
      ad_set.ins_avisosistema(p_titulo => 'Solicitação de Cancelamento.',
                              p_descricao => 'O usuário ' ||
                                              ad_get.nomeusu(r_sol.codusu, 'resumido') ||
                                              ' solicitou o cancelamento do agendamento ' ||
                                              r_sol.nuap || ', resultante da solicitação ' ||
                                              v_nrounico || ', alegando o seguinte motivo: <b> ' ||
                                              v_motivo || '</b>',
                              p_solucao => 'Para maiores detalhes, acesse o registro ',
                              p_usurem => r_sol.codusu, p_usudest => r_cap.codusuexc,
                              p_prioridade => 1, p_tabela => 'AD_TSFCAP', p_nrounico => r_sol.nuap,
                              p_erro => p_mensagem);
    
      if p_mensagem is not null then
        return;
      end if;
    
      v_msg := 'Solicitação de Cancelamento enviada com Sucesso!!!';
    
    else
      --entra no cancelamento real
    
      v_nrounico := act_int_field(p_idsessao, i, 'NUAP');
    
      for r_cap in (select * from ad_tsfcap where nuap = v_nrounico)
      loop
      
        if r_cap.status not in ('P', 'A') then
          p_mensagem := 'Somente agendamentos com status "<font color="#FF0000">Pendente</font>"' ||
                        'ou "<font color="#FF0000">Agendado</font>" podem ser cancelados.<br><br>';
          return;
        end if;
      
        /*Verifica se existe acerto*/
        -- encontra o acerto do agendamento em questão, verifica se o acerto ainda está pendente    
        ad_pkg_cap.exclui_acerto(r_cap.nuap, p_mensagem);
        if p_mensagem is not null then
          return;
        end if;
      
        /*Atualiza o status das solicitações de origem, envia e-mail para os solicitantes e aviso via sistema*/
        begin
          ad_pkg_cap.atualiza_statussol(r_cap.nuap, 'C', 'S', 'S', p_mensagem);
        
          if p_mensagem is not null then
            return;
          end if;
        
        end;
      
        begin
          update ad_tsfcap c
             set c.status       = 'C',
                 c.dtreabre     = sysdate,
                 c.motivoreabre = v_motivo,
                 c.codusureabre = stp_get_codusulogado
           where c.nuap = r_cap.nuap;
        exception
          when others then
            p_mensagem := 'Erro ao atulizar o status do agendamento. ' || sqlerrm;
            return;
        end;
      
      end loop r_cap;
    
      p_mensagem := 'Cancelamento realizado com sucesso!!!';
    
    end if;
  
  end loop;

  stp_set_atualizando('N');

end;
/
