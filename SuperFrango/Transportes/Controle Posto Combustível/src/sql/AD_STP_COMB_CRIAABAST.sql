Create Or Replace Procedure AD_STP_COMB_CRIAABAST(v_date Date) Is
	v_OrdemCarga Number;
	v_Codreg     Number;
Begin
	/*
  * Autor: Marcus Rangel
  * Processo: Posto de combustível
  * Objetivo: Procedure utilizada em um job para criação/atualização da base de dados utilizadas em dashboard da gerência de abastecimento e da viabilidade do posto
  */

	Begin
		Delete From Ad_tsfabast
		 Where Trunc(dtentsai) = v_date;
	Exception
		When Others Then
			Ad_set.Insere_msglog('Erro ao excluir lançamentos existentes na tabela base de abastecimento.');
	End;

	For T In (Select cab.Nunota,
									 cab.Dtentsai,
									 cab.Dtneg,
									 cab.Codemp,
									 cab.Codtipoper,
									 ad_pkg_comb.Veiculo(cab.codveiculo) codveiculo,
									 CAT.Codcat,
									 CAT.Categoria,
									 cab.Codparc,
									 ite.Qtdneg qtdlitros
							From Tgfite ite
							Join Tgfcab cab
								On ite.Nunota = cab.Nunota
							Join Tgfvei vei
								On ad_pkg_comb.Veiculo(cab.codveiculo) = vei.codveiculo
							 And Nvl(Ad_controlakm, 'N') = 'S'
							Left Join Ad_tsfcat CAT
								On vei.Ad_codcat = CAT.Codcat
							Join Ad_tsfppcp ppc
								On ite.Codprod = ppc.Codprod
							Join Ad_tsfppct ppt
								On cab.Codtipoper = ppt.Codtipoper
						 Where Tipmov = 'Q'
							 And cab.Codemp = 2
							 And cab.codveiculo <> 0
							 And Trunc(cab.dtentsai) = To_Date(v_date))
	Loop
		Begin
			v_Ordemcarga := ad_pkg_comb.Get_ordemcarga(T.Nunota);
		
			If v_OrdemCarga <> 0 Then
				v_Codreg := ad_pkg_comb.Get_codreg(T.Codemp, v_OrdemCarga);
			Else
				v_Codreg := 0;
			End If;
		
		End;
	
		Begin
			Insert Into Ad_tsfabast
				(Nunota, Dtentsai, Dtneg, Codemp, Codtipoper, Codveiculo, Ordemcarga, Codreg, Codcat, Categoria, Codparc,
				 Qtdlitros)
			Values
				(T.Nunota, T.Dtentsai, T.Dtneg, T.Codemp, T.Codtipoper, T.Codveiculo, v_Ordemcarga, v_Codreg, T.Codcat,
				 T.Categoria, T.Codparc, T.Qtdlitros);
		
			Commit;
		
		Exception
			When Others Then
			
				Dbms_output.Put_line('Erro ao inserir - ' || Sqlerrm);
				Ad_set.Insere_msglog('Erro ao inserir lançamentos na tabela base de abastecimento. ' || Sqlerrm);
				Continue;
		End;
	
	End Loop;
Exception
	When Others Then
		Dbms_output.Put_line('Erro ao inserir - ' || Sqlerrm);
		Rollback;
End;
/
