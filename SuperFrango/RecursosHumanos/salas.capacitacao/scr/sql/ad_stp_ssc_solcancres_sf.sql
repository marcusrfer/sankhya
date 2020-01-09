create or replace procedure ad_stp_ssc_solcancres_sf(p_codusu    number,
                                                     p_idsessao  varchar2,
                                                     p_qtdlinhas number,
                                                     p_mensagem  out varchar2) as
  p_motivo varchar2(4000);
  v_nussc  number;
  ssc      ad_tsfsscc%rowtype;
  sca      ad_tsfssca%rowtype;
begin

  /*
  ** Autor: M. Rangel
  ** Processo: Solicitação de sala de capacitação
  ** Objetivo: Solicitar o cancelamento da solicitação
  */

  p_motivo := act_txt_param(p_idsessao, 'MOTIVO');

  for i in 1 .. p_qtdlinhas
  loop
  
    v_nussc := act_int_field(p_idsessao, i, 'NUSSC');
  
    select * into ssc from ad_tsfsscc where nussc = v_nussc;
  
    if ssc.status = 'P' then
      p_mensagem := 'A solicitação ainda não foi enviada para Aprovação, podendo ser excluída.';
      return;
    end if;
  
    begin
      select *
        into sca
        from ad_tsfssca s
       where nussc = ssc.nussc
         and rownum = 1
       order by s.nussca;
    exception
      when too_many_rows then
        p_mensagem := 'Existem mais de uma reserva para essa solicitação, contate o suporte.';
        return;
    end;
  
    --envia mensagem no sistema
    ad_set.ins_avisosistema(p_titulo     => 'Cancelamento de reserva',
                            p_descricao  => 'Solicito o cancelamento do agendamento nº ' ||
                                            sca.nussca,
                            p_solucao    => p_motivo,
                            p_usurem     => p_codusu,
                            p_usudest    => sca.codusulib,
                            p_prioridade => 1,
                            p_tabela     => 'AD_TSFSSCA',
                            p_nrounico   => sca.nussca,
                            p_erro       => p_mensagem);
  
    if p_mensagem is not null then
      return;
    end if;
  
    -- envia mail
    ad_stp_gravafilabi(p_assunto  => 'Cancelamento de Reserva de Ambiente de Treinamento/Reunião',
                       p_mensagem => 'Venho por meio deste, solicitar o cancelamento da reserva da sala/ambiente <b>' ||
                                     ad_pkg_ssc.get_nomesala(sca.codsala) || '</b> no dia <b>' ||
                                     to_char(ssc.dtreserva, 'dd/mm/yyyy') ||
                                     ' </b>no intervalo das <b>' || fmt.hora(ssc.hrini) ||
                                     '</b> às ' || fmt.hora(ssc.hrfin) || ', pelo motivo de <b>' ||
                                     p_motivo || '</b>.' || '<br><p>Solicitante: ' ||
                                     nvl(ad_get.nomeusu(ssc.codususol, 'completo'),
                                         ad_get.nomeusu(ssc.codususol, 'resumido')) || ' - ' ||
                                     'CR: ' || ssc.codcencus || ' - ' ||
                                     ad_get.descrcencus(ssc.codcencus),
                       p_email    => ad_get.mailusu(sca.codusulib));
  
  end loop;

  p_mensagem := 'Ação realizada com suscesso!!!';

end;
/
