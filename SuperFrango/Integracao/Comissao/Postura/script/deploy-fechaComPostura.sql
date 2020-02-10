--------------------------------------------------------
--  DDL for Trigger AD_TRG_CMP_TSFFCPREF_SF
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE TRIGGER "SANKHYA"."AD_TRG_CMP_TSFFCPREF_SF" 
  for insert or update or delete on ad_tsffcpref
  compound trigger

  before each row is
    e  varchar2(4000);
    cd int := 5;
  begin
  
    if inserting then
    
      if not stp_get_atualizando then
        e := 'Utilize o botão de ação "Buscar Dados" para ' ||
             'inserir dados nesse formulário';
        raise_application_error(-20105, ad_fnc_formataerro(e));
      else
        null;
      end if;
    
    elsif updating then
    
      if (:old.nunotaent is not null or :old.nunotasai is not null) and
         (:new.nunotaent is null or :new.nunotaent is null) then
        :new.statuslote := 'A';
      end if;
    
      if (:old.nunotaent is null or :old.nunotasai is null) and
         (:new.nunotaent is not null or :new.nunotaent is not null) then
        :new.statuslote := 'F';
      end if;
    
      if :new.nunotaent is not null and :new.nunotasai is not null then
        :new.statuslote := 'L';
      end if;
    
      /* recalcula valores */
    
      --- receita bonus checklist
      if :new.vlrcomclist > 0 and :new.pontuacao > 0 then
        :new.recbonus := round(:new.vlrcomclist * (:new.pontuacao / 100), cd);
      end if;
    
      -- total comissão por ave
      :new.totcomave := round(:new.recbonus + :new.vlrcomfixa +
                              :new.vlrcomatrat,
                              cd);
    
      -- percentual de participacao
      if nvl(:new.qtdovosinc, 0) > 0 then
        :new.percparticipovo := round(:new.qtdovosinc * :new.totcomave, cd) /
                                round(:new.qtdovosinc * :new.vlrunitcom, cd) * 100;
      
        :new.qtdparticipovo := round((:new.qtdovosinc * :new.percparticipovo) / 100,
                                     cd);
      else
        :new.percparticipovo := 0;
        :new.qtdparticipovo  := 0;
      end if;
    
      -- comissão    
      :new.vlrcom := round(:new.qtdparticipovo * :new.vlrunitcom, 2);
    
      -- o lote será finalizado pela confirmação do nunota
      /* if :new.statusnfe in ('A', 'D') then
        :new.statuslote := 'L';
      end if;*/
    
      -- se está alterando mas não o nunota
      if not updating('STATUSLOTE') and not updating('NUNOTAENT') and
         not updating('NUNOTASAI') and :old.statuslote = 'L' then
        e := ad_fnc_formataerro('Erro! Lote já possui notas geradas,' ||
                                ' alterações não são permitidas!');
        raise_application_error(-20105, e);
      end if;
    
      begin
        update ad_tsffcp p
           set p.codusualter = stp_get_codusulogado,
               p.dhalter     = sysdate
         where p.codcencus = :new.codcencus;
      exception
        when others then
          raise;
      end;
    
    elsif deleting then
      if :old.nunota is not null then
        e := ad_fnc_formataerro('Erro! Já possui nota gerada!');
        raise_application_error(-20105, e);
      end if;
    
    end if;
  
  end before each row;

end;

/
ALTER TRIGGER "SANKHYA"."AD_TRG_CMP_TSFFCPREF_SF" ENABLE;
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

  p_tiponota varchar2(1);
  v_numnota  number;
  v_nufin    number;
  v_modelo   int;

