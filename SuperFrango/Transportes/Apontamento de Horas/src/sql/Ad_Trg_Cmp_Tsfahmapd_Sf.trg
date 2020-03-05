Create Or Replace Trigger "AD_TRG_CMP_TSFAHMAPD_SF"
		For Insert Or Update Or Delete On Ad_Tsfahmapd

		Compound Trigger
/*
  Dt. Criação: 09/11/2016
  Autor: Marcus Rangel
  Objetivo: Realizar validação antes da inserção/atualização nos apontamentos.
  Popular o valor trabalhado total do dia na tabela de totais.
  */

		Apt             Ad_Tsfahmapd%Rowtype;
		Maq             Ad_Tsfahmmaq%Rowtype;
		Fmg             Tmdfmg%Rowtype;
		v_Qtdresidual   Float;
		v_Listausuarios Varchar2(400);
		v_Mailusu       Varchar2(400);
		v_Enviamail     Boolean := False;
		v_Tipomedida    Char(1);
		v_Ultimaseq     Boolean Default False;
		Errmsg          Varchar2(4000);
		Error Exception;
		isDeleting Boolean Default False;

		Before Each Row Is
		Begin
		
				If Inserting Or Updating Then
				
						If (Sysdate - :New.Dtapont) > 60 Then
								Errmsg := 'O apontamento possui mais de 60 dias de retroatividade, por favor procure o responsável da área!';
								Raise Error;
						End If;
				
						:New.Hora := Lpad(Replace(:New.Hora, ':', ''), 4, '0');
				
						If Nvl(:new.Codcencus, 0) = 0 Then
								Begin
										Select codcencus Into apt.codcencus From ad_tsfahmc Where nuapont = :new.Nuapont;
										:new.Codcencus := apt.codcencus;
								Exception
										When Others Then
												Null;
								End;
						End If;
				
						-- popula valores usados no after
						Apt.Hora      := :New.Hora;
						Apt.Horimetro := :New.Horimetro;
						Apt.Qtdneg    := :New.Qtdneg;
						Apt.Dtapont   := :New.Dtapont;
						Apt.Tipoapont := :New.Tipoapont;
						Apt.Turno     := :New.Turno;
						Apt.Seqapont  := :New.Seqapont;
						Apt.Nuapont   := :New.Nuapont;
						Apt.Nuseqmaq  := :New.Nuseqmaq;
				
						-- se apontamento final de turno    
						If :New.Tipoapont In ('F', 'U') Then
								:New.Ultimaseq := 'S';
								v_Ultimaseq    := True;
						Elsif :New.Tipoapont = 'I' Then
								:New.Ultimaseq := 'N';
								v_Ultimaseq    := False;
						End If;
				
						-- popula com dados da máquina
						Select *
								Into Maq
								From Ad_Tsfahmmaq m
							Where m.Nuapont = :New.Nuapont
									And m.Nuseqmaq = :New.Nuseqmaq;
				
						-- set valores novos
						:New.Numcontrato := Maq.Numcontrato;
						:New.Codprod     := Maq.Codprod;
						:New.Codmaq      := Maq.Codmaq;
						:New.Codvol      := Maq.Codvol;
				
						If :New.Dtinijornada Is Null And :New.Dtapont Is Not Null Then
								:New.Dtinijornada := :New.Dtapont;
						End If;
				
						Apt.Dtinijornada := :New.Dtinijornada;
						Apt.Dtapont      := Apt.Dtinijornada;
				
						If Nvl(:Old.Tipoapont, :New.Tipoapont) Is Null Then
								Errmsg := 'É obrigatório informar o tipo do apontamento!';
								Raise Error;
						End If;
				
						If (:New.Hora Is Not Null Or :New.Horimetro Is Not Null) And Nvl(:Old.Turno, :New.Turno) Is Null Then
								Errmsg := 'É obrigatório informar o turno!';
								Raise Error;
						End If;
				
						-- valida se tem máquina
						If Maq.Codvol Is Null Then
								Errmsg := 'Não foi possível determinar o tipo de medição do equipamento em questão.';
								Raise Error;
						End If;
				
						/*If Nvl(:Old.Tipoapont, 'I') = 'F' And Updating('DTAPONT') Then
        Errmsg := 'Não é possível editar lançamentos marcados como final de apontamento.';
        Raise Error;
      End If;*/
				
						-- get tipo da medida 
						Select Nvl(v.Ad_Tipomed, 'Q') Into v_Tipomedida From Tgfvol v Where v.Codvol = Maq.Codvol;
				
						-- valida lançamento das informações para medição
				
						If v_Tipomedida = 'Q' Then
								-- medido por quantidade, 1 viagem, 1 dia, 10 kilos
						
								-- se não é hora e está preenchida
								If Nvl(:New.Hora, 0) <> 0 Or Nvl(:New.Horimetro, 0) <> 0 Then
										Errmsg := 'Para serviços com medição diferentes de horas, não é necessário preencher o campo "Hora".';
										Raise Error;
								End If;
						
								-- se quantidade nula
								If Nvl(:New.Qtdneg, 0) = 0 Then
										Errmsg := 'Para apontamentos por Quantidade, a mesma deve ser informada!.';
										Raise Error;
								Else
										Apt.Qtdneg := :New.Qtdneg;
								End If;
						
						Elsif v_Tipomedida = 'T' Then
								-- medido por tempo, intervalo de horas, horimetro
						
								If :New.Hora Is Null And :New.Horimetro Is Null Then
										Errmsg := 'Para unidades medidas por tempo, é necessário que o campo "Horas" ou "Horímetro" estejam preenchidos!';
										Raise Error;
								End If;
						
						End If;
				
						-- valida se tem NUNOTA gerado
						If :Old.Nunota Is Not Null And :New.Nunota Is Not Null Then
								Errmsg := 'Apontadamentos faturados não podem ser alterados.';
								Raise Error;
						End If;
				
						-- momento que está cancelando o pedido gerado
						-- ao excluir o pedido gerado, ocorre o insert na tgfcab_exc
						-- que possui uma trigger que exclui o vinculo na ad_tblcmf
						If :Old.Nunota Is Not Null And :New.Nunota Is Null Then
								:New.Dtfecha  := Null;
								:New.Faturado := 'N';
								--ad_pkg_var.Permite_Update := True;
						
								Begin
										Update Ad_Tsfahmtad Td
													Set Td.Pendente = 'S'
											Where Td.Nuapont = :New.Nuapont
													And Td.Nuseqmaq = :New.Nuseqmaq
													And Td.Dtapont = :New.Dtapont;
								Exception
										When Others Then
												Errmsg := 'Não foi possível desmarcar como pendente';
												Raise Error;
								End;
						
						End If;
				
						<<sai_Fim>>
						Null;
				
				Elsif Deleting Then
				
						isDeleting := True;
				
						If (Nvl(:Old.Tipoapont, 'I') In ('F', 'U') And :Old.Nunota Is Null) Then
						
								Begin
								
										Delete From Ad_Tsfahmtad t
											Where t.Nuapont = :Old.Nuapont
													And t.Nuseqmaq = :Old.Nuseqmaq
													And t.Dtapont = Nvl(:Old.Dtinijornada, :Old.Dtapont);
								
								Exception
										When Others Then
												Errmsg := 'Não foi possível excluir os apontamentos - ' || Sqlerrm;
												Raise Error;
										
								End;
						
						Else
						
								-- tratado separadamente, pois não exige ação, apenas valida a alteração no apontamento
								If :Old.Nunota Is Not Null And :New.Nunota Is Not Null Then
										Errmsg := 'Apontadamentos faturados não podem ser alterados.';
										Raise Error;
								End If;
						End If;
				
				End If;
		
		Exception
				When Error Then
						If Nvl(:Old.Origem, :New.Origem) = 1 Then
								Raise_Application_Error(-20105, Errmsg);
						Else
								Raise_Application_Error(-20105, Ad_Fnc_Formataerro(Errmsg));
						End If;
				When Others Then
						If Nvl(:Old.Origem, :New.Origem) = 1 Then
								Raise_Application_Error(-20105, Sqlerrm);
						Else
								Raise_Application_Error(-20105, Ad_Fnc_Formataerro(Sqlerrm));
						End If;
		End Before Each Row;

		After Statement Is
				i                 Int := 0;
				v_Descrmaq        Varchar2(200);
				v_Descrserv       Varchar2(200);
				v_Percexd         Float;
				v_Nrosolicitacao  Number;
				v_Nomesolicitante Varchar2(100);
				v_Qtdprevista     Float;
				v_Qtdusada        Float;
				v_Tipomedida      Char(1);
		
		Begin
		
				/*If ad_pkg_var.Permite_Update Then
      ad_pkg_var.Permite_Update := False;
      Goto sai_After;
    End If;*/
		
				Begin
						Select Count(*)
								Into i
								From Ad_Tsfahmapd
							Where Dtapont = Apt.Dtapont
									And Nuapont = Apt.Nuapont
									And Codmaq = Maq.Codmaq
									And Codprod = Maq.Codprod
									And Codvol = Maq.Codvol
									And Tipoapont = Apt.Tipoapont
									And Turno = Apt.Turno
									And Seqapont != Apt.Seqapont
									And Tipoapont != 'U';
				
						If (Nvl(i, 0) > 0) Then
								Errmsg := 'Já existe "' || Ad_Get.Opcoescampo(Apt.Tipoapont, 'TIPOAPONT', 'AD_TSFAHMAPD') ||
																		'" para o turno ' || Apt.Turno || ' nesse apontamento';
								Raise_Application_Error(-20105, Errmsg);
						
						End If;
				
						If (Apt.Dtapont != Apt.Dtinijornada And Apt.Turno != 3) Then
								Errmsg := 'Apontamentos que iniciam e terminam em dias diferentes, devem ser do turno 3.';
								Raise_Application_Error(-20105, Errmsg);
						End If;
				
						If (Apt.Tipoapont = 'F') Then
								Select Count(*)
										Into i
										From Ad_Tsfahmapd a
									Where a.Nuapont = Apt.Nuapont
														--And a.Dtapont = Apt.Dtapont
											And Nvl(a.Dtinijornada, a.dtapont) = Apt.Dtinijornada
											And a.Codmaq = Maq.Codmaq
											And a.Codprod = Maq.Codprod
											And a.Codvol = Maq.Codvol
											And a.Tipoapont = 'I'
											And a.Turno = Apt.Turno;
						
								If Nvl(i, 0) = 0 Then
										Errmsg := 'É necessário que exista um apontamento inicial neste turno para que se possa informar o final.';
										Raise_Application_Error(-20105, Errmsg);
								End If;
						
						Else
						
								If isDeleting Then
								
										Select Count(*)
												Into i
												From ad_tsfahmapd
											Where nuapont = apt.nuapont
													And nuseqmaq = apt.nuseqmaq
													And dtapont = apt.dtapont
													And tipoapont = 'F';
								
										If i > 0 Then
												Errmsg := 'Registro possui apontamento final e não pode ser excluído, por favor exclua o final do dia para continuar essa ação.';
												Raise error;
										End If;
								
								End If;
						
						End If;
				
				Exception
						When Others Then
								Raise_Application_Error(-20105, Ad_Fnc_Formataerro(Nvl(Errmsg, Sqlerrm)));
				End;
		
				If v_Ultimaseq Then
				
						Ad_Pkg_Ahm.Calcula_Dia_Apontamento(p_Nuapont => Apt.Nuapont, p_Nuseqmaq => Apt.Nuseqmaq,
																																									p_Dia => Apt.Dtapont, p_Turno => Null);
				
						v_Qtdresidual := Ad_Pkg_Ahm.Horas_Residuais(p_Nuapont => Apt.Nuapont, p_Nuseqmaq => Apt.Nuseqmaq);
				
						If v_Qtdresidual < 0 Then
								v_Enviamail := True;
						End If;
				
						If v_Enviamail Then
						
								Fmg.Assunto  := 'Quantidade de horas contratadas excedidas - Máquina/Veículo';
								Fmg.Mensagem := '<BODY><P><BR/></P><P><FONT STYLE="font-size: 14px; font-family: arial; ">A máquina/equipamento ' ||
																								v_Descrmaq || ' contratados para o serviço ' || v_Descrserv ||
																								', excedeu o número de horas em ' || v_Percexd ||
																								'% do previsto.</FONT></P><P><BR/></P><P><FONT STYLE="font-size: 14px; font-family: arial; ">Nro Solicitação: ' ||
																								v_Nrosolicitacao ||
																								'</FONT></P><P><FONT STYLE="font-size: 14px; font-family: arial; ">Solicitante: ' ||
																								v_Nomesolicitante ||
																								'</FONT></P><P><FONT STYLE="font-size: 14px; font-family: arial; ">Nro Contrato: ' ||
																								Apt.Numcontrato ||
																								'</FONT></P><P><FONT STYLE="font-size: 14px; font-family: arial; ">Qtd Horas previstas: ' ||
																								v_Qtdprevista ||
																								'</FONT></P><P><FONT STYLE="font-size: 14px; font-family: arial; ">Qtd Horas Realizads: ' ||
																								v_Qtdusada || '</FONT></P></BODY>';
								Begin
										Select Us.Email
												Into Fmg.Email
												From Tsiusu Us,
																	Ad_Tsfsstc s,
																	Ad_Tsfahmmaq m
											Where Us.Codusu = s.Codsol
													And s.Codsolst = m.Codsolst
													And m.Nuapont = Apt.Nuapont
											Group By Us.Email;
								Exception
										When Too_Many_Rows Then
												Select Us.Email
														Into Fmg.Email
														From Tsiusu Us,
																			Ad_Tsfsstc s,
																			Ad_Tsfahmmaq m
													Where Us.Codusu = s.Codsol
															And s.Codsolst = m.Codsolst
															And m.Nuapont = Apt.Nuapont
															And Rownum = 1
													Group By Us.Email;
								End;
						
								v_Listausuarios := Get_Tsipar_Texto('USURESPSERVTRP');
						
								For Cl In (Select Regexp_Substr(v_Listausuarios, '[^,]+', 1, Level) Codusu
																					From Dual
																			Connect By Regexp_Substr(v_Listausuarios, '[^,]+', 1, Level) Is Not Null)
								Loop
								
										Select Nvl(u.Emailsollib, u.Email)
												Into v_Mailusu
												From Tsiusu u
											Where u.Codusu = To_Number(Cl.Codusu);
								
										If v_Mailusu Is Null Then
												Continue;
										End If;
								
										If Fmg.Email Is Null Then
												Fmg.Email := v_Mailusu;
										Else
												Fmg.Email := Fmg.Email || ',' || v_Mailusu;
										End If;
								
								End Loop C1;
								Ad_Stp_Gravafilabi(Fmg.Assunto, Fmg.Mensagem, Fmg.Email);
						Else
								Null;
						End If;
				
				End If; -- se é ultima sequencia
		
				If Deleting Then
				
						Select Count(*)
								Into i
								From Ad_Tsfahmapd
							Where Nuapont = :Old.Nuapont
									And Dtapont = :Old.Dtapont
									And Nuseqmaq = :Old.Nuseqmaq
									And Seqapont != :Old.Seqapont;
				
						If i > 2 Then
								Ad_Pkg_Ahm.Calcula_Dia_Apontamento(p_Nuapont => :Old.Nuapont, p_Nuseqmaq => :Old.Nuseqmaq,
																																											p_Dia => :Old.Dtapont, p_Turno => Null);
						End If;
				End If;
		
				<<sai_After>>
				Null;
		End After Statement;

End;
/
