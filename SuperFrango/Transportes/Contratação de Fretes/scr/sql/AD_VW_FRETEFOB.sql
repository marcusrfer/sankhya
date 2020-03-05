create or replace view AD_VW_FRETEFOB as
Select /*+ INDEX_STATS    */
       c.nunota,
       c.codemp,
       ce.codcid codcidDest,
       ce.nomecid || '-' || ue.uf ciddestino,
       c.dtneg,
       c.codparc,
       p.nomeparc,
       cp.codcid codcidOrig,
       cp.nomecid || '-' || up.uf cidOrigem,
       c.codparctransp,
       pt.nomeparc nomeParcTransp,
       c.vlrnota,
			 c.peso,
      Nvl(to_number(Substr(o.peso, 1, Instr(o.peso, '.') - 1)) +
			(to_number(substr(Substr(o.peso, Instr(o.peso, '.') + 1, Length(o.peso)), 1, 2)) / 100),c.peso) pesobruto,
       c.vlrfrete,
			 round(to_number(Substr(ad_pkg_fob.melhorvalor(c.nunota, c.codparctransp), Instr(ad_pkg_fob.melhorvalor(c.nunota, c.codparctransp), '-') + 1)),2) vlratual,
       to_number(Substr(ad_pkg_fob.melhorValor(c.nunota), 1, Instr(ad_pkg_fob.melhorValor(c.nunota), '-') - 1)) melhorparc,
       round(to_number(Substr(ad_pkg_fob.melhorValor(c.nunota), Instr(ad_pkg_fob.melhorValor(c.nunota), '-') + 1)),2) melhorvalor
  From tgfcab c
	Left Join tgffin f On c.nunota = f.nunota And f.chavecte Is Not Null
	Left Join ad_vw_cteoobj o On o.chave_acesso = f.chavecte
  Join tsiemp emp On c.codemp = emp.codemp
  join tsicid ce On emp.codcid = ce.codcid
  Join tsiufs ue On ce.uf = ue.coduf
  Join tgfpar p On p.codparc = c.codparc
  Join tsicid cp On p.codcid = cp.codcid
  Join tsiufs up On cp.uf = up.coduf
  Join tgfpar pt On c.codparctransp = pt.codparc
 Where c.tipmov = 'C'
   And c.cif_fob = 'F'
   --And (Case When c.peso > 0 Then c.peso Else c.pesobruto End) > 0
   And emp.codcid <> p.codcid
   And nvl(c.vlrfrete,0) > 0
   And nvl(pt.ad_podecoletar,'N') = 'S'
;
