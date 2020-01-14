create or replace package ad_pkg_cap is
  /****************************************************************************
  Autor: Marcus Rangel
  Objetivo: Armazenar todos os objetos relacionados ao processo de Carro de Apoio
  *****************************************************************************/

  --v_permite_edicao boolean default false;

  function get_nroacerto(p_nroagend number) return number;
  /****************************************************************************
  Autor: Marcus Rangel
  Objetivo: 
  *****************************************************************************/

  function getagendcap(p_nucapsol int) return number;
  /****************************************************************************
  Autor: Marcus Rangel
  Objetivo: 
  *****************************************************************************/

  function voucher_pendentes(p_nrounico number,
                             p_tipo char) return varchar2;
  /****************************************************************************
  Autor: Marcus Rangel
  Objetivo: 
  *****************************************************************************/

  function msg_combinacao(p_nuap integer) return varchar2;
  /****************************************************************************
  Autor: Marcus Rangel
  Objetivo: 
  *****************************************************************************/

  procedure atualiza_statussol(p_nroagendamento number,
                               p_statussolicit char,
                               p_enviaemail char,
                               p_enviaaviso char,
                               p_errmsg out varchar2);
  /****************************************************************************
  Autor: Marcus Rangel
  Objetivo: 
  *****************************************************************************/

  procedure insere_rateio_acerto(p_nroagend number,
                                 p_nroacerto number,
                                 p_seqacerto number,
                                 p_errmsg out varchar2);
  /****************************************************************************
  Autor: Marcus Rangel
  Objetivo: 
  *****************************************************************************/

  procedure exclui_acerto(p_nroagend number,
                          p_errmsg out varchar2);
  /****************************************************************************
  Autor: Marcus Rangel
  Objetivo: 
  *****************************************************************************/

  procedure solicitacarro(p_solmodelo int,
                          p_qtdreg int);
  /****************************************************************************
  Autor: Marcus Rangel
  Objetivo: 
  *****************************************************************************/

  function compara_destino(p_nucapsol number) return boolean;
  /****************************************************************************
  Autor: Marcus Rangel
  Objetivo: 
  *****************************************************************************/

  type type_rec_carro is record(
    nucapsol       number,
    nomeusu        varchar2(100),
    codcencus      number,
    lotacao        number,
    descrcencus    varchar2(100),
    codparctransp  number,
    nomeparctransp varchar2(100),
    codvei         number,
    descrvei       varchar2(250),
    codusuexc      number,
    nomeusuexc     varchar2(100),
    dhsolicit      date,
    dtagend        date,
    status         varchar2(100),
    motivo         varchar2(250),
    nuap           number);

  type type_tab_carro is table of type_rec_carro;

  function vouchercab(p_nucapsol number) return type_tab_carro
    pipelined;

  procedure cria_bkp_avisos;

