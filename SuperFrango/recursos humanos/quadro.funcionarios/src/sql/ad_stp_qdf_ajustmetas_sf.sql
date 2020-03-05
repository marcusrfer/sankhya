create or replace procedure ad_stp_qdf_ajustmetas_sf
(
  p_codusu    number,
  p_idsessao  varchar2,
  p_qtdlinhas number,
  p_mensagem  out varchar2
) as
  p_codung varchar2(4000);
  p_codexe varchar2(4000);
  p_dtref  date;

  i     int;
  v_mes boolean;
  v_ano varchar2(1);

begin

  /*
    author: marcus.rangel 12/09/2019 17:59:42
    process: quadro de funcionários - rh
    objetivo: popular a previsão de metas
  */

  p_codung := act_txt_param(p_idsessao, 'CODUNG');
  p_codexe := act_txt_param(p_idsessao, 'CODEXE');
  p_dtref  := act_dta_param(p_idsessao, 'DTREF');

  --v_codhqf := act_int_field(p_idsessao, 1, 'CODHQF');

  -- perguntar se irá atualizar o mes ou o ano
  v_ano := act_escolher_simnao(p_titulo    => 'Atualização de previsão de metas',
                               p_texto     => 'Confirma a atulização dos valores para o ano todo?',
                               p_chave     => p_idsessao,
                               p_sequencia => 1);

  --- se não, pergunta se atualiza para o mes                            
  if v_ano = 'N' then
    v_mes := act_confirmar(p_titulo    => 'Atualização de previsão de metas',
                           p_texto     => 'Confirma a atulização dos valores somente para a referência ' ||
                                          to_char(p_dtref, 'dd/mm/yyyy') || ' ?',
                           p_chave     => p_idsessao,
                           p_sequencia => 2);
  
    if not v_mes then
      return;
    end if;
  
  end if;

  -- salva posição atual 
  begin
    insert into ad_tsfhqf_log
      select sysdate, h.* from ad_tsfhqf h;
  exception
    when others then
      p_mensagem := 'Erro ao salvar posição atual da estrutura. ' || sqlerrm;
      return;
  end;

  -- percorre a lotações 
  declare
    type tab_meta is table of ad_tmimetper%rowtype;
    t     tab_meta := tab_meta();
    l_mes date;
    x     int;
  begin
  
    for l in (select *
                from ad_tsfhqf
               where ativo = 'S'
                 and analitico = 'S'
               order by codhqf)
    loop
    
      -- verifica / insere cabeçalho da previsão METCAB
      merge into ad_tmimetcab c
      using (select l.numet from dual) c2
      on (c.codung = p_codung and c.codexe = p_codexe and c.numet = l.numet)
      when matched then
        update
           set c.codusu  = p_codusu,
               c.dhalter = sysdate
      when not matched then
        insert values (p_codung, l.numet, p_codexe, p_codusu, sysdate);
    
      -- insere os valores por periodo
      --- se o mes
      if (v_mes) then
        ---- insere apenas o mes 
      
        t.extend;
        x := t.last;
      
        t(x).codung := p_codung;
        t(x).codexe := p_codexe;
        t(x).numet := l.numet;
        t(x).perini := p_dtref;
        t(x).vlrprev := l.qtdfunc;
        t(x).observacao := 'Atualizado pela rotina do quadro de funcionários';
        t(x).atualizar := 'N';
        --- se o ano    
      else
        ---- cria o laço, de quanto meses falta 
        for i in 1 .. 13 - extract(month from sysdate)
        loop
          l_mes := add_months(add_months(trunc(sysdate, 'fmmm'), -1), i);
          t.extend;
          x := t.last;
        
          t(x).codung := p_codung;
          t(x).codexe := p_codexe;
          t(x).numet := l.numet;
          t(x).perini := l_mes;
          t(x).vlrprev := l.qtdfunc;
          t(x).observacao := 'Atualizado pela rotina do quadro de funcionários';
          t(x).atualizar := 'N';
        end loop;
      
      end if;
    
      --- atualizar o usuário e a data da atualização
      begin
        update ad_tsfhqf h
           set h.dhupdmeta = sysdate,
               h.codusuupd = p_codusu
         where h.codhqf = l.codhqf;
      exception
        when others then
          p_mensagem := 'Erro ao atualizar a data e o usuário no lançamento de origem.';
          return;
      end;
    
    end loop;
  
    -- percorre o laço com as previsões se mês/ano
    begin
      forall z in t.first .. t.last
        merge into ad_tmimetper p
        using (select t(z).numet numet,t(z).perini perini,t(z).vlrprev vlrprev from dual) t
        on (p.codung = p_codung and p.numet = t.numet and p.codexe = p_codexe and p.perini = t.perini and nvl(p.vlr_real, 0) = 0)
        when matched then
          update set p.vlrprev = t.vlrprev
        when not matched then
          insert values t (z);
    exception
      when others then
        p_mensagem := 'Erro ao atualizar as previsões de metas. ' || sqlerrm;
        return;
    end;
  end;

  p_mensagem := 'Previsões de metas atualizadas com sucesso!!!';

end;
/
