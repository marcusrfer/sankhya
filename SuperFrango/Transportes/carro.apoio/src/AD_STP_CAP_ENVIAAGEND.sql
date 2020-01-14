create or replace procedure "AD_STP_CAP_ENVIAAGEND"(p_codusu number,
                                                    p_idsessao varchar2,
                                                    p_qtdlinhas int,
                                                    p_mensagem out varchar2) is
  r_sol           ad_tsfcapsol%rowtype;
  r_cap           ad_tsfcap%rowtype;
  r_rat           ad_tsfcaprat%rowtype;
  r_lib           tsilib%rowtype;
  v_dtenvio       date := sysdate;
  v_rota          varchar2(4000);
  v_mailexec      tmdfmg.email%type;
  v_count         int := 0;
  v_percrattot    float;
  v_origdestigual boolean;
  v_horasuteis    int;
  o               int := 0;
  d               int := 0;
  v_incluir       boolean := true;
  v_titulo        varchar2(2000);
  v_msgconf       varchar2(2000);
  v_simnao        char(1);
  itaberai        boolean := false;
  errmsg          varchar2(4000);
  error exception;
  debugando boolean := false;
begin
  /*
  Autor: Marcus Rangel
  Processo: Carro de Apoio
  Objetivo: Enviar a solicitação de carro para o responsável pelo agendamento.
  
  */

  /* LOG DE MUDANÃ‡AS
  23/11/2016 - Inserida a quantidade de passageiros
  28/11/2016 - Tratativa para prazo mÃ­nimo se origem = destino
  02/12/2016 - Adicionado motivo da viagem
  13/01/2017 - Consulta que verifica documentos pendentes alterada para considerar agendamentos "vencidos" sem voucher como pendente de documentos
  26/06/2017 - lançaar solicitação com data retroativa
  26/06/2017 - Se origem e destino iguais e iguais a ItaberaÃ­, não valida prazo.
  29/05/2018 - M. Rangel - Enviar o rateio da solictaçaÃ£o para o agendamento gerado.
  */

  ad_pkg_cap.v_permite_edicao := true;

  for i in 1 .. p_qtdlinhas
  loop
    r_sol.nucapsol := act_int_field(p_idsessao, i, 'NUCAPSOL');
  
    begin
      select * into r_sol from ad_tsfcapsol s where s.nucapsol = r_sol.nucapsol;
    exception
      when no_data_found then
        errmsg := 'A Solicitação de Carro de Apoio nro ' || r_sol.nucapsol || ' não existe ou não foi encontrada.';
        raise error;
    end;
  
    /*Validações*/
    begin
    
      /* Valida o Status*/
      if r_sol.status not in ('P', 'L', 'SR') then
        errmsg := 'Somente solicitações pendentes ou liberadas podem ser enviadas para agendamento.';
        raise error;
      end if;
    
      if r_sol.status in ('P', 'SR') then
      
        /* Valida o centro de resultado */
        if r_sol.codcencus is null or r_sol.codcencus = 0 then
          errmsg := 'Centro de Resultados não informado.';
          raise error;
        end if;
      
        /*  valida existÃªncia de agendamento*/
        if r_sol.nuap is not null then
          errmsg := 'Já consta um agendamento para essa solicitação (Nro ' || r_sol.nuap || ')';
          raise error;
        end if;
      
        /*valida o percentual do rateio*/
        begin
          select sum(r.percentual) into v_percrattot from ad_tsfcaprat r where nucapsol = r_sol.nucapsol;
        
          if v_percrattot is not null and v_percrattot <> 100 then
            errmsg := 'Total do rateio incorreto. Verifique se a soma do rateio atingiu 100%.';
            raise error;
          end if;
        end;
      
        /*
        Valida a data de agendamento, impedindo que envie solicitaçaÃµes com data retroativa
        If r_sol.dtagend < v_DtEnvio Then
          Errmsg := 'A data de agendamento não pode ser menor que a data atual. Por favor, atualize a data de agendamento.';
          Raise error;
        End If;
        */
      
        begin
          if r_sol.qtdpassageiros is null then
            errmsg := 'Informe a quantidades de passageiros.';
            raise error;
          end if;
        end;
      
        -- Valida Documentos Pendentes
        --- 'S' de SolicitaçaÃ£o
        begin
          errmsg := ad_pkg_cap.voucher_pendentes(r_sol.nucapsol, 'S');
          if errmsg is not null then
            raise error;
          end if;
        end;
      
        /* Valida digitaçaÃ£o do itinerário */
        begin
          select count(*)
            into v_count
            from ad_tsfcapitn
           where nucapsol = r_sol.nucapsol
             and tipotin in ('O', 'D');
        
          if mod(v_count, 2) = 1 or v_count = 0 then
            errmsg := 'Necessário informar a origem e o destino na aba "Itinerário".';
            raise error;
          end if;
        
          for c_int in (select case
                                 when i.tipotin = 'O' then
                                  1
                                 else
                                  0
                               end as orig,
                               case
                                 when i.tipotin = 'D' then
                                  1
                                 else
                                  0
                               end as dest
                          from ad_tsfcapitn i
                         where i.nucapsol = r_sol.nucapsol)
          loop
            o := o + c_int.orig;
            d := d + c_int.dest;
          end loop;
        
          if o <> d then
            errmsg := 'Favor verifique as origens e o destinos na aba itinerário!';
            raise error;
          end if;
        
          /* Grava na solicitação o momento que o usuário solicitou o envio
          e o lançaamento passou das validaçaÃµes iniciais. A diferençaa entre o
          horário do envio da solicitação e o horário de recebimento do
          agendamento se dará pelo tempo para liberar a solicitação */
          begin
            update ad_tsfcapsol s set s.dhenvio = v_dtenvio where nucapsol = r_sol.nucapsol;
          exception
            when others then
              errmsg := 'Ocorreu um erro ao atualizar os horários de envio da solicitação. <br>' || sqlerrm;
              raise error;
          end;
        
          /* AlteraçaÃ£o realizada no dia 26/06/2017 a pedido do Sr. Márcio Moura
          * A solicitação consiste em permirtir o lançamento de solicitações retroativas
          * sem a necessidade de aprovação do GE, apenas do responsável da área.
          * tal medida, visa permitir lançaar no sistema as solicitações que foram
          * atendidas sem passar pelo processo desenhado no sistema.
          */
          if r_sol.dtagend < r_sol.dhsolicit or r_sol.dtagend < v_dtenvio then
          
            v_titulo  := 'Atenção, problemas com as datas';
            v_msgconf := 'A solicitação em questão, possui data de agendamento menor que a data de solicitação ou de envio.' ||
                         '<br> Essa solicitação será enviada para Aprovação da Área.<br>Deseja Continuar?';
          
            --v_Incluir := Act_Confirmar(v_Titulo, v_MsgConf, p_Idsessao, i);
          
            if debugando = false then
              v_simnao := act_escolher_simnao(p_titulo => v_titulo, p_texto => v_msgconf, p_chave => p_idsessao,
                                              p_sequencia => i);
            else
              v_simnao := 'S';
            end if;
          
            if nvl(v_simnao, 'N') = 'S' then
              v_incluir := true;
            else
              v_incluir := false;
              return;
            end if;
          
            if v_incluir then
            
              --busca o liberador
              select evelibsolcarrohor, e.codlibcap
                into r_lib.evento, r_lib.codusulib
                from ad_tsfelt e
               where e.nuelt = 1;
            
              --insere a solicitação de liberação
              ad_set.ins_liberacao(p_tabela => 'AD_TSFCAPSOL', p_nuchave => r_sol.nucapsol, p_evento => r_lib.evento,
                                   p_valor => 1, p_codusulib => r_lib.codusulib,
                                   p_obslib => 'Ref. Solicitação de carro de apoio nro ' || r_sol.nucapsol,
                                   p_errmsg => errmsg);
              if errmsg is not null then
                raise error;
              end if;
            
              /* Atualiza o status da solicitação para "Aguardando liberaçaÃ£o"*/
              begin
                update ad_tsfcapsol set status = 'AL' where nucapsol = r_sol.nucapsol;
              exception
                when others then
                  errmsg := sqlerrm;
                  raise error;
              end;
            
              return;
            
            end if;
          
          end if;
        
        end;
      
        /* Valida o prazo mínimo de agendamento para cidades diferentes */
        begin
          v_origdestigual := ad_pkg_cap.compara_destino(r_sol.nucapsol);
        
          /*AlteraçaÃ£o dia 26/06/2017
          * Passar somente se origem e destino forem iguai a Itaberaí
          */
          if v_origdestigual then
          
            for c_int in (select distinct itn.tipotin, codcid from ad_tsfcapitn itn where itn.nucapsol = r_sol.nucapsol)
            loop
            
              if c_int.tipotin = 'O' and c_int.codcid = 2 then
                itaberai := true;
              else
                itaberai := false;
              end if;
            
              if c_int.tipotin = 'D' and c_int.codcid = 2 then
                itaberai := true;
              else
                itaberai := false;
              end if;
            
            end loop;
          end if;
        
          if v_origdestigual and itaberai then
            null;
          else
          
            /* If ((((r_Sol.Dtagend - r_Sol.Dhsolicit) * 24) < 24) Or (((r_Sol.Dtagend - v_DtEnvio) * 24) < 24)) And r_sol.status = 'P' Then */
          
            --v_HorasUteis := ad_get.horasuteis(r_Sol.Dhsolicit, r_sol.dtagend);
            v_horasuteis := ad_get.horasuteis(p_dataini => v_dtenvio, p_datafin => r_sol.dtagend);
          
            if v_horasuteis < nvl(get_tsipar_inteiro('PRAZOSOLCARROAP'), 24) then
            
              v_titulo  := 'Atenção, problemas com horário';
              v_msgconf := 'A solicitação em questão, não atende ao prazo de antecedência mínima de 24 Hrs. Essa solicitação será enviada para Aprovação do responsável.
							<br>Deseja Continuar?';
            
              --v_Incluir := Act_Confirmar(v_Titulo, v_MsgConf, p_Idsessao, i);
            
              v_simnao := act_escolher_simnao(p_titulo => v_titulo, p_texto => v_msgconf, p_chave => p_idsessao,
                                              p_sequencia => i);
            
              if nvl(v_simnao, 'N') = 'S' then
                v_incluir := true;
              else
                v_incluir := false;
              end if;
            
              if v_incluir then
              
                select evelibsolcarrohor, e.codusuge
                  into r_lib.evento, r_lib.codusulib
                  from ad_tsfelt e
                 where e.nuelt = 1;
              
                if r_lib.evento is null or r_lib.codusulib is null then
                  errmsg := 'Os parâmetros "Evento de liberação" ou "Liberador" não estão informados na tela de Eventos de <i>liberações de Transporte</i>';
                  raise error;
                end if;
              
                /* Insere a liberaçaÃ£o para o GE */
                ad_set.ins_liberacao(p_tabela => 'AD_TSFCAPSOL', p_nuchave => r_sol.nucapsol, p_evento => r_lib.evento,
                                     p_valor => 1, p_codusulib => r_lib.codusulib,
                                     p_obslib => 'Ref. Solicitação de carro de apoio nro ' || r_sol.nucapsol,
                                     p_errmsg => errmsg);
              
                if errmsg is not null then
                  raise error;
                end if;
              
                /* Insere o envio da solicitação de liberaçaÃ£o */
                ad_set.ins_avisosistema(p_titulo => 'Liberação Solicitada',
                                        p_descricao => 'Foi solicitada liberação para carros de apoio solicitados fora do prazo!' ||
                                                        '\nMotivo: ' || r_sol.motivo,
                                        p_solucao => 'Verifique o lançamento para maiores detalhes',
                                        p_usurem => p_codusu, p_usudest => r_lib.codusulib, p_prioridade => 1,
                                        p_tabela => 'AD_TSFCAPSOL', p_nrounico => r_sol.nucapsol, p_erro => errmsg);
              
                if errmsg is not null then
                  raise error;
                end if;
              
                /* Envia o mail da solicitação de liberaçaÃ£o */
                select u.email into v_mailexec from tsiusu u where codusu = r_lib.codusulib;
              
                ad_stp_gravafilabi(p_assunto => 'Liberação Solicitada.',
                                   p_mensagem => 'Foi solicitada liberação para agendamento de carro de apoio fora do prazo de antecedência de 24 Hrs. ' ||
                                                  '\nNro Solicitação: ' || r_sol.nucapsol || '\nSolicitante: ' ||
                                                  ad_get.nomeusu(r_sol.codusu, 'completo') || '\nDt. Solicitação: ' ||
                                                  to_char(r_sol.dhsolicit, 'DD/MM/YYYY') || '\nMotivo: ' || r_sol.motivo,
                                   p_email => v_mailexec);
              
                /* Atualiza o status da solicitação para "Aguardando liberaçaÃ£o"*/
                begin
                  update ad_tsfcapsol set status = 'AL' where nucapsol = r_sol.nucapsol;
                exception
                  when others then
                    errmsg := sqlerrm;
                    raise error;
                end;
              
                return;
              else
                errmsg := 'Envio cancelado.';
                raise error;
              end if;
            
            end if;
          end if;
        
        end;
        -- fim valida cidade
      
        -- valida rateio
        begin
          for rat in (select * from ad_tsfcaprat r where r.nucapsol = r_sol.nucapsol)
          loop
          
            ad_stp_valida_natcrproj_sf(rat.codemp, 189, rat.codnat, rat.codcencus, rat.codproj, 0, p_mensagem);
          
            if p_mensagem is not null then
              rollback;
              return;
            end if;
          
          end loop;
        end;
        -- fim valida rateio
      
      end if;
    end;
    -- fim validações
  
    /* Insere o agendamento */
    begin
      --r_Cap.Codusuexc := Get_Tsipar_Inteiro('CODUSURESPCAP');
    
      select e.codlibcap into r_cap.codusuexc from ad_tsfelt e where e.nuelt = 1;
    
      if r_cap.codusuexc is null /*Or r_cap.codusuexc = 0*/
       then
        errmsg := 'O usuário responsável na tela de eventos de <í>liberação de Transportes.</i>';
        raise error;
      end if;
    
      v_rota := null;
      for r in (select decode(itn.tipotin, 'O', 'Origem', 'D', 'Destino', 'I', 'Intermediário') || ': ' || cid.nomecid ||
                       ' - ' || ufs.uf || ', ' || end.tipo || '  ' || end.nomeend || ', ' || itn.complemento || ' - ' ||
                       bai.nomebai || ' - ' || itn.referencia as v_end
                  from ad_tsfcapitn itn
                  left join tsiend end
                    on (itn.codend = end.codend)
                  left join tsibai bai
                    on (itn.codbai = bai.codbai)
                  left join tsicid cid
                    on (itn.codcid = cid.codcid)
                  left join tsiufs ufs
                    on (cid.uf = ufs.coduf)
                 where itn.nucapsol = r_sol.nucapsol)
      loop
        if v_rota is null then
          v_rota := r.v_end;
        else
          v_rota := v_rota || chr(13) || r.v_end;
        end if;
      
      end loop;
    
      v_rota := 'Solicitação nº: ' || r_sol.nucapsol || ', Usu. Solicitante: ' ||
                ad_get.nomeusu(r_sol.codusu, 'resumido') || chr(13) || v_rota;
    
      /* Busca o itenerário para registrar no agendamento
      SolicitaçaÃ£o realizada por Márcio Moura em 15/05/2017*/
    
      for c_cid in (select * from ad_tsfcapitn itn where itn.nucapsol = r_sol.nucapsol)
      loop
        begin
        
          if c_cid.tipotin = 'O' then
            r_cap.codcidorig := c_cid.codcid;
          elsif c_cid.tipotin = 'D' then
            r_cap.codciddest := c_cid.codcid;
          end if;
        
          select c.nomecid into r_cap.nomecidorig from tsicid c where c.codcid = r_cap.codcidorig;
          select c.nomecid into r_cap.nomeciddest from tsicid c where c.codcid = r_cap.codciddest;
        
        exception
          when no_data_found then
            if r_cap.codciddest is null then
              r_cap.codciddest := r_cap.codcidorig;
            end if;
          when others then
            errmsg := 'Erro ao buscar as cidades de origem e destino da solicitação nro ' || r_sol.nucapsol;
            raise error;
        end;
      end loop;
    
      /* Gera o agendamento */
      <<inicio_agend>>
    
      begin
      
        stp_keygen_tgfnum('AD_TSFCAP', 1, 'AD_TSFCAP', 'NUAP', 0, r_cap.nuap);
      
        insert into ad_tsfcap
          (nuap, codususol, dhsolicit, dtagend, codusuexc, status, taxi, motivotaxi, kminicial, kmfinal, totalkm,
           vlrcorrida, ordemcarga, nucapsol, rota, qtdpassageiros, motivo, codcidorig, nomecidorig, codciddest,
           nomeciddest, dhmov, dhenvio)
        values
          (r_cap.nuap, r_sol.codusu, r_sol.dhsolicit, r_sol.dtagend, r_cap.codusuexc, 'P', 'N', null, 0, 0, 0, 0, 0,
           r_sol.nucapsol, v_rota, r_sol.qtdpassageiros, r_sol.motivo, r_cap.codcidorig, r_cap.nomecidorig,
           r_cap.codciddest, r_cap.nomeciddest, sysdate, r_sol.dhenvio);
      
      exception
        when dup_val_on_index then
        
          merge into tgfnum n
          using (select max(nuap) maxnuap from ad_tsfcap) c
          on (n.arquivo = 'AD_TSFCAP' and n.codemp = 1 and n.serie = ' ')
          when matched then
            update set n.ultcod = c.maxnuap
          when not matched then
            insert (arquivo, codemp, serie, automatico, ultcod) values ('AD_TSFCAP', 1, ' ', 'S', c.maxnuap);
        
          goto inicio_agend;
        when others then
          errmsg := 'Erro ao inserir o agendamento. ' || sqlerrm;
          raise error;
      end;
    
      -- insere o rateio quando sÃ³ há um CR, tratativa para quando enviar para a tela de acerto, conseguir realizar o calculo com varias corridas no mesmo dia.
      begin
        select count(*) into v_count from ad_tsfcaprat rat where rat.nucapsol = r_sol.nucapsol;
      
        if v_count = 0 then
        
          select nvl(codemp, 1) into r_rat.codemp from tsiusu u where codusu = r_sol.codusu;
        
          insert into ad_tsfcaprat
            (nucapsol, nucaprat, codemp, codnat, codcencus, percentual)
          values
            (r_sol.nucapsol, 1, r_rat.codemp, 4051300, r_sol.codcencus, 100);
        end if;
      exception
        when others then
          errmsg := 'Erro ao inserir o rateio Único na solicitação';
          raise error;
      end;
    
      -- insere os documentos
      begin
        insert into ad_tsfcapdoc
          (nuap, seqdoc, codsolicit, codcencus, entregue)
        values
          (r_cap.nuap, 1, r_sol.codusu, r_sol.codcencus, 'N');
      exception
        when others then
          errmsg := 'Erro ao inserir o controle de documento. <br>' || sqlerrm;
          raise error;
      end;
    
      -- envia o rateio
      declare
        v_numfrt pls_integer := 0;
      begin
        for c_rat in (select * from ad_tsfcaprat where nucapsol = r_sol.nucapsol)
        loop
        
          v_numfrt := v_numfrt + 1;
        
          insert into ad_tsfcapfrt
            (nuap, numfrt, codemp, codcencus, codnat, codproj, percentual)
          values
            (r_cap.nuap, v_numfrt, c_rat.codemp, c_rat.codcencus, c_rat.codnat, c_rat.codproj, c_rat.percentual);
        
        end loop;
      end;
    
      /* Insere o aviso do sistema */
      begin
        ad_set.ins_avisosistema(p_titulo => 'Nova Solicitação de Agendamento.',
                                p_descricao => 'Uma nova solicitação de agendamento de carro de apoio foi registrada por usuário ' ||
                                                ad_get.nomeusu(r_sol.codusu, 'resumido') || '.',
                                p_solucao => 'Para detalhes, acesse o registro ', p_usurem => r_sol.codusu,
                                p_prioridade => 2, p_usudest => r_cap.codusuexc, p_tabela => 'AD_TSFCAP',
                                p_nrounico => r_cap.nuap, p_erro => errmsg);
      
        if errmsg is not null then
          raise error;
        end if;
      end;
    
      /* Notifica o agendador sobre a nova solicitação por e-mail */
      /*15/05/2017 - Removido a pedido de Marcio Moura, atual responsável pela área na empresa */
    
      /*
      Begin
        Select Email Into v_Mailexec From Tsiusu Where Codusu = r_Cap.Codusuexc;
        Select Nomeusu Into v_Nomesol From Tsiusu Where Codusu = r_Sol.Codusu;
      
        Ad_Stp_Gravafilabi(p_Assunto  => 'Nova solicitação de Agendamento.',
                           p_Mensagem => 'AtençaÃ£o, uma nova solicitação de agendamento de carro de apoio, do usuário ' ||
                                         v_Nomesol || ' foi cadastrada. ' ||
                                         'NÃºmero da solicitação: <a href="' || v_Link ||
                                         '" target="_black" title="Abri Tela">' || r_Cap.Nuap ||
                                         '</a><br>',
                           p_Email    => v_Mailexec);
      End;
      */
    
      begin
        update ad_tsfcapsol s
           set s.status = 'E',
               nuap     = r_cap.nuap
         where nucapsol = r_sol.nucapsol;
      end;
    
    end;
  end loop;

  if p_qtdlinhas < 2 then
    p_mensagem := 'Lançameto(s) enviado(s) para Agendamento com sucesso!!!<br> Agendamento nro: ' || r_cap.nuap;
  else
    p_mensagem := 'Foram gerados ' || p_qtdlinhas || ' agendamentos';
  end if;

exception
  when error then
    rollback;
    p_mensagem := '<p><font color="#FF0000" size="14"><b>Atenção!!!</b></font></p>' || errmsg;
    /* When Others Then
    Rollback;
    Errmsg     := Sqlerrm;
    p_Mensagem := '<p><font color="#FF0000" size="14"><b>AtençaÃ£o!!!</b></font></p>' || Errmsg;*/
end;
/
