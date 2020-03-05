Create Or Replace Procedure "AD_STP_FMP_DUPLCARGTO_SF"(p_codusu Number, p_idsessao Varchar2, p_qtdlinhas Number, p_mensagem Out Varchar2) As
			p_qtdordens Number;
			v_sequencia Number;
			v_newordem  Number;
			v_nroordens Varchar2(100);
			c           ad_contcargto%Rowtype;
Begin

			/* 
   * Autor: M. Rangel
   * Processo: Frete Matéria Prima
   * Objetivo: Gerar duplicações de determinada ordem
   */

			If p_qtdlinhas > 1 Then
						p_mensagem := 'Selecione apenas um registro para duplicação!';
						Return;
			End If;

			p_qtdordens := act_int_param(p_idsessao, 'QTDORDENS');
			--p_qtdordens := 4;

			v_sequencia := act_int_field(p_idsessao, 1, 'SEQUENCIA');
			--v_sequencia := 77156;

			Begin
						Select * Into c From ad_contcargto Where sequencia = v_sequencia;
			Exception
						When Others Then
									Raise;
			End;

			For i In 1 .. p_qtdordens
			Loop
			
						-- busca a numeração
						stp_keygen_tgfnum('AD_CONTCARGTO', 1, 'AD_CONTCARGTO', 'SEQUENCIA', 0, v_newordem);
			
						If v_nroordens Is Null Then
									v_nroordens := v_newordem;
						Else
									v_nroordens := v_nroordens || ', ' || v_newordem;
						End If;
			
						-- insere o cabeçalho
						Begin
									Insert Into ad_contcargto
												(sequencia, codveiculo, status, codusu, codlocal, classificacao, codemp, datahoralanc, tipomov, statusvei)
									Values
												(v_newordem, 0, 'ABERTO', p_codusu, c.codlocal, c.classificacao, c.codemp, Sysdate, c.tipomov, 'AP');
						Exception
									When Others Then
												p_mensagem := 'Erro ao inserir o cabeçalho de nova ordem de carregamento. <br>' || dbms_utility.format_error_stack;
												Return;
						End;
			
						-- percorre os itens
						For s In (Select * From ad_itecargto Where sequencia = v_sequencia Order By ordem)
						Loop
									-- insere os itens
									Begin
												Insert Into ad_itecargto
															(sequencia, ordem, codprod, qtde, codparc, codusu, dataalt, numcontrato)
												Values
															(v_newordem, s.ordem, s.codprod, 0, s.codparc, p_codusu, Sysdate, s.numcontrato);
									Exception
												When Others Then
															p_mensagem := 'Erro ao inserir os itens de nova ordem de carregamento. <br>' || dbms_utility.format_error_stack;
															Return;
									End;
						End Loop;
			
			End Loop;

			p_mensagem := 'Foram geradas ' || p_qtdordens || ' ordens de carregamento (' || v_nroordens || ')!';

End;
/
