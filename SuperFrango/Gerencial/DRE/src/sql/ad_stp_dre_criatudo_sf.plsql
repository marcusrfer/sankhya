create or replace procedure ad_stp_dre_criatudo_sf(p_codusu    number,
                                                   p_idsessao  varchar2,
                                                   p_qtdlinhas number,
                                                   p_mensagem  out varchar2) as
  p_dtref date;
  p_acao  varchar2(4000);
  ti      number;
  tt      number;
  vt      varchar2(100);
  i       int;
begin

  /*
  Autor: M. Rangel
  Processo: New DRE
  Objetivo: Botão de ação da tele de estrutura da DRE
  */

  p_dtref := act_dta_param(p_idsessao, 'DTREF');
  p_acao  := act_txt_param(p_idsessao, 'ACAO');

  /*
  1-Criar Base Padrão
  2-Criar Bases Acessórias
  3-Criar Base Gerencial
  4-Calcular Ind. Gerencial
  5-Calcular Rentabilidade
  6-Calcular Ind. Padão
  */

  if p_acao = '1' then
    p_mensagem := 'Base de Indicadores Padrões';
  
    ti := dbms_utility.get_time;
  
    ad_pkg_newdre.set_baseindpad(p_dtref, p_mensagem);
  
    if p_mensagem is not null then
      return;
    end if;
  
    tt := round(((dbms_utility.get_time - ti) / 100), 2);
  
    commit;
  elsif p_acao = '2' then
  
    select count(*)
      into i
      from dre_baseindpad
     where dtref = p_dtref;
  
    if i = 0 then
      p_mensagem := q'[Não encontramos dados na base atual, 
				           por favor calcule a base dos indicadores padrões
															primeiro!]';
      return;
    end if;
  
    p_mensagem := 'Base Auxiliares';
    ti         := dbms_utility.get_time;
  
    ad_pkg_newdre.set_basecusto(p_dtref, p_mensagem);
    ad_pkg_newdre.set_basedesccom(p_dtref, p_mensagem);
  
    if p_mensagem is not null then
      return;
    end if;
  
    tt := round(((dbms_utility.get_time - ti) / 100), 2);
  
  elsif p_acao = '3' then
  
    select count(*)
      into i
      from dre_baseindpad
     where dtref = p_dtref;
  
    if i = 0 then
      p_mensagem := q'[Não encontramos dados na base atual, 
				           por favor calcule a base dos indicadores padrões
															primeiro!]';
      return;
    end if;
  
    p_mensagem := 'Base de Indicadores Gerenciais';
    ti         := dbms_utility.get_time;
    ad_pkg_newdre.set_baseindger(p_dtref, p_mensagem);
    tt := round(((dbms_utility.get_time - ti) / 100), 2);
  
  elsif p_acao = '4' then
  
    select count(*)
      into i
      from dre_baseindger
     where dtref = p_dtref;
  
    if i = 0 then
      p_mensagem := q'[Não encontramos dados na base atual, 
				           por favor calcule a base dos indicadores gerenciais
															primeiro!]';
      return;
    end if;
  
    p_mensagem := 'Calculo Ind. Gerenciais';
    ti         := dbms_utility.get_time;
    ad_pkg_newdre.set_resindger(p_dtref, null, p_mensagem);
  
    if p_mensagem is not null then
      return;
    end if;
  
    tt := round(((dbms_utility.get_time - ti) / 100));
  
  elsif p_acao = '5' then
  
    select count(*)
      into i
      from dre_baseindpad
     where dtref = p_dtref;
  
    if i = 0 then
      p_mensagem := q'[Não encontramos dados na base atual, 
				           por favor calcule a base dos indicadores padrões
															primeiro!]';
      return;
    end if;
  
    p_mensagem := 'Calculo da Rentabilidade';
    ti         := dbms_utility.get_time;
    ad_pkg_newdre.set_rentabcom(p_dtref, null, p_mensagem);
    tt := round(((dbms_utility.get_time - ti) / 100));
  
  elsif p_acao = '6' then
  
    select count(*)
      into i
      from dre_baseindpad
     where dtref = p_dtref;
  
    if i = 0 then
      p_mensagem := q'[Não encontramos dados na base atual, 
				           por favor calcule a base dos indicadores padrões
															primeiro!]';
      return;
    end if;
  
    select count(*)
      into i
      from dre_baseindger
     where dtref = p_dtref;
  
    if i = 0 then
      p_mensagem := q'[Não encontramos dados na base atual, 
				           por favor calcule a base dos indicadores gerenciais
															primeiro!]';
      return;
    end if;
  
    p_mensagem := 'Calculo Ind. Padrões';
    ti         := dbms_utility.get_time;
    ad_pkg_newdre.set_resindpad(p_dtref, null, p_mensagem);
  
    tt := round(((dbms_utility.get_time - ti) / 100));
  
  end if;

  vt := to_char(to_date(tt, 'sssss'), 'hh24:mi:ss');

  p_mensagem := 'Ação: "' || p_mensagem || '" realizada com sucesso em ' || vt;

end;
/
