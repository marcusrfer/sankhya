create or replace procedure ad_stp_cap_unifagend(p_codusu    number,
                                                 p_idsessao  varchar2,
                                                 p_qtdlinhas int,
                                                 p_mensagem  out varchar2) is
  cap         ad_tsfcap%rowtype;
  new         ad_tsfcap%rowtype;
  v_proxnuap  number;
  v_seqdoc    int := 0;
  v_count     int := 0;
  v_mergerota clob;
  v_qtdpsg    number := 0;
  array_agend dbms_utility.maxname_array;

begin
  /*
  * Autor: Marcus Rangel.
  * Processo: Agendamento de Carro de Apoio.
  * Objetivo: Realizar a combinacao de agendamentos, para atender corridas distintas com o mesmo destino.
  */

  /*
  * 04/03/2020 - m.rangel - tratativa para locações - linha
  */

  cap.codusuexc := p_codusu;

  for i in 1 .. p_qtdlinhas
  loop
    cap.nuap := act_int_field(p_idsessao, i, 'NUAP');
    array_agend(i) := cap.nuap;
  end loop;

  if p_qtdlinhas < 2 then
    p_mensagem := 'Selecione no mínimo 2 lançamentos para combinar.';
    return;
  end if;

  /*Insere o novo agendamento*/
  begin
  
    -- v_msg := Ad_pkg_cap.Msg_combinacao(v_proxnuap);
    for r in array_agend.first .. array_agend.last
    loop
    
      select * into cap from ad_tsfcap where nuap = array_agend(r);
    
      -- tratativa para locacoes
      if cap.tipo = 'LOC' then
        p_mensagem := 'Aagendamentos do tipo "Locação" ' || 'não podem sem combinados devido a ' ||
                      'necessidade de ter um contrato por carro.';
        return;
      end if;
    
      /*tratativa para preencher alguns campos da tela como o parceiro, As cidades*/
      if new.codparctransp is null then
        new.codparctransp := cap.codparctransp;
      end if;
    
      if new.codveiculo is null then
        new.codveiculo := cap.codveiculo;
      end if;
    
      if new.codcidorig is null then
        new.codcidorig := cap.codcidorig;
      end if;
    
      if new.codciddest is null then
        new.codciddest := cap.codciddest;
      end if;
    
      if new.kminicial is null or new.kminicial = 0 then
        new.kminicial := cap.kminicial;
      end if;
    
      if new.kmfinal is null or new.kmfinal = 0 then
        new.kmfinal := cap.kmfinal;
      end if;
    
      if new.totalkm is null or new.totalkm = 0 then
        new.totalkm := cap.totalkm;
      end if;
    
      if v_mergerota is null then
        v_mergerota := cap.rota || chr(13) || 'Motivo: ' || cap.motivo || chr(13) || 'Horário: ' ||
                       to_char(cap.dtagend, 'dd/mm/yyyy hh24:mi:ss') || chr(13) || 'Passageiros: ' ||
                       to_char(cap.qtdpassageiros);
      
      else
        v_mergerota := v_mergerota || chr(13) ||
                       '----------------------------------------------------------------------------------------' ||
                       chr(13) || cap.rota || chr(13) || 'Motivo: ' || cap.motivo || chr(13) ||
                       'Horário: ' || to_char(cap.dtagend, 'dd/mm/yyyy hh24:mi:ss') || chr(13) ||
                       'Passageiros: ' || to_char(cap.qtdpassageiros);
      end if;
    
      v_qtdpsg := v_qtdpsg + cap.qtdpassageiros;
    
    end loop;
  
  end;

  <<insere_agend>>

  declare
    v_nomecidorig varchar2(200);
    v_nomeciddest varchar2(200);
  begin
  
    stp_keygen_tgfnum('AD_TSFCAP', 1, 'AD_TSFCAP', 'NUAP', 0, v_proxnuap);
  
    select nomecid into v_nomecidorig from tsicid where codcid = new.codcidorig;
  
    select nomecid into v_nomeciddest from tsicid where codcid = new.codciddest;
  
    insert into ad_tsfcap
      (nuap, dhsolicit, status, combinada, rota, codusuexc, codveiculo, codparctransp, motorista,
       kminicial, kmfinal, totalkm, qtdpassageiros, codcidorig, nomecidorig, codciddest, nomeciddest)
    values
      (v_proxnuap, sysdate, 'P', 'S', v_mergerota, cap.codusuexc, cap.codveiculo, new.codparctransp,
       cap.motorista, new.kminicial, new.kmfinal, new.totalkm, v_qtdpsg, new.codcidorig,
       new.nomecidorig, new.codciddest, new.nomeciddest);
  
  exception
    when dup_val_on_index then
      merge into tgfnum n
      using (select max(nuap) maxnuap from ad_tsfcap) c
      on (n.arquivo = 'AD_TSFCAP' and n.codemp = 1 and n.serie = ' ')
      when matched then
        update set n.ultcod = c.maxnuap
      when not matched then
        insert
          (arquivo, codemp, serie, automatico, ultcod)
        values
          ('AD_TSFCAP', 1, ' ', 'S', c.maxnuap);
    
      goto insere_agend;
    when others then
      p_mensagem := 'Erro ao inserir o agendamento. ' || sqlcode || ' - ' || sqlerrm;
      return;
  end;

  /* Atualiza o status dos lanÃ§amento de origem */
  for p in array_agend.first .. array_agend.last
  loop
    begin
      update ad_tsfcap c
         set c.status = 'M',
             --C.Rota    = C.Rota || Chr(13) || 'Agendamento combinado, resultando no agendamento nro ' || v_proxNuap,
             c.nuappai = v_proxnuap
       where nuap = array_agend(p);
    exception
      when others then
        p_mensagem := 'Erro ao atualizar agendamentos de origem. ' || sqlerrm;
        return;
    end;
  end loop p;

  -- atualiza o NUAP das solicitaÃ§Ãµes
  begin
    ad_pkg_cap.atualiza_statussol(p_nroagendamento => v_proxnuap, p_statussolicit => 'E',
                                  p_enviaemail => 'N', p_enviaaviso => 'N', p_errmsg => p_mensagem);
    if p_mensagem is not null then
      return;
    end if;
  end;

  -- insere os documentos
  for origdoc in (select nuap from ad_tsfcap where nuappai = v_proxnuap)
  loop
  
    for doc in (select * from ad_tsfcapdoc where nuap = origdoc.nuap)
    loop
      v_seqdoc := v_seqdoc + 1;
      v_count  := 0;
    
      select count(*)
        into v_count
        from ad_tsfcapdoc
       where nuap = v_proxnuap
         and codcencus = doc.codcencus
         and codsolicit = doc.codsolicit;
    
      if v_count = 0 then
        begin
          insert into ad_tsfcapdoc
            (nuap, seqdoc, codcencus, codsolicit, entregue)
          values
            (v_proxnuap, v_seqdoc, doc.codcencus, doc.codsolicit, 'N');
        exception
          when dup_val_on_index then
            v_proxnuap := v_proxnuap + 1;
        end;
      else
        continue;
      end if;
    
    end loop doc;
  
  end loop origdoc;

  -- insere o rateio
  declare
    v_seqrat int;
  begin
  
    delete from ad_tsfcapfrt where nuap = v_proxnuap;
  
    select nvl(max(r.numfrt), 1) into v_seqrat from ad_tsfcapfrt r where nuap = v_proxnuap;
  
    for c_rat in (select r.codemp, r.codcencus, r.codnat, nvl(r.codproj, 0) codproj,
                         ratio_to_report(count(*)) over() * 100 as percentual
                    from ad_tsfcapfrt r
                    join ad_tsfcap c
                      on r.nuap = c.nuap
                   where c.nuappai = v_proxnuap
                   group by r.codemp, r.codcencus, r.codnat, nvl(r.codproj, 0))
    loop
      v_seqrat := v_seqrat + 1;
      insert into ad_tsfcapfrt
        (nuap, numfrt, codemp, codcencus, codnat, codproj, percentual)
      values
        (v_proxnuap, v_seqrat, c_rat.codemp, c_rat.codcencus, c_rat.codnat, c_rat.codproj,
         c_rat.percentual);
    end loop;
  end;

  p_mensagem := 'Lançamentos combinados com sucesso! ' ||
                'Foi gerado o agendamento nro<a target ="_parent" href="' ||
                ad_fnc_urlskw('AD_TSFCAP', v_proxnuap) || '"><font color="#0000FF">' || v_proxnuap ||
                '</font></a>';

end;
/
