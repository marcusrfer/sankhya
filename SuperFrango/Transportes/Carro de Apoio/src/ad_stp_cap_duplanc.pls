create or replace procedure ad_stp_cap_duplanc(p_codusu    number,
                                               p_idsessao  varchar2,
                                               p_qtdlinhas number,
                                               p_mensagem  out varchar2) as
  v_nucapsol number;
  v_nucap    number;
  v_proxnum  number;
  v_numlink  varchar2(4000);
  errmsg     varchar2(4000);
  error exception;
begin
  /* 
  * Autor: M. Rangel
  * Processo: Carro de Apoio
  * Objetivo: Duplicar o lançamento, a aba intinerário e rateio.
  */

  for l in 1 .. p_qtdlinhas
  loop
  
    v_nucapsol := act_int_field(p_idsessao, l, 'NUCAPSOL');
    v_nucap    := act_int_field(p_idsessao, l, 'NUAP');
  
    if v_nucapsol is not null and v_nucap is null then
    
      /*Prenche o cabeçalho*/
      for c in (select * from ad_tsfcapsol where nucapsol = v_nucapsol)
      loop
      
        --v_ProxNum := ad_get.ultCod('AD_TSFCAPSOL', 1, ' ') + 1;
      
        stp_keygen_tgfnum('AD_TSFCAPSOL', 1, 'AD_TSFCAPSOL', 'NUCAPSOL', 0, v_proxnum);
      
        begin
          insert into ad_tsfcapsol
            (nucapsol, codusu, dhsolicit, codcencus, tiposol, status, dtagend, nuap, dhalter,
             qtdpassageiros)
          values
            (v_proxnum, p_codusu, sysdate, c.codcencus, c.tiposol, 'P', null, null, sysdate, 1);
        exception
          when others then
            p_mensagem := 'Erro ao duplicar o cabeçalho da solicitação. ' || sqlerrm;
            return;
        end;
      
        /*preenche o itinerário*/
        for i in (select * from ad_tsfcapitn where nucapsol = v_nucapsol)
        loop
          <<insert_sol>>
          begin
            insert into ad_tsfcapitn
              (nucapsol, nuitn, tipotin, codcid, codend, codbai, complemento, referencia)
            values
              (v_proxnum, i.nuitn, i.tipotin, i.codcid, i.codend, i.codbai, i.complemento,
               i.referencia);
          exception
            when dup_val_on_index then
              v_proxnum := v_proxnum + 1;
              goto insert_sol;
            when others then
              p_mensagem := 'Erro ao duplicar o itinerário. ' || sqlerrm;
              return;
          end;
        
        end loop i;
      
        /*Preenche o rateio*/
        for r in (select * from ad_tsfcaprat where nucapsol = v_nucapsol)
        loop
        
          begin
            insert into ad_tsfcaprat
              (nucapsol, nucaprat, codemp, codnat, codcencus, percentual)
            values
              (v_proxnum, r.nucaprat, r.codemp, r.codnat, r.codcencus, r.percentual);
          exception
            when others then
              errmsg := 'Erro ao duplicar o rateio da solicitação. ' || sqlerrm;
              raise error;
          end;
        
        end loop r;
      
        /*Update tgfnum
          Set ultcod = v_ProxNum
        Where arquivo = 'AD_TSFCAPSOL';*/
      
        v_numlink := '<a target="_top" href="' ||
                     ad_fnc_urlskw('AD_TSFCAPSOL', v_proxnum, null, null) || '">' || v_proxnum ||
                     '</a>';
      
      end loop c;
    
    else
    
      for c in (select * from ad_tsfcap where nuap = v_nucap)
      loop
      
        --v_ProxNum := ad_get.ultcod('AD_TSFCAP', 1, ' ') + 1;
      
        stp_keygen_tgfnum('AD_TSFCAP', 1, 'AD_TSFCAP', 'NUAP', 0, v_proxnum);
      
        <<insert_cap>>
        begin
          insert into ad_tsfcap
            (nuap, codususol, dhsolicit, ordemcarga, codusuexc, codparctransp, codveiculo, status,
             taxi, motivotaxi, kminicial, kmfinal, totalkm, vlrcorrida, nucapsol, dtagend, rota,
             dtagendfim, combinada, codcontato, qtdpassageiros, motorista, motivo, deptosol,
             codcidorig, codciddest, nomeciddest, nomecidorig, dhmov, dtreabre, motivoreabre,
             codusureabre, nuappai, temacerto)
          values
            (v_proxnum, c.codususol, c.dhsolicit, c.ordemcarga, c.codusuexc, c.codparctransp,
             c.codveiculo, 'P', c.taxi, c.motivotaxi, 0, 0, 0, 0, c.nucapsol, c.dtagend, c.rota,
             null, 'N', c.codcontato, c.qtdpassageiros, c.motorista, c.motivo, c.deptosol,
             c.codcidorig, c.codciddest, c.nomeciddest, c.nomecidorig, sysdate, null, null, null,
             null, 'N');
        exception
          when dup_val_on_index then
            v_proxnum := v_proxnum + 1;
            goto insert_cap;
          when others then
            errmsg := 'Erro ao duplicar o agendamento. ' || sqlerrm;
            raise error;
        end;
      
        for r in (select * from ad_tsfcapdoc d where nuap = v_nucap)
        loop
        
          begin
            insert into ad_tsfcapdoc
              (seqdoc, nuap, codcencus, codsolicit, entregue, codusuresp, entreguetransp)
            values
              (r.seqdoc, v_proxnum, r.codcencus, r.codsolicit, 'N', r.codusuresp, 'N');
          exception
            when others then
              errmsg := 'Erro ao duplicar os documentos do agendamento. ' || sqlerrm;
              raise error;
          end;
        
        end loop r;
      
        v_numlink := '<a target="_top" href="' || ad_fnc_urlskw('AD_TSFCAP', v_proxnum, null, null) || '">' ||
                     v_proxnum || '</a>';
      
      end loop c;
    
    end if;
  
  end loop l;

  /*Update tgfnum
    Set ultcod = v_ProxNum
  Where arquivo = 'AD_TSFCAP';*/

  p_mensagem := 'Lançamento duplicado com sucesso.<br> Lançamento nro: ' || v_numlink;

exception
  when error then
    rollback;
    p_mensagem := errmsg;
  when others then
    p_mensagem := 'Erro: ' || sqlerrm;
end;
/
