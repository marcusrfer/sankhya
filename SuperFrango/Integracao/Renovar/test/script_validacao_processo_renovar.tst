PL/SQL Developer Test script 3.0
112
-- Created on 18/10/2019 by MARCUS.RANGEL 
declare
 -- Local variables here
 cab        ad_adtssacab%rowtype;
 v_acao     varchar2(100);
 v_idsessao varchar2(100);
begin

 v_acao := :acao;

 if v_acao = 'insert' then
 
  --- valida insert do renovar
 
  begin
  
   begin
    update tgfnum
       set ultcod =
           (select max(nunico) + 1 from ad_adtssacab)
     where arquivo = 'AD_ADTSSACAB'
       and codemp = 1;
    commit;
   exception
    when others then
     raise;
   end;
  
   stp_keygen_tgfnum('AD_ADTSSACAB', 1, 'AD_ADTSSACAB', 'NUNICO', 0, cab.nunico);
   cab.dtvenc    := sysdate + 10;
   cab.historico := 'RENOVAR - ADTO ' || cab.nunico || '  - ' || ad_get.nome_parceiro(655044, 'fantasia');
   --cab.numnota  := regexp_replace(p.nomeparc, '[^[:digit:]]', null)||cab.nunico;
   cab.numnota := extract(year from sysdate) || cab.nunico;
  
   insert into ad_adtssacab
    (nunico, tipo, codemp, codparc, codparcrec, situacao, dtneg, dtvenc, forma, vlrdesdob, nrparcelas,
     dtvenc1, taxa, tipojuro, historico, codproj, codnat, codcencus, codcencusresp, codctabcoint, resumo,
     nufin, nuacerto, codusuinc, dhinc, dhsolicitacao, codusufin, dhaprovfin, codusuapr, dhaprovadt, modcred,
     numnota, numcontrato, dhalter)
   values
    (cab.nunico, 16, 1, 0, 655044, null, sysdate, cab.dtvenc, 1, 9000, 3, cab.dtvenc, 0, 'C', cab.historico,
     0, 9052500, null, null, 1, null, null, null, 114, sysdate, sysdate, null, null, null, null, null,
     cab.numnota, null, sysdate);
  
  exception
   when others then
    rollback;
    raise;
  end;
 
 elsif v_acao = 'delete' then
 
  begin
   delete from ad_adtssacab where nunico = :nunico;
  exception
   when others then
    raise;
  end;
 
 elsif v_acao = 'parcelas' then
 
  ad_set.inseresessao(p_nome      => 'NUNICO',
                      p_sequencia => 1,
                      p_tipo      => 'I',
                      p_valor     => :nunico,
                      p_idsessao  => v_idsessao);
 
  ad_set.inseresessao(p_nome      => '__CONFIRMACAO__',
                      p_sequencia => 1,
                      p_tipo      => 'S',
                      p_valor     => 'S',
                      p_idsessao  => v_idsessao);
 
  ad_stp_adtssa_geraparcela_sf(p_codusu    => 114,
                               p_idsessao  => v_idsessao,
                               p_qtdlinhas => 1,
                               p_mensagem  => :errmsg);
 
 elsif v_acao = 'confirma' then
 
  ad_set.inseresessao(p_nome      => 'NUNICO',
                      p_sequencia => 1,
                      p_tipo      => 'I',
                      p_valor     => :nunico,
                      p_idsessao  => v_idsessao);
 
  ad_set.inseresessao(p_nome      => '__CONFIRMACAO__',
                      p_sequencia => 1,
                      p_tipo      => 'S',
                      p_valor     => 'S',
                      p_idsessao  => v_idsessao);
 
  ad_stp_adtssa_solaprov_sf(p_codusu    => 114,
                            p_idsessao  => v_idsessao,
                            p_qtdlinhas => 1,
                            p_mensagem  => :errmsg);
 
 elsif v_acao = 'update' then
 
  update ad_adtssacab c set c.taxa = 5 where nunico = :nunico;
 
 elsif v_acao = 'liberacao' then
 
  update tsilib l
     set l.vlrliberado = l.vlratual,
         l.dhlib       = trunc(sysdate)
   where l.tabela = 'AD_ADTSSACAB'
     and l.nuchave = :nunico;
 
 end if;

end;
3
acao
1
liberacao
5
nunico
1
3508
3
errmsg
1
O valor total de despesa é diferente do valor total do empréstimo. Verifique se todas as despesas foram lançadas no sistema.
5
2
cab.nunico
cab.numnota
