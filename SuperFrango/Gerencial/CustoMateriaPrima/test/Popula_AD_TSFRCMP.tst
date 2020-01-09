PL/SQL Developer Test script 3.0
107
Declare
		p_dtini     Date;
		p_dtfim     Date;
		p_codprod   Number;
		v_dias      Int;
		v_sysdate   Date;
		v_Desconto  Float := 0;
		v_temLancto Boolean Default False;

		Type tipo_result_customp Is Table Of ad_tsfrcmp%Rowtype;
		t tipo_result_customp := tipo_result_customp();
		i Int;
		
Begin
		p_dtini   := '01/02/2019';
		p_dtfim   := Last_Day(p_dtini) + 1;
		v_sysdate := p_dtini;
		v_dias    := p_dtfim - p_dtini;
		p_codprod := 10001;

		Delete From ad_tsfrcmp
			Where dtentsai >= p_dtini
					And dtentsai <= p_dtfim;

		For d In 1 .. v_dias
		Loop
				t.extend;
				i := t.last;
		
				v_temLancto := False;
		
				For m In (Select *
																From ad_vw_estoqmp e
															Where e.dtentsai = v_sysdate
																	And e.codprod = p_codprod)
				Loop
				
						v_temLancto := True;
				
						t(i).dtentsai := m.dtentsai;
						t(i).codprod := m.codprod;
						t(i).qtdtotsc := m.qtdneg / 60;
						t(i).vlrsaca := ad_get.Valorprodcontrato(m.numcontrato, m.codprod) * 60;
						t(i).vlrtotsc := t(i).qtdtotsc * t(i).vlrsaca;
						t(i).vlrtotfrete := m.vlrfrete;
						t(i).vlrfretesc := m.vlrfrete / t(i).qtdtotsc;
				
						For l In (Select Avg(i.umidade) umidade, amz.codtdc
																		From ad_itecargto i
																		Join ad_contcargto c
																				On i.sequencia = c.sequencia
																		Left Join tgfcab cab
																				On cab.nunota = i.nunota
																		Left Join tcscon amz
																				On cab.numcontrato = amz.numcontrato
																	Where i.codprod = m.codprod
																			And i.codparc = m.codparc
																			And i.nunotaorig = m.numcontrato
																			And i.cancelado = 'NÃO'
																	Group By amz.codtdc)
						Loop
								Begin
										Select r.descontar
												Into v_Desconto
												From tgardc r
											Where r.codtdc = l.codtdc
													And r.vlrobtido = l.umidade;
								Exception
										When no_data_found Then
												v_desconto := 0;
								End;
						End Loop l;
				
						t(i).vlrdescumidade := ((t(i).vlrsaca * t(i).qtdtotsc) * (Case
																															When v_Desconto > 0 Then
																																1
																															Else
																																0
																													End + (v_Desconto / 100)) / t(i).qtdtotsc / 60);
				
						t(i).vlrtotarmz := 0;
						t(i).vlrarmzsc := 0;
						t(i).vlrcusto := t(i).vlrsaca + t(i).vlrfretesc + t(i).vlrdescumidade;
				
				End Loop m;     
		
				v_sysdate := v_sysdate + 1;
		
		End Loop d;

		Begin
				Forall x In t.first .. t.last Save Exceptions
						Insert Into ad_tsfrcmp Values t (x);
		Exception
				When Others Then
						i := Sql%Bulk_Exceptions.count;
				
						Dbms_Output.Put_Line('Qtde Erros: ' || x);
				
						For e In 1 .. i
						Loop
								Dbms_Output.Put_Line('   Erro: ' || e || ' Array index: ' || Sql%Bulk_Exceptions(e).error_index ||
																													' Msg: ' || Sqlerrm(-Sql%Bulk_Exceptions(e).error_code));
						End Loop;
		End;

End;
0
0
