create or replace procedure ad_stp_adtssa_solaprov_sf(p_codusu    number,
                                                      p_idsessao  varchar2,
                                                      p_qtdlinhas number,
                                                      p_mensagem  out varchar2) as
  cab  ad_adtssacab%rowtype;
  conf ad_adtssaconf%rowtype;

  v_aprfin           number := 0;
  v_count            int;
  v_diascarencia     number;
  v_dtvenc           date;
  v_log              varchar2(100);
  v_mensagemusu      varchar2(500);
  v_solicitacarencia number := 0;
  v_solicitajuro     number := 0;
  v_solicitaparcela  number := 0;
  v_solicitavalor    number := 0;
  v_tipojuro         varchar2(30);

  v_totdesp    float;
  v_totrec     float;
  v_totdespren float;
  v_totrecren  float;

  v_titulo   varchar(4000);
  v_mensagem varchar(4000);
  v_incluir  boolean;
  v_count1   int;
  p_errmsg   varchar(200);
  errmsg     varchar(200);
begin

  /*
    Autor: MARCUS.RANGEL 06/03/2020 13:31:47
    Processo: Adiantamento SSA
    Objetivo: realizar a solicitação de aprovação dos adiantamentos
  */

  stp_set_atualizando('S');

  if p_qtdlinhas > 1 then
    p_mensagem := 'Selecione apenas um registro por vez';
    return;
  end if;

  cab.nunico := act_int_field(p_idsessao, 1, 'NUNICO');

  begin
    select c.* into cab from ad_adtssacab c where c.nunico = cab.nunico;
  exception
    when others then
      p_mensagem := 'Erro ao localizar a nota pelo número único informado. ' || sqlerrm;
      return;
  end;

  select max(data)
    into v_dtvenc
    from table(func_dias_uteis_mmac(trunc(sysdate), trunc(sysdate) + 10, 1, 4));

  select c.* into conf from ad_adtssaconf c where c.codigo = cab.tipo;

  select sum(decode(p.recdesp, 1, p.vlrdesdob, 0)), sum(decode(p.recdesp, -1, p.vlrdesdob, 0))
    into v_totrec, v_totdesp
    from ad_adtssapar p
   where p.nunico = cab.nunico;

  -- VALIDAÇÕES
  begin
    if nvl(conf.renovar, 'N') = 'S' then
    
      select nvl(sum(p.vlrdesdob), 0)
        into v_totdespren
        from ad_adtssaparrenovar p
       where p.nunico = cab.nunico;
    
      --- se possui as parcelas renovar
      if v_totdespren = 0 then
        p_mensagem := 'Não foi encontrado valor total de despesa, por favor verifique ' ||
                      ' se as depesas foram lançadas na aba de parcelamento.';
        return;
      end if;
    
      if cab.vlrdesdob != v_totdespren then
        p_mensagem := 'O valor total de despesa é diferente do valor total do empréstimo.' ||
                      ' Verifique se todas as despesas foram lançadas no sistema.';
        return;
      end if;
    
    end if;
  
    -- validação dos demais campos
    begin
      ad_stp_adtssa_valida_cab_sf(p_nunico => cab.nunico,
                                  p_val_total => case
                                                    when nvl(conf.renovar, 'N') = 'S' then
                                                     'N'
                                                    else
                                                     'S'
                                                  end, p_solcarencia => v_solicitacarencia,
                                  p_solvalor => v_solicitavalor, p_soljuro => v_solicitajuro,
                                  p_solparc => v_solicitaparcela, p_mensagem => p_mensagem);
      if p_mensagem is not null then
        return;
      end if;
    end;
  end;
  -- fim validações

  -- mensageria
  begin
  
    /* Se o registro esta pendente de aprovação em função de juro, 
    nr de parcelas ou valor do adiantamento envia uma requisição 
    de aprovação para o financeiro, caso contrário faz a inclusão na TGFFIN pela */
  
    if (v_solicitajuro = 1 or v_solicitaparcela = 1 or v_solicitavalor = 1 or
       v_solicitacarencia = 1) and conf.exigaprdesp = 'S' then
    
      if v_solicitajuro = 1 then
        v_mensagemusu := 'Juro Minimo: ' || nvl(conf.juro, 0) || '% - Juro Negociado: ' ||
                         nvl(cab.taxa, 0) || '%. ';
      end if;
    
      if v_solicitaparcela = 1 then
        v_mensagemusu := case
                           when v_mensagemusu is not null then
                            v_mensagemusu || '\nNr. Máximo Parcelas: ' || conf.parcela || ' Nr. Parcelas Negociado: ' ||
                            cab.nrparcelas || '. '
                           else
                            v_mensagemusu || 'Nr. Máximo Parcelas: ' || conf.parcela || ' Nr. Parcelas Negociado: ' ||
                            cab.nrparcelas || '. '
                         end;
      end if;
    
      if v_solicitavalor = 1 then
        v_mensagemusu := case
                           when v_mensagemusu is not null then
                            v_mensagemusu || '\nVlr Máx Configurado: ' || ad_get.formatavalor(conf.vlrmax) ||
                            ' Vlr Negociado: ' || ad_get.formatavalor(cab.vlrdesdob) || '. '
                           else
                            v_mensagemusu || 'Vlr Máx Configurado: ' || ad_get.formatavalor(conf.vlrmax) ||
                            ' Vlr Negociado: ' || ad_get.formatavalor(cab.vlrdesdob) || '. '
                         end;
      end if;
    
      if v_solicitacarencia = 1 then
        v_mensagemusu := case
                           when v_mensagemusu is not null then
                            v_mensagemusu || '\nDias Máximo Carência: ' || conf.carencia || ' Dias Carência Negociado: ' ||
                            v_diascarencia || '. '
                           else
                            v_mensagemusu || 'Dias Máximo Carência: ' || conf.carencia || ' Dias Carência Negociado: ' ||
                            v_diascarencia || '. '
                         end;
      
      end if;
    
      v_titulo   := 'Verifique dados do adiantamento!';
      v_mensagem := 'Divergência de:\n' || v_mensagemusu ||
                    '\n\n<font color="#FF0000">Será encaminhado uma solicitação ' ||
                    'de aprovação para o departamento financeiro</font>.\n\nDeseja Continuar?';
      v_incluir  := act_confirmar(v_titulo, v_mensagem, p_idsessao, 1);
    
      if v_incluir then
      
        v_aprfin := 1;
      
        p_mensagem := 'Solicitação encaminhada para Responsável CR e Departamento Financeiro. ' ||
                      'Caso tenha urgência no processo entre em contato e informe sua necessidade!';
      
        v_log := 'Aguardando Aprovação Financeira e da Gerência';
      
      else
        v_log := 'Aguardando aprovação da gerência!';
      end if;
    
    end if;
  
  end;
  -- fim mensageria

  --insert financeiro
  begin
  
    p_mensagem := null;
  
    if nvl(conf.renovar, 'N') = 'S' then
      ad_stp_adtssa_gerafinren_sf(p_nunico => cab.nunico, p_aprov_fin => v_aprfin,
                                  p_mensagemusu => v_mensagemusu);
    else
      stp_adtssacab_gerafin_sf(cab.nunico, v_aprfin, v_mensagemusu);
    end if;
  
    if p_mensagem is not null then
      return;
    elsif conf.exigaprdesp = 'N' then
      p_mensagem := 'Adiantamento Finalizado com Sucesso!';
    else
      p_mensagem := 'Solicitação encaminhada para aprovação do Responsável CR. ' ||
                    'Caso tenha urgência no processo entre em contato com o aprovador e informe sua' ||
                    ' necessidade!';
    end if;
  
  end;
  stp_set_atualizando('N');
end;
/
