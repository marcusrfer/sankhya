create or replace procedure ad_stp_avs_geravisita_sf(p_codusu    number,
                                                     p_idsessao  varchar2,
                                                     p_qtdlinhas number,
                                                     p_mensagem  out varchar2) as

 vis ad_tsfavs%rowtype;

 cur  sys_refcursor;
 v_id int;
 stm  varchar2(32767);
 stm2 varchar2(200);

 v_confirma boolean default false;

 type tab_visitas is table of ad_vw_vismanut%rowtype;
 t_vsm tab_visitas;

 x int := 0;

begin

 /*
 * Autor: M. Rangel
 * Processo: Vistias Sanitarias
 * Objetivo: Realizar a inserção de visitas em lote para funcionários
             de acordo com a periodicidade definida na tela de parametros do RH.
             Ação anexada a tabela TSFAAD, utilizada no dash de prog visita manut func
 */

 -- valida se registro selecionado
 if p_qtdlinhas = 0 then
  p_mensagem := 'Necessário selecionar um linha!';
  return;
 end if;

 -- captura paramentros
 v_id         := act_int_field(p_idsessao, 1, 'ID');
 vis.dhprevis := act_dta_param(p_idsessao, 'DHPREVIS');

 -- percorre as linhas
 for i in 1 .. p_qtdlinhas
 loop
 
  -- captura selecionados
  vis.matfunc := act_int_field(p_idsessao, i, 'MATFUNC');
  vis.codemp  := act_int_field(p_idsessao, i, 'CODEMP');
 
  -- pega as queries do dash
  if v_id = 1 then
   stm := 'select * from ad_vw_vismanut where dias_prox_visita between 0 and 31';
  elsif v_id = 2 then
   stm := 'select * from ad_vw_vismanut where dias_prox_visita > 31';
  elsif v_id = 3 then
   stm := 'select * from ad_vw_vismanut v where dias_prox_visita between -90 and -1';
  elsif v_id = 4 then
   stm := 'select 4 as id, v.* from ad_vw_vismanut v where dias_prox_visita < -90';
  end if;
 
  -- questiona sobre execução unica ou em lote
  if p_qtdlinhas = 1 then
  
   v_confirma := act_confirmar(p_titulo    => 'Geração de Visitas',
                               p_texto     => 'Deseja gerar visitas para todos os funcionários?',
                               p_chave     => p_idsessao,
                               p_sequencia => 0);
  
  end if;
 
  if v_confirma = false then
   stm2 := ' and codemp = ' || vis.codemp || ' and matfunc = ' || vis.matfunc;
  end if;
 
  stm := stm || chr(13) || stm2;
 
  -- captura todos os registros do quadrante do dash   
  open cur for stm;
  fetch cur bulk collect
  into t_vsm;
  close cur;
 
  -- percorre linha a linha
  for l in t_vsm.first .. t_vsm.last
  loop
  
   -- insere a visita
   ad_pkg_avs.set_nova_visita_funcionario(p_codemp   => vis.codemp,
                              p_matfunc  => vis.matfunc,
                              p_tipovis  => 'M',
                              p_dhprevis => nvl(vis.dhprevis, t_vsm(l).prox_visita),
                              p_nuvisita => vis.nuvisita,
                              p_mensagem => p_mensagem);
   if p_mensagem is not null then
    return;
   end if;
  
  end loop;
 
  x := t_vsm.count;
  t_vsm.delete;
 
 end loop;

 if p_qtdlinhas = 1 and not v_confirma then
  p_mensagem := 'Visita nro ' || vis.nuvisita || ' gerada com sucesso!';
 elsif p_qtdlinhas = 1 and v_confirma then
  p_mensagem := 'Total de ' || x || ' visitas geradas com sucesso!!!';
 else
  p_mensagem := p_qtdlinhas || ' visitas foram geradas com sucesso!';
 end if;

end;
/
