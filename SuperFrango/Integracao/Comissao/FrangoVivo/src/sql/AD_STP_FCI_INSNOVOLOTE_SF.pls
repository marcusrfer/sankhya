create or replace procedure ad_stp_fci_insnovolote_sf(p_codusu    number,
                                                      p_idsessao  varchar2,
                                                      p_qtdlinhas number,
                                                      p_mensagem  out varchar2) as
 p_nrolote number;
 confirma  boolean;
 i         int := 0;

 pacote_invalido exception;

 pragma exception_init(pacote_invalido, -04061);

 procedure apaga_tudo(p_nrolote number) as
 begin
  delete from ad_tsffcinf where numlote = p_nrolote;
  delete from ad_tsffcifin where numlote = p_nrolote;
  delete from ad_tsffcibnf where numlote = p_nrolote;
 end;

begin
 -- Autor: M. Rangel
 -- Processo: Fechamento de Comiss?o Integrado - Frango Vivo
 -- Objetivo: Popular os dados na tela de comiss?o;
 
 <<inicio>>
 begin
  p_nrolote := act_int_param(p_idsessao, 'NROLOTE');
  --p_nrolote := act_int_field(p_idsessao,1,'NUMLOTE');
 
  select count(*)
    into i
    from lote_ave
   where numlote = p_nrolote
     and status = 'F';
 
  if i = 0 then
   p_mensagem := 'Lote n�o existe, n�o est� fechado ou n�o foi importado!';
   return;
  end if;
 
  select count(*) into i from ad_tsffci where numlote = p_nrolote;
 
  -- valida duplicidade
  if i > 1 then
   confirma := act_confirmar(p_titulo    => 'Lote duplicado',
                             p_texto     => 'J� existe um fechamento para este lote, gostaria de atualiz�-lo?',
                             p_chave     => p_idsessao,
                             p_sequencia => 1);
  
   if confirma then
    apaga_tudo(p_nrolote);
   else
    return;
   end if;
  
  end if;
 
  variaveis_pkg.v_atualizando := true;
 
  -- insere dados do lote
  begin
   ad_pkg_fci.set_dados_lote(p_nrolote, p_mensagem);
   if p_mensagem is not null then
    p_mensagem := 'Erro ao inserir lote. ' || p_mensagem;
    stp_set_atualizando('N');
    return;
   end if;
  end;
 
  -- insere os dados do financeiro
  begin
   ad_pkg_fci.set_dados_financeiro(p_nrolote, p_mensagem);
   if p_mensagem is not null then
    p_mensagem := 'Erro ao inserir parcelas. ' || p_mensagem;
    stp_set_atualizando('N');
    return;
   end if;
  end;
 
  -- insere os movimentos de notas
  begin
   ad_pkg_fci.set_dados_notas(p_nrolote, p_mensagem);
   if p_mensagem is not null then
    p_mensagem := 'Erro ao inserir notas. ' || p_mensagem;
    stp_set_atualizando('N');
    return;
   end if;
  end;
 
  begin
   update ad_tsffci i
      set i.dhalter     = sysdate,
          i.codusualter = p_codusu
    where numlote = p_nrolote;
  exception
   when others then
    apaga_tudo(p_nrolote);
    p_mensagem := 'Erro ao atualizar o registro. ' || sqlerrm;
    return;
  end;
 
  stp_set_atualizando('N');
  
  --javascript:openApp(''br.com.sankhya.menu.adicional.AD_TSFFCI'',{''NUMLOTE'': '||p_nrolote||'})'
  --'javascript:void(0)" onclick="openApp(''br.com.sankhya.menu.adicional.AD_TSFFCI'',{''NUMLOTE'': '||p_nrolote||'})"'
 
 p_mensagem := 'Confirmada a importa��o e calculo do lote nro ' || p_nrolote || '.' ||
                '<br>Clique <a title="Posicionar registro" target="_parent" href="' ||
                --ad_fnc_urlskw('AD_TSFFCI', p_nrolote)
                'javascript:workspace.openAppActivity(''br.com.sankhya.menu.adicional.AD_TSFFCI'','||
                '{NUMLOTE : '||p_nrolote||'})'
                ||'"><font color="#0000FF"><b> Aqui' ||
                '</b></font></a> para posicionar o registro.';
                
  --p_mensagem := 'Os c�lculos para o lote '||p_nrolote||' foram realizados com sucesso!';
  
 exception
  when pacote_invalido then
   goto inicio;
 end;

end;