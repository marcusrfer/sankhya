create or replace package ad_pkg_ahm as

  /****************************************************************************
  Autor: Marcus Rangel
  Objetivo: Biblioteca para todos métodos (funções e procedures) utilizadas 
  pelo processo de serviços de transportes>>Apontamentos.
  *****************************************************************************/
  type t_apont is record(
    codsolst     number,
    nuseqmaq     number,
    nuapont      number,
    seqapt       number,
    numcontrato  number,
    codserv      number,
    codmaq       number,
    codvol       char(2),
    qtdneg       float,
    dtinijornada date,
    dtapont      date,
    origem       int,
    ultsequencia boolean,
    dataini      date,
    datafin      date,
    qtdprevista  float,
    qtdusada     float);
  type type_rec_maquinas is record(
    nuapont     number,
    nunota      number,
    codemp      number,
    tipmov      char(1),
    dtneg       date,
    codparc     number,
    nomeparc    varchar2(200),
    numcontrato number,
    codprod     number,
    descrprod   tgfpro.descrprod%type,
    codmaq      number,
    descrmaq    varchar2(200),
    tothoras    float,
    codvol      char(2),
    vlrunit     float,
    vlrtot      float);
  type type_tab_maquinas is table of type_rec_maquinas;
  function vw_maquinas(p_dataini date,
                       p_datafin date) return type_tab_maquinas
    pipelined;

  function descrmaquina(p_codmaquina int) return varchar2;
  /****************************************************************************
  Autor: Marcus Rangel
  Objetivo: get simples de informações da máquina
  *****************************************************************************/

  function horas_residuais(p_nuapont number,
                           p_nuseqmaq number) return float;
  /****************************************************************************
  Autor: Marcus Rangel
  Objetivo: retornar a quantidade de horas residuais de determinada
  máquina, veículo ou equipamento de um determinado contrato.
  *****************************************************************************/

  function qtdhorasapont(p_nuapont number,
                         p_nuseqmaq number,
                         p_tipo char) return float;

  /****************************************************************************
  Autor: Marcus Rangel
  Objetivo: retornar a quantidade de horas já utilizadas de determinada
  máquina, veículo ou equipamento de um determinado contrato.
  *****************************************************************************/

  function nuapontorig(p_numcontrato number) return number;
  /****************************************************************************
  Autor: Marcus Rangel
  Objetivo: Retornar o nome do parceiro do contrato de origem quando há 
  aditivos.
  *****************************************************************************/

  function dadossolicit(p_codsolst number,
                        p_numcontrato number,
                        p_codprod number,
                        p_codmaq number,
                        p_codvol char,
                        p_tipo char) return varchar2;
  /****************************************************************************
  Autor: Marcus Rangel
  Objetivo: get simples de valor (V), quantidade (Q) e unidade de volume (U)
  *****************************************************************************/

  function valida_ococontrato(p_numcontrato number) return char; -- fecha apont maquinas
  /****************************************************************************
  Autor: Marcus Rangel
  Objetivo: Retorna a ultima situação de ocorrência de dado contrato
  *****************************************************************************/

  function nomecontrato(p_nuapont number) return varchar2;
  /****************************************************************************
  Autor: Marcus Rangel
  Objetivo: retornar o nome do parceiro do contrato pelo nro do apontamento
  *****************************************************************************/

  function numcontrato(p_nuapont number) return number;

  function dadoscontrato(p_nuapont number,
                         p_tipo varchar2) return number;

  function valorhora(p_codsolst number,
                     p_nussti number,
                     p_seqmaq number) return float;

  function get_ultimo_valor(p_numcontrato number,
                            p_codprod number,
                            p_codmaq number,
                            p_codvol char,
                            p_dtneg date) return float;
  /****************************************************************************
  Autor: Marcus Rangel
  Objetivo: get simples do valor da hora do  equipamento/máquina/veículo
  *****************************************************************************/

  procedure fat_apontamento(p_nunota pls_integer,
                            p_nuapont pls_integer,
                            p_nuseqmaq pls_integer,
                            p_dateini date,
                            p_datefin date,
                            p_valortotservico out float,
                            p_rowcount out pls_integer,
                            p_mensagem out varchar2);

  procedure fatura_exc_apontamento(p_nunota pls_integer,
                                   p_nuapont pls_integer,
                                   p_nuseqmaq pls_integer,
                                   p_codvol varchar2,
                                   p_dateini date,
                                   p_datefin date,
                                   p_valortotservico float,
                                   p_rowcount out pls_integer,
                                   p_mensagem out varchar2);

  /****************************************************************************
   Autor: Marcus Rangel
   Objetivo: Buscar o valor das horas, quantidade de horas apontadas, inseerir
   os itens no pedido de compras, atualizar o apontamentos e o saldo disponível
   para faturamento.
  *****************************************************************************/

  function get_vlr_atualapont(p_numcontrato number,
                              p_codsolst number,
                              p_nussti number,
                              p_seqmaq number,
                              p_dtapont date) return float;

  /****************************************************************************
   Autor: Marcus Rangel
   Objetivo: Buscar o valor atual do apontamento
  *****************************************************************************/

  procedure ins_rateio_apontamento(p_nuapont number,
                                   p_nuseqmaq number,
                                   p_nunota number,
                                   p_dtini date,
                                   p_dtfin date,
                                   p_errmsg out varchar2);
  /****************************************************************************
   Autor: Marcus Rangel
   Objetivo: gerar o rateio do pedido de compras de acordo com os centros de
   resultados dos apontamentos
  *****************************************************************************/

  --Function isFaturamentoAlternativo(p_numcontrato Number, p_codprod Number, p_seqmaq Number) Return Int;
  -- M. Rangel - função que verifica se o lançamento possui regra de faturamento alternativo

  --Procedure get_valor_fat_alternativo(p_numcontrato Number, p_codprod Number, p_codmaq Number,
  --                                  p_valor Out Float, p_codvol Out Varchar2);

  procedure desfaz_lancamentos(p_codsol number);

  procedure check_excecao_faturamento(p_numcontrato number,
                                      p_codprod number,
                                      p_seqmaq number,
                                      p_dataini date,
                                      p_datafin date,
                                      p_excecao out boolean,
                                      p_valor out float,
                                      p_codvol out varchar2);

  -- Autor: M. Rangel
  -- Objetivo: Calcular o total apontado por dia                                                                           

  procedure calcula_dia_apontamento(p_nuapont number,
                                    p_nuseqmaq number,
                                    p_dia date,
                                    p_turno number);

