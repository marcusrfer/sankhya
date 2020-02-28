create or replace procedure ad_stp_fcp_gerarnota_sf(p_codusu    number,
                                                    p_idsessao  varchar2,
                                                    p_qtdlinhas number,
                                                    p_mensagem  out varchar2) as
  ref ad_tsffcpref%rowtype;
  cfg ad_tsffciconf%rowtype;
  mgn ad_tsfmgn%rowtype;
  top tgftop%rowtype;

  p_tiponota varchar2(1);
  v_numnota  number;
  v_nufin    number;
  v_modelo   int;
  v_confirma boolean default false;

  procedure exclui_movimentacao(p_nunota number) as
  begin
    delete from tgfcab where nunota = p_nunota;
    delete from tgfite where nunota = p_nunota;
    delete from tgfimn where nunota = p_nunota;
    delete from tgfdin where nunota = p_nunota;
    delete from tgffin where nunota = p_nunota;
  end;

begin
  /*
    Autor: MARCUS.RANGEL 20/12/2019 14:39:21
    Processo: Fechamento de Comissão do Integrado - Postura
    Objetivo: Botão de ação "gerar nota" da tela de fechamento 
              de comissão, como diz o nome, o intuito de gerar 
              os documentos da cab, nota ou pedido.
  */

  stp_set_atualizando('N');

  if p_qtdlinhas > 1 then
    p_mensagem := 'Selecione apenas 1 referência.';
    return;
  end if;

  ref.codcencus := act_int_field(p_idsessao, 1, 'CODCENCUS');
  ref.dtref     := act_dta_field(p_idsessao, 1, 'DTREF');
  p_tiponota    := act_txt_param(p_idsessao, 'TIPONOTA');

  begin
    select *
      into ref
      from ad_tsffcpref
     where codcencus = ref.codcencus
       and dtref = ref.dtref;
  exception
    when others then
      p_mensagem := 'Erro ao buscar parâmetro da tela! ' || sqlerrm;
      return;
  end;

  -- valida nunota
  if p_tiponota = 'C' and ref.nunotaent is not null or
     p_tiponota = 'R' and ref.nunotasai is not null then
    p_mensagem := 'Referência já possui nota gerada!';
    return;
  end if;

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

  v_confirma := act_confirmar('Confirmação de Nota',
                              'Deseja confirmar a nota Gerada?',
                              p_idsessao,
                              1);

  -- busca set de parametros
  ad_pkg_fci.get_config(sysdate, cfg);

  -- define modelo de nota

  -- se uf GO
  if ad_get.ufparcemp(ref.codparc, 'P') = ad_get.ufparcemp(1, 'E') then
  
    if p_tiponota = 'R' then
      v_modelo := cfg.numodrempostgo;
    elsif p_tiponota = 'C' then
      v_modelo := cfg.numodcpapost; -- recebe o modelo da nota de compra  
    end if;
  
  else
    -- PR
    if p_tiponota = 'R' then
      v_modelo := cfg.numodrempost;
    elsif p_tiponota = 'C' then
      v_modelo := cfg.numodpcapost; -- recebe o modelo do pedido de compra
    end if;
  
  end if;

  -- busca valores do modelo
  begin
    select * into mgn from ad_tsfmgn m where m.numodelo = v_modelo;
  
    select *
      into top
      from tgftop
     where codtipoper = mgn.codtipoper
       and dhalter = ad_get.maxdhtipoper(mgn.codtipoper);
  exception
    when others then
      p_mensagem := sqlerrm;
      return;
  end;

  -- insere documento  
  declare
    c   varchar2(4000);
    i   varchar2(4000);
    f   varchar2(4000);
    obs varchar2(4000);
  begin
    -- insere cabeçalho
    obs := 'Produção mês ' || to_char(ref.dtref, 'MM/RRRR') || ' - lote ' || ref.numlote;
    c   := '';
    c   := c || '<CODEMP>' || mgn.codemp || '</CODEMP>';
    c   := c || '<CODPARC>' || ref.codparc || '</CODPARC>';
    c   := c || '<CODVEND>' || trim(to_char(mgn.codvend)) || '</CODVEND>';
    c   := c || '<CODTIPOPER>' || mgn.codtipoper || '</CODTIPOPER>';
    c   := c || '<TIPMOV>' || top.tipmov || '</TIPMOV>';
    c   := c || '<CODTIPVENDA>' || mgn.codtipvenda || '</CODTIPVENDA>';
    c   := c || '<SERIENOTA>' || mgn.serienota || '</SERIENOTA>';
    c   := c || '<DTNEG>' || to_char(sysdate, 'dd/mm/yyyy') || '</DTNEG>';
    c   := c || '<VLRNOTA>' || replace(ref.vlrcom, ',', '.') || '</VLRNOTA>';
    c   := c || '<CODNAT>' || mgn.codnat || '</CODNAT>';
    c   := c || '<CODCENCUS>' || ref.codcencus || '</CODCENCUS>';
    c   := c || '<CODPROJ>0</CODPROJ>';
    --c   := c || '<OBSERVACAO><![CDATA[' || obs || ']]></OBSERVACAO>';
    c := c || '<CODUSUINC>' || p_codusu || '</CODUSUINC>';
  
    i := '';
    i := i || '<NUNOTA/>';
    i := i || '<CODPROD>' || mgn.codprod || '</CODPROD>';
    i := i || '<QTDNEG>' || replace(ref.qtdparticipovo, ',', '.') || '</QTDNEG>';
    i := i || '<CODVOL>' || mgn.codvol || '</CODVOL>';
    i := i || '<CODLOCALORIG>' || trim(mgn.codlocal) || '</CODLOCALORIG>';
    i := i || '<VLRUNIT>' || replace(ref.vlrunitcom, ',', '.') || '</VLRUNIT>';
    i := i || '<VLRTOT>' || replace(ref.vlrcom, ',', '.') || '</VLRTOT>';
    i := i || '<CODBENEFNAUF>PR809998</CODBENEFNAUF>';
    i := i || '<USOPROD>P</USOPROD>';
    i := i || '<PERCDESC>0</PERCDESC>';
  
    ad_pkg_apiskw.acao_inserir_nota(p_cab    => c,
                                    p_itens  => i,
                                    p_nunota => ref.nunota,
                                    p_errmsg => p_mensagem);
  
    if p_mensagem is not null then
      exclui_movimentacao(ref.nunota);
      return;
    else
      update tgfcab set observacao = obs where nunota = ref.nunota;
    end if;
  
    -- insere financeiro  
  
    if top.atualfin <> 0 then
    
      begin
        f := '';
        f := f || '<NUNOTA>' || ref.nunota || '</NUNOTA>';
        f := f || '<CODEMP>' || mgn.codemp || '</CODEMP>';
        f := f || '<CODVEND>' || mgn.codvend || '</CODVEND>';
        f := f || '<NUMNOTA>0</NUMNOTA><ORIGEM>E</ORIGEM><PROVISAO>S</PROVISAO>';
        f := f || '<DTNEG>' || to_char(sysdate, 'dd/mm/yyyy') || '</DTNEG>';
        f := f || '<DTVENC>' || to_char(ref.dtvenc, 'dd/mm/yyyy') || '</DTVENC>';
        f := f || '<CODTIPOPER>' || mgn.codtipoper || '</CODTIPOPER>';
        f := f || '<SERIENOTA>' || mgn.serienota || '</SERIENOTA>';
        f := f || '<CODPARC>' || ref.codparc || '</CODPARC>';
        f := f || '<CODBCO>1</CODBCO>';
        f := f || '<CODCTABCOINT>' || mgn.codctabcoint || '</CODCTABCOINT>';
        f := f || '<CODNAT>' || mgn.codnat || '</CODNAT>';
        f := f || '<CODCENCUS>' || ref.codcencus || '</CODCENCUS>';
        f := f || '<CODTIPTIT>' || mgn.codtiptit || '</CODTIPTIT>';
        f := f || '<VLRDESDOB>' || replace(ref.vlrcom, ',', '.') || '</VLRDESDOB>';
        f := f || '<DESDOBRAMENTO>1</DESDOBRAMENTO>';
        f := f || '<RECDESP>-1</RECDESP>';
      
        -- exclui financeiro padrão
        begin
          delete from tgffin where nunota = ref.nunota;
        exception
          when others then
            p_mensagem := 'Erro na geração do Financeiro. ' || sqlerrm;
            exclui_movimentacao(ref.nunota);
            return;
        end;
      
        ad_pkg_apiskw.acao_inserir_financeiro(p_fin    => f,
                                              p_nufin  => v_nufin,
                                              p_errmsg => p_mensagem);
      
        if p_mensagem is not null then
          exclui_movimentacao(ref.nunota);
          return;
        else
          update tgffin f set historico = obs, f.codusu = p_codusu where nunota = ref.nunota;
        end if;
      
      end;
    
    end if;
  
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
      exclui_movimentacao(ref.nunota);
      return;
  end;

  -- cria vinculo externo (usando hash para contornar o problema da PK)
  begin
  
    select ora_hash(concat(ref.codcencus, ref.dtref), 1000000000, 2) into v_numnota from dual;
  
    insert into ad_tblcmf
      (nometaborig, nuchaveorig, nometabdest, nuchavedest)
    values
      ('AD_TSFFCPREF', v_numnota, 'TGFCAB', ref.nunota);
  
  exception
    when others then
      null;
  end;

  -- confirma pedido de compra
  if nvl(mgn.confauto, 'N') = 'S' then
  
    if v_confirma then
    
      commit; -- não remover
    
      ad_pkg_apiskw.acao_confirmar_nota(ref.nunota);
    
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
      end;
    
      -- atualizar informações na origem
      begin
        update ad_tsffcpref r
           set r.statusnfe = ref.statusnfe, r.statuslote = 'F'
         where r.nunota = ref.nunota;
      exception
        when others then
          p_mensagem := 'Erro ao atualizar as informações na origem. ' || sqlerrm;
      end;
    
    else
    
      null;
    
    end if;
  
  end if;

  -- atualiza data ultimo fechamento            
  begin
    update ad_tsffcp p set p.dtultfat = sysdate where p.codcencus = ref.codcencus;
  exception
    when others then
      p_mensagem := 'Erro ao atualizar a data "Último Fechamento". ' || sqlerrm;
  end;

  if p_mensagem is not null then
    p_mensagem := 'Concluído com ressalvas! ' || p_mensagem;
    return;
  end if;

  commit;

  p_mensagem := 'Nota nº Único ' || '<a title="Clique aqui" target="_parent" href="' ||
                ad_fnc_urlskw('TGFCAB', ref.nunota) || '">' || ref.nunota || '</a>' ||
                ' gerada com sucesso!';

end ad_stp_fcp_gerarnota_sf;
/
