Create Or Replace Package AD_PKG_EST Is

		-- Author  : MARCUS RANGEL
		-- Created : 27/02/2019 08:51:04
		-- Purpose : Agrupar todos os objetos utlizados no processo de cálculo do estoque estratégico

		-- Função que retorna o valor do evento
		Function get_valor_evento(p_codeee Number, p_dtref Date, p_codprod Number) Return Float;

		Procedure set_base_est(p_dtini     Date,
																									p_dtfin     Date,
																									p_codprod   Number,
																									p_eventopai Number Default Null,
																									p_evento    Number Default Null);

		Function get_estoque_armz(p_referencia Date, p_codprod In Number, p_tipo In Varchar2) Return Float;

		Function get_estoque_fab(p_dtini Date, p_dtfin Date, p_codprod Number, p_tipo Char) Return Float;

		Function get_consumo_med(p_evento Number, p_dtini Date, p_dtfin Date, p_codprod Number) Return Float;

		Function get_soma_evento(p_evento Number, p_dtini Date, p_dtfin Date, p_codprod Number) Return Float;

		Function get_valor_armz(p_dtref Date) Return Float;

		Function get_valor_hedge(p_dtini Date, p_dtfin Date, p_produto Varchar2) Return Float;

End AD_PKG_EST;
/
Create Or Replace Package Body ad_pkg_est Is

		-- author  : marcus rangel
		-- created : 27/02/2019 08:51:04
		-- purpose : agrupar todos os objetos utlizados no processo de cálculo do estoque estratégico

		Function get_valor_evento(p_codeee Number, p_dtref Date, p_codprod Number) Return Float Is
				v_result Float;
		Begin
				Select ree.vlrevento
						Into v_result
						From ad_tsfree ree
					Where ree.dtref = p_dtref
							And ree.codprod = p_codprod
							And ree.codeee = p_codeee;
		
				Return v_result;
		Exception
				When no_data_found Then
						Return 0;
		End;

		Function get_consumo_med(p_evento Number, p_dtini Date, p_dtfin Date, p_codprod Number) Return Float Is
				v_media Float;
		Begin
				Select Avg(vlrevento)
						Into v_media
						From ad_tsfree r
					Where r.codeee = p_evento
							And r.dtref Between p_dtini And p_dtfin
							And r.codprod = p_codprod;
		
				Return Round(v_media, 4);
		
		Exception
				When no_data_found Then
						Return 0;
		End get_consumo_med;

		Function get_soma_evento(p_evento Number, p_dtini Date, p_dtfin Date, p_codprod Number) Return Float Is
				v_soma Float;
		Begin
				Select Sum(vlrevento)
						Into v_soma
						From ad_tsfree r
					Where r.codeee = p_evento
							And r.dtref Between p_dtini And p_dtfin
							And r.codprod = p_codprod;
		
				Return Round(v_soma, 4);
		
		Exception
				When no_data_found Then
						Return 0;
		End get_soma_evento;

		Function get_estoque_armz(p_referencia Date, p_codprod In Number, p_tipo Varchar2) Return Float Is
				total_entradas_ssa   Float;
				total_saidas_ssa     Float;
				total_entradas_capt  Float;
				total_saidas_capt    Float;
				total_entradas_scapt Float;
				total_saidas_scapt   Float;
				saldo                Float;
				saldo_anterior       Float;
				v_result             Float;
		Begin
				/* p_tipo
    **1 = total_entradas_ssa,
    **2 = total_saidas_ssa,
    **3 = total_entradas_capt,
    **4 = total_saidas_capt,
    **5 = total_entradas_scapt ,
    **6 = total_saidas_scapt ,
    **7 = saldo
    **A = Anterior
    */
				If p_tipo = 'A' Then
						Select Nvl(Sum(Case
																							When cab.codtipoper In (622, 628, 150, 638) Then
																								ite.qtdneg
																							Else
																								0
																					End), 0) - Nvl(Sum(Case
																																										When cab.codtipoper In (633, 635, 636, 151, 433) Then
																																											ite.qtdneg
																																										Else
																																											0
																																								End), 0)
								Into saldo_anterior
								From tgfcab cab,
													tgfite ite,
													tcscon con,
													tgasaf saf,
													tgfloc loc,
													tgfpro pro
							Where cab.nunota = ite.nunota
									And cab.numcontrato = con.numcontrato
									And con.codsaf = saf.codsaf
									And ite.codlocalorig = loc.codlocal
									And ite.codprod = pro.codprod
									And cab.codtipoper In (622, 628, 633, 635, 636, 151, 433, 638)
									And cab.statusnota = 'L'
									And ite.codemp In (3, 4, 18)
									And saf.descricao Like '%' || To_Char(Substr(p_referencia, 7, 2)) || '%'
									And Trunc(cab.dtfatur, 'mm') < p_referencia
									And ite.codprod = p_codprod;
				Else
						Select Nvl(Sum(Case
																							When cab.codparc = 57 And cab.codtipoper In (622, 628, 638, 150) Then
																								ite.qtdneg
																							Else
																								0
																					End), 0),
													Nvl(Sum(Case
																							When cab.codparc = 57 And cab.codtipoper In (633, 635, 636, 433, 151) Then
																								ite.qtdneg
																							Else
																								0
																					End), 0),
													
													Nvl(Sum(Case
																							When Nvl(con.nunota, 0) > 0 And cab.codparc Not In (57) And
																												cab.codtipoper In (622, 628, 638, 150) Then
																								ite.qtdneg
																							Else
																								0
																					End), 0),
													Nvl(Sum(Case
																							When Nvl(con.nunota, 0) > 0 And cab.codparc Not In (57) And
																												cab.codtipoper In (633, 635, 636, 151, 433) Then
																								ite.qtdneg
																							Else
																								0
																					End), 0),
													
													Nvl(Sum(Case
																							When Nvl(con.nunota, 0) = 0 And cab.codparc Not In (57) And
																												cab.codtipoper In (622, 628, 638, 150) Then
																								ite.qtdneg
																							Else
																								0
																					End), 0),
													Nvl(Sum(Case
																							When Nvl(con.nunota, 0) = 0 And cab.codparc Not In (57) And
																												cab.codtipoper In (633, 635, 636, 151, 433) Then
																								ite.qtdneg
																							Else
																								0
																					End), 0),
													
													Nvl(Sum(Case
																							When cab.codtipoper In (622, 628, 150, 638) Then
																								ite.qtdneg
																							Else
																								0
																					End), 0) - Nvl(Sum(Case
																																										When cab.codtipoper In (633, 635, 636, 151, 433) Then
																																											ite.qtdneg
																																										Else
																																											0
																																								End), 0)
								Into total_entradas_ssa,
													total_saidas_ssa,
													total_entradas_capt,
													total_saidas_capt,
													total_entradas_scapt,
													total_saidas_scapt,
													saldo
								From tgfcab cab,
													tgfite ite,
													tcscon con,
													tgasaf saf,
													tgfloc loc,
													tgfpro pro
							Where cab.nunota = ite.nunota
									And cab.numcontrato = con.numcontrato
									And con.codsaf = saf.codsaf
									And ite.codlocalorig = loc.codlocal
									And ite.codprod = pro.codprod
									And cab.codtipoper In (622, 628, 633, 635, 636, 151, 433, 638)
									And cab.statusnota = 'L'
									And ite.codemp In (3, 4, 18)
									And saf.descricao Like '%' || To_Char(Substr(p_referencia, 7, 2)) || '%'
									And Trunc(cab.dtfatur, 'mm') = p_referencia
									And ite.codprod = p_codprod;
				
				End If;
		
				If p_tipo = '1' Then
						v_result := total_entradas_ssa;
				Elsif p_tipo = '2' Then
						v_result := total_saidas_ssa;
				Elsif p_tipo = '3' Then
						v_result := total_entradas_capt;
				Elsif p_tipo = '4' Then
						v_result := total_saidas_capt;
				Elsif p_tipo = '5' Then
						v_result := total_entradas_scapt;
				Elsif p_tipo = '6' Then
						v_result := total_saidas_scapt;
				Elsif p_tipo = '7' Then
						v_result := saldo;
				Elsif p_tipo = 'A' Then
						v_result := saldo_anterior;
				Else
						v_result := 0;
				End If;
		
				Return v_result;
		
		End get_estoque_armz;

		Function get_estoque_fab(p_dtini Date, p_dtfin Date, p_codprod Number, p_tipo Char) Return Float Is
				v_result Float;
				sufixo   Varchar2(1000);
				stmt     Varchar2(32000);
		Begin
				/*
    anterior a
    qtdentradas e
    qtddeventradas de
    qtdsaidas  s
    qtddevsaidas ds
    qtdquebra  q
    qtdformulados f
    saldo_atual    r
    */
		
				sufixo := ' And codemp = 2' || ' And codlocalorig between 4000 and 4999' ||
														' And dtreferencia between :dat1 and :dat2' || ' And codprod = :codprod';
		
				If p_tipo = 'A' Then
						Select Round(Sum(qtdneg * atualestoque), 2)
								Into v_result
								From tgfese
							Where codemp = 2
									And codlocalorig Like '4%'
									And dtreferencia < p_dtini
									And codprod = p_codprod;
				Elsif p_tipo = 'E' Then
						stmt := 'Select sum(qtdneg * atualestoque) ' || 'From tgfese ' ||
														'Where tipmov in (''C'', ''T'', ''F'')' || ' And codtipoper Not In (331,334,150)' ||
														' And atualestoque = 1' || sufixo;
				Elsif p_tipo = 'DE' Then
						stmt := 'Select Sum(qtdneg) ' || ' From tgfese' || '	Where tipmov = ''E'' ' || sufixo;
				
				Elsif p_tipo = 'S' Then
						stmt := 'Select sum(qtdneg * atualestoque) ' || 'From tgfese ' ||
														'Where (tipmov In (''Q'',''T'',''V'') Or codtipoper = 603) ' ||
														' And codtipoper Not In (153,334,151) ' || ' And atualestoque = -1 ' || sufixo;
				Elsif p_tipo = 'DS' Then
						stmt := 'Select sum(qtdneg*atualestoque) ' || ' From tgfese ' || ' Where codtipoper=334 ' ||
														' And atualestoque = 1 ' || sufixo;
				Elsif p_tipo = 'Q' Then
						stmt := 'Select sum(qtdneg*atualestoque) ' || 'From tgfese ' || ' Where codtipoper In (150,151,153) ' ||
														sufixo;
				Elsif p_tipo = 'F' Then
						stmt := 'Select sum(qtdneg*atualestoque) ' || ' From tgfese ' ||
														' Where codtipoper In (804,805,806,830,819,803) ' || ' And atualestoque = -1 ' || sufixo;
				Elsif p_tipo = 'R' Then
						Select Round(Sum(qtdneg * atualestoque), 2)
								Into v_result
								From tgfese
							Where codemp = 2
									And codlocalorig Like '4%'
									And dtreferencia <= p_dtfin
									And codprod = p_codprod;
				End If;
		
				If v_result Is Null Then
						Begin
								Execute Immediate stmt
										Into v_result
										Using Nvl(p_dtini, '01/01/1900'), p_dtfin, p_codprod;
						Exception
								When Others Then
										Dbms_Output.Put_Line(stmt || ' - ' || Sqlerrm);
										v_result := 0;
						End;
				
				End If;
		
				Return Nvl(v_result, 0);
		
		End get_estoque_fab;

		Function get_valor_armz(p_dtref Date) Return Float Is
				v_result Float;
		Begin
				Select Nvl(Sum(c.vlrnota), 0)
						Into v_result
						From tgfcab c
					Where c.codtipoper = 610
							And c.dtneg Between Add_Months(To_Date(To_Char(p_dtref, 'dd/mm/yyyy'), 'dd/mm/yyyy'), -1) + 14 And
											To_Date(To_Char(p_dtref, 'dd/mm/yyyy'), 'dd/mm/yyyy') + 13;
		
				Return v_result;
		
		Exception
				When Others Then
						Return 0;
		End get_valor_armz;

		Function get_valor_hedge(p_dtini Date, p_dtfin Date, p_produto Varchar2) Return Float Is
				v_result Float;
		Begin
		
				Select Sum((Select Case
																								When c.tipo = 'FUTURO' Then
																									((Select Sum(cp.strikeentrada * cp.numcontratos *
																																						Decode(pr.tipoliq, 'US', cp.cotacaoent, 1))
																													From ad_hdcontratoscompras cp
																												Where cp.corretora = c.corretora
																														And cp.idopcao = c.idopcao
																														And cp.caixa = 'S') * pr.qtd) -
																									((Select Sum(st.strikesaida * st.qtdcontratos *
																																						Decode(pr.tipoliq, 'US', st.cotaobaixa, 1))
																													From ad_hdcontratosstrike st
																												Where st.corretora = c.corretora
																														And st.idopcao = c.idopcao
																														And st.caixa = 'S') * pr.qtd)
																								Else
																									((Select Sum(cp.strikeentrada * cp.numcontratos *
																																						Decode(pr.tipoliq, 'US', cp.cotacaoent, 1))
																													From ad_hdcontratoscompras cp
																												Where cp.corretora = c.corretora
																														And cp.idopcao = c.idopcao
																														And cp.caixa = 'S') * pr.qtd)
																						End * Decode(c.cv, 'C', -1, 1) As saldo
																	From ad_hdcontratos c
																Inner Join ad_hdbolsaprod pr
																			On pr.idbolsa = c.idbolsa
																		And pr.idproduto = c.idproduto
																Where c.idopcao = h.idopcao
																		And c.corretora = h.corretora
																		And c.statusop = 'F'))
						Into v_result
						From ad_hdcontratos h
						Join ad_hdbolsaprod bol
								On bol.idbolsa = h.idbolsa
							And bol.idproduto = h.idproduto
					Where Trunc(dtexpiracao, 'mm') Between p_dtini And p_dtfin
							And Upper(bol.descricao) = Upper(p_produto);
		
				Return v_result;
		
		Exception
				When Others Then
						Return 0;
		End;

		Procedure set_base_est(p_dtini     Date,
																									p_dtfin     Date,
																									p_codprod   Number,
																									p_eventopai Number Default Null,
																									p_evento    Number Default Null) Is
				stmt        Varchar2(32000);
				v_vlrresult Float;
				v_numree    Int;
				--i           Int := 0;
		Begin
		
				-- percorre o período mês a mês
				For m In (Select To_Date(To_Char(Add_Months(p_dtini, Level - 1), 'dd/mm/yyyy'), 'dd/mm/yyyy') dtref
																From dual
														Connect By Level <= Months_Between(Add_Months(p_dtfin, 1), p_dtini))
				Loop
				
						Dbms_Output.Put_Line(m.dtref);
				
						/* 
      i := i + 1;
      if i > 1 then
        return;
      end if;
      */
				
						-- percorre os eventos pai
						For ep In (Select *
																			From ad_tsfeee
																		Where analitico = 'N'
																				And query Is Not Null
																				And (codeee = p_eventopai Or Nvl(p_eventopai, 0) = 0)
																		Order By codeee)
						Loop
						
								Begin
										Select Nvl(Max(nuree), 0) + 1 Into v_numree From ad_tsfree;
								
										Merge Into ad_tsfree e
										Using (Select m.dtref dtref,
																								ep.codeee codeee,
																								p_codprod codprod
																			From dual) d
										On (e.dtref = d.dtref And e.codeee = d.codeee And e.codprod = d.codprod)
										When Not Matched Then
												Insert
														(nuree, dtref, codeee, codprod, vlrevento)
												Values
														(v_numree, d.dtref, d.codeee, d.codprod, 0);
								Exception
										When dup_val_on_index Then
												Raise_Application_Error(-20105, m.dtref || ' - ' || ep.codeee);
										When Others Then
												Raise_Application_Error(-20105, Sqlerrm);
								End;
						
								For ef In (Select *
																					From ad_tsfeee e
																				Where e.codeeepai = ep.codeee
																						And analitico = 'S'
																						And query Is Not Null
																						And (e.codeee = p_evento Or Nvl(p_evento, 0) = 0)
																				Order By e.codeee)
								Loop
								
										If ef.query Is Null Then
												Continue;
										End If;
								
										-- preparação da query
										If Nvl(ef.calculado, 'N') = 'N' Then
												stmt := Replace(ep.query, ':FORMULA', ef.query);
										Else
										
												stmt := ef.query;
										
												If ef.query Like '%VALOR(%' Then
														stmt := Replace(stmt, 'VALOR(', 'AD_PKG_EST.GET_VALOR_EVENTO(');
												End If;
										
												If ef.query Like '%MEDIA(%' Then
														stmt := Replace(stmt, 'MEDIA(', 'AD_PKG_EST.GET_CONSUMO_MED(');
												End If;
										
												If ef.query Like '%SOMA(%' Then
														stmt := Replace(stmt, 'SOMA(', 'AD_PKG_EST.GET_SOMA_EVENTO(');
												End If;
										
												stmt := 'Select ' || stmt || ' from dual';
										
										End If;
								
										stmt := Replace(stmt, ':DTREF', '''' || m.dtref || '''');
										stmt := Replace(stmt, ':CODPROD', p_codprod);
										stmt := Replace(stmt, ':DTINI', '''' || p_dtini || '''');
										stmt := Replace(stmt, ':DTFIN', '''' || p_dtfin || '''');
										-- execução da query, obtenção do valor do evento
										Begin
												Execute Immediate stmt
														Into v_vlrresult;
										Exception
												When Others Then
														Raise_Application_Error(-20101,
																																						'Erro (' || Sqlerrm ||
																																							') ao executar a consulta da fórmula para obtenção do valor do evento: ' ||
																																							ef.codeee || ', no período :' || m.dtref);
										End;
								
										Select Nvl(Max(nuree), 0) + 1 Into v_numree From ad_tsfree;
								
										Merge Into ad_tsfree e
										Using (Select m.dtref dtref,
																								ef.codeee codeee,
																								p_codprod codprod,
																								Round(v_vlrresult, 4) vlrevento
																			From dual) d
										On (e.dtref = d.dtref And e.codeee = d.codeee And e.codprod = d.codprod)
										When Matched Then
												Update Set vlrevento = d.vlrevento
										When Not Matched Then
												Insert
														(nuree, dtref, codeee, codprod, vlrevento)
												Values
														(v_numree, d.dtref, d.codeee, d.codprod, d.vlrevento);
								
								End Loop ef;
						
						End Loop ep;
				
				End Loop m;
		
		End set_base_est;

End ad_pkg_est;
/
