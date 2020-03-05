Create Or Replace Procedure "AD_STP_VERORIGCAB"(P_CODUSU Number, P_IDSESSAO Varchar2, P_QTDLINHAS Number,
																								P_MENSAGEM Out Varchar2) As
	v_nroUnico   Number;
	v_nomeTabela Varchar2(50);
	v_nroChave   Number;
	v_linkOrigem Varchar2(1000);
	v_Count      Int := 0;
	errMsg       Varchar2(400);
	Error Exception;
Begin
	/*
  Autor: Marcus Rangel
  Processo: Despesas Extras de frete
  Objetivo: Criar um lançador na TGFCAB para a origem de telas persoanlizadas do sistema que possuem ligação na tabela TBLCMF
  */
	For I In 1 .. P_QTDLINHAS
	Loop
		v_nroUnico := ACT_INT_FIELD(P_IDSESSAO, I, 'NUNOTA');
	
		Select Count(*)
			Into v_Count
			From ad_tblcmf c
		 Where c.nuchavedest = v_nroUnico;
	
		If v_Count <> 0 Then
		
			Select C.NOMETABORIG, C.Nuchaveorig
				Into v_nomeTabela, v_nroChave
				From ad_tblcmf c
			 Where c.nuchavedest = v_nroUnico
				 And c.nometabdest = 'TGFCAB';
		Else
			Begin
				Select 'AD_TSFDEF', d.nudef
					Into v_nomeTabela, v_nroChave
					From ad_tsfdef d
				 Where d.nunota = v_nroUnico;
			Exception
				When no_data_found Then
					Select 'AD_CABACERTOTRANSP', c.nuacerto
						Into v_nomeTabela, v_nroChave
						From AD_CABACERTOTRANSP c
					 Where c.nunota = v_nroUnico;
			End;
		End If;
	
		If v_nomeTabela Is Null Or v_nroChave Is Null Then
			errmsg := 'Origem não encontrada.';
			Raise Error;
		End If;
	
	End Loop;
	v_linkOrigem := ad_fnc_urlskw(v_nomeTabela, v_nroChave);
	P_MENSAGEM   := 'Clique sobre o número único de origem <a href="' || v_linkOrigem || '" target="_parent">' ||
									'<font color="#FF0000"><b>' || v_nroChave || '</b></font></a>';
Exception
	When error Then
		P_MENSAGEM := errmsg;
	When Others Then
		P_MENSAGEM := errmsg;
End;
/
