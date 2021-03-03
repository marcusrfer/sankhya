create or replace procedure ad_stp_cap_refazrateio_sf(p_codusu    number,
                                                      p_idsessao  varchar2,
                                                      p_qtdlinhas number,
                                                      p_mensagem  out varchar2) as
  r_cap ad_tsfcap%rowtype;
begin
  /* 
  * Autor: M. Rangel
  * Processo: Carro de Apoio
  * Objetivo: Corrigir o rateio na aba de mesmo nome na tela de agendamento de carro de apoio
  */

  for i in 1 .. p_qtdlinhas
  loop
    r_cap.nuap := act_int_field(p_idsessao, i, 'NUAP');
  
    if r_cap.status not in ('A', 'P') then
      p_mensagem := 'Somente agendamentos não finalizados podem ser refeitos';
      return;
    end if;
  
    delete from ad_tsfcapfrt t where t.nuap = r_cap.nuap;
  
    for r_sol in (with filhos as
                     (select nuap, nuappai, nucapsol from ad_tsfcap c where c.nuappai = r_cap.nuap)
                    select rownum, r.codemp, r.codnat, r.codcencus, nvl(r.codproj, 0) codproj,
                           round(ratio_to_report(count(*)) over() * 100, 4) as percentual
                      from ad_tsfcap c
                      left join filhos f
                        on f.nuappai = c.nuap
                      join ad_tsfcapsol s
                        on s.nucapsol = nvl(c.nucapsol, f.nucapsol)
                      join ad_tsfcaprat r
                        on s.nucapsol = r.nucapsol
                     where c.nuap = r_cap.nuap
                     group by rownum, r.codemp, r.codnat, r.codcencus, nvl(r.codproj, 0)
                     order by rownum)
    loop
      dbms_output.put_line(r_cap.nuap || ' | ' || r_sol.codcencus || ' | ' || r_sol.percentual);
    
      insert into ad_tsfcapfrt
        (nuap, numfrt, codemp, codcencus, codnat, codproj, percentual)
      values
        (r_cap.nuap, r_sol.rownum, r_sol.codemp, r_sol.codcencus, r_sol.codnat, r_sol.codproj,
         r_sol.percentual);
    
    end loop r_sol;
  
  end loop i;

  p_mensagem := 'Rateio recalculado com sucesso!!!';
exception
  when others then
    p_mensagem := 'Ocorreu um erro ao realizar o processo. <br> Detalhes: ' || sqlerrm;
end;
/
