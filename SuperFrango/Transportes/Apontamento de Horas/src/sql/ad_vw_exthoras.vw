create or replace view ad_vw_exthoras as
(Select c.nuapont, m.numcontrato, m.codprod, ad_get.descrproduto(m.codprod) descrproduto, m.codmaq,
			 ad_pkg_ahm.descrmaquina(m.codmaq) descrmaq, a.dtapont, a.codvol,  to_char(to_date(a.hora,'HH24:MI'),'hh24:MI') hora, a.horimetro, a.qtdneg
	From ad_tsfahmc c
 Inner Join ad_tsfahmmaq m On m.nuapont = c.nuapont
 Inner Join ad_tsfahmapd a On a.nuapont = m.nuapont
												And a.nuseqmaq = m.nuseqmaq
 Inner Join tgfvol v On m.codvol = v.codvol												 )
;
