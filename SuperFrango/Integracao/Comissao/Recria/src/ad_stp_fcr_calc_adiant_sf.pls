create or replace procedure ad_stp_fcr_calc_adiant_sf(p_codusu    number,
                                                      p_idsessao  varchar2,
                                                      p_qtdlinhas number,
                                                      p_mensagem  out varchar2) as

  p_dtvencini date;

  fcr ad_tsffcr%rowtype;
  i   int;
begin

  /**
  * Autor: M. rangel
  * Processo: Fechamento de Comissão - Integrado Recria
  * Objetivo: Popular a aba adiantamentos da tela de fechamento de comissão recria
  **/

  -- verifica linhas selecionadas
  if nvl(p_qtdlinhas, 0) > 1 then
    p_mensagem := 'Selecione apenas 1 lote!';
    return;
  end if;

  p_dtvencini := act_dta_param(p_idsessao, 'DTVENCINI');

  --- get dados do registro
  begin
    select *
      into fcr
      from ad_tsffcr
     where codcencus = act_int_field(p_idsessao, 1, 'CODCENCUS')
       and codparc = act_int_field(p_idsessao, 1, 'CODPARC')
       and numlote = act_int_field(p_idsessao, 1, 'NUMLOTE')
       and sexo = act_txt_field(p_idsessao, 1, 'SEXO');
  exception
    when others then
      p_mensagem := 'Erro ao buscar os dados do registro selecionado. ' ||
                    sqlerrm;
      return;
  end;

  -- valida preenchimento de campos importantes
  if nvl(fcr.codemp, 0) = 0 or fcr.dtaloj is null or nvl(fcr.qtdmeses, 0) = 0 or
     nvl(fcr.qtdaves, 0) = 0 or nvl(fcr.sexo, 'N') = 'N' then
    p_mensagem := 'As informações complementares sobre o lote, como <b>Empresa</b>, ' ||
                  '<b>Data de Alojamento, Sexo</b> e <b>Quantidade de meses</b> ' ||
                  'são necessárias para a geração das parcelas.';
    return;
  end if;

  -- valida status
  if fcr.status = 'F' then
    p_mensagem := 'Lote já finalizado!';
    return;
  end if;

  -- verifica adiantamentos gerados
  select count(nuacerto)
    into i
    from ad_tsffcradt
   where 1 = 1
     and codcencus = fcr.codcencus
     and codparc = fcr.codparc
     and numlote = fcr.numlote
     and sexo = fcr.sexo;

  -- Não possui adiantamentos
  if i = 0 then
  
    if p_dtvencini is null and fcr.status = 'P' then
      p_mensagem := 'Necessário informar o vencimento para o primeiro cálculo!';
      return;
    end if;
  
    --** método de calculo/recalculo
    ad_stp_fcr_recalcfechamento_sf(fcr.codcencus,
                                   fcr.codparc,
                                   fcr.numlote,
                                   fcr.sexo,
                                   trunc(sysdate),
                                   fcr);
  
    -- atualizar os valores previstos
    stp_set_atualizando('S');
  
    fcr.vlrmesprev  := snk_dividir(fcr.totremave * fcr.qtdavesliq, fcr.qtdmeses);
    fcr.qtdmortperm := fcr.qtdaves * (fcr.percmortprev / 100);
    begin
      update ad_tsffcr r
         set r.codtabprev  = fcr.codtabreal,
             r.dreftabprev = fcr.dreftabreal,
             r.vlrunitprev = fcr.totremave,
             r.vlrtotprev  = fcr.totremave * fcr.qtdavesliq,
             r.vlrmesprev  = fcr.vlrmesprev,
             r.pontuacao   = 100,
             r.status      = 'A',
             r.statuslote  = 'A',
             r.qtdmortperm = fcr.qtdmortperm
      /*r.codusualt   = p_codusu, sendo atualizado pela proc do recalculo
      r.dhalter     = sysdate*/
       where codcencus = fcr.codcencus
         and codparc = fcr.codparc
         and numlote = fcr.numlote
         and sexo = fcr.sexo;
    exception
      when others then
        p_mensagem := 'Erro ao atualizar os valores previstos. ' || sqlerrm;
        return;
    end;
  
    -- exclui lançamentos existentes
    begin
      delete from ad_tsffcradt
       where codcencus = fcr.codcencus
         and codparc = fcr.codparc
         and numlote = fcr.numlote
         and sexo = fcr.sexo;
    exception
      when others then
        p_mensagem := 'Erro ao excluir previsões de adiantamentos existentes' ||
                      sqlerrm;
        return;
    end;
  
    -- insere previsões de adiantamentos
    for m in 1 .. fcr.qtdmeses
    loop
    
      begin
        insert into ad_tsffcradt
          (codcencus, codparc, numlote, sexo, nuadt, desdobramento, dtref,
           vlrprev, vlradiant, nuacerto, dtvenc, dtvencini)
        values
          (fcr.codcencus, fcr.codparc, fcr.numlote, fcr.sexo, m, m,
           trunc(add_months(fcr.dtaloj, m - 1), 'fmmm'), fcr.vlrmesprev, 0, null,
           add_months(p_dtvencini, m - 1), add_months(p_dtvencini, m - 1));
      exception
        when others then
          p_mensagem := 'Erro ao inserir previsão de adiantamento. ' || sqlerrm;
          return;
      end;
    
    end loop;
    stp_set_atualizando('N');
    --Sim, possui adiantamentos gerados
  else
    -- recalcula os valores reais
    ad_stp_fcr_recalcfechamento_sf(fcr.codcencus,
                                   fcr.codparc,
                                   fcr.numlote,
                                   fcr.sexo,
                                   trunc(sysdate),
                                   fcr);
  
    -- tratativa para quando há reajuste de valor
  
    /* caso de uso
    Inicialmente foram calculadas 6 parcelas de R$ 10.000,00 cada,
    sendo que já foi feito adiantamento de 2 parcelas, ou seja, foram adiantados R$ 20.000,00.
    Ao conceder o terceiro adiantamento, em função de nova tabela o valor de cada parcela
    passou de R$ 10.000,00 para R$ 12.000,00, como o reajuste é retroativo,
    o integrado passa a ter direito a receber R$ 12.000,00 da terceira parcela,
    e a diferença do reajuste das duas parcelas anteriores, ou seja, R$ 2.000,00 da parcela 1
    e R$ 2.000,00 da parcela 2, logo a terceira parcela será gerada no valor total de R$ 16.000,00.*/
    declare
      v_vlrdif float := 0;
      d        int := 0;
    begin
      i := 0;
      for m in (select a.*, rowid
                  from ad_tsffcradt a
                 where a.codcencus = fcr.codcencus
                   and a.codparc = fcr.codparc
                   and a.numlote = fcr.numlote
                   and a.sexo = fcr.sexo
                 order by a.desdobramento)
      loop
      
        --- verifica se há alteração de valor, se houver, captura a diferença
        if m.vlrprev != fcr.vlrmesprev and m.nuacerto is not null then
          v_vlrdif := v_vlrdif + (fcr.vlrmesprev - m.vlrprev);
          continue;
        end if;
      
        -- se já possui adiantamento gerado, pula
        if m.nuacerto is not null then
          continue;
        end if;
      
        -- se possui nova data de vencimento
        --- altera o valor e a dt venc
        if p_dtvencini is not null then
          update ad_tsffcradt a
             set a.vlradiant = fcr.vlrmesprev,
                 a.dtvenc    = add_months(p_dtvencini, d)
           where a.rowid = m.rowid;
        
          d := d + 1;
          --- se não, altera só o valor
        else
          update ad_tsffcradt a
             set a.vlradiant = fcr.vlrmesprev
           where a.rowid = m.rowid;
        end if;
      
        -- corrige o valor com as diferenças retroativas
        if v_vlrdif > 0 and i = 0 then
          update ad_tsffcradt a
             set a.vlradiant = fcr.vlrmesprev + v_vlrdif
           where a.rowid = m.rowid;
          i := i + 1;
        end if;
      
      end loop;
    
    end;
  
  end if;

  /*@Nesse momento o fechamento estatrá "Em andamento", as previsões de adiantamento estarão
  geradas, de acordo com a quantidade de meses, não será possível alterar manualmente os
  valores no mainform, será possível recalcular*/
  stp_set_atualizando('N');

  p_mensagem := 'Cálculo realizado com Sucesso!!!';

end;
/
