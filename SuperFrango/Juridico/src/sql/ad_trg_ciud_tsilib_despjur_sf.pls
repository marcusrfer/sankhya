create or replace trigger ad_trg_ciud_tsilib_despjur_sf
  for update on tsilib
  compound trigger

  /*
  * Autor: Marcus Rangel
  * Processo: Despesas Jurídicas
  * Objetivo: Tratar o processo de liberaçãoo das despesas jurídicas
              Atentar para o fato que as despesas e adiantamentos, necessitam de dupla
              aprovaçãoo, enquanto que o reeembolso necessita liberaçãoo apenas do jurídico.
              Como é necessária a verificaçãoo em tempo de execuçãoo se existem liberações
              pendentes e evitar o erro de tabela mutante, as liberações que necessitam de tal
              validaçãoo serão executadas no after statemente, enquanto que as liberações simples
              serão executadas no after each row
  */

  par        ad_jurtmp%rowtype;
  jur        ad_jurite%rowtype;
  p          ad_pkg_jur.type_rec_desp_jur;
  v_codctacp number;
  errmsg     varchar2(4000);
  processo_juridico exception;

  -----------------------------------------------------
  after each row is
  begin
  
    ad_pkg_jur.processo_juridico := true;
    variaveis_pkg.v_atualizando  := true;
  
    -- se não for do processo de despesas jurídicas, sai do gatilho
    if nvl(:new.tabela, :old.tabela) != 'AD_JURITE' then
      raise processo_juridico;
    end if;
  
    /*busca os eventos do proceso de despesa jurídica*/
    begin
      select jp.nuevento, jp.nueventofin, jp.nueventolibreemb, jp.codtoptransf
        into p.nueventofin, p.nueventojur, p.nueventoreemb, p.codtoptransf
        from ad_jurparam jp
       where jp.nujurpar = 1;
    exception
      when others then
        errmsg := 'Erro ao buscar dados dos parametros do processo jurídico.';
        raise_application_error(-20105, ad_fnc_formataerro(errmsg));
    end;
  
    par.nupasta    := :new.nuchave;
    par.seq        := :new.sequencia;
    par.seqcascata := :new.seqcascata;
  
    /*se atualizando dhlib e evento de adiantamento ou despesa/receita e não for reprovado*/
    if :new.dhlib is not null and :old.dhlib is null and :new.evento in (p.nueventofin, p.nueventojur) and
       nvl(:new.reprovado, 'N') = 'N' then
    
      begin
        select *
          into jur
          from ad_jurite i
         where i.nupasta = :new.nuchave
           and i.seq = :new.sequencia;
      exception
        when no_data_found then
          raise processo_juridico;
      end;
    
      if nvl(jur.adto, 'N') = 'S' then
      
        begin
        
          if nvl(par.ctadeb, 0) = 0 then
            select c.ad_codctabcocp
              into v_codctacp
              from tsicta c
             where c.codctabcoint = jur.codcta;
          else
            v_codctacp := par.ctadeb;
          end if;
        
          ad_pkg_jur.v_reclamante := ad_pkg_jur.get_nome_reclamante(jur.nupasta);
        
          -- gera o adiantamento
          ad_pkg_jur.realiza_transf_mbc(p_top => p.codtoptransf, p_dtlanc => jur.dtvenc, p_predata => jur.dtvenc,
                                        p_ctaorig => v_codctacp, p_ctadestino => jur.codcta, p_numdoc => jur.numdoc,
                                        p_valor => jur.valor,
                                        p_historico => 'Adiantamento processo ' || jur.numprocesso || ' - ' ||
                                                        ad_pkg_jur.v_reclamante, p_numtransf => ad_pkg_jur.v_numtransf);
        
          -- atualiza a transferÃªncia, heranÃ§a do que o Gustavo fez, antes tinha uma liberaçãoo do adiantamento pelo financeiro
          update tgfmbc
             set ad_nufinproc = jur.nufin
           where numtransf = ad_pkg_jur.v_numtransf;
        
          -- atualiza situação do processo
          update ad_jurite i
             set i.situacao = 'AR'
           where nupasta = jur.nupasta
             and seq = jur.seq;
        
        exception
          when others then
            raise;
        end;
      
        -- registra a transferÃªncia na aba lanÃ§amentos da desp. jur / adiantamento
        ad_pkg_jur.grava_log_transf_bancaria(jur.nupasta, jur.seq, ad_pkg_jur.v_numtransf, 'A');
      
      else
      
        -- se for despesa,
        begin
          update tgffin
             set provisao   = 'N',
                 autorizado = 'S'
           where nufin = jur.nufin;
        exception
          when others then
            raise_application_error(-20105,
                                    'Não foi possível retirar a provisão do lançaamento em questão. ' || sqlerrm);
        end;
      
      end if;
    
      /*se liberado e evento de reembolso*/
    elsif :new.dhlib is not null and nvl(:new.reprovado, 'N') = 'N' and :new.evento = p.nueventoreemb then
    
      -- envia o aviso do sistema
      if :new.codusulib > 0 then
        ad_set.ins_avisosistema(p_titulo => 'Liberação realizada',
                                p_descricao => 'O reembolso da pasta ' || :new.nuchave || ', sequencia ' ||
                                                :new.sequencia || ' foi liberado!',
                                p_solucao => 'Acesso novamente o processo e realize o lançaamento do reembolso',
                                p_usurem => :new.codusulib, p_usudest => :new.codususolicit, p_prioridade => 1,
                                p_tabela => 'AD_JURITE', p_nrounico => :new.nuchave, p_erro => errmsg);
      
        if errmsg is not null then
          raise_application_error(-20105, ad_fnc_formataerro(errmsg));
        end if;
      end if;
    
      --altera o status pra liberado
      begin
        update ad_jurite i
           set i.libreembolso = 'S'
         where nupasta = :new.nuchave
           and i.seq = :new.sequencia;
      exception
        when others then
          raise;
      end;
    
      -- busca os valores dos parÃ¢metros informados no reembolso
      begin
        select *
          into par
          from ad_jurtmp t
         where t.seqcascata = :new.seqcascata
           and t.nupasta = :new.nuchave
           and t.seq = :new.sequencia
           and nvl(t.compensado, 'N') = 'N';
      exception
        when others then
          raise;
      end;
    
      -- executa o reembolso
      if par.favorecido = '1' then
        -- reclamada
        ad_pkg_jur.encerra_proc_reclamada(par.nupasta, par.seq, par.seqcascata);
      
      else
        -- reclamante
        ad_pkg_jur.encerra_proc_reclamante(par.nupasta, par.seq, par.seqcascata);
      end if;
      /*fim transações*/
    
      begin
        update ad_jurite i
           set i.status = case
                            when par.parcial = 'S' and par.parcelafinal = 'N' then
                             'A'
                            when par.parcial = 'S' and par.parcelafinal = 'S' then
                             'E'
                          end,
               i.situacao = case
                              when par.parcial = 'S' and par.parcelafinal = 'N' then
                               'RP'
                              else
                               'RR'
                            end,
               
               libreembolso = case
                                when par.parcial = 'S' and par.parcelafinal = 'N' then
                                 'N'
                                else
                                 'S'
                              end
         where nupasta = :new.nuchave
           and seq = :new.sequencia;
      
      exception
        when others then
          --Rollback;
          errmsg := 'Erro Ao Atualizar Status Na Despesa Jurídica. ' || sqlerrm;
          raise_application_error(-20105, ad_fnc_formataerro(errmsg));
      end;
    
      -- Andamento ao processo de reembolso
    
      -- tratativa para reprovaçãoo das liberações comm atualizaçãoo de status
    elsif :new.reprovado = 'S' then
      null;
    end if;
  
    -- Atualiza a aba liberações da tela de despesa jurídica
    begin
      if updating then
        begin
          update ad_jurlib
             set dhlib         = :new.dhlib,
                 vlrliberado   = :new.vlrliberado,
                 codusulib     = :new.codusulib,
                 codususolicit = :new.codususolicit,
                 status       =
                 (case
                   when :new.dhlib is null and :new.reprovado = 'N' then
                    'P'
                   when :new.dhlib is not null and :new.reprovado = 'N' then
                    'L'
                   when :new.dhlib is not null and :new.reprovado = 'S' then
                    'R'
                 end)
           where nupasta = :new.nuchave
             and seq = :new.sequencia
             and seqcascata = :new.seqcascata;
        exception
          when others then
            raise;
        end;
      elsif deleting then
        begin
        
          delete from ad_jurlib
           where nupasta = :old.nuchave
             and seq = :old.sequencia
             and seqcascata = :old.seqcascata;
        
          delete from ad_jurtmp
           where nupasta = :old.nuchave
             and seq = :old.sequencia
             and seqcascata = :old.seqcascata;
        
        exception
          when others then
            raise;
        end;
      end if;
    end;
  
  exception
    when processo_juridico then
      variaveis_pkg.v_atualizando := false;
  end after each row;

end;
/
