create or replace procedure ad_stp_fci_fatura_sf(p_codusu    number,
                                                 p_idsessao  varchar2,
                                                 p_qtdlinhas number,
                                                 p_mensagem  out varchar2) as
  p_tiponota varchar2(4000);
  v_modelo   number;
  v_origem   varchar2(5);
  v_nufin    number;
  lote       ad_tsffci%rowtype;
  conf       ad_tsffciconf%rowtype;
  bnf        ad_tsffcibnf%rowtype;
  cab        tgfcab%rowtype;
  ite        tgfite%rowtype;
  top        tgftop%rowtype;
  stm        varchar2(4000);
  i          int := 0;

  pacote_invalidado exception;
  pragma exception_init(pacote_invalidado, -04061);

begin

  <<inicio>>

  begin
  
    stp_set_atualizando('S');
  
    -- selecionou mais de 1 registro
    if p_qtdlinhas > 1 then
      p_mensagem := 'Selecione apenas um lote para geração de notas.';
      return;
    end if;
  
    -- não selecionou nenhum registro
    if p_qtdlinhas = 0 then
      p_mensagem := 'Selecione pelo menos um lote para geração de notas';
      return;
    end if;
  
    p_tiponota   := act_txt_param(p_idsessao, 'TIPONOTA');
    lote.numlote := act_int_field(p_idsessao, 1, 'NUMLOTE');
  
    if ad_pkg_var.isdebugging then
      p_tiponota   := 'C';
      lote.numlote := 57474;
    end if;
  
    -- get dados lote e configurações
    ad_pkg_fci.get_dados_fechamento(lote.numlote, lote, conf);
  
    -- se lote finalizado
    if lote.statuslote = 'L' then
      p_mensagem := 'Lote já finalizado, não permite edições ou gerações de documentos.';
      return;
    end if;
  
    -- seleciona o modelo de nota de acordo com o parametro
    if p_tiponota = 'C' then
      v_modelo := conf.numodcpafrv;
      v_origem := 'COM';
    elsif p_tiponota = 'V' then
      v_modelo := conf.numodremfrv;
    elsif p_tiponota = 'M' then
      v_modelo := conf.numodmorfrv;
    elsif p_tiponota = 'B' then
      v_modelo := conf.numodbnffrv;
      v_origem := 'BNF';
    end if;
  
    -- get dados modelo
    select m.serienota, m.codvend, m.codtipvenda, m.codcencus, m.codnat,
           m.obspadrao, nvl(m.confauto, 'N'), m.codprod, m.codvol, m.codlocal,
           m.codtipoper
      into cab.serienota, cab.codvend, cab.codtipvenda, cab.codcencus,
           cab.codnat, cab.observacao, cab.confirmnotafat, ite.codprod,
           ite.codvol, ite.codlocalorig, cab.codtipoper
      from ad_tsfmgn m
     where m.numodelo = v_modelo;
  
    -- verifica se nota com a top do modelo consta na aba de notas da tela
    select count(*)
      into i
      from ad_tsffcinf
     where codtipoper = cab.codtipoper
       and numlote = lote.numlote;
  
    if i > 0 then
      p_mensagem := 'Já existe uma nota com essa top na lista de notas emitidas.';
      return;
    end if;
  
    -- get dados top do modelo
    select *
      into top
      from tgftop
     where codtipoper = cab.codtipoper
       and dhalter = ad_get.maxdhtipoper(cab.codtipoper);
  
    -- checa data de vencimento previamente
    begin
      stm := 'Select count(*) from ad_tsffcifin where numlote = :lote ' ||
             'and origem = :origem and dtvenc is null';
      execute immediate stm
        into i
        using lote.numlote, v_origem;
    
      if i > 0 then
        p_mensagem := 'Data de vencimento na aba "Financeiro" não informada.';
        return;
      end if;
    end;
  
    begin
      stm := 'Select count(*) from ad_tsffcifin where numlote = :lote ' ||
             'and origem = :origem and nufin is null';
      execute immediate stm
        into i
        using lote.numlote, v_origem;
    
      if i = 0 and top.atualfin <> 0 then
        p_mensagem := 'Não existem lançamentos pendentes de geração de nota!';
        return;
      end if;
    end;
  
    -- bonificação, valida se há aprovados
    if p_tiponota = 'B' then
    
      select count(*)
        into i
        from ad_tsffcibnf
       where numlote = lote.numlote
         and aprovado = 'S'
         and nunota is null;
    
      if i = 0 then
        p_mensagem := 'Não existem bonificações aprovadase pendentes para geração da nota!';
        return;
      elsif i > 1 then
        p_mensagem := 'Existem mais de 1 bonificação aprovada, o que não é permitido!';
        return;
      end if;
    
      cab.observacao := 'Complemento de comissão / ajuda de custo. Lote nº: ' ||
                        lote.numlote;
    
      -- obtem o valor da bonificação
      begin
        select vlrbonific
          into cab.vlrnota
          from ad_tsffcibnf
         where numlote = lote.numlote
           and aprovado = 'S';
      exception
        when no_data_found then
          p_mensagem := 'Valor unitário da bonificação não encontrado!';
          return;
        when too_many_rows then
          p_mensagem := 'Existem mais de uma bonificação aprovada!';
          return;
      end;
    
      ite.codprod := case
                       when lote.tipopreco = 'F' then
                        ad_pkg_fci.c_prodfemeabnf
                       when lote.tipopreco = 'M' then
                        ad_pkg_fci.c_prodmachobnf
                       when lote.tipopreco = 'X' then
                        ad_pkg_fci.c_prodsexadobnf
                     end;
    
      ite.qtdneg  := 1;
      ite.vlrunit := cab.vlrnota;
    
    elsif p_tiponota = 'C' then
    
      ite.codprod := case
                       when lote.tipopreco = 'F' then
                        ad_pkg_fci.c_prodfemeabnf
                       when lote.tipopreco = 'M' then
                        ad_pkg_fci.c_prodmachobnf
                       when lote.tipopreco = 'X' then
                        ad_pkg_fci.c_prodsexadobnf
                     end;
    
      ite.qtdneg  := lote.pesocom;
      ite.vlrunit := lote.vlrunit;
      cab.vlrnota := lote.pesocom * lote.vlrunit;
    
    elsif p_tiponota = 'V' then
      ite.codprod := case
                       when lote.tipopreco = 'F' then
                        ad_pkg_fci.c_codprodfemea
                       when lote.tipopreco = 'M' then
                        ad_pkg_fci.c_codprodmacho
                       when lote.tipopreco = 'X' then
                        ad_pkg_fci.c_codprodsexado
                     end;
    
      ite.qtdneg  := lote.pesocom;
      ite.vlrunit := lote.vlrunit;
      cab.vlrnota := lote.pesocom * lote.vlrunit;
    
    elsif p_tiponota = 'M' then
      ite.codprod := case
                       when lote.tipopreco = 'F' then
                        ad_pkg_fci.c_mortfemea
                       when lote.tipopreco = 'M' then
                        ad_pkg_fci.c_mortmacho
                       when lote.tipopreco = 'X' then
                        ad_pkg_fci.c_mortsexado
                     end;
    
      with dados as
       (select i.nunota, c.dtfatur, i.codprod, i.vlrunit
          from tgfite i
          join tgfcab c
            on i.nunota = c.nunota
         where 1 = 1
           and c.codparc = lote.codparc
           and c.dtfatur between lote.dtaloj and lote.dtsaida
           and c.codtipoper = 195
           and i.codprod = ite.codprod
           and i.sequencia > 0),
      maxdate as
       (select min(dtfatur) dtfatur from dados)
      select nunota, vlrunit
        into cab.observacao, ite.vlrunit
        from dados d
        join maxdate md
          on md.dtfatur = d.dtfatur;
    
      cab.observacao := 'Ref. Nota Transf. Interna nº único: ' ||
                        cab.observacao;
      ite.qtdneg     := lote.qtdmortes;
      cab.vlrnota    := ite.qtdneg * ite.vlrunit;
    end if;
    -- insere cabeçalho do pedido/nota
    begin
      ad_set.ins_pedidocab(p_codemp      => lote.codemp,
                           p_codparc     => lote.codparc,
                           p_codvend     => cab.codvend,
                           p_codtipoper  => cab.codtipoper,
                           p_codtipvenda => cab.codtipvenda,
                           p_dtneg       => trunc(sysdate),
                           p_vlrnota     => cab.vlrnota,
                           p_codnat      => cab.codnat,
                           p_codcencus   => cab.codcencus,
                           p_codproj     => 0,
                           p_obs         => cab.observacao,
                           p_nunota      => cab.nunota);
    
      update tgfcab
         set serienota      = cab.serienota,
             dtfatur        = trunc(sysdate),
             confirmnotafat = cab.confirmnotafat
       where nunota = cab.nunota;
    
    end;
  
    -- insere itens
    begin
      ad_set.ins_pedidoitens(p_nunota   => cab.nunota,
                             p_codprod  => ite.codprod,
                             p_qtdneg   => ite.qtdneg,
                             p_codvol   => ite.qtdvol,
                             p_codlocal => ite.codlocalorig,
                             p_controle => ite.controle,
                             p_vlrunit  => ite.vlrunit,
                             p_vlrtotal => ite.vlrunit * ite.qtdneg,
                             p_mensagem => p_mensagem);
    
      if p_mensagem is not null then
        return;
      end if;
    
      begin
        update tgfite i
           set i.ad_nloteavec = lote.numlote
        --i.codcfo       = ite.codcfo
         where i.nunota = cab.nunota;
      exception
        when others then
          p_mensagem := 'Erro ao atualizar dados no item do pedido/nota. ' ||
                        sqlerrm;
          return;
      end;
    
    end;
  
    -- insere financeiro
    if top.atualfin <> 0 then
      begin
        stp_set_atualizando('S');
        for cfin in (select *
                       from ad_tsffcifin
                      where numlote = lote.numlote
                        and origem = v_origem)
        loop
          ad_set.ins_financeiro(p_codemp     => lote.codemp,
                                p_numnota    => nvl(cab.numnota, 0),
                                p_dtneg      => trunc(sysdate),
                                p_dtvenc     => cfin.dtvenc,
                                p_codparc    => lote.codparc,
                                p_top        => cab.codtipoper,
                                p_contabanco => 1,
                                p_codnat     => cab.codnat,
                                p_codcencus  => cab.codcencus,
                                p_codproj    => 0,
                                p_codtiptit  => cfin.codtiptit,
                                p_origem     => 'E',
                                p_nunota     => cab.nunota,
                                p_valor      => cfin.vlrdesdob,
                                p_nufin      => v_nufin,
                                p_errmsg     => p_mensagem);
        
          update tgffin set historico = cab.observacao where nufin = v_nufin;
        
          update ad_tsffcifin f
             set f.nufin = v_nufin
           where f.numlote = lote.numlote
             and f.nufcifin = cfin.nufcifin;
        
          if p_mensagem is not null then
            return;
          end if;
        
          update ad_tsffcifin f
             set f.nufin = v_nufin
           where f.numlote = cfin.numlote
             and f.nufcifin = cfin.nufcifin;
        
        end loop;
      
        stp_set_atualizando('N');
      
      exception
        when others then
          p_mensagem := 'Erro ao gerar/atualizar o financeiro. ' || sqlerrm;
          return;
      end;
    
    end if;
  
    if p_tiponota = 'B' then
      -- atualiza informações na bonificação
      begin
        stp_set_atualizando('S');
        update ad_tsffcibnf b
           set b.nunota = cab.nunota
         where numlote = lote.numlote
           and aprovado = 'S';
      
        update ad_tsffci f
           set f.statusbonif = 'F',
               f.codusualter = p_codusu,
               f.dhalter     = sysdate
         where f.numlote = lote.numlote;
        stp_set_atualizando('N');
      exception
        when others then
          p_mensagem := 'Erro ao atualizar as informações na bonificação aprovada. ' ||
                        sqlerrm;
          rollback;
          return;
      end;
    
    else
    
      -- atualiza detalhes no lote
      begin
        stp_set_atualizando('S');
        update ad_tsffci f
           set f.statuslote  = 'F',
               f.codusualter = p_codusu,
               f.dhalter     = sysdate
         where f.numlote = lote.numlote;
        stp_set_atualizando('N');
      exception
        when others then
          p_mensagem := 'Erro ao atualizar status do lote! ' || sqlerrm;
          rollback;
          return;
      end;
    
    end if;
  
    -- insere as notas no lote sendo fechado
    begin
      stp_set_atualizando('S');
      delete from ad_tsffcinf where nunota = cab.nunota;
    
      select * into cab from tgfcab where nunota = cab.nunota;
    
      select max(nufcinf) + 1
        into i
        from ad_tsffcinf
       where numlote = lote.numlote;
    
      insert into ad_tsffcinf
        (numlote, nufcinf, codemp, nunota, nufin, numnota, serienota, dtneg,
         dtfatur, vlrnota, codtipoper, tipmov, statusnota, statusnfe, qtdneg)
      values
        (lote.numlote, i, lote.codemp, cab.nunota, v_nufin, cab.numnota,
         cab.serienota, cab.dtneg, cab.dtneg, cab.vlrnota, cab.codtipoper,
         top.tipmov, 'A', cab.statusnfe, ite.qtdneg);
      stp_set_atualizando('N');
    exception
      when others then
        p_mensagem := 'Erro ao inserir a nota gerada na aba "Notas" do lote. ' ||
                      sqlerrm;
        rollback;
        return;
    end;
  
    -- insert na tabela de ligação
    begin
      insert into ad_tblcmf
        (nometaborig, nuchaveorig, nometabdest, nuchavedest)
      values
        ('AD_TSFFCI', lote.numlote, 'TGFCAB', cab.nunota);
    exception
      when others then
        p_mensagem := 'Erro ao atulizar tabela de ligação. ' || sqlerrm;
        rollback;
        return;
    end;
  
    -- controle de notas emitidas e confirmadas
    declare
      qtd_emit int := 0;
      qtd_conf int := 0;
    begin
      select count(*)
        into qtd_emit
        from ad_tsffcinf nf
       where nf.numlote = lote.numlote;
    
      select count(*)
        into qtd_conf
        from ad_tsffcinf nf
       where nf.numlote = lote.numlote
         and nf.statusnota = 'L';
    
      if qtd_emit = qtd_conf then
        begin
          stp_set_atualizando('S');
          update ad_tsffci set statuslote = 'L' where numlote = lote.numlote;
          stp_set_atualizando('N');
        exception
          when others then
            p_mensagem := 'Erro ao atualizar o status do lote. ' || sqlerrm;
            return;
        end;
      end if;
    
    end;
  
    p_mensagem := 'Nota nº único ' ||
                  '<a title="Clique aqui" target="_parent" href="' ||
                  ad_fnc_urlskw('TGFCAB', cab.nunota) || '">' || cab.nunota ||
                  '</a>' || ' gerada com sucesso!';
  
    if p_tiponota in ('V', 'M') then
    
      if nvl(cab.confirmnotafat, 'N') = 'S' then
        if not act_confirmar('Confirmação de Nota',
                             'Deseja confirmar a nota Gerada?',
                             p_idsessao,
                             1) then
          return;
        else
          commit;
          stp_confirmanota_java_sf(cab.nunota);
        
          select * into cab from tgfcab where nunota = cab.nunota;
        
          stp_set_atualizando('S');
          update ad_tsffcinf
             set numnota    = cab.numnota,
                 statusnota = cab.statusnota,
                 statusnfe  = cab.statusnfe
           where nunota = cab.nunota;
          stp_set_atualizando('N');
        end if;
      end if;
    end if;
  
    stp_set_atualizando('N');
  
  exception
    when pacote_invalidado then
      goto inicio;
  end;

end;
/