end ad_pkg_ahm;
/
create or replace package body ad_pkg_ahm as

  function vw_maquinas(p_dataini date,
                       p_datafin date) return type_tab_maquinas
    pipelined as
    t type_rec_maquinas;
  begin
    for c_row in (with pedido as
                     (select cab.nunota, cab.codemp, cab.numcontrato, cab.dtneg, cab.codparc, cab.tipmov
                       from tgfcab cab
                       join tcscon con
                         on cab.numcontrato = con.numcontrato
                      where cab.statusnota = 'L'
                        and con.ambiente like '%TRANSPORTE%'
                        and dtfatur between p_dataini and p_datafin),
                    apont as
                     (select apd.nunota, apd.nuapont, apd.numcontrato, apd.codmaq, codprod, codvol, apd.nuseqmaq
                       from ad_tsfahmapd apd
                       join pedido ped
                         on apd.nunota = ped.nunota
                        and apd.numcontrato = ped.numcontrato
                      group by apd.nunota, apd.nuapont, apd.numcontrato, apd.codmaq, codprod, codvol, apd.nuseqmaq)
                    select r.nuapont,
                           ped.nunota,
                           ped.codemp,
                           ped.tipmov,
                           ped.dtneg,
                           ped.codparc,
                           ad_get.nome_parceiro(ped.codparc, 'P') nomeparc,
                           r.numcontrato,
                           r.codmaq,
                           r.codprod,
                           ad_get.descrproduto(r.codprod) descprod,
                           ad_pkg_ahm.descrmaquina(r.codmaq) descrmaq,
                           sum(r.tothoras) tothoras,
                           r.codvol,
                           ad_pkg_ahm.get_ultimo_valor(r.numcontrato, r.codprod, r.codmaq, r.codvol, ped.dtneg) as vlrunit
                      from ad_tsfahmtad r
                      join pedido ped
                        on r.numcontrato = ped.numcontrato
                      left join apont apt
                        on r.nuapont = apt.nuapont
                       and apt.codprod = r.codprod
                       and apt.codmaq = r.codmaq
                       and r.codvol = apt.codvol
                       and r.nuseqmaq = apt.nuseqmaq
                     group by r.nuapont,
                              ped.nunota,
                              ped.codemp,
                              ped.dtneg,
                              ped.codparc,
                              ad_get.nome_parceiro(ped.codparc, 'P'),
                              ped.codparc,
                              'P',
                              ped.codparc,
                              'P',
                              r.numcontrato,
                              r.codmaq,
                              descrmaquina(r.codmaq),
                              r.codmaq,
                              r.codprod,
                              ad_get.descrproduto(r.codprod),
                              r.codvol,
                              get_ultimo_valor(r.numcontrato, r.codprod, r.codmaq, r.codvol, ped.dtneg),
                              r.numcontrato,
                              r.codprod,
                              r.codmaq,
                              r.codvol,
                              ped.dtneg,
                              ped.tipmov)
    loop
      t.nuapont     := c_row.nuapont;
      t.nunota      := c_row.nunota;
      t.codemp      := c_row.codemp;
      t.tipmov      := c_row.tipmov;
      t.dtneg       := c_row.dtneg;
      t.codparc     := c_row.codparc;
      t.nomeparc    := c_row.nomeparc;
      t.numcontrato := c_row.numcontrato;
      t.codprod     := c_row.codprod;
      t.descrprod   := c_row.descprod;
      t.codmaq      := c_row.codmaq;
      t.descrmaq    := c_row.descrmaq;
      t.codvol      := c_row.codvol;
      t.tothoras    := c_row.tothoras;
      t.vlrunit     := c_row.vlrunit;
      t.vlrtot      := c_row.tothoras * c_row.vlrunit;
      pipe row(t);
    end loop;
  end vw_maquinas;

  -- retorna a descrição da máquina

  function descrmaquina(p_codmaquina int) return varchar2 is
    v_descrmaquina varchar2(4000);
  begin
    select m.descrmaq into v_descrmaquina from ad_tsfcme m where m.codmaq = p_codmaquina;
  
    return v_descrmaquina;
  exception
    when others then
      v_descrmaquina := 'Máquina não encontrada!';
      return v_descrmaquina;
  end descrmaquina;

  -- retorna as horas residuais, estimativa - efetuadas, 
  -- função usada na expressão de campo na tabela de máquinas

  function horas_residuais(p_nuapont number,
                           p_nuseqmaq number) return float is
    v_qtdresidual float := 0;
    v_qtdprevista float := 0;
    v_qtdusada    float := 0;
  begin
    select nvl(qtdprevista, 0)
      into v_qtdprevista
      from ad_tsfahmqpa p
     where p.nuapont = p_nuapont
       and p.nuseqmaq = p_nuseqmaq;
  
    select nvl(sum(td.tothoras), 0)
      into v_qtdusada
      from ad_tsfahmtad td
     where td.nuapont = p_nuapont
       and td.nuseqmaq = p_nuseqmaq;
  
    v_qtdresidual := v_qtdprevista - v_qtdusada;
    return nvl(v_qtdresidual, 0);
  exception
    when others then
      return 0;
  end horas_residuais;

  -- função que retorna a quantidade total apontada
  -- usada na expressão de campo da tabela de máquinas, no apontamento

  function qtdhorasapont(p_nuapont number,
                         p_nuseqmaq number,
                         p_tipo char) return float is
    v_qtdprevista float;
    v_qtdusada    float;
    v_qtdsaldo    float;
    v_result      float;
  begin
    select nvl(sum(qtdprevista), 0)
      into v_qtdprevista
      from ad_tsfahmqpa p
     where p.nuapont = p_nuapont
       and p.nuseqmaq = p_nuseqmaq;
  
    select nvl(sum(tothoras), 0)
      into v_qtdusada
      from ad_tsfahmtad t
     where t.nuapont = p_nuapont
       and t.nuseqmaq = p_nuseqmaq;
  
    v_qtdsaldo := v_qtdprevista - v_qtdusada;
    if p_tipo = 'P' then
      v_result := v_qtdprevista;
    elsif p_tipo = 'C' then
      v_result := v_qtdusada;
    elsif p_tipo = 'S' then
      v_result := v_qtdsaldo;
    end if;
  
    return nvl(v_result, 0);
  exception
    when others then
      v_result := 0;
      return nvl(v_result, 0);
  end qtdhorasapont;

  -- função que retorna o número do apontamento, buscando pelo contrato

  function nuapontorig(p_numcontrato number) return number is
    v_nuapont number;
    pragma autonomous_transaction;
  begin
    select ad_nuapont into v_nuapont from tcscon c where numcontrato = p_numcontrato;
  
    return v_nuapont;
  exception
    when no_data_found then
      v_nuapont := 0;
      return v_nuapont;
  end nuapontorig;

  -- função que retorna dados da solicitação de serviço

  function dadossolicit(p_codsolst number,
                        p_numcontrato number,
                        p_codprod number,
                        p_codmaq number,
                        p_codvol char,
                        p_tipo char) return varchar2 is
    r_sstm   ad_tsfsstm%rowtype;
    v_result varchar2(30);
  begin
    select *
      into r_sstm
      from ad_tsfsstm m
     where m.codsolst = p_codsolst
       and m.codserv = p_codprod
       and m.codmaq = p_codmaq
       and m.numcontrato = p_numcontrato
       and m.codvol = p_codvol;
  
    /*
    V - valor unitário
    Q - quantidade
    U - Unid. medição
    I - ID da máquina
    */
  
    if p_tipo = 'V' then
      v_result := to_char(r_sstm.vlrunit);
    elsif p_tipo = 'Q' then
      v_result := to_char(r_sstm.qtdneg);
    elsif p_tipo = 'U' then
      v_result := r_sstm.codvol;
    elsif p_tipo = 'I' then
      v_result := r_sstm.id;
    end if;
  
    return v_result;
  exception
    when others then
      v_result := 0;
      return v_result;
  end dadossolicit;

  -- função que retorna o valor atual do preço do serviço/máquina pela solicitação

  function get_vlr_atualapont(p_numcontrato number,
                              p_codsolst number,
                              p_nussti number,
                              p_seqmaq number,
                              p_dtapont date) return float is
    v_result float;
  begin
    select m.vlrunit
      into v_result
      from ad_tsfpmc m
     where m.numcontrato = p_numcontrato
       and m.codsolst = p_codsolst
       and m.nussti = p_nussti
       and m.seqmaq = p_seqmaq
       and m.dtvigor = (select max(m2.dtvigor)
                          from ad_tsfpmc m2
                         where m2.numcontrato = m.numcontrato
                           and m2.codsolst = m.codsolst
                           and m2.nussti = m.nussti
                           and m2.seqmaq = m.seqmaq
                           and to_date(m2.dtvigor, 'dd/mm/yyyy') <= to_date(p_dtapont, 'dd/mm/yyyy'))
       and rownum = 1;
  
    return v_result;
  exception
    when others then
      return '0';
  end get_vlr_atualapont;

  -- função que retorna a última ocorrência do contrato, se ativo, cancelado

  function valida_ococontrato(p_numcontrato number) return char is
    vresult char(1);
  begin
    select oco.sitprod
      into vresult
      from tcsocc occ
     inner join tcsoco oco
        on occ.codocor = oco.codocor
     where occ.numcontrato = p_numcontrato
       and occ.dtocor = (select max(dtocor) from tcsocc o2 where o2.numcontrato = occ.numcontrato)
       and trunc(occ.dtocor) <= trunc(sysdate);
  
    return nvl(vresult, 'C');
  end valida_ococontrato;

  -- função que retorna o nome do parceiro do contrato

  function nomecontrato(p_nuapont number) return varchar2 is
    v_nomeparc varchar2(200);
  begin
    begin
      select p.nomeparc
        into v_nomeparc
        from tgfpar p, tcscon c
       where c.codparc = p.codparc
         and c.ad_nuapont = p_nuapont
       group by p.nomeparc;
    
    exception
      when too_many_rows then
        select nomeparc
          into v_nomeparc
          from tgfpar p, tcscon c
         where c.codparc = p.codparc
           and c.ad_nuapont = p_nuapont
           and rownum = 1
         group by nomeparc;
      
      when no_data_found then
        v_nomeparc := 'Parceiro não encontrado.';
    end;
  
    return v_nomeparc;
  end nomecontrato;

  -- função que retorna o nro do contrato pelo nro do apontamento

  function numcontrato(p_nuapont number) return number is
    v_numcontrato varchar2(200);
  begin
    begin
      select c.numcontrato
        into v_numcontrato
        from tcscon c
       where c.ad_nuapont = p_nuapont
         and rownum = 1;
    
    exception
      when no_data_found then
        v_numcontrato := 0;
    end;
  
    return v_numcontrato;
  end numcontrato;

  -- função que retorna dados do contrato pelo nro do apontamento

  function dadoscontrato(p_nuapont number,
                         p_tipo varchar2) return number is
    v_infocontrato number;
  begin
    begin
      select case
               when p_tipo = 'CODCENCUS' then
                nvl(c.codcencus, 0)
               when p_tipo = 'CODPROJ' then
                nvl(c.codproj, 0)
               else
                0
             end
        into v_infocontrato
        from tcscon c
       where c.ad_nuapont = p_nuapont;
    
    exception
      when others then
        v_infocontrato := 0;
    end;
  
    return nvl(v_infocontrato, 0);
  end dadoscontrato;

  -- função que retorna o valor atual do preço do serviço/máquina pelo contrato/máquina

  function get_ultimo_valor(p_numcontrato number,
                            p_codprod number,
                            p_codmaq number,
                            p_codvol char,
                            p_dtneg date) return float is
    v_valorhora float;
  begin
    with maxdata as
     (select max(dtvigor) dtvigor
        from ad_tsfpmc
       where numcontrato = p_numcontrato
         and codprod = p_codprod
         and codmaq = p_codmaq
         and codvol = p_codvol
         and dtvigor <= p_dtneg)
    select m.vlrunit
      into v_valorhora
      from ad_tsfpmc m
      join maxdata d
        on m.dtvigor = d.dtvigor
     where numcontrato = p_numcontrato
       and codprod = p_codprod
       and codmaq = p_codmaq
       and codvol = p_codvol
       and rownum = 1;
  
    return v_valorhora;
  exception
    when others then
      return 0;
  end get_ultimo_valor;

  -- função que retorna o valor da hora

  function valorhora(p_codsolst number,
                     p_nussti number,
                     p_seqmaq number) return float is
    v_valorhora   float;
    v_numcontrato number;
  begin
  
    /*      
    Select m.Vlrunit
    Into v_Valorhora
    From Ad_Tsfsstm m
    Where m.Codsolst = p_Codsolst
    And m.Nussti = p_Nussti
    And m.Seqmaq = p_Seqmaq;
    */
    select m.numcontrato
      into v_numcontrato
      from ad_tsfahmmaq m
     where m.codsolst = p_codsolst
       and m.nussti = p_nussti
       and m.seqmaq = p_seqmaq;
  
    select vlrunit
      into v_valorhora
      from ad_tsfpmc
     where numcontrato = v_numcontrato
       and dhalter = (select max(dhalter) from ad_tsfpmc where numcontrato = v_numcontrato);
  
    return v_valorhora;
  exception
    when others then
      v_valorhora := 0;
      return v_valorhora;
  end valorhora;

  procedure fat_apontamento(p_nunota pls_integer,
                            p_nuapont pls_integer,
                            p_nuseqmaq pls_integer,
                            p_dateini date,
                            p_datefin date,
                            p_valortotservico out float,
                            p_rowcount out pls_integer,
                            p_mensagem out varchar2) is
  
    r_maq            ad_tsfahmmaq%rowtype;
    v_valorhora      float := 0;
    v_horasapontadas float := 0;
    v_valortotalhora float := 0;
    v_count          int := 0;
    errmsg           varchar2(4000);
    error exception;
  begin
    p_rowcount        := 0;
    p_valortotservico := 0;
    select *
      into r_maq
      from ad_tsfahmmaq
     where nuapont = p_nuapont
       and nuseqmaq = p_nuseqmaq;
  
    for c_totdias in (select *
                        from ad_tsfahmtad td
                       where td.nuapont = p_nuapont
                         and td.nuseqmaq = p_nuseqmaq
                         and td.dtapont between p_dateini and p_datefin
                         and nvl(td.pendente, 'N') = 'S')
    loop
    
      -- acumula horas apontadas
      v_horasapontadas := nvl(v_horasapontadas, 0) + c_totdias.tothoras;
      if v_horasapontadas = 0 then
        errmsg := 'Não foram encontradas horas válidas para essa máquina: <b>' ||
                  ad_pkg_ahm.descrmaquina(c_totdias.codmaq) || '</b><br>no período de ' || p_dateini || ' à ' ||
                  p_datefin || '.';
      
        raise error;
      end if;
    
      -- busca o valor da hora
    
      v_valorhora := get_vlr_atualapont(r_maq.numcontrato, r_maq.codsolst, r_maq.nussti, r_maq.seqmaq, c_totdias.dtapont);
    
      if v_valorhora is null then
        errmsg := 'Não foi encontrado o valor da hora do serviço na solicitação/cotação para a máquina ' ||
                  c_totdias.codmaq || ' do serviço ' || ad_get.descrproduto(c_totdias.codprod) || '.';
      
        raise error;
      end if;
    
      -- valor do dia
    
      v_valortotalhora := c_totdias.tothoras * v_valorhora;
    
      -- soma dos apontamentos
      p_valortotservico := p_valortotservico + v_valortotalhora;
      begin
        variaveis_pkg.v_atualizando := true;
        update ad_tsfahmapd a
           set a.faturado = 'S',
               a.nunota   = p_nunota,
               a.dtfecha  = trunc(sysdate),
               a.origem   = 0
         where a.nuapont = c_totdias.nuapont
           and a.nuseqmaq = c_totdias.nuseqmaq
           and nvl(a.dtinijornada, a.dtapont) = c_totdias.dtapont;
      
        update ad_tsfahmtad td
           set td.pendente = 'N'
         where td.dtapont = c_totdias.dtapont
           and td.nuapont = c_totdias.nuapont
           and td.nuseqmaq = c_totdias.nuseqmaq;
      
        variaveis_pkg.v_atualizando := false;
      exception
        when others then
          p_mensagem := 'Erro ao informar faturado no apontamento. ' || sqlerrm;
          return;
      end;
    
      p_rowcount := p_rowcount + 1;
    end loop c_totdias;
  
    -- Insere os itens do contrato no pedido de compra gerado
  
    ad_set.ins_pedidoitens(p_nunota, r_maq.codprod, v_horasapontadas, r_maq.codvol, v_valorhora, p_valortotservico,
                           errmsg);
  
    if errmsg is not null then
      raise error;
    end if;
  
    /* 
    gera a unidade alternativa para o serviço, uma vez que pela aplicação não existe essa opção 
    no cadastro de serviços, e a pedido do GE, o pedido será gerado com quantidades reais e na
    unidade de medição em que o serviço foi prestado.
    */
    begin
      select count(*)
        into v_count
        from tgfvoa v
       where v.codprod = r_maq.codprod
         and v.codvol = r_maq.codvol;
    
      if v_count = 0 then
        insert into tgfvoa
          (codprod, codvol, dividemultiplica, quantidade, ativo)
        values
          (r_maq.codprod, r_maq.codvol, 'M', 1, 'S');
      
      end if;
    
    exception
      when others then
        errmsg := 'Erro ao inserir a unidade alternativa do serviço. ' || sqlerrm;
        raise error;
    end;
  
  exception
    when error then
      p_mensagem := errmsg;
    when others then
      p_mensagem := sqlerrm;
  end fat_apontamento;

  procedure fatura_exc_apontamento(p_nunota pls_integer,
                                   p_nuapont pls_integer,
                                   p_nuseqmaq pls_integer,
                                   p_codvol varchar2,
                                   p_dateini date,
                                   p_datefin date,
                                   p_valortotservico in float,
                                   p_rowcount out pls_integer,
                                   p_mensagem out varchar2) is
  
    r_maq            ad_tsfahmmaq%rowtype;
    v_horasapontadas float := 0;
    v_count          int := 0;
    errmsg           varchar2(4000);
    error exception;
  begin
    p_rowcount := 0;
    select *
      into r_maq
      from ad_tsfahmmaq
     where nuapont = p_nuapont
       and nuseqmaq = p_nuseqmaq;
  
    for c_totdias in (select *
                        from ad_tsfahmtad td
                       where td.nuapont = p_nuapont
                         and td.nuseqmaq = p_nuseqmaq
                         and td.dtapont between p_dateini and p_datefin
                         and nvl(td.pendente, 'N') = 'S')
    loop
      v_horasapontadas := nvl(v_horasapontadas, 0) + c_totdias.tothoras;
      p_rowcount       := p_rowcount + 1;
    end loop c_totdias;
  
    if v_horasapontadas = 0 then
      errmsg := 'Não foram encontradas horas válidas para essa máquina: <b>' || ad_pkg_ahm.descrmaquina(r_maq.codmaq) ||
                '</b><br>no período de ' || p_dateini || ' à ' || p_datefin || '.';
    
      raise error;
    end if;
  
    v_horasapontadas := 1;
  
    /*ad_pkg_ahm.get_valor_fat_alternativo(r_maq.numcontrato,
    r_maq.codprod,
    r_maq.codmaq,
    p_Valortotservico,
    r_maq.codvol);*/
    if nvl(p_valortotservico, 0) = 0 then
      errmsg := 'Não foi encontrado o valor da hora do serviço na solicitação/cotação para a máquina ' || r_maq.codmaq ||
                ' do serviço ' || ad_get.descrproduto(r_maq.codprod) || '.';
    
      raise error;
    end if;
  
    begin
      update ad_tsfahmapd a
         set a.faturado = 'S',
             a.nunota   = p_nunota,
             a.dtfecha  = trunc(sysdate),
             a.origem   = 0
       where a.nuapont = r_maq.nuapont
         and a.nuseqmaq = r_maq.nuseqmaq
         and a.dtapont between p_dateini and p_datefin;
    
      dbms_output.put_line('linhas atualizadas (apd): ' || sql%rowcount);
      update ad_tsfahmtad td
         set td.pendente = 'N'
       where td.nuapont = r_maq.nuapont
         and td.nuseqmaq = r_maq.nuseqmaq
         and td.dtapont between p_dateini and p_datefin;
    
      dbms_output.put_line('linhas atualizadas (tad): ' || sql%rowcount);
    exception
      when others then
        errmsg := 'Erro ao atualizar dados no apontamento.' || chr(13) || sqlerrm;
        raise error;
    end;
  
    -- Insere os itens do contrato no pedido de compra gerado
  
    ad_set.ins_pedidoitens(p_nunota, r_maq.codprod, v_horasapontadas, p_codvol, p_valortotservico, p_valortotservico,
                           errmsg);
  
    if errmsg is not null then
      raise error;
    end if;
  
    /* 
    gera a unidade alternativa para o serviço, uma vez que pela aplicação não existe essa opção 
    no cadastro de serviços, e a pedido do GE, o pedido será gerado com quantidades reais e na
    unidade de medição em que o serviço foi prestado.
    */
    begin
      select count(*)
        into v_count
        from tgfvoa v
       where v.codprod = r_maq.codprod
         and v.codvol = p_codvol;
    
      if v_count = 0 then
        insert into tgfvoa
          (codprod, codvol, dividemultiplica, quantidade, ativo)
        values
          (r_maq.codprod, p_codvol, 'M', 1, 'S');
      
      end if;
    
    exception
      when others then
        errmsg := 'Erro ao inserir a unidade alternativa do serviço. ' || sqlerrm;
        raise error;
    end;
  
  exception
    when error then
      p_mensagem := errmsg;
    when others then
      p_mensagem := sqlerrm;
  end fatura_exc_apontamento;

  procedure ins_rateio_apontamento(p_nuapont number,
                                   p_nuseqmaq number,
                                   p_nunota number,
                                   p_dtini date,
                                   p_dtfin date,
                                   p_errmsg out varchar2) is
  
    x          int := 0;
    rowcount   int := 0;
    v_codnat   number;
    v_projeto  number;
    v_contrato number;
  begin
    select count(*)
      into x
      from ad_tsfahmapd a
     where a.nuapont = p_nuapont
       and (a.nuseqmaq = p_nuseqmaq or nvl(p_nuseqmaq, 0) = 0)
       and a.nunota = p_nunota
    --And Nvl(a.Faturado, 'N') = 'N'
    ;
  
    if x >= 1 then
      begin
        select codnat, codproj into v_codnat, v_projeto from tgfcab where nunota = p_nunota;
      exception
        when others then
          p_errmsg := sqlerrm;
          return;
      end;
    
      select numcontrato
        into v_contrato
        from ad_tsfahmmaq
       where nuapont = p_nuapont
         and (nuseqmaq = p_nuseqmaq or nvl(p_nuseqmaq, 0) = 0)
       group by numcontrato;
    
      for c_rateio in (select a.codcencus, a.codproj, count(*) as qtdcr
                         from ad_tsfahmapd a
                        where a.nuapont = p_nuapont
                          and (a.nuseqmaq = p_nuseqmaq or nvl(p_nuseqmaq, 0) = 0)
                          and a.nunota = p_nunota
                          and nvl(a.dtinijornada, a.dtapont) between p_dtini and p_dtfin
                        group by a.codcencus, a.codproj)
      loop
        begin
          insert into tgfrat
            (origem, nufin, codnat, codcencus, codproj, percrateio, numcontrato, digitado, codusu, dtalter)
          values
            ('E', p_nunota, v_codnat, c_rateio.codcencus, c_rateio.codproj, (c_rateio.qtdcr / x * 100), v_contrato, 'N',
             stp_get_codusulogado, sysdate);
        
          rowcount := rowcount + 1;
        exception
          when others then
            rollback;
            p_errmsg := 'Erro na inserção do rateio. - ' || sqlerrm;
            return;
        end;
      end loop;
    
      if rowcount >= 1 then
        begin
          update tgfcab c set c.rateado = 'S' where nunota = p_nunota;
        
        exception
          when others then
            p_errmsg := 'Erro ao atualizar o pedido. ' || sqlerrm;
            return;
        end;
      end if;
    
    else
      return;
    end if;
  
  end ins_rateio_apontamento;

  procedure desfaz_lancamentos(p_codsol number) is
  begin
    for c_contrato in (select con.numcontrato, con.ad_nuapont nuapont from tcscon con where con.ad_codsolst = p_codsol)
    loop
      for c_maq in (select * from ad_tsfahmmaq m where m.numcontrato = c_contrato.numcontrato)
      loop
        for c_apont in (select *
                          from ad_tsfahmapd a
                         where a.nuapont = c_maq.nuapont
                           and a.numcontrato = c_maq.numcontrato
                           and a.codprod = c_maq.codprod
                           and a.codmaq = c_maq.codmaq
                           and a.codvol = c_maq.codvol)
        loop
          if c_apont.nunota is not null then
            delete from tgfcab where nunota = c_apont.nunota;
          
          end if;
        
          delete from ad_tsfahmapd a
           where a.nuapont = c_apont.nuapont
             and a.numcontrato = c_apont.numcontrato
             and a.codprod = c_apont.codprod
             and a.codmaq = c_apont.codmaq
             and a.codvol = c_apont.codvol
             and a.seqapont = c_apont.seqapont;
        
        end loop c_apont;
      
        delete from ad_tsfahmmaq m
         where m.nuapont = c_maq.nuapont
           and m.numcontrato = c_maq.numcontrato
           and m.codprod = c_maq.codprod
           and m.codmaq = c_maq.codmaq
           and m.codvol = c_maq.codvol;
      
      end loop c_maq;
    
      delete from ad_tsfahmc c where c.nuapont = c_contrato.nuapont;
    
      begin
        delete from tcsocc where numcontrato = c_contrato.numcontrato;
      
        delete from ad_tsfpmc p where p.numcontrato = c_contrato.numcontrato;
      
        delete from tcspre where numcontrato = c_contrato.numcontrato;
      
        delete from tcspsc where numcontrato = c_contrato.numcontrato;
      
        update ad_tsfsstm m
           set m.numcontrato = null
         where codsolst = p_codsol
           and numcontrato = c_contrato.numcontrato
           and numcontrato is not null;
      
        delete from tcscon where numcontrato = c_contrato.numcontrato;
      
      end;
    
    end loop c_contrato;
  end desfaz_lancamentos;

  -- M. Rangel - função que verifica se o lançamento possui regra de faturamento alternativo
  /*Function isFaturamentoAlternativo(p_numcontrato Number, p_codprod Number, p_seqmaq Number) Return Int Is
  v_Count  Int;
  v_Result Int;
  Begin
  Select Count(*)
  Into v_Count
  From ad_tcsepc epc
  Where Numcontrato = p_numcontrato
  And codprod = p_codprod
  And epc.seqmaq = p_seqmaq
  And epc.dtvigor = (Select Max(e2.dtvigor)
                  From ad_tcsepc e2
                 Where e2.numcontrato = epc.numcontrato
                   And e2.codprod = epc.codprod
                   And e2.seqmaq = epc.seqmaq
                   And e2.dtvigor < Trunc(Sysdate));
  
  If v_count > 0 Then
  
  End If;
  
  Exception
  When Others Then
  Return 0;
  End isFaturamentoAlternativo;*/

  procedure check_excecao_faturamento(p_numcontrato number,
                                      p_codprod number,
                                      p_seqmaq number,
                                      p_dataini date,
                                      p_datafin date,
                                      p_excecao out boolean,
                                      p_valor out float,
                                      p_codvol out varchar2) is
    e            ad_tcsepc%rowtype;
    total_horas  float;
    atende_regra boolean default false;
  begin
    select *
      into e
      from ad_tcsepc epc
     where numcontrato = p_numcontrato
       and codprod = p_codprod
       and seqmaq = p_seqmaq
       and epc.dtvigor = (select max(e2.dtvigor)
                            from ad_tcsepc e2
                           where e2.numcontrato = epc.numcontrato
                             and e2.codprod = epc.codprod
                             and e2.seqmaq = epc.seqmaq
                             and e2.dtvigor < trunc(sysdate));
  
    -- verifica horas apontadas
  
    select sum(td.tothoras)
      into total_horas
      from ad_tsfahmmaq m
      join ad_tsfahmtad td
        on td.nuapont = m.nuapont
       and td.numcontrato = m.numcontrato
       and td.codprod = m.codprod
       and td.codmaq = m.codmaq
       and td.codvol = m.codvol
       and td.nuseqmaq = m.nuseqmaq
     where m.numcontrato = p_numcontrato
       and m.codprod = p_codprod
       and m.seqmaq = p_seqmaq
       and td.dtapont between p_dataini and p_datafin;
  
    --verifica regra 
  
    if e.sinal = '=' then
      if total_horas = e.qtdneg then
        atende_regra := true;
      end if;
    elsif e.sinal = '>=' then
      if total_horas >= e.qtdneg then
        atende_regra := true;
      end if;
    elsif e.sinal = '<=' then
      if total_horas <= e.qtdneg then
        atende_regra := true;
      end if;
    end if;
  
    if atende_regra then
      p_excecao := true;
      p_codvol  := e.codvol;
      p_valor   := e.valor;
    else
      p_excecao := false;
    end if;
  
  exception
    when others then
      p_valor   := 0;
      p_codvol  := 0;
      p_excecao := false;
  end check_excecao_faturamento;

  procedure calcula_dia_apontamento(p_nuapont number,
                                    p_nuseqmaq number,
                                    p_dia date,
                                    p_turno number) as
  
    maq             ad_tsfahmmaq%rowtype;
    v_horas         float;
    v_totalhorasdia float := 0;
    v_tipomedida    char(1);
    v_horafmt       varchar2(10);
    d1              date;
    d2              date;
    q1              number;
    q2              number;
    type tipo_tsfahmapd is table of ad_tsfahmapd%rowtype;
    t tipo_tsfahmapd := tipo_tsfahmapd();
  begin
  
    /*
    p_Nuapont  := 714;
    p_Nuseqmaq := 1;
    p_Dia      := '15/01/2019';
    p_Turno    := Null;
    */
    select *
      into maq
      from ad_tsfahmmaq
     where nuapont = p_nuapont
       and nuseqmaq = p_nuseqmaq;
  
    select nvl(v.ad_tipomed, 'Q') into v_tipomedida from tgfvol v where v.codvol = maq.codvol;
  
    select *
      bulk collect
      into t
      from ad_tsfahmapd a
     where a.nuapont = p_nuapont
       and a.nuseqmaq = p_nuseqmaq
          --And a.Dtapont = p_Dia
       and nvl(a.dtinijornada, a.dtapont) = p_dia
       and (to_number(a.turno) = p_turno or 0 = 0)
     order by nvl(a.dtinijornada, a.dtapont), a.turno, a.tipoapont desc;
  
    for z in t.first .. t.last
    loop
      if v_tipomedida = 'T' then
        if nvl(replace(t(z).horimetro, '.', ','), 0) = 0 then
          if t(z).tipoapont = 'I' then
            v_horafmt := substr(lpad(t(z).hora, 4, '0'), 1, 2) || ':' || substr(lpad(t(z).hora, 4, '0'), 3, 2);
          
            d1 := to_date(t(z).dtapont || ' ' || v_horafmt || ':00', 'dd/mm/yyyy hh24:mi:ss');
          
          else
            v_horafmt := substr(lpad(t(z).hora, 4, '0'), 1, 2) || ':' || substr(lpad(t(z).hora, 4, '0'), 3, 2);
          
            d2 := to_date(t(z).dtapont || ' ' || v_horafmt || ':00', 'dd/mm/yyyy hh24:mi:ss');
          
            v_horas         := round(24 * (d2 - d1), 2);
            v_totalhorasdia := nvl(v_totalhorasdia, 0) + v_horas;
          end if;
        
        else
          if t(z).tipoapont = 'I' then
            q1 := replace(t(z).horimetro, '.', ',');
          else
            q2              := replace(t(z).horimetro, '.', ',');
            v_horas         := q2 - q1;
            v_totalhorasdia := nvl(v_totalhorasdia, 0) + v_horas;
          end if;
        end if;
      
      else
        v_totalhorasdia := nvl(v_totalhorasdia, 0) + t(z).qtdneg;
      end if;
    end loop;
  
    dbms_output.put_line(v_totalhorasdia);
    begin
      merge into ad_tsfahmtad tot
      using (select p_nuapont nuapont, p_dia as dtapont, p_nuseqmaq as nuseqmaq from dual) d
      on (tot.dtapont = d.dtapont and tot.nuapont = d.nuapont and tot.nuseqmaq = d.nuseqmaq)
      when matched then
        update
           set tot.tothoras = v_totalhorasdia
         where tot.dtapont = d.dtapont
           and tot.nuapont = d.nuapont
           and tot.nuseqmaq = d.nuseqmaq
           and tot.pendente = 'S'
      when not matched then
        insert
          (dtapont, nuapont, numcontrato, codmaq, codprod, codvol, tothoras, pendente, nuseqmaq)
        values
          (p_dia, p_nuapont, maq.numcontrato, maq.codmaq, maq.codprod, maq.codvol, abs(v_totalhorasdia), 'S',
           p_nuseqmaq);
    
    exception
      when others then
        raise;
    end;
  
  end calcula_dia_apontamento;

end ad_pkg_ahm;
/
