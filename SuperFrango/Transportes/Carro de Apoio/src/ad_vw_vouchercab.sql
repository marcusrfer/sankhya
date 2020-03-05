create or replace view ad_vw_vouchercab as
Select "NUCAPSOL","NOMEUSU","CODCENCUS","LOTACAO","DESCRCENCUS","CODPARCTRANSP","NOMEPARCTRANSP","CODVEICULO","DESCRVEI","CODUSUEXC","NOMEUSUEXC","DHSOLICIT","DTAGEND","STATUS","MOTIVO","NUAP" From (
  /*  Select
						s.nucapsol,
						s.codusu || ' - ' || ad_get.nomeUsu(s.codusu, 'resumido') As nomeusu,
						s.codcencus,
				  cap.qtdpassageiros LOTACAO,
						cap.codveiculo,
						cus.descrcencus,
						cap.codparctransp,
						par.nomeparc nomeparctransp,
			   ad_get.formataplaca(vei.placa) || ' / ' || vei.marcamodelo descrvei,
						cap.codusuexc,
						ad_get.nomeUsu(cap.codusuexc, 'resumido') nomeusuexc,
						s.dhsolicit,
						cap.dtagend,
						s.status,
						s.motivo,
						s.nuap
	    From ad_tsfcapsol s
      Join ad_tsfcap cap On (cap.nuap = s.nuap)
      Join tsicus cus On (s.codcencus = cus.codcencus)
	     Join tgfpar par On (cap.motorista = par.codparc)
	     Join tgfvei vei On (cap.codveiculo = vei.codveiculo)
     Where cap.status In ('A', 'R')
  Union All
    Select
      s.nucapsol,
      s.codusu || ' - ' || ad_get.nomeUsu(s.codusu, 'resumido') As nomeusu,
      s.codcencus,
      cap.qtdpassageiros LOTACAO,
      cap.codveiculo,
      cus.descrcencus,
      cap.codparctransp,
      par.nomeparc nomeparctransp,
      ad_get.formataplaca(vei.placa) || ' / ' || vei.marcamodelo descrvei,
      cap.codusuexc,
      ad_get.nomeUsu(cap.codusuexc, 'resumido') nomeusuexc,
      s.dhsolicit,
      cap.dtagend,
      s.status,
      s.motivo,
      cap.nuap
     From ad_tsfcapsol s
      Join ad_tsfcap cap On (cap.nucapsol = s.nucapsol)
      Join tsicus cus On (s.codcencus = cus.codcencus)
      Join tgfpar par On (cap.motorista = par.codparc)
      Join tgfvei vei On (cap.codveiculo = vei.codveiculo)
     Where cap.status In ('A', 'R')*/

		With tabela_avo As
 (Select *
    From ad_tsfcap cap
   Where nuappai Is Not Null
     And status In ('A', 'R')),
tabela_pai As
 (Select *
    From ad_tsfcap cap
   Where status In ('A', 'R'))
Select cap.nucapsol,
       ad_get.nomeusu(cap.codususol, 'resumido') nomeusu,
       sol.codcencus,
       cap.qtdpassageiros lotacao,
       cus.descrcencus,
       nvl(Nvl(a.codparctransp, p.codparctransp), cap.codparctransp) codparctransp,
       par.nomeparc nomeparctransp,
       nvl(Nvl(a.codveiculo, p.codveiculo), cap.codveiculo) codveiculo,
       v.marcamodelo||' / '||ad_get.formataplaca(v.placa) descrvei,
       nvl(Nvl(a.codusuexc, p.codusuexc), cap.codusuexc) codusuexc,
       ad_get.nomeusu(nvl(Nvl(a.codusuexc, p.codusuexc), cap.codusuexc), 'resumido') nomeusuexc,
       nvl(Nvl(a.dhsolicit, p.dhsolicit), cap.dhsolicit) dhsolicit,
       nvl(Nvl(a.dtagend, p.dtagend),cap.dtagend) dtagend,
       nvl(Nvl(a.status, p.status), cap.dtagend) status,
       nvl(Nvl(a.motivo, p.motivo), cap.motivo) motivo,
       nvl(Nvl2(a.nuap, a.nuap, p.nuap), cap.nuap) nuap
  From ad_tsfcap cap
  Left Join tabela_pai p
    On p.nuap = cap.nuappai
  Left Join tabela_avo a
    On a.nuap = p.nuappai
  Join ad_tsfcapsol sol
    On cap.nucapsol = sol.nucapsol
  Left Join tgfvei v
    On v.codveiculo = nvl(Nvl(a.codveiculo, p.codveiculo), cap.codveiculo)
  Left Join tgfpar par
    On par.codparc = nvl(Nvl(a.motorista, p.motorista), cap.motorista)
  Join tsicus cus On cus.codcencus = sol.codcencus) sol;
