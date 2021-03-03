create or replace procedure ad_stp_cap_gerasolserv_sf(p_codusu    number,
                                                      p_idsessao  varchar2,
                                                      p_qtdlinhas number,
                                                      p_mensagem  out varchar2) as
  a          ad_tsfcap%rowtype;
  r          ad_tsfcapfrt%rowtype;
  v_codsolst number;
begin

  /* Autor: M. Rangel
  * Processo: Carro de Apoio
  * Objetivo: Gerar solicitações de serviços de transporte (aluguel de Van, ex)
  */
  if p_qtdlinhas > 1 then
    p_mensagem := 'Selecione apenas 1 lançamento por vez!';
    return;
  end if;

  a.nuap := act_int_field(p_idsessao, 1, 'NUAP');

  -- busca os dados do agendamento  
  begin
    select * into a from ad_tsfcap where nuap = a.nuap;
  exception
    when others then
      p_mensagem := sqlerrm;
      return;
  end;

  --- busca os dados do rateio
  begin
    select * into r from ad_tsfcapfrt where nuap = a.nuap fetch first 1 rows only;
  exception
    when others then
      p_mensagem := sqlerrm;
      return;
  end;

  begin
    stp_keygen_tgfnum('AD_TSFSSTC', 1, 'AD_TSFSSTC', 'CODSOLST', 0, v_codsolst);
  
    -- insert o cabeçalho da solicitação
    begin
      insert into ad_tsfsstc
        (codsolst, codsol, dhsolicit, codemp, codnat, codcencus, codproj, dtinicio, dtfim, codparc,
         status, numcontrato, dhalter, codusu, obs, nunotaorig, origem)
      values
        (v_codsolst, a.codususol, sysdate, 1, r.codnat, r.codcencus, r.codproj, a.dtagend,
         a.dtagend, null, 'P', null, sysdate, p_codusu, a.rota, null, null);
    exception
      when others then
        p_mensagem := 'Erro ao criar o cabeçalho da solicitação. <br>' || sqlerrm;
        return;
    end;
  
    -- insert do serviço
    begin
      insert into ad_tsfssti
        (codserv, codsolst, qtdneg, codvol, vlrunit, vlrtot, numcontrato, codparc, nussti,
         descrserv)
      values
        (7102, v_codsolst, 1, 'UN', 0, 0, null, 0, 1, ad_get.descrproduto(7102));
    exception
      when others then
        p_mensagem := 'Erro ao inserir o serviço na solicitação! <br>' || sqlerrm;
        return;
    end;
  
    -- envia a solicitação para análise da área de transporte
    -- cancela o agendamento
    declare
      v_sessao varchar2(100);
      v_msg    varchar2(4000);
    begin
      ad_set.inseresessao('CODSOLST', 1, 'I', v_codsolst, v_sessao);
      ad_stp_sst_envanalise(p_codusu, v_sessao, 1, v_msg);
      ad_set.inseresessao('NUAP', 1, 'I', a.nuap, v_sessao);
      ad_set.inseresessao('MOTIVO', 0, 'S',
                          'Solicitação enviada à área de transporte para contratação do mesmo!',
                          v_sessao);
      ad_stp_cap_cancagend(p_codusu, v_sessao, 1, v_msg);
      ad_set.remove_sessao(v_sessao);
    exception
      when others then
        p_mensagem := sqlerrm;
        return;
    end;
  
  exception
    when others then
      p_mensagem := sqlerrm;
      return;
  end;

  p_mensagem := 'Operação realizada com sucesso, gerada a solicitação nº ' || v_codsolst;

end;
/
