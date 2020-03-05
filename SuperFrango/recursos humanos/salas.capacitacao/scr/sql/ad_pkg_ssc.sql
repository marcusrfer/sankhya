create or replace package ad_pkg_ssc as

 procedure atualiza_reserva(p_nureserva number,
                            p_tipo      varchar,
                            p_motivo    varchar2 default null,
                            p_mensagem  out
                            /*+ nocopy */  varchar2);

 function get_nomesala(p_codsala number) return varchar2;

 function get_vlr_parametro(p_chave varchar2) return varchar2;

 /*
   Autor: MARCUS.RANGEL 18/06/2019 15:44:58
   Objetivo: função utlizada para retornar se o usuário logado é suplente ou não no filtro da tela de agendamento  
 */
 function issuplente(p_codusu number, p_nussca number) return integer;

 function issuplente_codgestor(p_codusu number, p_codgestor int) return integer;

 -- valida se atende o prazo mínimo, a lotação e disponibilidade da sala                     
 procedure valida_envio_reserva(p_nroreserva number, p_mensagem out varchar2);

 procedure valida_usuario_lib(p_nussca int, p_codusu int, p_errmsg out varchar);

end ad_pkg_ssc;
/
create or replace package body ad_pkg_ssc as

 function get_nomesala(p_codsala number) return varchar2 is
  v_nomesala varchar2(300);
 begin
 
  select nomesala
    into v_nomesala
    from ad_prhsalas
   where nuprh = 1
     and codsala = p_codsala;
 
  return v_nomesala;
 
 exception
  when others then
   return null;
 end get_nomesala;

 function get_vlr_parametro(p_chave varchar2) return varchar2 is
  st       varchar2(400);
  v_result varchar2(400);
 
 begin
 
  st := 'Select ' || p_chave || ' from ad_tsfprh ' || ' Where ativo = ''S'' and dtvigor = ( ' ||
        ' select max(dtvigor) from ad_tsfprh where ativo = ''S'' ' || ' and dtvigor <= trunc(sysdate) )';
 
  execute immediate st
  into v_result; -- using p_chave ;
 
  return v_result;
 
 exception
  when others then
   v_result := sqlerrm;
   return v_result;
 end get_vlr_parametro;

 procedure atualiza_reserva(p_nureserva number,
                            p_tipo      varchar,
                            p_motivo    varchar2 default null,
                            p_mensagem  out /*+ nocopy */  varchar2) is
  v_status    varchar2(200);
  v_codusu    number;
  mail        tmdfmg%rowtype;
  sca         ad_tsfssca%rowtype;
  sala        varchar2(200);
  msg_monitor varchar2(1000);
 
 begin
 
  v_codusu := stp_get_codusulogado;
 
  variaveis_pkg.v_atualizando := true;
 
  begin
   select * into sca from ad_tsfssca where nussca = p_nureserva;
  exception
   when no_data_found then
    p_mensagem := 'Reserva nro ' || p_nureserva || ' não existe!';
    return;
  end;
 
  -- get nomesala
  begin
   select nomesala into sala from ad_vwprhsalas where codsala = sca.codsala;
  exception
   when others then
    p_mensagem := 'Não foi possível encontrar a sala informada. ' || sqlerrm;
    return;
  end;
 
  -- A provação
  -- R eprovação
  -- C ancelamento
 
  -- popula campos do e-mail
  if p_tipo = 'A' then
   mail.assunto := 'Aprovação de reserva de Ambiente/Sala.';
   v_status     := 'APROVADA';
  elsif p_tipo = 'R' then
   mail.assunto := 'Reprovação de reserva de Ambiente/Sala.';
   v_status     := 'REPROVADA';
  elsif p_tipo = 'C' then
   mail.assunto := 'Cancelamento de reserva de Ambiente/Sala.';
   v_status     := 'CANCELADA';
  else
   p_mensagem := 'Parâmetro ' || p_tipo || ' não pôde ser identificado.';
   return;
  end if;
 
  v_status := '<span style="color: red;">' || v_status || '</span>';
 
  -- validação status com operação
  if p_tipo in ('A', 'R') and sca.status != 'P' then
   p_mensagem := 'Somente reservas pendentes podem ser ' || v_status || ' !';
   return;
   --elsif p_tipo = 'C' and sca.dtreserva >= trunc(sysdate) then
  
  end if;
 
  begin
   -- grava a dt aprovação e altera o status
   update ad_tsfssca
      set dhaprovneg   = sysdate,
          status       = p_tipo,
          motivocancel = p_motivo
    where nussca = p_nureserva;
  
   -- grava a dt aprovação e altera o status da origem
   if sca.nussc is not null then
   
    update ad_tsfsscc
       set dhaprovneg   = sysdate,
           status       = p_tipo,
           motivocancel = p_motivo
     where nussc = sca.nussc;
   
    --monta o corpo do mail
   
    mail.mensagem := 'A reserva ' || sca.nussc || ',' || ' referente a utilização da sala/ambiente ' || sala ||
                     ', no dia ' || sca.dtreserva || ', das ' || fmt.hora(sca.hrini) || ' às ' ||
                     fmt.hora(sca.hrfin) || ', com a finalidade de ' || sca.motivo || '.' || ', foi ' ||
                     v_status || ' por ' || ad_get.nomeusu(v_codusu, 'completo') || ' em ' ||
                     to_char(sysdate, 'dd/mm/yyyy hh24:mi:ss');
   
    if p_tipo = 'C' then
     mail.mensagem := mail.mensagem || '<br><b>Motivo: </b>' || p_motivo;
    end if;
   
    mail.email := ad_get.mailusu(sca.codususol);
   
    -- prep monitor
    if sca.codmonitor is not null then
    
     mail.mensagem := mail.mensagem || chr(13) || '<br>Dados do Monitor: ' ||
                      ad_get.nomeusu(sca.codmonitor, 'completo') || ' / ' || ad_get.mailusu(sca.codmonitor);
    
     mail.email := mail.email || ', ' || ad_get.mailusu(sca.codmonitor);
    end if;
   
    -- envia mail
   
    ad_stp_gravafilabi(mail.assunto, mail.mensagem, mail.email);
   
   end if;
  
  exception
   when others then
    rollback;
    p_mensagem := 'Erro ao atualizar lançamentos. ' || sqlerrm;
    return;
  end;
 
  variaveis_pkg.v_atualizando := false;
 
 end atualiza_reserva;

 /*
   Autor: MARCUS.RANGEL 18/06/2019 15:44:58
   Objetivo: função utlizada para retornar se o usuário logado é suplente ou não no filtro da tela de agendamento  
 */
 function issuplente(p_codusu number, p_nussca number) return integer is
  v_nussca    number;
  v_codgestor number;
 
  t ad_type_of_number := ad_type_of_number();
 
  v_result int;
 
 begin
  -- Test statements here
  for l in (select * from ad_tsfssca where nussca = p_nussca)
  loop
  
   select codgestor
     into v_codgestor
     from ad_prhsalas
    where codsala = l.codsala
      and nuprh = ad_pkg_ssc.get_vlr_parametro('NUPRH');
  
   select s.codususupl
     bulk collect
     into t
     from tsisupl s
    where s.codusu = v_codgestor
      and s.dtfim > sysdate;
  
  end loop;
 
  select count(*) into v_result from dual where p_codusu in (select column_value from table(t));
 
  return v_result;
 
 end issuplente;

 function issuplente_codgestor(p_codusu number, p_codgestor int) return integer is
  v_result int;
  t        int;
 begin
  -- Test statements here
 
  select count(*)
    into t
    from tsisupl s
   where s.codusu = p_codgestor
     And s.codususupl = p_codusu
     and s.dtfim > sysdate;
 
  if t > 0 then
   v_result := 1;
  else
   v_result := 0;
  end if;
 
  return v_result;
 
 end issuplente_codgestor;

 -- valida se atende o prazo mínimo, a lotação e disponibilidade da sala                       
 procedure valida_envio_reserva(p_nroreserva number, p_mensagem out varchar2) is
 begin
 
  for ssc in (
              
              select c.nussc, c.qtdparticipantes, c.dtreserva, c.hrini, c.hrfin
                from ad_tsfsscc c
               where c.nussc = p_nroreserva
              union all
              select r.nussc, r.qtdparticipantes, r.dtreserva, r.hrini, r.hrfin
                from ad_tsfsscr r
               where r.nussc = p_nroreserva
              
              )
  
  loop
   -- valida prazo mínimo e lotação
   for sala in (select nvl(prazomin, 0) prazomin, capacidade
                  from ad_prhsalas
                 where codsala = (select codsala from ad_tsfsscc where nussc = ssc.nussc)
                      --And prazomin > 0
                   and nuprh = ad_pkg_ssc.get_vlr_parametro('NUPRH'))
   loop
    if ssc.dtreserva < to_date(sysdate, 'dd/mm/yyyy') + sala.prazomin then
     p_mensagem := 'O prazo mínimo para solicitação de reserva desta sala/ambiente é de ' || sala.prazomin ||
                   ' dia(s), altere a data de reserva' || ', no mínimo para ' ||
                   to_char(sysdate + sala.prazomin, 'dd/mm/yyyy') || ', para continuar.';
     return;
    end if;
   
    if ssc.qtdparticipantes > sala.capacidade then
     p_mensagem := '***Número de participantes maior que a capacidade da sala.';
     return;
    end if;
   
   end loop;
  
   if ssc.dtreserva = trunc(sysdate) and
      to_number(substr(ssc.hrini, 1, 2)) <
      extract(hour from cast(to_char(sysdate, 'DD/MM/YYYY HH24:MI:SS') as timestamp)) then
    p_mensagem := 'Horário de reserva ('||to_number(substr(ssc.hrini, 1, 2))||') menor que o horário atual ('||
    extract(hour from cast(to_char(sysdate, 'DD/MM/YYYY HH24:MI:SS') as timestamp))||')!';
    return;
   end if;
  
   -- valida reservas no mesmo horário/sala
  
   for reservas in (select *
                      from ad_tsfssca sa
                     where sa.codsala = (select codsala from ad_tsfsscc where nussc = ssc.nussc)
                       and sa.dtreserva = ssc.dtreserva
                       and sa.status != 'R'
                       and sa.nussc != ssc.nussc
                       and ssc.hrini between sa.hrini and sa.hrfin)
   loop
   
    if reservas.status = 'P' then
     p_mensagem := ' Foi encontrada uma solicitação de reserva com o mesmo horário,' ||
                   ' a sua solicitação pode não ser aprovada, deseja enviar assim mesmo?';
     return;
    elsif reservas.status = 'A' then
     p_mensagem := 'Sala/Ambiente indisponível nesta data/horário (Agendamento nro:' || reservas.nussca || ')';
     return;
    end if;
   
   end loop;
  
  end loop;
 
 exception
  when others then
   p_mensagem := 'Não foi encontrada nenhuma parametrização válida!';
   return;
 end valida_envio_reserva;

 procedure valida_usuario_lib(p_nussca int, p_codusu int, p_errmsg out varchar) is
  sca         ad_tsfssca%rowtype;
  v_descrsala varchar2(400);
  v_codresp   int;
  v_nomeresp  varchar2(400);
  v_permitido boolean default false;
 begin
 
  select * into sca from ad_tsfssca where nussca = p_nussca;
 
  select s.nomesala, s.codgestor, ad_get.nomeusu(s.codgestor, 'completo')
    into v_descrsala, v_codresp, v_nomeresp
    from ad_prhsalas s
   where s.codsala = sca.codsala
     and s.nuprh = get_vlr_parametro('NUPRH');
 
  -- validação do usuário liberador -- 30/09/2019 m.rangel
  if sca.codusulib = p_codusu or p_codusu = get_vlr_parametro('CODUSURESPSL') or p_codusu = v_codresp or
     p_codusu = 0 or issuplente(p_codusu, sca.nussca) > 0 then
   v_permitido := true;
  end if;
 
  if not v_permitido then
   p_errmsg := 'Usuário ' || ad_get.nomeusu(p_codusu, 'completo') ||
               ' não pode aprovar solicitações da sala ' || v_descrsala || '.' ||
               ' Entre em contato com responsável da sala: ' || v_nomeresp;
   return;
  end if;
 end valida_usuario_lib;

end ad_pkg_ssc;
/
