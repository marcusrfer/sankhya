create or replace package ad_pkg_newdre authid current_user is

  /****************************************************************************
  autor: marcus rangel
  processo: dre
  objetivo: conter todos os m�todos utilizados na gera��o,calculo e obten��o de
  valores da dre.
  *****************************************************************************/
  v_sufixo   varchar2(6);
  v_nometab  varchar2(100);
  v_count    pls_integer;
  errm       varchar2(4000);
  stmt       clob;
  init_time  number;
  end_time   number;
  total_time number;

  --> m�todos auxiliares <--

  -- calcula o frete e peso do cross dock
  procedure aux_set_fretepesocross(p_referencia date, p_errmsg out nocopy varchar2);

  -- valida formulas de exce��es
  procedure aux_valida_excformulas(p_msg out nocopy varchar2);

  --> m�todos de retornos <--

  function get_qtdtotal(p_referencia date, p_codemp number) return float deterministic;

  function get_qtdtotal(p_referencia date,
                        p_codemp     int,
                        p_codune     int,
                        p_coduf      int,
                        p_codprod    number) return float deterministic;

  function get_resindpad(p_referencia date,
                         p_codindpad  number,
                         p_codprod    number,
                         p_codemp     number,
                         p_codune     number,
                         p_coduf      int) return float;

  function get_resindger(p_referencia date,
                         p_codind     int,
                         p_codemp     number,
                         p_codune     number,
                         p_coduf      number) return float deterministic;

  function get_vlrdescfin(p_referencia date,
                          p_codemp     number,
                          p_codune     number,
                          p_coduf      number,
                          p_codprod    number) return float deterministic;

  function get_vlrcusto_dre(p_referencia date, p_codprod number, p_codemp number, p_tipo char)
    return float;

  function get_vlrcusto_dre(p_referencia date, p_codprod number, p_codemp int) return float
    deterministic;

  -- cria as tabelas
  procedure cria_tabelabase(p_tipo pls_integer, p_mensagem out nocopy varchar2);

  /* preenchimento de dados necess�rios para o calculo */
  procedure set_baseindpad(p_referencia date, p_mensagem out nocopy varchar2);

  procedure set_basedesccom(p_referencia date);

  procedure set_basecusto(p_referencia date, p_mensagem out nocopy varchar2);

  procedure set_baseindger(p_referencia date, p_mensagem out nocopy varchar2);

  /* calculos dos indicadores */

  procedure set_resindger(p_referencia date, p_codindger number, p_mensagem out nocopy varchar2);

  procedure set_rentabcom(p_referencia date, p_codindpad int default null);

  procedure set_resindpad(p_referencia date, p_codindpad pls_integer default null);

  procedure get_relacionamento_indpad(p_codind number, p_array out nocopy ad_type_of_number);

  procedure executeagendamento;

