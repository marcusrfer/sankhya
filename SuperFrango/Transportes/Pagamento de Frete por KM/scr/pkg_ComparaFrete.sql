Create Or Replace Package pkg_ComparaFrete As

	/*
  * Autor: M. Rangel
  * Processo: Frete Ordem de Carga
  * Objetivo: Objeto similar a AD_PKG_FRE, utilizado para gerar 
              paralelamente as distâncias e valores em carater experimental
  */

	Procedure calcula_valores_oc(p_codemp Number, p_OrdemCarga Number);

	Procedure calcula_valor(p_codemp Number, p_ordemcarga Number);

End;
/
Create Or Replace Package Body pkg_ComparaFrete As

	Procedure calcula_sequencia(p_Codemp Number, p_OrdemCarga Number) As
	
		p_ErrMsg       Varchar2(4000);
		v_Count        Int;
		v_CodPacrOrig  Number;
		v_CoordOrig    Varchar2(25);
		v_Distancia    Float;
		v_DisTotal     Float := 0;
		ponto_final    Varchar2(25);
		l_dist_tab     Ad_type_fre_disttable := Ad_type_fre_disttable();
		l_dist_tab_ord Ad_type_fre_disttable := Ad_type_fre_disttable();
		x              Int;
		v_UltSeq       Int;
		l_rec_seq      Ad_type_of_number := Ad_type_of_number();
		l_Idx          Int;
	
		Erro_valor Exception;
		Pragma Exception_Init(Erro_valor, -06502);
	
	Begin
		/*    p_codemp     := :codemp;
    p_OrdemCarga := :oc;*/
	
		-- Verifica a qtde de registros na OC, usado no loop
		Select Count(Distinct Codparc)
			Into v_Count
			From ad_detalheoc doc
		 Where Codemp = p_Codemp
			 And Ordemcarga = p_OrdemCarga
			 And doc.newseqcarga = 0;
	
		-- verifica se existe origem definida pelo usuário 
		Select Nvl(Max(Seqcarga), 0)
			Into v_UltSeq
			From ad_detalheoc
		 Where Codemp = p_Codemp
			 And Ordemcarga = p_OrdemCarga
			 And Nvl(newSeqcarga, 0) > 0;
	
		--- define quem é o parceiro inicio da OC
		If Nvl(v_UltSeq, 0) > 0 Then
			Select Codparc, Substr(Latitude, 1, 9) || '%2C' || Substr(Longitude, 1, 9) Coordparc
				Into v_CodPacrOrig, v_CoordOrig
				From ad_detalheoc
			 Where Codemp = p_Codemp
				 And Ordemcarga = p_OrdemCarga
				 And Nvl(newSeqcarga, 0) = v_UltSeq;
		Else
			Select P.Codparc, Substr(Latitude, 1, 9) || '%2C' || Substr(Longitude, 1, 9) Coordparc
				Into v_CodPacrOrig, v_CoordOrig
				From Tgfpar P, Tgford O
			 Where P.Codparc = O.Codparcorig
				 And O.Codemp = p_Codemp
				 And O.Ordemcarga = p_OrdemCarga;
		End If;
	
		-- percorre as notas buscando os parceiros
		For i In 1 .. v_Count
		Loop
			-- limpa a coleção
			l_dist_tab.Delete;
		
			-- inner loop para preencher os demais valores da coleção
			-- não rodou com bulk, devido a proc dentro do object type, ordem de exceução
			For C In (Select Distinct Codparc, To_Char(Substr(Latitude, 1, 9) || '%2C' || Substr(Longitude, 1, 9)) Coord
									From ad_detalheoc
								 Where Codemp = p_Codemp
									 And Ordemcarga = p_OrdemCarga
									 And Nvl(newSeqcarga, 0) = 0
									 And Codparc Not In (Select *
																				 From Table(l_rec_seq))
								 Order By 1)
			Loop
				v_Distancia := Ad_pkg_fre.Get_distancia_xml(v_CoordOrig, C.Coord);
				l_dist_tab.Extend;
				x := l_dist_tab.Last;
				l_dist_tab(x) := Ad_type_fre_distobject(C.Codparc, C.Coord, v_Distancia);
			End Loop;
		
			-- ordena a coleção pela menor distância  
			Select Cast(Multiset (Select Codparc, Coord, distancia
											From Table(l_dist_tab)
										 Order By distancia) As Ad_type_fre_disttable)
				Into l_dist_tab_ord
				From Dual;
		
			l_rec_seq.Extend;
		
			l_Idx := l_rec_seq.Last;
		
			l_rec_seq(l_Idx) := l_dist_tab_ord(1).Codparc;
		
			v_CodPacrOrig := l_dist_tab_ord(1).Codparc;
		
			v_CoordOrig := l_dist_tab_ord(1).Coord;
		
			ponto_final := l_dist_tab_ord(1).Coord;
		
			v_DisTotal := v_DisTotal + l_dist_tab_ord(1).distancia;
		
		End Loop;
	
		-- atualiza as notas da OC
		For Z In l_rec_seq.First .. l_rec_seq.Last
		Loop
			Dbms_Output.Put_Line(Z || ' - ' || l_rec_seq(Z));
		
			Begin
				Update ad_detalheoc
					 Set newSeqcarga = Z + v_UltSeq
				 Where Ordemcarga = p_OrdemCarga
					 And Codemp = p_Codemp
					 And Codparc = l_rec_seq(Z);
			
			Exception
				When Others Then
					p_ErrMsg := '(' || l_rec_seq(Z) || ') ' || Sqlerrm;
					--Raise;
					Return;
			End;
		
		End Loop;
	
	Exception
		When Others Then
			Raise;
			/*When Erro_valor Then
      p_ErrMsg := 'Problema na informação contida na sequência de Entrega';*/
	
	End calcula_sequencia;

	Procedure calcula_distancia(p_Codemp Number, p_OrdemCarga Number) Is
	
		ponto_inicial Varchar2(50);
		ponto_final   Varchar2(50);
		v_Coord_Orig  Varchar2(50);
		v_Coord_Dest  Varchar2(50);
		v_CodParc     Number;
		v_km          Float;
		km_total      Float := 0;
		qtd_req       Number := 0;
	Begin
	
		/*p_codemp     := :codemp;
    p_OrdemCarga := :oc;*/
	
		/* Busca a localização do parceiro de origem da ordem de carga */
		Begin
			Select Replace(P.Latitude, ',', '.') || '%2C' || Replace(P.Longitude, ',', '.')
				Into ponto_inicial
				From Tgfpar P
				Join Tgford O
					On P.Codparc = O.Codparcorig
				 And O.Codemp = p_Codemp
				 And O.Ordemcarga = p_OrdemCarga
			 Where P.Latitude Is Not Null
				 And P.Longitude Is Not Null;
		
		Exception
			When No_data_found Then
				Raise;
		End;
	
		For Parc In (Select Codparc, Min(Sequencia) Sequencia, Coordenada
									 From (Select P.Codparc, 1 Sequencia,
																 Substr(Replace(P.Latitude, ',', '.'), 1, 9) || '%2C' ||
																	Substr(Replace(P.Longitude, ',', '.'), 1, 9) Coordenada
														From Tgfpar P
														Join Tgford O
															On P.Codparc = O.Codparcorig
														 And O.Codemp = p_Codemp
														 And O.Ordemcarga = p_OrdemCarga
													 Where P.Latitude Is Not Null
														 And P.Longitude Is Not Null
													Union
													Select Codparc, newSeqcarga,
																 Substr(Replace(Latitude, ',', '.'), 1, 9) || '%2C' || Substr(Replace(Longitude, ',', '.'), 1, 9)
														From ad_detalheoc
													 Where Codemp = p_Codemp
														 And Ordemcarga = p_OrdemCarga
														 And Latitude Is Not Null
														 And Longitude Is Not Null)
									Group By Codparc, Coordenada
									Order By Sequencia)
		Loop
		
			v_CodParc := Parc.Codparc;
		
			If v_Coord_Orig Is Null Then
				v_Coord_Orig := Parc.Coordenada;
			Else
			
				If v_Coord_Dest Is Not Null Then
					v_Coord_Orig := v_Coord_Dest;
				End If;
			
			End If;
		
			If Parc.Sequencia > 1 Then
			
				If Parc.Coordenada Is Null Then
					Continue;
				End If;
			
				v_Coord_Dest := Parc.Coordenada;
			
				v_km := ad_pkg_fre.Get_distancia_xml(v_Coord_Orig, v_Coord_Dest);
			
				/*Dbms_Output.put_line(v_Coord_Orig || ' / ' || v_Coord_Dest || ' - ' || v_km);*/
			
				km_total := km_total + v_km;
			
				ponto_final := v_Coord_Dest;
			
			End If;
		
			qtd_req := qtd_req + 1;
		
		End Loop Parc;
	
		-- calcula a volta
		If ponto_final Is Not Null Then
		
			-- Para utilizar a mesma distância simulando ida direta,
			-- Para obter o mesmo valor do gmaps, inverter o ponto inicial/final
			v_km := ad_pkg_fre.Get_distancia_xml(ponto_inicial, ponto_final);
		
			/*Dbms_Output.put_line(ponto_inicial || ' / ' || ponto_final || ' - ' || v_km);*/
		
			km_total := km_total + v_km;
		End If;
	
		/*Dbms_Output.put_line('KM Total: ' || km_total);
    qtd_req := qtd_req + 1;
    Dbms_Output.put_line(qtd_req);*/
	
		Begin
			Update ad_comparafrete cf
				 Set cf.newkm = km_total
			 Where cf.codemp = p_Codemp
				 And cf.ordemcarga = p_OrdemCarga;
		End;
	
	Exception
		When Others Then
			Raise;
	End calcula_distancia;

	Procedure calcula_valor(p_codemp Number, p_ordemcarga Number) Is
		v_CodVeiculo Number;
		v_ValorSaida Float;
		v_DistRota   Float;
		v_CodCat     Number;
		x            Float := 0;
		y            Float := 0;
		valor_atual  Float := 0;
		resto_km     Float := 0;
		valor_final  Float := 0;
		qtd_eixos    Number;
		vlr_pedagio  Float := 0;
		ErrMsg       Varchar2(4000);
		Error Exception;
	
	Begin
		/*
    * Autor: Marcus Rangel
    * Objetivo: Função que retorna o valor da ordem de carga, baseando-se
    * nos parametros definidos da tela de regiões de frete e praças de 
    * pedágio
    */
	
		/*    p_codemp     := :codemp;
    p_ordemcarga := :oc;*/
	
		For C_reg In (Select Distinct P.Ad_codregfre Codregfre
										From Tgfpar P
										Join ad_detalheoc C
											On C.Codparc = P.Codparc
									 Where C.Codemp = p_codemp
										 And C.Ordemcarga = p_ordemcarga)
		Loop
			Dbms_Output.Put_Line('Regiao de Frete: ' || c_reg.codregfre);
			/*Busca os dados do veículo*/
			Begin
				Select O.Codveiculo, V.Ad_codcat, Nvl(V.Ad_qtdeixos, 0)
					Into v_CodVeiculo, v_CodCat, qtd_eixos
					From Tgford O
					Join Tgfvei V
						On O.Codveiculo = V.Codveiculo
				 Where O.Codemp = p_codemp
					 And O.Ordemcarga = p_ordemcarga;
			
				If v_CodCat Is Null Or qtd_eixos Is Null Then
					ErrMsg := 'Não encontramos a categoria ou a quantidade de eixos do veículo ' || v_CodVeiculo;
					Raise Error;
				End If;
			
				Dbms_Output.Put_Line('Veículo: ' || v_CodVeiculo || ', Cat: ' || v_CodCat || ', Eixos: ' || qtd_eixos);
			
			End;
		
			/* Busca o valor da saída por categoria*/
			Begin
				Select Cat.Vlrsaida
					Into v_ValorSaida
					From Ad_tsfrfr Cat
				 Where Cat.Codregfre = C_reg.Codregfre
					 And Cat.Codcat = v_CodCat
					 And Cat.Dtvigor = (Select Max(Dtvigor)
																From Ad_tsfrfr R2
															 Where R2.Codregfre = C_reg.Codregfre
																 And Dtvigor <= Trunc(Sysdate));
			
				Dbms_Output.Put_Line('Valor Saída: ' || v_ValorSaida);
			
			Exception
				When No_data_found Then
					ErrMsg := 'Não encontramos valor para essa ordem de carga, verifique a região de frete do parceiro ';
					--c_reg.codparc;
					Raise Error;
			End;
		
			/*Busca a distância da rota pela localização dos parceiros*/
			Begin
				Select V.NEWKM
					Into v_DistRota
					From ad_comparafrete V
				 Where V.Codemp = p_codemp
					 And V.Ordemcarga = p_ordemcarga;
			Exception
				When No_data_found Then
					v_DistRota := ad_pkg_fre.Get_distancia_total_oc(p_codemp, p_ordemcarga);
			End;
		
			Dbms_Output.Put_Line('Distância: ' || v_DistRota);
		
			resto_km := v_DistRota;
		
			/*Percorre as faixas de valores para calcular o valor da rota*/
			For C_dist In (Select i.Codregfre, i.Nurfr, i.Numrfi, i.Inicioint, i.Finalint, i.Vlrkm, i.Vlrfixo
											 From Ad_tsfrfi i
											 Join Ad_tsfrfr R
												 On i.Codregfre = R.Codregfre
												And i.Nurfr = R.Nurfr
												And R.Codcat = v_CodCat
											Where i.Codregfre = C_reg.Codregfre
											Order By i.Numrfi)
			Loop
			
				If resto_km > C_dist.Finalint Then
					x := C_dist.Finalint - C_dist.Inicioint;
				Else
					x := resto_km;
				End If;
			
				If Nvl(C_dist.Vlrfixo, 'N') = 'S' Then
					y := C_dist.Vlrkm;
				Else
					y := x * C_dist.Vlrkm;
				End If;
			
				valor_atual := valor_atual + y;
				resto_km    := resto_km - x;
			
			End Loop C_dist;
		
			Dbms_Output.Put_Line('Valor faixas: ' || valor_atual);
		
		End Loop C_reg;
	
		/*Busca o valor do pedágio por cidade / categoria*/
		Begin
			Select Nvl(Cat.Vlrpedagio, 0) * qtd_eixos
				Into vlr_pedagio
				From Ad_tsfrfpcat Cat, Ad_tsfrfpcid Cid, Ad_tsfrfp P
			 Where P.Codpraca = Cat.Codpraca
				 And Nvl(P.Ativo, 'N') = 'S'
				 And Cat.Codpraca = Cid.Codpraca
				 And Cat.Codcat = v_CodCat
				 And Cat.Dtvigor = (Select Max(C2.Dtvigor)
															From Ad_tsfrfpcat C2
														 Where C2.Codpraca = Cat.Codpraca
															 And C2.Codcat = Cat.Codcat
															 And C2.Dtvigor <= Sysdate)
				 And Exists (Select 1
								From Tgfpar Par, ad_detalheoc Cab
							 Where Par.Codparc = Cab.Codparc
								 And Cab.Codemp = p_codemp
								 And Cab.Ordemcarga = p_ordemcarga
								 And Par.Codcid = Cid.Codcid);
		
		Exception
			When No_data_found Then
				vlr_pedagio := 0;
			When Others Then
				vlr_pedagio := 0;
		End;
	
		Dbms_Output.Put_Line('Pedágio: ' || vlr_pedagio);
	
		valor_final := v_ValorSaida + valor_atual + vlr_pedagio;
	
		Dbms_Output.Put_Line('Valor Final: ' || valor_final);
	
		Begin
			Update ad_comparafrete
				 Set Newvlrfrete = valor_final
			 Where codemp = p_codemp
				 And ordemcarga = p_OrdemCarga;
		End;
	
	Exception
		When Error Then
			Raise_Application_Error(-20105, ErrMsg);
		When Others Then
			Raise;
	End calcula_valor;

	Procedure calcula_valores_oc(p_codemp Number, p_ordemcarga Number) Is
	Begin
		calcula_sequencia(p_codemp, p_OrdemCarga);
		calcula_distancia(p_codemp, p_OrdemCarga);
		calcula_valor(p_codemp, p_OrdemCarga);
		Commit;
	End calcula_valores_oc;

End pkg_ComparaFrete;
/