begin

  /*
    Autor: MARCUS.RANGEL 20/12/2019 14:39:21
    Processo: Fechamento de ComissÃ£o do Integrado - Postura
    Objetivo: BotÃ£o de aÃ§Ã£o "gerar nota" da tela de fechamento 
              de comissÃ£o, como diz o nome, o intuito Ã© gerar 
              os documentos da cab, nota ou pedido.
  */

  if p_qtdlinhas > 1 then
    p_mensagem := 'Selecione apenas 1 referência.';
    return;
  end if;

  ref.codcencus := act_int_field(p_idsessao, 1, 'CODCENCUS');
  ref.dtref     := act_dta_field(p_idsessao, 1, 'DTREF');
  p_tiponota    := act_txt_param(p_idsessao, 'TIPONOTA');

  select *
    into ref
    from ad_tsffcpref
   where codcencus = ref.codcencus
     and dtref = ref.dtref;

  -- valida nunota
  if p_tiponota = 'C' and ref.nunotaent is not null or
     p_tiponota = 'R' and ref.nunotasai is not null then
    p_mensagem := 'Referência já possui nota gerada!';
    return;
  end if;
  /*if ref.nunota is not null then
    p_mensagem := 'Referência já possui nota gerada!';
    return;
  end if;*/

  -- valida quantidade de ovos 
  if ref.qtdovosinc != ref.qtdovosgrj then
    --p_mensagem := 'Quantidade de ovos inconsistente.';
    if not act_confirmar(p_titulo    => 'Geração de Notas Postura',
                         p_texto     => 'Quantidade Insconsistentes, deseja gerar assim mesmo?',
                         p_chave     => p_idsessao,
                         p_sequencia => 0) then
      return;
    end if;
  end if;

  -- busca set de parametros
  ad_pkg_fci.get_config(sysdate, cfg);

  if p_tiponota = 'R' then
  
    v_modelo := cfg.numodrempost;
  
  elsif p_tiponota = 'C' then
  
    -- se uf GO
    if ad_get.ufparcemp(ref.codparc, 'P') = ad_get.ufparcemp(ref.codemp, 'E') then
      v_modelo := cfg.numodcpapost; -- recebe o modelo da nota de compra
    else
      v_modelo := cfg.numodpcapost; -- recebe o modelo do pedido de compra
    end if;
  
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
    -- insere cabeÃ§alho
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
                         p_obs         => 'Produção mês ' ||
                                          to_char(ref.dtref, 'MM/RRRR') ||
                                          ' - lote ' || ref.numlote,
                         p_nunota      => ref.nunota);
  
    update tgfcab set serienota = mgn.serienota where nunota = ref.nunota;
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
       set /*r.nunota     = ref.nunota,*/ r.statuslote = 'F',
           r.nunotasai = case
                           when p_tiponota = 'R' then
                            ref.nunota
                           else
                            nunotasai
                         end,
           r.nunotaent = case
                           when p_tiponota = 'C' then
                            ref.nunota
                           else
                            nunotaent
                         end
     where r.codcencus = ref.codcencus
       and r.dtref = ref.dtref;
  exception
    when others then
      p_mensagem := sqlerrm;
      return;
  end;

  -- cria vinculo externo (usando hash para contornar o problema da PK)
  begin
  
    select ora_hash(concat(ref.codcencus, ref.dtref), 1000000000, 2)
      into v_numnota
      from dual;
  
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
  
    if act_confirmar('Confirmação de Nota',
                     'Deseja confirmar a nota Gerada?',
                     p_idsessao,
                     1) then
      commit;
      stp_confirmanota_java_sf(ref.nunota);
    
      -- experimental
      /**
      * remover caso necessite diminuir o runtime
      * a ideia é esperar antes de buscar o status da nfe, na esperanÃ§a
      * de trazer um status com alguma informaÃ§Ã£o retornada da sefaz
      **/
    
      dbms_lock.sleep(5);
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
        select c.statusnfe
          into ref.statusnfe
          from tgfcab c
         where c.nunota = ref.nunota;
      exception
        when others then
          p_mensagem := 'Erro ao buscar o status da NFE da nota ' || ref.nunota;
          return;
      end;
    
      -- atualiza informaÃ§Ãµes na origem
      begin
        update ad_tsffcpref r
           set r.statusnfe  = ref.statusnfe,
               r.statuslote = 'F'
         where r.nunota = ref.nunota;
      exception
        when others then
          p_mensagem := 'Erro ao atualizar as informações na origem. ' ||
                        sqlerrm;
          return;
      end;
    
    end if;
  
  end if;

  -- atualiza data ultimo fechamento            
  begin
    update ad_tsffcp p
       set p.dtultfat = sysdate
     where p.codcencus = ref.codcencus;
  exception
    when others then
      p_mensagem := 'Erro ao atualizar a data "Último Fechamento". ' || sqlerrm;
      return;
  end;

  p_mensagem := 'Nota nº Único ' ||
                '<a title="Clique aqui" target="_parent" href="' ||
                ad_fnc_urlskw('TGFCAB', ref.nunota) || '">' || ref.nunota ||
                '</a>' || ' gerada com sucesso!';

end;

/
--------------------------------------------------------
--  DDL for Procedure AD_STP_FCP_GETDATA_SF
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "SANKHYA"."AD_STP_FCP_GETDATA_SF" (p_codusu    number,
                                                  p_idsessao  varchar2,
                                                  p_qtdlinhas number,
                                                  p_mensagem  out varchar2) as

  --p_dataini  date;
  --p_datafin  date;
  v_confirma boolean;
  --v_dreftab  date;

  type tab_notas is table of ad_tsffcpnfe%rowtype;
  t tab_notas;

  lanc ad_tsffcpref%rowtype;
  conf ad_tsftcpref%rowtype;

  cd int := 5;
  i  int;

