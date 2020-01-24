create or replace function ad_fnc_fcp_getcustoave_sf(p_codtab number,
                                                     p_dtref  date)
  return float deterministic as
  v_result float;
begin
  /*
  ** autor: m.rangel
  ** processo: comissão integrado postura
  ** objetivo: função auxiliar pra retornar o valor do custo do ovo
  */
  select c.vlrovo
    into v_result
    from ad_tsftcpovo c
   where c.codtabpos = p_codtab
     and c.dtref = (select max(dtref)
                      from ad_tsftcpovo o2
                     where o2.codtabpos = p_codtab
                       and o2.dtref <= p_dtref);

  return v_result;
exception
  when others then
    raise;
end;
/
