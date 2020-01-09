create or replace procedure ad_stp_ndre_calcindpad_sf(p_codusu    number,
                                                      p_idsessao  varchar2,
                                                      p_qtdlinhas number,
                                                      p_mensagem  out nocopy varchar2) is
 it           number;
 ft           number;
 x            number;
 v_time       varchar2(100);
 v_individual varchar2(1);
 v_todos      varchar2(1);
 v_descrind   varchar2(256);
 v_mensagem   varchar2(4000);
 p_referencia date;

 ind ad_type_of_number := ad_type_of_number();
 rel ad_type_of_number := ad_type_of_number();

begin
 /*
 * autor: marcus rangel
 * processo: new dre
 * objetivo: calcular os valores dos indicadores padrões. ação "Recalcular Indicadores" da tela de cadatro de ind. padrões
 
 22/10/18 - alterado para calcular tudo ao mandar recalcular
 */

 -- get referencia
 begin
  p_referencia := act_dta_param(p_idsessao, 'DTREF');
 
  if p_referencia is null then
   p_referencia := to_date(substr(replace(act_dec_param(p_idsessao, 'DTREF'), '.', ''), 1, 8),
                           'yyyymmdd');
  end if;
 end;

 -- questionamentos sobre execução
 begin
 
  if stp_get_atualizando then
   --Null
   -- depuração do processo
   v_individual := 'N';
   v_todos      := 'S';
   p_referencia := '01/10/2019';
  else
  
   v_individual := act_escolher_simnao('Cálculo dos valores dos Índices padrões',
                                       'Deseja efetuar os cálculos somente para os indicadores selecionados?',
                                       p_idsessao,
                                       1);
  
   if v_individual = 'N' then
    -- confirmar se realmente irá executar todos os indicadores
    v_todos := act_escolher_simnao(p_titulo    => 'Confirmação para cálculo',
                                   p_texto     => 'Confirma o processamento para todos os indicadores?',
                                   p_chave     => p_idsessao,
                                   p_sequencia => 2);
   end if;
  
  end if;
 
 end;

 it := dbms_utility.get_time;

 -- inicio do processamento

 begin
  delete from dre_logeventos;
  commit;
 exception
  when others then
   p_mensagem := 'Erro ao limpar tabela de log antes da execução.' || sqlerrm;
   return;
 end;

 --- nesse momentos, vou construir a array com os códigos dos indicadores selecionados ou todos
 begin
  if v_individual = 'S' then
  
   for l in 1 .. p_qtdlinhas
   loop
    ind.extend;
    ind(l) := act_int_field(p_idsessao, l, 'CODINDPAD');
   end loop;
  
  elsif v_individual = 'N' and v_todos = 'S' then
  
   -- popula a coleção com todos os indicadores de acordo com a ordem da hierarquia
   for l in (select e.codindpad
               from dre_estrutura e
               join dre_cadindpad d
                 on d.codindpad = e.codindpad
              where ativo = 'S'
              order by e.seqind)
   loop
    ind.extend;
    x := ind.last;
    ind(x) := l.codindpad;
   end loop;
  end if;
 end;

 -- processamento
 --percorre os indicadores e checa os relacionamentos
 begin
  if v_individual = 'S' then
   -- calcula os selecioanados e os totalizadores dos mesmos e seus dependentes
   for w in ind.first .. ind.last
   loop
    ad_pkg_newdre.get_relacionamento_indpad(ind(w), rel);
   end loop w;
  
  else
  
   rel := ind;
  
  end if;
 
  for z in rel.first .. rel.last
  loop
  
   -- monta a mensagem de saída com os indicadores relacionados ao selecionado.
   if nvl(v_todos, 'N') = 'N' then
   
    select descrindpad into v_descrind from dre_cadindpad where codindpad = rel(z);
   
    if v_mensagem is null then
     v_mensagem := rel(z) || ' - ' || v_descrind;
    else
     v_mensagem := v_mensagem || chr(13) || '<br> ' || rel(z) || ' - ' || v_descrind;
    end if;
   end if;
  
   -- calcula os indicadores, seja o individual ou no caso de "todos", calcula os que não são totalizadores
   ad_pkg_newdre.set_rentabcom(p_referencia, rel(z));
   ad_pkg_newdre.set_resindpad(p_referencia, rel(z));
  
   if p_mensagem is not null then
    return;
   end if;
  
  end loop z;
 
  -- até este momento, no caso de recalculo de todos, os totalizadores não foram calculados ainda
  -- montagem da array com os relacionamentos entre os totalizadores
  /*if nvl(v_todos, 'N') = 'S' then
  
   begin
   
    ad_pkg_newdre.set_rentabcom(p_referencia, null);
    ad_pkg_newdre.set_resindpad(p_referencia, null);
   
    if p_mensagem is not null then
     return;
    end if;
   
   end;
  
  end if;*/
 
 end;

 ft := round(((dbms_utility.get_time - it) / 100), 2);

 if trunc(ft) > 60 then
  v_time := to_char(round(ft / 60, 2)) || ' min(s)';
 else
  v_time := to_char(ft) || ' seg(s)';
 end if;

 p_mensagem := 'Indicadores calculados com SUCESSO!!!<br> Dependentes recalculados:<br>' ||
               v_mensagem || '.<br> Temp de execução: ' || v_time || '.';

end;
/
