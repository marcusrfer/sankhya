Create Or Replace View AD_VW_TSFLFV
As
Select p.codparc, par.nomeparc unidade, par.razaosocial integrado, par.tippessoa, ad_get.Enderecocompleto('P', p.codparc, Null) propriedade,
       cid.nomecid As municipio, ufs.uf, p.codprod, pro.descrprod, l.dtalojamento, l.qtdaves, l.qtdaves - l.qtdmortes qtdavesfinal, l.descrabrevave linhagem,
       Case When par.codtipparc = 11110200 Then 'Incubatório SSA' Else par.razaosocial End As fornecedor, l.gta, par.cgc_cpf As origem,
       l.dhpega, l.dhracao, rtrim(ltrim(l.obs||Chr(13)||l.obsmedicamento||Chr(13)||l.obscarencia)) Obs, l.dtalojamento - 1 As dtmarek, 
       l.dtalojamento-1 As dtbouba, l.dtalojamento+14 As dtgumboro, l.irritacao,
       l.aerosaculite, l.calo, l.dermatose, l.risco, l.qtdmortes mortalidade, l.pesofinal
  From ad_tsfpfv p
  Join ad_tsflfv l
    On l.codparc = p.codparc And l.codprod = p.codprod And Trunc(l.dhpega) = p.dtdescarte
  Join tgfpar par
    On p.codparc = par.codparc
  Join tsicid cid 
    On par.codcid = cid.codcid
  Join tsiufs ufs 
    On cid.uf = ufs.coduf
  Join tgfpro pro
   On p.codprod = pro.codprod;
 
