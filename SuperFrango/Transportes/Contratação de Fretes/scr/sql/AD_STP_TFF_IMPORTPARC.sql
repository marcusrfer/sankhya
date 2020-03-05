Create Or Replace Procedure ad_ImpParcTranspNome(P_CODUSU    Number,
																								 P_IDSESSAO  Varchar2,
																								 P_QTDLINHAS Number,
																								 P_MENSAGEM  Out Varchar2) As
	pNomeParc Varchar2(4000);
	vNutab    Number;
	vNutrf    Number;
	vCount    Int := 0;
Begin
	/*
  Autor: Marcus Rangel
  Objetivo: Permitir a importação dos parceiros pelo nome na tela de cadastro
  das tabelas de preço do frete fob
  */

	pNomeParc := Nvl(ACT_TXT_PARAM(P_IDSESSAO, 'NOMEPARC'), 'tnt');
	pNomeParc := '%' || pNomeParc || '%';

	vNutab := Nvl(ACT_INT_FIELD(P_IDSESSAO, 0, 'MASTER_NUTAB'), 1);
	vNutrf := Nvl(ACT_INT_FIELD(P_IDSESSAO, 0, 'NUTRF'), 0);

	Select Nvl(Max(t.nutrf), 0) + 1 Into vNutrf From ad_tsftrf t Where t.nutab = vNutab;

	For Par In (Select codparc, ad_get.cnpjcpf(p.cgc_cpf) cgc_cpf, p.telefone, p.email
								From tgfpar p
							 Where ativo = 'S'
								 And p.transportadora = 'S'
								 And Upper(nomeparc) Like Upper(pNomeParc)
								 And 0 = (Select Count(*)
														From AD_TSFTRF F
													 Inner Join ad_tsftff t On f.nutab = t.nutab
													 Where p.CODPARC = F.CODPARC
														 And t.ativo = 'S'))
	Loop
		vCount := vCount + 1;
		Begin
			Insert Into ad_tsftrf (nutab, nutrf, codparc) Values (vNutab, vNutrf, par.codparc);
			vnutrf := vNutrf + 1;
		Exception
			When Others Then
				Continue;
		End;
	End Loop;

	P_MENSAGEM := vCount || ' Parceiros incluídos com sucesso. ';
End;
/
