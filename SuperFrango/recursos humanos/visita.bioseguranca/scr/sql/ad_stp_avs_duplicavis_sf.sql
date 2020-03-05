create or replace procedure ad_stp_avs_duplicavis_sf(p_codusu    number,
                                                     p_idsessao  varchar2,
                                                     p_qtdlinhas number,
                                                     p_mensagem  out varchar2) as
 p_qtdrept number;
 vis       ad_tsfavs%rowtype;
 v_nomeusu varchar2(20) := ad_get.nomeusu(p_codusu, 'resumido');
begin

 /*
 * Processo: Agenda de visitas sanitárias
 * Autor: m. rangel
 * Objetivo: criar duplicações de visitas
 */

 p_qtdrept := act_int_param(p_idsessao, 'QTDREPT');

 for l in 1 .. p_qtdlinhas
 loop
 
  /*if (p_qtdlinhas > 1) then
    p_mensagem := 'Selecione apenas uma visita para gerar os reagendamentos!';
    return;
  end if;*/
 
  vis.nuvisita := act_int_field(p_idsessao, l, 'NUVISITA');
 
  begin
   select * into vis from ad_tsfavs where nuvisita = vis.nuvisita;
  exception
   when others then
    p_mensagem := 'Não foi possível encontrar os dados da visita selecionada (Nuvisita = null)';
    return;
  end;
 
  -- cria as visitas de acordo com a quantidade do parâmentro
  for i in 1 .. p_qtdrept
  loop
   stp_keygen_tgfnum(p_arquivo => 'AD_TSFAVS',
                     p_codemp  => 1,
                     p_tabela  => 'AD_TSFAVS',
                     p_campo   => 'NUVISITA',
                     p_dsync   => 0,
                     p_ultcod  => vis.nuvisita);
  
   vis.dhinclusao    := sysdate;
   vis.dhvisita      := null;
   vis.reagend       := 'N';
   vis.motivoreagend := null;
   vis.carroapoio    := 'N';
   vis.nucapsol      := null;
   vis.codveiculo    := null;
   vis.dhagendcarro  := null;
   vis.statuscar     := null;
   --vis.obs        := vis.obs || chr(13) || 'Reagendamento';
   --vis.historico  := to_char(sysdate, 'dd/mm/yyyy hh24:mi:ss') || ' - Visita reagendada por ' || v_nomeusu;
  
   begin
    insert into ad_tsfavs values vis;
   exception
    when others then
     p_mensagem := 'Erro ao duplicar visita. ' || sqlerrm;
     return;
   end;
  
  end loop;
 
 end loop;

 p_mensagem := 'Duplicações realizada com sucesso!';

end;
/
