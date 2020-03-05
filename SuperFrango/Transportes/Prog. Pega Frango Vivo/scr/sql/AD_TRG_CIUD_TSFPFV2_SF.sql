Create Or Replace Trigger AD_TRG_CIUD_TSFPFV2_SF
		For Insert Or Update Or Delete On ad_tsfpfv2
		Compound Trigger

		/*
  * Autor: Marcus Rangel
  * Processo: Programação Coleta de Frango Vivo
  * Objetivo: Realizar validações e tratativas nos dados oriundos da integração com o AVECOM
  */

		gerandoPedido Varchar2(1);

		Before Statement Is
		Begin
				If ad_pkg_pfv.v_GeraPedido Then
						gerandoPedido := 'S';
				Else
						gerandoPedido := 'N';
				End If;
		End Before Statement;

		Before Each Row Is
				v_Codparc Number;
		Begin
		
				If (inserting Or updating) And gerandoPedido = 'N' Then
				
						-- teoricamente, a única entrada de dados nessa tabela será pela trigger da TSFTFV
						-- e já existe essa tratativa lá, permanceu aqui sem raise só para o fato de, futuramente,
						-- se permitir a inclusão pela tela.
				
						-- tratativa para parceiro nulo
						If :new.Codparc Is Null Then
								Begin
										Select codparc
												Into v_Codparc
												From tgfpar
											Where (Upper(nomeparc) Like '%UNIDADE%' || :new.codune || '%NUCLEO%' || :new.nucleo || '%' Or
																	Upper(nomeparc) Like '%UNIDADE%' || :new.codune || '%AVIARIO%' || :new.nucleo || '%');
								
										:new.Codparc := v_codparc;
								Exception
										When Others Then
												Null;
								End;
						
						End If;
				
						If Nvl(:new.Codcid, 0) = 0 Then
								Begin
										Select codcid Into :new.Codcid From tgfpar Where codparc = v_codparc;
								Exception
										When no_data_found Then
												Null;
								End;
						
						End If;
				
						-- tratativa para produto nulo
						If :new.Codprod Is Null Then
								If :new.Sexo = 'M' Then
										:new.Codprod := ad_pkg_pfv.v_codprodmacho;
								Elsif :new.Sexo = 'F' Then
										:new.Codprod := ad_pkg_pfv.v_codprodfemea;
								Elsif :new.Sexo = 'S' Then
										:new.Codprod := ad_pkg_pfv.v_codprodsexado;
								End If;
						End If;
				
						-- tratativa para prioridade, usuário conseguir ordenar por regra
						If :new.Dtdescarte > Trunc(:new.Dtagend) And :new.Horapega Between 1800 And 2359 Then
								:new.prioridade := 0;
						Else
								:new.Prioridade := 1;
						End If;
				
				End If;
		
				-- Ao atualizar, verifica se o laudo foi importado, se não, busca realizar a vinculação.  
				If updating And gerandopedido = 'N' Then
				
						If :old.Codveiculo Is Null And :new.Codveiculo Is Not Null And :old.Statusvei Is Null Then
								:new.Statusvei := 'P';
						End If;
				
						If :old.Codveiculo Is Not Null And :new.Codveiculo Is Null Then
								:new.Codparctransp := Null;
								:new.Codmotorista  := Null;
								:new.Statusvei     := Null;
						End If;
				
						If :new.Statusvei Is Not Null And :new.Codveiculo Is Not Null And gerandoPedido = 'N' Then
								:new.status := 'A';
						End If;
						/*
      TODO: owner="Marcus Rangel" category="Review" priority="1 - High" created="13/02/2019"
      text="tratar processo de cancelamento de nota e/ou programação com pedido gerado"
      */
						-- se cancelando a nota fiscal
						If :old.nunota Is Not Null And :new.Nunota Is Null Then
								Null;
						End If;
				
						If :old.Numlfv Is Null Then
						
								Begin
										Select l.numlfv,
																	To_Date(l.dtalojamento - 1, 'dd/mm/yyyy'),
																	To_Date(l.dtalojamento - 1, 'dd/mm/yyyy'),
																	To_Date(l.dtalojamento + 14, 'dd/mm/yyyy'),
																	l.gta || ' - ' || par.cgc_cpf,
																	l.qtdaves,
																	l.qtdmortes
												Into :new.Numlfv,
																	:new.dtmarek,
																	:new.dtbouba,
																	:new.dtgumboro,
																	:new.origpinto,
																	:new.qtdpega,
																	:new.qtdmortes
												From ad_tsflfv l
												Join tgfpar par
														On l.codparc = par.codparc
											Where l.codparc = :new.codparc
													And l.codprod = :new.codprod
													And To_Char(l.dhpega, 'dd/mm/yyyy hh24:mi:ss') = To_Char(:new.dhpega, 'dd/mm/yyyy hh24:mi:ss')
										--And l.dtabate = To_Date(:new.Dtdescarte, 'dd/mm/yyyy')
										;
								Exception
										When no_data_found Then
												:new.dtmarek   := Null;
												:new.dtbouba   := Null;
												:new.dtgumboro := Null;
												:new.origpinto := Null;
												:new.qtdpega   := Null;
												:new.qtdmortes := Null;
								End;
						
						End If;
				
				End If;
		
		End Before Each Row;

End;
/
