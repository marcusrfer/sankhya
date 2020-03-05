Create Or Replace View ad_vw_vagasdisp_fpw As
select v.vagcodigoempresa, l.locodlot, v.vagcodigo, v.vagdescricao, v.vagidentificacao, v.vagdescricaoposicao,
       v.vagdescricaodepartamento, v.vagdescricaocentrodecusto, v.vagfaseatual, v.vagdatainicio,
       v.vagdatalimite, v.vagdescricaocargo, v.vagdescricaomunicipio
  from fpwpower.vw_recr_vaga v
  join fpwpower.posicao p
    on p.posicodemp = v.vagcodigoempresa
   and v.vagcodigoposicao = p.posicodpos
  join fpwpower.lotacoes l
    on l.locodemp = p.posicodemp
   and l.locodlot = p.posicodlot
 where v.vagdataconclusao is null
