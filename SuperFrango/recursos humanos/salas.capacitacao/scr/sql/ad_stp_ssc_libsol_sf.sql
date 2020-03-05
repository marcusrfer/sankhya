create or replace procedure "AD_STP_SSC_LIBSOL_SF"(p_codusu    number,
                                                   p_idsessao  varchar2,
                                                   p_qtdlinhas number,
                                                   p_mensagem  out varchar2) as

 sca  ad_tsfssca%rowtype;
 acao varchar2(1);
 sala varchar2(100);
begin
 /*
 ** Autor: M. Rangel
 ** Processo: Reserva sala de capacita��o - RH
 ** Objetivo: Realizar aprova��o/reprova��o da solicita��o de reserva da sala
 */

 acao := act_txt_param(p_idsessao, 'TIPOLIB');

 for i in 1 .. p_qtdlinhas
 loop
 
  sca.nussca := act_int_field(p_idsessao, i, 'NUSSCA');
 
  select * into sca from ad_tsfssca where nussca = sca.nussca;
  select nomesala into sala from ad_vwprhsalas where codsala = sca.codsala;
 
  sca.status := acao;
 
  -- grava a dt aprova��o e altera o status
  update ad_tsfssca
     set dhaprovneg = sysdate,
         status     = sca.status
   where nussca = sca.nussca;
 
  -- grava a dt aprova��o e altera o status da origem                  
  if sca.nussc is not null then
   update ad_tsfsscc
      set dhaprovneg = sysdate,
          status     = sca.status
    where nussc = sca.nussc;
  
   -- envia mail
   ad_stp_gravafilabi(p_assunto  => 'Aprova��o/Reprova��o de Solicita��o',
                      p_mensagem => 'A solicita��o ' || sca.nussc ||
                                    ', referente a reserva da sala ' || sala || ', no dia ' ||
                                    sca.dtreserva || ', das ' ||
                                    substr(lpad(sca.hrini, 4, '0'), 1, 2) || ':' ||
                                    substr(sca.hrini, 2, 2) || ' �s ' ||
                                    substr(lpad(sca.hrfin, 4, '0'), 1, 2) || ':' ||
                                    substr(lpad(sca.hrfin, 4, '0'), 3, 2) ||
                                    ', com a finalidade de ' || sca.motivo || '.' || ', foi ' ||
                                    ad_get.opcoescampo(sca.status, 'STATUS', 'AD_TSFSSCA') ||
                                    ' por ' || ad_get.nomeusu(sca.codusulib, 'completo') || ' em ' ||
                                    to_char(sysdate, 'dd/mm/yyyy hh24:mi:ss'),
                      p_email    => ad_get.mailusu(sca.codususol));
  
  end if;
 
 end loop;

 if p_qtdlinhas > 1 then
  p_mensagem := 'Solicita��es ' || ad_get.opcoescampo(sca.status, 'STATUS', 'AD_TSFSSCA') || 's';
 else
  p_mensagem := 'Solicita��o ' || ad_get.opcoescampo(sca.status, 'STATUS', 'AD_TSFSSCA');
 end if;

end;
/
