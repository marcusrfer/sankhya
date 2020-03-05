Create Or Replace Trigger AD_TRG_CIUD_TCSAMZ_SF
		For Insert Or Update Or Delete On Ad_Tcsamz
		Compound Trigger

		v_Numcontrato Number;
		i             Int := 0;

		/*
  * Autor: M.Rangel
  * Processo: Matéria Prima
  * Objetivo: Atualizar os dados no contrato
  */

		Before Each Row Is
		Begin
		
				If :New.Numcontrato Is Null Then
						Stp_Keygen_Tgfnum('TCSCON', 1, 'TCSCON', 'NUMCONTRATO', 0, v_Numcontrato);
				
						:New.Numcontrato := v_Numcontrato;
				
				End If;
		
				If Updating('NUNOTA') Then
						Begin
								Select Cab.Numcontrato Into v_Numcontrato From Tgfcab Cab Where Cab.Nunota = :New.Nunota;
						
								:New.Numcontratocpa := v_Numcontrato;
						
						Exception
								When Others Then
										Null;
						End;
				End If;
		
		End Before Each Row;

		After Each Row Is
		Begin
		
				If Variaveis_Pkg.v_Atualizando Then
						Goto Finaldatrigger;
				End If;
		
				Select Count(*)
						Into i
						From Tgfcab
					Where Numcontrato = Nvl(:Old.Numcontrato, :New.Numcontrato)
							And Numcontrato > 0;
		
				If Inserting Then
				
						Begin
						
								Insert Into Tcscon
										(Numcontrato,
											Dtcontrato,
											Codcontato,
											Codemp,
											Codparc,
											Codnat,
											Codmoeda,
											Codcencus,
											Ativo,
											Codtdc,
											Tipoarm,
											Codsaf,
											Codusu,
											Dtbasereaj,
											Recdesp,
											Codgpc,
											Ad_Objcontrato,
											Nunota)
								Values
										(v_Numcontrato,
											:New.Dtcontrato,
											0,
											:New.Codemp,
											:New.Codparc,
											:New.Codnat,
											:New.Codmoeda,
											:New.Codcencus,
											:New.Ativo,
											:New.Codtdc,
											:New.Tipoarm,
											:New.Codsaf,
											Stp_Get_Codusulogado,
											:New.Dtcontrato,
											0,
											:New.Codgpc,
											'Armazem',
											:New.Nunota);
						
								Insert Into Tcspsc
										(Numcontrato,
											Codprod,
											Numusuarios,
											Kitservicos,
											Tipcobkit,
											Respquebratec,
											Respkitserv,
											Resparmaz,
											Unidconversao,
											Qtdisencao,
											Tipoarea,
											Areatotal,
											Areaplant,
											Qtdeprevista,
											Dtinicioisencao,
											Dtfimisencao)
								Values
										(:New.Numcontrato,
											:New.Codprod,
											1,
											:New.Kitservicos,
											:New.Tipcobkit,
											:New.Respquebratec,
											:New.Respkitserv,
											:New.Resparmaz,
											:New.Unidconversao,
											:New.Qtdisencao,
											Nvl(:New.Tipoarea, 'P'),
											:New.Areatotal,
											:New.Areaplant,
											:New.Qtdprevista,
											:New.Dtinicioisencao,
											:New.Dtfimisencao);
						
								Insert Into Tcspre
										(Numcontrato,
											Codprod,
											Referencia,
											Valor,
											Codserv)
								Values
										(v_Numcontrato,
											:New.Codprod,
											:New.Dtcontrato,
											:New.Valor,
											:New.Codserv);
						Exception
								When Others Then
										Raise;
						End;
				
				Elsif Updating Then
				
						Variaveis_Pkg.v_Atualizando := True;
				
						Begin
								Dbms_Output.Put_Line('KitServiços => ' || :New.Kitservicos);
						
								Begin
										Update Tcscon
													Set Dtcontrato = :New.Dtcontrato,
																	Codemp = :New.Codemp,
																	Codparc = :New.Codparc,
																	Codnat = :New.Codnat,
																	Codmoeda = :New.Codmoeda,
																	Codcencus = :New.Codcencus,
																	Ativo = :New.Ativo,
																	Codtdc = :New.Codtdc,
																	Tipoarm = :New.Tipoarm,
																	Codsaf = :New.Codsaf,
																	Codusu = Nvl(:New.Codusu, stp_get_codusulogado),
																	Codgpc = :New.Codgpc,
																	Codproj = Nvl(:New.Codproj, 0),
																	Nunota = :New.Nunota,
																	Codempresp = :New.Codempresp
											Where Numcontrato = :New.Numcontrato;
								Exception
										When Others Then
												Raise_Application_Error(-20105, 'Erro ao atualizar dados do cabeçalho do contrato. ' || Sqlerrm);
								End;
						
								Begin
										Update Tcspsc
													Set Codprod = :New.Codprod,
																	Tipcobkit = :New.Tipcobkit,
																	Respquebratec = :New.Respquebratec,
																	Kitservicos = Nvl(:New.Kitservicos, 'N'),
																	Respkitserv = :New.Respkitserv,
																	Resparmaz = :New.Resparmaz,
																	Unidconversao = :New.Unidconversao,
																	Qtdisencao = :New.Qtdisencao,
																	Tipoarea = Nvl(:New.Tipoarea, 'P'),
																	Areatotal = :New.Areatotal,
																	Areaplant = :New.Areaplant,
																	Qtdeprevista = :New.Qtdprevista,
																	Dtinicioisencao = :New.Dtinicioisencao,
																	Dtfimisencao = :New.Dtfimisencao
											Where Numcontrato = :New.Numcontrato
													And Codprod = :New.Codprod;
								Exception
										When Others Then
												Raise_Application_Error(-20105, 'Erro ao atualizar dados do produto do contrato. ' || Sqlerrm);
								End;
						
								Dbms_Output.Put_Line(:New.Qtdprevista);
						
								Begin
										Update Tcspre
													Set Codprod = :New.Codprod,
																	Referencia = :New.Dtcontrato,
																	Valor = :New.Valor,
																	Codserv = :New.Codserv
											Where Numcontrato = :New.Numcontrato
													And Codprod = :New.Codprod
													And Codserv = :New.Codserv;
								Exception
										When Others Then
												Raise_Application_Error(-20105, 'Erro ao atualizar dados do valor do contrato. ' || Sqlerrm);
								End;
						
								Variaveis_Pkg.v_Atualizando := False;
						
						End;
				
				Else
				
						If i > 0 Then
								Raise_Application_Error(-20105, 'Contrato possui lançamentos, não pode ser excluído!');
						Else
								Ad_Pkg_Sst.Exclui_Contrato(:Old.Numcontrato);
						End If;
				
				End If;
				<<finaldatrigger>>
				Null;
		End After Each Row;

End Ad_Trg_Ciud_Tcsamz_Sf;
/
