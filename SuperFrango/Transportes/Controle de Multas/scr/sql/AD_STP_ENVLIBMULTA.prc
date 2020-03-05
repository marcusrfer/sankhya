Create Or Replace Procedure "AD_STP_ENVLIBMULTA"(P_CODUSU Number, P_IDSESSAO Varchar2, P_QTDLINHAS Number,
																								 P_MENSAGEM Out Varchar2) As
	v_CodMulta   Number;
	v_CodUsuResp tsiusu.codusu%Type;
	v_CodCenCus  tsicus.codcencus%Type;
	r_Multa      ad_mulcontrol%Rowtype;
	v_Lib        Int;
	Errmsg       Varchar2(4000);
	P_COUNT      Int;
	Error Exception;
Begin
	Begin
		Select nvl(cus.codusuresp, 0), cus.codcencus
			Into v_codusuresp, v_codcencus
			From ad_mulpar par, tsicus cus
		 Where par.codemp = 1
			 And par.codcencuspag = cus.codcencus;
	
		-- alteração para mudar o liberador para o resposável pelos transportes
		Select u.codusu
			Into v_codusuresp
			From tsiusu u
		 Where nvl(u.ad_gertransp, 'N') = 'S'
			 And rownum = 1;
	
		-- v_codcencus
		If v_codusuresp = 0 Then
			Errmsg := 'O Centro de Resultado ' || to_char(v_codcencus) ||
								' está sem usuário responsável informado. Não é possível prosseguir.';
			Raise error;
		End If;
	
	Exception
		When Others Then
			Errmsg := 'Houve um problema ao identificar o usuário responsável pelo centro de resultado.';
			Raise error;
	End;

	For I In 1 .. P_QTDLINHAS
	Loop
		v_CodMulta := ACT_INT_FIELD(P_IDSESSAO, I, 'CODMULCONT');
	
	End Loop;

	Select * Into r_Multa From ad_mulcontrol m Where m.codmulcont = v_CodMulta;

	Select Count(*)
		Into P_COUNT
		From tsilib L
	 Where NUCHAVE = r_Multa.CODMULCONT
		 And L.TABELA = 'AD_MULCONT'
	--And L.DHLIB Is Not Null
	;

	If P_COUNT <> 0 Then
		errmsg := 'Já existe liberação para essa multa, proibido reenvio!!!.';
		Raise error;
	
	End If;

	Begin
		Insert Into tsilib
			(nuchave, tabela, evento, codususolicit, dhsolicit, codusulib, vlrlimite, vlratual, sequencia, observacao)
		Values
			(r_Multa.codmulcont, 'AD_MULCONT', 1012, stp_get_codusulogado(), Sysdate, v_codusuresp, 999999999,
			 r_Multa.valormulta, 1, 'Ref. Pagamento de Multa Cód. ' || r_Multa.Codmulcont);
	
		Update ad_mulcontrol m Set m.situacao = 'AL' Where m.codmulcont = r_Multa.Codmulcont;
	
	Exception
		When Others Then
			errmsg := 'Ocorreu um erro ao inserir a liberação. ' || Sqlerrm;
			Raise error;
	End;

	P_MENSAGEM := 'Multa(s) enviada(s) para liberação com sucesso!';

Exception
	When error Then
		P_MENSAGEM := errmsg;
	When Others Then
		P_MENSAGEM := 'Ocorreu um erro - ' || Sqlerrm;
	
End;
/
