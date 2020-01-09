create or replace package ad_pkg_metransp is

  -- Author  : M.RANGEL
  -- Created : 28/08/2017 14:52:43
  -- Purpose : Atender o processo de cálculo de metas de transporte

  cdcm constant int := 4;

  /*
  * Buscar o valor previsto pelo comercial para a referência
  */
  function get_qtdsimulada(p_dtref date) return float;

  /*
  * Buscar a quantidade total carregada para a referência
  */
  function get_qtdrealizada(p_dtref date) return float;
  function get_qtdrealizada_reg(p_dtref date, p_codreg number) return float;
  function get_qtdrealizada_cat(p_dtref date, p_codcat number) return float;

  /*
  * Efetua os calculos da referência considerando a média passada
  */
  procedure calcula_valores_metas(p_dtref date, p_codcat number, errmsg out nocopy varchar2);

  procedure calcula_valores_metas_reg(p_dtref date, p_codcat number, p_errmsg out nocopy varchar2);

  function get_km_orcarga_dupl(p_codemp number, p_ordemcarga number, p_peso float) return float;

  type type_rec_fretefrango is record(
    dtref          date,
    codger         number,
    nomeger        varchar2(400),
    codemp         number,
    ordemcarga     number,
    qtdordenscarga number,
    qtdentregas    number,
    codcat         number,
    categoria      varchar2(400),
    pesomediocat   float,
    capacidade     float,
    totalfrete     float,
    totalkm        float,
    totalpeso      float,
    totalvlrkm     float,
    totalpercocup  float);

  type table_rec_fretefrango is table of type_rec_fretefrango;

  function basefretefrango(p_codcat number, p_dataini date, p_datafin date)
    return table_rec_fretefrango
    pipelined;

  function get_vlrfrete_orcarga_dupl(p_codemp number, p_ordemcarga number, p_vlrfrete float)
    return float;

