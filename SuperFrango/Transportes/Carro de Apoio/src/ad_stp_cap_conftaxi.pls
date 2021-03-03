create or replace procedure ad_stp_cap_conftaxi(p_codusu    number,
                                                p_idsessao  varchar2,
                                                p_qtdlinhas int,
                                                p_mensagem  out varchar2) is
  v_nuap   number;
  v_motivo varchar2(400);
  errmsg   varchar2(4000);
  error exception;
begin
  /*
  * Autor: Marcus Rangel
  * Processo: Carro de Apoio
  * Objetivo: Informar o motivo da necessidade de táxi no agendamento da corrida.
  */
  for i in 1 .. p_qtdlinhas
  loop
    v_nuap   := act_int_field(p_idsessao, i, 'NUAP');
    v_motivo := act_txt_param(p_idsessao, 'MOTIVOTAXI');
  
    begin
      update ad_tsfcap c set c.taxi = 'S', c.motivotaxi = v_motivo where c.nuap = v_nuap;
    exception
      when others then
        errmsg := 'Erro ao atualizar as informações do Táxi. ' || sqlerrm;
        raise error;
    end;
  end loop;
  p_mensagem := 'Informações atualizadas com sucesso!!!';
exception
  when error then
    p_mensagem := errmsg;
end;
/
