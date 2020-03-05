Create Or Replace Procedure "AD_STP_REPROVLIB"(p_codusu Number, p_idsessao Varchar2, p_qtdlinhas Number, p_mensagem Out Varchar2) As
	param_motivo     Varchar2(4000);
	field_nuchave    Number;
	field_tabela     Varchar2(4000);
	field_evento     Number;
	field_sequencia  Number;
	field_seqcascata Number;
	field_nucll      Number;
Begin

	param_motivo := act_txt_param(p_idsessao, 'MOTIVO');

	For i In 1 .. p_qtdlinhas -- este loop permite obter o valor de campos dos registros envolvidos na execu��o.
	Loop
		-- a vari�vel "I" representa o registro corrente.
		field_nuchave := act_int_field(p_idsessao, i, 'NUCHAVE');
		field_tabela  := act_txt_field(p_idsessao, i, 'TABELA');
	
		/*altera��o gusttavo lopes n�o alterar a regra*/
		If field_tabela = 'AD_CABSOLCPA' Then
			p_mensagem := 'N�o pode reprovar. Entrar na tela Solicita��o de Compra para fazer a reprova��o.';
			Return;
		End If;
	
		Select evento
			Into field_evento
			From tsilib
		 Where nuchave = field_nuchave
			 And tabela = field_tabela
			 And codusulib = p_codusu;
	
		Begin
			Update tsilib l
				 Set l.reprovado = 'S', l.obslib = param_motivo, l.dhlib = Sysdate
			 Where l.nuchave = field_nuchave
				 And l.tabela = field_tabela
				 And Nvl(l.evento, 0) = Nvl(field_evento, 0)
				 And codusulib = p_codusu;
			If Sql%Rowcount = 0 Then
				p_mensagem := 'O lan�amento n�o foi encontrado. Nro:' || field_nuchave || '. Tabela: ' || field_tabela || '. Evento: ' ||
											field_evento;
				Return;
			End If;
		Exception
			When Others Then
				p_mensagem := 'Erro ao reprovar lan�amento - ' || Sqlerrm;
				Return;
		End;
	
	End Loop;
	p_mensagem := 'Lan�ameto(s) reprovado com sucesso.';

End;
/
