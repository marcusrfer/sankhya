create or replace view ad_vw_memomultafin as
(

Select
	m.Codmulcont,
	regexp_replace(f.codcencus,'([0-9]{3})([0-9]{3})([0-9]{3})','\1.\2.\3') codcencus,
	C2.Descrcencus,
	regexp_replace(f.codnat,'([0-9]{1})([0-9]{3})([0-9]{3})','\1.\2.\3') codnat,
	E.Razaosocial,
	ad_get.nuChaveDest('AD_MULCONTROL',m.codmulcont) nufin,
	Ad_get.Cnpjcpf(E.Cgc) cnpj,
	nvl(Case When Length(Replace(Inscestad, '-', '')) = 9 Then RegExp_Replace(Replace(Inscestad, '-', ''), '([0-9]{2})([0-9]{3})([0-9]{3})([0-9]{1})', '\1.\2.\3.\4') End,' ') IE,
	--Ad_get.Enderecocompleto('E', m.CODEMP, 0) || ' - ' || InItCap(B.Nomebai) || ', ' || Ad_get.Formatacep(E.Cep) || ' ' || InItCap(C.Nomecid) || '-' || t.Uf As endereco,
	Ad_get.Enderecocompleto('E', m.CODEMP, 0) As endereco,
	Ad_get.Formatatelefone(E.TELEFONE) TELEFONE,
	Ad_get.Formatatelefone(E.FAX) FAX,
	u.Nomeusucplt,
	m.Codempfin CODEMP,
	m.Ordemcarga,
	'      Providenciar pagamento ao ' || decode(m.pagotransp,'S',t.Nomeparc,p.nomeparc) || ', parceiro ' || decode(m.pagotransp,'S',m.codparctransp,m.Codparc) ||
	', no valor de ' || Trim(Ad_get.Formatavalor((Valormulta-m.Vlrdesconto))) ||
	' ( ' || Ad_get.Valorextenso((m.Valormulta-m.Vlrdesconto)) || ') referente infração "' || I.Descrinf || '"' ||
	' do veículo ' || RegExp_Replace(V.Placa, '([A-Z]{3})([0-9]{4})', '\1-\2')
	|| ', no dia ' || To_Char(m.Dtinfracao, 'DD/MM/YYYY') || ' em ' || m.Local
	|| ', no município de ' || C.Nomecid || ' - ' || t.Uf || ' com o auto de infração '
	|| m.Codautuacao || '.' As TEXTO
From Ad_mulcontrol m
	Left Join Ad_mulinf I On m.Codinfracao = I.Codinfracao
	Left Join Tgfvei V On V.Codveiculo = m.Codveiculo
	Left Join Tsicid C On m.Codcid = C.Codcid
	Left Join Tsiufs t On C.Uf = t.Coduf
	Join Tgfpar p On m.Codparc = p.Codparc
	Left Join tgfpar t On m.codparctransp = t.codparc
	Join Tsiemp E On E.CODEMP = m.CODEMP
	Join Tsiend N On E.Codend = N.Codend
	Join Tsibai B On E.Codbai = B.Codbai
	Join Tsiusu u On u.Codusu = Stp_get_codusulogado()
	Left Join ad_tblcmf cmf On m.codmulcont = cmf.nuchaveorig And cmf.nometaborig='AD_MULCONTROL'
	Join tgffin f On cmf.nuchavedest = f.nufin
	Join Tsicus C On C.Codcencus = f.Codcencus
	Join tsicus C2 On c2.codcencus = u.codcencuspad
 )
;
