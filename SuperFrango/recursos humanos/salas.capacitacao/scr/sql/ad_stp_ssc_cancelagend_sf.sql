create or replace procedure ad_stp_ssc_cancelagend_sf(p_codusu    number,
                                                      p_idsessao  varchar2,
                                                      p_qtdlinhas number,
                                                      p_mensagem  out varchar2) as
 p_motivo varchar2(4000);
 v_nussca number;

begin

 /*
 ** Autor: M. rangel
 ** Processo: Reserva de sala de capacitação
 ** Objetivo: cancelar agendamentos.
 */

 p_motivo := act_txt_param(p_idsessao, 'MOTIVO');

 variaveis_pkg.v_atualizando := true;

 for i in 1 .. p_qtdlinhas
 loop
  v_nussca := act_int_field(p_idsessao, i, 'NUSSCA');
 
  -- validação do usuário liberador -- 30/09/2019 m.rangel
  ad_pkg_ssc.valida_usuario_lib(p_nussca => v_nussca, p_codusu => p_codusu, p_errmsg => p_mensagem);
 
  if p_mensagem is not null then
   return;
  end if;
  -- fim validação liberador
 
  ad_pkg_ssc.atualiza_reserva(p_nureserva => v_nussca,
                              p_tipo      => 'C',
                              p_motivo    => p_motivo,
                              p_mensagem  => p_mensagem);
 
 end loop;

 variaveis_pkg.v_atualizando := false;

 if p_qtdlinhas > 1 then
  p_mensagem := 'Agendamentos cancelados com Sucesso!!!';
 else
  p_mensagem := 'Agendamento cancelado com sucesso!!!';
 end if;

end;
/
