Create Or Replace Procedure "STP_JURITE_CANCELA_DESPESA_SF"(P_Codusu Number,
																														-- Código Do Usuário Logado
																														P_Idsessao Varchar2,
																														-- Identificador Da Execução. Serve Para Buscar Informações Dos Parâmetros/Campos Da Execução.
																														P_Qtdlinhas Number,
																														-- Informa A Quantidade De Registros Selecionados No Momento Da Execução.
																														P_Mensagem Out Varchar2
																														-- Caso Seja Passada Uma Mensagem Aqui, Ela Será Exibida Como Uma Informação Ao Usuário.
																														) As
	Field_Nupasta Number;
	Field_Seq     Number;

	--Variáveis Da Ad_Jurite
	V_Nufin    Number;
	V_Situacao Char(1);

	P_Dhbaixa    Date;
	P_Numremessa Number;

	P_Count Int;

	V_Chave Number;
Begin

	If P_Qtdlinhas > 1 Or P_Qtdlinhas = 0 Then
		P_Mensagem := 'Selecione apenas um registro por vez';
		Return;
	End If;

	Field_Nupasta := Act_Int_Field(P_Idsessao, 1, 'NUPASTA');
	Field_Seq     := Act_Int_Field(P_Idsessao, 1, 'SEQ');

	Select I.Nufin
		Into V_Nufin
		From Ad_Jurite I
	 Where I.Nupasta = Field_Nupasta
		 And I.Seq = Field_Seq;

	---Valida Se For Gerado Financeiro
	If Nvl(V_Nufin, 0) = 0 Then
		P_Mensagem := Fc_Formatahtml_Sf('Ação não permitida!',
																		'Registro não possui despesa gerada',
																		'Só é possivel cancelar despesa que tenha gerado financeiro');
		Return;
	End If;

	Select Count(*)
		Into P_Count
		From Tgffin
	 Where Nufin = V_Nufin;

	---Situação: E - Elaborando
	V_Situacao := 'P';

	If P_Count > 0 Then
		Begin
			/* 15/06/2018 - M. Rangel */
			-- pesquisa despesas 
			-- enquanto o lançamento não foi liberado, pois o mesmo vai pra TSILIB, o recdesp permanece 0
			-- nos casos que uma despesa foi gerada por acidente a mesma não será liberada, logo, é necessário desfazer a solicitação de liberação
			-- e excluir o lançamento da TGFFIN
			Select Dhbaixa, Numremessa
				Into P_Dhbaixa, P_Numremessa
				From Tgffin
			 Where Nufin = V_Nufin
				 And recdesp != 0;
		Exception
			When no_data_found Then
				Select Dhbaixa, Numremessa
					Into P_Dhbaixa, P_Numremessa
					From Tgffin
				 Where Nufin = V_Nufin
					 And recdesp = 0
					 And Exists (Select 1
									From tsilib l
								 Where tabela = 'TGFFIN'
									 And l.nuchave = v_nufin);
		End;
	
		---Valida Se O Titulo Financeiro Já Foi Baixado
		If P_Dhbaixa Is Not Null Then
			P_Mensagem := Fc_Formatahtml_Sf('Ação não permitida!',
																			'Registro está baixado',
																			'Só é possivel cancelar despesa caso não tenha sido baixado.');
			Return;
		End If;
	
		---Valida Se O Titulo Financeiro Já Foi Gerado Remessa
		If Nvl(P_Numremessa, 0) > 0 Then
			P_Mensagem := Fc_Formatahtml_Sf('Ação não permitida!',
																			'Registro está com a remessa gerada',
																			'Só é possivel cancelar despesa caso não tenha sido gerado remessa');
			Return;
		End If;
	
		Select Count(*)
			Into P_Count
			From Tgfmbc Mbc
		 Where Mbc.Ad_Nufinproc = V_Nufin;
	
		---Valida Se O Titulo Financeiro Está Vinculado A Mov. Bancária
		If Nvl(P_Count, 0) > 0 Then
			P_Mensagem := Fc_Formatahtml_Sf('Ação não permitida!',
																			'Registro está vinculado a Mov. Bancária',
																			'Só é possivel cancelar despesa caso não tenha vinculo');
			Return;
		End If;
	
	End If;

	Delete From Tsilib
	 Where Nuchave = V_Nufin
		 And Evento In (1001, 1014);

	V_Chave := To_Number(To_Char(Field_Nupasta || Field_Seq));

	Delete From Ad_Tblcmf
	 Where Nometaborig = 'AD_JURITE'
		 And Nuchaveorig = V_Chave;

	Delete From Tgffin
	 Where Nufin = V_Nufin;

	Update Ad_Jurite
		 Set Nufin      = Null,
				 Situacao   = V_Situacao,
				 Codusucan  = P_Codusu,
				 Dhcanc     = Sysdate,
				 Nufincanc  = V_Nufin,
				 Codusudesp = Null,
				 Dhdesp     = Null,
				 Codusujur  = Null,
				 Dhjur      = Null,
				 Codusufin  = Null,
				 Dhfin      = Null
	 Where Nupasta = Field_Nupasta
		 And Seq = Field_Seq;

	P_Mensagem := 'Cancelado com sucesso!!!' || Chr(13) || Chr(10) || '<i> Nr. Financeiro: ' || V_Nufin || '</i>.';

End;
/
