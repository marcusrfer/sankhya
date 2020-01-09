create or replace function ad_fnc_get_param_fiscal_sf
(
  p_nurelparm number,
  p_data      date,
  p_tipo      varchar2
) return float deterministic is

  vlr ad_relparmaliq%rowtype;

  v_result float;

begin

  /*
  * Autor: Thiago Batista / M. Rangel
  * Processo: Automação fiscal / DRE
  * Objetivo: Retornar os valores mais recentes da tela de parametrização fiscal
  */

  begin
  
    select snk_dividir(a.aliq, 100), snk_dividir(a.aliqst, 100), snk_dividir(a.marglucro, 100),
           snk_dividir(a.percant, 100)
      into vlr.aliq, vlr.aliqst, vlr.marglucro, vlr.percant
      from ad_relparmaliq a
     where a.nurelparm = p_nurelparm
       and a.referencia = (select max(aa.referencia)
                             from ad_relparmaliq aa
                            where aa.nurelparm = a.nurelparm
                              and aa.referencia <= p_data);
  
    if p_tipo = 'ALIQ' then
      v_result := vlr.aliq;
    elsif p_tipo = 'ALIQST' then
      v_result := vlr.aliqst;
    elsif p_tipo = 'MARGLUCRO' then
      v_result := vlr.marglucro;
    elsif p_tipo = 'PERCANT' then
      v_result := vlr.percant;
    else
      v_result := 0;
    end if;
  
  exception
    when others then
      v_result := 0;
  end;

  return(v_result);

end;
/
