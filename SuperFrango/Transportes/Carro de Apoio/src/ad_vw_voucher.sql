create or replace view ad_vw_voucher as
(
Select Distinct s.nucapsol,
                s.codusu || ' - ' || ad_get.nomeUsu(pCodusu => s.codusu, pTipo => 'resumido') As nomeusu,
                cap.codparctransp, par.nomeparc nomeparctransp, cap.codveiculo,
                vei.placa || ' - ' || vei.marcamodelo descrvei, cap.codusuexc,
                ad_get.nomeUsu(cap.codusuexc, 'resumido') nomeusuexc, s.dhsolicit, cap.dtagend, s.status,
                Case
                  When i.tipotin = 'O' Then
                   'Origem'
                  When i.tipotin = 'D' Then
                   'Destino'
                  When i.tipotin = 'I' Then
                   'Intermedíario'
                End As tipoend, i.codcid, c.nomecid, e.tipo || ' ' || e.nomeend nomeend,
                nvl(b.nomebai, '<Sem Bairro>') nomebai, nvl(i.complemento, ' ') complemento,
                nvl(i.referencia, ' ') referencia, nvl(usu.codemp, rat.codemp) codemp, emp.razaosocial,
                nvl(rat.codnat, 4051300) codnat, nat.descrnat, nvl(rat.codcencus, s.codcencus) codcencus,
                cus.descrcencus, nvl(to_char(rat.percentual), 100) || '%' percentual
  From ad_tsfcapsol s
  Join ad_tsfcapitn i On (s.nucapsol = i.nucapsol)
  Left Join ad_tsfcaprat rat On (s.nucapsol = rat.nucapsol)
  Join tsicus cus On (s.codcencus = cus.codcencus Or cus.codcencus = rat.codcencus)
  Left Join ad_tsfcaplig lig On (s.nuap = lig.nuaporig)
  Left Join ad_tsfcap cap On (cap.nuap = lig.nuap Or cap.nuap = s.nuap)
  Left Join tgfpar par On (par.codparc = cap.codparctransp)
  Left Join tgfvei vei On (vei.codveiculo = cap.codveiculo)
  Left Join tsicid c On (i.codcid = c.codcid)
  Left Join tsiend e On (i.codend = e.codend)
  Left Join tsibai b On (i.codbai = b.codbai)
  Join tsiusu usu On s.codusu = usu.codusu
  Left Join tsiemp emp On emp.codemp = nvl(usu.codemp, 1)
  Left Join tgfnat nat On (nat.codnat = 4051300 Or rat.codnat = nat.codnat)
 Where s.status In ('A', 'R')
 Group By s.nucapsol, s.codusu, cap.codparctransp, par.nomeparc, cap.codveiculo,
          vei.placa || ' - ' || vei.marcamodelo, cap.codusuexc, s.dhsolicit, cap.dtagend, s.status,
					i.codcid, c.nomecid, e.tipo || ' ' || e.nomeend ,
          nvl(rat.codcencus, s.codcencus),b.nomebai,i.complemento,i.referencia,nvl(usu.codemp, rat.codemp),
					emp.razaosocial,nvl(rat.codnat, 4051300) , nat.descrnat, nvl(rat.codcencus, s.codcencus),
					cus.descrcencus, nvl(to_char(rat.percentual), 100) || '%',
          Case
            When i.tipotin = 'O' Then
             'Origem'
            When i.tipotin = 'D' Then
             'Destino'
            When i.tipotin = 'I' Then
             'Intermedíario'
          End
					);
