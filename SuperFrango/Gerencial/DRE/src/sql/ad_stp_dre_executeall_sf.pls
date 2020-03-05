create or replace procedure ad_stp_dre_executeall_sf(p_referencia date,
                                                     p_mensagem   out nocopy varchar2) is
  i     number;
  t     number;
  v_msg varchar2(4000);
  error exception;
begin

  i := dbms_utility.get_time;

  -- cria base de indicadores padrões
  begin
    ad_pkg_newdre.set_baseindpad(p_referencia, p_mensagem);
    if p_mensagem is not null then
      return;
    end if;
    v_msg := 'Base de indicadores padrões criada!';
    ad_pkg_dre.insereeventolog(p_referencia, v_msg, 0, null);
    commit;
  end;

  -- cria base de indicadores gerenciais
  begin
    ad_pkg_newdre.set_baseindger(p_referencia, p_mensagem);
    dbms_output.put_line('Base de indicadores gerenciais criada!');
    v_msg := 'Base de indicadores gerenciais criada!';
    ad_pkg_dre.insereeventolog(p_referencia, v_msg, 0, null);
    commit;
  end;

  -- cria base de descontos comerciais
  begin
    ad_pkg_newdre.set_basedesccom(p_referencia);
    dbms_output.put_line('Base de descontos baixados na referencia');
    v_msg := 'Base de descontos baixados na referencia';
    ad_pkg_dre.insereeventolog(p_referencia, v_msg, 0, null);
    commit;
  end;

  -- cria base de custos de produtos
  begin
    ad_pkg_newdre.set_basecusto(p_referencia, p_mensagem);
    dbms_output.put_line('Base de descontos baixados na referencia');
    v_msg := 'Base de descontos baixados na referencia';
    ad_pkg_dre.insereeventolog(p_referencia, v_msg, 0, null);
    commit;
  end;

  -- calcula valores indicadores gerenciais
  begin
    ad_pkg_newdre.set_resindger(p_referencia, null, p_mensagem);
    dbms_output.put_line('Indicadores padrões calculados!');
    v_msg := 'Indicadores padrões calculados!';
    ad_pkg_dre.insereeventolog(p_referencia, v_msg, 0, null);
    commit;
  end;

  -- calcula os valores da rentabilidade
  begin
    ad_pkg_newdre.set_rentabcom(p_referencia);
    dbms_output.put_line('Valores da rentabilidade calculados!');
    v_msg := 'Valores da rentabilidade calculados!';
    ad_pkg_dre.insereeventolog(p_referencia, v_msg, 0, null);
    commit;
  end;

  -- valores pad
  begin
    ad_pkg_newdre.set_resindpad(p_referencia);
    dbms_output.put_line('Indicadores gerenciais criada!');
    v_msg := 'Indicadores padrões calculados!';
    ad_pkg_dre.insereeventolog(p_referencia, v_msg, 0, null);
    --Commit;
  end;

  t := (dbms_utility.get_time - i) / 100;
  --ad_pkg_dre.insereeventolog(p_referencia, 'término da execução.',0,null);
  p_mensagem := 'Término da execução ( ' || t || 's )';

exception
  when others then
    p_mensagem := 'Erro na execução da Rotina calculo do período. ' || sqlerrm;
end;
/
