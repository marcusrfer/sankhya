Create Or Replace Procedure "STP_JURITE_GERA_DESPESA_SF"(p_Codusu Number,
																												 -- Código Do Usuário Logado
																												 p_Idsessao Varchar2,
																												 -- Identificador Da Execução. Serve Para Buscar Informações Dos Parâmetros/Campos Da Execução.
																												 p_Qtdlinhas Number,
																												 -- Informa A Quantidade De Registros Selecionados No Momento Da Execução.
																												 p_Mensagem Out Varchar2
																												 -- Caso Seja Passada Uma Mensagem Aqui, Ela Será Exibida Como Uma Informação Ao Usuário.
																												 ) As
	Field_Nupasta Number;
	Field_Seq     Number;

	---Variáveis Da Ad_Jurite
	r_Ite      Ad_Jurite%Rowtype;
	v_Nufin    Int;
	v_Situacao Char(1);

	v_Codtiptit Int;
	v_Provisao  Char(1);

	v_Codtipoper Number(5);
	v_Dhtipoper  Date;

	v_Count Int;

	p_Dtnegociacao Date;
	p_Dtvencimento Date;

	v_Eventojur Int := 0;
	v_Eventofin Int := 0;

	v_Codusulib  Number;
	v_Nometabori Varchar(20);
	v_Nometabdes Varchar(20);
	v_Nometablib Varchar(20);

	v_Chave   Number;
	v_Recdesp Number;

	p_Observacao Varchar2(255);
	p_Numnota    Number;

	Errmsg Varchar2(4000);
	Error Exception;

