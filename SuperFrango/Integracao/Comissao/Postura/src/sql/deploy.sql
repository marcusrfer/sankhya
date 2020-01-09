--------------------------------------------------------
--  DDL for Procedure AD_STP_FCP_GETDATA_SF
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "SANKHYA"."AD_STP_FCP_GETDATA_SF" (p_codusu    number,
                                                  p_idsessao  varchar2,
                                                  p_qtdlinhas number,
                                                  p_mensagem  out varchar2) as

 p_dataini  date;
 p_datafin  date;
 v_confirma boolean;
 v_dreftab  date;

 type tab_notas is table of ad_tsffcpnfe%rowtype;
 t tab_notas;

 lanc ad_tsffcpref%rowtype;
 conf ad_tsftcpref%rowtype;

begin

 /*
 * Autor: M. Rangel
 * Processo: Fechamento de Comissão Integrado - Postura
 * Objetivo: Ler os dados da tabela, popular e calcular os campos da tela de 
             fechamento da comissão postura
 */
 lanc.codcencus := act_int_field(p_idsessao, 0, 'MASTER_CODCENCUS');
 lanc.codemp    := to_number(act_txt_param(p_idsessao, 'CODEMP'));
 lanc.codtabpos := to_number(act_txt_param(p_idsessao, 'CODTAB'));
 lanc.numlote   := act_int_param(p_idsessao, 'NUMLOTE');
 lanc.pontuacao := act_int_param(p_idsessao, 'PONTUACAO');
 lanc.dtvenc    := act_dta_param(p_idsessao, 'DTVENC');
 p_dataini      := act_dta_param(p_idsessao, 'DATAINI');
 p_datafin      := act_dta_param(p_idsessao, 'DATAFIN');

 if p_qtdlinhas > 1 then
  v_confirma := act_confirmar(p_titulo    => 'Preparação para Fechamento',
                              p_texto     => 'Deseja recalcular os valores para todas as linhas ' ||
                                             'selecionadas?',
                              p_chave     => p_idsessao,
                              p_sequencia => 0);
 end if;

 if not v_confirma then
  return;
 end if;

 lanc.dtref      := trunc(sysdate, 'fmmm');
 lanc.statuslote := 'A';

 -- busca o parceiro pelo centro d resultados
 begin
  select codparc into lanc.codparc from tgfpar p where p.ad_codcencus = lanc.codcencus;
 exception
  when no_data_found then
  
   select codparc
     into lanc.codparc
     from tgfcab
    where codcencus = lanc.codcencus
      and codtipoper in (332, 777)
    fetch first 1 rows only;
  
  when others then
   raise;
 end;

 -- busca tabela e os valores da referencia e do custo
 begin
 
  ad_stp_fcp_getreftabela_sf(p_codcencus => lanc.codcencus,
                             p_dtref     => lanc.dtref,
                             p_codtab    => lanc.codtabpos,
                             p_dtreftab  => v_dreftab,
                             p_recoper   => lanc.vlrcomfixa,
                             p_recatrat  => lanc.vlrcomatrat,
                             p_recbonus  => lanc.vlrcomclist,
                             p_rectotal  => lanc.totcomfixa,
                             p_custo     => lanc.vlrunitcom);
 
 exception
  when others then
   p_mensagem := 'Erro ao buscar os valores da referencia da tabela. ' || sqlerrm;
   return;
 end;

 -- quantidade de ovos incubaveis no incubatorio
 begin
  select nvl(sum(case
                  when cab.codtipoper in (777) then
                   ite.qtdneg * -1
                  else
                   ite.qtdneg
                 end),
             0)
    into lanc.qtdovosinc
    from tgfcab cab, tgfite ite
   where cab.nunota = ite.nunota
     and cab.codtipoper in (332, 777)
     and cab.dtneg >= p_dataini
     and cab.dtneg <= p_datafin
     and cab.codcencus = lanc.codcencus
     and cab.codparc = lanc.codparc
     and ite.codprod = 72124;
 exception
  when others then
   p_mensagem := 'Erro ao buscar a quantidade de ovos incubaveis no incubatório. ' || sqlerrm;
   return;
 end;

 -- quantidade ovos incubaveis granja
 begin
  select nvl(sum(case
                  when cab.codtipoper in (19, 777) or cab.codparc = 615964 then
                   ite.qtdneg * -1
                  else
                   ite.qtdneg
                 end),
             0)
    into lanc.qtdovosgrj
    from tgfcab cab, tgfite ite
   where cab.nunota = ite.nunota
     and cab.codtipoper in (197, 777)
     and cab.dtneg >= p_dataini
     and cab.dtneg <= p_datafin
     and cab.codcencus = lanc.codcencus
     and ite.sequencia > 0
     and ite.codprod = 72124;
 exception
  when others then
   p_mensagem := 'Erro ao buscar a quantidade de ovos incubaveis na granja. ' || sqlerrm;
   return;
 end;

 lanc.nunota          := null;
 lanc.statusnfe       := null;
 lanc.recbonus        := lanc.vlrcomclist * (lanc.pontuacao / 100);
 lanc.totcomave       := lanc.recbonus + lanc.vlrcomfixa + lanc.vlrcomatrat;
 lanc.percparticipovo := snk_dividir((lanc.qtdovosinc * lanc.totcomave),
                                     (lanc.qtdovosinc * lanc.vlrunitcom)) * 100;

 lanc.qtdparticipovo := ((lanc.qtdovosinc * lanc.percparticipovo) / 100);
 lanc.vlrcom         := lanc.qtdparticipovo * lanc.vlrunitcom;
 lanc.dhalter        := sysdate;
 lanc.codusu         := p_codusu;

 -- insere os valores da referencia
 begin
  delete from ad_tsffcpref r
   where r.codcencus = lanc.codcencus
     and r.dtref = lanc.dtref;
 
  insert into ad_tsffcpref values lanc;
 exception
  when others then
   raise;
 end;

 -- fetch das notas
 select lanc.codcencus, lanc.dtref, cab.nunota, ite.sequencia, cab.numnota, cab.dtneg, ite.codprod,
        case
         when cab.codtipoper in (777) then
          ite.qtdneg * -1
         else
          ite.qtdneg
        end qtdneg, ite.vlrunit, ite.vlrtot
   bulk collect
   into t
   from tgfcab cab, tgfite ite
  where cab.nunota = ite.nunota
    and cab.codtipoper in (332, 777)
    and cab.dtneg >= p_dataini
    and cab.dtneg <= p_datafin
    and cab.codcencus = lanc.codcencus
    and cab.codparc = lanc.codparc
    and ite.codprod = 72124;

 -- Insert das notas
 forall x in t.first .. t.last
  merge into ad_tsffcpnfe p
  using (select t(x).codcencus codcencus,t(x).dtref dtref,t(x).nunota nunota,t(x).sequencia sequencia
           from dual) d
  on (p.nunota = d.nunota and p.sequencia = d.sequencia and p.codcencus = d.codcencus and p.dtref = d.dtref)
  when matched then
   update
      set numnota = t(x).numnota,
          dtneg   = t(x).dtneg,
          codprod = t(x).codprod,
          qtdneg  = t(x).qtdneg,
          vlrunit = t(x).vlrunit,
          vlrtot  = t(x).vlrtot
  when not matched then
   insert values t (x);

 p_mensagem := 'Valores populados com sucesso!';

