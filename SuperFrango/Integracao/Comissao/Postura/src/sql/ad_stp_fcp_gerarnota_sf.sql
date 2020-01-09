create or replace procedure ad_stp_fcp_gerarnota_sf(p_codusu    number,
                                                    p_idsessao  varchar2,
                                                    p_qtdlinhas number,
                                                    p_mensagem  out varchar2) as
 ref ad_tsffcpref%rowtype;
 cfg ad_tsffciconf%rowtype;
 mgn ad_tsfmgn%rowtype;

 v_numnota number;
 v_nufin   number;
 v_modelo  int;

begin

 /*
   Autor: MARCUS.RANGEL 20/12/2019 14:39:21
   Processo: Fechamento de Comissão do Integrado - Postura
   Objetivo: Botão de ação "gerar nota" da tela de fechamento 
             de comissão, como diz o nome, o intuito é gerar 
             os documentos da cab, nota ou pedido.
 */

 if p_qtdlinhas > 1 then
  p_mensagem := 'Selecione apenas 1 referência.';
  return;
 end if;

 ref.codcencus := act_int_field(p_idsessao, 1, 'CODCENCUS');
 ref.dtref     := act_dta_field(p_idsessao, 1, 'DTREF');

 select *
   into ref
   from ad_tsffcpref
  where codcencus = ref.codcencus
    and dtref = ref.dtref;

 -- valida nunota
 if ref.nunota is not null then
  p_mensagem := 'Referência já possui nota gerada!';
  return;
 end if;

 -- valida quantidade de ovos 
 if ref.qtdovosinc != ref.qtdovosgrj then
  p_mensagem := 'Quantidade de ovos inconsistente.';
  return;
 end if;

 -- busca set de parametros
 ad_pkg_fci.get_config(sysdate, cfg);

 -- se uf GO
 if ad_get.ufparcemp(ref.codparc, 'P') = ad_get.ufparcemp(ref.codemp, 'E') then
  v_modelo := cfg.numodcpapost; -- recebe o modelo da nota de compra
 else
  v_modelo := cfg.numodpcapost; -- recebe o modelo do pedido de compra
 end if;

 -- busca valores do modelo
 begin
  select * into mgn from ad_tsfmgn m where m.numodelo = v_modelo;
 exception
  when others then
   raise;
 end;

 -- insere documento  
 begin
  -- insere cabeçalho
  ad_set.ins_pedidocab(p_codemp      => ref.codemp,
                       p_codparc     => ref.codparc,
                       p_codvend     => mgn.codvend,
                       p_codtipoper  => mgn.codtipoper,
                       p_codtipvenda => mgn.codtipvenda,
                       p_dtneg       => sysdate,
                       p_vlrnota     => ref.vlrcom,
                       p_codnat      => mgn.codnat,
                       p_codcencus   => ref.codcencus,
                       p_codproj     => 0,
                       p_obs         => 'Produção mês ' || ref.dtref || ' - lote ' || ref.numlote,
                       p_nunota      => ref.nunota);
  -- insere item
  ad_set.ins_pedidoitens(p_nunota   => ref.nunota,
                         p_codprod  => mgn.codprod,
                         p_qtdneg   => ref.qtdparticipovo,
                         p_codvol   => mgn.codvol,
                         p_codlocal => mgn.codlocal,
                         p_controle => null,
                         p_vlrunit  => ref.vlrunitcom,
                         p_vlrtotal => ref.vlrcom,
                         p_mensagem => p_mensagem);
 
  if p_mensagem is not null then
   return;
  end if;
 
  -- insere financeiro
  begin
   ad_set.ins_financeiro(p_codemp     => ref.codemp,
                         p_numnota    => 0,
                         p_dtneg      => trunc(sysdate),
                         p_dtvenc     => ref.dtvenc,
                         p_codparc    => ref.codparc,
                         p_top        => mgn.codtipoper,
                         p_contabanco => mgn.codctabcoint,
                         p_codnat     => mgn.codnat,
                         p_codcencus  => ref.codcencus,
                         p_codproj    => 0,
                         p_codtiptit  => mgn.codtiptit,
                         p_origem     => 'E',
                         p_nunota     => ref.nunota,
                         p_valor      => ref.vlrcom,
                         p_nufin      => v_nufin,
                         p_errmsg     => p_mensagem);
  
   if p_mensagem is not null then
    return;
   end if;
  
  exception
   when others then
    p_mensagem := sqlerrm;
    return;
  end;
 
 end;

 -- atualiza dados na origem
 begin
  update ad_tsffcpref r
     set r.nunota     = ref.nunota,
         r.statuslote = 'F'
   where r.codcencus = ref.codcencus
     and r.dtref = ref.dtref;
 exception
  when others then
   p_mensagem := sqlerrm;
   return;
 end;

 -- cria vinculo externo (usnado hash para contornar o problema da PK)
 begin
 
  select ora_hash(concat(ref.codcencus, ref.dtref), 1000000000, 2) into v_numnota from dual;
 
  insert into ad_tblcmf
   (nometaborig, nuchaveorig, nometabdest, nuchavedest)
  values
   ('AD_TSFFCPREF', v_numnota, 'TGFCAB', ref.nunota);
 
 exception
  when others then
   p_mensagem := sqlerrm;
   return;
 end;

 -- confirma pedido de compra
 if nvl(mgn.confauto, 'N') = 'S' then
 
  if act_confirmar('Confirmação de Nota', 'Deseja confirmar a nota Gerada?', p_idsessao, 1) then
  
   stp_confirmanota_java_sf(ref.nunota);
  
   -- experimental
   /**
   * remover caso necessite diminuir o runtime
   * a ideia é esperar antes de buscar o status da nfe, na esperança
   * de trazer um status com alguma informação retornada da sefaz
   **/
  
   --dbms_lock.sleep(5); tá sem grant na DEV
   declare
    dtinicio date := sysdate;
    dtatual  date;
    x        number := 0;
   begin
    loop
     x       := x + 1;
     dtatual := sysdate;
     exit when dtatual > dtinicio + 0.09 /(24 * 60);
    end loop;
   end;
  
   -- busca status da nfe
   begin
    select c.statusnfe into ref.statusnfe from tgfcab c where c.nunota = ref.nunota;
   exception
    when others then
     p_mensagem := 'Erro ao buscar o status da NFE da nota ' || ref.nunota;
     return;
   end;
   
  
   -- atualiza informações na origem
   begin
    update ad_tsffcpref r set r.statusnfe = ref.statusnfe where r.nunota = ref.nunota;
   exception
    when others then
     p_mensagem := 'Erro ao atualizar as informações na origem. ' || sqlerrm;
     return;
   end;
  
  end if;
 
 end if;

 -- atualiza data ultimo fechamento            
 begin
  update ad_tsffcp p set p.dtultfat = sysdate where p.codcencus = ref.codcencus;
 exception
  when others then
   p_mensagem := 'Erro ao atualizar a data "Último Fechamento". ' || sqlerrm;
   return;
 end;

 p_mensagem := 'Nota nº único ' || '<a title="Clique aqui" target="_parent" href="' ||
               ad_fnc_urlskw('TGFCAB', ref.nunota) || '">' || ref.nunota || '</a>' ||
               ' gerada com sucesso!';

end;
/
