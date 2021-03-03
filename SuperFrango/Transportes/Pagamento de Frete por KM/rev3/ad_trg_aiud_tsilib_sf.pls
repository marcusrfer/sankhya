create or replace trigger ad_trg_aiud_tsilib_sf
  after delete or insert or update on tsilib
  referencing new as new old as old
  for each row
declare
  mail          tmdfmg%rowtype;
  eventos       ad_tsfelt%rowtype;
  v_count       int := 0;
  v_nuevento    number;
  v_descrevento varchar2(300);
  v_nomesolicit varchar2(300);
  v_ordcarga    number;
  v_codusulog   number := stp_get_codusulogado();
  v_enviamail   varchar2(1) := 'N';
  errmsg        varchar2(4000);
begin
  /*
  Autor: Marcus Rangel
  Dt. Criação: 31/08/2016
  Objetivo: Atender os processos customizados implemnentados no sistema. 
            Envio de e-mail, envio de avisos no sistema, gravação de log, atualização de status.
  
  ** Atualizações **
  Autor: Ricardo Soares
  Dt. Atualização: 01/09/2017
  Descritivo: Guardar log quando houver a exclusão do evento 1001;
  
  Autor: Ricardo Soares
  Dt. Atualização: 01/10/2018
  Descritivo: 001 - Dispara e-mail quando libera TOP 1009, se evento 1001 manda email 
              para quem libera 1007, se evento 1007 dispara email para quem libera 1006, 
              caso o usuário liberador não tenha tentado confirmar a nota
  */

  /*If Stp_Get_Atualizando Then
      Return;
  End If;*/

  /* Busca o nome do evento para o corpo do e-mail*/
  begin
    select e.descricao
      into v_descrevento
      from vgflibeve e
     where e.evento = nvl(:new.evento, :old.evento);
  exception
    when no_data_found then
      v_descrevento := 'Autorização de Pagamento';
  end;

  if :new.evento = 1017 then
    --ver com gusttavo se isso tem grandes impactos, se entrar nessa trigger dá tabela mutante no momento em que a Trg_Cmp_Tgffin_Confirma_Sf identifica que :NEW.PROVISAO = S
    return;
  end if;

  -- get eventos do transporte
  select *
    into eventos
    from ad_tsfelt
   where nuelt = 1;

  if inserting then
  
    -- liberação de pagamento de acerto
    select evelibpagacert
      into v_nuevento
      from ad_tsfelt e
     where e.nuelt = 1;
  
    --If :New.Evento = v_NuEvento Then
    if :new.dhlib is null then
      mail.assunto  := 'Nova Solicitação de Liberação.';
      mail.mensagem := '<font align="left">Atenção, foi inserida uma nova Solicitação de Liberação para ' ||
                       v_descrevento || '<br> <b> Solicitante : </b>' || ad_get.nomeusu(:new.codususolicit, 'resumido') ||
                       '<br> <b>Número Único: </b>' || :new.nuchave || '<br><b>Valor Solicitado: </b>' ||
                       replace(ltrim(rtrim('R$' || to_char(:new.vlratual, '999G999D99'))), '   ', ' ');
    
      mail.email := ad_get.mailusu(:new.codusulib);
      --Ad_Stp_Gravafilabi(Mail.Assunto, Mail.Mensagem, Mail.Email); solicitado Paulo Modesto
    end if;
    --End If;
  
    -- liberação de pagemento de despesas extras de frete
    if :new.tabela = 'AD_TSFDEF' then
    
      select nvl(u.nomeusucplt, u.nomeusu)
        into v_nomesolicit
        from tsiusu u
       where codusu = :new.codususolicit;
    
      begin
        select d.ordemcarga
          into v_ordcarga
          from ad_tsfdef d
         where nudef = :new.nuchave;
      exception
        when no_data_found then
          v_ordcarga := 0;
      end;
    
      mail.mensagem := '<br> Uma nova solicitação de liberação para pagamento de despesas extras de fretes, ' ||
                       'referente à Ordem de Carga nº ' || v_ordcarga || ', no valor de ' ||
                       ad_get.formatavalor(:new.vlratual) || ', foi cadastrada no sistema por ' || v_nomesolicit;
    
      mail.email := ad_get.mailusu(:new.codusulib);
    
      v_enviamail := 'S';
    
    end if;
  
    /*
      Alteração: Inclusão de teste para trabalhar com controle de multas.
      Data: 10/10/2016
      Autor: Guilherme Hahn
    */
    if :new.tabela = 'AD_MULCONT' then
    
      select nvl(u.nomeusucplt, u.nomeusu)
        into v_nomesolicit
        from tsiusu u
       where codusu = :new.codususolicit;
    
      mail.assunto := 'Nova solicitação de liberação.';
    
      mail.mensagem := '<br> Uma nova solicitação de liberação para Pagamento de Multas, ' ||
                       'referente ao Código de Controle de Multas nº ' || :new.nuchave || ', no valor de ' ||
                       ad_get.formatavalor(:new.vlratual) || ', foi cadastrada no sistema por ' || v_nomesolicit;
    
      mail.email := ad_get.mailusu(:new.codusulib);
    
      v_enviamail := 'S';
    
    end if;
  
    /*
    * Autor: Marcus Rangel
    * Objetivo: Tratativas do processo de despesas jurídicas
    */
    -- liberação de pagemento de despesas juridicas
  
    if :new.tabela = 'AD_JURITE' then
    
      declare
        j ad_jurite%rowtype;
      begin
        v_enviamail := 'S';
      
        v_nomesolicit := ad_get.nomeusu(:new.codususolicit, 'completo');
      
        mail.email := ad_get.mailusu(:new.codusulib);
      
        ad_pkg_jur.v_reclamante := ad_pkg_jur.get_nome_reclamante(p_nupasta => :new.nuchave);
      
        j.numprocesso := ad_pkg_jur.get_nro_processo_jur(:new.nuchave, :new.sequencia);
      
        mail.assunto := 'Nova solicitação de liberação.';
      
        mail.mensagem := '<br> Uma nova solicitação de liberação para pagamento de despesas juridicas, ' ||
                         'referente ao processo nº ' || j.numprocesso || ' de ' || ad_pkg_jur.v_reclamante ||
                         '(pasta nro ' || :new.nuchave || ', sequência ' || :new.sequencia || '), no valor de ' ||
                         ad_get.formatavalor(:new.vlratual) || ', foi cadastrada no sistema por ' || v_nomesolicit;
      
        -- envia o mail de notificação para o liberador do centro de resultados
      
      exception
        when others then
          raise;
      end;
    end if;
    -- fim if juridico
  
    -------------------------------------------------------------------------
    -- Bloco adicionado dia 12/03/2020
    -- por SERGIO R - B9  
    --     Objetivo: Tratativas do processo de Atendimento Social 
    --    1051 -1051 - Atendimento Social - Aprovação pelo Gestor - RH   
    --    (Evento disparado para notificar o Gestor - RH sobre a inserção da solicitação de liberação )
    -------------------------------------------------------------------------
  
    if :new.tabela = 'AD_ATDMSOC' and :new.evento = 1051 then
    
      select nvl(u.nomeusucplt, u.nomeusu)
        into v_nomesolicit
        from tsiusu u
       where codusu = :new.codususolicit;
    
      mail.assunto := 'Nova solicitação de liberação para Atendimento Social.';
    
      mail.mensagem := '<br> Uma nova solicitação de liberação para Atendimento Social , ' ||
                       'referente ao Código de Atendimento  nº ' || :new.nuchave || ', no valor de ' ||
                       ad_get.formatavalor(:new.vlratual) || ', foi cadastrada no sistema por ' || v_nomesolicit;
    
      mail.email := ad_get.mailusu(:new.codusulib);
    
      v_enviamail := 'S';
    end if;
  
    -------------------------------------------------------------------------
    -- Bloco adicionado dia 30/08/2019
    -- por SERGIO R - B9  
    --     Objetivo: Tratativas do processo de Benefícios 
    ------------------------------------------------------------------------------------------------------------------------------
    --1052 - Aprovação do RH para Benefício Negociado (Evento disparado para que o RH possa Aprovar a negociação do benefícios.)
    ------------------------------------------------------------------------------------------------------------------------------
  
    if :new.tabela = substr('AD_BENEFICIOS', 0, 12) and :new.evento = 1052 then
    
      select to_char(nvl(u.nomeusucplt, u.nomeusu))
        into v_nomesolicit
        from tsiusu u
       where codusu = :new.codususolicit;
      mail.email := null;
      for c_email in (select lim.codusu as codusulib
                        from tsilim lim, tsiusu usu
                       where usu.codusu = lim.codusu
                         and lim.evento = 1052
                         and usu.email is not null)
      loop
        if mail.email is null then
          mail.email := ad_get.mailusu(c_email.codusulib);
        else
          mail.email := mail.email || ',' || ad_get.mailusu(c_email.codusulib);
        end if;
      end loop;
    
      mail.assunto := 'Nova solicitação de liberação.';
    
      mail.mensagem := '<br> Uma nova solicitação de Aprovação de Benefícios , ' || ' Código Benefício :' ||
                       :new.nuchave || ', R$ ' || ad_get.formatavalor(:new.vlratual) || ', lançado por ' ||
                       to_char(v_nomesolicit);
    
      mail.mensagem := mail.mensagem || '<br><br>' || ' Solicitação de benefícios ' || :new.nuchave ||
                       ' clique no link :<BR><BR>' || '<a title="Abrir Tela" target=_parent href="' ||
                       ad_fnc_urlskw('AD_BENEFICIOS', :new.nuchave) ||
                       '"><font color="red">Abrir Tela - Clique aqui !!</font></a>'
      
       ;
    
      v_enviamail := 'S';
    end if;
  
    -- fim if BENEFICIOS
  
    -------------------------------------------------------------------------------------------------------------------------------------  
    -- Inicio Marcelo 
    --  1058 - Notifica que foi cadastrado um protocolo eletronico para o Usuário.)
    -------------------------------------------------------------------------------------------------------------------------------------
  
    if :new.tabela = 'AD_CABPROTOC' and :new.evento = 1058 then
    
      mail.assunto := 'Nova Solicitação de Liberação Protocolo.';
    
      mail.mensagem := '<font align="left">Atenção, existe Protocolo Eletrônico aguardando a ' || v_descrevento ||
                       '<br> <b> Solicitante : </b>' || ad_get.nomeusu(:new.codususolicit, 'resumido') ||
                       '<br> <b>Número Protocolo: </b>' || :new.nuchave;
    
      mail.mensagem := mail.mensagem || '<br><br>' || ' PROTOCOLO ELETRÔNICO ' || :new.nuchave ||
                       ' clique no link :<BR><BR>' || '<a title="Abrir Tela" target=_parent href="' ||
                       ad_fnc_urlskw('AD_CABPROTOC', :new.nuchave) ||
                       '"><font color="red">Abrir Tela - Clique aqui !!</font></a>';
    
      mail.email := ad_get.mailusu(:new.codusulib);
      --Ad_Stp_Gravafilabi(Mail.Assunto, Mail.Mensagem, Mail.Email); solicitado Paulo Modesto
      v_enviamail := 'S';
    end if;
  
    --Fim Marcelo
    -------------------------------------------------------------------------------------------------------------------------------
  
    /* M. Rangel 21/01/2019
    **se evento de liberação de conferência de pedido
    **adicionado basicamente para efetuar a comunicação dos pedidos
    **gerados pelo apontamento de horas
    */
    if :new.evento = eventos.evelibconfped then
      v_enviamail := 'S';
    end if;
  
    -- se liberador já selecionar e assunto preenchido e marcado para enviar e-mail
    if :new.codusulib > 0 and mail.assunto is not null and v_enviamail = 'S' then
    
      --Ad_Stp_Gravafilabi(Mail.Assunto, Mail.Mensagem, Mail.Email);
    
      ad_set.insere_mail_fila_fmg(mail.assunto, mail.mensagem, mail.email, :new.nuchave, :new.evento);
    
      ad_set.ins_avisosistema(p_titulo => 'Liberação solicitada.',
                              p_descricao => 'Uma nova solicitação de liberação para você foi cadastrada no sistema, ' ||
                                              v_descrevento,
                              p_solucao => 'Verifique a tela de liberação disponíveis para maiores detalhes.',
                              p_usurem => :new.codususolicit, p_usudest => :new.codusulib, p_prioridade => 1,
                              p_tabela => :new.tabela, p_nrounico => :new.nuchave, p_erro => errmsg);
    
      if errmsg is not null then
        raise_application_error(-20105, ad_fnc_formataerro(errmsg));
      end if;
    
    end if;
  
    -- AD_FILANOTIFICACAOPUSH
    -- insert na tabela que envia notificação push para a rotina alternativa de liberação de limites
    -- liberação de Limites SSA / rotina quanto o app de liberação são customizados.
    if :new.codusulib > 0 then
      declare
        v_codfila number;
      begin
        stp_keygen_tgfnum(p_arquivo => 'AD_FILANOTIFICACAOPUSH', p_codemp => 1, p_tabela => 'AD_FILANOTIFICACAOPUSH',
                          p_campo => 'CODFILA', p_dsync => 0, p_ultcod => v_codfila);
      
        insert into ad_filanotificacaopush
          (codfila, codusudest, codapp, mensagem, dtentrada, status)
        values
          (v_codfila,
           --nvl((select max(codfila) from ad_filanotificacaopush), 0) + 1, 
           :new.codusulib, 1, 'Nova liberação de limites solicitada', sysdate, 'P');
      exception
        when others then
          errmsg := 'Erro ao enviar notificação para apps. ' || sqlerrm;
          raise_application_error(-20105, ad_fnc_formataerro(errmsg));
      end;
    
    end if;
  
    --Novo aplicativo liberações
    --Danilo Ferreira Adorno
    --Em 29/12/2019
    if (:new.codusulib > 0) then
    
      declare
        p_token_usu varchar2(4000);
        p_token_app varchar2(4000);
      
      begin
      
        begin
          select c.token, c.tokenapp
            into p_token_usu, p_token_app
            from ad_cadappssaliberacoes c
           where c.codusu = :new.codusulib;
        exception
          when no_data_found then
            p_token_usu := null;
            p_token_app := null;
        end;
      
        if (p_token_usu is not null and p_token_app is not null) then
          insert into ad_cadappssanotify
            (codmsg, tokendest, tokenapp, titulo, mensagem, dhcriacao, dhenvio, status, msgerro)
          values
            (ad_cadappssanotify_seq.nextval, p_token_usu, p_token_app, 'Liberação de limites',
             'Nova liberação de limites solicitada!', sysdate, null, 'P', null);
        end if;
      
      end;
    
    end if;
  
    begin
      insert into ad_tsiliblog
        (nuchave, tabela, dhsolicit, dhlib, codususol, codusulib, codusuexc, vlratual, vlrliberado, evento, observacao,
         obslib, operacao, dhoper, seqlog)
      values
        (:new.nuchave, :new.tabela, :new.dhsolicit, :new.dhlib, :new.codususolicit, :new.codusulib, v_codusulog,
         :new.vlratual, :new.vlrliberado, :new.evento, :new.observacao, :new.obslib, 'Inclusão', sysdate,
         ad_seq_tsilib_log.nextval);
    exception
      when others then
        errmsg := 'Erro ao gravar o log da liberação - Insert - ' || sqlerrm;
        raise_application_error(-20105, ad_fnc_formataerro(errmsg));
    end;
  
  end if;
  -- fim inserting

  if updating then
  
    mail.email := ad_get.mailusu(:new.codususolicit);
  
    if updating('DHLIB') and (:new.dhlib is not null and :old.dhlib is null) then
    
      -- descrição padrão
      if nvl(:new.reprovado, 'N') = 'N' then
        mail.assunto  := 'Solicitação liberada.';
        mail.mensagem := '<br> A solicitação de Liberação para ' || v_descrevento || ', ' || 'referente ao código nº ' ||
                         :new.nuchave || ', foi liberada no sistema. linha 206';
      else
        mail.assunto  := 'Solicitação Reprovada.';
        mail.mensagem := '<br> A solicitação de Liberação para ' || v_descrevento || ', ' || 'referente ao código nº ' ||
                         :new.nuchave || ', foi reprovada no sistema.';
      end if;
      -- fim descrição padrão
    
      -- processo de visita sanitaria - RH
      if :new.tabela = 'AD_TSFAVS' then
        begin
          update ad_tsfavs v
             set v.resultvis = case
                                 when nvl(:new.reprovado, 'N') = 'N' then
                                  'A'
                                 else
                                  'R'
                               end,
                 v.status    = 'conc'
           where nuvisita = :new.nuchave;
        
          if nvl(:new.reprovado, 'N') = 'N' then
            ad_pkg_avs.insere_historico(:new.nuchave, 'Aprovação do candidato visitado.');
          else
            ad_pkg_avs.insere_historico(:new.nuchave, 'Reprovação do candidato visitado.');
          end if;
        
        exception
          when others then
            errmsg := 'Erro ao atualizar status da visita. ' || sqlerrm;
            raise_application_error(-20105, ad_fnc_formataerro(errmsg));
        end;
      end if;
    
      if :new.tabela = 'AD_TABCOTCAB' then
        begin
          update ad_tabcotcab c
             set c.situacao = 'L'
           where c.numcotacao = :new.nuchave;
        exception
          when others then
            errmsg := 'Erro ao atualizar o status do lançamento de origem. ' || sqlerrm;
            raise_application_error(-20105, ad_fnc_formataerro(errmsg));
        end;
      end if;
    
      -- Inicio alteração 001 por Ricardo Soares em 01/10/2018 - Envia aviso que tem uma liberação pendente, caso o usuário liberador não tenha tentado confirmar a nota
      if :new.tabela = 'TGFCAB' and :new.evento in (1001, 1007) then
      
        v_enviamail := 'S';
      
        v_count := ad_get.qtdlibpend(p_nuchave => :new.nuchave, p_tabela => 'TGFCAB', p_sequencia => :new.sequencia);
      
        if v_count = 0 then
          -- neste caso é possivel que o usuário não tenha clicado no confirmar e com isso a próxima solicitação não foi enviada.
        
          mail.assunto := 'Empréstimo de Funcionários';
        
          mail.mensagem := '<br> A solicitação de ' || case
                             when :new.evento = 1001 then
                              ' Aprovação de Urgência de Despesa '
                             else
                              ' Aprovação do RH '
                           end || 'foi efetuada pelo usuário , ' || :new.codusulib || ' ' ||
                           ad_get.nomeusu(:new.codusulib, 'RESUMIDO') || ' no lançamento ' || :new.nuchave || ', no valor de ' ||
                           ad_get.formatavalor(:new.vlratual) ||
                           '. É possivel que o usuário não tenha encaminhado a próxima aprovação, favor verificar.';
        
          select listagg(u.email, ', ') within group(order by u.email)
            into mail.email
            from tsilim l, tsiusu u
           where u.codusu = l.codusu
             and l.evento = :new.evento
             and email is not null;
        
          ad_set.insere_mail_fila_fmg(mail.assunto, mail.mensagem, mail.email, :new.nuchave, :new.evento);
        end if;
      
      end if;
      -- Fim alteração 001 por Ricardo Soares em 01/10/2018 - Envia aviso que tem uma liberação pendente, caso o usuário liberador não tenha tentado confirmar a nota
    
      if :new.tabela = 'AD_TSFDEF' then
      
        v_enviamail := 'S';
      
        v_count := ad_get.qtdlibpend(p_nuchave => :new.nuchave, p_tabela => 'AD_TSFDEF', p_sequencia => :new.sequencia);
        if v_count = 0 then
          begin
            update ad_tsfdef d
               set d.status = 'L'
             where nudef = :new.nuchave;
          exception
            when others then
              errmsg := 'Erro ao atualizar o status da despesa. ' || sqlerrm;
              raise_application_error(-20105, ad_fnc_formataerro(errmsg));
          end;
        end if;
      
        mail.assunto := 'Solicitação liberada.';
      
        mail.mensagem := '<br> A solicitação de liberação para pagamento de despesas extras de fretes, ' ||
                         'referente à Ordem de Carga nº ' || :new.nuchave || ', no valor de ' ||
                         ad_get.formatavalor(:new.vlratual) || ', foi liberada no sistema.';
      
        if nvl(:new.reprovado, 'N') = 'S' then
          begin
            update ad_tsfdef d
               set d.status = 'N'
             where nudef = :new.nuchave;
          
            mail.assunto  := 'Solicitação Reprovada.';
            mail.mensagem := '<br> A solicitação de liberação para pagamento    de despesas extras de fretes, ' ||
                             'referente à Ordem de Carga nº ' || :new.nuchave || ', no valor de ' ||
                             ad_get.formatavalor(:new.vlratual) || ', foi reprovada no sistema.' || '<br> Motivo: ' ||
                             :new.obslib;
          
            --Ad_Stp_Gravafilabi(Mail.Assunto, Mail.Mensagem, Mail.Email);
            ad_set.insere_mail_fila_fmg(mail.assunto, mail.mensagem, mail.email, :new.nuchave, :new.evento);
          
          exception
            when others then
              errmsg := 'Erro ao atualizar o status da despesa reprovada. ' || sqlerrm;
              raise_application_error(-20105, ad_fnc_formataerro(errmsg));
          end;
        end if;
      
      end if;
    
      if :new.tabela = 'AD_MULCONT' then
      
        v_enviamail := 'S';
        /*
          Alteração: Inclusão de teste para trabalhar com controle de multas.
          Data: 10/10/2016
          Autor: Guilherme Hahn
        */
      
        stp_controle_multa(p_codmulta => :new.nuchave, p_mensagem => errmsg);
      
        if errmsg is not null then
          raise_application_error(-20105, ad_fnc_formataerro(errmsg));
        end if;
      
        -- v_Count := Ad_Get.Qtdlibpend(New.Nuchave,'AD_MULCONT',:New.Sequencia);
        -- If v_Count = 0 Then
      
        begin
          update ad_mulcontrol m
             set m.situacao = 'A',
                 m.dtlib    = sysdate
           where m.codmulcont = :new.nuchave;
        exception
          when others then
            errmsg := 'Erro ao atualizar o status da liberação da multa. ' || sqlerrm;
            raise_application_error(-20105, ad_fnc_formataerro(errmsg));
        end;
      
        --End If;
      
        mail.assunto := 'Solicitação liberada.';
      
        mail.mensagem := '<br> A solicitação de liberação para pagamento de multa, ' ||
                         'referente código de controle de multa nº ' || :new.nuchave || ', no valor de ' ||
                         ad_get.formatavalor(:new.vlratual) || ', foi liberada no sistema.';
      
        if :new.reprovado = 'S' then
          begin
            update ad_mulcontrol m
               set m.situacao = 'N'
             where m.codmulcont = :new.nuchave;
          
            mail.assunto  := 'Solicitação Reprovada.';
            mail.mensagem := '<br> A solicitação de liberação para pagamento de multa, ' ||
                             'referente código de controle de multa nº ' || :new.nuchave || ', no valor de ' ||
                             ad_get.formatavalor(:new.vlratual) || ', foi reprovada no sistema.' || '<br> Motivo: ' ||
                             :new.obslib;
          
          exception
            when others then
              errmsg := 'Erro ao atualizar o status da liberação da multa. ' || sqlerrm;
              raise_application_error(-20105, ad_fnc_formataerro(errmsg));
          end;
        end if;
      
      end if;
    
      -------------------------------------------------------------------------
      --INICIO - Bloco adicionado dia 30/08/2019 -- por SERGIO R - B9  
      -------------------------------------------------------------------------
      -- enviar e-mail de liberação/reprovação do evento de BENEFÍCIOS 
      --  1052 - Aprovação do RH para Benefício Negociado (Evento disparado para que o RH possa Aprovar a negociação do benefícios.)
      -------------------------------------------------------------------------
    
      if :new.tabela = substr('AD_BENEFICIOS', 0, 12) then
        if nvl(:new.reprovado, 'N') = 'N' then
          mail.assunto  := 'Solicitação liberada.';
          mail.mensagem := '<br> A solicitação de Liberação para ' || v_descrevento || ', ' ||
                           'referente ao código nº ' || :new.nuchave || ', foi liberada no sistema.';
        else
          mail.assunto  := 'Solicitação Reprovada.';
          mail.mensagem := '<br> A solicitação de Liberação para ' || v_descrevento || ', ' ||
                           'referente ao código nº ' || :new.nuchave || ', foi reprovada no sistema.';
        end if;
      
        v_enviamail := 'S';
      
        if nvl(:new.reprovado, 'N') = 'N' then
          begin
            update ad_beneficios b
               set b.status = case
                                when :new.evento = 1052 then
                                 'AP' -- Benefício Aprovado
                              end
             where b.nubeneficio = :new.nuchave;
          exception
            when others then
              raise;
          end;
        end if;
      
        if nvl(:new.reprovado, 'N') = 'S' then
          begin
            update ad_beneficios b
               set b.status = case
                                when :new.evento = 1052 then
                                 'BR' -- Benefício REPROVADO
                              end
             where b.nubeneficio = :new.nuchave;
          exception
            when others then
              raise;
          end;
        end if;
      
      end if;
    
      -------------------------------------------------------------------------
      --TÉRMINO - Bloco adicionado dia 30/08/2019 -- por SERGIO R - B9  
      -------------------------------------------------------------------------
    
      -------------------------------------------------------------------------
      --INICIO - Bloco adicionado dia 12/03/2020 -- por SERGIO R - B9  
      -------------------------------------------------------------------------
      -- enviar e-mail de liberação/reprovação do evento de AD_ATDMSOC 
      --  1051 - Atendimento Social - Aprovação pelo Gestor - RH
      --  1060 - Atendimento Social - Aprovação pelo Gestor Financeiro
      -------------------------------------------------------------------------
    
      if :new.tabela = substr('AD_ATDMSOC', 0, 12) then
        if nvl(:new.reprovado, 'N') = 'N' then
          mail.assunto  := 'Solicitação liberada.';
          mail.mensagem := '<br> A solicitação de Liberação para ' || v_descrevento || ', ' ||
                           'referente ao código nº ' || :new.nuchave || ', foi liberada no sistema.';
        else
          mail.assunto  := 'Solicitação Reprovada.';
          mail.mensagem := '<br> A solicitação de Liberação para ' || v_descrevento || ', ' ||
                           'referente ao código nº ' || :new.nuchave || ', foi reprovada no sistema.';
        end if;
      
        v_enviamail := 'S';
      
        if nvl(:new.reprovado, 'N') = 'N' then
          begin
            update ad_atdmsoc b
               set b.situacao = case
                                  when :new.evento = 1051 then
                                   'APG' -- Aprovada pelo Gestor
                                  when :new.evento = 1060 then
                                   'APF' -- Aprovada Financeiro
                                end
             where b.nuatdmsoc = :new.nuchave;
          exception
            when others then
              raise;
          end;
        end if;
      
        if nvl(:new.reprovado, 'N') = 'S' then
          begin
            update ad_atdmsoc b
               set b.situacao = case
                                  when :new.evento = 1051 then
                                   'NAG' --  Não Aprovada pelo Gestor
                                  when :new.evento = 1060 then
                                   'NAF' -- Não Aprovada pelo Financeiro
                                end
             where b.nuatdmsoc = :new.nuchave;
          exception
            when others then
              raise;
          end;
        end if;
      
      end if;
    
      -------------------------------------------------------------------------
      --TÉRMINO - Bloco adicionado dia 30/08/2019 -- por SERGIO R - B9  
      -------------------------------------------------------------------------
    
      -------------------------------------------------------------------------
      --Inicio Marcelo
      -- enviar e-mail de liberação/reprovação do Protocolo de Recebimento     
      -------------------------------------------------------------------------
    
      if :new.tabela = 'AD_CABPROTOC' then
        if nvl(:new.reprovado, 'N') = 'N' then
          mail.assunto  := 'Protocolo Confirmado.';
          mail.mensagem := '<br> O Protocolo de ' || v_descrevento || ', ' || 'referente ao PROTOCOLO nº ' ||
                           :new.nuchave || ', foi confirmado no sistema.';
        else
          mail.assunto  := 'Protocolo Reprovado.';
          mail.mensagem := '<br> O protocolo de  ' || v_descrevento || ', ' || 'referente ao código nº ' ||
                           :new.nuchave || ', foi REPROVADO no sistema.';
        end if;
      
        v_enviamail := 'S';
      
        if nvl(:new.reprovado, 'N') = 'N' then
          begin
            update ad_cabprotoc b
               set b.status       = 'RA',
                   b.dhaprovreceb = sysdate
             where b.protocolo = :new.nuchave;
          exception
            when others then
              raise;
          end;
        end if;
      
        if nvl(:new.reprovado, 'N') = 'S' then
          begin
            update ad_cabprotoc b
               set b.status       = 'RR',
                   b.dhaprovreceb = sysdate
             where b.protocolo = :new.nuchave;
          exception
            when others then
              raise;
          end;
        end if;
      
        if nvl(:new.reprovado, 'N') = 'N' then
          begin
            update ad_iteprotoc i
               set i.status = 'RA'
             where i.protocolo = :new.nuchave;
          exception
            when others then
              raise;
          end;
        end if;
      
        if nvl(:new.reprovado, 'N') = 'S' then
          begin
            update ad_iteprotoc i
               set i.status = 'RR'
             where i.protocolo = :new.nuchave;
          exception
            when others then
              raise;
          end;
        end if;
      
      end if;
    
      ------------------------------------------------------------------------------------------------
    
      if :new.tabela = 'AD_CABSOLCPA' then
      
        v_enviamail := 'S';
      
        /*
          Alteração: Aprovadores - Solicitação de Compras
          Data: 24/04/2017
          Autor: Gusttavo Lopes
          ---Tela - Solicitação de compra
          ---  Rotinas Personalizadas » Almoxarifado » Telas Adicionais » Solicitação de compra
          --- SubTela - Aprovadores
        */
      
        ---Liberado
        if nvl(:new.reprovado, 'N') = 'N' then
          mail.assunto  := 'Solicitação liberada.';
          mail.mensagem := '<br> A solicitação de Liberação para ' || v_descrevento || ', ' ||
                           'referente ao código nº ' || :new.nuchave || ', foi liberada no sistema.';
        
        else
          ---Reprovado
          mail.assunto  := 'Solicitação Reprovada.';
          mail.mensagem := '<br> A solicitação de liberação para ' || v_descrevento || ', ' ||
                           'referente ao código nº ' || :new.nuchave || ', foi reprovada no sistema.' ||
                           '<br> Motivo: ' || :new.obslib;
        
        end if;
      
      end if;
    
      if :new.tabela = 'AD_TSFCAPSOL' then
      
        declare
          v_codususol number;
        begin
        
          ad_pkg_cap.v_permite_edicao := true;
        
          v_enviamail := 'S';
        
          if nvl(:new.reprovado, 'N') = 'N' then
          
            begin
              update ad_tsfcapsol s
                 set s.status = 'L'
               where nucapsol = :new.nuchave;
            exception
              when others then
                raise;
            end;
          
            select s.codusu
              into v_codususol
              from ad_tsfcapsol s
             where nucapsol = :new.nuchave;
          
            insert into execparams
              (idsessao, sequencia, nome, tipo, numint)
            values
              ('liberaeeenviaparaagendamento', 1, 'NUCAPSOL', 'I', :new.nuchave);
          
            /* Ao liberar, já envia a solicitação automaticamente, evitando que o solicitante
            * necessite entrar na solicitação e realizar o envio manualmente.
            */
            ad_stp_cap_enviaagend(v_codususol, 'liberaeeenviaparaagendamento', 1, errmsg);
          
            delete from execparams
             where idsessao = 'liberaeeenviaparaagendamento';
          
            mail.assunto  := 'Solicitação liberada.';
            mail.mensagem := '<br> A solicitação de Liberação para ' || v_descrevento || ', ' ||
                             'referente ao código nº ' || :new.nuchave || ', foi liberada no sistema.';
          
          else
          
            begin
              update ad_tsfcapsol s
                 set s.status = 'SR' --Sol. Reprovada
               where nucapsol = :new.nuchave;
            exception
              when others then
                raise;
            end;
          
            mail.assunto  := 'Solicitação Reprovada.';
            mail.mensagem := '<br> A solicitação de liberação para ' || v_descrevento || ', ' ||
                             'referente ao código nº ' || :new.nuchave || ', foi reprovada no sistema.' ||
                             '<br> Motivo: ' || :new.obslib;
          end if;
        
        exception
          when others then
            raise_application_error(-20105, sqlerrm);
        end;
      
      end if;
    
      -- Bloco adicionado dia 11/06/2018
      -- por M. Rangel
      -- enviar e-mail de liberação/reprovação do evento de horas/máquina
    
      if :new.tabela = 'TGFCAB' and :new.evento = 1011 then
        if nvl(:new.reprovado, 'N') = 'N' then
          mail.assunto  := 'Solicitação liberada.';
          mail.mensagem := '<br> A solicitação de Liberação para ' || v_descrevento || ', ' ||
                           'referente ao código nº ' || :new.nuchave || ', foi liberada no sistema.';
        else
          mail.assunto  := 'Solicitação Reprovada.';
          mail.mensagem := '<br> A solicitação de Liberação para ' || v_descrevento || ', ' ||
                           'referente ao código nº ' || :new.nuchave || ', foi reprovada no sistema.';
        end if;
      end if;
    
      --m. rangel - 08/07/2020
      -- atualização de status das revisões de pag frete km
      if :new.tabela = 'AD_TSFRPFC' then
      
        declare
          v_status varchar2(1);
          tipo     varchar2(1);
        begin
        
          if nvl(:new.reprovado, 'N') = 'N' then
            v_status := 'L';
          else
            v_status := 'R';
          end if;
        
          /*select motivo
           into tipo
           from ad_tsfrpfc r
          where r.nurpfc = :new.nuchave;*/
        
          --if tipo = '1' or tipo = '2' then
          begin
            update ad_tsfrpfc r
               set status      = v_status,
                   r.codusulib = :new.codusulib,
                   dhlib       = :new.dhlib,
                   r.obslib    = :new.obslib,
                   r.log       = r.log || chr(13) || to_char(sysdate, 'dd/mm/yyyy hh24:mi:ss') || ' - ' ||
                                 'Liberação do evento ' || :new.evento || ' pelo usuário ' || :new.codusulib || ' - ' ||
                                 ad_get.nomeusu(:new.codusulib, 'completo')
             where nurpfc = :new.nuchave;
          exception
            when others then
              errmsg := 'Erro ao atualizar status da revisão de pagamento de frete! ' || sqlerrm;
              raise_application_error(-20105, ad_fnc_formataerro(errmsg));
          end;
        
        end;
      
      end if;
    
      if :new.evento = eventos.evelibconfped then
        v_enviamail := 'S';
      end if;
    
      if :new.codusulib > 0 and mail.assunto is not null and v_enviamail = 'S' then
      
        --Ad_Stp_Gravafilabi(Mail.Assunto, Mail.Mensagem, Mail.Email);
        ad_set.insere_mail_fila_fmg(mail.assunto, mail.mensagem, mail.email, :new.nuchave, :new.evento);
      
        ad_set.ins_avisosistema(p_titulo => 'Liberação realizada.',
                                p_descricao => 'Ocorreu uma liberação em uma solicitação realizada por você.',
                                p_solucao => 'Verifique o evento ' || v_descrevento || ', lançamento ' || :new.nuchave,
                                p_usurem => :new.codusulib, p_usudest => :new.codususolicit, p_prioridade => 1,
                                p_tabela => :new.tabela, p_nrounico => :new.nuchave, p_erro => errmsg);
        if errmsg is not null then
          raise_application_error(-20105, ad_fnc_formataerro(errmsg));
        end if;
      end if;
    
    end if;
    -- fim if updating dhlib
  
    -- grava log 
    begin
      ----Valores Antigos
      insert into ad_tsiliblog
        (nuchave, tabela, dhsolicit, dhlib, codususol, codusulib, codusuexc, vlratual, vlrliberado, evento, observacao,
         obslib, operacao, dhoper, seqlog, nuadto)
      values
        (:old.nuchave, :old.tabela, :old.dhsolicit, :old.dhlib, :old.codususolicit, :old.codusulib, v_codusulog,
         :old.vlratual, :old.vlrliberado, :old.evento, :old.observacao, :old.obslib, 'Alteração - valores antigos',
         sysdate, ad_seq_tsilib_log.nextval, :new.ad_nuadto);
    
      ----Valores Novos    
      insert into ad_tsiliblog
        (nuchave, tabela, dhsolicit, dhlib, codususol, codusulib, codusuexc, vlratual, vlrliberado, evento, observacao,
         obslib, operacao, dhoper, seqlog, nuadto)
      values
        (:new.nuchave, :new.tabela, :new.dhsolicit, :new.dhlib, :new.codususolicit, :new.codusulib, v_codusulog,
         :new.vlratual, :new.vlrliberado, :new.evento, :new.observacao, :new.obslib, 'Alteração - valores novos',
         sysdate, ad_seq_tsilib_log.nextval, :new.ad_nuadto);
    
    exception
      when others then
        errmsg := 'Erro ao gravar o log da exclusão da liberação. ' || sqlerrm;
        raise_application_error(-20105, ad_fnc_formataerro(errmsg));
    end;
  
  end if;
  -- fim if updating

  if deleting then
  
    mail.email := ad_get.mailusu(:old.codusulib);
    mail.email := mail.email || ', ' || ad_get.mailusu(:old.codususolicit);
  
    select nvl(u.nomeusucplt, u.nomeusu)
      into v_nomesolicit
      from tsiusu u
     where codusu = stp_get_codusulogado;
  
    mail.assunto  := 'Exclusão de liberação.';
    mail.mensagem := '<br> A solicitação de liberação para ' || v_descrevento || ', ' || 'referente ao código nº ' ||
                     :old.nuchave || ', foi excluída no sistema por ' || v_nomesolicit;
  
    if :old.tabela = 'AD_TSFDEF' then
    
      v_enviamail := 'S';
    
      begin
        select d.ordemcarga
          into v_ordcarga
          from ad_tsfdef d
         where nudef = :old.nuchave;
      exception
        when no_data_found then
          v_ordcarga := 0;
      end;
    
      mail.assunto  := 'Exclusão de liberação.';
      mail.mensagem := '<br> A solicitação de liberação para pagamento    de despesas extras de fretes, ' ||
                       'referente à Ordem de Carga nº ' || v_ordcarga || ', no valor de ' ||
                       ad_get.formatavalor(:old.vlratual) || ', foi excluída no sistema por ' || v_nomesolicit;
    
    end if;
  
    if :old.tabela = 'AD_MULCONT' then
    
      v_enviamail := 'S';
    
      mail.assunto  := 'Exclusão de liberação.';
      mail.mensagem := '<br> A solicitação de liberação para pagamento de multa, ' ||
                       'referente código de controle de multas nº ' || :new.nuchave || ', no valor de ' ||
                       ad_get.formatavalor(:old.vlratual) || ', foi excluída no sistema por ' || v_nomesolicit;
    
    end if;
  
    begin
    
      insert into ad_tsiliblog
        (nuchave, tabela, dhsolicit, dhlib, codususol, codusulib, codusuexc, vlratual, vlrliberado, evento, observacao,
         obslib, operacao, dhoper, seqlog)
      values
        (:old.nuchave, :old.tabela, :old.dhsolicit, :old.dhlib, :old.codususolicit, :old.codusulib, v_codusulog,
         :old.vlratual, :old.vlrliberado, :old.evento, :old.observacao, :old.obslib, 'Exclusão', sysdate,
         ad_seq_tsilib_log.nextval);
    exception
      when others then
        errmsg := 'Erro ao gravar o log da exclusão da liberação. ' || sqlerrm;
        raise_application_error(-20105, ad_fnc_formataerro(errmsg));
    end;
  
    if :old.codusulib > 0 and mail.assunto is not null and v_enviamail = 'S' then
      ad_set.insere_mail_fila_fmg(mail.assunto, mail.mensagem, mail.email, :old.nuchave, :old.evento);
      --Ad_Stp_Gravafilabi(Mail.Assunto, Mail.Mensagem, Mail.Email);
    end if;
  
  end if;

end;
/
