create or replace package body ad_pkg_avs is

 function get_dados_visita(p_nuvisita number) return ad_tsfavs%rowtype is
  v_result ad_tsfavs%rowtype;
 begin
  select * into v_result from ad_tsfavs where nuvisita = p_nuvisita;
  return v_result;
 end;

 procedure exclui_solcitcarro(p_nucapsol number) is
 begin
  update ad_tsfavs a
     set nucapsol       = null,
         a.statuscar    = null,
         a.dhagendcarro = null,
         a.codveiculo   = null
   where nucapsol = p_nucapsol;
 
  delete from ad_tsfcaprat where nucapsol = p_nucapsol;
  delete from ad_tsfcapitn where nucapsol = p_nucapsol;
  delete from ad_tsfcapsol where nucapsol = p_nucapsol;
 
  stp_set_atualizando('N');
 end;

 /*
   Autor: MARCUS.RANGEL 22/11/2019 11:10:27
   Objetivos: inserir os registro dos históricos.
 */
 procedure insere_historico(p_nuvisita number, p_msg varchar2) is
  i int;
 begin
  select nvl(max(nuavshis), 0) + 1 into i from ad_tsfavshis h where h.nuvisita = p_nuvisita;
 
  insert into ad_tsfavshis
   (nuavshis, nuvisita, dhalter, codusu, descroco)
  values
   (i, p_nuvisita, sysdate, stp_get_codusulogado, p_msg);
 
 exception
  when others then
   raise_application_error(-20105, ad_fnc_formataerro('Erro ao inserir histórico. ' || sqlerrm));
 end insere_historico;

 procedure insere_historico(p_nuvisita number, p_msg varchar2, p_errmsg out varchar2) is
 begin
  insere_historico(p_nuvisita, p_msg);
 exception
  when others then
   p_errmsg := sqlerrm;
 end insere_historico;

 /*
   Autor: MARCUS.RANGEL 22/11/2019 16:14:29
   Objetivos: cria solicitação de aprovação.
 */
 procedure solicita_aprovacao(p_nuvisita number) is
  vis       ad_tsfavs %rowtype;
  evento    int;
  liberador int;
 begin
  --vis := get_dados_visita(p_nuvisita);
 
  select p.nuevevisita, p.codusulibvis
    into evento, liberador
    from ad_tsfprh p
   where p.ativo = 'S'
     and p.dtvigor = (select max(dtvigor)
                        from ad_tsfprh p2
                       where p2.nuprh = p.nuprh
                         and p2.dtvigor < sysdate);
 
  -- insere o pedido de liberação na lib
  ad_set.ins_liberacao(p_tabela    => 'AD_TSFAVS',
                       p_nuchave   => p_nuvisita,
                       p_evento    => evento,
                       p_valor     => 1,
                       p_codusulib => liberador,
                       p_obslib    => 'Referente visita para contratação',
                       p_errmsg    => ad_pkg_var.errmsg);
 
  -- monta e atualiza a observacao complementar com dados da visita
  for v in (select vis.nomevisitado || ' - ' || car.descrcargo || '  - ' || lot.descrlot || chr(13) as complemento
              from ad_tsfavs vis
              left join ad_fpwcrg car
                on car.codcargo = vis.codcargo
               and car.codemp = 1
              left join ad_fpwlot lot
                on lot.codlot = vis.codlot
             where vis.nuvisita = p_nuvisita)
  loop
   update tsilib
      set obscompl = v.complemento
    where tabela = 'AD_TSFAVS'
      and nuchave = p_nuvisita;
  end loop;
 
  if ad_pkg_var.errmsg is not null then
   raise_application_error(-20105, ad_fnc_formataerro(ad_pkg_var.errmsg));
  end if;
 
  -- atualiza o status da visita e insere o histórico
  begin
   update ad_tsfavs v set v.resultvis = 'L' where v.nuvisita = p_nuvisita;
   insere_historico(p_nuvisita, 'Enviado para aprovação técnica');
  exception
   when others then
    raise;
  end;
 
  stp_set_atualizando('N');
 
 end solicita_aprovacao;

 -- M. Rangel - Cria nova visista
 procedure set_nova_visita_funcionario(p_codemp   number,
                                       p_matfunc  number,
                                       p_tipovis  varchar2,
                                       p_dhprevis date,
                                       p_nuvisita out number,
                                       p_mensagem out varchar2) as
 
  vis ad_tsfavs%rowtype;
  fun fpwpower.funciona%rowtype;
 
  v_erroend boolean;
  v_codusu  number := stp_get_codusulogado;
 
  i int := 0;
  x int := 0;
 begin
 
  vis.codemp  := p_codemp;
  vis.matfunc := p_matfunc;
  --p_tipovis   := 'M';
 
  -- captura dados do cadastro do funcionario
  begin
   select *
     into fun
     from fpwpower.funciona fu
    where fu.fucodemp = vis.codemp
      and fu.fumatfunc = vis.matfunc;
  exception
   when others then
    p_mensagem := 'Matricula não encontrada no FPW. ' || sqlerrm;
    return;
  end;
 
  -- loading antes do insert
  begin
  
   stp_keygen_tgfnum('AD_TSFAVS', 1, 'AD_TSFAVS', 'NUVISITA', 0, vis.nuvisita);
   p_nuvisita := vis.nuvisita;
  
   --busca unidade do funcionario
   x := 0;
   <<get_unidade>>
   if x = 0 then
    begin
     select lig.unidade into vis.coduni from fpw_lotacoes_lig lig where lig.codlot = fun.fucodlot;
    exception
     when no_data_found then
      ad_pkg_frh.cria_ligacoes_lotacao_fpw; -- atualiza ligações de lotação
      goto get_unidade;
     when others then
      null;
    end;
   end if;
  
   vis.codend := ad_get.codend_pelo_nome(fun.fuendereco);
   vis.codbai := ad_get.codbai_pelo_nome(fun.fubairro);
  
   -- popula complemento em caso de não achar endereço
   if nvl(vis.codend, 0) = 0 or nvl(vis.codbai, 0) = 0 then
    vis.complemento := fun.fuendereco || '  - ' || fun.fubairro || ' nro ' || fun.funumero ||
                       '  - ' || fun.fucomplemento;
   end if;
  
   vis.dhinclusao   := sysdate;
   vis.tipovisita   := p_tipovis;
   vis.nomevisitado := fun.funomfunc;
   vis.complemento  := vis.complemento;
   vis.codcid       := ad_pkg_func.get_codcid_coduf(fun.fucodemp, fun.fumatfunc, 'codcid');
   vis.coduf        := ad_pkg_func.get_codcid_coduf(fun.fucodemp, fun.fumatfunc, 'coduf');
   vis.codlot       := fun.fucodlot;
   vis.dhprevis     := p_dhprevis;
   vis.status       := 'pend';
   vis.codcargo     := fun.fucodcargo;
   vis.codusuinc    := v_codusu;
   vis.dhalter      := sysdate;
   vis.codusu       := v_codusu;
   vis.numend       := fun.funumero;
   vis.cep          := fun.fucep;
   vis.telefone     := fmt.telefone(to_char(fun.futelefone)) || '/' ||
                       fmt.telefone(to_char(fun.fucelular));
  
   insert into ad_tsfavs values vis;
  
   begin
    ad_pkg_avs.insere_historico(vis.nuvisita,
                                'Inserido por ' || ad_get.nomeusu(v_codusu, 'completo'));
   exception
    when others then
     p_mensagem := sqlerrm;
     return;
   end;
  
  end;
 
 end set_nova_visita_funcionario;

 -- ação realizada na inserção das respostas que possuem ações , rotina de pesquisa, 
 procedure set_aprovado(p_nuvisita number) is
 begin
 
  variaveis_pkg.v_atualizando := true;
 
  update ad_tsfavs v set v.resultvis = 'A' where v.nuvisita = p_nuvisita;
 
  insere_historico(p_nuvisita, 'Aprovação do visitado pela equipe técnica');
 
  variaveis_pkg.v_atualizando := false;
 
 exception
  when others then
   raise;
 end;

 procedure set_reprovado(p_nuvisita number) is
 begin
  update ad_tsfavs v set v.resultvis = 'R' where v.nuvisita = p_nuvisita;
 
  insere_historico(p_nuvisita, 'Reprovação do visitado pela equipe técnica');
 exception
  when others then
   raise;
 end;

 -- procedure que realiza as alterações da visita quando reagendadas
 procedure set_reagendado(p_nuvisita number, p_newdata date, p_numotivo int) is
  vis ad_tsfavs %rowtype;
 begin
  vis := get_dados_visita(p_nuvisita);
 
  stp_set_atualizando('S');
 
  begin
   update ad_tsfavs v
      set v.dhprevis   = p_newdata,
          v.reagend    = 'S',
          v.qtdreagend = nvl(v.qtdreagend, 0) + 1,
          v.numotivo   = p_numotivo,
          v.status     = 'prog',
          v.codpesquisa = Null,
          v.dhalter    = sysdate,
          v.codusu     = stp_get_codusulogado
    where v.nuvisita = p_nuvisita;
  exception
   when others then
    ad_pkg_var.errmsg := 'Erro ao atualizar reagendamento da visita. ' || sqlerrm;
    raise_application_error(-20105, ad_fnc_formataerro(ad_pkg_var.errmsg));
  end;
 
  insere_historico(p_nuvisita,
                   'Reagendamento da visita para dia ' || to_char(p_newdata, 'dd/mm/yyyy'));
 
  stp_set_atualizando('N');
 
 end set_reagendado;

 -- chamada alternativa para inserção de pesquisas
 procedure set_nova_pesquisa(p_nuvisita number, p_pesquisa out number, p_errmsg out varchar2) is
 begin
  set_nova_pesquisa(p_nuvisita, p_pesquisa);
 exception
  when others then
   p_errmsg := 'Erro ao criar nova pesquisa. ' || sqlerrm;
 end;

 -- insere nova pesquisa
 procedure set_nova_pesquisa(p_nuvisita number, p_pesquisa out number) is
  vis ad_tsfavs %rowtype := get_dados_visita(p_nuvisita);
  pes ad_tsfpes %rowtype;
 begin
 
  /*pes.dados := 'Endereço: ' ||
  fmt.endereco_completo(vis.codend, vis.codbai, vis.codcid, vis.coduf);*/
 
  pes.compl := vis.complemento;
 
  --Criação do campo observação: Tipo de Visita  
  pes.observacao := pes.observacao || chr(13) || 'Tipo de visita: ' ||
                    ad_get.opcoescampo(vis.tipovisita, 'TIPOVISITA', 'AD_TSFAVS') || chr(13) ||
                    'Obs: ' || vis.obs;
 
  --Criação do campo observação: busca o cargo do candidato/funcionário
  for crg in (select *
                from ad_fpwcrg c
               where c.codcargo = vis.codcargo
                 and c.codemp = 1)
  loop
   pes.observacao := pes.observacao || chr(13) || 'Cargo: ' || crg.descrcargo;
  end loop;
 
  --Criação do campo observação: Lotação
  for lot in (select * from ad_fpwlot l where l.codlot = vis.codlot)
  loop
   pes.observacao := pes.observacao || chr(13) || 'Lotação: ' || lot.descrlot;
  end loop;
 
  --Criação do campo observação: Unidade
  for ung in (select * from ad_fpwlot l where l.codlot = vis.coduni)
  loop
   pes.observacao := pes.observacao || chr(13) || 'Unidade: ' || ung.descrlot;
  end loop;
 
  -- insere pesquisa
  stp_keygen_tgfnum('AD_TSFPES', 1, 'AD_TSFPES', 'CODPESQUISA', 0, pes.codpesquisa);
 
  select a.dhprevis into pes.dhinc from ad_tsfavs a where a.nuvisita = vis.nuvisita;
  pes.codquest      := vis.codquest;
  pes.descrpesquisa := 'Visita Biosegurança - ' || vis.nomevisitado;
  pes.dhrealizacao  := null;
  pes.status        := 'P';
  pes.codusu        := stp_get_codusulogado;
  pes.nometab       := 'AD_TSFAVS';
  pes.valorpk       := vis.nuvisita;
  pes.codusuapp     := vis.codusuapp;
  pes.nomealvo      := 'Funcionários/Candidatos';
  pes.codend        := vis.codend;
  pes.codbai        := vis.codbai;
  pes.codcid        := vis.codcid;
  pes.coduf         := vis.coduf;
  pes.numend        := to_char(vis.numend);
  pes.cep           := vis.cep;
  pes.telefone      := vis.telefone;
 
  begin
   insert into ad_tsfpes values pes;
  exception
   when others then
    ad_pkg_var.errmsg := 'Erro ao inserir a pesquisa. ' || sqlerrm;
    raise_application_error(-20105, ad_fnc_formataerro(ad_pkg_var.errmsg));
  end;
 
  p_pesquisa := pes.codpesquisa;
 
 end set_nova_pesquisa;

 procedure set_carro_apoio(p_nuvisita  number,
                           p_data      date,
                           p_solmotivo varchar2,
                           p_nucapsol  out number,
                           p_errmsg    out varchar2) is
  sol ad_tsfcapsol %rowtype;
  itn ad_tsfcapitn %rowtype;
  rat ad_tsfcaprat %rowtype;
  vis ad_tsfavs %rowtype := get_dados_visita(p_nuvisita);
 begin
  -- insere cabeçalho da solicitação
  begin
  
   if p_solmotivo is null then
    sol.motivo := sol.motivo || chr(13) || 'Visita Sanitária nro: ' || vis.nuvisita || ' - ' ||
                  vis.nomevisitado;
   else
    sol.motivo := p_solmotivo;
   end if;
  
   if p_data is not null then
    --vis.dhprevis := to_char(p_data, 'dd/mm/yyyy hh24:mi:ss');
    vis.dhprevis := p_data;
   
   end if;
  
   stp_keygen_tgfnum('AD_TSFCAPSOL', 1, 'AD_TSFCAPSOL', 'NUCAPSOL', 0, sol.nucapsol);
   sol.codusu         := stp_get_codusulogado;
   sol.codcencus      := 110100206;
   sol.dhsolicit      := sysdate;
   sol.tiposol        := null;
   sol.status         := 'P';
   sol.dtagend        := vis.dhprevis;
   sol.nuap           := null;
   sol.dhalter        := sysdate;
   sol.qtdpassageiros := 1;
   sol.dhenvio        := null;
   sol.motivo         := substr(sol.motivo, 1, 250);
   sol.origem         := null;
  
   insert into ad_tsfcapsol values sol;
  
  exception
   when others then
    p_errmsg := 'Erro ao inserir o cabeçalho da solicitação. ' || sqlerrm;
    return;
  end;
 
  -- insere intinerário da solicitação
  begin
   for l in 1 .. 2
   loop
    itn.nuitn      := l;
    itn.nucapsol   := sol.nucapsol;
    itn.referencia := null;
   
    if l = 1 then
     itn.tipotin := 'O';
     itn.codcid  := 2;
    
     select e.codend, e.codbai, e.complemento
       into itn.codend, itn.codbai, itn.complemento
       from tsiemp e
      where e.codemp = 1;
    
    else
     itn.tipotin     := 'D';
     itn.codcid      := vis.codcid;
     itn.codend      := nvl(vis.codend, 0);
     itn.codbai      := nvl(vis.codbai, 0);
     itn.complemento := vis.complemento;
    end if;
   
    insert into ad_tsfcapitn values itn;
   
   end loop;
  exception
   when others then
    p_errmsg := 'Erro ao inserir o intinerário da solicitação. ' || sqlerrm;
    return;
  end;
 
  -- insere rateio
  begin
   rat.nucapsol   := sol.nucapsol;
   rat.nucaprat   := 1;
   rat.codemp     := 1;
   rat.codnat     := 4051300;
   rat.codcencus  := sol.codcencus;
   rat.percentual := 100;
   rat.codproj    := 0;
  
   insert into ad_tsfcaprat values rat;
  exception
   when others then
    p_errmsg := 'Erro ao inserir o rateio da solicitação. ' || sqlerrm;
    return;
  end;
 
  -- envia as solicitações para agendamento do transporte
  begin
   insert into execparams
    (idsessao, sequencia, nome, tipo, numint)
   values
    ('NOVASOLICITACAOCARRO', 1, 'NUCAPSOL', 'I', sol.nucapsol);
  
   ad_stp_cap_enviaagend(stp_get_codusulogado, 'NOVASOLICITACAOCARRO', 1, p_errmsg);
  
   if p_errmsg not like '%sucesso%' then
    return;
   end if;
  
   delete from execparams where idsessao = 'NOVASOLICITACAOCARRO';
  
  end;
 
  p_nucapsol := sol.nucapsol;
 
  --commit;
 
 end set_carro_apoio;

 procedure set_carro_apoio(p_nuvisita number, p_nucapsol out number, p_errmsg out varchar2) is
 begin
  set_carro_apoio(p_nuvisita, null, null, p_nucapsol, p_errmsg);
 end;

end ad_pkg_avs;
