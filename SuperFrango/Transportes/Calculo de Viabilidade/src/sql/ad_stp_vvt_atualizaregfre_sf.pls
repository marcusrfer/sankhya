create or replace procedure ad_stp_vvt_atualizaregfre_sf(p_codusu    number,
                                                         p_idsessao  varchar2,
                                                         p_qtdlinhas number,
                                                         p_mensagem  out nocopy varchar2) as
  vvt          ad_tsfvvt%rowtype;
  v_nurfr      number;
  v_numrfi     number;
  v_valorsaida float;
  v_valorkm    float;
  v_count      int default 0;
begin

  /*
  * Autor: Marcus Rangel
  * Processo: Viabilidade de Veículos de Transporte
  * Objetivo: Atualizar os valores na tela de região de frete
  */

  for i in 1 .. p_qtdlinhas
  loop
    vvt.numvvt := act_int_field(p_idsessao, i, 'NUMVVT');
  
    -- popula record
    select * into vvt from ad_tsfvvt where numvvt = vvt.numvvt;
  
    -- verifica se ativo
    if nvl(vvt.ativo, 'N') = 'N' then
      p_mensagem := 'Configuração não está ativa, não pode ser utilizada.';
      return;
    end if;
  
    -- popula variáveis de valores
    -- saida + Km
    if vvt.formaprecif = 'S' then
    
      v_valorsaida := case
                        when vvt.vlrsaida = 0 then
                         vvt.vlrsaidasug
                        else
                         vvt.vlrsaida
                      end;
    
      v_valorkm := case
                     when vvt.vlrkmsaida = 0 then
                      vvt.vlrkmsaidasug
                     else
                      vvt.vlrkmsaida
                   end;
    
    elsif vvt.formaprecif = 'K' then
      -- Km
      v_valorsaida := 0;
    
      v_valorkm := case
                     when vvt.custokm = 0 then
                      vvt.custosugerido
                     else
                      vvt.custokm
                   end;
    
    elsif vvt.formaprecif = 'V' then
      -- Saida apenas
      v_valorsaida := case
                        when vvt.vlrsaida = 0 then
                         vvt.vlrsaidasug
                        else
                         vvt.vlrsaida
                      end;
    
      v_valorkm := 0;
    
    end if;
  
    -- verifica se existe a categoria na região
    begin
      select count(*)
        into v_count
        from ad_tsfrfr r
       where r.codregfre = vvt.codregfre
         and r.codcat = vvt.codcat
         and r.dtvigor = vvt.dtref;
    
      -- se existir, atualiza os valores e faz o link
      if v_count > 0 then
      
        for reg in (select rowid, r.nurfr
                      from ad_tsfrfr r
                     where r.codregfre = vvt.codregfre
                       and r.codcat = vvt.codcat
                       and r.dtvigor = trunc(vvt.dhvigor))
        loop
          begin
            update ad_tsfrfr r
               set r.vlrsaida = v_valorsaida, numvvt = vvt.numvvt
             where rowid = reg.rowid;
          exception
            when others then
              p_mensagem := 'Não foi possível atualizar o valor de saída na região ' ||
                            vvt.codregfre || ', categoria ' || vvt.codcat || ', na referência ' ||
                            vvt.dtref || chr(13) || sqlerrm;
              return;
          end;
        
          begin
          
            select max(i.numrfi) + 1 into v_numrfi from ad_tsfrfi i where nurfr = reg.nurfr;
          
            merge into ad_tsfrfi i
            using (select v_numrfi as numrfi, reg.nurfr as nurfr, vvt.codregfre as codregfre,
                          0 as inicioint, 4000 as finalint, v_valorkm as vlrkm, 'N' as vlrfixo,
                          vvt.numvvt as numvvt
                     from dual) d
            on (i.nurfr = d.nurfr and i.codregfre = d.codregfre)
            when matched then
              update set i.vlrkm = v_valorkm, numvvt = vvt.numvvt
            when not matched then
              insert
              values
                (d.numrfi, d.nurfr, d.codregfre, d.inicioint, d.finalint, d.vlrkm, d.vlrfixo,
                 d.numvvt);
          exception
            when others then
              p_mensagem := 'Não foi possível atualizar o valor na região ' || vvt.codregfre ||
                            ', categoria ' || vvt.codcat || ', na referência ' || vvt.dtref ||
                            chr(13) || sqlerrm;
              return;
          end;
        end loop;
      
      else
        -- se não existir, insere uma nova categoria
      
        -- insere categoria
        begin
          select nvl(max(nurfr), 0) + 1
            into v_nurfr
            from ad_tsfrfr
           where codregfre = vvt.codregfre;
        
          insert into ad_tsfrfr
            (nurfr, codregfre, vlrsaida, codcat, dtvigor, numvvt)
          values
            (v_nurfr, vvt.codregfre, v_valorsaida, vvt.codcat, to_date(vvt.dhvigor, 'DD/MM/RRRR'),
             vvt.numvvt);
        exception
          when others then
            p_mensagem := 'Não foi possível inserir a categoria ' || vvt.codcat ||
                          ' com referência ' || vvt.dtref || ' na região ' || vvt.codregfre ||
                          chr(13) || sqlerrm;
            return;
        end;
      
        -- insere faixa de valores
        begin
          select nvl(max(numrfi), 0) + 1
            into v_numrfi
            from ad_tsfrfi
           where nurfr = v_nurfr
             and codregfre = vvt.codregfre;
        
          insert into ad_tsfrfi
            (numrfi, nurfr, codregfre, inicioint, finalint, vlrkm, vlrfixo, numvvt)
          values
            (v_numrfi, v_nurfr, vvt.codregfre, 0, 4000, v_valorkm, 'S', vvt.numvvt);
        exception
          when others then
            p_mensagem := 'Não foi possível inserir a faixa de valor na categoria ' || vvt.codcat ||
                          ' com referência ' || vvt.dtref || ' na região ' || vvt.codregfre ||
                          chr(13) || sqlerrm;
            return;
        end;
      
      end if;
    end;
  
  end loop;

  p_mensagem := 'Valores atualizados com sucesso!!!';

end;
/