begin

  /*
  * Autor: M. Rangel
  * Processo: Fechamento de Comissão Integrado - Postura
  * Objetivo: Ler os dados da tabela, popular e calcular os campos da tela de 
              fechamento da comissão postura
  */
  lanc.codcencus   := act_int_field(p_idsessao, 0, 'MASTER_CODCENCUS');
  lanc.codemp      := to_number(act_txt_param(p_idsessao, 'CODEMP'));
  lanc.codtabpos   := to_number(act_txt_param(p_idsessao, 'CODTAB'));
  lanc.numlote     := act_int_param(p_idsessao, 'NUMLOTE');
  lanc.pontuacao   := act_int_param(p_idsessao, 'PONTUACAO');
  lanc.dtvenc      := act_dta_param(p_idsessao, 'DTVENC');
  lanc.param_dtini := act_dta_param(p_idsessao, 'DATAINI');
  lanc.param_dtfim := act_dta_param(p_idsessao, 'DATAFIN');

  if ad_pkg_var.isdebugging then
    lanc.codcencus   := 110800301;
    lanc.codemp      := 1;
    lanc.codtabpos   := 2;
    lanc.numlote     := 33;
    lanc.pontuacao   := 98;
    lanc.dtvenc      := '06/02/2020';
    lanc.param_dtini := '01/01/2020';
    lanc.param_dtfim := '31/01/2020';
  end if;

  if lanc.pontuacao is null then
    lanc.pontuacao := 0;
  end if;

  select count(*)
    into i
    from ad_tsftcpcus c
   where c.codtabpos = lanc.codtabpos
     and c.codcencus = lanc.codcencus;

  if i = 0 then
    p_mensagem := 'Essa tabela não pode ser utilizada com este CR!';
    return;
  end if;

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

  lanc.dtref      := add_months(trunc(sysdate, 'fmmm'), -1);
  lanc.statuslote := 'A';

  select count(*)
    into i
    from ad_tsffcpref r
   where r.codcencus = lanc.codcencus
     and r.dtref = lanc.dtref;

  if i > 0 then
    p_mensagem := 'já existe cálculo para essa referência! ' ||
                  'Exclua a mesma e refaça os cálculos.';
    return;
    /*begin
      delete from ad_tsffcpref
       where codcencus = lanc.codcencus
         and dtref = lanc.dtref;
    exception
      when others then
        p_mensagem := 'Erro ao substituir lançamento existente. ' || sqlerrm;
        return;
    end;*/
  end if;

  -- busca o parceiro pelo centro d resultados
  begin
    select codparc
      into lanc.codparc
      from tgfpar p
     where p.ad_codcencus = lanc.codcencus;
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
  
    select r.dtref, r.recoper, r.recatrat, r.recbonus, r.rectotal
      into lanc.dtreftab, lanc.vlrcomfixa, lanc.vlrcomatrat, lanc.vlrcomclist,
           lanc.totcomfixa
      from ad_tsftcpref r
     where r.codtabpos = lanc.codtabpos
       and r.dtref = (select max(dtref)
                        from ad_tsftcpref r2
                       where r2.codtabpos = lanc.codtabpos
                         and r2.dtref <= lanc.dtref);
  
    select c.vlrovo
      into lanc.vlrunitcom
      from ad_tsftcpovo c
     where c.codtabpos = lanc.codtabpos
       and c.dtref = (select max(dtref)
                        from ad_tsftcpovo o2
                       where o2.codtabpos = lanc.codtabpos
                         and o2.dtref <= lanc.dtref);
  
  exception
    when others then
      p_mensagem := 'Erro ao buscar os valores da referencia da tabela. ' ||
                    sqlerrm;
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
      from tgfcab cab, tgfite ite, tgfpro pro
     where cab.nunota = ite.nunota
       and ite.codprod = pro.codprod
       and cab.codtipoper in (332, 777)
       and cab.dtneg >= lanc.param_dtini
       and cab.dtneg <= lanc.param_dtfim
       and cab.codcencus = lanc.codcencus
       and cab.codparc = lanc.codparc
       and pro.descrprod like ('OVOS INCUBAVEIS%')
    --and ite.codprod = 72124
    ;
  exception
    when others then
      p_mensagem := 'Erro ao buscar a quantidade de ovos incubaveis no incubatório. ' ||
                    sqlerrm;
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
      from tgfcab cab, tgfite ite, tgfpro pro
     where cab.nunota = ite.nunota
       and pro.codprod = ite.codprod
       and cab.codtipoper in (197, 777)
       and cab.dtneg >= lanc.param_dtini
       and cab.dtneg <= lanc.param_dtfim
       and cab.codcencus = lanc.codcencus
       and ite.sequencia > 0
          --and ite.codprod = 72124
       and pro.descrprod like ('OVOS INCUBAVEIS%');
  exception
    when others then
      p_mensagem := 'Erro ao buscar a quantidade de ovos incubaveis na granja. ' ||
                    sqlerrm;
      return;
  end;

  if lanc.qtdovosinc is null then
    lanc.qtdovosinc := 0;
  end if;

  if lanc.qtdovosgrj is null then
    lanc.qtdovosgrj := 0;
  end if;

  lanc.nunota    := null;
  lanc.statusnfe := null;

  if nvl(lanc.vlrcomclist, 0) > 0 and nvl(lanc.pontuacao, 0) > 0 then
    lanc.recbonus := round(lanc.vlrcomclist * (lanc.pontuacao / 100), cd);
  else
    lanc.recbonus := 0;
  end if;

  lanc.totcomave := round(lanc.recbonus + lanc.vlrcomfixa + lanc.vlrcomatrat,
                          cd);

  if nvl(lanc.qtdovosinc, 0) > 0 then
    lanc.percparticipovo := round(lanc.qtdovosinc * lanc.totcomave, cd) /
                                  round(lanc.qtdovosinc * lanc.vlrunitcom, cd) * 100;
  
    lanc.qtdparticipovo := round((lanc.qtdovosinc * lanc.percparticipovo) / 100,
                                 cd);
  else
    lanc.percparticipovo := 0;
    lanc.qtdparticipovo  := 0;
  end if;

  lanc.vlrcom := round(lanc.qtdparticipovo * lanc.vlrunitcom, 2);

  lanc.dhalter := sysdate;
  lanc.codusu  := p_codusu;

  -- insere os valores da referencia
  begin
    stp_set_atualizando('S');
    delete from ad_tsffcpref r
     where r.codcencus = lanc.codcencus
       and r.dtref = lanc.dtref;
  
    insert into ad_tsffcpref values lanc;
    stp_set_atualizando('N');
  exception
    when others then
      raise;
  end;

  -- fetch das notas
  select cab.nunota, ite.sequencia, lanc.codcencus, lanc.dtref, cab.numnota,
         cab.dtneg, ite.codprod,
         case
           when cab.codtipoper in (777) then
            ite.qtdneg * -1
           else
            ite.qtdneg
         end qtdneg, ite.vlrunit, ite.vlrtot
    bulk collect
    into t
    from tgfcab cab, tgfite ite, tgfpro pro
   where cab.nunota = ite.nunota
     and pro.codprod = ite.codprod
     and cab.codtipoper in (332, 777)
     and cab.dtneg >= lanc.param_dtini
     and cab.dtneg <= lanc.param_dtfim
     and cab.codcencus = lanc.codcencus
     and cab.codparc = lanc.codparc
        --and ite.codprod = 72124
     and pro.descrprod like ('OVOS INCUBAVEIS%');

  -- Insert das notas
  stp_set_atualizando('S');
  forall x in t.first .. t.last
    merge into ad_tsffcpnfe p
    using (select t(x).codcencus codcencus,t(x).dtref dtref,t(x).nunota nunota,
                  t(x).sequencia sequencia
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

  stp_set_atualizando('N');

  p_mensagem := 'Valores populados com sucesso!';

end;

/
--------------------------------------------------------
--  DDL for Procedure AD_STP_FCP_GETREFTABELA_SF
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "SANKHYA"."AD_STP_FCP_GETREFTABELA_SF" (p_codcencus in number,
                                                       p_dtref     in date,
                                                       p_sexo      in varchar2 default null,
                                                       p_codtab    out number,
                                                       p_dtreftab  out date,
                                                       p_recoper   out float,
                                                       p_recatrat  out float,
                                                       p_recbonus  out float,
                                                       p_rectotal  out float,
                                                       p_custo     out float) is
  e varchar2(4000);
begin

  /*
  ** autor: m. rangel
  ** processo: fechamento comissão integrado recria e postura 
  ** objetivo: retornar os valores da tabela de comissões de acordo 
               com sexo e referência
  */

  -- busca tabela
  begin
    select distinct c.codtabpos
      into p_codtab
      from ad_tsftcp p
      join ad_tsftcpcus c
        on c.codtabpos = p.codtabpos
     where c.codcencus = p_codcencus
       and nvl(p.sexo, 'N') = nvl(p_sexo, 'N');
  exception
    when others then
      e := ad_fnc_formataerro('Erro! Tabela de preços não encontrada para o CR ' ||
                              p_codcencus);
      raise_application_error(-20105, e);
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
    when no_data_found then
      e := ad_fnc_formataerro('Erro! Valores não encontrado nessa referência');
      raise_application_error(-20105, e);
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
