create or replace view ad_tcssca as
Select 
 	con.numcontrato, 
  con.dtcontrato,
  'Emp: '||con.codemp||', Prod: '||psc.codprod||', Parc: '||con.codparc descrcontrato,
	con.codparc, 	
  psc.codprod,
  psc.qtdeprevista qtdneg,
	nvl(Sum(c.qtdsacas*60),0) qtdent,
  psc.qtdeprevista - nvl(Sum(c.qtdsacas*60),0) qtdres
From tcscon con
  join tcspsc psc 
    on psc.numcontrato = con.numcontrato
  left join ad_vw_cmp c 
    on c.contratocpa = con.numcontrato
      and c.codprod = psc.codprod
Group By con.numcontrato, 
  con.dtcontrato,
  'Emp: '||con.codemp||', Prod: '||psc.codprod||', Parc: '||con.codparc,
	con.codparc, 	
  psc.codprod,
  psc.qtdeprevista;
