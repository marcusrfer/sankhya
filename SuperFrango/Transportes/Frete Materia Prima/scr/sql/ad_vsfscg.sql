create or replace view ad_vsfscg as
with entradas as (
 Select v.nunotaorig,
	sum(i.qtdneg * i.atualestoque) qtdent
  from tgfcab c, tgfite i, tgfvar v
  where c.nunota = i.nunota
  and v.nunota = c.nunota
 GROUP BY v.nunotaorig
)
select c.numcontrato, c.codemp, 0 As nunota, c.dtentsai, c.codparc, i.codprod, Sum( i.qtdneg) qtdneg, sum(E.qtdent) qtdent, Sum(i.qtdneg - E.qtdent) saldo
 from tgfcab c
 join tgfite i
  on c.nunota = i.nunota
 join entradas e
  on e.nunotaorig = c.nunota
		Join tcscon con On con.numcontrato = c.numcontrato
 where C.codtipoper in (919,950)
 and C.numcontrato > 0
	And nvl(con.ativo,'N') = 'S'
Group By c.numcontrato, c.codemp, 0 , c.dtentsai, c.codparc, i.codprod;