Begin

	If p_Qtdlinhas > 1 Or p_Qtdlinhas = 0 Then
		p_Mensagem := 'Selecione apenas um registro por vez';
		Return;
	End If;

	Field_Nupasta := Act_Int_Field(p_Idsessao, 1, 'NUPASTA');
	Field_Seq     := Act_Int_Field(p_Idsessao, 1, 'SEQ');

	If p_Idsessao = 'AAA' Then
		Field_Nupasta := 4116;
		Field_Seq     := 2;
	
	End If;

	Select *
		Into r_Ite
		From Ad_Jurite
	 Where Nupasta = Field_Nupasta
		 And Seq = Field_Seq;

	v_Codtipoper := Case
										When r_Ite.Codnat = 4012700 Then
										 160
										Else
										--704
										--Em 07/12/2017, Por Ricardo Soares de Oliveira, conforme orientações Wander todos os registros que são gerados com a 704 devem ser gerados com a 708
										 708
									End; ---Ctas A Pgar A Vista 

	v_Provisao := 'S'; ---Provisão = Sim

	If Nvl(r_Ite.Numdoc, '0') = '0' Then
		p_Numnota := Field_Nupasta || Lpad(Field_Seq, 3, 0);
	Else
		p_Numnota := r_Ite.Numdoc;
	End If;

	v_Nometabori := 'AD_JURITE';
	v_Nometabdes := 'TGFFIN';
	v_Nometablib := 'TGFFIN';

	If r_Ite.Codnat = 4012700 Then
		v_Codtiptit := 59;
	Elsif r_Ite.Forma = 'D' Then
		v_Codtiptit := 21; --- Credito Em C/C
		---Valida Se A Forma É Deposito, Logo É Obrigatorio Favorecido, Cpf, Cód. Banco, Agência, Conta.
		If Nvl(r_Ite.Sequencia, 0) = 0 And
			 (r_Ite.Favorecido Is Null Or r_Ite.Cpf Is Null Or r_Ite.Codbco Is Null Or r_Ite.Agencia Is Null Or r_Ite.Conta Is Null) Then
			p_Mensagem := Fc_Formatahtml_Sf('Ação cancelada!',
																			'Dados incompletos',
																			'Ao selecionar a Forma de Pagamento Depósito é necessário informar <b>Conta do Parceiro</b> ou <i>Nome CPF, Banco, Agência e Conta do Favorecido</i>');
			Return;
		End If;
		--        If R_Ite.Sequencia Is Null Then
		--            P_Mensagem := Fc_Formatahtml_Sf('Ação não permitida!', 'Registro não permite gerar despesa', 'Só é possivel gerar despesa do tipo Depósito quando a conta báncaria for informada');
		--            Return;
		--        End If;
	Elsif r_Ite.Forma = 'G' Then
		v_Codtiptit := 49; --- Guia Recolhimento
	Elsif r_Ite.Forma = 'B' Then
		v_Codtiptit := 5; --- Boleta
	Elsif r_Ite.Forma = 'R' Then
		v_Codtiptit := 6; --- Dinheiro
	Else
		v_Codtiptit := 0;
	End If;

	v_Recdesp := (Case
								 When Nvl(r_Ite.Adto, 'N') = 'S' Then
									0
								 Else
									-1
							 End);

	---Valida Se For Gerado Financeiro
	If Nvl(r_Ite.Nufin, 0) > 0 Then
		p_Mensagem := Fc_Formatahtml_Sf('Ação não permitida!',
																		'Registro não permite gerar despesa',
																		'Só é possivel gerar despesa quando não tiver sido gerado financeiro');
		Return;
	End If;

	---Valida Se A Situação É Diferente De Aguardando Confirmação
	/*IF r_Ite.Situacao <> 'P' THEN
        p_Mensagem := Fc_Formatahtml_Sf('Ação não permitida!', 'Situação do registro não permite gerar despesa', 'Só é possivel gerar despesa quando situação for igual a <b>Aguardando Confirmação</b>');
        RETURN;
  END IF;*/

	---Registro Já Está Vencido
	If (r_Ite.Dtvenc < Trunc(Sysdate)) Then
		p_Mensagem := Fc_Formatahtml_Sf('Ação não permitida!',
																		'Registro está vencido',
																		'Só é possivel gerar despesa quando o registro não estiver vencido.');
		Return;
	End If;

	v_Dhtipoper := Ad_Get.Maxdhtipoper(v_Codtipoper);

	---Valida Se A Top Está existe
	If v_Dhtipoper Is Null Then
		p_Mensagem := Fc_Formatahtml_Sf('Ação cancelada!',
																		'TOP não existe ou inativa',
																		'Verificar se a TOP (' || v_Codtipoper || ') está correta.');
		Return;
	End If;

	Select Count(*)
		Into v_Count
		From Tgftit
	 Where Codtiptit = v_Codtiptit
		 And Ativo = 'S';

	---Valida Se O Tipo De Titulo Está Ativo
	If v_Count Is Null Then
		p_Mensagem := Fc_Formatahtml_Sf('Ação cancelada!',
																		'Tipo de titulo não existe ou inativo',
																		'Verificar se a Tipo de Titulo (' || v_Codtiptit || ') está correta.');
		Return;
	End If;

	---Pega A Data Minima Possivel De Vencimento
	p_Dtnegociacao := Trunc(Sysdate);
	p_Dtvencimento := Ad_Get.Datavencimento(p_Dtnegociacao);

	---Caso O Vencimento Seja Maior Do Que A Data Minima Da Validação, Irá Para O Evento (1014) De Liberação Do Juridico
	---Caso O Vencimento Seja Menor Ou Igual A Data Minima Da Validação, Irá Para O Evento (1001) De Liberação Do Financeiro
	-- 1014 - Aprova Gerência Despesa - Juridico
	-- Por Ricardo Soares em 04/09/2017, passamos a tratar tambem o lançamento de multa de fgts nesse processo, e quando for assim será encaminhado para o RH com o evento 1035
	-- Por Ricardo Soares em 01/02/2018 tudo passou para 1035
	v_Eventojur := 1035; /*CASE
                           WHEN r_Ite.Codnat = 4012700 THEN
                            1035
                           ELSE
                            1014
                     END;*/

	If (r_Ite.Dtvenc <= Trunc(p_Dtvencimento)) Then
		-- 1001 - Aprova Urgência Financeiro - Financeiro
		--V_Eventofin := 1001;
		/*Comentário Por Ricardo Soares de Oliveira em 24/11/2016
    O processo inicialmente foi desenvolvido para solicitar liberação do financeiro, por decisão do Flávio em reunião colocamos uma trava
    e orientamos o usuário sobre a ação*/
		p_Mensagem := Fc_Formatahtml_Sf('Ação cancelada!',
																		'Vencimento inválido',
																		'Por orientação do departamento financeiro o vencimento deve ser superior a ' ||
																		p_Dtvencimento ||
																		' portanto informe uma data posterior a esta e entre em contato direto com o financeiro solicitando o pagamento antecipado');
		Return;
	End If;

	/*If (R_Ite.Dtvenc <= P_Dtvencimento) Then
  -- 1001 - Aprova Urgência Financeiro - Financeiro
       V_Eventofin := 1001;
  End If;*/

	/* p_Mensagem := Fc_Formatahtml_Sf('Ação cancelada!', 'V_CODTIPOPER: ' ||
                                   v_Codtipoper, 'V_CODTIPTIT ' ||
                                   v_Codtiptit);
  RETURN;*/
	---Definir O Nr. Unico Do Financeiro
	-- Stp_Obtemid('TGFFIN', v_Nufin);
	-- Por Ricardo Soares em 20/12/2017. Troquei a STP_OBTEMID conforme orientações Gualberto
	stp_keygen_nufin(P_ULTCOD => V_Nufin);

	Select reclamante || ' - ' || r_ite.numprocesso
		Into r_ite.obsfin
		From ad_jurcab
	 Where nupasta = r_ite.nupasta;

	Insert Into Tgffin
		(Nufin, Codemp, Numnota, Dtneg, Desdobramento, Dhmov, Dtvencinic, Dtvenc, Codparc, Codtipoper, Dhtipoper, Codbco, Codnat,
		 Codcencus, Codproj, Codvend, Codmoeda, Vlrdesdob, Recdesp, Provisao, Origem, Nunota, Rateado, Dtentsai, Dtalter, Numcontrato,
		 Ordemcarga, Codusu, Codcontato, Codtiptit, Dhbaixa, Codtipoperbaixa, Dhtipoperbaixa, Codctabcoint, Sequencia, Historico,
		 Ad_Codusuinc)
		Select v_Nufin, r_Ite.Codemp, p_Numnota As Numnota, Trunc(Sysdate) As Dtneg, 1 As Desdobramento, Sysdate, r_Ite.Dtvenc,
					 r_Ite.Dtvenc, r_Ite.Codparc, v_Codtipoper As Codtipoper, v_Dhtipoper, Nvl(r_Ite.Codbco, 0), r_Ite.Codnat,
					 r_Ite.Codcencus, 0 As Codproj, 0 As Codvend, 0 As Codmoeda, r_Ite.Valor, v_Recdesp, v_Provisao, 'F' As Origem,
					 Null As Nunota, 'N' As Rateado, Trunc(Sysdate) As Dtentsai, Sysdate As Dtalter, 0 As Numcontrato, 0 As Ordemcarga,
					 p_Codusu, Null As Codcontato, v_Codtiptit, Null As Dhbaixa, 0 As Codtipoperbaixa, '01/01/1998' As Dhtipoperbaixa,
					 Null As Codctabcoint, 1 As Sequencia, Nvl(r_Ite.Obsfin, ' '), p_Codusu
			From Dual;

	-- Insere Registro Na Tsilib Do Evento Juridico E Evento Financeiro
	Begin
	
		If Nvl(v_Eventojur, 0) > 0 Then
			v_Count := 0;
		
			Select Count(*)
				Into v_Count
				From Tsilib
			 Where Nuchave = v_Nufin
				 And Tabela = v_Nometablib
				 And Evento = v_Eventojur;
		
			v_Codusulib := Case
											 When r_Ite.Codnat = 4012700 Then
												993
											 Else
												1018
										 End;
		
			If v_Count = 0 Then
				If Length(r_Ite.Obsjur) > 250 Then
					p_Observacao := Substr(r_Ite.Obsjur, 1, 255);
				Else
					p_Observacao := 'Ref. Pasta Nº ' || To_Char(Field_Nupasta) || ' - Seq.: ' || Field_Seq || '.' || r_Ite.Obsjur;
				End If;
			
				Insert Into Tsilib
					(Nuchave, Tabela, Evento, Codususolicit, Dhsolicit, Codusulib, Vlrlimite, Vlratual, Sequencia, Observacao)
				Values
					(v_Nufin, v_Nometablib, v_Eventojur, p_Codusu, Sysdate, v_Codusulib, r_Ite.Valor, r_Ite.Valor, 0, p_Observacao);
			Else
				Update Tsilib
					 Set Vlratual = r_Ite.Valor, Codususolicit = p_Codusu, Codusulib = v_Codusulib, Dhlib = Null
				 Where Nuchave = v_Nufin
					 And Tabela = v_Nometablib
					 And Evento = v_Eventojur;
			End If;
		End If;
	
		If Nvl(v_Eventofin, 0) > 0 Then
			v_Count := 0;
		
			Select Count(*)
				Into v_Count
				From Tsilib
			 Where Nuchave = v_Nufin
				 And Tabela = v_Nometablib
				 And Evento = v_Eventofin;
		
			If v_Count = 0 Then
				p_Observacao := 'Ref. Pasta Nº ' || To_Char(Field_Nupasta) || ' - Seq.: ' || Field_Seq || '.';
			
				Insert Into Tsilib
					(Nuchave, Tabela, Evento, Codususolicit, Dhsolicit, Codusulib, Vlrlimite, Vlratual, Sequencia, Observacao)
				Values
					(v_Nufin, v_Nometablib, v_Eventofin, p_Codusu, Sysdate, 0, r_Ite.Valor, r_Ite.Valor, 0, p_Observacao);
			Else
				Update Tsilib
					 Set Vlratual = r_Ite.Valor, Codususolicit = p_Codusu, Codusulib = 0, Dhlib = Null
				 Where Nuchave = v_Nufin
					 And Tabela = v_Nometablib
					 And Evento = v_Eventofin;
			End If;
		End If;
	Exception
		When Others Then
			Errmsg := 'Erro ao inserir solicitação de liberação pendente.' || Sqlerrm;
			Raise Error;
	End;

	-- Insere Registro Na Ad_Tblcmf
	Begin
		v_Count := 0;
		v_Chave := To_Number(To_Char(Field_Nupasta || Field_Seq));
	
		Select Count(*)
			Into v_Count
			From Ad_Tblcmf
		 Where Nometaborig = v_Nometabori
			 And Nuchaveorig = v_Chave;
	
		If v_Count = 0 Then
			Insert Into Ad_Tblcmf
				(Nometaborig, Nuchaveorig, Nometabdest, Nuchavedest)
			Values
				(v_Nometabori, v_Chave, v_Nometabdes, v_Nufin);
		Else
			Update Ad_Tblcmf
				 Set Nuchavedest = v_Nufin, Nometabdest = v_Nometabdes
			 Where Nometaborig = v_Nometabori
				 And Nuchaveorig = v_Chave;
		End If;
	Exception
		When Others Then
			Errmsg := 'Erro ao inserir a ligação na tabela (AD_TBLCMF).' || Sqlerrm;
			Raise Error;
	End;

	---Situação: D - Aguardando Aprovação Despesa
	v_Situacao := 'D';

	Update Ad_Jurite
		 Set Nufin = v_Nufin, Situacao = v_Situacao, Codusudesp = p_Codusu, Dhdesp = Sysdate
	 Where Nupasta = Field_Nupasta
		 And Seq = Field_Seq;

	p_Mensagem := 'Gerado com sucesso!!!' || Chr(13) || Chr(10) || '<i> Nr. Financeiro: ' || v_Nufin || '</i>.';
	--Exception
	--         When                     
End;
/
