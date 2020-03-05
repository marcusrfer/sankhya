Create Or Replace Trigger AD_TRG_CMP_TSFTFV_SF
	For Insert On AD_TSFTFV
	Compound Trigger

	/* 
  * Autor: M. Rangel
  * Processo: Programação Frango Vivo
  * Objetivo: Insert na TSFPFV, Tratar os dados recebidos da rotina java, oriundos do avecom, para inserir na tela de programação
  */

	t ad_tsftfv%Rowtype;
	p ad_tsfpfv%Rowtype;
	i Int;

	Before Each Row Is
	
	Begin
	
		t.numtfv     := :New.Numtfv;
		t.dtdescarte := :new.Dtdescarte;
		t.horapega   := :new.Horapega;
		t.unidade    := To_Char(Ltrim(Rtrim(:new.Unidade)));
		t.nucleo     := To_Char(Ltrim(Rtrim(:New.Nucleo)));
		t.aviario    := To_Char(Ltrim(Rtrim(:new.Aviario)));
		t.idade      := :new.Idade;
		t.sexo       := :new.Sexo;
		t.peso       := :new.Peso;
		t.localidade := Ltrim(Rtrim(:new.Localidade));
		t.km         := :new.Km;
		t.pega       := :new.Pega;
		t.tecnico    := :new.Tecnico;
		t.qtdpega    := :new.Qtdpega;
	
	End Before Each Row;

	After Statement Is
		i             Int;
		v_nuafv       Number;
		v_Qtdneg      Float;
		v_Divisor     Number;
		v_QtdResidual Float := 0;
		v_errmsg      Varchar2(4000);
	Begin
	
		If Nvl(t.numtfv, 0) > 0 Then
		
			Select Count(*)
				Into i
				From ad_tsfpfv p
			 Where p.numtfv = t.numtfv;
		
			If i > 0 Then
				Goto finalmetodo;
			End If;
		
			stp_keygen_tgfnum('AD_TSFPFV', 1, 'AD_TSFPFV', 'NUPFV', 0, p.nupfv);
			p.numtfv    := t.numtfv;
			p.codune    := To_Number(t.unidade);
			p.nucleo    := To_Number(t.nucleo);
			p.codparc   := ad_pkg_pfv.get_codparc_integrado(To_Char(t.Unidade),
																											To_Char(t.Nucleo),
																											To_Char(t.Aviario));
			p.sexo      := t.sexo;
			p.distancia := t.km;
			p.origpinto := Null;
			p.dtagend   := Sysdate;
			--p.qtdneg    := t.qtdpega;
			--p.qtdpega    := t.qtdpega;
			p.status     := 'P';
			p.tecnico    := Ltrim(Rtrim(t.tecnico));
			p.pegador    := Ltrim(Rtrim(t.pega));
			p.dtdescarte := To_Date(Substr(t.dtdescarte, 9, 2) || '/' || Substr(t.dtdescarte, 6, 2) || '/' ||
															Substr(t.dtdescarte, 1, 4),
															'dd/mm/yyyy');
			p.horapega := Case
											When To_Number(Replace(Substr(t.horapega, 12, 5), ':', '')) = 0 Then
											 0001
											Else
											 To_Number(Replace(Substr(t.horapega, 12, 5), ':', ''))
										End;
		
			p.dhpega := To_Date(Substr(t.dtdescarte, 9, 2) || '/' || Substr(t.dtdescarte, 6, 2) || '/' ||
													Substr(t.dtdescarte, 1, 4) || ' ' || Substr(t.horapega, 12, 8),
													'dd/mm/yyyy hh24:mi:ss');
		
			-- seleciona o produto de acordo com o sexo
			If t.Sexo = 'M' Then
				p.Codprod := ad_pkg_pfv.v_codprodmacho;
				v_Qtdneg  := ad_pkg_pfv.v_QtdMacho;
				v_Divisor := ad_pkg_pfv.v_DivMacho;
			Elsif t.Sexo = 'F' Then
				p.Codprod := ad_pkg_pfv.v_codprodfemea;
				v_Qtdneg  := ad_pkg_pfv.v_QtdFemea;
				v_Divisor := ad_pkg_pfv.v_DivFemea;
			Elsif t.Sexo = 'X' Then
				p.Codprod := ad_pkg_pfv.v_codprodsexado;
				v_Qtdneg  := ad_pkg_pfv.v_QtdMacho;
				v_Divisor := ad_pkg_pfv.v_DivMacho;
			End If;
		
			-- busca a cidade
			Begin
				Select codcid
					Into p.codcid
					From tsicid
				 Where nomecid = t.localidade
					 And rownum = 1;
			Exception
				When Others Then
					p.codcid := 0;
			End;
		
			-- busca o laudo     
			Begin
				Select l.numlfv, l.dtalojamento - 1, l.dtalojamento - 1, l.dtalojamento + 14,
							 l.gta || ' - ' || ad_get.get_cgccpf_parcemp(p.codparc, 'P'), l.qtdaves, l.qtdmortes,
							 (l.qtdaves - l.qtdmortes)
					Into p.numlfv, p.dtmarek, p.dtbouba, p.dtgumboro, p.origpinto, p.qtdpega, p.qtdmortes, p.qtdneg
					From ad_tsflfv l
				 Where l.codparc = p.codparc
					 And l.codprod = p.codprod
					 And To_Date(l.dtabate, 'dd/MM/yyyy') = To_Date(p.dtdescarte, 'dd/MM/yyyy');
			Exception
				When Others Then
					Null;
			End;
		
			-- insert dos dados do cabeçalho
			Begin
				If p.qtdneg Is Null Then
					p.qtdneg := t.qtdpega;
				End If;
			
				p.codusu  := stp_get_codusulogado;
				p.dhalter := Sysdate;
			
				Insert Into ad_tsfpfv
				Values p;
			Exception
				When dup_val_on_index Then
					Goto finalmetodo;
				When Others Then
					v_errmsg := 'Erro ao inserir o lançamento na programação. Unidade ' || t.unidade || ' núcleo ' ||
											t.nucleo || ' - ' || t.numtfv || '<br>' || Sqlerrm;
					Raise_Application_Error(-20105, ad_fnc_formataerro(v_errmsg));
			End;
		
			-- insert das quantidades      
			Begin
				If Nvl(p.qtdneg, 0) > 0 Then
					v_QtdResidual := p.qtdneg; -- se achou o lote, usa a qtd result do laudo
				Else
					p.qtdneg      := t.qtdpega; -- qtde que vai ser inserida
					v_qtdresidual := t.qtdpega; -- se não, usa a qtd da tabela base msm
				End If;
			
				v_nuafv := 0;
			
				-- loop que distribui as quantidades por linhas
				<<insere_agend>>
				Loop
					Exit When v_QtdResidual <= 0;
					v_QtdResidual := v_QtdResidual - v_Qtdneg;
					v_nuafv       := v_nuafv + 1;
				
					Begin
						Insert Into ad_tsfafv
							(nupfv, nuafv, unidade, nucleo, dtagend, codparctransp, codveiculo, codmotorista, codcid,
							 qtdneg, qtdnegalt, qtdvolalt, statusvei, codparc, codprod, nunota)
						Values
							(p.nupfv, v_nuafv, p.codune, p.nucleo, p.dtdescarte, Null, Null, Null, p.codcid, v_qtdneg,
							 (v_qtdneg / v_divisor), v_divisor, Null, p.codparc, p.codprod, Null);
					Exception
						When Others Then
							Raise;
					End;
				
					If v_QtdResidual < v_Qtdneg Then
						v_qtdneg := v_QtdResidual;
					End If;
				
				End Loop insere_agend;
			End;
		
			<<finalmetodo>>
			Null;
		
		End If;
	
	End After Statement;

End;
/
