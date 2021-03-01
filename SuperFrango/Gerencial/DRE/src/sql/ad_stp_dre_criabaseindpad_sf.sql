create or replace procedure ad_stp_dre_criabaseindpad_sf(p_codusu    number,
                                                         p_idsessao  varchar2,
                                                         p_qtdlinhas number,
                                                         p_mensagem  out varchar2) as
  p_referencia date;
begin
  /*
  * autor: m. rangel
  * processo: new dre
  * objetivo: criar base de dados para os cálculos na referência, 
              utilizado na ação "Recriar Base de Dados" na tela de cadastro de indicador padrão
  */
  p_referencia := act_dta_param(p_idsessao, 'DTREF');

  if p_referencia is null then
    p_referencia := to_date(substr(replace(act_dec_param(p_idsessao, 'DTREF'), '.', ''), 1, 8), 'yyyymmdd');
  end if;

  begin
    execute immediate 'SELECT COUNT(*) FROM DRE_BASEINDPAD WHERE DTREF = :DTREF'
      into ad_pkg_var.count
      using p_referencia;
  exception
    when others then
      dbms_output.put_line(sqlerrm);
  end;

  if ad_pkg_var.count > 0 then
    if act_escolher_simnao(p_titulo => 'Sobreposição de lançamentos.',
                           p_texto => 'Já existem lançamentos gerados para a referência informada.' ||
                                       '\nDeseja Sobrescrever essas informações?', p_chave => p_idsessao,
                           p_sequencia => 0) = 'N' then
      return;
    else
      execute immediate 'delete from dre_baseindpad where dtref = :dtref'
        using p_referencia;
    end if;
  end if;

  ad_pkg_var.init_time := dbms_utility.get_time;
  ad_pkg_newdre.set_baseindpad(p_referencia, ad_pkg_var.errmsg);
  ad_pkg_newdre.set_basecusto(p_referencia, ad_pkg_var.errmsg);
  ad_pkg_newdre.set_basedesccom(p_referencia, ad_pkg_var.errmsg);
  ad_pkg_var.end_time := trunc(dbms_utility.get_time - ad_pkg_var.init_time / 100);

  if ad_pkg_var.errmsg is null then
    p_mensagem := '<img src="http://chittagongit.com/images/green-check-mark-icon-png/green-check-mark-icon-png-13.jpg" ' ||
                  ' style="width:64px;height:64px;float:left">' || '<p style="text-align:center;padding:10px 3px">' || '
		Base de dados recriada com sucesso' || ' em ' ||
                  to_char(to_date(ad_pkg_var.end_time, 'sssss'), 'hh24:mi:ss') || ' Mins.</p>';
  else
    p_mensagem := ad_pkg_var.errmsg;
    return;
  end if;

end;
/
