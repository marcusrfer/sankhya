create or replace procedure ad_stp_fci_calcbonifica_sf(p_codusu    number,
                                                       p_idsessao  varchar2,
                                                       p_qtdlinhas number,
                                                       p_mensagem  out varchar2) as
  p_tipobonif varchar2(4000);
  p_vlrcusto  float;
  --p_vlrbnfpinto float;
  p_vlrmedcom  float;
  p_sem1       number;
  p_sem2       number;
  p_sem3       number;
  p_sem4       number;
  v_qtdmortsem number;
  v_confirma   boolean;
  lote         lote_ave%rowtype;
  l            ad_tsffci%rowtype;
  b            ad_tsffcibnf%rowtype;
  c            ad_tsffciconf%rowtype;
  t            ad_tsftci%rowtype;
  i            int;

  pacote_invalido exception;
  pragma exception_init(pacote_invalido, -04061);
  --pragma exception_init(pacote_invalido, -06512);
begin

  /*
   Autor: M. Rangel
   Processo: Fechamento de comissao do Integrado - Frango Vivo
   Objetivo: Calcular as diversas possibilidades de bonifica��es
  */

  /* Log de altera��es 
   15/01/2020 - mrangel - remo��o do par�metro vlrbnfpinto
  
  */

  stp_set_atualizando('S');

  <<inicio>>
  begin
  
    if p_qtdlinhas > 1 then
      p_mensagem := 'Selecione apenas 1 lote por vez';
      return;
      rollback;
    end if;
  
    l.numlote   := act_int_field(p_idsessao, 1, 'NUMLOTE');
    p_tipobonif := act_txt_param(p_idsessao, 'TIPOBONIF');
    p_vlrcusto  := act_dec_param(p_idsessao, 'VLRCUSTO');
    --  p_vlrbnfpinto := act_dec_param(p_idsessao, 'VLRBNFPINTO');
    p_vlrmedcom := act_dec_param(p_idsessao, 'VLRMEDCOM');
    p_sem1      := act_int_param(p_idsessao, 'QTDMORT1');
    p_sem2      := act_int_param(p_idsessao, 'QTDMORT2');
    p_sem3      := act_int_param(p_idsessao, 'QTDMORT3');
    p_sem4      := act_int_param(p_idsessao, 'QTDMORT4');
  
    lote := ad_pkg_fci.get_dados_lote(l.numlote);
    ad_pkg_fci.get_dados_fechamento(l.numlote, l, c);
  
    -- valida status do lote antes de iniciar o procedimento
    if l.statuslote = 'P' then
      p_mensagem := 'Lote ainda n�o foi Auditado. Por favor realize a confer�ncia do lote ' ||
                    'para que seja poss�vel realizar o c�lculo das bonifica��es.';
      return;
      rollback;
    elsif l.statuslote = 'L' then
      p_mensagem := 'Lote j� finalizado, o que impossibilita altera��es no lote.';
      return;
      rollback;
    elsif l.statuslote = 'A' then
      null;
    end if;
  
    -- valida status da bonifica��o
    if l.statusbonif in ('F', 'L') then
      p_mensagem := 'Bonifica��o j� foi calculada e possui nota gerada, ' ||
                    'o que impossibilita altera��es no c�lculo j� realizado.';
      return;
      rollback;
    end if;
  
    -- inicio dos calculos
    begin
      delete from ad_tsffcibnf where numlote = l.numlote;
    exception
      when others then
        p_mensagem := 'Erro ao limpar bonifica��es existentes. ' || sqlerrm;
        return;
        rollback;
    end;
  
    -- insere a linha do c�lculo do lote real
    begin
      ad_pkg_fci.set_bnf_lotereal(l.numlote, p_mensagem);
      if p_mensagem is not null then
        stp_set_atualizando('N');
        p_mensagem := 'Erro ao gravar o lote real. ' || p_mensagem;
        return;
        rollback;
      end if;
    end;
  
    for x in 1 .. 4
    loop
      if x = 1 then
        p_tipobonif := 'M';
      elsif x = 2 then
        p_tipobonif := 'C';
      elsif x = 3 then
        p_tipobonif := 'ITA';
      elsif x = 4 then
        p_tipobonif := 'NVZ';
      end if;
    
      -- calcula bonifica��es
      begin
        -- mortalidade
        if p_tipobonif = 'M' then
        
          -- valida input
          if p_sem1 is null or p_sem2 is null or p_sem3 is null or p_sem4 is null then
            stp_set_atualizando('N');
            p_mensagem := 'Preencha a quantidade de mortes para todas as semanas!';
            return;
            rollback;
          end if;
        
          --efetua opera��o
          ad_pkg_fci.set_bnf_mortalidade(l.numlote, p_sem1, p_sem2, p_sem3, p_sem4, p_mensagem);
        
          --valida resultado opera��o
          if p_mensagem is not null then
            stp_set_atualizando('N');
            p_mensagem := 'Erro ao calcular a bonifica��o da mortalidade. ' || p_mensagem;
            return;
            rollback;
          end if;
        
          -- carca�a GPA
        elsif p_tipobonif = 'C' then
        
          ad_pkg_fci.set_bnf_carcaca(l.numlote, p_vlrmedcom, p_mensagem);
        
          if p_mensagem is not null then
            stp_set_atualizando('N');
            p_mensagem := 'Erro ao calcular a bonifica��o pela carca�a. ' || p_mensagem;
            return;
            rollback;
          end if;
        
        elsif p_tipobonif = 'ITA' then
          begin
          
            if nvl(p_vlrcusto, 0) = 0 then
              ad_pkg_fci.get_dados_tabela(l.numlote, l.codemp, t);
              p_vlrcusto := t.vlrcustoave;
            
              /*
              v_confirma := act_confirmar(
                         p_titulo    => 'Confirma��o de valores',
                         p_texto     => 'O custo da ave n�o foi informada no par�metro, o valor ' ||                                                  
                                     ' do custo ser� o informado nas configura��es da rotina (' ||
                         fmt.valor_moeda(p_vlrcusto) || '). <br>' ||'Confirma a utiliza��o desse valor?',
                         p_chave     => p_idsessao,
                         p_sequencia => 0);
              
              if not v_confirma then
                return;
                rollback;
              end if;
              */
            
            end if;
          
            --p_vlrbnfpinto := nvl(p_vlrbnfpinto, 0);
            b.vlrcom     := l.vlrcom; --+ p_vlrbnfpinto;
            b.vlrbonific := greatest((l.qtdabat * p_vlrcusto) - b.vlrcom, 0);
            b.vlrunitbnf := snk_dividir(b.vlrbonific, l.qtdabat);
          
            b.obs := 'Utilizando tabela ' || t.codtab || '/' || t.codemp || ', custo da ave de 0' ||
                     fmt.numero(p_vlrcusto);
            --||' e com ajuda extra de ' || fmt.numero(p_vlrbnfpinto);
          
            select max(nufcibnf) + 1 into i from ad_tsffcibnf where numlote = l.numlote;
          
            insert into ad_tsffcibnf
              (numlote, nufcibnf, tipobonif, percmortprev, qtdmortprev, saldoprev, percmortreal,
               qtdmortreal, saldoreal, qtdavesbnf, percavesbnf, viabilidade, percmortlote, perccom,
               vlrcom, vlrunitcom, vlrbonific, vlrunitbnf, aprovado, obs)
            values
              (l.numlote, i, 'ITA', c.percmortprev, l.qtdaves * (c.percmortprev / 100),
               l.qtdaves - (l.qtdaves * (c.percmortprev / 100)), (l.qtdmortes / l.qtdaves) * 100,
               l.qtdmortes, l.qtdaves - l.qtdmortes, 0, 0, l.viabilidade, 100 - l.viabilidade,
               l.percom, b.vlrcom, b.vlrcom / l.qtdabat, b.vlrbonific, b.vlrunitbnf, 'N', b.obs);
          
          exception
            when others then
              rollback;
              p_mensagem := 'Erro ao inserir o c�lculo da bonifica��o Itabera�. ' || sqlerrm;
              return;
          end;
        elsif p_tipobonif = 'NVZ' then
          begin
          
            ad_pkg_fci.get_dados_tabela(l.numlote, 19, t);
          
            l.ipsumedio := case
                             when l.tipopreco = 'F' then
                              t.ipsufemea
                             when l.tipopreco = 'M' then
                              t.ipsumacho
                             when l.tipopreco = 'X' then
                              t.ipsusexado
                           end;
          
            l.percom     := trunc(ad_pkg_fci.get_perc_com(l.ipsulote, l.ipsumedio), 2);
            l.pesocom    := l.peso * (l.percom / 100);
            b.vlrcom     := (l.pesocom * l.vlrunit);
            b.vlrbonific := greatest(b.vlrcom - l.vlrcom, 0);
            b.vlrunitbnf := snk_dividir(b.vlrbonific, l.qtdabat);
            b.obs        := 'Utilizando tabela ' || t.codtab || '/' || t.codemp ||
                            ', custo da ave de 0' || fmt.numero(p_vlrcusto)
            --||' e com ajuda de ' || fmt.numero(p_vlrbnfpinto)
             ;
          
            select max(nufcibnf) + 1 into i from ad_tsffcibnf where numlote = l.numlote;
          
            insert into ad_tsffcibnf
              (numlote, nufcibnf, tipobonif, percmortprev, qtdmortprev, saldoprev, percmortreal,
               qtdmortreal, saldoreal, qtdavesbnf, percavesbnf, viabilidade, percmortlote, perccom,
               vlrcom, vlrunitcom, vlrbonific, vlrunitbnf, aprovado)
            values
              (l.numlote, i, 'NVZ', c.percmortprev, l.qtdaves * (c.percmortprev / 100),
               l.qtdaves - (l.qtdaves * (c.percmortprev / 100)), (l.qtdmortes / l.qtdaves) * 100,
               l.qtdmortes, l.qtdaves - l.qtdmortes, 0, 0, l.viabilidade, 100 - l.viabilidade,
               l.percom, b.vlrcom, b.vlrcom / l.qtdabat, b.vlrbonific, b.vlrunitbnf, 'N');
          end;
        end if;
      
      end;
    
    end loop x;
  
    -- atualiza dados no formulario principal
    begin
      update ad_tsffci f
         set /*f.tipobonif   = p_tipobonif,*/ f.statusbonif = 'A',
             f.codusualter = p_codusu,
             f.dhalter     = sysdate
       where f.numlote = l.numlote;
    exception
      when others then
        p_mensagem := 'Erro ao atualizar os dados na tela do fechamento. ' || sqlerrm;
        return;
        rollback;
    end;
  
    -- atualiza dados no formulario das bonifica��es
    begin
      update ad_tsffcibnf b
         set b.codusu  = p_codusu,
             b.dhalter = sysdate
       where b.numlote = l.numlote
      --and b.tipobonif = p_tipobonif
      ;
    exception
      when others then
        p_mensagem := 'Erro ao atualizar os dados na tela do c�lculo da bonifica��o. ' || sqlerrm;
        return;
        rollback;
    end;
  
    /* envia mail para liberador */
    declare
      mail      tmdfmg%rowtype;
      enviamail boolean;
    begin
      select usu.codusu, usu.email
        into mail.codusu, mail.email
        from tsiusu usu
        join ad_tsfmgn m
          on m.numodelo = c.numodbnffrv
        join tsicus cus
          on cus.codusuresp = usu.codusu
         and cus.codcencus = m.codcencus;
    
      enviamail := act_confirmar(p_titulo    => 'C�lculo de Bonifica��o',
                                 p_texto     => 'Deseja enviar um e-mail para ' ||
                                                ad_get.nomeusu(mail.codusu, 'completo') ||
                                                ' solicitando a aprova��o das simula��es?',
                                 p_chave     => p_idsessao,
                                 p_sequencia => 0);
    
      if enviamail then
      
        mail.assunto := 'Nova aprova��o de bonfica��o de comiss�o do integrado.';
      
        mail.mensagem := 'Uma nova solicita��o de aprova��o de bonifica��o foi gerada ' ||
                         'para o lote ' || l.numlote || ' (' ||
                         ad_get.nome_parceiro(l.codparc, 'fantasia') || '; ' || l.tipopreco || '; ' ||
                         fmt.numero(l.qtdaves) || ')' || ', por ' ||
                         ad_get.nomeusu(825, 'completo') || '.<br>' || chr(13) ||
                         'Acesse o link abaixo para maiores detalhes.<br>' || chr(13) ||
                         '<a href="' || ad_fnc_urlskw('AD_TSFFCI', l.numlote) ||
                         '">Qlique Aqui</a>';
      
        ad_set.insere_mail_fila_fmg(p_assunto  => mail.assunto,
                                    p_mensagem => mail.mensagem,
                                    p_email    => mail.email,
                                    p_nunota   => null,
                                    p_evento   => null);
      
      end if;
    
    end;
  
    p_mensagem := 'C�lculo da bonifica��o conclu�da com sucesso!';
  exception
    when pacote_invalido then
      goto inicio;
  end;

  stp_set_atualizando('N');

end;
/