end;

/
--------------------------------------------------------
--  DDL for Procedure AD_STP_FCP_GETREFTABELA_SF
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "SANKHYA"."AD_STP_FCP_GETREFTABELA_SF" (p_codcencus in number,
                                                       p_dtref     in date,
                                                       p_codtab    out number,
                                                       p_dtreftab  out date,
                                                       p_recoper   out float,
                                                       p_recatrat  out float,
                                                       p_recbonus  out float,
                                                       p_rectotal  out float,
                                                       p_custo     out float) is
begin

 -- busca tabela
 begin
  select distinct c.codtabpos into p_codtab from ad_tsftcpcus c where c.codcencus = p_codcencus;
 exception
  when others then
   raise;
 end;

 -- busca valores da referencia da tabela
 begin
  select r.dtref, r.recoper, r.recatrat, r.recbonus, r.rectotal
    into p_dtreftab, p_recoper, p_recatrat, p_recbonus, p_rectotal
    from ad_tsftcpref r
   where r.codtabpos = p_codtab
     and r.dtref = (select max(dtref)
                      from ad_tsftcpref r2
                     where r2.codtabpos = p_codtab
                       and r2.dtref <= p_dtref);
 exception
  when others then
   raise;
 end;

 begin
  select c.vlrovo
    into p_custo
    from ad_tsftcpovo c
   where c.codtabpos = p_codtab
     and c.dtref = (select max(dtref)
                      from ad_tsftcpovo o2
                     where o2.codtabpos = p_codtab
                       and o2.dtref <= p_dtref);
 exception
  when no_data_found then
   p_custo := 0;
 end;
end;

/
--------------------------------------------------------
--  DDL for Procedure AD_STP_FCP_GERARNOTA_SF
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "SANKHYA"."AD_STP_FCP_GERARNOTA_SF" (p_codusu    number,
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
--------------------------------------------------------
--  DDL for Function AD_FNC_FCP_GETCUSTOAVE_SF
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE FUNCTION "SANKHYA"."AD_FNC_FCP_GETCUSTOAVE_SF" (p_codtab number, p_dtref date) return float
  deterministic as
  v_result float;
begin
  select c.vlrovo
    into v_result
    from ad_tsftcpovo c
   where c.codtabpos = p_codtab
     and c.dtref = (select max(dtref)
                      from ad_tsftcpovo o2
                     where o2.codtabpos = p_codtab
                       and o2.dtref <= p_dtref);

  return v_result;
exception
  when others then
    raise;
end;

/
