create or replace procedure ad_stp_dre_recalcind_sf(p_codusu    number,
                                                    p_idsessao  varchar2,
                                                    p_qtdlinhas number,
                                                    p_mensagem  out varchar2) as
  p_dtref date;
  executa boolean;
  tipo    char(1);
  ti      number;
  tt      number;
  vt      varchar2(100);
begin

  /* 
  Autor: M. Rangel
  Processo: DRE
  Objetivo: Botão de ação da tela de hierarquia da DRE, 
            intuito de recalcular os indicadores gerenciais e padrões
  */

  p_dtref := act_dta_param(p_idsessao, 'DTREF');
  tipo    := act_txt_param(p_idsessao, 'INDICADOR');

  executa := act_confirmar(p_titulo    => 'Cálculo de Indicadores',
                           p_texto     => 'Execute os indicadores na seguinte sequência:<br>' ||
                                          '<ol><li>Gerenciais</li><li>Rentabilidade</li><li>Padrões</li></ol>',
                           p_chave     => p_idsessao,
                           p_sequencia => 1);

  if executa then
  
    ti := dbms_utility.get_time;
  
    if tipo = 'G' then
      ad_pkg_newdre.set_resindger(p_dtref, null, p_mensagem);
      commit;
    elsif tipo = 'R' then
      -- valores pad
      ad_pkg_newdre.set_rentabcom(p_dtref);
      commit;
    elsif tipo = 'P' then
      ad_pkg_newdre.set_resindpad(p_dtref);
      commit;
    end if;
  
    if p_mensagem is not null then
      return;
    end if;
  
    tt := round(((dbms_utility.get_time - ti) / 100), 2);
  
    if trunc(tt) > 60 then
      vt := to_char(round(tt / 60, 2)) || ' min(s)';
    else
      vt := to_char(tt) || ' seg(s)';
    end if;
  
    p_mensagem := 'Indicadores recalculados em ' || vt;
  
  end if;

end;
/
