create or replace procedure ad_stp_ndre_calcindger(p_codusu    number,
                                                   p_idsessao  varchar2,
                                                   p_qtdlinhas number,
                                                   p_mensagem  out varchar2) as
  p_referencia date;
  p_codindger  number;
  errmsg       varchar2(4000);
  i            number;
  t            number;
  v_time       varchar2(100);
  v_select     varchar2(1);
  v_todos      varchar2(1);
  v_count      int := 0;

begin
  /*
  * autor: marcus rangel
  * processo: new dre
  * objetivo: calcular os valores dos indicadores gerenciais. 
              Ação "Recalcular Indicadores" da tela de cadatro de ind. gerenciais
  */

  p_referencia := act_dta_param(p_idsessao, 'DTREF');

  if p_referencia is null then
    p_referencia := to_date(substr(replace(act_dec_param(p_idsessao, 'DTREF'), '.', ''), 1, 8),
                            'yyyymmdd');
  end if;

  i := dbms_utility.get_time;

  v_select := act_escolher_simnao(p_titulo    => 'Cálculo dos valores dos Índices gerenciais',
                                  p_texto     => 'Deseja efetuar os cálculos somente para os indicadores selecionados?',
                                  p_chave     => p_idsessao,
                                  p_sequencia => 1);

  if v_select = 'N' then
  
    v_todos := act_escolher_simnao(p_titulo    => 'Confirmação para cálculo',
                                   p_texto     => 'Confirma o processamento para todos os indicadores?',
                                   p_chave     => p_idsessao,
                                   p_sequencia => 2);
  
    -- processa todos os ativos com fórmula
    if v_todos = 'S' then
    
      ad_pkg_newdre.set_resindger(p_referencia, null, errmsg);
    
      if errmsg is not null then
        p_mensagem := errmsg;
        return;
      end if;
    
    else
      null;
    end if;
  
  else
    -- processa apenas os selecionados
    for l in 1 .. p_qtdlinhas
    loop
    
      p_codindger := act_int_field(p_idsessao, l, 'CODINDGER');
    
      select count(*)
        into v_count
        from dre_cadindger
       where codindger = p_codindger
         and nvl(ativo, 'N') = 'S';
    
      if v_count = 0 then
        p_mensagem := 'Desculpe, o indicador selecionado não está ativo!';
        return;
      end if;
    
      ad_pkg_newdre.set_resindger(p_referencia, p_codindger, errmsg);
    
      if errmsg is not null then
        p_mensagem := errmsg;
        return;
      end if;
    
    end loop l;
  
  end if;

  t := round((dbms_utility.get_time - i) / 100, 2);

  if trunc(t) > 60 then
    v_time := to_char(t) || ' min(s)';
  else
    v_time := to_char(t) || ' seg(s)';
  end if;

  p_mensagem := 'Indicadores calculados com sucesso!!!<br> ' || ' Temp de execução: ' || v_time;

end;
/
