Create Or Replace Procedure "AD_STP_GERAMULTA"(P_CODUSU Number, P_IDSESSAO Varchar2, P_QTDLINHAS Number,
																							 P_MENSAGEM Out Varchar2) As
	v_CodNotif   Number;
	r_Not        AD_MULNOTIF%Rowtype;
	v_Count      Int := 0;
	v_CodMulCont Number;
	Error Exception;
	Errmsg Varchar2(4000);
Begin

	For I In 1 .. P_QTDLINHAS
	Loop
		v_CodNotif := ACT_INT_FIELD(P_IDSESSAO, I, 'CODMULNOTIF');
		Select * Into r_Not From AD_MULNOTIF Where codmulnotif = v_CodNotif;
	
		Begin
			Select Count(*) Into v_Count From ad_mulcontrol m Where upper(m.codautuacao) = upper(r_Not.Codautuacao);
		Exception
			When no_data_found Then
				v_Count := 0;
		End;
	
		If v_Count = 0 Then
			Select Max(codmulcont) + 1 Into v_CodMulCont From ad_mulcontrol;
		
			Insert Into ad_mulcontrol
				(codmulcont, codemp, ordemcarga, codautuacao, codparc, dtinfracao, Local, codcid, situacao, dtcad, codusucad,
				 historico, codinfracao, codparctransp, codveiculo, codparcmot)
			Values
				(v_CodMulCont, r_Not.Codemp, r_not.ordemcarga, r_Not.Codautuacao, r_Not.Codparc, r_Not.Dtmulta, r_Not.Local,
				 r_Not.Codcid, 'P', Sysdate, stp_get_codusulogado(), r_Not.Observacao, r_Not.Codinfracao, r_Not.Codparctransp,
				 r_Not.Codveiculo, r_Not.Codmotorista);
		
		Else
			Errmsg := 'Já existe multa para essa autuação!';
			Raise error;
		End If;
	
	End Loop;
	p_Mensagem := 'Gerada a Multa de Nro Único: ' || '<a href="' || ad_fnc_urlskw('AD_MULCONTROL', v_CodMulCont) ||
								'" target="_parent" title="Visualizar Multa">' || '<font color="#0000FF"><b>' || v_CodMulCont ||
								'</b></font></a>';
Exception
	When error Then
		p_Mensagem := Errmsg;
End;
/
