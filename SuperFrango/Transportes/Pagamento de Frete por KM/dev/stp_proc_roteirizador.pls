create or replace procedure stp_proc_roteirizador(p_codusu    number,
                                                  p_idsessao  varchar2,
                                                  p_qtdlinhas number,
                                                  p_mensagem  out varchar2) as
  field_codigo    number;
  v_seqentrega    number;
  v_ultordemcarga number;
  v_count         number;

begin

  --Pk registro 
  field_codigo := act_int_field(p_idsessao, 1, 'CODIGO');

  --Loop veículos
  for cur_veiculo in (select cab.codemp, rot.codveiculo, rot.codparcorig, vei.pesomax, vei.codparc, rot.nuparam,
                             max(rot.distancia) as distancia,
                             fc_get_regiao_ped_sf(cab.codemp, cab.codparc).regiaotransb as regiaotransb,
                             case
                                when fc_get_regiao_ped_sf(cab.codemp, cab.codparc).regiaotransb = 'ENTBSB' then
                                 fc_get_dep_by_local(ite.codlocalorig, ite.codlocalterc)
                                else
                                 1
                              end as coddep, vei.ad_codcat codcat
                        from ad_roteirizadorrot rot
                        join tgfcab cab
                          on rot.nunota = cab.nunota
                        join tgfite ite
                          on cab.nunota = ite.nunota
                        join tgfvei vei
                          on vei.codveiculo = rot.codveiculo
                       where rot.codigo = field_codigo
                       group by cab.codemp, rot.codveiculo, rot.codparcorig, vei.pesomax, vei.codparc, rot.nuparam,
                                fc_get_regiao_ped_sf(cab.codemp, cab.codparc).regiaotransb,
                                case
                                  when fc_get_regiao_ped_sf(cab.codemp, cab.codparc).regiaotransb = 'ENTBSB' then
                                   fc_get_dep_by_local(ite.codlocalorig, ite.codlocalterc)
                                  else
                                   1
                                end, vei.ad_codcat
                       order by 7 /*Distancia*/
                      )
  loop
  
    --Busca incremental TGFORD 
  
    --Implementação Danilo - O.S 42501 (OC Distintas por depósito)  
    select ultordemcarga
      into v_ultordemcarga
      from ad_integracaorothbsisparam
     where nuparam = cur_veiculo.nuparam;
  
    v_count := 1; --para iniciar o loop
  
    while v_count > 0
    loop
      v_ultordemcarga := v_ultordemcarga + 1;
    
      select count(1)
        into v_count
        from tgford
       where ordemcarga = v_ultordemcarga;
    
    end loop;
  
    --Implementação Danilo - O.S 42501 (OC Distintas por depósito) 
    update ad_integracaorothbsisparam
       set ultordemcarga = v_ultordemcarga
     where nuparam = cur_veiculo.nuparam;
  
    commit;
  
    insert into tgford
      (codemp, ordemcarga, codveiculo, codparctransp, codreg, pesomax, codparcorig, dtinic, dtprevsaida, ad_kmrota)
    values
      (cur_veiculo.codemp, v_ultordemcarga, cur_veiculo.codveiculo, cur_veiculo.codparc, 0, cur_veiculo.pesomax,
       case when cur_veiculo.codemp = 5 then 22147 when cur_veiculo.codemp = 1 and cur_veiculo.coddep = 2 then 774811 else
        cur_veiculo.codparcorig end, trunc(sysdate), trunc(sysdate), (cur_veiculo.distancia / 1000) /*Distancia em km*/);
    commit;
  
    insert into ad_roteirizadorord
      (codigo, codemp, ordemcarga)
    values
      (field_codigo, cur_veiculo.codemp, v_ultordemcarga);
  
    commit;
  
    --Atribuí ordem de carga aos pedidos
    v_seqentrega := 1;
  
    for cur_pedido in (select cab.nunota, rot.seqentrega, cab.ordemcarga
                         from ad_roteirizadorrot rot
                         join tgfcab cab
                           on rot.nunota = cab.nunota
                         join tgfite ite
                           on cab.nunota = ite.nunota
                        where rot.codigo = field_codigo
                          and cab.codemp = cur_veiculo.codemp
                          and rot.codveiculo = cur_veiculo.codveiculo
                          and (case
                                when cur_veiculo.regiaotransb = 'ENTBSB' then
                                 (case
                                   when fc_get_dep_by_local(ite.codlocalorig, ite.codlocalterc) = cur_veiculo.coddep then
                                    1
                                   else
                                    0
                                 end)
                                else
                                 1
                              end) = 1
                       
                        order by rot.seqentrega)
    loop
    
      update tgfcab cab
         set cab.ordemcarga    = v_ultordemcarga,
             cab.seqcarga      = v_seqentrega * 10,
             cab.codveiculo    = cur_veiculo.codveiculo,
             cab.codparctransp = cur_veiculo.codparc
       where cab.nunota = cur_pedido.nunota;
    
      commit;
    
      v_seqentrega := v_seqentrega + 1;
    
    end loop cur_pedido;
  
    -- m. rangel - precificação do frete por km
    declare
      v_codreg      number;
      v_codparcorig number;
      v_vlrkm       float;
      errmsg        varchar2(4000);
    begin
    
      v_codreg := ad_pkg_fkm.get_regioes_oc(cur_veiculo.codemp, v_ultordemcarga);
    
      for r in (select *
                  from ad_tsfrfc
                 where codregfre = v_codreg)
      loop
        if nvl(r.precifica, 'N') = 'S' then
        
          v_codparcorig := case
                             when cur_veiculo.codemp = 5 then
                              22147
                             when cur_veiculo.codemp = 1 and cur_veiculo.coddep = 2 then
                              774811
                             else
                              cur_veiculo.codparcorig
                           end;
        
          v_vlrkm := ad_pkg_fkm.get_vlr_regfrete(r.codregfre, cur_veiculo.codcat, v_codparcorig,
                                                 (cur_veiculo.distancia / 1000));
          update tgford
             set tipcalcfrete = 9,
                 vlrfrete     = round(v_vlrkm, 2)
           where codemp = cur_veiculo.codemp
             and ordemcarga = v_ultordemcarga;
        end if;
      end loop;
    
    exception
      when others then
        errmsg := sqlerrm;
        insert into ad_vlrfretekm_log
        values
          (cur_veiculo.codemp, v_ultordemcarga, errmsg);
    end;
  
  end loop cur_veiculo;

  p_mensagem := 'Gerado com sucesso!';
end;
/
