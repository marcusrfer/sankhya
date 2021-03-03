create or replace procedure stp_fecha_frete_fgo_abat_sf as
  p_count         integer;
  p_valor         number;
  p_roteiro       varchar(300);
  p_distancia     number;
  p_codrota       integer;
  p_dhalter       date;
  p_vlrfrete_acum number;
  p_nunota        number;
  p_vlrfrete      number;
  p_qtdneg_total  number;
  p_dif           number;
  p_categoria     varchar(20);
  p_count_rota    int;
  p_dataoc        date;

  error exception;
  errmsg  varchar2(4000);
  errmsg2 varchar2(4000);

  type r_ordens_carga is record(
    codemp     int,
    ordemcarga number);

  type t_ordens_carga is table of r_ordens_carga;
  ord t_ordens_carga := t_ordens_carga();

begin
  p_dataoc := trunc(sysdate) - 1;
  --p_dataoc := '24/01/2020';

  --- DELETA DADOS DO DIA CASO HAJA RECÁCULO
  delete from tb_ord_calc_sf
   where dtcalculo = p_dataoc;

  -- BY RODRIGO 15/08/2016 PARA AUTOMATIZAR O FECHAMENTO DE ORDEM DE CARGAS FGO VIVO
  -- O.S4610 
  for cur_oc in (select ord.codemp, ord.ordemcarga, ord.codveiculo, ord.tipcalcfrete, codrota, ord.situacao, ord.vincrot
                   from tgford ord
                  where ord.dtinic = p_dataoc
                    and exists (select 1
                           from tgfcab cab
                          where cab.ordemcarga = ord.ordemcarga
                            and cab.codemp = ord.codemp
                            and cab.codtipoper in (61, 83, 175, 273, 120, 134, 46, 460))
                    and ord.codveiculo not in (10858, 10897, 10898, 10910, 11008, 11009, 11010, 14408)
                    and (select count(*)
                           from tgford o
                          where o.dtinic = p_dataoc
                            and o.codveiculo = ord.codveiculo) = 1)
  loop
    if cur_oc.tipcalcfrete = 9 then
      -- popula array
      ord.extend;
      ord(ord.last).codemp := cur_oc.codemp;
      ord(ord.last).ordemcarga := cur_oc.ordemcarga;
    else
    
      begin
        update tgford ord
           set ord.tipcalcfrete = 4,
               ord.situacao     = 'F',
               ord.vincrot      = 'S'
         where ord.ordemcarga = cur_oc.ordemcarga
           and ord.codemp = cur_oc.codemp;
        commit;
      exception
        when others then
          errmsg  := 'ERROR TRIGGERS';
          errmsg2 := sqlerrm;
          raise error;
      end;
    
      select count(*)
        into p_count
        from tgfcab cab
       where cab.codtipoper = 134
         and cab.ordemcarga = cur_oc.ordemcarga
         and cab.codemp = cur_oc.codemp;
    
      if p_count > 0 then
        begin
        
          -- ATUALIZA ORDEM DE CARGA
          update tgford ord
             set ord.codrota   = 270,
                 ord.vincrot   = 'S',
                 qtdentrega    = 1,
                 roteiro       = p_roteiro,
                 kmfin         = p_distancia,
                 vlrfrete      = p_valor,
                 dtalterrotcat = p_dhalter,
                 fretecalc     = 'S'
           where ord.ordemcarga = cur_oc.ordemcarga
             and ord.codemp = cur_oc.codemp;
        
          -- VALOR DO FRETE CONSIDERAR SEMPRE CONTAINER ACERTADO COM O ORLANDO DIA 23/05/2018
          select cat.valor, rot.descrrota, rot.distancia, cat.dtalter
            into p_valor, p_roteiro, p_distancia, p_dhalter
            from tgfrotcat cat, tgfrot rot
           where cat.codrota = rot.codrota
             and rot.codrota = 270
             and cat.ativo = 'S'
             and cat.categoria = 'CONTAINER';
        
          p_qtdneg_total := 0;
        
          for cur_exp in (select cab.nunota, sum(qtdneg) qtde,
                                 round(sum(qtdneg) / sum(sum(ite.qtdneg)) over(partition by 1) * 100, 2) perc,
                                 round(sum(qtdneg) / sum(sum(ite.qtdneg)) over(partition by 1) * 100, 2) * p_valor / 100 vlrfrete,
                                 sum(sum(ite.qtdneg)) over(partition by 1) total
                            from tgfcab cab, tgfite ite
                           where cab.nunota = ite.nunota
                             and cab.codtipoper = 134
                             and cab.ordemcarga = cur_oc.ordemcarga
                             and cab.codemp = cur_oc.codemp
                             and cab.tipmov = 'V'
                             and not exists (select 1
                                    from tgffre f
                                   where f.nunota = cab.nunota)
                           group by cab.nunota)
          loop
          
            update tgfcab
               set baseicmsfrete = cur_exp.vlrfrete,
                   vlrfrete      = cur_exp.vlrfrete,
                   tipfrete      = 'N',
                   vlrfretecalc  = cur_exp.vlrfrete,
                   icmsfrete     = 0,
                   ad_km         = p_distancia / p_count
            
             where nunota = cur_exp.nunota;
          
            p_qtdneg_total := p_qtdneg_total + cur_exp.qtde;
          
          end loop; -- CURSOR EXP                             
        
          insert into tb_ord_calc_sf
            (dtcalculo, codemp, ordemcarga, peso_total, cod_rota, valor_rota, status, obs)
          values
            (trunc(sysdate), cur_oc.codemp, cur_oc.ordemcarga, p_qtdneg_total, 270,
             -- COD_ROTA
             p_valor, 'CALCULADO',
             'CATEGORIA DO VEÍCULO: CONTAINER - EXPORTAÇÃO ' || 'VLR DT BASE CATEGORIA: ' || p_dhalter);
        
          commit;
        
        exception
          when error then
            errmsg := 'TESTE';
            raise error;
        end;
      
      end if; -- FIM SI EXPORTAÇÃO
    
      commit;
    
    end if; --tipcalcfrete = 9
  
  end loop;

  if ord.count > 0 then
    -- calcula as OC por KM
    declare
      qtderros int := 0;
    begin
      for i in ord.first .. ord.last
      loop
        ad_pkg_fkm.set_vlrfrete_notas(ord(i).codemp, ord(i).ordemcarga, ad_pkg_var.errmsg);
      
        if ad_pkg_var.errmsg != 'Sucesso' then
          qtderros := qtderros + 1;
          insert into ad_vlrfretekm_log
          values
            (ord(i).codemp, ord(i).ordemcarga, ad_pkg_var.errmsg);
        end if;
      
        ad_stp_gravafilabi(p_assunto => 'Fechamento automático de OC por Km',
                           p_mensagem => 'Foram processadas ' || ord.count || ' Ordens de carga. Sendo que ' ||
                                          ord.count - qtderros || ' delas foram processadas com sucesso e ' || qtderros ||
                                          ' delas não foram ' ||
                                          'processadas por algum erro. Verifique o log para maiores informações.',
                           p_email => 'paulo.modesto@ssa-br.com, orlando.sales@ssa-br.com');
      
      end loop;
    end;
  
  else
  
    stp_gravafilabi_sf('FECHAMENTO AUTOMÁTICO DE ORDENS DE CARGA', null, sysdate, 'PENDENTE', 0, 0,
                       'FECHAMENTO AUTOMÁTICO DE ORDENS DE CARGA REFERENTE AO DIA: ' || p_dataoc, 'E', 3,
                       'PAULO.MODESTO@SSA-BR.COM,ORLANDO.SALES@SSA-BR.COM,RODRIGO.PEREIRA@SSA-BR.COM');
  
    -- CASO HAJA RECALCULO OU TROCA DE ROTA AJUSTA O VLR DO FREETE NA ORDEM DE CARGA
    for cur_corrige in (select ord.codemp, ord.ordemcarga, cab.codveiculo, sum(cab.vlrfrete) fretecab, ord.vlrfrete
                          from tgfcab cab, tgford ord
                         where cab.ordemcarga = ord.ordemcarga
                           and cab.codemp = ord.codemp
                           and (cab.codemp, cab.ordemcarga) in (select s.codemp, s.ordemcarga
                                                                  from tb_ord_calc_sf s)
                              --- O.S  8604 A PEDIDO DO ORLANDO O NÃO CALCULO DESSES VEÍCULOS BY RODRIGO 
                           and (ord.codveiculo not in
                               (10858, 10897, 10898, 10910, 11008, 11009, 11010, 14408, 14497, 14408)) ---14408 o.s  35055 by rodrigo dia 03/09/2018
                           and cab.tipmov = 'V'
                           and ord.dtinic >= trunc(sysdate) - 6
                           and ord.dtinic >= trunc(sysdate) - 2
                         group by ord.codemp, ord.ordemcarga, cab.codveiculo, ord.vlrfrete
                        having sum(cab.vlrfrete) <> ord.vlrfrete)
    loop
    
      begin
        update tgford ord
           set ord.vlrfrete = cur_corrige.fretecab
         where ord.codemp = cur_corrige.codemp
           and ord.ordemcarga = cur_corrige.ordemcarga;
      exception
        when error then
          errmsg := 'TESTE';
          raise error;
      end;
    
    end loop;
  
    commit;
  
    --- ATIVA ROTAS COM PARCEIRO DE ORIGEM
    begin
      update tgfrot
         set ativo = 'S'
       where codrota in (select codrota
                           from tgfrot rot
                          where nvl(rot.ad_codparcrt, 0) > 0);
    exception
      when error then
        errmsg := 'TESTE';
        raise error;
    end;
  
    commit;
  
    --- EFETUA CALCULO
    for cur_oc in (select ord.codemp, ord.ordemcarga, ord.codveiculo, ord.tipcalcfrete, codrota, ord.situacao,
                          ord.vincrot, ord.codparcorig
                     from tgford ord
                    where ord.dtinic = p_dataoc
                      and exists
                    (select 1
                             from tgfcab cab
                            where cab.ordemcarga = ord.ordemcarga
                              and cab.codemp = ord.codemp
                              and cab.codtipoper in (61, 83, 175, 273, 460, 46, 120, 46, 460))
                      and ord.codveiculo not in (10858, 10897, 10898, 10910, 11008, 11009, 11010, 10858, 10897, 10898,
                                                 10910, 11008, 11009, 11010, 14408, 14497, 14408)
                      and (select count(*)
                             from tgford o
                            where o.dtinic = p_dataoc
                              and o.codveiculo = ord.codveiculo) = 1)
    loop
    
      -- VERIFICA SE EXISTE ROTA 
      p_count_rota := fc_conta_rota_transp_sf(cur_oc.codemp, cur_oc.ordemcarga);
    
      begin
        select nvl(fc_busca_rota_transp_sf(cur_oc.codemp, cur_oc.ordemcarga, p_count_rota, cur_oc.codparcorig), 0)
          into p_codrota
          from dual;
      exception
        when others then
          insert into tb_log_erro_fgo_sf
          values
            (cur_oc.codemp, cur_oc.ordemcarga, p_count_rota, cur_oc.codparcorig);
      end;
    
      if p_count_rota in (1, 2) and p_codrota > 0 then
      
        begin
          p_codrota := fc_busca_rota_transp_sf(cur_oc.codemp, cur_oc.ordemcarga, p_count_rota, cur_oc.codparcorig);
        exception
          when others then
            insert into tb_log_erro_fgo_sf
            values
              (cur_oc.codemp, cur_oc.ordemcarga, p_count_rota, cur_oc.codparcorig);
        end;
      
        --- VERIFICA SE EXISTE CATEGORIA
        select count(*)
          into p_count
          from tgfrotcat rot, tgfvei vei
         where rot.codrota = p_codrota
           and rot.categoria = vei.categoria
           and rot.ativo = 'S'
           and vei.codveiculo = cur_oc.codveiculo;
      
        -- SI MAIOR Q 1 EXISTE
        if p_count = 1 then
        
          select rot.valor, r.descrrota, r.distancia, rot.dtalter, rot.categoria
            into p_valor, p_roteiro, p_distancia, p_dhalter, p_categoria
            from tgfrot r, tgfrotcat rot, tgfvei vei
           where r.codrota = rot.codrota
             and rot.codrota = p_codrota
             and rot.categoria = vei.categoria
             and rot.ativo = 'S'
             and vei.codveiculo = cur_oc.codveiculo;
        
          update tgford
             set codrota       = p_codrota,
                 codusu        = 221,
                 dtalter       = sysdate,
                 qtdentrega   =
                 (select count(distinct codparc) as qtdentrega
                    from tgfcab cab
                   where cab.ordemcarga = tgford.ordemcarga
                     and cab.tipmov in ('V')
                     and cab.codemp in (tgford.codemp, tgford.codemp + 500, tgford.codemp - 500)
                     and cab.statusnota = 'L'),
                 roteiro       = p_roteiro,
                 kmfin         = p_distancia,
                 vlrfrete      = p_valor,
                 dtalterrotcat = p_dhalter,
                 fretecalc     = 'S'
          
           where (codemp = cur_oc.codemp or codemp = cur_oc.codemp + 500 or codemp = case
                   when cur_oc.codemp = 5 then
                    008
                   else
                    cur_oc.codemp
                 end or codemp = case
                   when cur_oc.codemp = 5 then
                    508
                   else
                    cur_oc.codemp
                 end)
             and ordemcarga = cur_oc.ordemcarga;
        
          ----- CALCULA O FRETE NAS NOTAS
        
          select sum(ite.qtdneg) qtdneg
            into p_qtdneg_total
          
            from tgfcab cab, tgfite ite
           where cab.nunota = ite.nunota
             and cab.ordemcarga = cur_oc.ordemcarga
                
             and (cab. codemp = cur_oc.codemp or cab.codemp = cur_oc.codemp + 500 or cab.codemp = case
                    when cur_oc.codemp = 5 then
                     008
                    else
                     cur_oc.codemp
                  end or cab.codemp = case
                    when cur_oc.codemp = 5 then
                     508
                    else
                     cur_oc.codemp
                  end)
                
             and tipmov = 'V';
        
          p_vlrfrete_acum := 0;
        
          for cur_notas in (select cab.ordemcarga, cab.nunota, vlrfrete, baseicmsfrete, icmsfrete, codveiculo,
                                   sum(ite.qtdneg) qtdneg,
                                   round((sum(ite.qtdneg) / sum(sum(ite.qtdneg))
                                           over(partition by cab.ordemcarga order by cab.ordemcarga)) * p_valor, 2) vlr_frete,
                                   sum(sum(ite.qtdneg)) over(partition by cab.ordemcarga order by cab.ordemcarga) peso
                              from tgfcab cab, tgfite ite
                             where cab.nunota = ite.nunota
                               and cab.ordemcarga = cur_oc.ordemcarga
                                  
                               and (cab. codemp = cur_oc.codemp or cab.codemp = cur_oc.codemp + 500 or cab.codemp = case
                                      when cur_oc.codemp = 5 then
                                       008
                                      else
                                       cur_oc.codemp
                                    end or cab.codemp = case
                                      when cur_oc.codemp = 5 then
                                       508
                                      else
                                       cur_oc.codemp
                                    end)
                                  
                               and tipmov = 'V'
                             group by cab.ordemcarga, cab.nunota, vlrfrete, baseicmsfrete, icmsfrete, codveiculo
                             order by cab.nunota)
          loop
          
            p_vlrfrete := round((cur_notas.qtdneg / p_qtdneg_total) * p_valor, 2);
          
            update tgfcab
               set baseicmsfrete = p_vlrfrete,
                   vlrfrete      = p_vlrfrete,
                   tipfrete      = 'N',
                   vlrfretecalc  = p_vlrfrete,
                   icmsfrete     = 0
             where nunota = cur_notas.nunota;
          
            p_nunota := cur_notas.nunota;
          
          end loop; --- FIM CURSOR NOTA FISCAL
        
          select sum(cab.vlrfrete)
            into p_vlrfrete_acum
            from tgfcab cab
           where cab.ordemcarga = cur_oc.ordemcarga
             and (cab. codemp = cur_oc.codemp or cab.codemp = cur_oc.codemp + 500 or cab.codemp = case
                    when cur_oc.codemp = 5 then
                     008
                    else
                     cur_oc.codemp
                  end or cab.codemp = case
                    when cur_oc.codemp = 5 then
                     508
                    else
                     cur_oc.codemp
                  end)
             and tipmov = 'V';
        
          p_dif := 0;
        
          if p_vlrfrete_acum > p_valor then
          
            p_dif := (p_valor - p_vlrfrete_acum);
          
            update tgfcab cab
               set baseicmsfrete = baseicmsfrete + p_dif,
                   vlrfrete      = vlrfrete + p_dif,
                   vlrfretecalc  = vlrfretecalc + p_dif
             where nunota = p_nunota;
          
          elsif p_vlrfrete_acum < p_valor then
          
            p_dif := nvl(p_valor - p_vlrfrete_acum, 0);
          
            update tgfcab cab
               set baseicmsfrete = baseicmsfrete + p_dif,
                   vlrfrete      = vlrfrete + p_dif,
                   vlrfretecalc  = vlrfretecalc + p_dif
             where nunota = p_nunota;
          
          end if;
        
          --VLRFRETECPL = 7.87,                                            
        
          insert into tb_ord_calc_sf
            (dtcalculo, codemp, ordemcarga, peso_total, cod_rota, valor_rota, status, obs)
          values
            (trunc(sysdate), cur_oc.codemp, cur_oc.ordemcarga, p_qtdneg_total, p_codrota, p_valor, 'CALCULADO',
             'CATEGORIA DO VEÍCULO: ' || p_categoria || 'VLR DT BASE CATEGORIA: ' || p_dhalter);
        
          commit;
        
        else
        
          insert into tb_ord_calc_sf
            (dtcalculo, codemp, ordemcarga, peso_total, cod_rota, valor_rota, status, obs)
          values
            (trunc(sysdate), cur_oc.codemp, cur_oc.ordemcarga, p_qtdneg_total, 0, 0, 'ERRO',
             'NÃO EXISTE CADASTRADA A CATEGORIA DE VEÍCULO CORRESPONDENTE A ORDEM DE CARGA');
        
          commit;
        
        end if; -- FIM TESTA CATEGORIA
      
      else
      
        insert into tb_ord_calc_sf
          (dtcalculo, codemp, ordemcarga, peso_total, cod_rota, valor_rota, status, obs)
        values
          (trunc(sysdate), cur_oc.codemp, cur_oc.ordemcarga, p_qtdneg_total, 0, 0, 'ERRO',
           'NÃO EXISTE ROTA COMPATÍVEL PARA A ORDEM DE CARGA OU PARCEIRO DE ORIGEM ERRADO');
      
        commit;
      
      end if;
    
    end loop;
  
  end if; -- ord.count > 0

exception
  when error then
    stp_gravafilabi_sf('FECHAMENTO AUTOMÁTICO DE ORDENS DE CARGA - ' || errmsg, null, sysdate, 'PENDENTE', 0, 0,
                       'VERIFICAR ERROR: ' || errmsg2, 'E', 3, 'RODRIGO.PEREIRA@SSA-BR.COM,MARCELO.VIEIRA@SSA-BR.COM');
end;
/
