Create Or Replace Trigger AD_TRG_CMP_TSFADC_SF
		For Insert Or Update On SANKHYA.AD_TSFADC
		Referencing New As New Old As Old
		Compound Trigger

		/*
  * Autor: Marcus Rangel 
  * Processo: Posto de Combustível
  * Objetivo: Realizar o controle dos valores informados nas aferições, confrontando com a movimentação;
  */

		Type type_rec_adc Is Record(
				Dtref     Date,
				dhafer    Date,
				nrotanque Number,
				nrobomba  Number,
				tipo      Char(1),
				categoria Varchar2(10),
				turno     Varchar2(10),
				codprod   Number,
				qtdlitros Float,
				reset     Char(1));

		r_Adc type_rec_adc;

		Before Each Row Is
		Begin
		
				If inserting Or updating Then
				
						R_Adc.Dtref     := :New.Dtreferencia;
						r_adc.dhafer    := :New.Dhafericao;
						r_adc.nrotanque := :new.Nrotanque;
						r_adc.nrobomba  := :new.Bomba;
						r_adc.tipo      := :new.Tipo;
						r_adc.categoria := :new.Categoria;
						r_adc.turno     := :new.Turno;
						r_adc.codprod   := :new.Codprod;
						r_adc.qtdlitros := :new.Qtdlits;
						r_Adc.reset     := :new.Reset;
				
				End If;
		
		End Before Each Row;

		After Statement Is
				v_UltApont    Date;
				v_QtdUltApont Float;
				v_qtdsaida    Float;
				v_qtdent      Float;
				v_Newqtd      Float;
				v_Margem      Float;
		Begin
		
				/* se é abertura, procura o último fechamento
    * seja ele por bomba ou por tanque, pois não serão nulos
    * e não tenho movimentação fora da rotina
    */
		
				If ad_pkg_comb.ajuste_bomba Then
						Goto saida;
				End If;
		
				Select (Nvl(MARGEMDIFAFER, 0) / 100)
						Into v_Margem
						From ad_tsfppc p
					Where p.nuppc = 1;
		
				If r_adc.tipo = 'A' Then
				
						Begin
								Select a.qtdlits
										Into v_qtdultapont
										From ad_tsfadc a
									Where Nvl(a.nrotanque, 0) = Nvl(r_adc.nrotanque, 0)
											And a.codprod = r_adc.codprod
											And Nvl(a.bomba, 0) = Nvl(r_adc.nrobomba, 0)
											And a.tipo = 'F'
											And a.categoria = r_adc.categoria
											And a.dhafericao = (Select Max(c.dhafericao)
																																	From ad_tsfadc c
																																Where c.nrotanque = a.nrotanque
																																		And c.bomba = a.bomba
																																		And a.codprod = c.codprod
																																		And a.tipo = c.tipo
																																		And A.Categoria = C.Categoria
																																		And C.Dhafericao < R_Adc.Dhafer
																															--To_Date(R_Adc.Dhafer, 'dd/mm/yyyy hh24:mi:ss')
																															);
						Exception
								When no_data_found Then
										v_qtdultapont := 0;
								When too_many_rows Then
										Raise_Application_Error(-20105,
																																		'Verifique os dados pois foram encontrado mais de uma abertura/fechamento para esta data!!!');
						End;
				
						If v_qtdultapont > 0 And v_qtdultapont != r_adc.qtdlitros Then
								Raise_Application_Error(-20105,
																																fc_formatahtml(p_mensagem => 'Existe diferença entre a quantidade informada no fechamento. (' ||
																																																													v_qtdultapont || ')',
																																															p_motivo   => 'Divergência de valores',
																																															p_solucao  => 'Verifique a quantidade informada no último fechamento'));
						End If;
						-- se for fechamento
						-- busca o valor da abertura e nesse caso eu tenho movimentação
						-- seja compra ou abastecimento
						-- as compras sempre são por tanque
						-- as requisições são por bomba (0 quando nulo)
				Else
				
						Begin
								Select Round(a.qtdlits), a.dhafericao
										Into v_qtdultapont, v_ultapont
										From ad_tsfadc a
									Where Nvl(a.nrotanque, 0) = Nvl(r_adc.nrotanque, 0)
											And a.codprod = r_adc.codprod
											And a.bomba = r_adc.nrobomba
											And a.turno = r_adc.turno
											And a.tipo = 'A'
											And a.categoria = r_adc.categoria
											And a.dhafericao = (Select Max(c.dhafericao)
																																	From ad_tsfadc c
																																Where Nvl(c.nrotanque, 0) = Nvl(a.nrotanque, 0)
																																		And c.bomba = a.bomba
																																		And c.codprod = a.codprod
																																		And c.tipo = a.tipo
																																		And c.Turno = a.Turno
																																		And c.categoria = a.categoria
																																		And c.dhafericao < r_adc.dhafer);
						Exception
								When no_data_found Then
										Raise_Application_Error(-20105,
																																		ad_fnc_formataerro('Quantidade da abertura não foi encontrada.'));
						End;
				
						-- se por tanque, pega a abertura, entradas, saídas para compor o valor final
						If r_adc.categoria = 'T' Then
						
								v_qtdent := ad_pkg_comb.saldo_estoque_turno(p_codemp   => 2,
																																																				p_codprod  => r_adc.codprod,
																																																				p_codlocal => 3300,
																																																				p_controle => 'POSTOABAST',
																																																				p_dtini    => v_ultapont,
																																																				p_dtfim    => R_Adc.Dhafer,
																																																				p_tipo     => 'E');
						
								v_qtdsaida := ad_pkg_comb.saldo_estoque_turno(p_codemp   => 2,
																																																						p_codprod  => r_adc.codprod,
																																																						p_codlocal => 3300,
																																																						p_controle => 'POSTOABAST',
																																																						p_dtini    => v_ultapont,
																																																						p_dtfim    => R_Adc.Dhafer,
																																																						p_tipo     => 'S');
						
								v_Newqtd := v_qtdultapont + v_qtdsaida + v_qtdent;
						
								--- comentado a pedido do paulo o.s 23479 by rodrigo dia 11/12/2017
						
								/*
        If v_newqtd Not Between (r_adc.qtdlitros * (1 - v_margem)) And
               (r_adc.qtdlitros * (1 + v_margem)) Then
              Raise_Application_Error(-20105,
                                      ad_fnc_formataerro('Quantidade de Fechamento diferente do esperado (Qtde. Abertura + Entradas - Abastecimentos). ' ||
                                                         v_newqtd));
            End If;
        */
						Else
								-- se por bomba, pega abertura mais o que saiu na bomba
								v_qtdsaida := ad_pkg_comb.saldo_estoque(p_codemp   => 2,
																																																p_codprod  => r_adc.codprod,
																																																p_codlocal => 3300,
																																																p_controle => 'POSTOABAST',
																																																p_NroBomba => r_adc.nrobomba,
																																																p_dtini    => v_ultapont,
																																																p_dtfim    => R_Adc.Dhafer,
																																																p_tipo     => 'S');
						
								v_newqtd := v_qtdultapont + Abs(Round(v_qtdsaida));
						
								If v_newqtd Not Between (r_adc.qtdlitros * (1 - v_margem)) And
											(r_adc.qtdlitros * (1 + v_margem)) And Nvl(r_Adc.reset, 'N') = 'N' Then
										Raise_Application_Error(-20105, ad_fnc_formataerro('Quantidade diferente'));
								End If;
						
						End If;
				
				End If;
				<<saida>>
				Null;
		
		End After Statement;

End AD_TRG_CMP_TSFADC_SF;
/