end ad_pkg_cap;
/
create or replace package body ad_pkg_cap is

  function get_nroacerto(p_nroagend number) return number is
    v_nroacerto number;
    r_cap       ad_tsfcap % rowtype;
  begin
  
    select * into r_cap from ad_tsfcap where nuap = p_nroagend;
  
    begin
      select nvl(nuacerto, 0)
        into v_nroacerto
        from ad_cabacertotransp ct
       where ct.codparc = r_cap.codparctransp
         and trunc(ct.referencia, 'mm') = trunc(r_cap.dtagend, 'mm');
    exception
      when too_many_rows then
        raise_application_error(-20105,
                                fc_formatahtml_sf('Não foi possível realizar essa operação',
                                                   'Foram encontrados dois acertos nessa referência para esse parceiro',
                                                   'Verifique  o motivo de existirem dois acertos da mesma referência para o mesmo parceiro.'));
    end;
  
    /*And ct.Referencia = (Select Max(Referencia)
     From Ad_cabacertotransp ct2
    Where ct.Codparc = r_cap.Codparctransp
      And Trunc(ct.Referencia, 'mm') = Trunc(r_cap.Dtagend, 'mm'));*/
  
    return nvl(v_nroacerto, 0);
  
  exception
    when no_data_found then
      return 0;
  end;

  function getagendcap(p_nucapsol int) return number is
    v_nuap  int;
    v_nuap2 int;
  begin
  
    select nuap into v_nuap from ad_tsfcapsol where nucapsol = p_nucapsol;
  
    for i in (select nuap from ad_tsfcaplig where nuaporig = v_nuap)
    loop
    
      for u in (select nuap from ad_tsfcaplig where nuaporig = i.nuap)
      loop
        v_nuap2 := u.nuap;
      end loop u;
    
      if v_nuap2 is null then
        v_nuap2 := i.nuap;
      end if;
    
    end loop i;
  
    dbms_output.put_line(v_nuap2);
    return nvl(v_nuap2, v_nuap);
  
  end getagendcap;

  procedure exclui_acerto(p_nroagend number,
                          p_errmsg out varchar2) is
    v_nunota   number;
    v_nuacerto number;
    i          int := 0;
    errmsg     varchar2(4000);
    error exception;
  begin
  
    begin
      /*      Select Nunota, Nuacerto
       Into v_Nunota, v_NuAcerto
       From Ad_cabacertotransp
      Where Nuacerto = Ad_pkg_cap.Get_nroacerto(p_NroAgend);*/
    
      select cab.nunota, cab.nuacerto
        into v_nunota, v_nuacerto
        from ad_cabacertotransp cab
        left join ad_diaacertotransp dia
          on cab.nuacerto = dia.nuacerto
       where dia.nuap = p_nroagend;
    
    exception
      when no_data_found then
        return;
    end;
  
    if nvl(v_nunota, 0) = 0 then
      -- exclui o km do agendamento
    
      /* no dia 16/10 foi identificado um caso do agendamento 1977
      cuja a viagem foi realizada e não há rastro na tabela do dia, 
      mas consta um registro na tabela do rateio, verificando o relacionamento
      entre diaacertotransp e ratacerttransp, notei que não há FK, logo o sistma
      não realiza o delete e nem o cascade on delete, o bloco abaixo foi criada 
      para sanar essa situação, o mesmo ainda está comentado, pois ainda não foi
      validado.*/
    
      for r in (select dia.nuap,
                       rat.nuacerto,
                       rat.seqacertodia,
                       rat.seqrateiocr,
                       rat.codcencus,
                       rat.perc,
                       rat.vlrcencus,
                       rat.codproj,
                       rat.codnat
                  from ad_ratacertotransp rat, ad_diaacertotransp dia
                 where rat.nuacerto = dia.nuacerto
                   and rat.seqacertodia = dia.seqacertodia
                   and rat.nuacerto = v_nuacerto
                   and dia.nuap = p_nroagend)
      loop
        begin
          delete from ad_ratacertotransp
           where nuacerto = v_nuacerto
             and seqacertodia = r.seqacertodia
             and seqrateiocr = r.seqrateiocr;
        exception
          when no_data_found then
            continue;
          when others then
            errmsg := 'Erro ao excluir o rateio do acerto ' || v_nuacerto || '. - ' || sqlerrm;
            raise error;
        end;
      end loop;
    
      begin
        delete from ad_diaacertotransp dat
         where dat.nuacerto = v_nuacerto
           and dat.nuap = p_nroagend;
      exception
        when no_data_found then
          return;
        when others then
          errmsg := 'Erro ao excluir a viagem do acerto ' || v_nuacerto || '. - ' || sqlerrm;
          raise error;
      end;
    
    else
      select count(*) into i from tgfcab where nunota = v_nunota;
    
      if i <> 0 then
        errmsg := 'Acerto Nro ' || v_nuacerto || ' já gerou o pedido (nro único ' || v_nunota ||
                  '). <br> O agendamento não pode ser desfeito.';
        raise error;
      end if;
    
    end if;
  
  exception
    when error then
      rollback;
      p_errmsg := errmsg;
    when others then
      rollback;
      p_errmsg := sqlerrm;
  end exclui_acerto;

  function voucher_pendentes(p_nrounico number,
                             p_tipo char) return varchar2 is
    v_count         int := 0;
    v_codusu        number;
    v_codparctransp number;
    v_codveiculo    number;
    v_corpomsg      varchar2(4000);
    v_msg           varchar2(4000);
  begin
  
    -- Tipo S, Solicitante
    -- tipo A, Motorista
    -- Tipo V, Veículo
  
    if p_tipo = 'S' then
    
      select s.codusu into v_codusu from ad_tsfcapsol s where s.nucapsol = p_nrounico;
    
      for c_doc in (select *
                      from (select d.codsolicit, d.nuap, c.dtagendfim
                              from ad_tsfcapdoc d, ad_tsfcap c
                             where c.nuap = d.nuap
                               and (c.status = 'R')
                               and nvl(d.entregue, 'N') = 'N'
                            union
                            select d.codsolicit, d.nuap, c.dtagendfim
                              from ad_tsfcapdoc d, ad_tsfcap c
                             where c.nuap = d.nuap
                               and trunc(c.dtagendfim) < trunc(sysdate)
                               and c.status = 'A'
                               and nvl(d.entregue, 'N') = 'N') doc
                     where doc.codsolicit = v_codusu)
      loop
      
        if v_corpomsg is null then
          v_corpomsg := 'Agend. Nro: ' || c_doc.nuap || ' do dia ' || c_doc.dtagendfim;
        else
          v_corpomsg := v_corpomsg || chr(13) || 'Agend. Nro: ' || c_doc.nuap || ' do dia ' || c_doc.dtagendfim;
        end if;
      
        v_count := v_count + 1;
      end loop;
    
    elsif p_tipo = 'M' then
    
      select c.codusuexc, c.codparctransp into v_codusu, v_codparctransp from ad_tsfcap c where c.nuap = p_nrounico;
    
      for c_doc in (select *
                      from (select c.codparctransp, d.nuap, c.dtagendfim
                              from ad_tsfcapdoc d, ad_tsfcap c
                             where c.nuap = d.nuap
                               and (c.status = 'R')
                               and nvl(d.entreguetransp, 'N') = 'N'
                            union
                            select c.codparctransp, d.nuap, c.dtagendfim
                              from ad_tsfcapdoc d, ad_tsfcap c
                             where c.nuap = d.nuap
                               and trunc(c.dtagendfim) < trunc(sysdate)
                               and c.status = 'A'
                               and nvl(d.entreguetransp, 'N') = 'N') doc
                     where doc.codparctransp = v_codparctransp)
      loop
      
        if v_corpomsg is null then
          v_corpomsg := 'Agend. Nro: ' || c_doc.nuap || ' do dia ' || c_doc.dtagendfim;
        else
          v_corpomsg := v_corpomsg || chr(13) || 'Agend. Nro: ' || c_doc.nuap || ' do dia ' || c_doc.dtagendfim;
        end if;
      
        v_count := v_count + 1;
      end loop;
    
    elsif p_tipo = 'V' then
    
      select c.codusuexc, c.codveiculo into v_codusu, v_codveiculo from ad_tsfcap c where c.nuap = p_nrounico;
    
      for c_doc in (
                    
                    select *
                      from (select c.codveiculo, d.nuap, c.dtagendfim
                               from ad_tsfcapdoc d, ad_tsfcap c
                              where c.nuap = d.nuap
                                and (c.status = 'R')
                                and nvl(d.entreguetransp, 'N') = 'N'
                             union
                             select c.codveiculo, d.nuap, c.dtagendfim
                               from ad_tsfcapdoc d, ad_tsfcap c
                              where c.nuap = d.nuap
                                and trunc(c.dtagendfim) < trunc(sysdate)
                                and c.status = 'A'
                                and nvl(d.entreguetransp, 'N') = 'N') doc
                     where doc.codveiculo = v_codveiculo
                    
                    )
      loop
      
        if v_corpomsg is null then
          v_corpomsg := 'Agend. Nro: ' || c_doc.nuap || ' do dia ' || c_doc.dtagendfim;
        else
          v_corpomsg := v_corpomsg || chr(13) || 'Agend. Nro: ' || c_doc.nuap || ' do dia ' || c_doc.dtagendfim;
        end if;
      
        v_count := v_count + 1;
      end loop;
    
    end if;
  
    if v_count <> 0 then
      v_msg := 'Vouchers pendentes:<br>' || v_corpomsg;
    end if;
  
    return(v_msg);
  
  end voucher_pendentes;

  function msg_combinacao(p_nuap integer) return varchar2 is
    v_msg1 varchar2(500);
    v_msg2 varchar2(500);
    v_msg  varchar2(4000);
  begin
  
    for c_lig in (select * from ad_tsfcaplig where nuap = p_nuap)
    loop
    
      for c_lig2 in (select * from ad_tsfcaplig where nuap = c_lig.nuaporig)
      loop
        c_lig.nuaporig := c_lig2.nuaporig;
      
        for r_cap in (select * from ad_tsfcap where nuap = c_lig.nuaporig)
        loop
          dbms_output.put_line('***' || r_cap.nucapsol);
          v_msg1 := 'Nro Agend. Origem: ' || c_lig.nuaporig || ' / Nro Solicitação Origem: ' || r_cap.nucapsol;
          v_msg2 := 'Usuário Solicitante: ' || r_cap.codususol || ' / Motivo Origem: ' || r_cap.motivo;
        
          if v_msg is null then
            v_msg := v_msg1 || chr(13) || v_msg2 || chr(13) || r_cap.rota || chr(13) ||
                     '-----------------------------------------------------------------------------------------';
          else
            v_msg := v_msg || chr(13) || v_msg1 || chr(13) || v_msg2 || chr(13) || r_cap.rota || chr(13) ||
                     '-----------------------------------------------------------------------------------------';
          end if;
        
        end loop r_cap;
      
      end loop c_lig2;
    
      dbms_output.put_line('**' || c_lig.nuaporig);
    
      if v_msg1 is null then
      
        for r_cap in (select * from ad_tsfcap where nuap = c_lig.nuaporig)
        loop
          dbms_output.put_line('***' || r_cap.nucapsol);
          v_msg1 := 'Nro Agend. Origem: ' || c_lig.nuaporig || ' / Nro Solicitação Origem: ' || r_cap.nucapsol;
          v_msg2 := 'Usuário Solicitante: ' || r_cap.codususol || ' / Motivo Origem: ' || r_cap.motivo;
        
          if v_msg is null then
            v_msg := v_msg1 || chr(13) || v_msg2 || chr(13) || r_cap.rota || chr(13) ||
                     '-----------------------------------------------------------------------------------------';
          else
            v_msg := v_msg || chr(13) || v_msg1 || chr(13) || v_msg2 || chr(13) || r_cap.rota || chr(13) ||
                     '-----------------------------------------------------------------------------------------';
          end if;
        
        end loop r_cap;
      
      end if;
    
      v_msg1 := null;
      v_msg2 := null;
    
    end loop c_lig;
  
    dbms_output.put_line(v_msg);
    return v_msg;
  
  end msg_combinacao;

  procedure atualiza_statussol(p_nroagendamento number,
                               p_statussolicit char,
                               p_enviaemail char,
                               p_enviaaviso char,
                               p_errmsg out varchar2) is
    i         int := 0;
    v_emailig varchar2(2000);
    v_email   varchar2(2000);
    r_cap     ad_tsfcap % rowtype;
    r_sol     ad_tsfcapsol % rowtype;
    r_avi     tsiavi % rowtype;
  
    type ty_nuap is table of number;
    n ty_nuap := ty_nuap();
  
    error exception;
  begin
  
    stp_set_atualizando('S');
  
    select * into r_cap from ad_tsfcap where nuap = p_nroagendamento;
  
    for c_sol in (select nucapsol
                    from ad_tsfcap
                   where nucapsol is not null
                     and status = 'M'
                   start with nuap = p_nroagendamento
                  connect by prior nuap = nuappai
                  union
                  select nucapsol
                    from ad_tsfcap
                   where status <> 'M'
                     and nuap = p_nroagendamento
                     and nucapsol is not null)
    loop
    
      if c_sol.nucapsol is not null then
        i := i + 1;
        n.extend;
        n(i) := c_sol.nucapsol;
      end if;
    
    end loop c_sol;
  
    for c_idx in n.first .. n.last
    loop
    
      begin
        update ad_tsfcapsol sol set status = p_statussolicit where nucapsol = n(c_idx);
      
        -- processo de visitas de biossegurança
        update ad_tsfavs a
           set a.statuscar    = p_statussolicit,
               a.dhagendcarro = r_cap.dtagend,
               a.codveiculo   = r_cap.codveiculo
         where a.nucapsol = n(c_idx);
      
      exception
        when others then
          rollback;
          raise;
      end;
    
      select * into r_sol from ad_tsfcapsol s where s.nucapsol = n(c_idx);
    
      begin
        select email into v_emailig from tsiusu where codusu = r_cap.codususol;
      exception
        when no_data_found then
          continue;
      end;
    
      if v_email is null then
        v_email := v_emailig;
      else
      
        if v_email <> v_emailig then
          v_email := v_email || ',' || v_emailig;
        end if;
      
      end if;
    
      /*envia notificação*/
      /* Insere o aviso do sistema */
      if nvl(p_enviaaviso, 'N') = 'S' then
      
        r_avi.titulo    := 'Alteração de Status de Agendamento';
        r_avi.descricao := 'Nro Agendamento: ' || p_nroagendamento || '.<br> 
								Nro Solicitação: ' || r_sol.nucapsol || '<br>
								Dt. Agendamento: ' || trunc(r_cap.dtagend) || '.<br>
								Status: ' || ad_get.opcoescampo(p_statussolicit, 'STATUS', 'AD_TSFCAP');
      
        if r_cap.motorista is not null and r_cap.codveiculo is not null then
          r_avi.descricao := r_avi.descricao || '<br> Motorista: ' || ad_get.nome_parceiro(r_cap.motorista, 'completo') ||
                             '<br> Veículo: ' || ad_get.formataplaca(r_cap.codveiculo);
        end if;
      
        ad_set.ins_avisosistema(p_titulo => r_avi.titulo, p_descricao => r_avi.descricao, p_solucao => '',
                                p_prioridade => 2, p_usurem => r_cap.codusuexc, p_usudest => r_sol.codusu,
                                p_tabela => 'AD_TSFCAPSOL', p_nrounico => r_sol.nucapsol, p_erro => p_errmsg);
      
        if p_errmsg is not null then
          raise error;
        end if;
      
        begin
          stp_keygen_tgfnum(p_arquivo => 'TSIAVI', p_codemp => 1, p_tabela => 'TSIAVI', p_campo => 'NUAVISO',
                            p_dsync => 0, p_ultcod => r_avi.nuaviso);
        exception
          when others then
            p_errmsg := 'Erro ao atualizar a numeração dos avisos. ' || sqlerrm;
            raise error;
        end;
      end if;
      /*fim envia notificação*/
    
      /*envia email*/
      if nvl(p_enviaemail, 'N') = 'S' then
        begin
        
          if v_email is null then
            begin
              select email into v_email from tsiusu where codusu = r_cap.codususol;
            
            exception
              when no_data_found then
              
                -- M. Rangel - 17/12/2018
                -- Atualização para unificação da origem dos liberadores utilizdos no processo de transportes
                select usu.email
                  into v_email
                  from ad_tsfelt e
                  join tsiusu usu
                    on usu.codusu = e.codlibcap
                 where e.nuelt = 1;
              
              /*Select Email
               Into v_Email
               From Tsiusu
              Where Codusu = Get_tsipar_inteiro('CODUSURESPCAP');*/
            end;
          end if;
        
          r_avi.descricao := r_avi.descricao || chr(13) || '<br><br> Clique <a href="' ||
                             ad_fnc_urlskw('AD_TSFCAPSOL', r_sol.nucapsol) || '">aqui</a> para maiores detalhes.';
        
          ad_stp_gravafilabi(p_assunto => r_avi.titulo, p_mensagem => r_avi.descricao, p_email => v_email);
        end;
      end if;
      /*fim envia email*/
    
    end loop c_idx;
  
    stp_set_atualizando('N');
  
  exception
    when error then
      rollback;
      p_errmsg := 'Erro ao atualizar o status da solicitação de agendamento. ' || sqlerrm;
      return;
    when others then
      rollback;
      p_errmsg := 'Erro ao atualizar o status da solicitação de agendamento. ' || sqlerrm;
      return;
  end atualiza_statussol;

  procedure insere_rateio_acerto(p_nroagend number,
                                 p_nroacerto number,
                                 p_seqacerto number,
                                 p_errmsg out varchar2) is
  
    v_seqrateio int := 1;
    v_count     int := 0;
  begin
  
    select count(*)
      into v_count
      from ad_ratacertotransp rat
     where rat.nuacerto = p_nroacerto
       and rat.seqacertodia = p_seqacerto;
  
    if v_count > 0 then
      begin
        delete from ad_ratacertotransp rat
         where rat.nuacerto = p_nroacerto
           and rat.seqacertodia = p_seqacerto;
      
      exception
        when no_data_found then
          null;
        when others then
          p_errmsg := sqlerrm;
          return;
      end;
    end if;
  
    for cur_rat in (select f.codemp, f.codcencus, f.codnat, nvl(f.codproj, 0) codproj, f.percentual
                      from ad_tsfcapfrt f
                      join ad_tsfcap c
                        on c.nuap = f.nuap
                     where f.nuap = p_nroagend)
    loop
    
      begin
        insert into ad_ratacertotransp
          (nuacerto, seqacertodia, seqrateiocr, codcencus, codnat, codproj, perc)
        values
          (p_nroacerto, p_seqacerto, v_seqrateio, cur_rat.codcencus, cur_rat.codnat, cur_rat.codproj,
           cur_rat.percentual);
      exception
        when others then
          p_errmsg := 'Erro ao inserir o rateio no acerto. - ' || sqlerrm;
          return;
      end;
    
      v_seqrateio := v_seqrateio + 1;
    
    end loop;
  
  end insere_rateio_acerto;

  procedure solicitacarro(p_solmodelo int,
                          p_qtdreg int) is
    max_nucapsol int;
  begin
    for ins in 1 .. p_qtdreg
    loop
      for s in (select * from ad_tsfcapsol where nucapsol = p_solmodelo)
      loop
        select max(nucapsol) + 1 into max_nucapsol from ad_tsfcapsol;
      
        insert into ad_tsfcapsol
          (nucapsol, codusu, dhsolicit, codcencus, tiposol, status, dtagend, dhalter, qtdpassageiros)
        values
          (max_nucapsol, s.codusu, sysdate, s.codcencus, s.tiposol, 'P', s.dtagend, sysdate, 1);
      
      end loop s;
    
      for i in (select * from ad_tsfcapitn where nucapsol = p_solmodelo)
      loop
        insert into ad_tsfcapitn
          (nucapsol, nuitn, tipotin, codcid, codend, codbai)
        values
          (max_nucapsol, i.nuitn, i.tipotin, i.codcid, i.codend, i.codbai);
      end loop i;
    
      for r in (select * from ad_tsfcaprat where nucapsol = p_solmodelo)
      loop
        insert into ad_tsfcaprat
          (nucapsol, nucaprat, codemp, codnat, codcencus, percentual)
        values
          (max_nucapsol, r.nucaprat, r.codemp, r.codnat, r.codcencus, r.percentual);
      end loop;
    end loop ins;
  end solicitacarro;

  function compara_destino(p_nucapsol number) return boolean is
    v_orig       char(1);
    v_codcidorig int;
    v_dest       char(1);
    v_codciddest int;
    v_count      int := 0;
    v_igual      boolean := false;
  begin
  
    for c_itn in (select * from ad_tsfcapitn where nucapsol = p_nucapsol order by nucapsol, nuitn)
    loop
    
      if c_itn.tipotin = 'D' then
        v_orig       := c_itn.tipotin;
        v_codcidorig := c_itn.codcid;
      elsif c_itn.tipotin = 'O' then
        v_dest       := c_itn.tipotin;
        v_codciddest := c_itn.codcid;
      end if;
    
      v_count := v_count + 1;
    
      if v_count = 2 then
      
        if v_codcidorig = v_codciddest then
          v_igual := true;
        else
          v_igual := false;
        end if;
      
        v_count := 0;
      
      end if;
    
    end loop;
  
    return v_igual;
  exception
    when others then
      v_igual := false;
      return v_igual;
  end compara_destino;

  function vouchercab(p_nucapsol number) return type_tab_carro
    pipelined is
    t             type_rec_carro;
    c             ad_tsfcap%rowtype;
    v_codcencus   number;
    v_descrcencus varchar2(200);
    v_nomeusu     varchar2(250);
    v_motivo      ad_tsfcapsol.motivo%type;
  begin
  
    begin
      select *
        into c
        from ad_tsfcap
       where nucapsol = p_nucapsol
         and status not in ('C');
    exception
      when too_many_rows then
        select *
          into c
          from ad_tsfcap
         where nucapsol = p_nucapsol
           and status not in ('C')
           and rownum = 1;
    end;
  
    select s.codcencus, cus.descrcencus, s.motivo, ad_get.nomeusu(s.codusu, 'resumido')
      into v_codcencus, v_descrcencus, v_motivo, v_nomeusu
      from ad_tsfcapsol s, tsicus cus
     where s.codcencus = cus.codcencus
       and nucapsol = p_nucapsol;
  
    while c.nuappai is not null
    loop
      if c.status = 'M' and c.nuappai is not null then
        select * into c from ad_tsfcap where nuap = c.nuappai;
      end if;
    end loop;
  
    for c_cap in (select cap.codususol,
                         ad_get.nomeusu(cap.codususol, 'resumido') nomeusu,
                         cap.qtdpassageiros lotacao,
                         cap.codparctransp,
                         par.nomeparc nomeparctransp,
                         cap.codveiculo codveiculo,
                         v.marcamodelo || ' / ' || ad_get.formataplaca(v.placa) descrvei,
                         cap.codusuexc codusuexc,
                         ad_get.nomeusu(cap.codusuexc, 'resumido') nomeusuexc,
                         dhsolicit,
                         cap.dtagend,
                         cap.status
                    from ad_tsfcap cap
                    left join tgfvei v
                      on v.codveiculo = cap.codveiculo
                    left join tgfpar par
                      on par.codparc = cap.motorista
                   where cap.nuap = c.nuap
                     and cap.status in ('A', 'R'))
    loop
      t.nucapsol       := p_nucapsol;
      t.nomeusu        := v_nomeusu;
      t.codcencus      := v_codcencus;
      t.lotacao        := c_cap.lotacao;
      t.descrcencus    := v_descrcencus;
      t.codparctransp  := c_cap.codparctransp;
      t.nomeparctransp := c_cap.nomeparctransp;
      t.codvei         := c_cap.codveiculo;
      t.descrvei       := c_cap.descrvei;
      t.codusuexc      := c_cap.codusuexc;
      t.nomeusuexc     := c_cap.nomeusuexc;
      t.dhsolicit      := c_cap.dhsolicit;
      t.dtagend        := c_cap.dtagend;
      t.status         := c_cap.status;
      t.motivo         := v_motivo;
      t.nuap           := c.nuap;
    
      pipe row(t);
    end loop;
  
  end vouchercab;

  procedure cria_bkp_avisos is
  begin
    for i in (select *
                from tsiavi
               where codusu = 166
                 and dhcriacao < sysdate - 90)
    loop
      begin
        insert into tsiavi_exc values i;
      exception
        when others then
          ad_set.insere_msglog('Erro ao inserir registro de backuo de aviso do sistema');
          continue;
      end;
    end loop;
  
    begin
      delete from tsiavi
       where codusu = 166
         and dhcriacao < sysdate - 90;
    exception
      when others then
        ad_set.insere_msglog(p_mensagem => 'Erro ao excluir aviso do sistema.');
    end;
  end cria_bkp_avisos;

end ad_pkg_cap;
/
