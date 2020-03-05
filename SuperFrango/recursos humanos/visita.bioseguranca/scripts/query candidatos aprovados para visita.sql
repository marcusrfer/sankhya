select vag.vagidentificacao,
       vag.vagdescricao,
       vag.vagdatainicio,
       vag.vagnomeanalista,
       vag.vagnomegestor,
       vag.vagcodigoempresa,
       vag.vagcodigoposicao,
       vag.vagdescricaoposicao,
       vag.vagfaseatual,
       vag.vagprctconclusao,
       p.posicodlot,
       vag.vagdescricaoestabelecimento,
       vag.vagdescricaodepartamento,
       vag.vagdescricaocentrodecusto,
       vag.vagcodigocargo,
       vag.vagdescricaocargo,
       can.cancodigo,
       can.cannome,
       ce.endcep,
       ce.endlogradouro,
       ce.endnumero,
       ce.endcomplemento,
       ce.endbairro,
       mun.munnome,
       mun.munestado
  from fpwpower.vw_recr_vaga vag
  join fpwpower.recr_participantedavaga part
  on vag.id = part.pdvidvaga
  join fpwpower.recr_dadoscontratuais dad
  on dad.dctidvaga = part.pdvidvaga
   join fpwpower.recr_candidato can
  on part.pdvidorigemparticipante = can.id
   join fpwpower.recr_etapa etp
  on vag.id = etp.etpidvaga
 left join fpwpower.comp_endereco ce
   on can.canidendereco = ce.id
 left join fpwpower.comp_municipio mun
   on mun.id = ce.endidmunicipio
 left join fpwpower.posicao p
  on p.posicodpos = vag.vagcodigoposicao
 left join(select fun.*,
                   id,
                   idtenant
            from fpwpower.funciona fun
            join fpwpower.infr_objetoid oidcontrato
          on oidcontrato.oidtipo = 1034
           where fun.fumatfunc = oidcontrato.oidcodigo
             and fun.fucodemp = oidcontrato.oidcodigoempresa
           )gestor
on vag.vagidcontratosolicitante = gestor.id
   and vag.idtenant = gestor.idtenant
 where 1 = 1
   --and vag.vagfaseatual = 'Seleção'
   --and vag.vagestadovaga = 0
   --and etp.etpordem = 4
   and vag.vagcodigo = 2676
   and etp.etpdescricao like '%DOMICILIAR'