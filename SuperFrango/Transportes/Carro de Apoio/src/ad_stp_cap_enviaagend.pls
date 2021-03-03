create or replace procedure ad_stp_cap_enviaagend(p_codusu    number,
                                                  p_idsessao  varchar2,
                                                  p_qtdlinhas int,
                                                  p_mensagem  out varchar2) is
  r_sol           ad_tsfcapsol%rowtype;
  r_cap           ad_tsfcap%rowtype;
  r_rat           ad_tsfcaprat%rowtype;
  r_elt           ad_tsfelt%rowtype;
  v_cpf           varchar2(20);
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

begin
  /*
  Autor: Marcus Rangel
  Processo: Carro de Apoio
  Objetivo: Enviar a solicita��o de carro para o respons�vel pelo agendamento.
  
  */

  /* mudan�as
  23/11/2016 - Inserida a quantidade de passageiros
  28/11/2016 - Tratativa para prazo mínimo se origem = destino
  02/12/2016 - Adicionado motivo da viagem
  13/01/2017 - Consulta que verifica documentos pendentes alterada para considerar 
             agendamentos "vencidos" sem voucher como pendente de documentos
  26/06/2017 - lan�aar solicita��o com data retroativa
  26/06/2017 - Se origem e destino iguais e iguais a Itaberaí, n�o valida prazo.
  29/05/2018 - M. Rangel - Enviar o rateio da solicta�aão para o agendamento gerado.
  04/03/2020 - m. rangel - adequa��o para atender as loca��es de ve�culos
  */

  ad_pkg_cap.v_permite_edicao := true;

  for i in 1 .. p_qtdlinhas
  loop
  
    r_sol.nucapsol := act_int_field(p_idsessao, i, 'NUCAPSOL');
  
    begin
      select *
        into r_sol
        from ad_tsfcapsol s
       where s.nucapsol = r_sol.nucapsol;
    exception
      when no_data_found then
        p_mensagem := 'A Solicita��o de Carro de Apoio nro ' || r_sol.nucapsol || ' n�o existe ou n�o foi encontrada.';
        return;
    end;
  
    --busca os parametros
    begin
      select *
        into r_elt
        from ad_tsfelt e
       where e.nuelt = 1;
    
      -- verfica se existe algum suplente ativo
      select codususupl
        into r_elt.codlibcap
        from ad_tsisupl s
       where s.codusu = r_elt.codlibcap
         and trunc(sysdate) between s.dtinicio and s.dtfim
         and rownum = 1;
    
    exception
      when no_data_found then
        null;
      when others then
        p_mensagem := 'Erro ao buscar os par�metros. ' || sqlerrm;
        return;
    end;
  
    --> Valida��es
    begin
    
      --- Valida o Status
      if r_sol.status not in ('P', 'L', 'SR') then
        p_mensagem := 'Somente solicita��es pendentes ou liberadas podem ser enviadas para agendamento.';
        return;
      end if;
    
      -- entra se estatus for "Pendente" ou "Solicita�ao Reprovada"
      if r_sol.status in ('P', 'SR') then
      
        --- Valida o centro de resultado 
        if r_sol.codcencus is null or r_sol.codcencus = 0 then
          p_mensagem := 'Centro de Resultados n�o informado.';
          return;
        end if;
      
        --- valida existencia de agendamento
        if r_sol.nuap is not null then
          p_mensagem := 'J� consta um agendamento para essa solicita��o (Nro ' || r_sol.nuap || ')';
          return;
        end if;
      
        --- valida o percentual do rateio
        begin
          select sum(r.percentual)
            into v_percrattot
            from ad_tsfcaprat r
           where nucapsol = r_sol.nucapsol;
        
          if v_percrattot is not null and v_percrattot <> 100 then
            p_mensagem := 'Total do rateio incorreto. Verifique se a soma do rateio atingiu 100%.';
            return;
          end if;
        end;
      
        /*
        Valida a data de agendamento, impedindo que envie solicita�aões com data retroativa
        If r_sol.dtagend < v_DtEnvio Then
          p_mensagem := 'A data de agendamento n�o pode ser menor que a data atual. '||
          'Por favor, atualize a data de agendamento.';
          return;
        End If;
        */
      
        --- valida qtd de passageiros
        begin
          if r_sol.qtdpassageiros is null then
            p_mensagem := 'Informe a quantidades de passageiros.';
            return;
          end if;
        end;
      
        --> se do tipo carro de apoio
        if r_sol.tipo = 'CAP' then
        
          -- Valida Documentos Pendentes
          --- 'S' de Solicita�aão
          begin
            p_mensagem := ad_pkg_cap.voucher_pendentes(r_sol.nucapsol, 'S');
            if p_mensagem is not null then
              return;
            end if;
          end;
        
          /* Valida digitacao do itiner�rio */
          begin
            select count(*)
              into v_count
              from ad_tsfcapitn
             where nucapsol = r_sol.nucapsol
               and tipotin in ('O', 'D');
          
            if mod(v_count, 2) = 1 or v_count = 0 then
              p_mensagem := 'Necess�rio informar a origem e o destino na aba "Itiner�rio".';
              return;
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
              p_mensagem := 'Favor verifique as origens e o destinos na aba itiner�rio!';
              return;
            end if;
          
            /* Grava na solicita��o o momento que o usu�rio solicitou o envio
            e o lan�aamento passou das valida�aões iniciais. A diferen�aa entre o
            hor�rio do envio da solicita��o e o hor�rio de recebimento do
            agendamento se dar� pelo tempo para liberar a solicita��o */
            begin
              update ad_tsfcapsol s
                 set s.dhenvio = v_dtenvio
               where nucapsol = r_sol.nucapsol;
            exception
              when others then
                p_mensagem := 'Ocorreu um erro ao atualizar os hor�rios de envio da solicita��o. <br>' || sqlerrm;
                return;
            end;
          
            /* Altera�ao realizada no dia 26/06/2017 a pedido do Sr. M�rcio Moura
            * A solicita��o consiste em permirtir o lan�amento de solicita��es retroativas
            * sem a necessidade de aprova��o do GE, apenas do respons�vel da �rea.
            * tal medida, visa permitir lan�aar no sistema as solicita��es que foram
            * atendidas sem passar pelo processo desenhado no sistema.
            */
            if r_sol.dtagend < r_sol.dhsolicit or r_sol.dtagend < v_dtenvio then
            
              v_titulo  := 'Aten��o, problemas com as datas';
              v_msgconf := 'A solicita��o em quest�o, possui data de agendamento menor ' ||
                           'que a data de solicita��o ou de envio.' ||
                           '<br> Essa solicita��o ser� enviada para Aprova��o da �rea.<br>Deseja Continuar?';
            
              --v_Incluir := Act_Confirmar(v_Titulo, v_MsgConf, p_Idsessao, i);
              v_simnao := act_escolher_simnao(p_titulo => v_titulo, p_texto => v_msgconf, p_chave => p_idsessao,
                                              p_sequencia => i);
            
              if nvl(v_simnao, 'N') = 'S' then
                v_incluir := true;
              else
                return;
              end if;
            
              if v_incluir then
              
                --insere a solicita��o de libera��o
                ad_set.ins_liberacao(p_tabela => 'AD_TSFCAPSOL', p_nuchave => r_sol.nucapsol,
                                     p_evento => r_elt.evelibsolcarrohor, p_valor => 1, p_codusulib => r_elt.codlibcap,
                                     p_obslib => 'Ref. Solicita��o de carro de apoio nro ' || r_sol.nucapsol,
                                     p_errmsg => p_mensagem);
                if p_mensagem is not null then
                  return;
                end if;
              
                /* Atualiza o status da solicita��o para "Aguardando libera�ao"*/
                begin
                  update ad_tsfcapsol
                     set status = 'AL'
                   where nucapsol = r_sol.nucapsol;
                exception
                  when others then
                    p_mensagem := sqlerrm;
                    return;
                end;
              
                return;
              
              end if;
            
            end if;
          
          end;
        
          -- Valida o prazo m�nimo de agendamento para cidades diferentes 
          begin
          
            v_origdestigual := ad_pkg_cap.compara_destino(r_sol.nucapsol);
          
            /*Altera�ao dia 26/06/2017
            * Passar somente se origem e destino forem iguai a Itabera�
            */
            if v_origdestigual then
            
              for c_int in (select distinct itn.tipotin, codcid
                              from ad_tsfcapitn itn
                             where itn.nucapsol = r_sol.nucapsol)
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
            
              /* If ((((r_Sol.Dtagend - r_Sol.Dhsolicit) * 24) < 24) Or 
              (((r_Sol.Dtagend - v_DtEnvio) * 24) < 24)) And r_sol.status = 'P' Then */
            
              --v_HorasUteis := ad_get.horasuteis(r_Sol.Dhsolicit, r_sol.dtagend);
              v_horasuteis := ad_get.horasuteis(p_dataini => v_dtenvio, p_datafin => r_sol.dtagend);
            
              if v_horasuteis < nvl(get_tsipar_inteiro('PRAZOSOLCARROAP'), 24) then
              
                v_titulo  := 'Aten��o, problemas com hor�rio';
                v_msgconf := 'A solicita��o em quest�o, n�o atende ao prazo ' || 'de anteced�ncia m�nima de 24 Hrs. ' ||
                             'Essa solicita��o ser� enviada para Aprova��o do respons�vel.' || '
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
                
                  if r_elt.evelibsolcarrohor is null or r_elt.codlibcap is null then
                    p_mensagem := 'Os par�metros "Evento de libera��o" ou "Liberador" n�o est�o ' ||
                                  'informados na tela de Eventos de <i>libera��es de Transporte</i>';
                    return;
                  end if;
                
                  /* Insere a libera�a� para o GE */
                  ad_set.ins_liberacao('AD_TSFCAPSOL', r_sol.nucapsol, r_elt.evelibsolcarrohor, 1, r_elt.codlibcap,
                                       'Ref. Solicita��o de carro de apoio nro ' || r_sol.nucapsol, p_mensagem);
                
                  if p_mensagem is not null then
                    return;
                  end if;
                
                  /* Insere o envio da solicita��o de libera��o */
                  ad_set.ins_avisosistema(p_titulo => 'Libera��o Solicitada',
                                          p_descricao => 'Foi solicitada libera��o para carros de ' ||
                                                          'apoio solicitados fora do prazo!' || '\nMotivo: ' ||
                                                          r_sol.motivo,
                                          p_solucao => 'Verifique o lan�amento para maiores detalhes',
                                          p_usurem => p_codusu, p_usudest => r_elt.codusuge, p_prioridade => 1,
                                          p_tabela => 'AD_TSFCAPSOL', p_nrounico => r_sol.nucapsol, p_erro => p_mensagem);
                
                  if p_mensagem is not null then
                    return;
                  end if;
                
                  /* Envia o mail da solicita��o de libera�aão */
                  select u.email
                    into v_mailexec
                    from tsiusu u
                   where codusu = r_elt.codlibcap;
                
                  ad_stp_gravafilabi(p_assunto => 'Libera��o Solicitada.',
                                     p_mensagem => 'Foi solicitada libera��o para agendamento de ' ||
                                                    'carro de apoio fora do prazo de anteced�ncia ' || 'de 24 Hrs. ' ||
                                                    '\nNro Solicita��o: ' || r_sol.nucapsol || '\nSolicitante: ' ||
                                                    ad_get.nomeusu(r_sol.codusu, 'completo') || '\nDt. Solicita��o: ' ||
                                                    to_char(r_sol.dhsolicit, 'DD/MM/YYYY') || '\nMotivo: ' ||
                                                    r_sol.motivo, p_email => v_mailexec);
                
                  /* Atualiza o status da solicita��o para "Aguardando libera�aão"*/
                  begin
                    update ad_tsfcapsol
                       set status = 'AL'
                     where nucapsol = r_sol.nucapsol;
                  exception
                    when others then
                      p_mensagem := sqlerrm;
                      return;
                  end;
                
                  return;
                else
                  -- incluir = false
                  rollback;
                  return;
                end if; -- fim incluir
              
              end if;
            
            end if;
          
          end;
          -- fim valida cidade
        
        else
          -- LOCA��O
        
          if nvl(r_sol.codcondut, 0) = 0 then
            p_mensagem := 'Necess�rio informar o c�digo do parceiro condutor!';
            return;
          end if;
        
          ad_set.ins_liberacao(p_tabela => 'AD_TSFCAPSOL', p_nuchave => r_sol.nucapsol, p_evento => r_elt.eveliblocvei,
                               p_valor => 1, p_codusulib => r_elt.codliblocvei,
                               p_obslib => 'Ref. Loca��o de ve�culo de apoio nro: ' || r_sol.nucapsol,
                               p_errmsg => p_mensagem);
          if p_mensagem is not null then
            return;
          end if;
        
          /* Insere o envio da solicita��o de libera��o */
          ad_set.ins_avisosistema(p_titulo => 'Libera��o Solicitada',
                                  p_descricao => 'Foi solicitada libera��o para carros de ' ||
                                                  'apoio solicitados fora do prazo!' || '\nMotivo: ' || r_sol.motivo,
                                  p_solucao => 'Verifique o lan�amento para maiores detalhes', p_usurem => p_codusu,
                                  p_usudest => r_elt.codliblocvei, p_prioridade => 1, p_tabela => 'AD_TSFCAPSOL',
                                  p_nrounico => r_sol.nucapsol, p_erro => p_mensagem);
        
          if p_mensagem is not null then
            return;
          end if;
        
          /* Envia o mail da solicita��o de libera�aão */
          select u.email
            into v_mailexec
            from tsiusu u
           where codusu = r_elt.codliblocvei;
        
          ad_stp_gravafilabi(p_assunto => 'Libera��o Solicitada.',
                             p_mensagem => 'Foi solicitada libera��o para loca��o de ' ||
                                            've�culos de apoio \nNro Solicita��o: ' || r_sol.nucapsol ||
                                            '\nSolicitante: ' || ad_get.nomeusu(r_sol.codusu, 'completo') ||
                                            '\nDt. Solicita��o: ' || to_char(r_sol.dhsolicit, 'DD/MM/YYYY') ||
                                            '\nMotivo: ' || r_sol.motivo, p_email => v_mailexec);
        
          /* Atualiza o status da solicita��o para "Aguardando libera�ao"*/
          begin
            update ad_tsfcapsol
               set status = 'AL'
             where nucapsol = r_sol.nucapsol;
          exception
            when others then
              p_mensagem := 'Erro ao atulizar o status! ' || sqlerrm;
              return;
          end;
        
          p_mensagem := 'Solicita��o enviada para aprova��o com sucesso!';
        
          return;
        
        end if;
      
        -- valida rateio
        begin
          for rat in (select *
                        from ad_tsfcaprat r
                       where r.nucapsol = r_sol.nucapsol)
          loop
          
            ad_stp_valida_natcrproj_sf(rat.codemp, 189, rat.codnat, rat.codcencus, rat.codproj, 0, p_mensagem);
          
            if p_mensagem is not null then
              rollback;
              return;
            end if;
          
          end loop;
        end;
        -- fim valida rateio
      
      end if; -- sol.status
    
    end;
    -- fim valida��es
  
    /* Insere o agendamento */
    begin
    
      if nvl(r_elt.codlibcap, 0) = 0 then
        p_mensagem := 'O usu�rio respons�vel na tela de eventos de <�>libera��o de Transportes</i>' ||
                      ' n�o foi informado!';
        return;
      end if;
    
      -- monta o itiner�rio para ser usado no campo observa��o   
      begin
      
        v_rota := 'Solicita��o n�: ' || r_sol.nucapsol || ', Usu. Solicitante: ' ||
                  ad_get.nomeusu(r_sol.codusu, 'resumido');
      
        if nvl(r_sol.tipo, 'CAP') = 'CAP' then
        
          for r in (select decode(itn.tipotin, 'O', 'Origem', 'D', 'Destino', 'I', 'Intermedi�rio') || ': ' ||
                            cid.nomecid || ' - ' || ufs.uf || ', ' || end.tipo || '  ' || end.nomeend || ', ' ||
                            itn.complemento || ' - ' || bai.nomebai || ' - ' || itn.referencia as v_end
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
            v_rota := v_rota || chr(13) || r.v_end;
          end loop;
        
          /* Busca o itener�rio para registrar no agendamento
          Solicita�aão realizada por M�rcio Moura em 15/05/2017*/
          for c_cid in (select *
                          from ad_tsfcapitn itn
                         where itn.nucapsol = r_sol.nucapsol)
          loop
            begin
            
              if c_cid.tipotin = 'O' then
                r_cap.codcidorig := c_cid.codcid;
              elsif c_cid.tipotin = 'D' then
                r_cap.codciddest := c_cid.codcid;
              end if;
            
              select c.nomecid
                into r_cap.nomecidorig
                from tsicid c
               where c.codcid = r_cap.codcidorig;
              select c.nomecid
                into r_cap.nomeciddest
                from tsicid c
               where c.codcid = r_cap.codciddest;
            
            exception
              when no_data_found then
                if r_cap.codciddest is null then
                  r_cap.codciddest := r_cap.codcidorig;
                end if;
              when others then
                p_mensagem := 'Erro ao buscar as cidades de origem e destino da solicita��o nro ' || r_sol.nucapsol;
                return;
            end;
          end loop;
        
        else
        
          r_cap.motorista := r_sol.codcondut;
        
          select fmt.cnpj_cpf(p.cgc_cpf)
            into v_cpf
            from tgfpar p
           where p.codparc = r_sol.codcondut;
        
          r_sol.motivo := r_sol.motivo || chr(13) || 'CPF Condutor: ' || v_cpf;
        
        end if;
      
      end;
    
      /* Gera o agendamento */
      begin
      
        stp_keygen_tgfnum('AD_TSFCAP', 1, 'AD_TSFCAP', 'NUAP', 0, r_cap.nuap);
      
        r_cap.codususol      := r_sol.codusu;
        r_cap.dhsolicit      := r_sol.dhsolicit;
        r_cap.dtagend        := r_sol.dtagend;
        r_cap.nucapsol       := r_sol.nucapsol;
        r_cap.rota           := v_rota;
        r_cap.qtdpassageiros := r_sol.qtdpassageiros;
        r_cap.motivo         := r_sol.motivo;
        r_cap.dhenvio        := r_sol.dhenvio;
        r_cap.dtagend        := r_sol.dtagend;
        r_cap.tipo           := r_sol.tipo;
        r_cap.codusuexc      := r_elt.codlibcap;
        r_cap.codveiculo     := 0;
      
        if r_cap.tipo = 'LOC' then
          r_cap.temacerto := 'N';
        else
          r_cap.temacerto := 'S';
        end if;
      
        if r_sol.dtagendfim is null then
          r_cap.dtagendfim := r_sol.dtagend + 2 / 24;
        else
          r_cap.dtagendfim := r_sol.dtagendfim;
        end if;
      
        r_cap.status     := 'P';
        r_cap.taxi       := 'N';
        r_cap.motivotaxi := 'N';
        r_cap.kminicial  := 0;
        r_cap.kmfinal    := 0;
        r_cap.totalkm    := 0;
        r_cap.vlrcorrida := 0;
        r_cap.ordemcarga := 0;
        r_cap.dhmov      := sysdate;
      
        insert into ad_tsfcap
        values r_cap;
      
      exception
        when others then
          p_mensagem := 'Erro ao inserir o agendamento. ' || sqlerrm;
          return;
      end;
    
      /*insere o rateio quando soh h� um CR, tratativa para quando enviar 
      para a tela de acerto, conseguir realizar o calculo com varias corridas no mesmo dia.*/
      begin
        select count(*)
          into v_count
          from ad_tsfcaprat rat
         where rat.nucapsol = r_sol.nucapsol;
      
        if v_count = 0 then
        
          select nvl(codemp, 1)
            into r_rat.codemp
            from tsiusu u
           where codusu = r_sol.codusu;
        
          insert into ad_tsfcaprat
            (nucapsol, nucaprat, codemp, codnat, codcencus, percentual)
          values
            (r_sol.nucapsol, 1, r_rat.codemp, 4051300, r_sol.codcencus, 100);
        end if;
      exception
        when others then
          p_mensagem := 'Erro ao inserir o rateio �nico na solicita��o. ' || sqlerrm;
          return;
      end;
    
      -- insere os documentos
      begin
        insert into ad_tsfcapdoc
          (nuap, seqdoc, codsolicit, codcencus, entregue)
        values
          (r_cap.nuap, 1, r_sol.codusu, r_sol.codcencus, 'N');
      exception
        when others then
          p_mensagem := 'Erro ao inserir o controle de documento. <br>' || sqlerrm;
          return;
      end;
    
      -- envia o rateio
      declare
        v_numfrt pls_integer := 0;
      begin
        for c_rat in (select *
                        from ad_tsfcaprat
                       where nucapsol = r_sol.nucapsol)
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
        ad_set.ins_avisosistema(p_titulo => 'Nova Solicita��o de Agendamento.',
                                p_descricao => 'Uma nova solicita��o de agendamento de carro de apoio ' ||
                                                'foi registrada por usu�rio ' || ad_get.nomeusu(r_sol.codusu, 'resumido') || '.',
                                p_solucao => 'Para detalhes, acesse o registro ', p_usurem => r_sol.codusu,
                                p_prioridade => 2, p_usudest => r_cap.codusuexc, p_tabela => 'AD_TSFCAP',
                                p_nrounico => r_cap.nuap, p_erro => p_mensagem);
      
        if p_mensagem is not null then
          return;
        end if;
      end;
    
      /* Notifica o agendador sobre a nova solicita��o por e-mail */
      /*15/05/2017 - Removido a pedido de Marcio Moura, atual respons�vel pela �rea na empresa */
    
      /*
      Begin
        Select Email Into v_Mailexec From Tsiusu Where Codusu = r_Cap.Codusuexc;
        Select Nomeusu Into v_Nomesol From Tsiusu Where Codusu = r_Sol.Codusu;
      
        Ad_Stp_Gravafilabi(p_Assunto  => 'Nova solicita��o de Agendamento.',
                           p_Mensagem => 'Aten��o, uma nova solicita��o de agendamento '||
                                      'de carro de apoio, do usu�rio ' ||
                                         v_Nomesol || ' foi cadastrada. ' ||
                                         'N�mero da solicita��o: <a href="' || v_Link ||
                                         '" target="_black" title="Abri Tela">' || r_Cap.Nuap ||
                                         '</a><br>',
                           p_Email    => v_Mailexec);
      End;
      */
    
      -- atualiza status para 'Enviada'
      begin
        update ad_tsfcapsol s
           set s.status  = 'E',
               nuap      = r_cap.nuap,
               s.dhenvio = sysdate
         where nucapsol = r_sol.nucapsol;
      end;
    
    end;
  end loop;

  ad_pkg_cap.v_permite_edicao := false;

  if p_qtdlinhas < 2 then
    p_mensagem := 'Lan�ameto(s) enviado(s) para Agendamento com sucesso!!!<br> Agendamento nro: ' || r_cap.nuap;
  else
    p_mensagem := 'Foram enviadas ' || p_qtdlinhas || ' solicita��es para agendamento ' || 'com sucesso!!!';
  end if;

  /*exception
  when error then
    rollback;
    p_mensagem := '<p><font color="#FF0000" size="14"><b>Aten��o!!!</b></font></p>' || p_mensagem;
  When Others Then
    Rollback;
    p_mensagem     := Sqlerrm;
    p_Mensagem := '<p><font color="#FF0000" size="14"><b>Aten�aão!!!</b></font></p>' || p_mensagem;*/
end;
/
