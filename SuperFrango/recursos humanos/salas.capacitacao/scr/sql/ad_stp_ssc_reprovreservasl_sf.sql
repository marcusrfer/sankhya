create or replace procedure ad_stp_ssc_reprovreservasl_sf(p_codusu    number,
                                                          p_idsessao  varchar2,
                                                          p_qtdlinhas number,
                                                          p_mensagem  out varchar2) as
 p_motivo varchar2(4000);
 v_nussca number;
begin
 /*
 ** Autor = M. Rangel
 ** Processo = Reserva sala de capacitação - RH (SSC)
 ** Obejtivo = Realizar a reprovação da solicitação de reserva de sala/ambiente.
 */
 p_motivo := act_txt_param(p_idsessao, 'MOTIVO');

 for i in 1 .. p_qtdlinhas
 loop
 
  v_nussca := act_int_field(p_idsessao, i, 'NUSSCA');
 
  ad_pkg_ssc.atualiza_reserva(v_nussca, 'R', p_motivo, p_mensagem);
 
  if p_mensagem is not null then
   return;
  end if;
 
 end loop;

 p_mensagem := 'Ação concluída com sucesso!!!';

end;
/
