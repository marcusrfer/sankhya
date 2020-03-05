Create Or Replace Procedure AD_STP_COMB_CRIAKMROD(v_Data Date) Is
	v_DtEntSai Date;
Begin
	/*
  * Autor: Marcus Rangel
  * Processo: Posto de combustível
  * Objetivo: Procedure utilizada em um job para criação/atualização da base de dados utilizadas em dashboard da gerência de abastecimento e da viabilidade do posto
  */
	Begin
		Delete From Ad_tsfkmr
		 Where Dtneg = v_Data;
	Exception
		When Others Then
			Ad_set.Insere_msglog('Erro ao excluir lançamentos existentes na tabela base km rodado.');
	End;

	For I In (
						
						/*Select Sysdate As dtneg,
                                                                                            1 As codemp,
                                                                                            1 As codcat,
                                                                                            'Teste' As categoria,
                                                                                            0 As codveiculo,
                                                                                            0 As ordemcarga,
                                                                                            0 As Codparctransp,
                                                                                            0 As codreg,
                                                                                            0 As distancia
                                                                                      From dual*/
						Select cab.Dtneg,
										cab.Codemp,
										CAT.Codcat,
										CAT.Categoria,
										ad_pkg_comb.Veiculo(cab.codveiculo) codveiculo,
										cab.Ordemcarga,
										cab.Codparctransp,
										P.Codreg,
										Case
											 When cab.Ordemcarga = 0 And Nvl(R.distancia, 0) = 0 Then
												Ad_get.Distanciacidade(E.Codcid, P.Codcid) * 2
											 When cab.Ordemcarga <> 0 And Nvl(R.distancia, 0) <> 0 Then
												R.distancia
											 When cab.Ordemcarga <> 0 And Nvl(R.distancia, 0) = 0 Then
												Ad_get.Distanciacidade(E.Codcid, P.Codcid) * 2
											 Else
												Ad_get.Distanciacidade(E.Codcid, P.Codcid) * 2
										 End As distancia
							From Tgfcab cab
							Join Tgfvei vei
								On ad_pkg_comb.Veiculo(cab.codveiculo) = vei.codveiculo
							 And Nvl(Ad_controlakm, 'N') = 'S'
							Left Join Ad_tsfcat CAT
								On vei.Ad_codcat = CAT.Codcat
							Join Tgford o
								On cab.Ordemcarga = o.Ordemcarga
							 And cab.Codemp = o.Codemp
							Left Join Tgfrot R
								On o.Codrota = R.Codrota
							Join Tgfpar P
								On cab.Codparc = P.Codparc
							Join Tsiemp E
								On cab.Codemp = E.Codemp
						 Where Tipmov In ('V', 'T', 'N', 'C')
							 And Dtneg = v_Data
						 Group By cab.Dtneg,
											 cab.Codemp,
											 CAT.Codcat,
											 CAT.Categoria,
											 ad_pkg_comb.veiculo(cab.codveiculo),
											 cab.Ordemcarga,
											 cab.Codparctransp,
											 P.Codreg,
											 Case
												 When cab.Ordemcarga = 0 And Nvl(R.distancia, 0) = 0 Then
													Ad_get.Distanciacidade(E.Codcid, P.Codcid) * 2
												 When cab.Ordemcarga <> 0 And Nvl(R.distancia, 0) <> 0 Then
													R.distancia
												 When cab.Ordemcarga <> 0 And Nvl(R.distancia, 0) = 0 Then
													Ad_get.Distanciacidade(E.Codcid, P.Codcid) * 2
												 Else
													Ad_get.Distanciacidade(E.Codcid, P.Codcid) * 2
											 End
						
						)
	
	Loop
		Begin
			Delete From ad_tsfkmr
			 Where dtneg = i.dtneg
				 And codemp = i.codemp
				 And ordemcarga = i.ordemcarga
				 And codveiculo = i.codveiculo;
		Exception
			When Others Then
				Ad_set.Insere_msglog('Erro ao excluir registro de km rodado. ' || Sqlerrm);
		End;
	
		v_DtEntSai := fc_saida_veic_sf(i.codemp, i.ordemcarga);
	
		Begin
			Insert Into Ad_tsfkmr
				(Dtneg, Codemp, Codcat, Categoria, Codveiculo, Ordemcarga, Codreg, Distancia, Dtentsai, Codparc)
			Values
				(I.Dtneg, I.Codemp, I.Codcat, I.Categoria, I.Codveiculo, I.Ordemcarga, I.Codreg, I.Distancia, v_DtEntSai,
				 i.Codparctransp);
		Exception
			When Others Then
				Ad_set.Insere_msglog('Erro ao inserir registro de km rodado. ' || Sqlerrm);
		End;
	End Loop;

	Commit;

End;
/
