create or replace procedure ad_stp_cap_valrateio(p_codusu    number,
                                                 p_idsessao  varchar2,
                                                 p_qtdlinhas number,
                                                 p_mensagem  out varchar2) as
  v_nuacerto number;
  error exception;
begin
  /*
  * Autor: Marcus Rangel
  * Processo: Acerto de Carro de apoio
  * Objetivo: Realizar correções nos lançamentos contidos na aba de rateio
  */

  for i in 1 .. p_qtdlinhas
  loop
    v_nuacerto := act_int_field(p_idsessao, i, 'NUACERTO');
  
    for cur_rat in (select nuap, nuacerto, seqacertodia
                      from ad_diaacertotransp
                     where nuacerto = v_nuacerto)
    loop
    
      ad_pkg_cap.insere_rateio_acerto(p_nroagend => cur_rat.nuap, p_nroacerto => cur_rat.nuacerto,
                                      p_seqacerto => cur_rat.seqacertodia, p_errmsg => p_mensagem);
    
    end loop cur_rat;
  end loop i;
  p_mensagem := 'Revalidação concluída com sucesso!!!';
exception
  when error then
    null;
  when others then
    p_mensagem := sqlerrm;
end;
/
