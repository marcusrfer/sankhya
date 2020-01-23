create or replace procedure ad_stp_fcp_getreftabela_sf(p_codcencus in number,
                                                       p_dtref     in date,
                                                       p_sexo      in varchar2 default null,
                                                       p_codtab    out number,
                                                       p_dtreftab  out date,
                                                       p_recoper   out float,
                                                       p_recatrat  out float,
                                                       p_recbonus  out float,
                                                       p_rectotal  out float,
                                                       p_custo     out float) is
Begin

  /*
  ** autor: m. rangel
  ** processo: fechamento comissão integrado recria e postura 
  ** objetivo: retornar os valores da tabela de comissões de acordo 
               com sexo e referência
  */
                                                                   

  -- busca tabela
  begin
    select distinct c.codtabpos
      into p_codtab
      from ad_tsftcp p
      join ad_tsftcpcus c
        on c.codtabpos = p.codtabpos
     where c.codcencus = p_codcencus
       and nvl(p.sexo, 'N') = nvl(p_sexo, 'N');
  exception
    when others then
      raise;
  end;

  -- busca valores da referencia da tabela
  begin
    select r.dtref, r.recoper, r.recatrat, r.recbonus, r.rectotal
      into p_dtreftab, p_recoper, p_recatrat, p_recbonus, p_rectotal
      from ad_tsftcpref r
     where r.codtabpos = p_codtab
       and r.dtref = (select max(dtref)
                        from ad_tsftcpref r2
                       where r2.codtabpos = p_codtab
                         and r2.dtref <= p_dtref);
  exception
    when others then
      raise;
  end;

  begin
    select c.vlrovo
      into p_custo
      from ad_tsftcpovo c
     where c.codtabpos = p_codtab
       and c.dtref = (select max(dtref)
                        from ad_tsftcpovo o2
                       where o2.codtabpos = p_codtab
                         and o2.dtref <= p_dtref);
  exception
    when no_data_found then
      p_custo := 0;
  end;
end;
/
