Create Or Replace Procedure "AD_STP_LIBPAGACERTO"(p_codusu    Number,
																									p_idsessao  Varchar2,
																									p_qtdlinhas Number,
																									p_mensagem  Out Varchar2) As
	v_Evento     Number;
	v_NuChave    Number;
	v_Sequencia  Number;
	v_NumLinha   Number;
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
	For i In 1 .. p_qtdlinhas
	Loop
	
		v_NuChave    := Act_Int_Field(p_idsessao, i, 'NUCHAVE');
		v_Valor      := Act_Dec_Field(p_idsessao, i, 'VLRATUAL');
		v_Tabela     := Act_Txt_Field(p_idsessao, i, 'TABELA');
		v_Evento     := Act_Int_Field(p_idsessao, i, 'EVENTO');
		v_SeqCascata := Act_Int_Field(p_idsessao, i, 'SEQCASCATA');
	
		If v_tabela Is Null Then
		
			v_NuChave   := Act_Int_Field(p_idsessao, i, 'NUPASTA');
			v_Sequencia := Act_Int_Field(p_idsessao, i, 'SEQ');
			v_numlinha  := Act_Int_Field(p_idsessao, i, 'NUMLINHA');
		
			Select seqcascata
				Into v_SeqCascata
				From ad_jurlib
			 Where nupasta = v_NuChave
				 And seq = v_Sequencia
				 And numlinha = v_numlinha;
		
			Begin
				Update tsilib
					 Set dhlib       = Sysdate,
							 vlrliberado = vlratual,
							 codusulib = Case
															When p_codusu = 0 Then
															 codusulib
															Else
															 p_codusu
														End
				 Where nuchave = v_NuChave
					 And sequencia = v_Sequencia
					 And seqcascata = v_SeqCascata;
			Exception
				When Others Then
					p_mensagem := 'Erro ao liberar - ' || Sqlerrm;
					Return;
			End;
		
		Else
		
			/*Alteração Gusttavo Lopes não alterar a regra*/
			If v_Tabela = 'AD_CABSOLCPA' Then
				p_mensagem := 'Não pode liberar. Entrar na tela Solicitação de Compra para fazer aprovação.';
				Return;
			End If;
		
			Begin
				Update Tsilib l
					 Set l.Codusulib   = p_codusu,
							 l.Vlrliberado = Round(v_Valor, 2),
							 l.Dhlib       = Sysdate,
							 ad_codusulib  = p_codusu
				 Where Nuchave = v_NuChave
					 And l.evento = v_Evento
					 And Round(l.vlratual, 2) = Round(v_Valor, 2)
					 And (Nvl(l.seqcascata, 0) = Nvl(v_SeqCascata, 0) Or Nvl(v_SeqCascata, 0) = 0)
					 And Nvl(Tabela, 0) = Nvl(v_Tabela, 0);
			
			Exception
				When Others Then
					p_Mensagem := 'Erro ao liberar o evento. ' || Sqlerrm;
					Return;
			End;
		
			/* Tranferir para a Trigger Ad_Trg_Aiud_Tsilib_Sf por Marcus Rangel no dia 31 / 10 / 2017 */
		
			If v_Tabela = 'AD_MULCONT' Then
			
				Stp_Controle_Multa(p_Codmulta => v_NuChave, p_Mensagem => p_mensagem);
			
				If p_mensagem Is Not Null Then
					Return;
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
						p_mensagem := 'Erro ao atualizar o financeiro. ' || Sqlerrm;
						Return;
				End;
			
			End If;
		
		End If;
	
	End Loop;
	p_mensagem := p_qtdlinhas || ' lançamento(s) liberados';
Exception
	When Error Then
		--Rollback;
		p_mensagem := Errmsg;
	When Others Then
		--Rollback;
		p_mensagem := Sqlerrm;
End;
/
