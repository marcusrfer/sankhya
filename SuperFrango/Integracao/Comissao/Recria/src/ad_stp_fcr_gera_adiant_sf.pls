create or replace procedure ad_stp_fcr_gera_adiant_sf(p_codusu    number,
                                                      p_idsessao  varchar2,
                                                      p_qtdlinhas number,
                                                      p_mensagem  out varchar2) as

  fcr        ad_tsffcr%rowtype;
  cfg        ad_adtssaconf%rowtype;
  fci        ad_tsffciconf%rowtype;
  fin        tgffin%rowtype;
  fre        tgffre%rowtype;
  v_dtreftab date;
  v_confirma boolean;
  v_gerou    int := 0;

  type linhas_adiant is table of ad_tsffcradt%rowtype;
  adt linhas_adiant := linhas_adiant();

begin
  /*
  * Autor: M. Rangel
  * Processo: Fechamento de comissão Recria
  * Objetivo: Validação e geração dos adiantamentos. Ação "Gerar adiantamento"
              da aba adiantamentos da tela de fechamento recria.
  */

  /*
   a rotina gera sequencialmente o adiantamento, ordenado pela pk, logo, não é
   necessário que o usuário selecione alguma linha, sempre seguirá a ordem da pk
  */

  -- popula com as informações do fechamento

  select *
    into fcr
    from ad_tsffcr f
   where f.codcencus = act_int_field(p_idsessao, 0, 'MASTER_CODCENCUS')
     and f.codparc = act_int_field(p_idsessao, 0, 'MASTER_CODPARC')
     and f.numlote = act_int_field(p_idsessao, 0, 'MASTER_NUMLOTE')
     and f.sexo = act_txt_field(p_idsessao, 0, 'MASTER_SEXO');

  if fcr.status = 'P' then
    p_mensagem := 'Necessário calcular o adiantamento antes!';
    return;
  end if;

  -- armazena as previsões de adiantmento
  select *
    bulk collect
    into adt
    from ad_tsffcradt a
   where a.codcencus = fcr.codcencus
     and a.codparc = fcr.codparc
     and a.numlote = fcr.numlote
     and a.sexo = fcr.sexo
   order by a.nuadt --dtvenc
  ;

  -- percorre os adiantamentos
  for l in adt.first .. adt.last
  loop
  
    -- ignora os registros  com nufin gerado
    if adt(l).nuacerto is not null then
      continue;
    else
    
      if nvl(adt(l).vlradiant, 0) = 0 then
        adt(l).vlradiant := adt(l).vlrprev;
      end if;
    
      -- busca os dados da tela de parametros do Fech. Com. Integrado
      -- cabe um  exception pra tratar a msg de config not found --
      ad_pkg_fci.get_config(adt(l).dtref, fci);
      -- busca set de parametros
    
      -- busca a ultima data de atualização de tabela
      begin
        select ref.dtref
          into v_dtreftab
          from ad_tsftcp tab
          join ad_tsftcpcus cus
            on cus.codtabpos = tab.codtabpos
          join ad_tsftcpref ref
            on ref.codtabpos = tab.codtabpos
         where cus.codcencus = fcr.codcencus
           and tab.sexo = fcr.sexo
           and ref.dtref = (select max(dtref)
                              from ad_tsftcpref r2
                             where r2.codtabpos = tab.codtabpos
                               and r2.dtref <= adt(l).dtref);
      exception
        when no_data_found then
          p_mensagem := 'Tabela não encontrada para o CR ' || fcr.codcencus ||
                        ' na referência ' || adt(l).dtref;
          return;
      end;
    
      --- se data do ultimo calculo do lote for menor que a ultima atualização da tabela
      if fcr.dreftabreal < v_dtreftab then
        v_confirma := act_confirmar('Geração de Adiantamentos',
                                    'Existe uma atualização de tabela, indicando ' ||
                                    'que o lote não foi recalculado, deseja recalcular ' ||
                                    'antes de gerar o adiantamento?',
                                    p_idsessao,
                                    0);
        if v_confirma then
          -- recalcula o lote
          ad_stp_fcr_recalcfechamento_sf(fcr.codcencus,
                                         fcr.codparc,
                                         fcr.numlote,
                                         fcr.sexo,
                                         adt(l).dtref,
                                         fcr);
        
          adt(l).vlradiant := ((fcr.totremave * fcr.qtdaves) / fcr.qtdmeses);
        
          --calcular a diferença retroativa de valores
          declare
            vlrdiff float := 0;
            vlrnovo float := adt(l).vlradiant;
          begin
            for val in (select vlrprev, vlradiant
                          from ad_tsffcradt
                         where codcencus = fcr.codcencus
                           and codparc = fcr.codparc
                           and numlote = fcr.numlote
                           and sexo = fcr.sexo
                           and dtref < adt(l).dtref)
            loop
              vlrdiff := vlrdiff + (vlrnovo - val.vlradiant);
            end loop;
            adt(l).vlradiant := vlrnovo + abs(vlrdiff);
          end;
        
        else
          p_mensagem := 'Efetue o recalculo do lote ou a correção da tabela para ' ||
                        'gerar a parcela do adiantamento.';
          return;
        end if;
      
      end if;
    
      -- busca os dados da tela de parametros para adiantamentos ssa
      select *
        into cfg
        from ad_adtssaconf c
       where c.codigo = fci.codconfemprec;
    
    end if;
  
    -- se for a última parcela
    if l = fcr.qtdmeses and fcr.statuslote != 'F' then
      p_mensagem := 'A última parcela do adiantamento só poderá ser gerada ' ||
                    'após a realização da ação de fechamento, pois é necessário ' ||
                    'obter o valor residual dos adiantamentos';
      return;
    end if;
  
    <<valida_venc>>
    begin
      if to_char(adt(l).dtvenc, 'd') in (1, 7) then
        adt(l).dtvenc := adt(l).dtvenc + 1;
        goto valida_venc;
      end if;
    end;
  
    -- confirmação de geração da parcela X
    v_confirma := act_confirmar('Geração de Adiantamentos',
                                'Confirma a geração da parcela ' || l ||
                                ' no valor de ' ||
                                fmt.valor_moeda(adt(l).vlradiant) ||
                                ' com vencimento para ' ||
                                to_char(adt(l).dtvenc, 'dd/MM/yyyy'),
                                p_idsessao,
                                1);
  
    if not v_confirma then
      return;
    end if;
  
    -- inicio da geração do adiantamento
    begin
    
      stp_keygen_tgfnum('TGFFRE', 1, 'TGFFRE', 'NUACERTO', 0, fre.nuacerto);
      fre.sequencia := 0;
    
      -- prepara para inserir uma receita e uma despesa
      for rec_desp in -1 .. 1
      loop
      
        if rec_desp = 0 then
          continue;
        end if;
      
        stp_keygen_nufin(p_ultcod => fin.nufin);
      
        if rec_desp = 1 then
          fin.codtipoper := cfg.codtipoperrec;
          fin.codtiptit  := cfg.tipotitrec;
          fin.provisao   := 'N';
          fin.dtvenc     := adt(adt.last).dtvenc; -- se receita gera para o fim do processo
          fin.dtvencinic := adt(l).dtvenc;
        else
          fin.codtipoper := cfg.codtipoperdesp;
          fin.codtiptit := 4;
          fin.provisao := 'S';
          adt(l).nuacerto := fre.nuacerto;
          fin.dtvenc := adt(l).dtvenc;
          fin.dtvencinic := adt(l).dtvenc;
        end if;
      
        fin.dhtipoper := ad_get.maxdhtipoper(fin.codtipoper);
        fin.historico := 'Ref. fechamento comissão recriar - lote ' || adt(l).numlote || '. ' ||
                         'Parcela ' || adt(l).desdobramento || ' de ' ||
                         adt.count;
      
        insert into tgffin
          (nufin, codemp, numnota, dtneg, desdobramento, dhmov, dtvenc,
           dtvencinic, codparc, codtipoper, dhtipoper, codctabcoint, codnat,
           codcencus, codproj, codtiptit, vlrdesdob, vlrjuronegoc, recdesp,
           provisao, origem, codusu, dtalter, desdobdupl, historico, codbco,
           ad_variacao)
        values
          (fin.nufin, fcr.codemp, fcr.numlote, trunc(sysdate),
           adt(l).desdobramento, sysdate, fin.dtvenc, fin.dtvencinic,
           fcr.codparc, fin.codtipoper, fin.dhtipoper, cfg.codctabcoint,
           fci.codnatrecria, fci. codcradiant, 0, fin.codtiptit,
           adt(l).vlradiant, 0, rec_desp, fin.provisao, 'F', p_codusu, sysdate,
           'ZZ', fin.historico, 1, 'comrecria');
      
        fre.sequencia := fre.sequencia + 1;
      
        insert into tgffre
          (nuacerto, nunota, nufin, nufinorig, codusu, dhalter, tipacerto,
           sequencia, nuedi)
        values
          (fre.nuacerto, null, fin.nufin, null, p_codusu, sysdate, 'A',
           fre.sequencia, null);
      
        update tgffin f
           set f.nucompens = fre.nuacerto,
               f.numdupl   = fre.nuacerto
         where nufin = fin.nufin;
      
        -- se exige aprovação e é a despesa do adiantmento
        if cfg.exigaprdesp = 'S' and rec_desp = -1 then
          -- insere liberação
          ad_set.ins_liberacao('TGFFIN',
                               fin.nufin,
                               1035,
                               adt(l).vlradiant,
                               cfg.codusuapr,
                               'Ref. Com. Recria, lote ' || fcr.numlote ||
                               ', parcela ' || to_char(adt(l).desdobramento) ||
                               ' de ' || adt.count,
                               p_errmsg => p_mensagem);
        
          if p_mensagem is not null then
            return;
          end if;
        
        end if;
      
      end loop;
      -- loop do financeiro
    
      begin
        -- atualiza o total do adiantamento gerado no mainform
        stp_set_atualizando('S');
      
        select sum(vlradiant)
          into fcr.vlrtotadiant
          from ad_tsffcradt
         where codcencus = fcr.codcencus
           and codparc = fcr.codparc
           and numlote = fcr.numlote
           and sexo = fcr.sexo;
      
        fcr.vlrtotreal := fcr.totremave * fcr.qtdavesliq;
      
        update ad_tsffcr f
           set f.vlrtotreal   = fcr.vlrtotreal,
               f.vlrtotadiant = fcr.vlrtotadiant + adt(l).vlradiant,
               f.saldo = case
                           when nvl(f.vlrtotreal, 0) > 0 then
                            fcr.vlrtotreal - fcr.vlrtotadiant
                         --(fcr.vlrtotadiant + adt(l).vlradiant)
                           else
                            0
                         end
         where f.codcencus = fcr.codcencus
           and f.codparc = fcr.codparc
           and f.numlote = fcr.numlote
           and f.sexo = fcr.sexo;
      
        -- devolve o nuacerto gerado
        update ad_tsffcradt a
           set a.nuacerto  = fre.nuacerto,
               a.vlradiant = adt(l).vlradiant
         where a.codcencus = fcr.codcencus
           and a.codparc = fcr.codparc
           and a.numlote = fcr.numlote
           and a.nuadt = adt(l).nuadt
           and a.sexo = fcr.sexo;
      
        stp_set_atualizando('N');
      exception
        when others then
          p_mensagem := 'Erro ao atualizar o número único do adiantamento. ' ||
                        sqlerrm;
          return;
      end;
    
    end;
    -- fim da geração do adiantamento
  
    exit;
  
  end loop;

  p_mensagem := 'Adiantamento gerado com sucesso!!!';

end;
/
