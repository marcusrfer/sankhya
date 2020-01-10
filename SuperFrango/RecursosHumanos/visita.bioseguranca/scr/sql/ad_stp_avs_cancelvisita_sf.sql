create or replace procedure ad_stp_avs_cancelvisita_sf(p_codusu    number,
                                                       p_idsessao  varchar2,
                                                       p_qtdlinhas number,
                                                       p_mensagem  out varchar2) as
  p_motivocancel varchar2(4000);
  vis            ad_tsfavs %rowtype;
  v_idsessao     varchar2(200);
  v_count        int;
  v_qtdcancel    int;
  v_nuap         number;
begin

  p_motivocancel := act_txt_param(p_idsessao, 'MOTIVOCANCEL');

  for i in 1 .. p_qtdlinhas
  loop
    --vis.nuvisita := act_int_field(p_idsessao, i, 'NUVISITA');
    --return;
    vis := ad_pkg_avs.get_dados_visita(act_int_field(p_idsessao, i, 'NUVISITA'));
  
    if vis.status = 'conc' then
      p_mensagem := 'Visitas concluídas não podem ser canceladas!';
      return;
    elsif vis.status = 'canc' then
      p_mensagem := 'Visita já cancelada!';
      return;
    end if;
  
    -- verifica visitas por solicitações de carros de apoio 
    select count(*) into v_count from ad_tsfavs where nucapsol = vis.nucapsol;
  
    <<start_cancel>>
  
    if v_count = 0 then
      -- quando não possui carro de apoio
      --update ad_tsfavs a set a.status = 'canc' where a.nuvisita = vis.nuvisita;
      null;
    
    elsif v_count = 1 then
    
      -- cancela solicitação
      begin
      
        for cap in (select s.nuap, s.nucapsol
                      from ad_tsfcapsol s
                     where s.nucapsol = vis.nucapsol
                       and s.status != 'C')
        loop
          v_idsessao := p_idsessao;
        
          if cap.nuap is null then
            ad_set.inseresessao('NUCAPSOL', i, 'I', cap.nucapsol, v_idsessao);
          else
            ad_set.inseresessao('NUAP', i, 'I', cap.nuap, v_idsessao);
          end if;
        
          ad_set.inseresessao('MOTIVO', i, 'S', p_motivocancel, v_idsessao);
        
          ad_stp_cap_cancagend(p_codusu, p_idsessao, 1, ad_pkg_var.errmsg);
        
        end loop;
      
      end;
    
      -- cancela agendamento
    elsif v_count > 1 then
      -- verifica quantas solicitações válidas possuem
      select count(*) + 1
        into v_qtdcancel
        from ad_tsfavs a
       where a.nucapsol = vis.nucapsol
         and a.status = 'canc';
      -- se diferente do total cancela apenas a visita
    
      if v_qtdcancel = v_count then
        v_count := 1;
        goto start_cancel;
      end if;
    
      -- se, contando a atual, todas estão canceladas, cancela o carro de apoio
    end if;
  
    update ad_tsfavs a set a.status = 'canc' where a.nuvisita = vis.nuvisita;
  
    ad_pkg_avs.insere_historico(vis.nuvisita, 'Visita Cancelada, motivo: ' || p_motivocancel);
    
    /* Implementação da alteração do status da pesquisa - M. Rangel - 10/01/2020 */
    Begin
      if vis.codpesquisa Is Not Null then
         Update ad_tsfpes p
          Set p.status = 'C'
         Where p.codpesquisa = vis.codpesquisa;
      end if; 
      exception
    	  when others then
    		 p_mensagem := 'Erro ao atualizar o status da pesquisa! '||Sqlerrm;
       Return;
    end; 
  end loop;

  p_mensagem := 'Lançamento cancelado com sucesso!';

end;
/
