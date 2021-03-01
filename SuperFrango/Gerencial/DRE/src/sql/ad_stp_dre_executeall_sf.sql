create or replace procedure ad_stp_dre_executeall_sf(p_referencia date,
                                                     p_mensagem out nocopy varchar2) is
  i     number;
  t     number;
  v_msg varchar2(4000);
  error exception;
begin
  /*
    Autor: MARCUS.RANGEL 20/05/2020 10:52:03
    Processo: New DRE
    Objetivo: Essa procedure é a que é chamada no agendamento do sistema
  */

  -- cria base de indicadores padrões
  begin
    i := dbms_utility.get_time;
  
    ad_pkg_newdre.set_baseindpad(p_referencia, p_mensagem);
  
    if p_mensagem is not null then
      return;
    end if;
  
    v_msg := 'Base de indicadores padrões criada!';
    ad_pkg_newdre.insereeventolog(p_referencia, v_msg, 0, null);
  
    t := trunc((dbms_utility.get_time - i) / 100);
    dbms_output.put_line(v_msg || ' - ' || to_char(to_date(t, 'sssss'), 'hh24:mi:ss'));
  end;

  -- cria base dA FINRQRAT
  begin
    i := dbms_utility.get_time;
  
    ad_pkg_newdre.set_basefinreqrat(p_referencia, p_mensagem);
  
    if p_mensagem is not null then
      return;
    end if;
  
    v_msg := 'Base da FINREQRAT criada!';
    ad_pkg_newdre.insereeventolog(p_referencia, v_msg, 0, null);
  
    t := trunc((dbms_utility.get_time - i) / 100);
    dbms_output.put_line(v_msg || ' - ' || to_char(to_date(t, 'sssss'), 'hh24:mi:ss'));
  end;

  -- cria base de indicadores gerenciais
  begin
    i := dbms_utility.get_time;
  
    ad_pkg_newdre.set_baseindger(p_referencia, p_mensagem);
  
    if p_mensagem is not null then
      return;
    end if;
  
    v_msg := 'Base de indicadores gerenciais criada!';
    ad_pkg_newdre.insereeventolog(p_referencia, v_msg, 0, null);
  
    t := trunc((dbms_utility.get_time - i) / 100);
    dbms_output.put_line(v_msg || ' - ' || to_char(to_date(t, 'sssss'), 'hh24:mi:ss'));
  end;

  -- cria base de descontos comerciais
  begin
    i := dbms_utility.get_time;
  
    ad_pkg_newdre.set_basedesccom(p_referencia, p_mensagem);
  
    if p_mensagem is not null then
      return;
    end if;
  
    v_msg := 'Base de descontos baixados na referencia';
    ad_pkg_newdre.insereeventolog(p_referencia, v_msg, 0, p_mensagem);
  
    t := trunc((dbms_utility.get_time - i) / 100);
    dbms_output.put_line(v_msg || ' - ' || to_char(to_date(t, 'sssss'), 'hh24:mi:ss'));
  end;

  -- cria base de custos de produtos
  begin
    i := dbms_utility.get_time;
  
    ad_pkg_newdre.set_basecusto(p_referencia, p_mensagem);
  
    if p_mensagem is not null then
      return;
    end if;
  
    v_msg := 'Base de custos de produtos na referencia';
    ad_pkg_newdre.insereeventolog(p_referencia, v_msg, 0, null);
  
    t := trunc((dbms_utility.get_time - i) / 100);
    dbms_output.put_line(v_msg || ' - ' || to_char(to_date(t, 'sssss'), 'hh24:mi:ss'));
  end;

  -- calcula valores indicadores gerenciais
  begin
    i := dbms_utility.get_time;
  
    ad_pkg_newdre.set_resindger(p_referencia, null, p_mensagem);
  
    if p_mensagem is not null then
      return;
    end if;
  
    v_msg := 'Indicadores gerenciais calculados!';
    ad_pkg_newdre.insereeventolog(p_referencia, v_msg, 0, null);
  
    t := trunc((dbms_utility.get_time - i) / 100);
    dbms_output.put_line(v_msg || ' - ' || to_char(to_date(t, 'sssss'), 'hh24:mi:ss'));
  end;

  -- calcula os valores da rentabilidade
  begin
    i := dbms_utility.get_time;
  
    ad_pkg_newdre.set_rentabcom(p_referencia, null, p_mensagem);
  
    if p_mensagem is not null then
      return;
    end if;
  
    v_msg := 'Valores da rentabilidade calculados!';
    ad_pkg_newdre.insereeventolog(p_referencia, v_msg, 0, p_mensagem);
  
    t := trunc((dbms_utility.get_time - i) / 100);
    dbms_output.put_line(v_msg || ' - ' || to_char(to_date(t, 'sssss'), 'hh24:mi:ss'));
  end;

  -- valores pad
  begin
    i := dbms_utility.get_time;
  
    ad_pkg_newdre.set_resindpad(p_referencia, null, p_mensagem);
  
    if p_mensagem is not null then
      return;
    end if;
  
    v_msg := 'Indicadores padrões calculados!';
    ad_pkg_newdre.insereeventolog(p_referencia, v_msg, 0, p_mensagem);
  
    t := trunc((dbms_utility.get_time - i) / 100);
    dbms_output.put_line(v_msg || ' - ' || to_char(to_date(t, 'sssss'), 'hh24:mi:ss'));
  end;

exception
  when others then
    p_mensagem := 'Erro na execução da Rotina calculo do período. ' || sqlerrm;
end;
/
