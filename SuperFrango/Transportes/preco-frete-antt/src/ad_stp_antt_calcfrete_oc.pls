create or replace procedure ad_stp_antt_calcfrete_oc(p_codemp     int,
                                                     p_ordemcarga int,
                                                     preco_final  out float,
                                                     p_memcalc    out varchar2) is
  v_descrtabela   varchar2(100);
  perc_ocup_ida   float;
  perc_ocup_volta float;
  v_codtabela     int;
  v_vlrkm         float;
  v_vlrserv       float;
  v_vlrida        float;
  v_vlrvolta      float;
  valor           float := 0;
  valor_total     float := 0;

begin
  -- Test statements here

  for l in (select o.codemp, o.ordemcarga, v.codparc, o.temtransbordo, o.dtinic, o.codveiculo,
                   nvl(v.ad_qtdeixos, cat.qtdeixos) qtdeixos, t.codtiptransp, t.descrtiptransp,
                   t.codtipcarga, g.descrtipcarga, cat.codcat, cat.categoria, r.codregfre regiao,
                   r.descrregfre, round(nvl(o.ad_kmrota, o.kmfin), 2) km, o.vlrfrete
              from tgford o
              join tgfvei v
                on v.codveiculo = o.codveiculo
              join ad_tsfcat cat
                on cat.codcat = v.ad_codcat
              join ad_tsfctt t
                on t.codtiptransp = v.ad_codtiptransp
              join ad_tsfctg g
                on g.codtipcarga = t.codtipcarga
              left join ad_tsfrfc r
                on r.codregfre =
                   to_number(substr(ad_pkg_fre.get_regioes_oc(o.codemp, o.ordemcarga), 1, 6))
             where 1 = 1
               and nvl(o.ad_kmrota, o.kmfin) > 0
               and nvl(o.vlrfrete, 0) > 0
               and nvl(t.antt, 'N') = 'S'
               and o.codemp = p_codemp
               and o.ordemcarga = p_ordemcarga)
  loop
    --dbms_output.put_line(l.codemp || '  - ' || l.ordemcarga);
    p_memcalc := 'Cód. Empresa: ' || l.codemp || '  - OC: ' || l.ordemcarga || chr(13);
    p_memcalc := p_memcalc || 'Tipo Transporte: ' || l.descrtiptransp || chr(13);
    p_memcalc := p_memcalc || 'Categoria: ' || l.categoria || chr(13);
    p_memcalc := p_memcalc || 'Região: ' || l.regiao || '  - ' || l.descrregfre || chr(13);
    p_memcalc := p_memcalc || 'Distância: ' || l.km || chr(13);
    p_memcalc := p_memcalc || 'vlr frete: ' || l.vlrfrete || chr(13);
  
    ad_stp_antt_get_valores(p_codtipcarga => l.codtipcarga, p_qtdeixos => l.qtdeixos,
                            p_codparc => l.codparc, p_codtabela => v_codtabela, p_vlrkm => v_vlrkm,
                            p_vlrserv => v_vlrserv);
  
    -- obtem tipo da tabela de preço
    begin
      select ad_get.opcoescampo(t.tipofrete, 'TIPOFRETE', 'AD_TSFTFO')
        into v_descrtabela
        from ad_tsftfo t
       where t.codtabela = v_codtabela;
    exception
      when no_data_found then
        p_memcalc := 'Erro! Tabela não encontrada!';
        return;
      when others then
        p_memcalc := 'Erro! ' || sqlerrm;
        return;
    end;
  
    p_memcalc := p_memcalc || '----------Tabela ANTT------------' || chr(13);
    p_memcalc := p_memcalc || 'Tabela: ' || v_codtabela || '  - ' || v_descrtabela || chr(13);
    p_memcalc := p_memcalc || 'Tipo de Carga: ' || l.descrtipcarga || chr(13);
    p_memcalc := p_memcalc || 'Eixos: ' || l.qtdeixos || chr(13);
    p_memcalc := p_memcalc || 'Vlr KM: ' || v_vlrkm || chr(13);
    p_memcalc := p_memcalc || 'Vlr Descarca: ' || v_vlrserv || chr(13);
    p_memcalc := p_memcalc || 'Vlr. Rota: ' || fmt.valor_moeda((l.km * v_vlrkm)) || chr(13);
    p_memcalc := p_memcalc || 'Vlr. Mínimo: ' || fmt.valor_moeda((l.km * v_vlrkm) + v_vlrserv) ||
                 chr(13);
  
    p_memcalc := p_memcalc || '----------Viabilidade------------' || chr(13);
    for reg in (select v.distanciakm, dv.descrdespvei,
                       case
                         when d.vlrdespfixa = 0 then
                          d.vlrdespvar
                         else
                          d.vlrdespfixa
                       end as valor
                  from ad_tsfvvt v
                  join ad_tsfdvt d
                    on d.numvvt = v.numvvt
                  join ad_tsfcdv dv
                    on dv.coddespvei = d.coddespvei
                   and nvl(dv.antt, 'N') = 'S'
                 where v.codcat = l.codcat
                   and v.codregfre = l.regiao
                   and v.dtref = (select max(v2.dtref)
                                    from ad_tsfvvt v2
                                   where v2.codcat = v.codcat
                                     and v2.codregfre = v.codregfre
                                     and v2.dtref < trunc(sysdate)))
    loop
      if lower(trim(reg.descrdespvei)) = 'imposto' then
        valor := reg.valor * 0.10 / reg.distanciakm;
      else
        valor := reg.valor / reg.distanciakm;
      end if;
    
      valor := round(valor, 4);
    
      p_memcalc := p_memcalc || 'Vlr ' || reg.descrdespvei || ': ' || valor || chr(13);
    
      valor_total := round(valor_total + valor, 4);
    
    end loop reg;
  
    p_memcalc := p_memcalc || 'Vlr.Tot. Viabilidade: ' || valor_total || chr(13);
  
    v_vlrkm := v_vlrkm + valor_total;
  
    p_memcalc := p_memcalc || 'vlr km final: ' || v_vlrkm || chr(13);
  
    -- obtem os percentuais de ida e volta
    begin
      select *
        into perc_ocup_ida, perc_ocup_volta
        from (select ida, volta
                 from (select tipo, percentual
                          from ad_tsfofo o
                         where o.codtabela = v_codtabela
                           and o.codtiptransp = l.codtiptransp)
               pivot(sum(percentual)
                  for tipo in('I' as ida, 'V' as volta)));
    
    exception
      when others then
        raise;
    end;
    p_memcalc := p_memcalc || '--------- Total --------' || chr(13);
  
    -- ida
    v_vlrida  := l.km * (perc_ocup_ida / 100) * v_vlrkm;
    p_memcalc := p_memcalc || 'Vlr ida (' || perc_ocup_ida || '%) : ' || fmt.valor_moeda(v_vlrida) ||
                 chr(13);
    -- volta
    v_vlrvolta := l.km * (perc_ocup_volta / 100) * (v_vlrkm * 0.92);
    p_memcalc  := p_memcalc || 'Vlr. volta (92% de ' || perc_ocup_volta || '%): ' ||
                  fmt.valor_moeda(v_vlrvolta) || chr(13);
  
    preco_final := v_vlrida + v_vlrvolta;
    p_memcalc   := p_memcalc || 'Soma ida e volta: ' || fmt.valor_moeda(preco_final) || chr(13);
  
    preco_final := preco_final + v_vlrserv;
    p_memcalc   := p_memcalc || 'vlr. final rota: ' || fmt.valor_moeda(preco_final);
  
  end loop;

end;
/
