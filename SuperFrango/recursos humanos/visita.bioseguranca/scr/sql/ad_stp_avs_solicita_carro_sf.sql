create or replace procedure ad_stp_avs_solicita_carro_sf(p_codusu    number,
                                                         p_idsessao  varchar2,
                                                         p_qtdlinhas number,
                                                         p_mensagem  out varchar2) as
  vis ad_tsfavs%rowtype;
  old ad_tsfavs%rowtype;
  sol ad_tsfcapsol%rowtype;
  itn ad_tsfcapitn%rowtype;
  rat ad_tsfcaprat%rowtype;

  p_horaini date;
  p_horafim date;
  v_horaini varchar2(10);
  v_horafim varchar2(10);

  t dbms_utility.number_array;

begin

  /*
  * Processo: Visita Sanitária/Biosegurança
  * Autor: M. Rangel
  * Objetivo: Ação "Solicitar Carro de Apoio"s
  */

  --processamento das datas do parametro
  begin
  
    p_horaini := act_dta_param(p_idsessao, 'HORAINI');
    p_horafim := act_dta_param(p_idsessao, 'HORAFIM');
  
    -- validação preenchimento dos parametros
    if p_qtdlinhas > 1 and (p_horaini is null or p_horafim is null) then
      p_mensagem := 'Por favor informe a data da solicitação do carro de apoio.';
      return;
    end if;
  
    -- tratativas do horário
    if p_horaini is not null and p_horafim is not null then
      v_horaini := to_char(p_horaini, 'hh24:mi:ss');
    
      if v_horaini = '00:00:00' or v_horaini is null then
        v_horaini := '08:00:00';
        p_horaini := to_date(to_char(p_horaini, 'dd/mm/yyyy') || ' ' || v_horaini,
                             'dd/mm/yyyy hh24:mi:ss');
      end if;
    
      v_horafim := to_char(p_horafim, 'hh24:mi:ss');
    
      if v_horafim = '00:00:00' then
        v_horafim := '18:00:00';
        p_horafim := to_date(to_char(p_horafim, 'dd/mm/yyyy') || ' ' || v_horafim,
                             'dd/mm/yyyy hh24:mi:ss');
      end if;
    end if;
  
  end;

  -- motivo padrão
  sol.motivo := 'Realização de visita de biossegurança.';

  -- percorre as linhas selecionadas
  for i in 1 .. p_qtdlinhas
  loop
    old := vis;
    vis := ad_pkg_avs.get_dados_visita(act_int_field(p_idsessao, i, 'NUVISITA'));
    -- confirma geração de N:1
    if p_qtdlinhas > 1 then
      if not act_confirmar('Solicitação de Carro de Apoio',
                           'Confirma a geração de 1 solicitação para ' || p_qtdlinhas || ' visitas?',
                           p_idsessao,
                           1) then
        return;
      end if;
    end if;
  
    -- se já existe solicitação
    if nvl(vis.nucapsol, 0) > 0 and vis.statuscar not in ('C', 'SR') then
      p_mensagem := 'Visita já possui solicitação de carro de apoio. Cancele a solicitação atual (' ||
                    vis.nucapsol || ').';
      return;
    end if;
  
    -- valida cidades das visitas
    if old.codcid is not null and old.codcid != vis.codcid then
      p_mensagem := 'Não é permitido agrupar visitas na mesma viagem quando existem cidades diferentes';
      return;
    end if;
  
    t(i) := vis.nuvisita;
  
    -- monta motivo com nomes dos visitados
    sol.motivo := sol.motivo || chr(13) || 'Visita nro: ' || vis.nuvisita || ' - ' ||
                  vis.nomevisitado;
  
  end loop;

  --insere a solicitação e envia para agendamento do carro de apoio
  ad_pkg_avs.set_carro_apoio(vis.nuvisita, p_horaini, sol.motivo, vis.nucapsol, p_mensagem);
  if p_mensagem is not null and p_mensagem not like '%sucesso%' then
    return;
  end if;

  -- atualiza dados na visita
  for l in t.first .. t.last
  loop
    begin
      update ad_tsfavs
         set carroapoio   = 'S',
             nucapsol     = vis.nucapsol,
             dhprevis     = nvl(p_horaini, vis.dhprevis),
             dhcapsol     = sysdate,
             status       = 'aguard',
             codveiculo   = null,
             dhagendcarro = null,
             statuscar    = 'P'
       where nuvisita = t(l);
    exception
      when others then
        p_mensagem := 'Erro ao atualizar os dados na visita. ' || sqlerrm;
        return;
    end;
  
    begin
      ad_pkg_avs.insere_historico(vis.nuvisita, 'Envio da solicitação de carro de apoio');
    exception
      when others then
        null;
    end;
  
  end loop;

  p_mensagem := 'Processo realizado com sucesso! Foi gerada a solicitação ' || sol.nucapsol;

end;
/
