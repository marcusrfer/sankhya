create or replace package ad_pkg_func is

 -- Author  : MARCUS.RANGEL
 -- Created : 31/07/2019 17:56:41
 -- Purpose : métodos relacionados à obtenção de dados de  funcionarios  tanto do W quanto do  FPW

 -- Public type declarations

 -- Public constant declarations

 -- Public variable declarations
 is_debug boolean := false;

 -- Public function and procedure declarations
 function get_descr_estado_civil(p_estcivil int) return varchar2 deterministic;

 function get_descr_escolaridade(p_codgrau int) return varchar2 deterministic;

 /*função que irá buscar o grau de instrução do funcionário em um determinado momento do tempo*/
 /*function get_grauinstr_periodo(p_dtref date,
 p_matfunc number) return number;*/

 /*function get_descricao_grauinstr(p_dtref date,
 p_matfunc number) return varchar2;*/

 function get_descricao_atributo(p_codemp number, p_codfunc number, p_atrib number) return varchar2;

 function get_cidade_uf(p_emp number, p_mat number, p_tipo char) return varchar2;

 function get_codcid_coduf(p_codemp int, p_matfunc number, p_tipo varchar2) return number
 deterministic;

 type rec_dados_periodo is record(
  codemp    number,
  matfunc   number,
  codsit    number,
  grauinstr number,
  codlot    number,
  codcargo  number);

 type tab_dados_periodo is table of rec_dados_periodo;

 /*função que irá buscar o dados variáveis do funcionário em um determinado momento do tempo*/
 function retorna_dados_periodo(p_dtref date, p_codemp number, p_matfunc number)
  return tab_dados_periodo
 pipelined;

 function get_descr_lotacao(p_codlot number, p_grau int) return varchar2 deterministic;

 /* Retorna a descrição do funcionário em determinado período*/
 function get_descrformacao_func(p_codemp int, p_matfunc number, p_dtref date) return varchar2;

