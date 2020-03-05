create or replace procedure ad_stp_ndre_criabaseindger(p_codusu    number,
                                                       p_idsessao  varchar2,
                                                       p_qtdlinhas number,
                                                       p_mensagem  out varchar2) as
  p_referencia date;
  errmsg       varchar2(4000);
begin

  p_referencia := act_dta_param(p_idsessao, 'DTREF');

  if upper(p_idsessao) = 'DEBUG' then
    p_referencia := '01/01/2018';
  end if;

  if p_referencia is null then
    p_referencia := to_date(substr(replace(act_dec_param(p_idsessao, 'DTREF'), '.', ''), 1, 8),
                            'yyyymmdd');
  end if;

  ad_pkg_var.nometab := 'DRE_BASEINDGER';

  begin
    execute immediate 'Select count(*) from ' || ad_pkg_var.nometab || ' '
      into ad_pkg_var.count;
  exception
    when others then
      ad_pkg_var.count := 0;
  end;

  if ad_pkg_var.count > 0 then
  
    if act_escolher_simnao(p_titulo    => 'Sobreposição de lançamentos.',
                           p_texto     => 'Já existem lançamentos gerados para a referência informada.' ||
                                          '\nDeseja Sobrescrever essas informações?',
                           p_chave     => p_idsessao,
                           p_sequencia => 0) = 'S' then
      execute immediate 'delete from ' || ad_pkg_var.nometab || ' where dtref = :dtref'
        using p_referencia;
    else
      return;
    end if;
  
  end if;

  ad_pkg_var.init_time := dbms_utility.get_time;

  ad_pkg_newdre.set_baseindger(p_referencia, errmsg);

  ad_pkg_var.end_time := (dbms_utility.get_time - ad_pkg_var.init_time) / 60;

  if errmsg is null then
    p_mensagem := 'Base de dados recriada com sucesso' || ' em ' || trunc(ad_pkg_var.end_time) ||
                  'segs';
  else
    p_mensagem := errmsg;
  end if;

end;
/
