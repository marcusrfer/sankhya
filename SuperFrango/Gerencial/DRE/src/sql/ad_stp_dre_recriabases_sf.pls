create or replace procedure ad_stp_dre_recriabases_sf(p_codusu    number,
                                                      p_idsessao  varchar2,
                                                      p_qtdlinhas number,
                                                      p_mensagem  out varchar2) as
  p_dtref date;
  ti      number;
  tt      number;
  vt      varchar2(100);
begin

  /* 
  Autor: M. Rangel
  Processo: DRE
  Objetivo: Botão de ação da tela de hierarquia da DRE, intuito de recriar as bases simultaneamente
  */

  p_dtref := act_dta_param(p_idsessao, 'DTREF');

  ti := dbms_utility.get_time;

  begin
    --ad_pkg_dre.set_baseindpad(p_dtref, p_mensagem);
    ad_pkg_newdre.set_baseindpad(p_dtref, p_mensagem);
    --Commit;
  end;

  begin
    ad_pkg_newdre.set_basecusto(p_dtref, p_mensagem);
  end;

  begin
    ad_pkg_newdre.set_basedesccom(p_dtref);
  end;

  -- base ind ger
  begin
    ad_pkg_newdre.set_baseindger(p_dtref, p_mensagem);
    --Commit;
  end;

  if p_mensagem is not null then
    return;
  end if;

  tt := round(((dbms_utility.get_time - ti) / 100), 2);

  if trunc(tt) > 60 then
    vt := to_char(round(tt / 60, 2)) || ' min(s)';
  else
    vt := to_char(tt) || ' seg(s)';
  end if;

  p_mensagem := 'Bases recriadas em ' || vt;

end;
/
