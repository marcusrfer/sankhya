Create Or Replace Procedure "AD_STP_TFF_DUPLTAB"(p_codusu    Number,
																								 p_idsessao  Varchar2,
																								 p_qtdlinhas Number,
																								 p_mensagem  Out Varchar2) As
	p_newdtvigor Date;
	p_nutab      Number;
	p_NewNutab   Number;
	Error Exception;
Begin

	p_newdtvigor := act_dta_param(p_idsessao, 'NEWDTVIGOR');
	/*Tratativa para faturar a partir do layou html5,os campos data estão sendo passados como float*/
	If p_newdtvigor Is Null Then
		p_newdtvigor := To_Date(Substr(Replace(act_dec_param(P_IDSESSAO, 'NEWDTVIGOR'), '.', ''), 1, 8),
														'yyyymmdd');
	End If;

	If p_qtdlinhas > 1 Then
		p_Mensagem := 'Por favor, selecione uma tabela por vez.';
		Raise error;
	End If;

	For i In 1 .. p_qtdlinhas
	Loop
		p_nutab := act_int_field(p_idsessao, i, 'NUTAB');
		stp_obtemid('AD_TSFTFF', p_NewNutab);
	
		-- tabela
		For T In (Select *
								From ad_tsftff
							 Where nutab = p_Nutab)
		Loop
			Insert Into ad_tsftff
				(nutab, dtinc, dtvigor, modal, ativo, obs, codtipvenda, codusu, descrtab, nutaborig)
			Values
				(p_NewNutab,
				 Sysdate,
				 p_NewDtVigor,
				 t.modal,
				 'S',
				 'Tabela gerada a partir da tabela ' || p_nutab,
				 t.codtipvenda,
				 p_codusu,
				 t.descrtab || ' ' || p_NewDtVigor,
				 p_nutab);
		
			-- despesas
			Insert Into ad_tsfdff
				Select p_NewNutab,
							 dff.nudff,
							 dff.codcdf,
							 dff.valor,
							 dff.tipo,
							 dff.aplicacao,
							 dff.somaicms,
							 dff.vlrmin,
							 dff.pesofrac,
							 dff.calcmesmauf
					From ad_tsfdff dff
				 Where dff.nutab = t.nutab;
		
			-- transportador
			Insert Into ad_tsftrf
				Select trf.nutrf, p_NewNutab, trf.codparc
					From ad_tsftrf trf
				 Where trf.nutab = t.nutab;
		
			For R In (Select *
									From ad_tsfrff rff
								 Where rff.nutab = t.nutab
								 Order By rff.descrregiao)
			Loop
			
				Insert Into ad_tsfrff
					(nurff, nutab, codciddest, descrregiao, pesomin, vlrfretemin, vlrtaxmin, percfrete)
				Values
					(r.nurff,
					 p_NewNutab,
					 r.codciddest,
					 r.descrregiao,
					 r.pesomin,
					 r.vlrfretemin,
					 r.vlrtaxmin,
					 r.percfrete);
			
				-- cidades
				Insert Into ad_tsfcrff
					Select crf.nurff, p_NewNutab, crf.nucrf, crf.codcid, crf.distancia
						From ad_tsfcrff crf
					 Where crf.nutab = t.nutab
						 And crf.nurff = r.nurff;
			
				--preços
				Insert Into ad_tsfpff
					Select pff.nupff, pff.nurff, p_NewNutab, pff.faixaini, pff.faixafim, 0, 0, pff.tipocob
						From ad_tsfpff pff
					 Where pff.nutab = t.nutab
						 And pff.nurff = r.nurff;
			End Loop;
		
		End Loop T;
	
	End Loop i;

	p_mensagem := 'Tabela duplicada com sucesso!!!<br>Gerada a tabela Nro ' || p_NewNutab;

Exception
	When error Then
		Rollback;
	When Others Then
		Rollback;
		p_mensagem := Sqlerrm;
End;
/
