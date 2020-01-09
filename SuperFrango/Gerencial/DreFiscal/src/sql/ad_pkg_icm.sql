create or replace package ad_pkg_icm as

 v_stmt_param varchar2(32767);

 function get_vlrantecip_pamg(p_codemp number, p_codprod number, p_nuparam int, p_dhmov date) return float
 deterministic;

 function get_vlrantecip_ba(p_nunota number, p_sequencia number) return float deterministic;

 function get_vlrantecip_pa(p_codemp number, p_codprod number, p_dhmov date) return float deterministic;

 function get_param_fiscal(p_nurelparm number, p_data date, p_tipo varchar2) return float deterministic;

 function get_credout_pres_prot(v_dtref     date,
                                v_codemp    number,
                                v_nunota    number,
                                v_sequencia int,
                                v_imposto   varchar2,
                                v_origem    varchar2) return float deterministic;

 function get_vlrantecip(p_nunota number, p_sequencia int) return float deterministic;

 procedure set_base_antecipacao(p_dtref date);

 procedure set_base_credoutpres(p_dtref date);

 procedure exec_agendamento;

end ad_pkg_icm;
/
create or replace package body ad_pkg_icm as

 function get_param_fiscal(p_nurelparm number, p_data date, p_tipo varchar2) return float deterministic is
  vlr      ad_relparmaliq%rowtype;
  v_result float;
 
 begin
 
  /*
  * Autor: Thiago Batista / M. Rangel
  * Processo: Automação fiscal / DRE
  * Objetivo: Retornar os valores mais recentes da tela de parametrização fiscal
  */
 
  begin
  
   select --snk_dividir(a.aliq, 100), snk_dividir(a.aliqst, 100), snk_dividir(a.marglucro, 100),
    snk_dividir(a.percant, 100)
     into /*vlr.aliq, vlr.aliqst, vlr.marglucro, */ vlr.percant
     from ad_relparmaliq a
    where a.nurelparm = p_nurelparm
      and a.referencia <= p_data
      and rownum = 1
    order by a.referencia desc;
   /*(select max(aa.referencia)
    from ad_relparmaliq aa
   where aa.nurelparm = a.nurelparm
     and aa.referencia <= trunc(p_data,'fmmm'));*/
  
   if p_tipo = 'ALIQ' then
    v_result := vlr.aliq;
   elsif p_tipo = 'ALIQST' then
    v_result := vlr.aliqst;
   elsif p_tipo = 'MARGLUCRO' then
    v_result := vlr.marglucro;
   elsif p_tipo = 'PERCANT' then
    v_result := vlr.percant;
   else
    v_result := 0;
   end if;
  
  exception
   when others then
    v_result := 0;
  end;
 
  return(v_result);
 
 end get_param_fiscal;

 function get_vlrantecip_pamg(p_codemp number, p_codprod number, p_nuparam int, p_dhmov date) return float
 deterministic is
  v_result float;
 begin
 
  select (l.baseicms / i.qtdneg) *
          (select (r.percant / 100) from ad_relparmaliq r where r.nurelparm = p_nuparam)
    into v_result
    from tgfliv l
    join tgfite i
      on i.codemp = l.codemp
     and i.codemp = l.codemp
     and i.nunota = l.nunota
     and i.sequencia = l.sequencia
    join tgfpro p
      on p.codprod = i.codprod
    join ad_adrelparmgruicms g
      on g.grupoicms = p.grupoicms
   where 1 = 1
     and l.codcfo = 2152
     and i.codprod = p_codprod
     and i.codemp = p_codemp
     and l.dhmov <= p_dhmov
     and l.dhmov = (select max(l2.dhmov)
                      from tgfliv l2
                     where l2.codcfo = 2152
                       and l2.codemp = p_codemp
                       and l2.dhmov <= p_dhmov
                       and exists (select 1
                              from tgfite i2
                             where i2.nunota = l2.nunota
                               and i2.sequencia = l2.sequencia
                               and i2.codemp = l2.codemp
                               and i2.codprod = p_codprod))
     and rownum = 1;
 
  return v_result;
 exception
  when no_data_found then
   return 0;
 end get_vlrantecip_pamg;

 function get_vlrantecip_pa(p_codemp number, p_codprod number, p_dhmov date) return float deterministic is
  v_result float;
 begin
  select (a.percant / 100) * (l.baseicms / i.qtdneg) vlrantecip
  --snk_dividir(a.percant, 100) * snk_dividir(l.baseicms, i.qtdneg) vlrantecip
    into v_result
    from tgfliv l
    join tgfite i
      on (i.nunota = l.nunota and i.sequencia = l.sequencia)
    join tgfpro p
      on (p.codprod = i.codprod)
    join ad_adrelparmgruicms g
      on g.grupoicms = p.grupoicms
    join ad_relparmemp e
      on (e.nurelparm = g.nurelparm and e.codemp = l.codemp)
    join ad_relparmaliq a
      on a.nurelparm = g.nurelparm
   where 1 = 1
     and l.codemp = p_codemp
     and l.dhmov <= p_dhmov
     and l.codcfo = 2152
     and i.codprod = p_codprod
     and rownum = 1
   order by l.dhmov desc;
 
  return v_result;
 
 exception
  when no_data_found then
   return 0;
  when others then
   raise_application_error(-20105, 'Erro! ' || sqlerrm);
 end get_vlrantecip_pa;

 function get_vlrantecip_ba(p_nunota number, p_sequencia number) return float deterministic is
  v_result float;
 begin
 
  -- calcula antecipacao BA
  select snk_dividir(((t.basest * 0.18) - t.icmsnorm), t.qtdneg)
    into v_result
    from (with pauta as (select e.codprod, e.vlrvenda
                           from tgfexc e
                          where nutab = (select max(nutab) from tgftab where codtab = 30))
          select i.qtdneg,
                 i.qtdneg * case
                  when i.vlrunit > pt.vlrvenda then
                   i.vlrunit
                  else
                   pt.vlrvenda
                 end as baseicms,
                 (i.qtdneg * (case
                  when i.vlrunit > pt.vlrvenda then
                   i.vlrunit
                  else
                   pt.vlrvenda
                 end)) * 0.12 as icmsnorm,
                 (i.qtdneg * (case
                  when i.vlrunit > pt.vlrvenda then
                   i.vlrunit
                  else
                   pt.vlrvenda
                 end)) * 1.3415 as basest
            from tgfliv l
            join tgfite i
              on i.nunota = l.nunota
             and i.sequencia = l.sequencia
            join tgfpro p
              on p.codprod = i.codprod
            join pauta pt
              on pt.codprod = i.codprod
           where i.nunota = p_nunota
             and i.sequencia = p_sequencia
             and rownum = 1
           order by l.dhmov desc) t;
 
 
  return v_result;
 
 exception
  when no_data_found then
   return 0;
 end get_vlrantecip_ba;

 function get_credout_pres_prot(v_dtref     date,
                                v_codemp    number,
                                v_nunota    number,
                                v_sequencia int,
                                v_imposto   varchar2,
                                v_origem    varchar2) return float deterministic is
 
  v_credout  float;
  v_protege  float;
  v_credpres float;
  v_antecip  float;
 
 begin
  --v_imposto := 'CredOutVenda';
  --v_origem  := 'INT';
 
  -- Test statements here
  for c_notas in (select dtref, codemp, nunota, sequencia, codprod,
                         case
                          when qtdneg > 0 then
                           qtdneg
                          else
                           qtddev
                         end as qtdneg, coduf
                    from dre_baseindpad
                   where dtref = v_dtref
                     and codemp = v_codemp
                     and nunota = v_nunota
                     and sequencia = v_sequencia)
  loop
  
   if v_origem = 'VDA' then
   
    begin
     select snk_dividir(c.credito_outor, c_notas.qtdneg), snk_dividir(c.protege, c_notas.qtdneg)
       into v_credout, v_protege
       from ad_credoutprot9lxvi c
      where c.empresa = c_notas.codemp
        and c.nunota = c_notas.nunota
        and c.sequencia = c_notas.sequencia
        and c.referencia = c_notas.dtref
        and c.codcfo in (1201, 2201, 2208, 5101, 5910, 6101, 6107, 6401, 6910);
    exception
     when no_data_found then
      begin
       select snk_dividir(c.credito_outor, c_notas.qtdneg), snk_dividir(c.protege, c_notas.qtdneg)
         into v_credout, v_protege
         from ad_adcredoutprot9vi c
        where c.empresa = c_notas.codemp
          and c.nunota = c_notas.nunota
          and c.sequencia = c_notas.sequencia
          and c.referencia = c_notas.dtref
          and c.codcfo in (1201, 2201, 2208, 5101, 5910, 6101, 6107, 6401, 6910);
      exception
       when no_data_found then
        begin
         select snk_dividir(c.credito_outor, c_notas.qtdneg), snk_dividir(c.protege, c_notas.qtdneg)
           into v_credout, v_protege
           from ad_credoutprotpres3 c
          where c.empresa = c_notas.codemp
            and c.nunota = c_notas.nunota
            and c.sequencia = c_notas.sequencia
            and c.referencia = c_notas.dtref
            and c.codcfo in (1201, 2201, 2208, 5101, 5910, 6101, 6107, 6401, 6910);
        exception
         when no_data_found then
          if v_credout is null then
           v_credout := 0;
          end if;
          if v_protege is null then
           v_protege := 0;
          end if;
        end;
      end;
    end;
   
    begin
     select snk_dividir(c.credito_presumido, c_notas.qtdneg), snk_dividir(c.protege, c_notas.qtdneg)
       into v_credpres, v_protege
       from ad_credoutprotrb10 c
      where c.empresa = c_notas.codemp
        and c.nunota = c_notas.nunota
        and c.sequencia = c_notas.sequencia
        and c.referencia = c_notas.dtref
        and c.codcfo in (1201, 2201, 2208, 5101, 5910, 6101, 6107, 6401, 6910);
    exception
     when no_data_found then
      if v_credout is null then
       v_credout := 0;
      end if;
      if v_protege is null then
       v_protege := 0;
      end if;
    end;
   
    if upper(v_imposto) = 'CREDOUTVENDA' then
     return abs(v_credout);
    elsif upper(v_imposto) = 'CREDPRESUMIDO' then
     return abs(v_credpres);
    elsif upper(v_imposto) = 'PROTGOVENDA' then
     return abs(v_protege);
    end if;
   
   else
    -- transf
   
    begin
     select snk_dividir(c.credito_outor, c_notas.qtdneg), snk_dividir(c.protege, c_notas.qtdneg), 0
       into v_credout, v_protege, v_credpres
       from ad_credoutprot9lxvi c
      where c.empresa = c_notas.codemp
        and c.nunota = c_notas.nunota
        and c.sequencia = c_notas.sequencia
        and c.referencia = c_notas.dtref
        and c.codcfo in (5151, 5152, 6151, 6152);
    exception
     when no_data_found then
      begin
       select snk_dividir(c.credito_outor, c_notas.qtdneg), snk_dividir(c.protege, c_notas.qtdneg), 0
         into v_credout, v_protege, v_credpres
         from ad_adcredoutprot9vi c
        where c.empresa = c_notas.codemp
          and c.nunota = c_notas.nunota
          and c.sequencia = c_notas.sequencia
          and c.referencia = c_notas.dtref
          and c.codcfo in (5151, 5152, 6151, 6152);
      exception
       when no_data_found then
        begin
         select snk_dividir(c.credito_outor, c_notas.qtdneg), snk_dividir(c.protege, c_notas.qtdneg), 0
           into v_credout, v_protege, v_credpres
           from ad_credoutprotpres3 c
          where c.empresa = c_notas.codemp
            and c.nunota = c_notas.nunota
            and c.sequencia = c_notas.sequencia
            and c.referencia = c_notas.dtref
            and c.codcfo in (5151, 5152, 6151, 6152);
        exception
         when no_data_found then
          if v_credpres is null then
           v_credpres := 0;
          end if;
          if v_protege is null then
           v_protege := 0;
          end if;
          if v_credout is null then
           v_credout := 0;
          end if;
         
        end;
      end;
    end;
   
    if v_imposto = 'CREDOUTTRANSF' then
     return v_credout;
    elsif v_imposto = 'CREDPRESUMIDO' then
     return v_credpres;
    elsif v_imposto = 'PROTGOTRANS' then
     return v_protege;
    end if;
   
   end if;
  
  end loop;
 
 end get_credout_pres_prot;

 function get_vlrantecip(p_nunota number, p_sequencia int) return float deterministic is
  v_vlrantecip float;
 begin
  select a.vlrantecip
    into v_vlrantecip
    from ad_antecipicm a
   where a.nunota = p_nunota
     and a.sequencia = p_sequencia;
 
  return v_vlrantecip;
 exception
  when no_data_found then
   return 0;
 end get_vlrantecip;

 --pupula base antecipação
 -- Created on 27/09/2019 by MARCUS.RANGEL 
 procedure set_base_antecipacao(p_dtref date) is
 
  type rec_livro is record(
   dtref     date,
   codemp    int,
   nunota    number,
   sequencia int,
   dhmov     date,
   dtdoc     date,
   coduf     int,
   uforigem  varchar2(2),
   ufdestino varchar2(2),
   codcfo    number,
   vlrctb    float,
   baseicms  float,
   aliqicms  float,
   vlricms   float);
 
  type tab_livro is table of rec_livro;
  livro tab_livro := tab_livro();
 
  type dados_antecipacao is table of ad_antecipicm%rowtype;
  icm    dados_antecipacao := dados_antecipacao();
  i      integer;
  v_rows int := 0;
 
  it number;
  et number;
 
 begin
 
  -- before each row
  declare
  begin
  
   delete from ad_antecipicm where dtref = p_dtref;
  
   -- simula o insert
   select trunc(liv.dhmov, 'fmmm'), liv.codemp, liv.nunota, liv.sequencia, liv. dhmov, dtdoc,
          ad_get.ufparcemp(liv.codemp, 'E'), liv.uforigem, liv.ufdestino, liv.codcfo, liv.vlrctb, liv.baseicms,
          liv.aliqicms, liv.vlricms
     bulk collect
     into livro
     from tgfliv liv
    where liv.dhmov >= p_dtref
      and liv.dhmov <= last_day(p_dtref)
      and liv.entsai = 'S'
      and liv.origem = 'E'
      and ((liv.uforigem = 'GO' and liv.ufdestino = 'BA') or (liv.uforigem = 'PA' and liv.ufdestino = 'PA') or
          (liv.uforigem = 'MG' and liv.ufdestino = 'MG'));
  
  end;
  -- end before each row
 
  -- after statement
  declare
   v_vlrantecip float;
  begin
   if livro.count > 0 then
    for x in livro.first .. livro.last
    loop
    
     -- filtro, passa os registros do insert nessa "peneira" para verificar os que
     -- possuem restrição por grupo de icms informado em "parametros de relatorios"
     -- visa unificar o atendimento aos cenários que utilizam restrição e os que não
    
     -- it := dbms_utility.get_time;
     for compl in (select p.codprod, p.grupoicms, nvl(prm.nurelparm, 0) nuparam,
                          nvl(snk_dividir(ite.vlricmsant, ite.qtdneg), 0) vlrantecip,
                          nvl(snk_dividir(ite.vlrsubst, ite.qtdneg), 0) vlrantecip_to,
                          ad_get.ufparcemp(cab.codparc, 'P') ufparc
                     from tgfite ite
                     join tgfcab cab
                       on cab.nunota = ite.nunota
                     join tgfpro p
                       on ite.codprod = p.codprod
                     left join (select emp.codemp, rg.nurelparm, rg.grupoicms
                                 from ad_adrelparmgruicms rg
                                 join ad_relparmemp emp
                                   on emp.nurelparm = rg.nurelparm) prm
                       on prm.codemp = ite.codemp
                      and p.grupoicms = prm.grupoicms
                    where ite.nunota = livro(x).nunota
                      and ite.sequencia = livro(x).sequencia)
     loop
     
      -- calcula o vlr da antecipação
      if livro(x).uforigem = 'PA' and livro(x).ufdestino = 'PA' then
      
       --v_vlrantecip := ad_pkg_icm.get_vlrantecip_pa(livro(x).codemp, compl.codprod, livro(x).dhmov);
       -- (case when :nuparam = 7 then 8.4 else 3.458824 end / 100),4)
       ad_pkg_var.stmt := q'[select 
        round( (l.baseicms / i.qtdneg) * 
          ad_pkg_icm.get_param_fiscal(:nuparam, :dhmov, 'PERCANT'), 4)
          from tgfliv l
          join tgfite i
            on (i.nunota = l.nunota and i.sequencia = l.sequencia)
         where 1 = 1
           and l.codemp = :codemp
           and l.dhmov <= :dtref
           and l.codcfo = 2152
           and i.codprod = :codprod
           and rownum = 1
         order by l.dhmov desc]';
      
       begin
        execute immediate ad_pkg_var.stmt
        into v_vlrantecip
        using compl.nuparam, livro(x).dhmov, livro(x).codemp, livro(x).dhmov, compl.codprod;
       exception
        when no_data_found then
         v_vlrantecip := 0;
       end;
      
      elsif livro(x).uforigem = 'MG' and livro(x).ufdestino = 'MG' then
      
       v_vlrantecip := compl.vlrantecip;
      
      elsif livro(x).uforigem = 'GO' and livro(x).ufdestino = 'BA' and livro(x).codcfo = 6101 and
             compl.grupoicms in (1004, 1016, 1030) then
      
       v_vlrantecip := ad_pkg_icm.get_vlrantecip_ba(livro(x).nunota, livro(x).sequencia);
      
       /*elsif livro(x).uforigem = 'GO' and livro(x).ufdestino = 'TO' then
       
       v_vlrantecip := compl.vlrantecip_to;*/
      
      end if;
     
      if v_vlrantecip > 0 then
       icm.extend;
       i      := icm.last;
       v_rows := v_rows + 1;
      
       icm(i).dtref := livro(x).dtref;
       icm(i).codemp := livro(x).codemp;
       icm(i).nunota := livro(x).nunota;
       icm(i).sequencia := livro(x).sequencia;
       icm(i).dhmov := livro(x).dhmov;
       icm(i).dtdoc := livro(x).dtdoc;
       icm(i).vlrctb := livro(x).vlrctb;
       icm(i).baseicms := livro(x).baseicms;
       icm(i).aliqicms := livro(x).aliqicms;
       icm(i).vlricms := livro(x).vlricms;
       icm(i).coduf := compl.ufparc; --livro(x).coduf;
       icm(i).codprod := compl.codprod;
       icm(i).vlrantecip := v_vlrantecip;
      
       v_vlrantecip := 0;
      
      end if;
     
     --et := (dbms_utility.get_time - it) / 100;
     --dbms_output.put_line(livro(x).nunota || ' - ' || livro(x).sequencia || ' - ' || et);
     
     end loop compl;
    
    end loop x;
   
    --if icm.count > 0 and i < 1000 then
    --it := dbms_utility.get_time;
    forall x in icm.first .. icm.last
     insert into ad_antecipicm values icm (x);
   
    --et := (dbms_utility.get_time - it) / 100;
    --dbms_output.put_line('Insert: ' || et);
   
    commit;
   
    --icm.delete;
    --i := 0;
    --end if;
   
   end if;
  
  end;
 
  -- dbms_output.put_line('total de linhas: ' || v_rows);
  -- end after statement
 
  --rollback;
 
 end set_base_antecipacao;

 procedure set_base_credoutpres(p_dtref date) is
 
  type ty_tab_credoutpres is table of ad_outprotpres%rowtype;
  t ty_tab_credoutpres := ty_tab_credoutpres();
  i int;
 
  v_credout9vi   int;
  v_credout9lxvi int;
  v_credoutpres3 int;
  v_credoutrb10  int;
  v_icmsret      tgfliv.icmsretencao%type;
  v_fator        int;
 
 begin
 
  --simula dml tgfliv
  for new in (select /*+ PARALLEL(AUTO) */
               liv.*, ite.codprod, pro.codgrupoprod, pro.ncm, top.somasubst
                from tgfliv liv
                join tgfcab cab
                  on cab.nunota = liv.nunota
                 and cab.codemp = liv.codemp
                join tgftop top
                  on top.codtipoper = cab.codtipoper
                 and top.dhalter = cab.dhtipoper
                join tgfite ite
                  on ite.codemp = liv.codemp
                 and ite.nunota = liv.nunota
                 and ite.sequencia = liv.sequencia
                join tgfpro pro
                  on pro.codprod = ite.codprod
               where 1 = 1
                 and liv.origem in ('E', 'A')
                 and liv.entsai = 'S'
                 and cab.statusnota = 'L'
                 and ite.pendente = 'N'
                 and cab.tipmov in ('V', '3', 'T', 'C', 'E')
                 and liv.dhmov between p_dtref and last_day(p_dtref)
                 and cab.dtfatur between p_dtref and last_day(p_dtref)
              
              )
  loop
  
   if new.codcfo < 5000 then
    v_fator := -1;
   else
    v_fator := 1;
   end if;
  
   if new.somasubst = 'S' then
    v_icmsret := new.icmsretencao;
   else
    v_icmsret := 0;
   end if;
  
   begin
    select count(*)
      into v_credout9vi
      from ad_relparmcfop cf
      join ad_relparmgrup gr
        on gr.nurelparm = cf.nurelparm
     where cf.nurelparm = 1
       and cf.codcfo = new.codcfo
       and gr.codgrupoprod = new.codgrupoprod;
   end;
  
   begin
    select count(*)
      into v_credout9lxvi
      from ad_relparmcfop cf
      join ad_relparmgrup gr
        on gr.nurelparm = cf.nurelparm
     where cf.nurelparm = 2
       and cf.codcfo = new.codcfo
       and gr.codgrupoprod = new.codgrupoprod;
   end;
  
   begin
    select count(*)
      into v_credoutpres3
      from ad_relparmcfop cf
      join ad_relparmgrup gr
        on gr.nurelparm = cf.nurelparm
     where cf.nurelparm = 3
       and cf.codcfo = new.codcfo
       and gr.codgrupoprod = new.codgrupoprod;
   end;
  
   begin
    select count(*)
      into v_credoutrb10
      from ad_relparmcfop cf
     where cf.nurelparm = 4
       and cf.codcfo = new.codcfo;
   end;
  
   if v_credout9vi > 0 or v_credout9lxvi > 0 or v_credoutpres3 > 0 or v_credoutrb10 > 0 then
   
    t.extend;
    i := t.last;
   
    t(i).dtref := trunc(new.dhmov, 'fmmm');
    t(i).codgrupoprod := new.codgrupoprod;
    t(i).codemp := new.codemp;
    t(i).nunota := new.nunota;
    t(i).sequencia := new.sequencia;
    t(i).numnota := new.numnota;
    t(i).origem := new.origem;
    t(i).dhmov := new.dhmov;
    t(i).dtdoc := new.dtdoc;
    t(i).codcfo := new.codcfo;
    t(i).codprod := new.codprod;
    t(i).ncm := new.ncm;
    t(i).aliqreal := trunc(snk_dividir(new.vlricms, (new.vlrctb - v_icmsret - new.vlripi) * 100));
    t(i).vlrctb := new.vlrctb * v_fator;
    t(i).baseicms := new.baseicms * v_fator;
    t(i).aliqicms := new.aliqicms;
    t(i).vlricms := new.vlricms;
    t(i).basesemst := 0;
   
   end if;
  
   -- ad_adcredoutprot9vi / ad_adcredoutprot9lxvi  
   if v_credout9vi > 0 or v_credout9lxvi > 0 then
   
    t(i).aliqcredout := 9;
    t(i).aliqprot := func_aliq_protege_sf(1, trunc(new.dhmov, 'fmmm'));
    t(i).vlricmsliq := 0;
    t(i).vlrcredout := new.baseicms * 0.09 * v_fator;
    t(i).vlrcredpres := 0;
    t(i).vlrprotege := t(i).vlrcredout * (t(i).aliqprot / 100);
    t(i).tipo := case
                  when v_credout9vi > 0 then
                   1 --'9VI'
                  when v_credout9lxvi > 0 then
                   2 --'9LXVI'
                  else
                   ''
                 end;
   elsif v_credoutpres3 > 0 then
    t(i).aliqcredout := case
                         when new.codprod in (50593, 50587, 50588) then
                          0
                         else
                          case
                           when new.codgrupoprod in (01040500, 01040200) then
                            1
                           else
                            3
                          end
                        end;
   
    t(i).vlrcredout := new.baseicms * (t(i).aliqcredout / 100) * v_fator;
    t(i).aliqprot := func_aliq_protege_sf(3, trunc(new.dhmov, 'fmmm'));
    t(i).vlrprotege := t(i).vlrcredout * (t(i).aliqprot / 100);
    t(i).tipo := 3 /*'PRES3'*/
     ;
   
   elsif v_credoutrb10 > 0 and
         trunc(snk_dividir(new.vlricms, (new.vlrctb - v_icmsret - new.vlripi) * 100)) between 10 and 11 then
   
    t(i).aliqprot := func_aliq_protege_sf(4, trunc(new.dhmov, 'fmmm'));
    t(i).basesemst := new.vlrctb - v_icmsret - new.vlripi * v_fator;
    t(i).vlricmsliq := round(t(i).basesemst * (t(i).aliqicms / 100), 2);
    t(i).vlrcredpres := round(t(i).basesemst * (t(i).aliqicms / 100), 2) - new.vlricms;
    t(i).vlrprotege := round((t(i).basesemst * (t(i).aliqicms / 100) - new.vlricms) * (t(i).aliqprot / 100),
                             2);
    t(i).tipo := 4 /*'RB10'*/
     ;
   
   end if;
  
  end loop new;
 
  delete from ad_outprotpres where dtref = p_dtref;
 
  forall x in t.first .. t.last
   insert into ad_outprotpres values t (x);
 
  /*if t.count > 0 then
   merge into ad_outprotpres opp
   using (select t(i).nunota nunota,t(i).sequencia sequencia,t(i).vlrcredout vlrcredout,
                 t(i).vlrcredpres vlrcredpres,t(i).vlrprotege vlrprotege
            from dual) d
   on (opp.nunota = d.nunota and opp.sequencia = d.sequencia)
   when matched then
    update
       set vlrcredout  = d.vlrcredout,
           vlrcredpres = d.vlrcredpres,
           vlrprotege  = d.vlrprotege
   when not matched then
    insert values t (i);
  
  end if;*/
 
 end set_base_credoutpres;

 procedure exec_agendamento is
  p_dtref date;
 begin
  p_dtref := add_months(trunc(sysdate, 'fmmm'), -1);
  set_base_credoutpres(p_dtref);
  set_base_antecipacao(p_dtref);
 
 end exec_agendamento;

end ad_pkg_icm;
/
