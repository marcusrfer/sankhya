create or replace procedure ad_stp_fcr_gera_nota_sf(p_codusu    number,
                                                    p_idsessao  varchar2,
                                                    p_qtdlinhas number,
                                                    p_mensagem  out varchar2) as

  fcr ad_tsffcr%rowtype;
  cfg ad_tsffciconf%rowtype;
  mgn ad_tsfmgn%rowtype;

  v_nufin  number;
  v_dtvenc date;
  v_modelo int;
  i        int;
begin

  /*
  * Autor: M. Rangel
  * Processo: Fechamento da comiss�o da Recria
  * Objetivo: A��o "Gerar notas" da tela de fechamento da comiss�o da recria.
              Tem por objetivo permitir a cria��o dos documentos exigidos pelo
              processo, considerando a quest�o de dentro ou fora da UF GO, permitindo
              escolher entre gerar a nota de compra ou o pedido de compra (no caso do PR).
              As informa��es para a gera��o da nota, como top, natureza, est�o na tela de
              modelos para gera��o de notas (TSFMGN).
  */

  stp_set_atualizando('N');

  if p_qtdlinhas > 1 then
    p_mensagem := 'Selecione apenas 1 registro.';
    return;
  end if;

  select *
    into fcr
    from ad_tsffcr a
   where a.codcencus = act_int_field(p_idsessao, 1, 'CODCENCUS')
     and a.codparc = act_int_field(p_idsessao, 1, 'CODPARC')
     and a.numlote = act_int_field(p_idsessao, 1, 'NUMLOTE');

  -- valida nunota
  if fcr.nunota is not null then
    p_mensagem := 'Comiss�o j� possui nota gerada!';
    return;
  end if;

  -- valida se adiantamentos est�o gerados
  select count(*)
    into i
    from ad_tsffcradt a
   where a.codcencus = fcr.codcencus
     and a.codparc = fcr.codparc
     and a.numlote = fcr.numlote
     and a.nuacerto is null;

  if i > 0 then
    p_mensagem := 'Para a gera��o das notas, � necess�rio que todos os ' ||
                  'adiantamentos tenham sido gerados';
    return;
  end if;

  -- busca set de parametros
  ad_pkg_fci.get_config(trunc(sysdate), cfg);

  /*begin
   select *
     into conf
     from ad_tsffciconf c
    where c.dtvigor = (select max(dtvigor)
                         from ad_tsffciconf c2
                        where c2.nuconf = c.nuconf
                          and c2.dtvigor <= sysdate);
  exception
   when no_data_found then
    p_mensagem := 'Erro ao buscar as configura��o da ' || 'tela de par�metros. ' || sqlerrm;
    return;
  end;*/

  if ad_get.ufparcemp(fcr.codparc, 'P') = ad_get.ufparcemp(fcr.codemp, 'E') then
    v_modelo := cfg.numodcparec;
  else
    v_modelo := cfg.numodpcarec;
  end if;

  begin
    select * into mgn from ad_tsfmgn where numodelo = v_modelo;
  exception
    when others then
      raise;
  end;

  begin
    -- insere cabe�alho
    ad_set.ins_pedidocab(p_codemp      => fcr.codemp,
                         p_codparc     => fcr.codparc,
                         p_codvend     => mgn.codvend,
                         p_codtipoper  => mgn.codtipoper,
                         p_codtipvenda => mgn.codtipvenda,
                         p_dtneg       => trunc(sysdate),
                         p_vlrnota     => fcr.vlrtotreal,
                         p_codnat      => mgn.codnat,
                         p_codcencus   => fcr.codcencus,
                         p_codproj     => 0,
                         p_obs         => 'Fech. Com. Recria - n� lote: ' || fcr.numlote,
                         p_nunota      => fcr.nunota);
    -- insere item
    ad_set.ins_pedidoitens(p_nunota   => fcr.nunota,
                           p_codprod  => mgn.codprod,
                           p_qtdneg   => fcr.participacao,
                           p_codvol   => mgn.codvol,
                           p_codlocal => mgn.codlocal,
                           p_controle => null,
                           p_vlrunit  => fcr.vlrcomave,
                           p_vlrtotal => fcr.vlrtotreal,
                           p_mensagem => p_mensagem);
  
    if p_mensagem is not null then
      return;
    end if;
  
    begin
    
      -- try dia do vencimento fds
      v_dtvenc := add_months(sysdate, 12);
      <<check_dia_vencto>>
      begin
        if to_number(to_char(v_dtvenc, 'd')) in (1, 7) then
          v_dtvenc := v_dtvenc + 1;
          goto check_dia_vencto;
        end if;
      end;
    
      ad_set.ins_financeiro(p_codemp     => fcr.codemp,
                            p_numnota    => 0,
                            p_dtneg      => trunc(sysdate),
                            p_dtvenc     => v_dtvenc,
                            p_codparc    => fcr.codparc,
                            p_top        => mgn.codtipoper,
                            p_contabanco => mgn.codctabcoint,
                            p_codnat     => mgn.codnat,
                            p_codcencus  => fcr.codcencus,
                            p_codproj    => 0,
                            p_codtiptit  => mgn.codtiptit,
                            p_origem     => 'E',
                            p_nunota     => fcr.nunota,
                            p_valor      => fcr.vlrtotreal,
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
  
    -- atualiza dados na origem
  
    stp_set_atualizando('S');
  
    begin
      update ad_tsffcr r
         set r.nunota     = fcr.nunota,
             r.status     = 'F',
             r.statusnota = 'A'
       where r.codcencus = fcr.codcencus
         and r.codparc = fcr.codparc
         and r.numlote = fcr.numlote;
    exception
      when others then
        p_mensagem := sqlerrm;
        return;
    end;
  
    -- confirma pedido de compra
    if nvl(mgn.confauto, 'N') = 'S' then
    
      if act_confirmar('Confirma��o de Nota', 'Deseja confirmar a nota Gerada?', p_idsessao, 1) then
      
        stp_confirmanota_java_sf(fcr.nunota);
      
        --select * into cab from tgfcab where nunota = fcr.nunota;
      
        -- atualiza informa��es na origem
        update ad_tsffcr r
           set r.statusnota = 'L',
               r.dhalter    = sysdate,
               r.codusualt  = p_codusu
         where nunota = fcr.nunota;
      
      end if;
    
    end if;
  
    stp_set_atualizando('N');
  
  end;

  p_mensagem := 'Nota n� �nico ' || '<a title="Clique aqui" target="_parent" href="' ||
                ad_fnc_urlskw('TGFCAB', fcr.nunota) || '">' || fcr.nunota || '</a>' ||
                ' gerada com sucesso!';

end;
/
