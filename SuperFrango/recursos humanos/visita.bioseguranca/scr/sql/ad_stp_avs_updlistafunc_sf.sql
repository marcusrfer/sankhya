create or replace procedure ad_stp_avs_updlistafunc_sf(p_codusu    number,
                                                       p_idsessao  varchar2,
                                                       p_qtdlinhas number,
                                                       p_mensagem  out varchar2) as

 /*
 * Autor: M. Rangel
 * Processo: agendamento de visitas sanitarias
 * Objetivo: Atualizar os funcionários que terão as datas de visitas editadas para 
             geração das visitas em lote. Ação na tela "prog. visita manut. funcionario"
 */

 type vsm is table of ad_tsfprgvis%rowtype;

 v vsm;
 o vsm;

 type dif_matricula is table of number;
 d1 dif_matricula := dif_matricula();
 d2 dif_matricula := dif_matricula();
 d3 dif_matricula := dif_matricula();

 cursor cur is
  select fu.fumatfunc as matfunc, fu.fucodemp as codemp, fu.fucodlot as codlot,
         fu.fucodcargo as codcargo, 
         ad_pkg_func.get_codcid_coduf(fu.fucodemp, fu.fumatfunc, 'codcid') codcid,
         ad_pkg_func.get_codcid_coduf(fu.fucodemp, fu.fumatfunc, 'coduf') coduf,
         null as dtultvis, 
         'S' as ativo         
    from fpwpower.funciona fu
    join fpw_lotacoes_lig lot
      on lot.codemp = fu.fucodemp
     and lot.codlot = fu.fucodlot
    join fpwpower.cargos ca
      on ca.cacodemp = fu.fucodemp
     and ca.cacodcargo = fu.fucodcargo
    join fpwpower.municip mun
      on mun.mucodmunic = fu.fucodmunic
   where fu.fucodemp = 1
     and fmt.number_to_date(fu.fudtadmis) <= last_day(sysdate)
     and not exists (select 1
            from ad_prhsit p
           where p.codsit = fu.fucodsitu
             and p.gruporel = 'R')
     and exists (select 1 from ad_tsfprhvsm v where v.codlot = lot.setor);

begin

 -- popula com os novos funcionarios
 open cur;
 fetch cur bulk collect
 into v;
 close cur;

 -- popula com matriculas novas para comparação
 for i in v.first .. v.last
 loop
  d1.extend;
  d1(i) := v(i).matfunc;
 end loop;

 -- popula com os existentes
 select * bulk collect into o from ad_tsfprgvis;

 --- preenche array com matriculas existentes para comparação
 if o.count > 0 then
  for i in o.first .. o.last
  loop
   d2.extend;
   d2(i) := o(i).matfunc;
  end loop;
 end if;

 -- preenche array com a diferença entre as matriculas
 d3 := d1 multiset except d2;

 -- merge na table destino com os novos funcionários das lotações 
 --- informadas na tela de parametros      
 begin
  forall i in v.first .. v.last
   merge into ad_tsfprgvis v
   using (select v(i).matfunc matfunc,v(i).codemp codemp,v(i).codlot codlot,v(i).codcargo cargo,
                 v(i).dtultvis dtvis, v(i).ativo ativo, v(i).codcid codcid, v(i).coduf coduf
            from dual) f
   on (v.codemp = f.codemp and v.matfunc = f.matfunc)
   when not matched then
    insert values (f.matfunc, f.codemp, f.codlot, f.cargo, f.codcid, f.coduf, f.dtvis, f.ativo)
    When Matched then 
     Update Set codcid = f.codcid, coduf = f.coduf;
 end;

 -- percorre as matriculas divergentes e desativa as rescididas
 if d3.count > 0 then
 
  for i in d3.first .. d3.last
  loop
   for func in (select fu.fucodemp codemp, fu.fumatfunc matfunc
                  from fpwpower.funciona fu
                 where fu.fumatfunc = d3(i)
                   and fu.fucodemp = 1
                   and exists (select 1
                          from ad_prhsit p
                         where p.codsit = fu.fucodsitu
                           and p.gruporel = 'R'))
   loop
    begin
     update ad_tsfprgvis v
        set v.ativo = 'N'
      where codemp = func.codemp
        and matfunc = func.matfunc;
    exception
     when others then
      p_mensagem := 'Erro ao desativar funcionários demitidos. ' || sqlerrm;
      return;
    end;
   end loop;
  
  end loop;
 
 end if;

 p_mensagem := 'Atualizações realizadas com sucesso!';

 --rollback;

end;
/
