create or replace procedure ad_stp_cab_gerarnotatransf_sf(p_codusu    pls_integer,
                                                          p_idsessao  varchar2,
                                                          p_qtdlinhas pls_integer,
                                                          p_mensagem  out nocopy varchar2) as
  notas ad_type_of_number := ad_type_of_number();

  top tgftop%rowtype;
  cab tgfcab%rowtype;
  ite tgfite%rowtype;

  permite_parc_dif boolean := true;
  permite_prod_dif boolean := false;

  v_count int;

begin

  /*
  * Autor: M. Rangel
  * Processo: Armazém
  * Objetivo: Gerar notas de transferências a partir de outras notas
  */
  --stp_set_atualizando('S');

  cab.codempnegoc  := act_txt_param(p_idsessao, 'CODEMPNEGOC');
  cab.codparc      := act_txt_param(p_idsessao, 'CODPARC');
  cab.codtipoper   := act_txt_param(p_idsessao, 'CODTIPOPER');
  cab.codnat       := act_txt_param(p_idsessao, 'CODNAT');
  cab.codcencus    := act_txt_param(p_idsessao, 'CODCENCUS');
  cab.codproj      := act_txt_param(p_idsessao, 'CODPROJ');
  cab.serienota    := act_int_param(p_idsessao, 'SERIENOTA');
  ite.qtdneg       := act_dec_param(p_idsessao, 'QTDNEG');
  ite.codlocalterc := act_int_param(p_idsessao, 'CODLOCALDEST');

  if ite.qtdneg is null then
    p_mensagem := 'não pegou a quantidade';
    return;
  end if;

  if cab.codtipoper in (88, 604, 129) then
    permite_parc_dif := false;
  end if;

  /*
  cab.codempnegoc := '3';
  cab.codparc     := '15589';
  cab.codtipoper  := '217';
  cab.codnat      := '2010000';
  cab.codcencus   := '20200100';
  cab.codproj     := '0';
  cab.serienota   := '2';*/
  cab.codvend := 103;

  select *
    into top
    from tgftop
   where codtipoper = cab.codtipoper
     and dhalter = ad_get.maxdhtipoper(cab.codtipoper);

  cab.tipmov    := top.tipmov;
  cab.dhtipoper := top.dhalter;

  /*  if p_qtdlinhas = 1 then
    p_mensagem := 'Selecione mais de uma nota!';
    return;
  end if;*/

  for i in 1 .. p_qtdlinhas
  loop
    notas.extend;
    notas(notas.last) := act_int_field(p_idsessao, i, 'NUNOTA');
  
    -- valida se notas confirmadas
    for conf in (select statusnota
                   from tgfcab
                  where nunota = notas(notas.last)
                    and statusnota != 'L')
    loop
      if top.adiaratualest = 'S' then
        p_mensagem := 'A nota ' || notas(notas.last) || ' não está confirmada!';
        return;
      end if;
    end loop;
  
    -- valida itens pendentes  
    for pend in (select 1
                   from tgfite
                  where nunota = notas(notas.last)
                    and sequencia = 1
                    and qtdneg - qtdentregue > 0)
    loop
      ite.pendente := 'S';
    end loop;
  
    if ite.pendente is null then
      p_mensagem := 'Não existem produtos pendentes nas notas selecionadas!';
      return;
    end if;
  
  end loop;

  -- valida parceiros diferentes
  begin
    v_count := 0;
    select count(distinct codparc)
      into v_count
      from tgfcab
     where nunota in (select column_value
                        from table(cast(notas as ad_type_of_number)));
  
    if v_count > 1 and permite_parc_dif = false then
      p_mensagem := 'Não é permitido utilizar Notas com parceiros diferentes!';
      return;
    end if;
  
  end;

  -- valida produtos diferentes
  begin
    v_count := 0;
    select count(distinct codprod)
      into v_count
      from tgfite
     where nunota in (select column_value
                        from table(cast(notas as ad_type_of_number)));
  
    if v_count > 1 and not permite_prod_dif then
      p_mensagem := 'Não é permitido utilizar Notas com produtos diferentes! ';
      return;
    end if;
  
  end;

  -- valida quantidade pendente
  for qtd in (
              
              select codprod, sum(qtdneg - qtdentregue) qtdpendente
                from tgfite
               where nunota in (select column_value
                                  from table(cast(notas as ad_type_of_number)))
               group by codprod
              
              )
  loop
    if qtd.qtdpendente < ite.qtdneg then
      p_mensagem := 'Quantidade pendente das notas são insuficientes!' || ' / ' || ite.qtdneg || ' / ' ||
                    qtd.qtdpendente;
      return;
    end if;
  end loop;

  -- insere o cabeçalho
  begin
  
    begin
      select codempnegoc, tipmov
        into cab.codemp, cab.tipmov
        from (select case
                         when nvl(codempnegoc, 0) > 0 then
                          codempnegoc
                         else
                          codemp
                       end codempnegoc, tipmov
                 from tgfcab
                where nunota in (select column_value
                                   from table(cast(notas as ad_type_of_number))))
       group by codempnegoc, tipmov;
    exception
      when too_many_rows then
        raise_application_error(-20105,
                                'Erro! Empresas ou Tipos de Movimentação diferentes ' ||
                                 'nas notas de origem selecionadas.');
      when others then
        raise;
    end;
  
    -- nunota
    stp_keygen_tgfnum(p_arquivo => 'TGFCAB', p_codemp => 1, p_tabela => 'TGFCAB', p_campo => 'NUNOTA', p_dsync => 0,
                      p_ultcod => cab.nunota);
  
    savepoint before_insert_cab;
    begin
      insert into tgfcab
        (nunota, codemp, codempnegoc, codparc, codparcdest, codtipoper, dhtipoper, tipmov, codnat, codcencus, codproj,
         serienota, codvend, dtneg, dtfatur, dtentsai, dtmov, vlrnota, numnota, codtipvenda, dhtipvenda, tipfrete,
         cif_fob, qtdvol, pendente, statusnota, rateado, codusu, ad_tela, dtalter)
      values
        (cab.nunota, cab.codemp, cab.codempnegoc, cab.codparc, cab.codparc, cab.codtipoper, top.dhalter, top.tipmov,
         cab.codnat, cab.codcencus, cab.codproj, cab.serienota, cab.codvend, trunc(sysdate), trunc(sysdate),
         trunc(sysdate), sysdate, 0, 0, 0, ad_get.maxdhtipvenda(0), 'N', 'F', 0, 'S', 'A', 'N', p_codusu,
         'AcaoGeraNotaTransf', sysdate);
    exception
      when others then
        rollback to before_insert_cab;
        raise_application_error(-20105, 'Erro! insert da cab - ' || sqlerrm);
    end;
  
    dbms_output.put_line(cab.nunota);
  
  end;

  -- insere os itens
  begin
  
    -- define o tipo de atualização do estoque da sequencia 1 baseada na top
    ite.atualestoque := case
                          when top.atualest = 'B' then
                           -1
                          when top.atualest = 'E' then
                           1
                          when top.atualest = 'N' then
                           0
                        end;
  
    -- define a cfop 
    --- verifica se dentro ou fora da UF
    if ad_get.ufparcemp(cab.codparc, 'P') = ad_get.ufparcemp(cab.codemp, 'E') then
      if ite.atualestoque = -1 then
        ite.codcfo := top.codcfo_saida;
      else
        ite.codcfo := top.codcfo_entrada;
      end if;
    else
      if ite.atualestoque = -1 then
        ite.codcfo := top.codcfo_saida_fora;
      else
        ite.codcfo := top.codcfo_entrada_fora;
      end if;
    end if;
  
    if ite.codcfo is null then
      ite.codcfo := 0;
    end if;
  
    for l in (select sequencia, atualestoque, codprod, codlocalorig, codvol, usoprod, controle, sum(qtdneg) qtdneg,
                     sum(vlrtot) vlrtot
                from tgfite i
               where 1 = 1
                 and qtdneg - qtdentregue > 0
                 and i.nunota in (select column_value
                                    from table(cast(notas as ad_type_of_number)))
               group by sequencia, atualestoque, codprod, codlocalorig, codvol, usoprod, controle
               order by sequencia)
    loop
      begin
      
        ite.sequencia := nvl(ite.sequencia, 0) + 1;
        ite.vlrunit   := round(l.vlrtot / l.qtdneg, 6);
      
        if l.sequencia < 0 then
        
          insert into tgfite
            (nunota, sequencia, codemp, codprod, qtdneg, vlrunit, vlrtot, atualestoque, codvol, usoprod, controle,
             codlocalorig, codcfo, codtrib, cstipi, pendente)
          values
            (cab.nunota, ite.sequencia, cab.codemp, l.codprod, ite.qtdneg, ite.vlrunit, ite.vlrunit * ite.qtdneg,
             ite.atualestoque, l.codvol, l.usoprod, l.controle, l.codlocalorig, ite.codcfo, 41, -1, ite.pendente);
        else
          if cab.tipmov = 'C' then
            insert into tgfite
              (nunota, sequencia, codemp, codprod, qtdneg, vlrunit, vlrtot, atualestoque, codvol, usoprod, controle,
               codlocalorig, codcfo, codtrib, cstipi, pendente)
            values
              (cab.nunota, l.sequencia, cab.codemp, l.codprod, ite.qtdneg, ite.vlrunit, ite.vlrunit * ite.qtdneg,
               ite.atualestoque, l.codvol, l.usoprod, l.controle, l.codlocalorig, ite.codcfo, 41, -1, ite.pendente);
          end if;
        
          update tgfite
             set codemp       = cab.codempnegoc,
                 codlocalorig = ite.codlocalterc, --l.codlocalorig,
                 pendente     = 'S',
                 codusu       = p_codusu,
                 dtalter      = sysdate
           where tgfite.nunota = cab.nunota
             and tgfite.sequencia = l.sequencia * -1;
        end if;
      
      exception
        when others then
          rollback to before_insert_cab;
          raise;
          null;
      end;
    end loop;
  
  end;

  --- cria o relacionamento com a VAR
  declare
    qtddif         float := 0;
    v_qtdneg       float;
    realiza_insert boolean := false;
  begin
    qtddif := ite.qtdneg;
    for v in (select c.nunota, c.numnota, i.sequencia, i.codprod, sum(i.qtdneg - i.qtdentregue) qtdneg
                from tgfcab c
                join tgfite i
                  on i.nunota = c.nunota
                 and i.sequencia > 0
               where c.nunota in (select column_value
                                    from table(cast(notas as ad_type_of_number)))
               group by c.nunota, c.numnota, i.sequencia, i.codprod)
    loop
    
      begin
      
        if cab.observacao is null then
          cab.observacao := v.numnota;
        else
          cab.observacao := cab.observacao || ', ' || v.numnota;
        end if;
      
        if v.qtdneg < qtddif then
          qtddif         := ite.qtdneg - v.qtdneg;
          v_qtdneg       := v.qtdneg;
          realiza_insert := true;
        else
          if qtddif > 0 then
            v_qtdneg       := qtddif;
            realiza_insert := true;
          else
            realiza_insert := false;
            null;
          end if;
          qtddif := 0;
        end if;
      
        if realiza_insert then
          insert into tgfvar
            (nunota, sequencia, nunotaorig, sequenciaorig, qtdatendida)
          values
            (cab.nunota, 1, v.nunota, v.sequencia, v_qtdneg);
        end if;
        v_qtdneg := 0;
      exception
        when others then
          raise;
      end;
    end loop;
  end;

  -- atualiza o cabeçalho
  begin
    for ite in (select sum(vlrtot) vlrnota, sum(qtdneg) qtdvol
                  from tgfite
                 where nunota = cab.nunota
                   and sequencia > 0)
    loop
      begin
        update tgfcab c
           set vlrnota          = round(ite.vlrnota, 2),
               c.totalcustoprod = round(ite.vlrnota, 2),
               qtdvol           = ite.qtdvol,
               peso             = ite.qtdvol,
               pesobruto        = ite.qtdvol,
               codmoddoc        = 1,
               observacao       = 'Ref. Notas: ' || cab.observacao || ' (' || cab.codparc || ' - ' ||
                                  ad_get.nome_parceiro(cab.codparc, 'razao') || ')'
         where nunota = cab.nunota;
      exception
        when others then
          rollback to before_insert_cab;
          p_mensagem := 'Erro ao atualizar o cabeçalho da nota' || ' - ' || sqlerrm;
          return;
      end;
    end loop;
  end;

  p_mensagem := q'[Nota gerada com sucesso!
    <a href="javascript:workspace.reloadApp('br.com.sankhya.com.mov.CentralNotas', 
    {'NUNOTA': p_nunota});document.getElementsByClassName('btn-popup-ok')[0].click();">
    <b>Clique AQUI</b></a>para acessar o registro]';

  p_mensagem := replace(p_mensagem, 'p_nunota', cab.nunota);

  --stp_set_atualizando('N');
end;
/