end ad_pkg_newdre;
/
create or replace package body ad_pkg_newdre is

  /* rotina que grava log de opera��o */
  procedure insereeventolog(p_referencia date, p_evento varchar2, p_status char, p_errmsg clob) is
  begin
    -- status, 1 para sucesso, -1 para falha
    insert into dre_logeventos
      (dtref, evento, dhevento, status, errmsg)
    values
      (p_referencia, p_evento, sysdate, p_status, p_errmsg);
  end insereeventolog;

  /* envia o valor do frete calculado e o peso total por cidade da vgfcross */
  procedure aux_set_fretepesocross(p_referencia date, p_errmsg out nocopy varchar2) is
  
    type type_rec_cidcross is record(
      id     rowid,
      codcid number);
  
    type type_tab_cidcross is table of type_rec_cidcross;
  
    t type_tab_cidcross := type_tab_cidcross();
  
    c vgfcross%rowtype;
  
    c_cid sys_refcursor;
  
  begin
    v_sufixo := to_char(p_referencia, 'YYYYMM');
  
    stmt := 'Select Rowid,  ' || 'Case When cidcross > 0 Then cidcross Else ' ||
            'Case When codemp <> 1 And vlrtrx > 0 Then ' ||
            'ad_get.Codcidparcemp(codemp,''E'') End ' || 'End From dre_baseindpad ' ||
            'Where dtref = :dtref ' || ' and Case When cidcross > 0 Then cidcross ' ||
            'Else Case When codemp <> 1 And vlrtrx > 0 Then ' ||
            ' ad_get.Codcidparcemp(codemp,''E'') End ' || 'End = :codcid';
  
    for c in (select * from vgfcross where referencia = p_referencia)
    loop
    
      open c_cid for stmt
        using p_referencia, c.codcid;
      fetch c_cid bulk collect
        into t;
      close c_cid;
    
      begin
        forall z in t.first .. t.last save exceptions
          update dre_baseindpad
             set vlrfretecross = c.frete,
                 pesocross     = c.peso,
                 cidcross      = case
                                   when cidcross > 0 then
                                    cidcross
                                   else
                                    case
                                      when codemp <> 1 and vlrtrx > 0 then
                                       ad_get.codcidparcemp(codemp, 'E')
                                    end
                                 end
           where dtref = p_referencia
             and case
                   when cidcross > 0 then
                    cidcross
                   else
                    case
                      when codemp <> 1 and vlrtrx > 0 then
                       ad_get.codcidparcemp(codemp, 'E')
                    end
                 end = t(z).codcid
             and rowid = t(z).id;
      exception
        when others then
          for e in 1 .. sql%bulk_exceptions.count
          loop
            p_errmsg := p_errmsg || chr(13) || sql%bulk_exceptions(e).error_index || ': ' || sql%bulk_exceptions(e).error_code;
          end loop;
          raise_application_error(-20105, p_errmsg);
      end;
    
    end loop c;
  
  end aux_set_fretepesocross;

  procedure get_relacionamento_indpad(p_codind number, p_array out nocopy ad_type_of_number) is
    v_newind  number;
    v_oldind  number;
    v_formula varchar2(4000);
    t1        ad_type_of_number := ad_type_of_number();
    t2        ad_type_of_number := ad_type_of_number();
    t3        ad_type_of_number := ad_type_of_number();
    x         int;
  
    v_newabv dre_cadindpad.abrev%type;
    v_oldabv dre_cadindpad.abrev%type;
  begin
    --p_codind := 7;
    p_array  := ad_type_of_number();
    v_newind := p_codind;
  
    while v_newind > 0
    loop
    
      -- executa para o indicador
      --dbms_output.put_line(v_newind);
      select abrev
        into v_newabv
        from dre_cadindpad
       where ativo = 'S'
         and codindpad = v_newind;
    
      t1.extend;
      x := t1.last;
      t1(x) := v_newind;
    
      -- busca dependentes
      begin
        select f.codindpad
          into v_newind
          from dre_forindpad f
          join dre_cadindpad c
            on c.codindpad = f.codindpad
         where c.ativo = 'S'
           and c.totalizador = 'S'
              --and nvl(f.ignorar, 'N') = 'N'
           and upper(formindpad) like '%' || upper(v_newabv) || '%'
           and f.dhvigor = (select max(f2.dhvigor)
                              from dre_forindpad f2
                             where f2.codindpad = f.codindpad
                            --and nvl(f2.ignorar, 'N') = 'N'
                            )
         order by f.codindpad;
      exception
        when no_data_found then
          v_newind := 0;
        when too_many_rows then
          for dep in (select rownum, f.codindpad
                        from dre_forindpad f
                        join dre_cadindpad c
                          on c.codindpad = f.codindpad
                       where c.ativo = 'S'
                         and c.totalizador = 'S'
                            --and nvl(f.ignorar, 'N') = 'N'
                         and upper(formindpad) like '%' || upper(v_newabv) || '%'
                         and f.dhvigor = (select max(f2.dhvigor)
                                            from dre_forindpad f2
                                           where f2.codindpad = f.codindpad
                                          --and nvl(f2.ignorar, 'N') = 'N'
                                          )
                       order by f.codindpad)
          loop
            if dep.rownum > 1 then
              t2.extend;
              x := t2.last;
              t2(x) := dep.codindpad;
            end if;
          end loop;
          continue;
      end;
      v_oldind := v_newind;
      v_oldabv := v_newabv;
    end loop;
  
    --- tratativa para duplicados e j� calculados na mesma runtime
    if t2 submultiset of t1 then
      t3 := t1;
    else
      t3 := t1 multiset union distinct t2;
    end if;
  
    -- verifica as f�rmulas dos totalizadores, verificando relacionamento entre eles
    for i in t3.first .. t3.last
    loop
      select abrev into v_newabv from dre_cadindpad where codindpad = t3(i);
      v_newind := case
                    when i > 1 then
                     t3(i - 1)
                    else
                     t3(i)
                  end;
    
      --dbms_output.put_line(t3(i));
      p_array.extend;
      x := p_array.last;
      p_array(x) := t3(i);
    
    end loop;
  
    /*for l in  p_array.first .. p_array.last
    loop
       dbms_output.put_line( 'ind: ' || p_array(l)); 
    end loop;*/
  
  end get_relacionamento_indpad;

  /* fun��o que retorna quantidade total negociada */
  function get_qtdtotal(p_referencia date, p_codemp number) return float deterministic is
    v_qtdtotal float;
  begin
    execute immediate 'Select sum(Qtdneg)-sum(qtddev) from dre_baseindpad where codemp = :codemp and dtref = :dtref'
      into v_qtdtotal
      using p_codemp, p_referencia;
  
    return v_qtdtotal;
  
  exception
    when others then
      return 0;
  end get_qtdtotal;

  function get_qtdtotal(p_referencia date,
                        p_codemp     int,
                        p_codune     int,
                        p_coduf      int,
                        p_codprod    number) return float deterministic is
    v_result float;
    stmt     varchar2(4000);
  begin
  
    stmt := 'Select sum(qtdneg-qtddev) from dre_baseindpad where dtref = :dtref ' ||
            ' and codemp = :emp  and codune = :une and coduf = :uf  and codprod = :prod';
  
    execute immediate stmt
      into v_result
      using p_referencia, p_codemp, p_codune, p_coduf, p_codprod;
  
    return v_result;
  
  end get_qtdtotal;

  -- Busca os valores dos descontos pagos no per�odo
  function get_vlrdescfin(p_referencia date,
                          p_codemp     number,
                          p_codune     number,
                          p_coduf      number,
                          p_codprod    number) return float deterministic is
    stmt      varchar2(4000);
    v_vlrdesc float;
    v_sufixo  varchar2(6);
  begin
    v_sufixo := to_char(p_referencia, 'YYYYMM');
    stmt     := 'Select sum(vlrdesc) From dre_basevlrdesc  
                 Where dtref = :dtref 
                  and codemp = :codemp
                  And codune = :codune
                  And coduf = :coduf
                  And codprod = :codoprod';
    begin
      execute immediate stmt
        into v_vlrdesc
        using p_referencia, p_codemp, p_codune, p_coduf, p_codprod;
    exception
      when no_data_found then
        v_vlrdesc := 0;
      when others then
        v_vlrdesc := 0;
    end;
  
    return v_vlrdesc;
  
  end get_vlrdescfin;

  /* fun��o que retorna valor da base de custo */
  function get_vlrcusto_dre(p_referencia date, p_codprod number, p_codemp number, p_tipo char)
    return float is
    p_dataini      date;
    p_datafin      date;
    vlr_custo_oper float := 0;
    vlr_custo      float := 0;
  
    stmt        varchar2(4000);
    v_tipo      varchar2(100);
    v_tipocusto number;
  begin
    p_dataini := trunc(p_referencia, 'mm');
    p_datafin := last_day(p_referencia);
  
    if p_tipo = 'G' then
      v_tipo      := 'cus.cusger';
      v_tipocusto := 1;
    else
      v_tipo      := 'cus.cussemicm';
      v_tipocusto := 3;
    end if;
  
    stmt := 'Select fc_divide(Sum(i.qtdneg * ' || v_tipo ||
            '), Nvl(Sum(i.qtdneg), 1))
        From tgfite i, tgfcab c, tgfcus cus
       Where i.nunota = c.nunota
         And c.dtneg >= :dataini
         And c.dtneg <= :datafin
         And c.tipmov = ''F''
         And c.codtipoper <> 812
         And i.codprod = :CodProd
         And cus.dtatual = c.dtneg
         And cus.codprod = i.codprod
         And (cus.codemp = :Codemp Or cus.codemp = 1)
         And cus.codlocal in (1100,2100, 2200, 2300,2500)';
  
    execute immediate stmt
      into vlr_custo_oper
      using p_dataini, p_datafin, p_codprod, p_codemp;
  
    if vlr_custo_oper <> 0 then
      vlr_custo := vlr_custo_oper;
    else
      vlr_custo := ad_get.custo_produto(p_codprod, 1, 1100, p_datafin, v_tipocusto);
    end if;
  
    return nvl(vlr_custo, 0);
  exception
    when others then
      dbms_output.put_line(sqlerrm);
      return 0;
  end get_vlrcusto_dre;

  function get_vlrcusto_dre(p_referencia date, p_codprod number, p_codemp int) return float
    deterministic is
    vlr_custo_oper float := 0;
    vlr_custo      float := 0;
    stmt           varchar2(4000);
  
  begin
  
    stmt := q'[Select vlrcusto from DRE_BASECUSTO where dtref = :dtref and codprod = :codprod]';
  
    execute immediate stmt
      into vlr_custo_oper
      using p_referencia, p_codprod;
  
    /*if vlr_custo_oper <> 0 then
      vlr_custo := vlr_custo_oper;
    else
      vlr_custo := ad_get.custo_produto(p_codprod, 1, 1100, last_day(p_referencia), 1);
    end if;*/
  
    return nvl(vlr_custo_oper, 0);
  
  exception
    when others then
      --Dbms_Output.Put_Line(p_codprod || ' - '||p_codemp || ' - '|| Sqlerrm);
      return 0;
  end get_vlrcusto_dre;

  /* fun��o que retorna os valores de indicadores gerenciais */
  function get_resindger(p_referencia date,
                         p_codind     int,
                         p_codemp     number,
                         p_codune     number,
                         p_coduf      number) return float deterministic is
    v_valorind float;
  begin
  
    select ri.vlrindger
      into v_valorind
      from dre_resindger ri
      left join dre_forindger fi
        on ri.codindger = fi.codindger
       and ri.codforger = fi.codforger
     where ri.codindger = p_codind
       and ri.dtref = p_referencia
       and nvl(ri.codemp, 0) = nvl(p_codemp, 0)
       and nvl(ri.codune, 0) = nvl(p_codune, 0)
       and nvl(ri.coduf, 0) = case
             when fi.coduf = 0 then
              0
             else
              nvl(p_coduf, 0)
           end;
  
    return round(v_valorind, 4);
  
  exception
    when no_data_found then
      return 0;
    when others then
      return 0;
  end get_resindger;

  /* fun��o que retorna valores de indicadores padr�es */
  function get_resindpad(p_referencia date,
                         p_codindpad  number,
                         p_codprod    number,
                         p_codemp     number,
                         p_codune     number,
                         p_coduf      int) return float is
    v_vlrindpad float;
    pragma autonomous_transaction;
  begin
    select p.vlrindpad
      into v_vlrindpad
      from dre_resindpad p
     where p.dtref = p_referencia
       and p.codindpad = p_codindpad
       and (nvl(codprod, 0) = nvl(p_codprod, 0) or nvl(p.codprod, 0) = 0)
       and (nvl(p.codemp, 0) = nvl(p_codemp, 0) or nvl(p.codemp, 0) = 0)
       and (nvl(p.codune, 0) = nvl(p_codune, 0) or nvl(p.codune, 0) = 0)
       and (nvl(p.coduf, 0) = nvl(p_coduf, 0) or nvl(p.coduf, 0) = 0);
  
    return nvl(v_vlrindpad, 0);
  
  exception
    when others then
      return 0;
  end get_resindpad;

  procedure cria_tabelabase(p_tipo pls_integer, p_mensagem out nocopy varchar2) is
  begin
  
    if p_tipo = 1 then
      v_nometab := 'DRE_BASEINDPAD';
    
      select f.query
        into stmt
        from dre_formulas f
       where f.tipoind = 'P'
         and base = 'S';
    
    else
    
      v_nometab := 'DRE_BASEINDGER';
    
      select f.query
        into stmt
        from dre_formulas f
       where f.tipoind = 'G'
         and base = 'S'
         and rownum = 1
       order by f.codform;
    
    end if;
  
    stmt := replace(upper(stmt), ':REFERENCIA', '''01/01/1900''');
    stmt := 'create table  ' || v_nometab || ' as ' || chr(13) || stmt || ' and 1 = 0';
  
    begin
      execute immediate stmt;
    exception
      when others then
        raise_application_error(-20105, sqlerrm);
    end;
  
    /*
    todo: owner="marcus.rangel" category="implementa��o" priority="alta" created="04/07/2019"
    text="criar mecanismo para cria��o dinamica dos indices"
    */
  
    p_mensagem := errm;
  
  end cria_tabelabase;

  procedure set_baseindpad(p_referencia date, p_mensagem out nocopy varchar2) is
    v_cur sys_refcursor;
  begin
  
    /*if periodofechado(p_referencia) then
      p_mensagem := 'Per�odo fechado! Altera��es n�o s�o mais permitidas';
      return;
    end if;*/
  
    v_nometab := 'DRE_BASEINDPAD';
  
    open v_cur for 'Select count(*) from dba_objects where object_name = :nometab and object_type = ''TABLE'''
      using v_nometab;
    fetch v_cur
      into v_count;
  
    if v_cur%notfound then
      cria_tabelabase(p_tipo => 1, p_mensagem => errm);
    end if;
  
    close v_cur;
  
    select f.query
      into stmt
      from dre_formulas f
     where f.tipoind = 'P'
       and base = 'S';
  
    for del in (select dtref from dre_baseindpad where dtref = p_referencia group by dtref)
    loop
      delete from dre_baseindpad where dtref = p_referencia;
    end loop;
  
    --stmt := replace(upper(stmt), ':REFERENCIA', '''' || p_referencia || '''');
    stmt := 'insert /*+ APPEND */ into ' || v_nometab || chr(13) || stmt;
  
    execute immediate stmt
      using p_referencia;
  
    commit;
  
    aux_set_fretepesocross(p_referencia, errm);
  
    dbms_stats.gather_table_stats(user, v_nometab);
  
    p_mensagem := errm;
  
  end set_baseindpad;

  procedure set_basedesccom(p_referencia date) is
  begin
  
    select count(*) into v_count from dre_basevlrdesc d where d.dtref = p_referencia;
    if (v_count > 0) then
      delete from dre_basevlrdesc d where dtref = p_referencia;
      commit;
    end if;
  
    select f.query into stmt from dre_formulas f where f.codform = 18;
  
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          --noformat start
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            stmt := q'[insert /*+ APPEND */ into DRE_BASEVLRDESC
Select 
  trunc(dhbaixa,'mm') dtref, 
  codemp, 
  codune, 
  codparc, 
  codvend, 
  codcencus, 
  coduf, 
  codprod, 
  Sum(vlrdesc) vlrdesc 
from ( SELECT * FROM AD_VW_BASEDESCFIN_SF ) 
 where trunc(dhbaixa,'mm') = :dtref
group by trunc(dhbaixa,'mm'),
  codemp, 
  codune,
  codparc, 
  codvend, 
  codcencus, 
  coduf, 
  codprod]';
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          --noformat end
  
    execute immediate stmt
      using p_referencia;
  
  end set_basedesccom;

  /* rotina que cria base de valores de custos */
  procedure set_basecusto(p_referencia date, p_mensagem out nocopy varchar2) is
  
    type rec_valores is record(
      dtref    date,
      codemp   number,
      codprod  number,
      vlrcusto float);
  
    type tab_valores is table of rec_valores;
  
    tv tab_valores := tab_valores();
  
    c sys_refcursor;
  
  begin
  
    open c for q'[select dtref,
           codemp,
           codprod,
           vlrcusto
      from(select trunc(dtatual, 'mm')dtref,
                  cus.codemp,
                  cus.codprod,
                  cus.codlocal,
                  snk_dividir(sum(i.qtdneg * cusger), sum(i.qtdneg))vlrcusto
           from tgfite i,
                tgfcab c,
                tgfcus cus
          where i.nunota = c.nunota
            and c.tipmov = 'F'
            and c.codtipoper <> 812
            and cus.dtatual = c.dtneg
            and cus.codprod = i.codprod
          group by trunc(dtatual, 'mm'),
                   cus.codemp,
                   cus.codprod,
                   codlocal
         Union All
         select trunc(dtatual, 'mm')dtref,
                c.codemp,
                c.codprod,
                c.codlocal,
                cusger
           from tgfcus c
           join dre_baseindpad ind
         on ind.dtref = trunc(c.dtatual, 'fmmm')
            and ind.codprod = c.codprod
          where c.dtatual =(select max(c2.dtatual)
                             from tgfcus c2
                            where trunc(c.dtatual, 'mm')= trunc(c2.dtatual, 'mm')
                              And c2.codprod = c.codprod
                              and c2.codemp = c.codemp
                              and c2.codlocal = c.codlocal)
    )t
     where t.dtref = :dtref
       and codemp = 1
       and codlocal in(1100, 2100, 2200, 2300, 2500)
     Group By dtref,codemp,codprod,codlocal,vlrcusto]'
      using p_referencia;
  
    fetch c bulk collect
      into tv;
    close c;
  
    begin
      delete from dre_basecusto where dtref = p_referencia;
    end;
  
    begin
      forall i in tv.first .. tv.last save exceptions
        insert into dre_basecusto values tv (i);
    exception
      when dup_val_on_index then
        null;
      when others then
        dbms_output.put_line('Updated ' || sql%rowcount || ' rows.');
      
    end;
  
    /*for i in tv.first .. tv.last
    loop
     insert into dre_basecusto values tv(i);
    end loop;*/
  
  exception
    when others then
      raise;
  end set_basecusto;

  procedure set_baseindger(p_referencia date, p_mensagem out nocopy varchar2) is
  begin
  
    for l in (select dtref from dre_baseindger where dtref = p_referencia group by dtref)
    loop
      delete from dre_baseindger where dtref = l.dtref;
      commit;
    end loop;
  
    for c_form in (select *
                     from dre_formulas f
                    where f.tipoind = 'G'
                      and base = 'S'
                    order by f.codform)
    loop
    
      v_nometab := 'DRE_BASEINDGER';
    
      stmt := 'insert /*+ APPEND */ into ' || v_nometab || chr(13) || c_form.query;
    
      dbms_output.put_line(stmt);
    
      execute immediate stmt
        using p_referencia;
    
      commit;
    
    end loop;
  
    dbms_stats.gather_table_stats(user, v_nometab);
  
  end set_baseindger;

  /* calcula e popula a tabela de valores dos indicadores gerenciais */
  procedure set_resindger(p_referencia date, p_codindger number, p_mensagem out nocopy varchar2) is
    rig dre_resindger%rowtype;
  
    type cursor_ind is ref cursor;
    ci cursor_ind;
  
  begin
  
    v_nometab := 'DRE_BASEINDGER';
  
    -- verifica exist�ncia de dados
    select count(*) into v_count from dre_baseindger where dtref = p_referencia;
  
    if v_count = 0 then
      p_mensagem := 'N�o possui base calculada para este per�odo.';
      return;
    end if;
  
    -- percorre cadastro de indicadores gerenciais
    for c_ind in (select g.codindger, g.descrindger, f.formindger, nvl(f.coduf, 0) coduf,
                         nvl(f.codune, 0) codune, nvl(f.codemp, 0) codemp, f.sigla, f.clacus,
                         f.clacuscont, f.codform, f.dhvigor, f.codforger
                    from dre_cadindger g
                    join dre_forindger f
                      on g.codindger = f.codindger
                   where f.formindger is not null
                     and nvl(g.ativo, 'N') = 'S'
                     and nvl(f.codform, 0) > 0
                     and (g.codindger = p_codindger or nvl(p_codindger, 0) = 0)
                     and f.dhvigor = (select max(dhvigor)
                                        from dre_forindger ff
                                       where ff.codindger = f.codindger
                                         and ff.codforger = f.codforger
                                         and nvl(ff.codform, 0) > 0
                                         and (trunc(ff.dhvigor, 'mm') = p_referencia or
                                             trunc(ff.dhvigor, 'mm') <= p_referencia)
                                         and ff.dhvigor <= sysdate)
                   order by g.codindger)
    loop
    
      -- busca query base com f�rmula
      begin
        select f.query into stmt from dre_formulas f where f.codform = c_ind.codform;
      exception
        when others then
          p_mensagem := 'Erro: Consulta base n�o encontrada no cadastro de f�rmulas. Indicador: ' ||
                        c_ind.codindger || ' | ' || chr(13) || sqlerrm;
          return;
      end;
    
      -- tratativas da f�rmula
      stmt := replace(stmt, ':FORMULA', c_ind.formindger);
      stmt := replace(stmt, ':NOMETABELA', v_nometab);
      stmt := replace(stmt, 'DRE_BASEINDPAD_:SUFIXO', 'DRE_BASEINDPAD');
    
      -- verifica a exist�ncia de dados
      select count(*)
        into v_count
        from dre_resindger
       where dtref = p_referencia
         and codindger = c_ind.codindger;
    
      -- exclus�o de dados existentes
      if v_count > 0 then
        begin
          delete from dre_resindger
           where codindger = c_ind.codindger
             and dtref = p_referencia;
        exception
          when others then
            raise;
        end;
      end if;
    
      if stmt is null then
        continue;
      end if;
    
      open ci for stmt
        using p_referencia, c_ind.codemp, c_ind.codune, c_ind.coduf, c_ind.clacus, c_ind.clacuscont;
      loop
        fetch ci
          into rig.codemp, rig.codune, rig.coduf, rig.vlrindger;
        exit when ci%notfound;
      
        --  popula tabela de valores (serializado, runtime medido, irrelevante)
        begin
          insert /*+ append */
          into dre_resindger
            (dtref, codindger, codemp, codune, coduf, vlrindger, codforger)
          values
            (p_referencia, c_ind.codindger, nvl(rig.codemp, 1), nvl(rig.codune, 1),
             nvl(rig.coduf, 9), nvl(rig.vlrindger, 0), c_ind.codforger);
        exception
          when others then
            continue;
        end;
      
      end loop;
    
      close ci;
    
    end loop c_ind;
  
  exception
    when others then
      raise_application_error(-20105, sqlerrm);
  end set_resindger;

  procedure set_rentabcom(p_referencia date, p_codindpad int) is
    i             int := 0;
    v_formula_ind clob;
    v_formula_all clob;
    v_query       clob;
    stmt          varchar2(32767);
    v_offset      number default 1;
    v_chunk_size  number := 32000;
  
    type rec_val_temp is record(
      dtref     date,
      nunota    number,
      sequencia number,
      valor     float);
  
    type tab_val_temp is table of rec_val_temp;
  
    t  tab_val_temp := tab_val_temp();
    c  sys_refcursor;
    it number;
    et number;
    tt number;
  begin
  
    -- verifica se existem lan�amentos na tab de rentab
    select count(*) into i from dre_rentabcom where dtref = p_referencia;
  
    --- se nula, preenche com os dados da base da dre
    if i = 0 then
      insert into dre_rentabcom
        (dtref, nunota, sequencia)
        select dtref, nunota, sequencia from dre_baseindpad where dtref = p_referencia;
    else
      null;
    end if;
  
    -- percorre os indicadores padr�es
    for l in (select dc.codindpad, fp.formindpad, dc.temexc, nvl(dc.totalizador, 'N') totalizador,
                     dc.abrev, nvl(fp.ignorar, 'N') ignorar
                from dre_cadindpad dc
                join dre_forindpad fp
                  on dc.codindpad = fp.codindpad
                join dre_estrutura de
                  on de.codindpad = dc.codindpad
               where nvl(dc.ativo, 'N') = 'S'
                 and fp.formindpad is not null
                 and (dc.codindpad = p_codindpad or nvl(p_codindpad, 0) = 0)
                 and fp.dhvigor = (select max(dhvigor)
                                     from dre_forindpad ff
                                    where ff.codindpad = fp.codindpad
                                      and ff.dhvigor <= sysdate)
               order by de.seqind)
    loop
    
      it            := sys.dbms_utility.get_time;
      v_formula_ind := null;
    
      -- se totalizador 
      if l.totalizador = 'S' then
      
        stmt := 'update dre_rentabcom' || ' set ' || l.abrev || ' = ' || l.formindpad ||
                ' Where dtref = :dtref';
      
        -- atualiza valor na dre_rentabcom
        execute immediate stmt
          using p_referencia;
        i := sql%rowcount;
      
        commit;
      
        --- se n�o � totalizador
      else
      
        --if nvl(l.ignorar, 'N') = 'N' then
        begin
          select count(*) into i from tmp_rentabcom;
        
          if i > 0 then
            t.delete;
            delete from tmp_rentabcom purge;
            commit;
          end if;
        exception
          when others then
            null;
        end;
      
        -- se tem exce��o
        if (l.temexc = 'S') then
          for txt in (select e.codindpad, p.abrev, e.dhvigor, codemp, codune, codgrupoprod, codprod,
                             coduf, e.codexc,
                             ' when (codemp = ' || e.codemp || ' or ' || e.codemp || ' = 0)' ||
                             chr(13) || ' and (codune = ' || e.codune || ' or ' || e.codune ||
                             ' = 0)' || chr(13) || ' and (codgrupoprod = ' || e.codgrupoprod ||
                             ' or ' || e.codgrupoprod || ' = 0 )' || chr(13) || ' and (codprod = ' ||
                             e.codprod || ' or ' || e.codprod || ' = 0)' || chr(13) ||
                             ' and (coduf = ' || e.coduf || ' or ' || e.coduf || ' = 0) then ' ||
                             chr(13) || case
                               when e.tipovlr = 'F' then
                                replace(e.formexc, 'SUM', '')
                               else
                                to_char(e.vlrperc)
                             end as formula
                        from dre_excecoes e
                        join dre_cadindpad p
                          on p.codindpad = e.codindpad
                       where nvl(e.ativo, 'N') = 'S'
                         and e.codindpad = l.codindpad
                         and e.dhvigor = (select max(dhvigor)
                                            from dre_excecoes ei
                                           where ei.codindpad = e.codindpad
                                             and nvl(ativo, 'N') = 'S'
                                             and ei.codemp = e.codemp
                                             and ei.codune = e.codune
                                             and ei.coduf = e.coduf
                                             and ei.codgrupoprod = e.codgrupoprod
                                             and ei.codprod = e.codprod)
                       order by e.codindpad)
          loop
          
            v_formula_ind := v_formula_ind || chr(13) || nvl(txt.formula, l.formindpad);
          
          end loop txt;
        
          if v_formula_ind is not null then
          
            v_formula_ind := ' case ' || v_formula_ind || ' else ' || l.formindpad || ' end as ' ||
                             l.abrev;
          
          else
            v_formula_ind := l.formindpad || ' as ' || l.abrev;
          end if;
        
        else
          v_formula_ind := replace(upper(l.formindpad), 'SUM(', '(') || ' as ' || l.abrev;
        end if;
        -- fim exce��o
      
        -- unindo todas as formulas em uma s�
        --- obsoleto
        /*if v_formula_all is null then
         v_formula_all := v_formula_ind;
        else
         v_formula_all := v_formula_all || ', ' || chr(13) || v_formula_ind;
        end if;*/
      
        v_formula_ind := replace(upper(v_formula_ind), 'SUM(', '(');
      
        v_query := 'Select ''' || p_referencia || ''' as dtref, nunota, sequencia,' ||
                   v_formula_ind || chr(13) || ' from DRE_BASEINDPAD where dtref = :dtref'
        --||' and codprod = 63368 and codemp = 1 and coduf = 5'
         ;
      
        -- popula a tabela temporaria que ser� usar para fazer o insert as
        -- na tabela de valores da rentabilidade
        begin
          open c for v_query
            using p_referencia;
        
          fetch c bulk collect
            into t;
        
          begin
            forall x in t.first .. t.last
              insert into tmp_rentabcom values t (x);
            i := sql%rowcount;
            commit;
          exception
            when others then
              raise;
          end;
        
          close c;
        
        end;
      
        -- merge que insere os dados na tabela da rentabilidade
        begin
          stmt := 'MERGE /*+ first_rows parallel(dre_rentabcom) parallel(tmp_rentabcom) */ INTO dre_rentabcom rtc
                    USING tmp_rentabcom tmp
                      ON (rtc.dtref = tmp.dtref and rtc.nunota = tmp.nunota and rtc.sequencia = tmp.sequencia)
                    WHEN MATCHED THEN UPDATE SET ' || l.abrev || ' = tmp.valor';
        
          execute immediate stmt;
        end;
      
        -- insere o log da opera��o para acompanhamento
        insereeventolog(p_referencia,
                        ' *** calculo do indicador - ' || l.codindpad || ' - ' ||
                        to_char(sysdate, 'HH24:MI:SS'),
                        1,
                        null);
      
        --end if; -- fim ignorar
      end if; ---fim totalizador 
    
      et := dbms_utility.get_time;
      tt := (et - it) / 100;
    
    end loop l;
  
  end set_rentabcom;

  procedure set_resindpad(p_referencia date, p_codindpad pls_integer default null) is
    stmt varchar2(32762);
    type tab_resindpad is table of dre_resindpad%rowtype;
    t tab_resindpad := tab_resindpad();
    i pls_integer;
  
    c sys_refcursor;
  
  begin
  
    for ind in (select dc.codindpad, dc.abrev
                  from dre_cadindpad dc
                  join dre_forindpad fp
                    on dc.codindpad = fp.codindpad
                  join dre_estrutura de
                    on de.codindpad = dc.codindpad
                 where nvl(dc.ativo, 'N') = 'S'
                      --and nvl(dc.totalizador, 'N') = 'S'
                   and fp.formindpad is not null
                   and (dc.codindpad = p_codindpad or nvl(p_codindpad, 0) = 0)
                      --and dc.codindpad not in ( 10 )
                   and fp.dhvigor = (select max(dhvigor)
                                       from dre_forindpad ff
                                      where ff.codindpad = fp.codindpad
                                        and ff.dhvigor <= sysdate)
                 order by de.seqind)
    loop
    
      if ind.codindpad = 45 then
        stmt := 'select ' || ind.codindpad ||
                ' as codindpad,DTREF,CODEMP,CODUNE,CODGRUPOPROD,CODPROD,CODUF,' ||
                ' sum( snk_dividir(r.resliqgeral , r.recliq)) * 100 ,0,0,0,sysdate' ||
                ' from ad_vw_rentabcom r ' || 'where r.dtref = :referencia ' ||
                'group by dtref, codemp, codune, codgrupoprod, codprod, coduf';
      else
        stmt := 'select ' || ind.codindpad ||
                ' as codindpad,DTREF,CODEMP,CODUNE,CODGRUPOPROD,CODPROD,CODUF,' || ind.abrev ||
                ',0,0,0,sysdate' || ' from ad_vw_rentabcom r ' || 'where r.dtref = :referencia';
      end if;
    
      open c for stmt
        using p_referencia;
      fetch c bulk collect
        into t;
      close c;
    
      begin
        delete from dre_resindpad r
         where dtref = p_referencia
           and (r.codindpad = p_codindpad or nvl(p_codindpad, 0) = 0);
      exception
        when others then
          raise;
      end;
    
      begin
        forall x in t.first .. t.last
          merge into dre_resindpad r
          using (select t(x).codindpad codindpad,t(x).dtref dtref,t(x).codemp codemp,
                        t(x).codune codune,t(x).codgrupoprod codgrupoprod,t(x).codprod codprod,
                        t(x).coduf coduf,t(x).vlrindpad vlrindpad,t(x).codforpad codforpad,
                        t(x).codexc codexc,t(x).dhinclusao dhinclusao
                   from dual) d
          on (r.codindpad = d.codindpad and r.dtref = d.dtref and r.codemp = d.codemp and r.codune = d.codune and r.codgrupoprod = d.codgrupoprod and d.codprod = r.codprod and r.coduf = d.coduf)
          when matched then
            update
               set vlrindpad  = d.vlrindpad,
                   codforpad  = d.codforpad,
                   codexc     = d.codexc,
                   dhinclusao = d.dhinclusao
          when not matched then
            insert values t (x);
      
      end;
    
      begin
        update dre_cadindpad p
           set p.dhultexec  = sysdate,
               p.statusexec = 'S'
         where p.codindpad = ind.codindpad;
      exception
        when others then
          raise;
      end;
    
      commit;
    
      insereeventolog(p_referencia,
                      ' *** Gravando Resultado do indicador ' || ind.codindpad,
                      1,
                      null);
    
      t.delete;
    
    end loop;
  
  end set_resindpad;

  procedure executeagendamento is
    p_referencia date;
    v_msg        varchar2(4000);
  begin
    insereeventolog(p_referencia, 'In�cio da execu��o agendada', 0, null);
    p_referencia := trunc(add_months(trunc(sysdate), -1), 'mm');
    ad_stp_dre_executeall_sf(p_referencia, v_msg);
  
  end executeagendamento;

  /*
    Autor: MARCUS.RANGEL 11/09/2019 10:25:30
    Objetivo: parsear as formulas das exce��es em busca de erros  
  */
  procedure aux_valida_excformulas(p_msg out nocopy varchar2) is
    stmt          varchar2(4000);
    v_formula_ind varchar2(4000);
    v_dtref       date := add_months(trunc(sysdate, 'fmmm'), -1);
    i             int;
    m             int := 2;
    c             sys_refcursor;
  begin
  
    for f in (select *
                from dre_excecoes e
               where e.ativo = 'S'
                 and e.tipovlr = 'F'
               order by e.codindpad, e.codexc)
    loop
    
      v_formula_ind := replace(upper(f.formexc), 'SUM', '');
    
      stmt := 'Select nunota, sequencia, ' || v_formula_ind || chr(13) ||
              ' from DRE_BASEINDPAD where dtref = :dtref';
    
      --possui lan�amentos?
      select count(*) into i from dre_baseindpad where dtref = v_dtref;
    
      -- retroaje um mes caso n�o tenha dados da table no time selecionado
      if i = 0 then
        while i = 0
        loop
          v_dtref := add_months(trunc(sysdate, 'fmmm'), -m);
          select count(*) into i from dre_baseindpad where dtref = v_dtref;
          m := m + 1;
        end loop;
      end if;
    
      begin
        open c for stmt
          using v_dtref;
        close c;
      exception
        when others then
          p_msg := ltrim(rtrim(p_msg) || chr(13) || f.codexc || '  - ' || sqlerrm);
          --dbms_output.put_line(f.codexc || '  - ' || sqlerrm);
          continue;
      end;
    end loop;
  
  end;

end ad_pkg_newdre;
/
