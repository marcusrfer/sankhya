Create Or Replace Trigger AD_TRG_BIUD_JURITE_SF
	Before Insert Or Update Or Delete On SANKHYA.AD_JURITE
	For Each Row
Begin

	If deleting Then
		Return;
	End If;

	/* Status
     A - Em Andamento
     E - Encerrado
     P - Pendente
  */

	/* TIPOS
  AC - Acordo
  CU - Custas
  DI - Distrato
  DR - Depósito Recursal
  HO - HonorÃ¡rios
  HP - HonorÃ¡rios Periciais
  MF - Multa FGTS (Origem RH)
  MU - Multas
  OT - Outras Despesas
  RO - Recurso OrdinÃ¡rio
  SC - Sentença CÃ­veis e Outras
  ST - Sentença Trabalhista
  */
	-----Regras De Validação Do Insert
	If Inserting Then
	
		If Length(:new.Numprocesso) <> 20 Then
			Raise_Application_Error(-20105,
															Fc_Formatahtml_Sf('Número do processo incompleto',
																								'Por favor informe os 20 números que compõe o número do processo.',
																								Null));
		End If;
	
		:new.Numprocesso := ad_pkg_jur.fmt_numprocesso(:new.Numprocesso);
	
	End If;

	If inserting Or updating Then
		If :new.Numdoc Is Null Then
			--:new.Numdoc := Replace(To_Char(Sysdate), '/', '');
			:new.numdoc := :new.nupasta || Rpad(:new.seq, 4, '0');
		End If;
	End If;

	-- Validação Caso A Situação Seja Diferente De Elaborando E Os
	-- Campos (Codemp, Codparc, Codcencus, Codnat, Forma, Valor, Dtvenc, Numprocesso, Cpf, Codbco, Agencia, Conta)
	-- Não Podem Ser Alterados.

	If :New.Situacao Not In ('P') And (Updating('CODEMP') Or Updating('CODPARC') Or Updating('AGENCIA') Or Updating('CODCENCUS') Or
		 Updating('CODNAT') Or Updating('FORMA') Or Updating('VALOR') Or Updating('DTVENC') Or
		 Updating('CONTA') Or Updating('NUMPROCESSO') Or Updating('CPF') Or Updating('CODBCO')) Then
	
		Raise_Application_Error(-20101,
														Fc_Formatahtml_Sf('Ação cancelada!',
																							'As alterações só podem ser executadas em despesas que estão sendo elaboradas',
																							Null));
	
	End If;

	If (Inserting Or Updating('FORMA') Or Updating('SEQUENCIA') Or Updating('FAVORECIDO') Or Updating('CPF') Or Updating('CODBCO') Or
		 Updating('AGENCIA') Or Updating('CONTA')) And :New.Forma = 'D' And :New.Sequencia Is Null And
		 (:New.Favorecido Is Null Or :New.Cpf Is Null Or :New.Codbco Is Null Or :New.Agencia Is Null Or :New.Conta Is Null) Then
		Raise_Application_Error(-20101,
														Fc_Formatahtml_Sf('Forma de Pagamento',
																							'A conta do parceiro ou os dados do Favorecido deve ser informado',
																							Null));
	End If;

	/*
  If Updating('OBSJUR') And :New.Situacao In ('D', 'J') Then
  
    Update Tsilib
       Set Observacao = 'Ref. Pasta NÂº ' || :New.Nupasta || ' - Seq.: ' || :New.Sequencia || '.' || Substr(:New.Obsjur, 1, 220)
     Where Nuchave = :New.Nufin
       And Tabela = 'TGFFIN';
    Commit;
  
  End If;*/

	/*
  If Updating('OBSFIN') And :New.Situacao In ('D', 'J') Then
    Update Tgffin
       Set Historico = 'Ref. Pasta NÂº ' || :New.Nupasta || ' - Seq.: ' || :New.Sequencia || '.' || Substr(:New.Obsjur, 1, 220)
     Where Nufin = :New.Nufin;
    Commit;
  
  End If;
  */

	If :new.Numprocesso Is Null Then
		Raise_Application_Error(-20105,
														fc_formatahtml_sf(P_MENSAGEM => 'Erro ao processar o lançamento',
																							P_MOTIVO   => 'Número do processo não informado',
																							P_SOLUCAO  => 'informar o número do processo',
																							P_ERROR    => Null));
	End If;

	If updating('NUMPROCESSO') Then
		If Length(Regexp_Replace(:new.Numprocesso, '[^Aa-Zz]+')) > 0 Then
			Raise_Application_Error(-20105,
															Fc_Formatahtml_Sf('Formato do número do processo incorreto',
																								'Insira apenas números no campo Nro do Processo',
																								Null));
		End If;
	
		:new.Numprocesso := Substr(Lpad(Replace(Replace(Ltrim(Rtrim(Regexp_Replace(:new.numprocesso, '[^0-9]+', Null))), '-', ''),
																						'/',
																						''),
																		20,
																		'0'),
															 1,
															 20);
	
		If Length(:new.Numprocesso) <> 20 Then
		
			Raise_Application_Error(-20105,
															Fc_Formatahtml_Sf('Número do processo incompleto',
																								'Por favor informe os 20 números que compõe o número do processo.',
																								Null));
		End If;
	
		:new.Numprocesso := ad_pkg_jur.fmt_numprocesso(:new.Numprocesso);
	End If;

End AD_TRG_BIUD_JURITE_SF;
/
