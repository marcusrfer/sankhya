Create Or Replace Trigger AD_TRG_BIUD_TGFFIN_FRETE_SF
	Before Insert On SANKHYA.TGFFIN
	Referencing New As New Old As Old
	For Each Row
Declare

	/************************************************************************
  Autor: Marcus Rangel
  Processo: Frete Fob Coleta
  Objetivo: Preecher os valores no financeiro de acordo com a chave do CT-e,
  Alterar o centro de resultados e natureza do financeiro de acordo com a 
  informação do cabeçalho
  **************************************************************************/
	cab           tgfcab%Rowtype;
	cte           ad_vw_cteoobj%Rowtype;
	v_CodCenCus   Number;
	v_VlrFrete    Float;
	v_Peso        Float;
	v_PodeColetar Varchar2(10);
	v_Count       Int := 0;
Begin

	If inserting Then
	
		Select Nvl(ad_podecoletar, 'N') Into v_PodeColetar From tgfpar Where codparc = :new.Codparc;
	
		If :new.Desdobdupl = 'F' And :new.Origem = 'E' And :new.Recdesp = -1 And :new.Chavecte Is Not Null And
			 v_PodeColetar = 'S' And :new.nureneg Is Null Then
		
			Select Count(*) Into v_Count From ad_vw_cteoobj Where chave_acesso = :new.Chavecte;
		
			If v_Count <> 0 Then
				Select * Into cte From ad_vw_cteoobj Where chave_acesso = :new.Chavecte;
				Select codcencus Into v_CodCenCus From tgfcab Where nunota = :new.Nunota;
			Else
				Return;
			End If;
		
			v_VlrFrete := To_Number(Substr(cte.vlrcte, 1, Instr(cte.vlrcte, '.') - 1)) +
										(To_Number(Substr(cte.vlrcte, Instr(cte.vlrcte, '.') + 1, Length(cte.vlrcte))) / 100);
		
			v_Peso := To_Number(Substr(cte.peso, 1, Instr(cte.peso, '.') - 1)) +
								(To_Number(Substr(Substr(cte.peso, Instr(cte.peso, '.') + 1, Length(cte.peso)), 1, 2)) / 100);
		
			:new.Vlrdesdob := v_VlrFrete;
			:new.Codcencus := v_Codcencus;
			-- ACERTADO COM O MARCUS DEVIDO POSSURI N NATUREZAS 05/09/2017 BY RODRIGO
			--:new.Codnat    := get_tsipar_inteiro('CODNATPREFFRETE');
			:new.Historico := 'DESPESA DE FRETE REF. NF COMPRA ' || :new.numdupl;
			:new.Numnota   := To_Number(cte.Num_Doc_Fiscal);
		
			Begin
				Update tgfcab
					 Set peso = v_Peso, pesobruto = v_peso, vlrfrete = v_VlrFrete, chavecte = :new.Chavecte
				 Where nunota = :new.nunota;
			Exception
				When Others Then
					--Raise_Application_Error(-20105, ad_fnc_formataerro(Sqlerrm));
					ad_set.insere_msglog('Erro ao atualizar a cab nunota (' || :new.Nunota || ' - ' || Sqlerrm);
					Return;
			End;
		
			Begin
				Select codparc Into cab.codparc From tgfpar p Where p.cgc_cpf = cte.cnpj_emitente;
			
				If :new.Codparc <> cab.codparc Then
					:new.Codparc := cab.codparc;
					Update tgfcab Set codparctransp = cab.codparc Where nunota = :new.Nunota;
				End If;
			
			Exception
				When Others Then
					--Raise_Application_Error(-20105, 'Erro parceiro - ' || Sqlerrm);
					ad_set.insere_msglog('erro: Nunota ' || :new.Nunota || ' - ' || Sqlerrm);
					Return;
			End;
		
		End If;
	End If;
End;
/