end ad_pkg_metransp;
/
create or replace package body ad_pkg_metransp is

  function get_qtdsimulada(p_dtref date) return float is
    v_result float;
  begin
  
    /*
    Alteração para duplicar os valores das regiões que possuem transbordo
    a marcação das regiões foi feita no cadastro de vendedores, nos gerentes
    que correspondem às suas respectivas regiões, reutilizando o campo
    "Cód. Categoria de Venda" AD_CODCAT = 2
    */
  
    select sum(case
                 when ven.ad_codcat = '2' then
                  round(ef.qtdsimulada, cdcm) * 2
                 else
                  round(ef.qtdsimulada, cdcm)
               end)
      into v_result
      from vw_estima_fat_sf ef
      join tgfven ven
        on ef.codger = ven.codvend
     where trunc(ef.dtrererencia, 'mm') = p_dtref
       and ven.ativo = 'S';
  
    return v_result;
  
  end get_qtdsimulada;

  function get_qtdrealizada(p_dtref date) return float is
    v_result float;
  begin
    select sum(ff.pesototal)
      into v_result
      from ad_vw_fretefrango ff
     where ff.dtref = p_dtref
       and ff.vlrkm > 0
       and ff.vlrfrete > 0;
    return v_result;
  end get_qtdrealizada;

  function get_qtdrealizada_reg(p_dtref date, p_codreg number) return float is
    v_result float;
  begin
    select sum(ff.pesototal)
      into v_result
      from ad_vw_fretefrango ff
     where ff.dtref = p_dtref
       and ff.vlrkm > 0
       and ff.vlrfrete > 0
       and ff.codger = p_codreg;
    return v_result;
  exception
    when others then
      return 0;
  end get_qtdrealizada_reg;

  function get_qtdrealizada_cat(p_dtref date, p_codcat number) return float is
    v_result float;
  begin
    select sum(ff.pesototal)
      into v_result
      from ad_vw_fretefrango ff
     where ff.dtref = p_dtref
       and ff.vlrkm > 0
       and ff.vlrfrete > 0
       and ff.codcat = p_codcat;
    return v_result;
  exception
    when others then
      return 0;
  end get_qtdrealizada_cat;

  function get_km_orcarga_dupl(p_codemp number, p_ordemcarga number, p_peso float) return float is
    v_dtinic  date;
    maiorvlr  float := 0;
    maiorkm   float := 0;
    v_totalkm float;
  begin
  
    /*Begin
    Select dtinic
      Into v_dtinic
      From tgford o
     Where o.ordemcarga = p_OrdemCarga;
    Exception
      When Others Then
        Raise;
    End;*/
  
    select peso
      into maiorvlr
      from (select v.codger, round(sum(c.peso), 2) peso
               from tgfcab c
               join tgfven v
                 on c.codvend = v.codvend
              where c.codemp = p_codemp
                and c.ordemcarga = p_ordemcarga
                and c.tipmov = 'V'
              group by v.codger
              order by sum(c.peso) desc)
     where rownum = 1;
  
    select round(sum(ad_km), cdcm)
      into maiorkm
      from tgfcab c
      join tgfven v
        on c.codvend = v.codvend
     where c.codemp = p_codemp
       and c.ordemcarga = p_ordemcarga
       and c.tipmov = 'V'
     order by sum(c.peso) desc;
  
    /*    For r In (Select v.codger, Sum(c.ad_km) As totalkm, Sum(c.peso) totalpeso
                From tgfcab c
                Join tgfven v
                  On c.codvend = v.codvend
               Where c.ordemcarga = p_OrdemCarga
                 And c.codemp = p_codemp
                 And c.tipmov <> 'P'
               Group By v.codger
               Order By 1)
    
    Loop
    
      If maiorvlr < r.totalpeso Then
        maiorvlr := r.totalpeso;
        --maiorkm  := r.totalkm;
      Else
        Null;
      End If;
    
      maiorkm := maiorkm + r.totalkm;
    
    End Loop;*/
  
    if p_peso = maiorvlr then
      v_totalkm := round(maiorkm, cdcm);
    else
      v_totalkm := null;
    end if;
  
    return v_totalkm;
  
  end get_km_orcarga_dupl;

  function get_vlrfrete_orcarga_dupl(p_codemp number, p_ordemcarga number, p_vlrfrete float)
    return float is
    v_dtinic     date;
    v_maiorvlr   float := 0;
    v_vlrtotfre  float;
    v_totalfrete float;
  begin
  
    select frete
      into v_maiorvlr
      from (select v.codger, round(sum(c.vlrfrete), cdcm) frete
               from tgfcab c
               join tgfven v
                 on c.codvend = v.codvend
              where c.codemp = p_codemp
                and c.ordemcarga = p_ordemcarga
                and c.tipmov = 'V'
              group by v.codger
              order by sum(c.vlrfrete) desc)
     where rownum = 1;
  
    select round(sum(c.vlrfrete), cdcm)
      into v_vlrtotfre
      from tgfcab c
      join tgfven v
        on c.codvend = v.codvend
     where c.codemp = p_codemp
       and c.ordemcarga = p_ordemcarga
       and c.tipmov = 'V'
     order by sum(c.vlrfrete) desc;
  
    if p_vlrfrete = v_maiorvlr then
      v_totalfrete := v_vlrtotfre;
    else
      v_totalfrete := null;
    end if;
  
    return v_totalfrete;
  
  end get_vlrfrete_orcarga_dupl;

  procedure calcula_valores_metas(p_dtref date, p_codcat number, errmsg out nocopy varchar2) is
    mes                date;
    descrcat           varchar2(100);
    qtd_prev_comercial float := 0;
    qtd_real_total_mes float := 0;
    qtd_real_cat_mes   float := 0;
    capacid_cat        float;
    capacid_media_cat  float := 0;
    capacid_real_ocup  float;
    perc_vol_cat_mes   float := 0;
    perc_vol_cat_medio float := 0;
    perc_ocup_mes      float;
    perc_ocup_medio    float := 0;
    total_km_mes       float;
    total_km_medio     float := 0;
    total_km_prev      float;
    valor_km_mes       float;
    valor_km_media     float := 0;
    qtd_prev_ref       float;
    nro_viagens        float;
    custototal         float;
    custofrete         float;
    memocalc           clob;
    i                  number;
  begin
  
    i := 3;
  
    select upper(categoria) into descrcat from ad_tsfcat where codcat = p_codcat;
  
    memocalc := descrcat || ' - ' || 'Ref.: ' || p_dtref || '<br>';
  
    --Quantidade prevista pelo comercial, cubo 415210 - Estimativa de faturamento
    qtd_prev_comercial := round(get_qtdsimulada(p_dtref), 4);
  
    memocalc := memocalc || chr(13) || 'Previsao de Entrega:' ||
                ltrim(ad_get.formatanumero(qtd_prev_comercial)) || '<br>';
  
    -- percorre o período
    for l in 1 .. i
    loop
      -- determina os meses analisados
      if extract(month from p_dtref) = 11 then
        mes := add_months(trunc(p_dtref, 'mm'), ((-1 * l) - 2));
      elsif extract(month from p_dtref) = 12 then
        mes := add_months(trunc(p_dtref, 'mm'), ((-1 * l) - 3));
      else
        mes := add_months(trunc(p_dtref, 'mm'), ((-1 * l) - 1));
      end if;
    
      -- busca quantidadee real faturada no mês
      qtd_real_total_mes := round(get_qtdrealizada(mes), 4);
    
      memocalc := memocalc || chr(13) || 'Qtd. Entrega Total: ' || mes || ' - ' ||
                  ltrim(ad_get.formatanumero(qtd_real_total_mes)) || '<br>';
    
      select round(sum(ff.pesototal), 4),
             --qtd_real_cat_mes
             sum(ff.perc_ocupacao),
             --perc_Ocup_Mes
             case
               when ff.qtdordenscarga > 0 then
                sum(ff.kmtotal / ff.qtdordenscarga)
               else
                0
             end,
             --total_km_Mes
             case
               when ff.kmtotal > 0 then
                sum(ff.vlrfrete / ff.kmtotal)
               else
                0
             end,
             --valor_km_Mes
             ff.pesomediocat --capacid_cat
        into qtd_real_cat_mes, perc_ocup_mes, total_km_mes, valor_km_mes, capacid_cat
        from ad_vw_fretefrango ff
       where ff.dtref = mes
         and ff.codcat = p_codcat
       group by ff.pesomediocat;
    
      memocalc := memocalc || chr(13) || 'Qtd. Entrega Categoria: ' || mes || ' - ' ||
                  ltrim(ad_get.formatanumero(qtd_real_cat_mes)) || '<br>';
    
      -- percentual de volume por categoria frente ao total faturado
      perc_vol_cat_mes := round(qtd_real_cat_mes / qtd_real_total_mes, cdcm);
      memocalc         := memocalc || chr(13) || '% Volume Categoria:' || mes || ' - ' ||
                          ltrim(ad_get.formatanumero(perc_vol_cat_mes * 100)) || '<br>';
    
      -- Capacidade média da categoria no período      
      capacid_media_cat := capacid_media_cat + capacid_cat;
    
      --
      perc_vol_cat_medio := round((perc_vol_cat_medio + perc_vol_cat_mes), cdcm);
    
      perc_ocup_medio := perc_ocup_medio + perc_ocup_mes;
    
      total_km_medio := total_km_medio + total_km_mes;
    
      valor_km_media := valor_km_media + valor_km_mes;
    
    end loop;
  
    perc_vol_cat_medio := round(perc_vol_cat_medio / i, cdcm);
    memocalc           := memocalc || chr(13) || '% Volume médio: ' ||
                          ltrim(ad_get.formatanumero(perc_vol_cat_medio * 100)) || '<br>';
  
    capacid_media_cat := capacid_media_cat / i;
    memocalc          := memocalc || chr(13) || 'Ocupação Média Cat.: ' ||
                         ltrim(ad_get.formatanumero(capacid_media_cat)) || '<br>';
  
    perc_ocup_medio := perc_ocup_medio / i;
    memocalc        := memocalc || chr(13) || '% OCupação Médio Cat.: ' ||
                       ltrim(ad_get.formatanumero(perc_ocup_medio)) || '<br>';
  
    total_km_medio := total_km_medio / i;
    memocalc       := memocalc || chr(13) || 'Média KM: ' ||
                      ltrim(ad_get.formatanumero(total_km_medio)) || '<br>';
  
    valor_km_media := valor_km_media / i;
    memocalc       := memocalc || chr(13) || 'Valor do Km: ' ||
                      ltrim(ad_get.formatanumero(valor_km_media)) || '<br>';
  
    qtd_prev_ref := qtd_prev_comercial * perc_vol_cat_medio;
    memocalc     := memocalc || chr(13) || 'Qtd. Prevista: ' ||
                    ltrim(ad_get.formatanumero(qtd_prev_ref)) || '<br>';
  
    capacid_real_ocup := capacid_media_cat * (perc_ocup_medio / 100);
    memocalc          := memocalc || chr(13) || 'Capacidade real: ' ||
                         ltrim(ad_get.formatanumero(capacid_real_ocup)) || '<br>';
  
    nro_viagens := qtd_prev_ref / capacid_real_ocup;
    memocalc    := memocalc || chr(13) || 'Nro Viagens: ' ||
                   ltrim(ad_get.formatanumero(nro_viagens)) || '<br>';
  
    total_km_prev := nro_viagens * total_km_medio;
    memocalc      := memocalc || chr(13) || 'Total KM: ' ||
                     ltrim(ad_get.formatanumero(total_km_prev)) || '<br>';
  
    custototal := total_km_prev * valor_km_media;
    memocalc   := memocalc || chr(13) || 'Custo Total: ' || ltrim(ad_get.formatanumero(custototal)) ||
                  '<br>';
  
    custofrete := custototal / (qtd_prev_ref / 1000);
    memocalc   := memocalc || chr(13) || 'Custo Frete - ' ||
                  ltrim(ad_get.formatanumero(custofrete)) || '<br>';
  
    <<insere_memo>>
    begin
      insert into ad_tsfmcmtl
        (dtref, codcat, qtd_prev_comercial, perc_vol_cat_medio, capacid_media_cat, perc_ocup_medio,
         total_km_medio, valor_km_media, qtd_prev_ref, capacid_real_ocup, nro_viagens, total_km_prev,
         custototal, custofrete, memocalc)
      values
        (p_dtref, p_codcat, qtd_prev_comercial, perc_vol_cat_medio, capacid_media_cat,
         perc_ocup_medio, total_km_medio, valor_km_media, qtd_prev_ref, capacid_real_ocup,
         nro_viagens, total_km_prev, custototal, custofrete, memocalc);
    exception
      when dup_val_on_index then
        delete from ad_tsfmcmtl
         where dtref = p_dtref
           and codcat = p_codcat;
        goto insere_memo;
    end;
  
  exception
    when others then
      rollback;
      errmsg := sqlerrm;
  end calcula_valores_metas;

  procedure calcula_valores_metas_reg(p_dtref date, p_codcat number, p_errmsg out nocopy varchar2) is
    descricao_cat   varchar2(200);
    peso_veiculo    float;
    data_ini        date;
    data_fin        date;
    peso_real_total float;
    peso_real_cat   float;
    perc_real_vol   float;
    peso_prev_total float;
    peso_prev_cat   float;
    v_memoriacalc   clob;
    v_detailcat     clob;
  
    type type_rec_metas is record(
      qtdneg      float := 0,
      distancia   float := 0,
      capacidade  float := 0,
      valorkm     float := 0,
      qtdviagens  float := 0,
      percocup    float := 0,
      custotransp float := 0,
      custofrete  float := 0);
  
    soma type_rec_metas;
    prev type_rec_metas;
    tot  type_rec_metas;
  
    qtd_regioes int := 0;
  
    error exception;
  
  begin
  
    begin
      select initcap(c.categoria) into descricao_cat from ad_tsfcat c where codcat = p_codcat;
      dbms_output.put_line('Categoria: ' || descricao_cat);
    exception
      when others then
        p_errmsg := 'Erro ao buscar dados da categoria. <br>' || chr(13) || sqlerrm;
        p_errmsg := replace(p_errmsg, 'ORA-01403:', ' ');
        p_errmsg := p_errmsg || chr(13) || dbms_utility.format_error_backtrace;
        --Raise error;
        return;
    end;
  
    begin
      select pesomax
        into peso_veiculo
        from ad_tsfcat c
       where c.codcat = p_codcat
         and nvl(c.pesomax, 0) > 0;
    
      if nvl(peso_veiculo, 0) = 0 then
        p_errmsg := 'Categoria não possui peso informado! Verifique o cadastro da mesma.';
        --Raise error;
        return;
      end if;
    
    exception
      when others then
        p_errmsg := 'Erro ao buscar o <b style="color:red;">peso da categoria.</b>' ||
                    replace(sqlerrm, 'ORA-01403:', ' ');
        --Raise error;
        return;
    end;
  
    v_memoriacalc := '<!DOCTYPE html>
		              <html>
									<head>
									<style>
									table{ font-family: arial, sans-serif; border-collapse: collapse; width: 100%; }
									td, th { border: 1px solid #dddddd; padding: 3px; }
									tr:nth-child(even) {background-color: #dddddd;}
									</style>
									<body>' || chr(13);
  
    v_memoriacalc := v_memoriacalc || chr(13) || 'Categoria: ' || p_codcat || ' -' || descricao_cat ||
                     '<br>';
    v_memoriacalc := v_memoriacalc || chr(13) || 'Referência: ' || p_dtref || '<br>';
  
    -- tratativa para identificar o período de cálculo
    /*
    tudo que for 01/02/03 .. pega 09/10/11
    tudo que for 04/05/06 .. pega 12/01/02..
    tudo que for 07/08/09 .. pega 03/04/05
    tudo que for 10/11/12 .. pega 06/07/08
    */
  
    if extract(month from p_dtref) in (1, 2, 3) then
      data_fin := '01/11/' || substr(to_char(p_dtref - 365), 7, 4);
    elsif extract(month from p_dtref) in (4, 5, 6) then
      data_fin := '01/02/' || substr(to_char(p_dtref), 7, 4);
    elsif extract(month from p_dtref) in (7, 8, 9) then
      data_fin := '01/05/' || substr(to_char(p_dtref), 7, 4);
    elsif extract(month from p_dtref) in (10, 11, 12) then
      data_fin := '01/08/' || substr(to_char(p_dtref), 7, 4);
    end if;
  
    data_ini := add_months(data_fin, -2);
  
    -- busca o peso real total do período
    <<calcula_peso_real>>
    begin
    
      select sum(ff.pesototal)
        into peso_real_total
        from ad_vw_fretefrango ff
       where trunc(ff.dtref, 'mm') between data_ini and data_fin;
    
      if nvl(peso_real_total, 0) = 0 then
        data_ini := add_months(data_ini, -12);
        data_fin := add_months(data_fin, -12);
        goto calcula_peso_real;
      
        --p_ErrMsg := 'Não existem dados de peso vendido para este perído: ' || data_ini || ' à ' ||Last_Day(data_fin);
        --Raise error;
        --Return;
      end if;
    
    exception
      when others then
        p_errmsg := 'Erro ao buscar peso vendido no período. ' || sqlerrm;
        --Raise error;
        return;
    end;
  
    v_memoriacalc := v_memoriacalc || chr(13) || 'Período base: ' || data_ini || ' a ' ||
                     last_day(data_fin) || '<br>';
  
    v_memoriacalc := v_memoriacalc || chr(13) || 'Total Faturado Período: ' ||
                     ad_get.formatanumero(peso_real_total) || '<br>';
  
    -- total faturado da categoria no período
    -- nesse momento, se não há movimentação o data fin e ini já assumiram
    -- o valor do ano anterior
    begin
      select sum(ff.pesototal)
        into peso_real_cat
        from ad_vw_fretefrango ff
       where trunc(ff.dtref, 'mm') between data_ini and data_fin
         and ff.codcat in (select codcat from ad_tsfcat c where c.codcatpai = p_codcat);
      dbms_output.put_line('Peso Real da Categoria: ' || ad_get.formatanumero(peso_real_cat));
    exception
      when others then
        p_errmsg := ad_get.formatnativeoramsg('Erro ao buscar dados do período. ' || sqlerrm);
        --Raise error;
    end;
  
    v_memoriacalc := v_memoriacalc || chr(13) || 'Total Fat. Categoria: ' ||
                     ad_get.formatanumero(peso_real_cat) || '<br>';
  
    -- % de volume da categoria em relação ao total faturado
    perc_real_vol := case
                       when peso_real_total > 0 then
                        round(peso_real_cat / peso_real_total, cdcm)
                       else
                        0
                     end;
  
    -- quantidade total prevista para todas as regiões  
    <<insere_previsto>>
    begin
      select sum(qtdprevista) into peso_prev_total from ad_tsfpcr p where dtref = p_dtref;
    
      if nvl(peso_prev_total, 0) = 0 then
      
        Begin
          Merge into ad_tsfpcr p
          using (select ef.dtrererencia dtref , ef.codger codreg ,
                   sum(case
                         when ven.ad_codcat = '2' then
                          round(ef.qtdsimulada, cdcm) * 2
                         else
                          round(ef.qtdsimulada, cdcm)
                       end) qtdprevista 
              from vw_estima_fat_sf ef
              join tgfven ven
                on ef.codger = ven.codvend
             where trunc(ef.dtrererencia, 'mm') = p_dtref
               and ven.ativo = 'S'
             group by ef.dtrererencia, ef.codger) d
          on (p.dtref = d.dtref And p.codreg = d.codreg)
          when matched then 
           Update Set qtdprevista = d.qtdprevista
          when not matched then
           Insert Values (d.dtref, d.codreg, d.qtdprevista);
            
        exception
          when others then
            p_errmsg := 'Erro ao atualizar as quantidades previstas pelo comercial. ' || sqlerrm;
            p_errmsg := ad_get.formatnativeoramsg(p_errmsg);
            --Raise error;
            return;
        end;
      
        goto insere_previsto;
      
      end if;
    end;
  
    v_memoriacalc := v_memoriacalc || chr(13) || 'Total Previsto: ' ||
                     ad_get.formatanumero(peso_prev_total) || '<br>';
  
    -- quantidade prevista para a categoria de acordo com o % de representatividade
    -- da categoria no faturamento total do período
    peso_prev_cat := round(peso_prev_total * perc_real_vol, cdcm);
    dbms_output.put_line('Volume Previsto para a Categoria: ' ||
                         ad_get.formatanumero(peso_prev_cat));
  
    v_memoriacalc := v_memoriacalc || chr(13) || 'Total Previsto Categoria: ' ||
                     ad_get.formatanumero(peso_prev_cat) || '<br>';
  
    v_detailcat := '<br><table border=1 style="width:100%">
						               <tr>
														 <th>Região</th>
														 <th align="right">Peso</th>
														 <th align="right">km</th>
														 <th align="right">R$/Km</th>
														 <th align="right">%Ocup</th>
														 <th align="right">Viagens</th>
													 </tr>
													 ';
  
    for reg in (select b.codcat, initcap(b.nomeger) nomeger, round(sum(totalpeso), cdcm) med_peso,
                       nvl(round(avg(b.totalkm), cdcm), 0) med_km,
                       nvl(round(fc_divide(sum(totalfrete), sum(totalkm)), 2), 0) med_vlrkm,
                       nvl(round(avg(totalpercocup), cdcm), 0) med_ocupacao,
                       nvl(sum(totalpercocup), 0) soma_ocupacao,
                       nvl(sum(qtdordenscarga), 0) qtd_entregas
                  from table(ad_pkg_metransp.basefretefrango(p_codcat, data_ini, data_fin)) b
                 group by b.codcat, b.nomeger, initcap(b.nomeger)
                 order by 1, 2)
    loop
      qtd_regioes := qtd_regioes + 1;
    
      dbms_output.put_line('Região: ' || reg.nomeger);
    
      soma.valorkm    := soma.valorkm + reg.med_vlrkm;
      soma.qtdviagens := soma.qtdviagens + reg.qtd_entregas;
      soma.percocup   := soma.percocup + reg.soma_ocupacao;
      soma.distancia  := soma.distancia + (reg.med_km * reg.qtd_entregas);
    
      dbms_output.put_line('Valor do km - qtd Entregas - ocupacao - distancia');
      dbms_output.put_line(reg.med_vlrkm || ' - ' || reg.qtd_entregas || ' - ' ||
                           reg.soma_ocupacao || ' - ' || (reg.med_km * reg.qtd_entregas));
    
      begin
        prev.qtdneg      := round(fc_divide(reg.med_peso, peso_real_cat), cdcm) * peso_prev_cat;
        prev.qtdviagens  := round(fc_divide(prev.qtdneg, (peso_veiculo * (reg.med_ocupacao / 100))),
                                  cdcm);
        prev.distancia   := round(prev.qtdviagens * nvl(reg.med_km, 0), cdcm);
        prev.custotransp := round(prev.distancia * nvl(reg.med_vlrkm, 0), cdcm);
      
        dbms_output.put_line('Previsões para a Região');
        dbms_output.put_line('Volume    | Qtd. Viagens   | Distância  |  Custo Transp');
        dbms_output.put_line(prev.qtdneg || ' | ' || prev.qtdviagens || ' | ' || prev.distancia ||
                             ' | ' || prev.custotransp);
      
      exception
        when zero_divide then
          prev.qtdviagens  := 0;
          prev.distancia   := 0;
          prev.custotransp := 0;
      end;
    
      tot.qtdviagens  := tot.qtdviagens + prev.qtdviagens;
      tot.distancia   := tot.distancia + prev.distancia;
      tot.custotransp := tot.custotransp + prev.custotransp;
    
      /* 
      se o percentual de ocupação for por fora
      prev.PercOcup := round(reg.med_peso / (peso_veiculo * reg.qtd_entregas),2);
      soma.PercOcup := soma.PercOcup + prev.PercOcup;
      */
    
      v_detailcat := v_detailcat || chr(13) || '<tr>
					<td>' || reg.nomeger || '</td>
					<td align="right">' || ad_get.formatanumero(reg.med_peso) ||
                     '</td>
					<td align="right">' || reg.med_km || '</td>
					<td align="right">' || reg.med_vlrkm || '</td>
					<td align="right">' || reg.med_ocupacao || '</td>
					<td align="right">' || reg.qtd_entregas || '</td>
			</tr>';
    
    end loop reg;
  
    dbms_output.put_line('Total de Viagens - Distancia total - Custo Total');
    dbms_output.put_line(tot.qtdviagens || ' - ' || tot.distancia || ' - ' || tot.custotransp);
  
    if qtd_regioes = 0 then
      return;
    end if;
  
    v_detailcat := v_detailcat || chr(13) || '</table><br>';
    -- tot.percOcup := round(soma.percOcup / qtd_regioes,2);
    tot.percocup := round(nvl(soma.percocup, 0) / nvl(soma.qtdviagens, 1), cdcm);
  
    tot.custofrete := round(fc_divide(tot.custotransp, (peso_prev_cat / 1000)), cdcm);
  
    v_memoriacalc := v_memoriacalc || chr(13) || v_detailcat;
  
    v_memoriacalc := v_memoriacalc || chr(13) || '%Ocup Final: ' || tot.percocup || '<br> R$/KM: ' ||
                     round(fc_divide(tot.custotransp, tot.distancia), cdcm) || '<br> Km Total: ' ||
                     ad_get.formatanumero(tot.distancia) || '<br> Custo Transp.: ' ||
                     ad_get.formatanumero(tot.custotransp) || '<br> Custo Frete/T: ' ||
                     ad_get.formatanumero(tot.custofrete);
    v_memoriacalc := v_memoriacalc || chr(13) || '<br>
		</body>
		</html>';
  
    <<insere_memo>>
    begin
      insert into ad_tsfmcmtl
        (dtref, codcat, qtd_prev_comercial, perc_vol_cat_medio, capacid_media_cat, perc_ocup_medio,
         total_km_medio, valor_km_media, qtd_prev_ref, capacid_real_ocup, nro_viagens, total_km_prev,
         custototal, custofrete, memocalc)
      values
        (p_dtref, p_codcat, peso_real_total, perc_real_vol, peso_veiculo, tot.percocup,
         round(fc_divide(soma.distancia, soma.qtdviagens), cdcm),
         round(fc_divide(tot.custotransp, tot.distancia), cdcm), peso_prev_cat,
         round(tot.qtdviagens * peso_veiculo, cdcm), tot.qtdviagens, tot.distancia, tot.custotransp,
         tot.custofrete, v_memoriacalc);
    
    exception
      when dup_val_on_index then
        delete from ad_tsfmcmtl
         where dtref = p_dtref
           and codcat = p_codcat;
        commit;
        goto insere_memo;
    end;
  
  exception
    when error then
      rollback;
    when others then
      rollback;
      p_errmsg := sqlerrm;
      p_errmsg := p_errmsg || chr(13) || dbms_utility.format_error_backtrace;
  end calcula_valores_metas_reg;

  function basefretefrango(p_codcat number, p_dataini date, p_datafin date)
    return table_rec_fretefrango
    pipelined is
    v_row      type_rec_fretefrango;
    v_aux_peso float;
  begin
    for c_ord in (with vendas_subprodutos as
                     (select c1.codemp, c1.ordemcarga
                       from tgfcab c1
                       join tgfite i1
                         on c1.nunota = i1.nunota
                       join tgfpro p
                         on i1.codprod = p.codprod
                       join tgford o1
                         on c1.codemp = o1.codemp
                        and c1.ordemcarga = o1.ordemcarga
                      where p.codgrupoprod in (62010000, 81040000)
                        and c1.statusnota = 'L'
                        and c1.tipmov = 'V'
                        and c1.ordemcarga > 0
                        and c1.vlrfrete > 0
                        and o1.dtinic >= p_dataini
                        and o1.dtinic <= last_day(p_datafin)),
                    sum_oc_total as
                     (select /*+ materialize */
                      last_day(add_months(o.dtinic, -1)) + 1 dtref, ger.codvend as codger,
                      ger.apelido nomeger, c.codemp, c.ordemcarga, t.categoria, t.codcatpai codcat,
                      round(sum(c.vlrfrete), cdcm) vlrfrete,
                      count(distinct c.ordemcarga) qtdordenscarga,
                      round(avg(v.pesomax), cdcm) pesomediocat,
                      round(count(distinct c.ordemcarga) * avg(v.pesomax), cdcm) capacidade,
                      round(sum(nvl(c.ad_km, 0)), cdcm) kmtotal, round(sum(c.peso), cdcm) pesototal,
                      round(snk_dividir(sum(c.vlrfrete), sum(c.ad_km)), cdcm) vlrkm,
                      round((snk_dividir(sum(c.peso),
                                          (count(distinct c.ordemcarga) * avg(v.pesomax))) * 100),
                             cdcm) perc_ocupacao, count(distinct c.codparc) qtdentregas
                       from tgfcab c
                       join tgford o
                         on c.codemp = o.codemp
                        and c.ordemcarga = o.ordemcarga
                       join tgfvei v
                         on c.codveiculo = v.codveiculo
                       join tgfven ven
                         on ven.codvend = c.codvend
                       join tgfven ger
                         on ven.codger = ger.codvend
                       left join ad_tsfcat t
                         on v.ad_codcat = t.codcat
                      where c.statusnota = 'L'
                        and (c.tipmov = 'V' or ((c.codtipoper = 519 and c.tipmov = 'C') or
                            (c.codtipoper = 532 and c.tipmov = 'T')))
                        and c.ordemcarga > 0
                        and c.vlrfrete > 0
                        and not exists (select 1
                               from ad_centparamtop top
                              where top.codtipoper = c.codtipoper
                                and top.nupar = 21
                                and nvl(top.utilizacao, 'X') = 'PROIBIDO')
                        and o.dtinic >= p_dataini
                        and o.dtinic <= last_day(p_datafin)
                        and (t.codcatpai = p_codcat or nvl(p_codcat, 0) = 0)
                        and not exists (select 1
                               from vendas_subprodutos vsp
                              where c.codemp = vsp.codemp
                                and c.ordemcarga = vsp.ordemcarga)
                      group by last_day(add_months(o.dtinic, -1)) + 1, c.codemp, c.ordemcarga,
                               ger.codvend, ger.apelido, t.categoria, t.codcatpai),
                    total_oc as
                     (select /*+ materialize*/
                      codemp, ordemcarga, count(ordemcarga) count_orcarga, sum(kmtotal) totalkm,
                      sum(perc_ocupacao) as totalpercocup
                       from sum_oc_total
                      group by codemp, ordemcarga)
                    
                    /* Importante não alterar os valores nulos para zero, pois prejudica as médias */
                    select dtref, codger, nomeger, codemp, ordemcarga, qtdentregas, codcat, categoria,
                           pesomediocat, capacidade, totalfrete, totalkm, totalpeso,
                           round(snk_dividir(totalfrete, totalkm), 4) as totalvlrkm,
                           case
                             when totalkm is null then
                              null
                             else
                              qtdordenscarga
                           end as qtdordenscarga,
                           case
                             when totalkm is null then
                              null
                             else
                              totalpercocup
                           end as totalpercocup
                      from (select t1.dtref, t1.codger, t1.nomeger, t1.codemp, t1.ordemcarga,
                                    sum(t1.qtdordenscarga) as qtdordenscarga,
                                    sum(t1.qtdentregas) qtdentregas, t1.codcat, t1.categoria,
                                    t1.pesomediocat, t1.capacidade * sum(t1.qtdordenscarga) capacidade,
                                    --round(sum(t1.vlrfrete), 2) totalfrete,
                                    (case
                                      when sum(t2.count_orcarga) > 1 then
                                       ad_pkg_metransp.get_vlrfrete_orcarga_dupl(t1.codemp,
                                                                                 t1.ordemcarga,
                                                                                 sum(t1.vlrfrete))
                                      else
                                       round(sum(t1.vlrfrete), cdcm)
                                    end) as totalfrete,
                                    (case
                                      when sum(t2.count_orcarga) > 1 then
                                       ad_pkg_metransp.get_km_orcarga_dupl(t1.codemp,
                                                                           t1.ordemcarga,
                                                                           sum(t1.pesototal))
                                      else
                                       round(sum(t2.totalkm), cdcm)
                                    end) as totalkm, round(sum(t1.pesototal), cdcm) totalpeso,
                                    --round(snk_dividir(sum(t1.vlrfrete), sum(t2.totalkm)), 2) totalvlrkm,
                                    round(sum(t2.totalpercocup), cdcm) as totalpercocup
                               from sum_oc_total t1, total_oc t2
                              where t1.codemp = t2.codemp
                                and t1.ordemcarga = t2.ordemcarga
                              group by t1.dtref, t1.codger, t1.nomeger, t1.codemp, t1.ordemcarga,
                                       t1.codcat, t1.categoria, t1.pesomediocat, t1.capacidade)
                    
                  )
    loop
    
      if c_ord.totalkm is null then
        v_aux_peso := c_ord.totalpeso;
      end if;
    
      v_row.dtref        := c_ord.dtref;
      v_row.codger       := c_ord.codger;
      v_row.nomeger      := c_ord.nomeger;
      v_row.codemp       := c_ord.codemp;
      v_row.ordemcarga   := c_ord.ordemcarga;
      v_row.qtdentregas  := c_ord.qtdentregas;
      v_row.codcat       := c_ord.codcat;
      v_row.categoria    := c_ord.categoria;
      v_row.pesomediocat := c_ord.pesomediocat;
      v_row.capacidade   := c_ord.capacidade;
      v_row.totalfrete := case
                            when c_ord.totalkm is null then
                             null
                            else
                             c_ord.totalfrete
                          --(select sum(vlrfrete) from tgfcab c where codemp = c_ord.codemp and ordemcarga = c_ord.ordemcarga))
                          end;
      v_row.totalkm      := c_ord.totalkm;
      v_row.totalpeso    := c_ord.totalpeso;
      /*v_row.totalpeso := Case
        When c_ord.totalkm Is Null Then
         Null
        Else
         c_ord.totalpeso  + v_aux_peso
      End;*/
      v_row.qtdordenscarga := c_ord.qtdordenscarga;
      v_row.totalvlrkm := case
                            when c_ord.totalkm is null then
                             null
                            else
                             c_ord.totalvlrkm
                          --Round(ad_set.divide_valores(c_ord.totalfrete, c_ord.totalkm), 2)
                          end;
      v_row.totalpercocup  := c_ord.totalpercocup;
    
      pipe row(v_row);
    
    end loop;
  
  end basefretefrango;

end ad_pkg_metransp;
/
