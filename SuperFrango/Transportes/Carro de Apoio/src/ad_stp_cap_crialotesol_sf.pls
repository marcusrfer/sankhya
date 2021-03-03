create or replace procedure ad_stp_cap_crialotesol_sf(p_codusu    number,
                                                      p_idsessao  varchar2,
                                                      p_qtdlinhas number,
                                                      p_mensagem  out varchar2) as
  p_qtdviagens     number;
  p_tipoviagem     number;
  p_dhpartida      date;
  p_dhretorno      date;
  p_codcidorig     varchar2(4000);
  p_codciddest     varchar2(4000);
  p_qtdpassageiros number;
  p_obs            varchar2(4000);
  p_endereco       varchar2(4000);

  r_sol   ad_tsfcapsol%rowtype;
  r_itn   ad_tsfcapitn%rowtype;
  v_volta boolean default false;

  type type_numsol is table of number;
  t_sol type_numsol := type_numsol();
  i_sol int := 0;

  v_session varchar2(4000);
begin
  /* 
  * Autor: M. Rangel
  * Processo: Carro de Apoio
  * Objetivo: Ação "Criar solicitações em Lotes" da tela de solicitações de carro de apoio.
  */

  if lower(p_idsessao) = 'debug' then
    p_qtdviagens     := 1;
    p_tipoviagem     := to_number('2');
    p_dhpartida      := to_date('30/07/2018 08:00:00', 'dd/mm/yyyy hh24:mi:ss');
    p_dhretorno      := to_date('30/07/2018 18:00:00', 'dd/mm/yyyy hh24:mi:ss');
    p_codcidorig     := 2;
    p_codciddest     := 3;
    p_qtdpassageiros := 4;
    p_endereco       := 'TESTE TESTE TESTE TESTE TESTE TESTE TESTE TESTE TESTE';
    p_obs            := 'TESTE TESTE TESTE TESTE TESTE TESTE TESTE TESTE TESTE';
  else
    p_qtdviagens     := act_int_param(p_idsessao, 'QTDVIAGENS');
    p_tipoviagem     := to_number(act_txt_param(p_idsessao, 'TIPOVIAGEM'));
    p_dhpartida      := act_dta_param(p_idsessao, 'DHPARTIDA');
    p_dhretorno      := act_dta_param(p_idsessao, 'DHRETORNO');
    p_codcidorig     := act_txt_param(p_idsessao, 'CODCIDORIG');
    p_codciddest     := act_txt_param(p_idsessao, 'CODCIDDEST');
    p_qtdpassageiros := act_int_param(p_idsessao, 'QTDPASSAGEIROS');
    p_obs            := act_txt_param(p_idsessao, 'OBS');
    p_endereco       := act_txt_param(p_idsessao, 'ENDERECO');
  end if;

  if p_tipoviagem = 2 and p_dhretorno is null then
    p_mensagem := 'Para viagens Ida e Volta é necessário informar a data de retornno.';
    return;
  end if;

  if p_dhretorno < p_dhpartida then
    p_mensagem := 'A data de retorno não pode ser inferior à data de partida';
    return;
  end if;

  <<inicio>>
  for v in 1 .. p_qtdviagens
  loop
    begin
      -- inicia o index da array
      i_sol := i_sol + 1;
    
      --busca o número da solicitação
      stp_keygen_tgfnum('AD_TSFCAPSOL', 1, 'AD_TSFCAPSOL', 'NUCAPSOL', 0, r_sol.nucapsol);
    
      -- preenche os demais campos da tabela
      r_sol.codusu := p_codusu;
    
      select u.codcencuspad into r_sol.codcencus from tsiusu u where codusu = p_codusu;
    
      r_sol.dhsolicit      := sysdate;
      r_sol.tiposol        := 'A';
      r_sol.status         := 'P';
      r_sol.dtagend := case
                         when v_volta then
                          p_dhretorno + v - 1
                         else
                          p_dhpartida + v - 1
                       end;
      r_sol.nuap           := null;
      r_sol.dhalter        := sysdate;
      r_sol.qtdpassageiros := p_qtdpassageiros;
      r_sol.dhenvio        := null;
      r_sol.motivo         := p_obs;
    
      -- insere a solicitação
      insert into ad_tsfcapsol values r_sol;
    
    exception
      when others then
        p_mensagem := 'Erro ao buscar os dados para a criação da solicitação. ' || sqlerrm;
        return;
    end;
  
    -- prepara para insert do itinerário
    begin
      for i in 1 .. 2
      loop
        r_itn.nuitn    := i;
        r_itn.nucapsol := r_sol.nucapsol;
        r_itn.tipotin := case
                           when i = 1 then
                            'O'
                           else
                            'D'
                         end;
      
        -- se for a volta
        if v_volta then
          r_itn.codcid := case
                            when i = 1 then
                             p_codciddest
                            else
                             p_codcidorig
                          end;
        else
          r_itn.codcid := case
                            when i = 1 then
                             p_codcidorig
                            else
                             p_codciddest
                          end;
        end if;
      
        r_itn.codend      := 0;
        r_itn.codbai      := 0;
        r_itn.complemento := p_endereco;
        r_itn.referencia  := null;
      
        -- insere o itinerário
        insert into ad_tsfcapitn values r_itn;
      
      end loop i;
    
    exception
      when others then
        p_mensagem := 'Erro ao preencher as informações do itinerário. ' || sqlerrm;
        return;
    end;
  
    -- insere o rateio
    begin
      insert into ad_tsfcaprat
        (nucapsol, nucaprat, codemp, codnat, codcencus, percentual, codproj)
      values
        (r_sol.nucapsol, 1, 1, 4051300, r_sol.codcencus, 100, 0);
    exception
      when others then
        p_mensagem := 'Erro ao preencher as informações sobre o rateio ' || sqlerrm;
        return;
    end;
  
    --iniciar e popula array
    t_sol.extend;
    t_sol(i_sol) := r_sol.nucapsol;
  
  end loop v;

  -- verifica se ida e volta se for, reinicia com os destinos trocados
  if p_tipoviagem = 2 and v_volta = false then
    v_volta := true;
    goto inicio;
  end if;

  begin
  
    if act_escolher_simnao(p_titulo => 'Envio para Agendamento',
                           p_texto => 'Deseja enviar diretamente as solicitações criadas ' ||
                                       'para o agendamento dos carros?', p_chave => p_idsessao,
                           p_sequencia => 1) = 'S' then
    
      v_session := dbms_random.string('A', 20);
    
      for a in t_sol.first .. t_sol.last
      loop
        ad_set.inseresessao('NUCAPSOL', a, 'I', t_sol(a), v_session);
      end loop;
    
      ad_stp_cap_enviaagend(p_codusu, v_session, t_sol.last, p_mensagem);
    
      ad_set.remove_sessao(v_session);
    
    else
      null;
    end if;
  
  end;

  p_mensagem := 'Solicitações criadas com sucesso!';

end;
/
