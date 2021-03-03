create or replace function ad_fnc_antt_getvalores(p_codemp     int,
                                                  p_ordemcarga number) return float is
  preco_final float;
  v_memcalc   varchar2(4000);
begin
  /*
  ** autor: m. rangel
  ** processo: calculo de frete ANTT
  ** objetivo: criar interface para sql da procedure de calculo do frete
  */

  ad_stp_antt_calcfrete_oc(p_codemp, p_ordemcarga, preco_final, v_memcalc);

  return round(preco_final, 2);

end;
/
