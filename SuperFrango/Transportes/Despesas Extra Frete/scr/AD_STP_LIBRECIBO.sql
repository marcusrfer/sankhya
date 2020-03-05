Create Or Replace Procedure "AD_STP_LIBRECIBO"(P_CODUSU Number, P_IDSESSAO Varchar2, P_QTDLINHAS Number,
																							 P_MENSAGEM Out Varchar2) As
	v_Nudef     Number;
	v_codUsuLog Number := stp_get_codusulogado();
	v_NomeUsu   Varchar2(100);
	r_def       ad_tsfdef%Rowtype;
	v_Count     Int := 0;
	v_Titulo    Varchar2(100);
	v_Mensagem  Varchar2(200);
	v_Confirma  Boolean;
	ErrMsg      Varchar2(4000);
	Error Exception;
Begin
	/* 
  Autor: M. Rangel
  Processo: Despesas Extras de Frete
  Objetivo: Realizar a liberação do lançamento direto na tela através da ação "2-Realizar Liberação"
  */

	For I In 1 .. P_QTDLINHAS
	Loop
		v_Nudef := ACT_INT_FIELD(P_IDSESSAO, I, 'NUDEF');
		Select *
			Into r_def
			From ad_tsfdef
		 Where nudef = v_nudef;
		Select u.nomeusu
			Into v_NomeUsu
			From tsiusu u
		 Where u.codusu = v_codUsuLog;
	
		Select Count(*)
			Into v_Count
			From tsilib l
		 Where l.nuchave = v_nudef
			 And l.tabela = 'AD_TSFDEF'
			 And l.dhlib Is Null
			 And l.codusulib = v_codUsuLog
		--And (l.codusulib = v_codUsuLog Or v_codUsuLog = 0) --só pra debugar, remover essa linha antes de publicar
		;
	
		If v_count = 0 Then
			ErrMsg := 'Não existem liberações pendentes para você, ' || v_nomeusu;
			Raise error;
		Else
			Begin
				Update tsilib l
					 Set l.dhlib = Sysdate, l.vlrliberado = l.vlratual
				 Where nuchave = v_Nudef
					 And tabela = 'AD_TSFDEF'
					 And l.codusulib = v_codUsuLog;
			Exception
				When Others Then
					ErrMsg := 'Não foi possível liberar o lançamento. ' || Sqlerrm;
					Raise error;
			End;
		End If;
	
	End Loop;

	P_MENSAGEM := 'Lançamento(s) liberado(s) com sucesso';
Exception
	When error Then
		P_MENSAGEM := ErrMsg;
	When Others Then
		P_MENSAGEM := Sqlerrm;
End;
/
