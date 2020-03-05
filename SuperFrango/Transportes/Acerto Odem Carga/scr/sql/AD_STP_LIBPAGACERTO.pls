Create Or Replace Procedure "AD_STP_LIBPAGACERTO"(Pcodusu    Number,
																									Pidsessao  Varchar2,
																									Pqtdlinhas Number,
																									Pmensagem  Out Varchar2) As
	v_Evento     Number;
	v_NuChave    Number;
	v_Valor      Float;
	v_Tabela     Varchar2(50);
	v_SeqCascata Int;
	Errmsg       Varchar2(4000);
	Error Exception;
Begin
	/*
  Autor: Marcus Rangel
  Dt. Criação: 31/08/2016
  Objetivo: Atender o processo de autorização de pagamento de acerto. liberar o pagamento do título.
  */
	For i In 1 .. Pqtdlinhas
	Loop
		v_NuChave    := Act_Int_Field(Pidsessao, i, 'NUCHAVE');
		v_Valor      := Act_Dec_Field(Pidsessao, i, 'VLRATUAL');
		v_Tabela     := Act_Txt_Field(Pidsessao, i, 'TABELA');
		v_Evento     := Act_Int_Field(Pidsessao, i, 'EVENTO');
		v_SeqCascata := Act_Int_Field(Pidsessao, i, 'SEQCASCATA');
	
		/*if pidsessao = '112233b' then
    v_Evento     := 1035;
        v_NuChave    := 26694529;
        v_Valor      := 512.76;
        v_Tabela     := 'TGFCAB';
        v_SeqCascata := 1;
    end if;*/
		/*Alteração Gusttavo Lopes não alterar a regra*/
		If v_Tabela = 'AD_CABSOLCPA' Then
			Errmsg := 'Não pode liberar. Entrar na tela Solicitação de Compra para fazer aprovação.';
			Raise Error;
		End If;
	
		Begin
			Update Tsilib l
				 Set l.Codusulib   = Pcodusu,
						 l.Vlrliberado = Round(v_Valor, 2),
						 l.Dhlib       = Sysdate,
						 ad_codusulib  = Pcodusu
			 Where Nuchave = v_NuChave
				 And l.evento = v_Evento
				 And Round(l.vlratual, 2) = Round(v_Valor, 2)
				 And (Nvl(l.seqcascata, 0) = Nvl(v_SeqCascata, 0) Or Nvl(v_SeqCascata, 0) = 0)
				 And Nvl(Tabela, 0) = Nvl(v_Tabela, 0);
		
		Exception
			When Others Then
				Errmsg := 'Erro ao liberar o evento. ' || Sqlerrm;
				Raise Error;
		End;
		/*
      Alteração: Inclusão de teste de tabela origem para que a rotina possa trabalhar com diferentes
                 tipos de liberações.
      Data: 10/10/2016
      Autor: Guilherme Hahn
    */
	
		/*  Tranferir para a trigger Ad_Trg_Aiud_Tsilib_Sf por Marcus Rangel no dia 31/10/2017 */
		If v_Tabela = 'AD_MULCONT' Then
			Stp_Controle_Multa(p_Codmulta => v_NuChave, p_Mensagem => Pmensagem);
			If Pmensagem Is Not Null Then
				Errmsg := Pmensagem;
				Raise Error;
			End If;
		Elsif v_Tabela <> 'AD_MULCONT' And v_Tabela <> 'AD_TSFCAPSOL' And v_Tabela <> 'TGFCAB' Then
			--Ricardo Soares comentou em 09/03/2017 pois esse comando falta condições
			--Elsif v_Tabela = 'TGFFIN' And Vevento In (1010, 1011, 1012, 1013, 1028, 1030) Then
			Begin
			
				Update Tgffin f
					 Set Provisao = 'N', f.Autorizado = 'S'
				 Where Nufin = v_NuChave
					 And f.provisao = 'S'
					 And Nvl(f.autorizado, 'N') = 'N';
				--Commit;
			Exception
				When Others Then
					Errmsg := 'Erro ao atualizar o financeiro. ' || Sqlerrm;
					Raise Error;
			End;
		End If;
	
	End Loop;
	Pmensagem := Pqtdlinhas || ' lançamento(s) liberados';
Exception
	When Error Then
		--Rollback;
		Pmensagem := Errmsg;
	When Others Then
		--Rollback;
		Pmensagem := Sqlerrm;
End;
/
