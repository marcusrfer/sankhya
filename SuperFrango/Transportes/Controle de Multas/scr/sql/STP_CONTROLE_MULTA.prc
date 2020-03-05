Create Or Replace Procedure "STP_CONTROLE_MULTA"(p_codmulta In Number, p_mensagem Out Varchar2) As

	v_newnufin  tgffin.nufin%Type;
	v_dhtipoper tgftop.dhalter%Type;
	v_notifprev Char(1);
	v_convenio  Char(1);
	r_Par       ad_mulpar%Rowtype;
	r_Mul       ad_mulcontrol%Rowtype;
	v_quant     Number;
	error Exception;
Begin

	/* Autor/Revisor: Guilherme Hahn/M. Rangel
  * Processo: Controle de Multas
  * Objetivo: Gerar o financeiro das multas considerando os cenários após a aprovação da multa
  */

	Select *
		Into r_Par
		From ad_mulpar par
	 Where par.codmulpar = 1; -- cadastro único para parâmetros

	Begin
		Select mul.codemp,
					 mul.codempfin,
					 mul.valormulta - mul.Vlrdescfin,
					 mul.dtinfracao,
					 mul.dtvencto,
					 Substr(mul.codbarra, 1, 50),
					 mul.pagotransp,
					 mul.dtpagtotransp,
					 ord.codparctransp,
					 mul.situacao,
					 mul.ordemcarga,
					 mul.historico,
					 mul.codautuacao notif_aut,
					 mul.codparc,
					 (Case
							When Nvl(notif.codautuacao, 0) = Nvl(mul.codautuacao, 0) Then
							 'S'
							Else
							 'N'
						End),
					 vlrdesconto
			Into r_Mul.codemp,
					 r_Mul.codempfin,
					 r_Mul.valormulta,
					 r_Mul.dtinfracao,
					 r_mul.dtvencto,
					 r_mul.codbarra,
					 r_mul.pagotransp,
					 r_mul.dtpagtotransp,
					 r_mul.codparctransp,
					 r_mul.situacao,
					 r_mul.ordemcarga,
					 r_mul.historico,
					 r_mul.codautuacao,
					 r_mul.codparc,
					 v_notifprev,
					 r_Mul.vlrdesconto
			From ad_mulcontrol mul, tgford ord, ad_mulnotif notif
		 Where mul.codmulcont = p_codmulta
			 And mul.codemp = ord.codemp(+)
			 And mul.ordemcarga = ord.ordemcarga(+)
			 And mul.codparc = notif.codparc(+)
			 And mul.codautuacao = notif.codautuacao(+);
	
		If r_Mul.codempfin Is Null Then
			r_Mul.codempfin := r_Mul.codemp;
		End If;
	
	Exception
		When no_data_found Then
			p_mensagem := 'Dados da ordem de carga não encontrados.';
			Raise error;
		When too_many_rows Then
			p_mensagem := 'Consulta da ordem de carga retorna mais de uma linha.';
			Raise error;
	End;

	v_dhtipoper := ad_get.maxdhtipoper(r_par.codtipoperreemb);

	-- retira letras do código da autuação, para seguir padrão numnota utilizado pela contabilidade
	--v_numnota := to_number(ltrim(translate(r_mul.codautuacao, translate(r_mul.codautuacao, '1234567890', ' '), ' ')));

	If r_Mul.dtinfracao <= Nvl(r_par.dtvigor, '01/01/2016') Then
		v_notifprev := 'S';
	End If;

	-- pago pelo transportador = não
	If Nvl(r_mul.pagotransp, 'N') = 'N' Then
	
		-- verifica se o parceiro é convênio, se for, utiliza outro tipo de título
		Select convenio
			Into v_convenio
			From ad_mulparcod
		 Where codparc = r_mul.codparc;
	
		If Nvl(v_convenio, 'N') = 'S' Then
			Select m.codtiptitconv
				Into r_par.codtiptitpag
				From ad_mulpar m
			 Where m.codmulpar = 1;
		End If;
	
		-- transportador notificou?
		If Nvl(v_notifprev, 'N') = 'S' Then
			--sim
			--- gera despesa pro parceiro
			Begin
				v_newnufin  := seq_tgffin_nufin.nextval;
				v_dhtipoper := ad_get.maxdhtipoper(r_Par.codtipoperpag);
			
				Insert Into tgffin
					(nufin,
					 codemp,
					 numnota,
					 vlrdesdob,
					 codparc,
					 dtneg,
					 dtvenc,
					 dtvencinic,
					 codnat,
					 codcencus,
					 codproj,
					 nossonum,
					 historico,
					 codtipoper,
					 recdesp,
					 origem,
					 desdobramento,
					 provisao,
					 dtalter,
					 dhtipoper,
					 dhmov,
					 codtiptit,
					 desdobdupl,
					 codbco,
					 codctabcoint,
					 linhadigitavel,
					 vlrdesc,
					 ordemcarga,
					 autorizado)
				Values
					(v_newnufin,
					 r_Mul.codempfin,
					 p_codmulta,
					 r_Mul.valormulta,
					 r_mul.codparc,
					 Trunc(Sysdate),
					 r_mul.dtvencto,
					 r_mul.dtvencto,
					 r_par.codnatpag,
					 Nvl(r_par.codcencuspag, 0),
					 Nvl(r_par.codprojpag, 0),
					 Null,
					 r_par.prefixopag || '. CÓD. INFRAÇÃO: ' || r_mul.codautuacao || ', OC: ' ||
					 r_mul.ordemcarga,
					 r_Par.codtipoperpag,
					 -1,
					 'F',
					 '0',
					 'N',
					 Sysdate,
					 v_dhtipoper,
					 Sysdate,
					 r_par.codtiptitpag,
					 'ZZ',
					 r_par.codbcoadiant,
					 r_par.codctabcointadiant,
					 r_mul.codbarra,
					 r_Mul.vlrdesconto,
					 0,
					 'S');
			
				Insert Into ad_tblcmf
					(nometaborig, nuchaveorig, nometabdest, nuchavedest)
				Values
					('AD_MULCONTROL', p_codmulta, 'TGFFIN', v_newnufin);
			
			Exception
				When Others Then
					p_mensagem := 'Erro ao gerar despesa para o parceiro - ' || Sqlerrm;
					Raise;
			End;
		Else
			-- não gera 
			-- gera despesa pro parceiro
			-- gera adiantamento por transportador
			Begin
				v_newnufin  := seq_tgffin_nufin.nextval;
				v_dhtipoper := ad_get.maxdhtipoper(r_Par.codtipoperpag);
			
				Insert Into tgffin
					(nufin,
					 codemp,
					 numnota,
					 vlrdesdob,
					 codparc,
					 dtneg,
					 dtvenc,
					 dtvencinic,
					 codnat,
					 codcencus,
					 codproj,
					 nossonum,
					 historico,
					 codtipoper,
					 recdesp,
					 origem,
					 desdobramento,
					 provisao,
					 dtalter,
					 dhtipoper,
					 dhmov,
					 codtiptit,
					 desdobdupl,
					 codbco,
					 codctabcoint,
					 linhadigitavel,
					 vlrdesc,
					 ordemcarga,
					 autorizado)
				Values
					(v_newnufin,
					 r_Mul.codempfin,
					 p_codmulta,
					 r_Mul.valormulta,
					 r_mul.codparc,
					 Trunc(Sysdate),
					 r_mul.dtvencto,
					 r_mul.dtvencto,
					 r_par.codnatpag,
					 Nvl(r_par.codcencuspag, 0),
					 Nvl(r_par.codprojpag, 0),
					 Null,
					 r_par.prefixopag || '. CÓD. INFRAÇÃO: ' || r_mul.codautuacao || ', OC: ' ||
					 r_mul.ordemcarga,
					 r_Par.codtipoperpag,
					 -1,
					 'F',
					 '0',
					 'N',
					 Sysdate,
					 v_dhtipoper,
					 Sysdate,
					 r_par.codtiptitpag,
					 'ZZ',
					 r_par.codbcoadiant,
					 r_par.codctabcointadiant,
					 r_mul.codbarra,
					 r_Mul.vlrdesconto,
					 0,
					 'S');
			
				Insert Into ad_tblcmf
					(nometaborig, nuchaveorig, nometabdest, nuchavedest)
				Values
					('AD_MULCONTROL', p_codmulta, 'TGFFIN', v_newnufin);
			
				Select Count(1)
					Into v_quant
					From ad_mulparcexadiant ex
				 Where ex.codparc = r_mul.codparctransp;
			
				If v_quant = 0 Then
				
					v_newnufin  := seq_tgffin_nufin.nextval;
					v_dhtipoper := ad_get.maxdhtipoper(r_par.codtipoperadiant);
				
					Insert Into tgffin
						(nufin,
						 codemp,
						 numnota,
						 vlrdesdob,
						 codparc,
						 dtneg,
						 dtvenc,
						 dtvencinic,
						 codnat,
						 codcencus,
						 codproj,
						 nossonum,
						 historico,
						 codtipoper,
						 recdesp,
						 origem,
						 desdobramento,
						 provisao,
						 dtalter,
						 dhtipoper,
						 dhmov,
						 codtiptit,
						 desdobdupl,
						 codbco,
						 codctabcoint,
						 linhadigitavel,
						 vlrdesc,
						 ordemcarga,
						 autorizado)
					Values
						(v_newnufin,
						 r_Mul.codempfin,
						 p_codmulta,
						 r_Mul.valormulta,
						 r_mul.codparctransp,
						 Trunc(Sysdate),
						 r_mul.dtvencto,
						 r_mul.dtvencto,
						 --r_par.codnatpag,
						 --Nvl(r_par.codcencusadiant, 0),
						 --Nvl(r_par.codprojadiant, 0),
						 r_par.codnatpag,
						 Nvl(r_par.codcencuspag, 0),
						 Nvl(r_par.codprojpag, 0),
						 Null,
						 r_par.prefixoadiant || '. CÓD. INFRAÇÃO: ' || r_mul.codautuacao || ', OC: ' ||
						 r_mul.ordemcarga,
						 r_par.codtipoperadiant,
						 1,
						 'F',
						 '0',
						 'N',
						 Sysdate,
						 v_dhtipoper,
						 Sysdate,
						 r_par.codtiptitadiant,
						 'ZZ',
						 r_par.codbcoadiant,
						 r_par.codctabcointadiant,
						 r_mul.codbarra,
						 r_Mul.vlrdesconto,
						 0,
						 'S');
				
					Insert Into ad_tblcmf
						(nometaborig, nuchaveorig, nometabdest, nuchavedest)
					Values
						('AD_MULCONTROL', p_codmulta, 'TGFFIN', v_newnufin);
				
				End If;
			
			Exception
				When Others Then
					p_mensagem := 'Erro ao gerar despesa para o parceiro - ' || Sqlerrm;
					Raise;
			End;
		
		End If;
		-- pago pelo transportador = sim
		-- gera reembolso
	Else
		Begin
			v_newnufin  := seq_tgffin_nufin.nextval;
			v_dhtipoper := ad_get.maxdhtipoper(r_par.codtipoperreemb);
			Insert Into tgffin
				(nufin,
				 codemp,
				 numnota,
				 vlrdesdob,
				 codparc,
				 dtneg,
				 dtvenc,
				 dtvencinic,
				 codnat,
				 codcencus,
				 codproj,
				 nossonum,
				 historico,
				 codtipoper,
				 recdesp,
				 origem,
				 desdobramento,
				 provisao,
				 dtalter,
				 dhtipoper,
				 dhmov,
				 codtiptit,
				 codbco,
				 codctabcoint,
				 linhadigitavel,
				 vlrdesc,
				 ordemcarga,
				 autorizado)
			Values
				(v_newnufin,
				 r_Mul.codempfin,
				 p_codmulta,
				 r_Mul.valormulta,
				 r_mul.codparctransp,
				 Trunc(Sysdate),
				 r_mul.dtvencto,
				 r_mul.dtvencto,
				 --r_par.codnatreemb,
				 --Nvl(r_par.codcencusreemb, 0),
				 --Nvl(r_par.codprojreemb, 0),
				 r_par.codnatpag,
				 Nvl(r_par.codcencuspag, 0),
				 Nvl(r_par.codprojpag, 0),
				 Null,
				 r_par.prefixoreemb || '. CÓD. INFRAÇÃO: ' || r_mul.codautuacao || ', OC: ' ||
				 r_mul.ordemcarga,
				 r_par.codtipoperreemb,
				 -1,
				 'F',
				 0,
				 'N',
				 Sysdate,
				 v_dhtipoper,
				 Sysdate,
				 r_par.codtiptitreemb,
				 r_par.codbcoreemb,
				 r_par.codctabcointreemb,
				 0, --r_mul.codbarra, podem existir pagamentos distintos com o mesmo codbarras
				 r_Mul.vlrdesconto,
				 0,
				 'S');
		
			Insert Into ad_tblcmf
				(nometaborig, nuchaveorig, nometabdest, nuchavedest)
			Values
				('AD_MULCONTROL', p_codmulta, 'TGFFIN', v_newnufin);
		
			--Commit;
		Exception
			When Others Then
				p_mensagem := 'Erro ao inserir financeiro I - ' || Sqlerrm;
				Raise;
		End;
	End If;

Exception
	When error Then
		Null;
		--Rollback;
	--Return;
	When Others Then
		p_mensagem := Sqlerrm;
		--Rollback;
	--Return;
End;
/
