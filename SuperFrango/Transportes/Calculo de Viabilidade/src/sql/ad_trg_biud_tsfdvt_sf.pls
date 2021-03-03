create or replace trigger ad_trg_biud_tsfdvt_sf
  before insert or update or delete on ad_tsfdvt
  for each row
declare
  v_nomecampo   varchar2(100);
  v_newvlrdesp  float;
  v_oldvlrdesp  float;
  v_newvlrchar  varchar2(10);
  v_oldvlrchar  varchar2(10);
  v_codcat      number;
  v_codreg      number;
  v_dtref       date;
  despvei       ad_tsfcdv%rowtype;
  v_form        varchar2(4000);
  stmt          varchar2(4000);
  busca_formula boolean;
begin

  /*
  * Autor: Marcus Rangel
  * Processo: Viabilidade de Veículos
  * Objetivo: Atualizar a tabela master e provocar a atualização dos campos de soma
  */

  if stp_get_atualizando then
    return;
  end if;

  begin
    select *
      into despvei
      from ad_tsfcdv d
     where d.coddespvei = nvl(:new.coddespvei, :old.coddespvei);
  exception
    when no_data_found then
      null;
  end;

  if :new.tipodesp = 'F' or :old.tipodesp = 'F' then
    v_nomecampo  := 'VLRCUSTOFIXO';
    v_newvlrdesp := :new.vlrdespfixa;
    v_oldvlrdesp := :old.vlrdespfixa;
  else
    v_nomecampo  := 'VLRCUSTOVAR';
    v_newvlrdesp := :new.vlrdespvar;
    v_oldvlrdesp := :old.vlrdespvar;
  end if;

  if inserting or updating then
    if :new.tipodesp = 'F' and nvl(:new.vlrdespvar, 0) > 0 then
      raise_application_error(-20105,
                              ad_fnc_formataerro('Se o tipo da despesa é <b>Fixa</b>,' ||
                                                  ' não poderá ter o valor variável preenchido.'));
    end if;
  
    if :new.tipodesp = 'V' and nvl(:new.vlrdespfixa, 0) > 0 then
      raise_application_error(-20105,
                              ad_fnc_formataerro('Se o tipo da despesa é <b>Variável</b>,' ||
                                                  ' não poderá ter o valor fixo preenchido.'));
    end if;
  
    if :new.vlrdespfixa > 0 and :new.vlrdespvar > 0 then
      raise_application_error(-20105,
                              ad_fnc_formataerro('Informe apenas um valor para a despesa,' ||
                                                  ' a mesma não pode ser fixa e variável ao mesmo tempo.'));
    end if;
  
    if :new.tipodesp <> :old.tipodesp then
      raise_application_error(-20105,
                              ad_fnc_formataerro('Por favor exclua o lançamento e lançe novamente com o tipo de despesa correto'));
    end if;
  
    -- busca a categoria e a região do cabeçalho
  
    begin
      select v.codregfre, v.codcat, v.dtref
        into v_codreg, v_codcat, v_dtref
        from ad_tsfvvt v
       where v.numvvt = :new.numvvt;
    
    exception
      when others then
        raise_application_error(-20105, ad_fnc_formataerro(sqlerrm));
    end;
  
    -- busca a formula para o calculo do valor da despesa variável
    -- a busca pesquisa inicialmente as exceções registradas no
    -- cadastro de regiões de frete (ad_tsfrc), se nada for encontrado
    -- a busca é feita na tabela do cadastro de despesas obtendo a fórmula
    -- padrão para a despesa
  
    if nvl(despvei.manual, 'N') = 'N' then
      busca_formula := true;
    elsif nvl(despvei.manual, 'N') = 'S' and nvl(v_newvlrdesp, 0) = 0 then
      busca_formula := true;
    elsif nvl(despvei.manual, 'N') = 'S' and nvl(v_newvlrdesp, 0) > 0 then
      busca_formula := false;
    end if;
  
    if busca_formula then
      begin
        select replace(d.formula, ',', '.'), nvl(d.imposto, 'N')
          into v_form, despvei.imposto
          from ad_tsfrfc c
          join ad_tsfrfr r
            on r.codregfre = c.codregfre
          join ad_tsfrfd d
            on d.codregfre = c.codregfre
           and d.nurfr = r.nurfr
         where c.codregfre = v_codreg
           and r.codcat = v_codcat
           and d.coddespvei = :new.coddespvei
           and (r.dtvigor = (select max(dtvigor)
                               from ad_tsfrfr r2
                              where r2.codregfre = r.codregfre
                                and r2.codcat = r.codcat
                                and r2.dtvigor < sysdate) or r.dtvigor = v_dtref);
      
      exception
        when no_data_found then
          select replace(formula, ',', '.'), nvl(imposto, 'N')
            into v_form, despvei.imposto
            from ad_tsfcdv c
           where c.coddespvei = :new.coddespvei;
        when too_many_rows then
          select replace(d.formula, ',', '.'), nvl(d.imposto, 'N')
            into v_form, despvei.imposto
            from ad_tsfrfc c
            join ad_tsfrfr r
              on r.codregfre = c.codregfre
            join ad_tsfrfd d
              on d.codregfre = c.codregfre
             and d.nurfr = r.nurfr
           where c.codregfre = v_codreg
             and r.codcat = v_codcat
             and d.coddespvei = :new.coddespvei
             and (r.dtvigor = (select max(dtvigor)
                                 from ad_tsfrfr r2
                                where r2.codregfre = r.codregfre
                                  and r2.codcat = r.codcat
                                  and r2.dtvigor < sysdate) or r.dtvigor = v_dtref)
             and rownum = 1;
        when others then
          raise_application_error(-20105, ad_fnc_formataerro(sqlerrm));
      end;
    
    end if;
  
  end if;

  /*
  Begin
    Select Replace(formula, ',', '.'), Nvl(imposto, 'N')
      Into v_form, despvei.imposto
      From ad_tsfcdv c
     Where c.coddespvei = :New.Coddespvei;
  Exception
    When Others Then
      Null;
  End;
  */

  /* Atualiza os totais na master table */
  -- só atualiza o valor do campo com o da fórmula ou o da região se o valor for nulo ou zero
  --If inserting then
  if inserting then
    begin
    
      if v_form is not null then
        stmt := 'select round(' || v_form || ',2) from ad_tsfvvt where numvvt = :numvvt';
        execute immediate stmt
          into v_newvlrdesp
          using :new.numvvt;
        v_newvlrchar := replace(to_char(v_newvlrdesp), ',', '.');
      else
        v_newvlrchar := replace(to_char(v_newvlrdesp), ',', '.');
      end if;
    
      stmt := 'Update AD_TSFVVT V ' || 'SET ' || v_nomecampo || ' = ' || v_nomecampo || ' + ' || v_newvlrchar || ', ' ||
              'VLRTOTCUSTO = VLRTOTCUSTO + ' || v_newvlrchar || ', ' || 'VLRCUSTOTEMP = VLRCUSTOTEMP + ' ||
              'CASE WHEN ''S'' = ''' || nvl(despvei.imposto, 'N') || '''' || ' then 0 ELSE ' || v_newvlrchar || ' END ' ||
              'WHERE V.NUMVVT = :numvvt';
    
      execute immediate stmt
        using :new.numvvt;
    
    exception
      when others then
        raise_application_error(-20105,
                                'Erro ao executar a consulta com a fórmula da despesa (' || :new.numvvt || '). <br>' ||
                                 sqlerrm);
    end;
  elsif updating then
    begin
      if v_form is not null then
        stmt := 'select round(' || v_form || ',2) from ad_tsfvvt where numvvt = :numvvt';
        execute immediate stmt
          into v_newvlrdesp
          using :new.numvvt;
        v_newvlrchar := replace(to_char(v_newvlrdesp), ',', '.');
        v_oldvlrchar := replace(to_char(v_oldvlrdesp), ',', '.');
      else
        v_newvlrchar := replace(to_char(v_newvlrdesp), ',', '.');
        v_oldvlrchar := replace(to_char(v_oldvlrdesp), ',', '.');
      end if;
    
      stmt := 'UPDATE AD_TSFVVT V ' || 'SET ' || v_nomecampo || ' = ' || v_nomecampo || ' + ' || v_newvlrchar || ' - ' ||
              v_oldvlrchar || ' , VLRTOTCUSTO = VLRTOTCUSTO + ' || v_newvlrchar || ' - ' || v_oldvlrchar || ' , ' ||
              'VLRCUSTOTEMP = VLRCUSTOTEMP + CASE WHEN ''S'' <> ''' || nvl(despvei.imposto, 'N') || ''' THEN ' ||
              v_newvlrchar || ' - ' || v_oldvlrchar || ' ELSE 0 END WHERE V.NUMVVT = :numvvt';
    
      execute immediate stmt
        using :new.numvvt;
    exception
      when others then
        raise;
    end;
  elsif deleting then
    begin
      v_oldvlrchar := replace(to_char(v_oldvlrdesp), ',', '.');
      stmt         := 'Update AD_TSFVVT V ' || 'SET ' || v_nomecampo || ' = ' || v_nomecampo || ' - ' || v_oldvlrchar || ', ' ||
                      'VLRTOTCUSTO = VLRTOTCUSTO - ' || v_oldvlrchar || ', ' || 'VLRCUSTOTEMP = VLRCUSTOTEMP - ' ||
                      'CASE WHEN ''S'' = ''' || nvl(despvei.imposto, 'N') || '''' || ' THEN 0 ELSE ' || v_oldvlrchar ||
                      ' END ' || 'WHERE V.NUMVVT = :numvvt';
    
      execute immediate stmt
        using :old.numvvt;
    exception
      when others then
        raise;
    end;
  end if;

  if inserting or updating then
    if :new.tipodesp = 'F' then
      :new.vlrdespfixa := v_newvlrdesp;
    else
      :new.vlrdespvar := v_newvlrdesp;
    end if;
  end if;

  begin
    update ad_tsfvvt
       set codusu  = stp_get_codusulogado(),
           dhalter = sysdate
     where numvvt = nvl(:new.numvvt, :old.numvvt);
  
  exception
    when others then
      raise;
  end;

end;
/
