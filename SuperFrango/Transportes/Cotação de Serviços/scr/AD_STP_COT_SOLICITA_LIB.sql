Create Or Replace Procedure "AD_STP_COT_SOLICITA_LIB"(p_Codusu    Number,
																											p_Idsessao  Varchar2,
																											p_Qtdlinhas Number,
																											p_Mensagem  Out Varchar2) As
	v_NumCot    Number;
	v_Codusulib Int;
	v_ValorCot  Float;
	v_Count     Int := 0;
	status_lib  Varchar2(100);

Begin
	/*Objeto criado por Marcus Rangel para enviar a cotação de serviços de transporte para liberação do responsável pela área.*/
	For i In 1 .. p_Qtdlinhas
	Loop
		Begin
			Select codusu
				Into v_Codusulib
				From tsiusu
			 Where Nvl(ad_gertransp, 'N') = 'S';
		Exception
			When no_data_found Then
				p_Mensagem := 'Não foi encontrado usuário liberador, por favor verifique se o cadastro do usuário liberador está configurado corretamente.';
				Return;
			When Others Then
				p_Mensagem := 'Erro ao localizar o usuário liberador. ' || Sqlerrm;
				Return;
		End;
	
		v_NumCot := Act_Int_Field(p_Idsessao, i, 'NUMCOTACAO');
	
		Begin
			Select f.vlrtot
				Into v_ValorCot
				From ad_tabcotforn f
			 Where numcotacao = v_NumCot
				 And Nvl(vencedor, 'N') = 'S';
		Exception
			When no_data_found Then
				p_Mensagem := 'Não foram encontrados itens na cotação!';
				Return;
			When too_many_rows Then
				Select f.vlrtot
					Into v_ValorCot
					From ad_tabcotforn f
				 Where numcotacao = v_NumCot
					 And Nvl(vencedor, 'N') = 'S'
					 And rownum = 1;
			When Others Then
				p_Mensagem := Sqlerrm;
				Return;
		End;
	
		Select Count(*)
			Into v_Count
			From tsilib l
		 Where l.nuchave = v_NumCot
			 And l.tabela = 'AD_TABCOTCAB';
	
		If v_Count != 0 Then
			Select Case
							 When dhlib Is Null Then
								'Pendente'
							 Else
								'Aprovada'
						 End
				Into status_lib
				From tsilib l
			 Where l.nuchave = v_NumCot
				 And l.tabela = 'AD_TABCOTCAB';
		
			p_Mensagem := 'Já foi solicitada aprovação para Cotação ' || v_NumCot || ', e a mesma está ' ||
								status_lib;
			Return;
		End If;
	
		ad_set.Ins_Liberacao(p_Tabela    => 'AD_TABCOTCAB',
												 p_Nuchave   => v_NumCot,
												 p_Evento    => 1011,
												 p_Valor     => v_ValorCot,
												 p_Codusulib => v_Codusulib,
												 p_Obslib    => 'Verificar a cotação nro  ' || v_NumCot || '.',
												 p_p_Mensagem    => p_Mensagem);
		If p_Mensagem Is Not Null Then
			Return;
		End If;
	
		ad_set.Ins_Avisosistema(p_Titulo     => 'Solicitação de Aprovação',
														p_Descricao  => 'Favor verificar a cotação nro ' || v_NumCot ||
																						' para maiores detalhes.',
														p_Solucao    => '',
														p_Usurem     => p_Codusu,
														p_Usudest    => v_Codusulib,
														p_Prioridade => 1,
														p_Tabela     => 'AD_TABCOTCAB',
														p_Nrounico   => v_NumCot,
														p_Erro       => p_Mensagem);
		If p_Mensagem Is Not Null Then
			Return;
		End If;
	
		Begin
			Update ad_tabcotcab c
				 Set c.situacao = 'AL'
			 Where c.numcotacao = v_NumCot;
		Exception
			When Others Then
				p_Mensagem := 'Erro ao atualizar a situação da cotação. ' || Sqlerrm;
				Return;
		End;
	
	End Loop;
	
	p_Mensagem := 'Solicitação enviada com sucesso!';

End;
/
