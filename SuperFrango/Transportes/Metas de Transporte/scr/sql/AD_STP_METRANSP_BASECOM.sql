create or replace procedure ad_stp_metransp_basecom(p_codusu    number,
                                                    p_idsessao  varchar2,
                                                    p_qtdlinhas number,
                                                    p_mensagem  out varchar2) as
  v_dtref  date;
  v_codcat number;
  v_numet  number;

begin

  /*
  * Autor: Marcus Rangel
  * Processo: Metas Logística
  * Objetivo: Recalcular os valores da previsão comercial e grava em tabela temporária para agilizar a pesquisa
  */

  for i in 1 .. p_qtdlinhas
  loop
    v_dtref  := act_dta_field(p_idsessao, i, 'DTREF');
    v_codcat := act_int_field(p_idsessao, i, 'CODCAT');
    v_numet  := act_int_field(p_idsessao, i, 'NUMET');
  
    begin
      delete from ad_tsfpcr p where dtref = v_dtref;
    exception
      when others then
        p_mensagem := 'Erro ao excluir o valores.';
        return;
    end;
  
    begin
      merge into ad_tsfpcr p
      using (select ef.dtrererencia dtref, ef.codger codreg,
                    sum(case
                          when ven.ad_codcat = '2' then
                           round(ef.qtdsimulada, 1) * 2
                          else
                           round(ef.qtdsimulada, 2)
                        end) qtdprevista
               from vw_estima_fat_sf ef
               join tgfven ven
                 on ef.codger = ven.codvend
              where trunc(ef.dtrererencia, 'mm') = v_dtref
                and ven.ativo = 'S'
              group by ef.dtrererencia, ef.codger) d
      on (p.dtref = d.dtref and p.codreg = d.codreg)
      when matched then
        update set qtdprevista = d.qtdprevista
      when not matched then
        insert values (d.dtref, d.codreg, d.qtdprevista);
    
    exception
      when others then
        p_mensagem := 'Erro ao atualizar as quantidades previstas pelo comercial. ' || sqlerrm;
        --p_mensagem := ad_get.formatnativeoramsg(p_errmsg);
        --Raise error;
        return;
    end;
  
  end loop;

  p_mensagem := 'Valores atualizados com sucesso!!!';

end;
/
