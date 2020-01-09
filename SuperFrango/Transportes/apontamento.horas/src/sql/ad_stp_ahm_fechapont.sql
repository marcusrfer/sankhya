create or replace procedure ad_stp_ahm_fechapont(p_codusu    pls_integer,
                                                 p_idsessao  varchar2,
                                                 p_qtdlinhas number,
                                                 p_mensagem  out varchar2) as

  t                 ad_pkg_ahm.t_apont;
  v_dataini         date;
  v_datafin         date;
  r_cab             tgfcab%rowtype;
  r_con             tcscon%rowtype;
  v_temmedicao      char(1);
  v_sitprod         char(1);
  v_valortotservico float := 0;
  v_itens           pls_integer := 0;
  v_evelibped       pls_integer;
  v_geraordcarga    char(1) := 'N';
  v_codliberador    pls_integer;
  v_vlrdesc         float;
  v_isfatalt        boolean;
  v_faturaalt       varchar2(1);
  v_crdiferente     int := 0;
  v_prjdiferente    int := 0;
  error exception;
  errmsg varchar2(4000);
  --debug  DBA_PLSQL_OBJECT_SETTINGS.plsql_debug%Type;
  debug boolean := false;
begin

  /******************************************************************************** 
  * Autor: Marcus Rangel
  * Processo: Contratação de Serviços de Transportes
  * Objetivo: Realizar a geração do pedido de compras como saida das rotinas que usam 
  os contratos de locação de máquinas/equipamentos/veículos,tanto os contratos 
  por empreito quanto os contratos por medição utilizam esse procedimento para 
  realizar o fechamento.
  **********************************************************************************/
  t.nuapont        := act_int_field(p_idsessao, 1, 'NUAPONT');
  t.nuseqmaq       := act_int_field(p_idsessao, 1, 'NUSEQMAQ');
  t.numcontrato    := act_int_field(p_idsessao, 1, 'NUMCONTRATO');
  r_cab.codtipoper := act_int_param(p_idsessao, 'CODTIPOPER');
  r_cab.codvend    := act_int_param(p_idsessao, 'CODVEND');
  r_cab.observacao := act_txt_param(p_idsessao, 'OBSERVACAO');
  r_cab.dtneg      := trunc(sysdate);
  v_dataini        := act_dta_param(p_idsessao, 'DTINI');
  v_datafin        := act_dta_param(p_idsessao, 'DTFIM');

  /*Tratativa para faturar a partir do layou html5,os campos data estão sendo passados como float*/
  if v_dataini is null then
    v_dataini := to_date(substr(replace(act_dec_param(p_idsessao, 'DTINI'), '.', ''), 1, 8),
                         'yyyymmdd');
  end if;

  if v_datafin is null then
    v_datafin := to_date(substr(replace(act_dec_param(p_idsessao, 'DTFIM'), '.', ''), 1, 8),
                         'yyyymmdd');
  end if;

  if lower(p_idsessao) = 'debug' then
    debug            := true;
    t.nuapont        := 596;
    t.nuseqmaq       := 1;
    t.numcontrato    := 7709;
    r_cab.codtipoper := 170;
    r_cab.codvend    := 995;
    r_cab.observacao := null;
    r_cab.dtneg      := trunc(sysdate);
    v_dataini        := '21/08/2018';
    v_datafin        := '21/09/2018';
  end if;

  --Select PLSQL_DEBUG Into debug From DBA_PLSQL_OBJECT_SETTINGS Where Name = 'AD_STP_FECHAPONT';

  if debug then
    v_geraordcarga := 'N';
  else
    v_geraordcarga := act_escolher_simnao(p_titulo    => 'Geração de Ordem de Carga',
                                          p_texto     => 'Deseja gerar Ordem de Carga para o pedido que será gerado?',
                                          p_chave     => p_idsessao,
                                          p_sequencia => 1);
  
  end if;

  /*Se nro Contrato é nulo,busca do maior contrato dos itens no apontamento*/

  if t.numcontrato is null then
  
    begin
      select c.numcontrato into t.numcontrato from ad_tsfahmc c where nuapont = t.nuapont;
    exception
      when others then
        p_mensagem := 'Erro ao buscar o número do contrato. ' || sqlerrm;
        return;
    end;
  
  end if;

  begin
    select * into r_con from tcscon where numcontrato = t.numcontrato;
  exception
    when others then
      p_mensagem := sqlerrm;
      return;
  end;

  /* Busca o valor dos descontos do contrato */

  begin
    select nvl(sum(d.vlrdesc), 0)
      into v_vlrdesc
      from ad_tsfdfc d
     where d.numcontrato = t.numcontrato
       and nvl(compensado, 'N') = 'N';
  exception
    when no_data_found then
      v_vlrdesc := 0;
  end;

  --valida a ultima ocorrencia do contrato está ativa

  v_sitprod := ad_pkg_ahm.valida_ococontrato(t.numcontrato);

  if nvl(v_sitprod, 'C') <> 'A' then
    errmsg := 'Somente contratos com a última ocorrência ATIVA,podem ser faturados.';
    raise error;
  end if;

  --popula as variáveis com os valores do contrato

  select c.codemp, c.codparc, c.codnat, c.codcencus, c.codproj, c.codtipvenda,
         case
           when c.temmed = 'S' and c.observacoes is not null then
            r_cab.observacao || chr(13) || 'Ref. Apontamento ' || c.ad_nuapont
           else
            'Ref. Apontamento ' || c.ad_nuapont
         end, c.temmed, c.ad_situacao
    into r_cab.codemp, r_cab.codparc, r_cab.codnat, r_cab.codcencus, r_cab.codproj,
         r_cab.codtipvenda, r_cab.observacao, v_temmedicao, r_cab.statusnota
    from tcscon c
   where c.numcontrato = t.numcontrato;

  --valida se o tipo de negociação foi informado

  if r_cab.codtipvenda is null then
    p_mensagem := 'Tipo de negociação não informado no contrato ' || t.numcontrato;
    return;
  end if;

  --busca o nro da solicitação de origem

  select c.ad_codsolst into t.codsolst from tcscon c where c.numcontrato = t.numcontrato;

  -- valida cr nat proj

  begin
    ad_stp_valida_natcrproj_sf(r_cab.codemp,
                               r_cab.codtipoper,
                               r_cab.codnat,
                               r_cab.codcencus,
                               r_cab.codproj,
                               0,
                               p_mensagem);
  
    if p_mensagem is not null then
      return;
    end if;
  end;

  --insere o cabeçalho do pedido

  begin
    ad_set.ins_pedidocab(r_cab.codemp,
                         r_cab.codparc,
                         r_cab.codvend,
                         r_cab.codtipoper,
                         r_cab.codtipvenda,
                         r_cab.dtneg,
                         r_cab.vlrnota,
                         r_cab.codnat,
                         r_cab.codcencus,
                         r_cab.codproj,
                         r_cab.observacao,
                         r_cab.nunota);
  exception
    when others then
      p_mensagem := 'Não gerou o cabeçalho do pedido de compras. Motivo: ' || sqlerrm;
      return;
  end;

  --se é faturamento por apontamento ao invés de contrato

  if t.nuapont is not null then
    for i in 1 .. p_qtdlinhas
    loop
      /* Se possui serviços e máquina,realiza o faturamento do apontamento 
      insere os itens do pedido de compras,atualiza os apontamentos 
      no caso de apontamentos gerados sem máquina,apenas com serviço,o codmaq será nulo*/
    
      -- faturamento por apontamento (todas as máquinas)
      -- quando é faturado pelo cabeçalho do apontamento e nenhuma máquina é selecionada diretamente
      t.nuseqmaq := act_int_field(p_idsessao, i, 'NUSEQMAQ');
    
      -- verifica quantos CRs diferentes existem
      select count(distinct codcencus), count(distinct codproj)
        into v_crdiferente, v_prjdiferente
        from ad_tsfahmapd
       where nuapont = t.nuapont
         and (nuseqmaq = t.nuseqmaq or nvl(t.nuseqmaq, 0) = 0)
         and codcencus is not null;
    
      --ad_pkg_var.Permite_Update := True;
    
      --percorre as máquinas envolvidas
    
      for c_maq in (select m.nuapont, m.numcontrato, m.codprod, m.codmaq, m.nuseqmaq, m.seqmaq,
                           m.codvol
                      from ad_tsfahmmaq m
                      join ad_tsfahmapd a
                        on m.nuapont = a.nuapont
                       and m.nuseqmaq = a.nuseqmaq
                     where m.nuapont = t.nuapont
                       and a.dtinijornada between v_dataini and v_datafin
                       and (m.nuseqmaq = t.nuseqmaq or nvl(t.nuseqmaq, 0) = 0)
                     group by m.nuapont, m.numcontrato, m.codprod, m.nuseqmaq, m.seqmaq, m.codmaq,
                              m.codvol
                     order by m.nuapont, m.nuseqmaq)
      loop
      
        -- verifica se atende as regras de faturamento alternativo para a máquina
        ad_pkg_ahm.check_excecao_faturamento(c_maq.numcontrato,
                                             c_maq.codprod,
                                             c_maq.seqmaq,
                                             v_dataini,
                                             v_datafin,
                                             v_isfatalt,
                                             v_valortotservico,
                                             t.codvol);
      
        --se atender alguma regra
      
        if v_isfatalt then
        
          -- pergunta ao usuário se deseja faturar pela regra
        
          if debug then
            v_faturaalt := 'S';
          else
            declare
              msg_tothoras   float;
              msg_vlrhora    float;
              msg_vlrtothora float;
            begin
              select sum(tad.tothoras),
                     ad_pkg_ahm.get_ultimo_valor(c_maq.numcontrato,
                                                  c_maq.codprod,
                                                  c_maq.codmaq,
                                                  c_maq.codvol,
                                                  sysdate)
                into msg_tothoras, msg_vlrhora
                from ad_tsfahmtad tad
               where tad.nuapont = c_maq.nuapont
                 and tad.codprod = c_maq.codprod
                 and tad.codmaq = c_maq.codmaq
                 and tad.nuseqmaq = c_maq.nuseqmaq
                 and tad.dtapont between v_dataini and v_datafin
               group by ad_pkg_ahm.get_ultimo_valor(c_maq.numcontrato,
                                                     c_maq.codprod,
                                                     c_maq.codmaq,
                                                     c_maq.codvol,
                                                     sysdate);
            
              msg_vlrtothora := msg_tothoras * msg_vlrhora;
              v_faturaalt    := act_escolher_simnao('Confirma Faturamento Alternativo',
                                                    'Foi identificado que esta máquina/serviço possui regras de exceções ' ||
                                                    'de faturamento ativa,' ||
                                                    'deseja gerar o pedido utilizando os dados da exceção? <p>' ||
                                                    'Faturamento normal: ' ||
                                                    ad_get.formatanumero(msg_tothoras) || ' - ' ||
                                                    c_maq.codvol || ' - ' ||
                                                    ad_get.formatavalor(msg_vlrtothora) ||
                                                    '<br>Faturamento Altern: 1 - ' || t.codvol ||
                                                    ' - ' || ad_get.formatavalor(v_valortotservico),
                                                    p_idsessao,
                                                    2);
            
            end;
          end if;
        
        end if;
      
        if v_isfatalt = true and v_faturaalt = 'S' then
          ad_pkg_ahm.fatura_exc_apontamento(r_cab.nunota,
                                            c_maq.nuapont,
                                            c_maq.nuseqmaq,
                                            nvl(t.codvol, c_maq.codvol),
                                            v_dataini,
                                            v_datafin,
                                            v_valortotservico,
                                            v_itens,
                                            p_mensagem);
        else
          ad_pkg_ahm.fat_apontamento(r_cab.nunota,
                                     c_maq.nuapont,
                                     c_maq.nuseqmaq,
                                     v_dataini,
                                     v_datafin,
                                     v_valortotservico,
                                     v_itens,
                                     p_mensagem);
        end if;
      
        if p_mensagem is not null then
          return;
        end if;
      
        r_cab.vlrnota := nvl(r_cab.vlrnota, 0) + v_valortotservico;
      
        if t.nuseqmaq is not null and (v_crdiferente > 1 or v_prjdiferente > 1) then
          ad_pkg_ahm.ins_rateio_apontamento(c_maq.nuapont,
                                            t.nuseqmaq,
                                            r_cab.nunota,
                                            v_dataini,
                                            v_datafin,
                                            p_mensagem);
        
          if p_mensagem is not null then
            return;
          end if;
        end if;
      
      end loop c_maq;
    
      if t.nuseqmaq is null and (v_crdiferente > 1 or v_prjdiferente > 1) then
        ad_pkg_ahm.ins_rateio_apontamento(t.nuapont,
                                          t.nuseqmaq,
                                          r_cab.nunota,
                                          v_dataini,
                                          v_datafin,
                                          p_mensagem);
      
        if p_mensagem is not null then
          return;
        end if;
      end if;
    
    end loop i;
  
    --ad_pkg_var.Permite_Update := False;
    --se não encontrar nenhum apontamento pendente
  
    if v_itens = 0 then
      delete from tgfcab where nunota = r_cab.nunota;
    
      p_mensagem := 'Não foram encontradas horas disponíveis para faturamento nas máquinas selecionadas no período de ' ||
                    v_dataini || ' a ' || v_datafin;
      return;
    end if;
  
    --cria a ligação entre os registros de origem e destino
  
    insert into ad_tblcmf
      (nometaborig, nuchaveorig, nometabdest, nuchavedest)
    values
      ('AD_TSFAHMC', t.nuapont, 'TGFCAB', r_cab.nunota);
  
    /* Insere o extrato do apontamento em html para comprovação das horas pelo liberador */
  
    begin
      stp_i_tsiata_tsfahmtad_sf(r_cab.nunota, t.nuapont);
    exception
      when others then
        errmsg := 'Erro ao inserir o anexo do apontamento no pedido. <br>' || sqlerrm;
        --Raise Error;
        ad_set.insere_msglog(p_mensagem => errmsg);
    end;
  
    /* deduz os descontos do contrato no valor do serviço*/
  
    v_valortotservico := v_valortotservico - v_vlrdesc;
  
    /* se faturamento por empreito - sem medição */
  else
    if r_cab.statusnota in ('C', '0') then
      errmsg := 'Este contrato já está concluído ou cancelado!';
      raise error;
    elsif r_con.ad_situacao = 'P' then
      errmsg := 'Contrato não está confirmado.';
      raise error;
    end if;
  
    if nvl(v_temmedicao, 'N') = 'S' then
      errmsg := 'Contratos que geram pedidos por empreito não podem estar marcados como ''Tem Medição=Sim''';
      raise error;
    end if;
  
    if r_con.parcelaatual = r_con.parcelaqtd then
      errmsg := 'Este Contrato já foi faturado completamente (Qtd. parcelas: ' || r_con.parcelaqtd || ')';
      raise error;
    end if;
  
    for itens_contrato in (select psc.codprod as codprod, 1 as qtdprevista, sum(pmc.vlrunit) vlrunit
                             from tcspsc psc
                             join ad_tsfpmc pmc
                               on pmc.numcontrato = psc.numcontrato
                              and pmc.codprod = psc.codprod
                            where psc.numcontrato = t.numcontrato
                              and pmc.dtvigor = (select max(p2.dtvigor)
                                                   from ad_tsfpmc p2
                                                  where p2.numcontrato = pmc.numcontrato
                                                    and p2.codprod = pmc.codprod
                                                    and p2.dtvigor <= sysdate + 1)
                            group by psc.codprod, 1)
    loop
    
      begin
        ad_set.ins_pedidoitens(r_cab.nunota,
                               itens_contrato.codprod,
                               itens_contrato.qtdprevista,
                               itens_contrato.vlrunit,
                               itens_contrato.qtdprevista * itens_contrato.vlrunit,
                               errmsg);
      
        if errmsg is not null then
          raise error;
        end if;
      
        insert into tcsocc
          (numcontrato, codprod, dtocor, codusu, codparc, codcontato, codocor, descricao)
        values
          (t.numcontrato, itens_contrato.codprod, sysdate, p_codusu, r_cab.codparc, 1, 1004,
           'Faturamento ');
      
      exception
        when others then
          raise error;
      end;
    end loop;
  
    begin
      update tcscon c
         set c.dtrefproxfat = add_months(trunc(sysdate, 'mm'), 1),
             c.parcelaatual = nvl(c.parcelaatual, 0) + 1,
             c.ad_situacao  = 'E'
       where numcontrato = t.numcontrato;
    
      update ad_tsfdfc d
         set d.compensado = 'S',
             d.nunota     = r_cab.nunota
       where numcontrato = t.numcontrato
         and nvl(compensado, 'N') = 'N';
    
    exception
      when others then
        errmsg := 'Erro ao atualizar a parcela do contrato.' || sqlerrm;
        raise error;
    end;
  
  end if;
  /*end of contrato por apontamento*/

  if v_valortotservico is null or v_valortotservico = 0 or v_valortotservico <> r_cab.vlrnota then
  
    select sum(i.vlrtot) into v_valortotservico from tgfite i where nunota = r_cab.nunota;
  
  end if;

  /* Busca a ordem de carga e o veiculo */

  begin
    if v_geraordcarga = 'S' then
    
      stp_keygen_tgfnum('TGFORD', r_cab.codemp, 'TGFORD', 'ORDEMCARGA', 0, r_cab.ordemcarga);
    
      begin
        select codveiculo
          into r_cab.codveiculo
          from tgfvei
         where codparc = r_cab.codparc
           and nvl(ativo, 'N') = 'S'
           and proprio = 'N';
      
      exception
        when no_data_found then
          r_cab.codveiculo := 0;
        when too_many_rows then
          r_cab.codveiculo := 0;
        when others then
          errmsg := 'Erro ao buscar o veículo. ' || sqlerrm;
          raise error;
      end;
    
      begin
        insert into tgford
          (codemp, ordemcarga, dtinic, codparctransp, codveiculo, situacao)
        values
          (r_cab.codemp, r_cab.ordemcarga, sysdate, r_cab.codparc, r_cab.codveiculo, 'A');
      
      exception
        when others then
          errmsg := 'Erro ao Inserir a Ordem de carga. ' || sqlerrm;
          raise error;
      end;
    
    else
      null;
    end if;
  
  end;

  /* atualiza o valor do pedido*/

  begin
  
    /*Set Vlrnota=Nvl(v_VlrFat,v_Valortotservico),Numcontrato=t.Num_contrato*/
  
    /* OBSERVAÇÃO IMPORTANTE!!!
     
    O tipo frete será incluso,pois a nota/pedido não possui frete financeiro,
    essa medida é apenas para que o lançamento possa ser exibido na rotina de 
    pagamento de acerto de OC,que exige que possua valor do frete,o que causa 
    uma duplicidade de valor no pedido,pois soma-se o valor do serviço e o valor 
    do serviço que deve ser informado no vlrfrete para que apareça no acerto.
    A solucção dessa situação está sendo tratada por mim,Marcus Rangel e em breve
    será sanada.
    
    tipfrete alterado para 'N' e adicionada o cif_fob = 'C' - M.Rangel - 15/12/2017
    */
  
    /* Após a atualização para a 3.21 não consegue confirmar o pedido 
    com frete extra nota sem exibir a janela para lançar o financeiro 
    do frete e como esses pedidos serão usados no acerto,a solução foi deixar
    o frete como incluso e dar o desconto no valor,lembrando que esses pedidos não
    possuem financeiro */
    update tgfcab
       set vlrnota     = v_valortotservico,
           numcontrato = t.numcontrato,
           tipfrete    = 'S',
           cif_fob     = 'C',
           vlrfrete = case
                        when v_geraordcarga = 'S' then
                         v_valortotservico
                        else
                         0
                      end,
           ordemcarga = case
                          when v_geraordcarga = 'S' then
                           r_cab.ordemcarga
                          else
                           0
                        end,
           codveiculo = case
                          when v_geraordcarga = 'S' then
                           r_cab.codveiculo
                          else
                           0
                        end,
           vlrdesctot = case
                          when v_geraordcarga = 'S' then
                           v_valortotservico
                          else
                           0
                        end,
           observacao  = observacao || chr(13) || ' Ref.  dias ' || v_dataini || ' a ' || v_datafin ||
                         ', apont. nro ' || t.nuapont
     where nunota = r_cab.nunota;
  
  exception
    when others then
      errmsg := 'Erro ao atualizar valor total do pedido de compras. ' || sqlerrm;
      raise error;
  end;

  /*insere a liberação do pedido*/

  select t.evelibconfped into v_evelibped from ad_tsfelt t where t.nuelt = 1;

  --v_Codliberador := Ad_get.Usuarioliberador('TRANSPORTE');
  /*
  Select codusuresp
  Into v_Codliberador
    From tsicus
  Where codcencus = r_cab.codcencus;
  */

  -- M. Rangel - 17/12/2018
  -- alteração para buscar o liberador do CR de fonte alteranativa
  -- conforme instrução enviada por e-mail

  begin
    select u.codusu
      into v_codliberador
      from ad_itesolcpalibcr l
      join tsiusu u
        on u.codusu = l.codusu
     where l.codcencus = r_cab.codcencus
       and l.ativo = 'SIM'
       and nvl(l.aprova, 'N') = 'S'
       and l.vlrfinal > v_valortotservico
       and (u.dtlimacesso is null or u.dtlimacesso > trunc(sysdate));
  
  exception
    when no_data_found then
      p_mensagem := 'Não foi encontrato o usuário liberador do CR. Por favor revifique se o CR ' ||
                    r_cab.codcencus || ' possui um usuário liberador vinculado ao mesmo.';
      return;
  end;

  /*  
   If v_VlrFat <> 0 Then
    v_Valortotservico:=v_VlrFat;
   End If;
  */

  if debug then
    null;
  else
    ad_set.ins_liberacao(p_tabela    => 'TGFCAB',
                         p_nuchave   => r_cab.nunota,
                         p_evento    => v_evelibped,
                         p_valor     => v_valortotservico,
                         p_codusulib => v_codliberador,
                         p_obslib    => ' Ref. Fechamento de horas do contrato ' || t.numcontrato,
                         p_errmsg    => errmsg);
  
    if errmsg is not null then
      raise error;
    end if;
  end if;

  p_mensagem := 'Gerado o pedido de compras Nº único ' ||
                '<a title="Visualizar registro" target="_parent" href="' ||
                ad_fnc_urlskw('TGFCAB', r_cab.nunota) || '"><font color="#0000FF"><b>' ||
                r_cab.nunota || '</b></font></a>, no valor de ' ||
                ad_get.formatavalor(v_valortotservico);

  /* Insere a ligação enter contrato e pedido de comrpas */

  /* Comentado no dia 19/11/2019 pois depois da mudança na trigger que realiza
  a ligação entre processos adicionais, foi identificado um problema ao excluir lançamentos
  da CAB com o mesmo nunota mesmo que de tabelas diferentes */
  /*begin
      insert into ad_tblcmf
        (nometaborig, nuchaveorig, nometabdest, nuchavedest)
      values
        ('TCSCON', t.numcontrato, 'TGFCAB', r_cab.nunota);
    
    exception
      when others then
        insert into tsilog
          (codusu, dhevento, descricao)
        values
          (stp_get_codusulogado, sysdate, 'Erro ao inserir na tabela de ligação.');
      
    end;
  */
exception
  when error then
    rollback;
    begin
      delete from tgfcab where nunota = r_cab.nunota;
    end;
    p_mensagem := errmsg;
end;
/
