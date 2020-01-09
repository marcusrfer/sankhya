create or replace procedure ad_stp_ssc_aprovreservasl_sf(p_codusu    number,
                                                         p_idsessao  varchar2,
                                                         p_qtdlinhas number,
                                                         p_mensagem  out varchar2) as
 v_nussca    number;
 v_descrsala varchar2(400);
 v_codresp   number;
 v_nomeresp  varchar2(400);
 v_confirma  boolean;
 v_permitido boolean default false;
 sca         ad_tsfssca%rowtype;
 sala        ad_prhsalas.nomesala%type;
begin
 /*
 ** Autor: M. Rangel
 ** Processo: Reserva sala de capacita��o - RH
 ** Objetivo: Realizar aprova��o da solicita��o de reserva da sala
 */
 for i in 1 .. p_qtdlinhas
 loop
 
  v_nussca := act_int_field(p_idsessao, i, 'NUSSCA');
 
  select * into sca from ad_tsfssca where nussca = v_nussca;
 
  -- valida��o do usu�rio liberador -- 30/09/2019 m.rangel
  ad_pkg_ssc.valida_usuario_lib(sca.nussca, p_codusu, p_mensagem);
 
  if p_mensagem is not null then
   return;
  end if;
  -- fim valida��o liberador
 
  if sca.codusulib is null then
   p_mensagem := 'Informe o c�digo do usu�rio respons�vel pela libera��o da solicita��o';
   return;
  end if;
 
  -- valida reservas j� aprovadas no mesmo hor�rio/sala
  for reservas in (select *
                     from ad_tsfssca sa
                    where sa.codsala = sca.codsala
                      and sa.dtreserva = sca.dtreserva
                      and sa.status = 'A'
                      and sa.nussca != sca.nussca
                      and (sca.hrini between sa.hrini and sa.hrfin or sca.hrfin between sa.hrini and sa.hrfin))
  loop
  
   v_confirma := act_confirmar(p_titulo    => 'Reservas conflitantes',
                               p_texto     => ' Foi encontrada uma solicita��o de reserva no mesmo hor�rio, ' ||
                                              reservas.nussca || ' - ' ||
                                              ad_get.nomeusu(reservas.codususol, 'completo') ||
                                              ', deseja aprovar assim mesmo?',
                               p_chave     => p_idsessao,
                               p_sequencia => i);
  
   if not v_confirma then
    return;
   end if;
  
  end loop;
 
  -- realiza a aprova��o
  ad_pkg_ssc.atualiza_reserva(p_nureserva => v_nussca, p_tipo => 'A', p_mensagem => p_mensagem);
 
  if p_mensagem is not null then
   return;
  end if;
 
 end loop;

 p_mensagem := 'Aprova��o realizada com Sucesso!!!';

end;
/