end ad_pkg_func;
/
create or replace package body ad_pkg_func is

 function get_descr_estado_civil(p_estcivil int) return varchar2 deterministic is
  v_descricao varchar2(4000);
 begin
 
  v_descricao := case
                  when p_estcivil = '1' then
                   'Solteiro'
                  when p_estcivil = '2' then
                   'Casado'
                  when p_estcivil = '3' then
                   'Sep. Judicialmente'
                  when p_estcivil = '4' then
                   'Divorciado'
                  when p_estcivil = '5' then
                   'Viuvo'
                  when p_estcivil = '6' then
                   'Outros'
                  when p_estcivil = '7' then
                   'Ignorado'
                 end;
 
  return v_descricao;
 
 end get_descr_estado_civil;

 function get_descr_escolaridade(p_codgrau int) return varchar2 deterministic is
  v_result varchar2(100);
 begin
  v_result := case
               when p_codgrau = 1 then
                'Analfabeto'
               when p_codgrau = 2 then
                'Primeiro Grau Incompleto'
               when p_codgrau = 3 then
                'Primeiro grau completo'
               when p_codgrau = 4 then
                'Ens. Fundamental Incompleto'
               when p_codgrau = 5 then
                'Ens. Fundamental Completo'
               when p_codgrau = 6 then
                'Ensino Médio Incompleto'
               when p_codgrau = 7 then
                'Ensino Médio Completo'
               when p_codgrau = 8 then
                'Superior Incompleto'
               when p_codgrau = 9 then
                'Superior Completo'
               when p_codgrau = 10 then
                'Pós-Graduação/Especialização'
               when p_codgrau = 11 then
                'Doutorado Completo'
               when p_codgrau = 12 then
                'Segundo grau técnico incompleto'
               when p_codgrau = 13 then
                'Segundo grau técnico completo'
               when p_codgrau = 14 then
                'Mestrado'
               when p_codgrau = 15 then
                'Pós-Doutorado'
               else
                'Não informado'
              end;
 
  return v_result;
 
 end get_descr_escolaridade;

 /*função que irá buscar o grau de instrução do funcionário em um determinado momento do tempo*/
 function retorna_dados_periodo(p_dtref date, p_codemp number, p_matfunc number)
  return tab_dados_periodo
 pipelined is
  t rec_dados_periodo;
 begin
  select /*+ RESULT_CACHE */
   codemp, matfunc, codsit, grauinstr, codlot, codcargo
    into t.codemp, t.matfunc, t.codsit, t.grauinstr, t.codlot, t.codcargo
    from (with maior_data as (select f.fuhistcodemp codemp, f.fuhistmatfunc matfunc,
                                     max(fmt.number_to_date(f.fuhistdataini)) dataini
                                from fpwpower.funcionahist f
                               where p_dtref between
                                     trunc(fmt.number_to_date(f.fuhistdataini), 'fmmm') and
                                     trunc(fmt.number_to_date(f.fuhistdatafim), 'fmmm')
                                 and f.fuhistmatfunc = p_matfunc
                               group by f.fuhistcodemp, f.fuhistmatfunc)
          select fh.fuhistcodemp codemp, fh.fuhistmatfunc matfunc, f.funomfunc nomefunc,
                 f.fudtadmis dtadmiss, fh.fuhistcodsitu codsit,
                 fmt.number_to_date(fh.fuhistdataini) dtini,
                 fmt.number_to_date(fh.fuhistdatafim) dtfim, fh.fuhistgrauinst grauinstr,
                 fh.fuhistcodlot codlot, fh.fuhistcodcargo codcargo
            from fpwpower.funcionahist fh
            join fpwpower.funciona f
              on f.fumatfunc = fh.fuhistmatfunc
             and f.fucodemp = fh.fuhistcodemp
            join maior_data md
              on md.codemp = fh.fuhistcodemp
             and md.matfunc = fh.fuhistmatfunc
             and fmt.number_to_date(fh.fuhistdataini) = md.dataini
           where fh.fuhistcodemp = p_codemp
             and to_number(fh.fuhistmatfunc) = p_matfunc)
           where 1 = 1
             and p_dtref between trunc(dtini, 'mm') and trunc(dtfim, 'mm')
             and (trunc(dtfim, 'mm') >= p_dtref)
             and rownum = 1;
 
 
  pipe row(t);
 
 end retorna_dados_periodo;

 /*function get_descricao_grauinstr(p_dtref date,
                                  p_matfunc number) return varchar2 is
   v_result  varchar2(100);
   v_codgrau int;
 begin
   v_codgrau := get_grauinstr_periodo(p_dtref, p_matfunc);
   v_result  := get_descr_escolaridade(v_codgrau);
   return v_result;
 end get_descricao_grauinstr;*/

 function get_descricao_atributo(p_codemp number, p_codfunc number, p_atrib number) return varchar2 is
  atb      fpwpower.atribfun%rowtype;
  v_result varchar2(100);
 begin
 
  select *
    into atb
    from fpwpower.atribfun a
   where a.afcodemp = p_codemp
     and a.afmatfunc = p_codfunc
     and a.afcodatrib = p_atrib;
 
  -- cidade / UF
  if (p_atrib = 1002) then
   if length(substr(trim(atb.afvalor), -2)) = 2 then
    v_result := substr(trim(atb.afvalor), -2);
   else
    v_result := null;
   end if;
  
  end if;
 
  return v_result;
 
 exception
  when others then
   return null;
 end get_descricao_atributo;

 -- trata string do atributo para buscar cidade e uf
 function get_cidade_uf(p_emp number, p_mat number, p_tipo char) return varchar2 is
  v_nomecid varchar2(200);
  v_uf      varchar2(2);
 begin
  -- tipos
  --- c para cidade
  --- u para uf  
 
  select case
          when instr(v_string, '/') > 0 then
           substr(v_string, 1, instr(v_string, '/') - 1)
          else
           v_string
         end nomecid,
         substr(case
                 when instr(v_string, '/') > 0 then
                  trim(substr(v_string, instr(v_string, '/') + 1, length(v_string)))
                 else
                  trim(uf)
                end,
                1,
                2) as uf
    into v_nomecid, v_uf
    from (select nvl(trim(translate(replace(a.afvalor, ' - ', '/'), '1234567890', '          ')),
                       m.mudesmunic) v_string, m.mudesmunic nomecid, m.muuf uf
             from fpwpower.funciona f
             left join fpwpower.atribfun a
               on a.afcodemp = f.fucodemp
              and a.afmatfunc = f.fumatfunc
              and a.afcodatrib = 1002
             join fpwpower.municip m
               on m.mucodmunic = f.fucodmunic
            where f.fucodemp = p_emp
              and f.fumatfunc = p_mat);
 
  if upper(p_tipo) = 'C' then
   return v_nomecid;
  elsif upper(p_tipo) = 'U' then
   return v_uf;
  else
   return v_nomecid || '  - ' || v_uf;
  end if;
 exception
  when others then
   return 'ER';
 end get_cidade_uf;

 function get_descr_lotacao(p_codlot number, p_grau int) return varchar2 deterministic is
  v_codlot number;
  v_result varchar2(4000);
 begin
  if (nvl(p_codlot, 0) = 0) then
   return 'Todas as Unidades';
  end if;
  select case
          when p_grau = 1 then
           unidade
          when p_grau = 2 then
           depto
          when p_grau = 3 then
           setor
          when p_grau = 4 then
           divisao
         end
    into v_codlot
    from fpw_lotacoes_lig
   where codlot = p_codlot;
 
  select lodesclot
    into v_result
    from fpwpower.lotacoes l
   where l.locodlot = v_codlot
     and l.locodemp = 1;
 
  return v_result;
 exception
  when others then
   v_result := 'Lotação não encontrada';
   dbms_output.put_line('erro: ' || p_codlot || '  - ' || sqlerrm);
 end get_descr_lotacao;

 function get_descrformacao_func(p_codemp int, p_matfunc number, p_dtref date) return varchar2 is
  v_result varchar2(4000);
 begin
 
  select --fp.fopecodemp codemp,
  --fp.fopecodfor codfor,
   t.tifodestip || '  - ' || f.formdesfor
    into v_result
  --fmt.number_to_date(fp.fopedtcon) dtconslusao
    from fpwpower.formpessoal fp, fpwpower.formacao f, fpwpower.tipoformacao t
   where fp.fopecodemp = p_codemp
     and fp.fopecodpessoa = p_matfunc --875
     and fp.fopeindcf = 'F'
     and f.formcodemp = fp.fopecodemp
     and f.formcodfor = fp.fopecodfor
     and t.tifocodemp = f.formcodemp
     and t.tifocodtip = fp.fopecodtip
     and fmt.number_to_date(fp.fopedtcon) =
         (select max(fmt.number_to_date(fp2.fopedtcon))
            from fpwpower.formpessoal fp2
           where fp2.fopecodemp = fp.fopecodemp
             and fp2.fopecodpessoa = fp.fopecodpessoa
             and trunc(fmt.number_to_date(fp2.fopedtcon), 'fmmm') <= p_dtref);
 
  return v_result;
 
 exception
  when others then
   return 'Formação não encontrada';
 end get_descrformacao_func;

 function get_codcid_coduf(p_codemp int, p_matfunc number, p_tipo varchar2) return number
 deterministic is
  v_codcid number;
  v_coduf  number;
 begin
 
  for nomes in (select mn.mudesmunic cidade, mn.muuf uf
                  from fpwpower.funciona fu
                  join fpwpower.municip mn
                    on mn.mucodmunic = fu.fucodmunic
                 where fu.fucodemp = p_codemp
                   and fu.fumatfunc = p_matfunc)
  loop
   v_coduf  := ad_get.coduf_pelo_nome(nomes.uf);
   v_codcid := ad_get.codcid_pelo_nome(nomes.cidade);
  end loop;
 
  if lower(p_tipo) = 'codcid' then
   return v_codcid;
  else
   return v_coduf;
  end if;
 
 end get_codcid_coduf;

end ad_pkg_func;
/
