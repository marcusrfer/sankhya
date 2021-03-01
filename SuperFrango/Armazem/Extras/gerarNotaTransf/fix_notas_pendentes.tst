PL/SQL Developer Test script 3.0
31
begin
  stp_set_atualizando('S');
  for l in (select c.nunota, c.codtipoper, c.ad_tela, i.sequencia, i.codprod, i.qtdneg
              from tgfite i
              join tgfcab c
                on c.nunota = i.nunota
             where c.tipmov = 'T'
               and c.dtneg >= '01/06/2020'
               and i.pendente = 'N'
               and i.qtdentregue = 0
               and i.codprod = 10001)
  loop
    update tgfcab
       set pendente = 'S'
     where nunota = l.nunota
       and pendente = 'N';
  
    update tgfite
       set pendente = 'S'
     where nunota = l.nunota
       and sequencia = l.sequencia
       and pendente = 'N';
  
    if sql%rowcount > 0 then
      dbms_output.put_line(l.nunota);
    end if;
  
  end loop;
  stp_set_atualizando('N');
  commit;
end;
0
0
