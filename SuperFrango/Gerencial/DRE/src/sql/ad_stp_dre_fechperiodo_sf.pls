create or replace procedure ad_stp_dre_fechperiodo_sf(p_codusu    number,
                                                      p_idsessao  varchar2,
                                                      p_qtdlinhas number,
                                                      p_mensagem  out varchar2) as
  p_dtref    date;
  p_tipooper varchar2(1);
  v_seqind   pls_integer;
  v_numfech  pls_integer;
begin
  /* Autor: M. Rangel
  * Processo: DRE
  * Objetivo: Fechar ou Reabrir determinados períodos impedindo ou permitindo alteração nos registros bases.
  */

  p_dtref    := act_dta_param(p_idsessao, 'DTREF');
  p_tipooper := act_txt_param(p_idsessao, 'TIPOOPER');

  for i in 1 .. p_qtdlinhas
  loop
    begin
      v_seqind := act_int_field(p_idsessao, i, 'SEQIND');
    
      stp_keygen_tgfnum('DRE_FECHAMENTOS', 1, 'DRE_FECHAMENTOS', 'NUMFECH', 0, v_numfech);
    
      insert into dre_fechamentos
        (numfech, dtref, codusu, dhalter, operacao)
      values
        (v_numfech, p_dtref, stp_get_codusulogado, sysdate,
         case when p_tipooper = '1' then 'A' else 'F' end);
    
    exception
      when others then
        p_mensagem := ad_fnc_formataerro('Erro ao realizar operação. <br> Detalhes: ' || sqlerrm);
        return;
    end;
  
  end loop;

  p_mensagem := 'Operação realizada com sucesso!!!';

end;
/
