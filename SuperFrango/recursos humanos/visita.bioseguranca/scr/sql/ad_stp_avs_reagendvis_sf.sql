CREATE OR REPLACE PROCEDURE "AD_STP_AVS_REAGENDVIS_SF" (p_codusu number,
                                                     p_idsessao varchar2,
                                                     p_qtdlinhas number,
                                                     p_mensagem out varchar2) as
  v_nuvisita number;
  p_dhprev   date;
  p_motivo   varchar2(4000);
  vis        ad_tsfavs%rowtype;
  v_nomeusu  varchar2(20) := ad_get.nomeusu(p_codusu, 'resumido');
  v_atencao  varchar2(100) := '<span style="color:#ff0000; font-size:18px">Atenção!!!</span>';
begin
  /*
  * Processo: Visita sanitária - RH
  * Autor: M. Rangel
  * Objetivo: Realizar o reagendamento da visita, registrar o motivo
  */

  p_dhprev := act_dta_param(p_idsessao, 'DHPREV');
  p_motivo := act_txt_param(p_idsessao, 'MOTIVO');

  for i in 1 .. p_qtdlinhas
  loop
    v_nuvisita := act_int_field(p_idsessao, i, 'NUVISITA');
  
    begin
      select * into vis from ad_tsfavs where nuvisita = v_nuvisita;
    exception
      when others then
        p_mensagem := 'Erro ao encontrar a visita!';
        return;
    end;
  
    --> valida visitas condluidas
    if vis.status = 'pend' then
      p_mensagem := v_atencao || ' Não há motivos para reagendar uma visita pendente!!!';
      return;
    elsif vis.status = 'conc' then
      p_mensagem := v_atencao || ' Visitas concluídas não podem ser alteradas!';
      return;
    end if;
  
    stp_keygen_tgfnum('AD_TSFAVS', 1, 'AD_TSFAVS', 'NUVISITA', 0, vis.nuvisita);
    vis.obs         := vis.obs || chr(13) || 'Reagendamento da visita ' || v_nuvisita;
    vis.dhinclusao  := sysdate;
    vis.nuvisitapai := v_nuvisita;
    vis.reagend     := 'N';
    vis.dhprevis    := p_dhprev;
  
    --> insere nova visita
    begin
      insert into ad_tsfavs values vis;
    exception
      when others then
        p_mensagem := 'Erro ao inserir reagendamento! ' || sqlerrm;
        return;
    end;
  
    --> atualiza dados na visita anterior
    begin
      update ad_tsfavs a
         set a.reagend       = 'S',
             a.motivoreagend = p_motivo,
             a.historico     = a.historico || chr(13) || to_char(sysdate, 'dd/mm/yyyy hh24:mi:ss') ||
                               ' - Visita reagendada por ' || v_nomeusu
      
       where nuvisita = v_nuvisita;
    exception
      when others then
        p_mensagem := 'Erro ao atualizar a visita de origem! ' || sqlerrm;
        return;
    end;
  
  end loop;

  p_mensagem := 'Reagendamento realizado com sucesso, gerada a visita nº ' || vis.nuvisita;

end;
/
