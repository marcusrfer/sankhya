create or replace procedure ad_stp_fci_aprovabonif_sf(p_codusu    number,
                                                      p_idsessao  varchar2,
                                                      p_qtdlinhas number,
                                                      p_mensagem  out varchar2) as
  b ad_tsffcibnf%rowtype;
  i int;
begin

  if p_qtdlinhas = 0 then
    p_mensagem := 'Selecione pelo menos 1 registro para aprovar.';
    return;
  end if;

  if p_qtdlinhas > 1 then
    p_mensagem := 'Selecione apenas um registro para aprovação!';
    return;
  end if;

  b.nufcibnf := act_int_field(p_idsessao, 1, 'NUFCIBNF');
  b.numlote  := act_int_field(p_idsessao, 1, 'NUMLOTE');

  select *
    into b
    from ad_tsffcibnf
   where numlote = b.numlote
     and nufcibnf = b.nufcibnf;

  if b.tipobonif = 'LR' then
    p_mensagem := 'Não há necessidade de aprovar o lote real, pois o mesmo é apenas ' ||
                  'uma demonstração dos valores calculados na tela principal.';
    return;
  end if;

  select count(*)
    into i
    from ad_tsffcibnf
   where numlote = b.numlote
     and nunota is not null;

  if i > 0 then
    p_mensagem := 'Já existe nota gerada para este lote, ' ||
                  'não é possível aprovar lançamentos após a geração da nota!';
    return;
  else
    -- se não possui nota gerada
  
    if b.vlrbonific = 0 then
      if act_confirmar('Bonificação sem valor.',
                       'A linha selecionada não possui valor de bonificação.' ||
                       ' Deseja aprová-la assim mesmo? Não será possível gerar nota com valor ZERO.',
                       p_idsessao,
                       0) then
        null;
      else
        return;
      end if;
    end if;
    stp_set_atualizando('S');
    update ad_tsffcibnf
       set aprovado = 'N'
     where numlote = b.numlote
       and nufcibnf != b.nufcibnf
       and tipobonif != 'LR';
  
    update ad_tsffcibnf
       set aprovado = 'S',
           codusu   = p_codusu,
           dhalter  = sysdate
     where numlote = b.numlote
       and nufcibnf = b.nufcibnf;
    stp_set_atualizando('N');
  
    if b.vlrbonific = 0 then
      return;
    end if;
  
    -- insere um linha na aba financeiro para programação
    declare
      fin ad_tsffcifin%rowtype;
      cfg ad_tsffciconf%rowtype;
    begin
      stp_set_atualizando('S');
      delete from ad_tsffcifin where origem = 'BNF';
      fin.numlote := b.numlote;
      fin.origem  := 'BNF';
    
      select nvl(max(f.nufcifin), 0) + 1, nvl(max(f.desdobramento), 0) + 1
        into fin.nufcifin, fin.desdobramento
        from ad_tsffcifin f
       where numlote = b.numlote;
    
      -- get dados da tela de parametros
      begin
        ad_pkg_fci.get_config(trunc(sysdate), cfg);
      
        select m.codnat, m.codcencus
          into fin.codnat, fin.codcencus
          from ad_tsfmgn m
         where m.numodelo = cfg.numodbnffrv;
      exception
        when others then
          raise;
      end;
    
      fin.dtvenc    := null;
      fin.vlrdesdob := b.vlrbonific;
      fin.codtiptit := cfg.codtiptitcom;
      fin.historico := 'Ref. Ajuda de Custo/Bonificação';
      fin.nufin     := null;
    
      insert into ad_tsffcifin values fin;
    
      update ad_tsffci f
         set f.tipobonif   = b.tipobonif,
             f.codusualter = p_codusu,
             f.dhalter     = sysdate
       where numlote = b.numlote;
    
      stp_set_atualizando('N');
    
    exception
      when others then
        p_mensagem := sqlerrm;
        return;
    end;
  
  end if;

  p_mensagem := 'Registro aprovado com sucesso!';

end;
/
