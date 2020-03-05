Create Or Replace Procedure "AD_STP_DESFAZLIB"(P_CODUSU Number, P_IDSESSAO Varchar2, P_QTDLINHAS Number,
																							 P_MENSAGEM Out Varchar2) As
	v_NuChave     Number;
	v_NomeTab     Varchar(20);
	r_def         ad_tsfdef%Rowtype;
	r_Multa       ad_mulcontrol%Rowtype;
	v_count       Int := 0;
	v_NuchaveDest Number;
	v_baixado     Int := 0;
	Errmsg        Varchar2(4000);
	Error Exception;
Begin

	For I In 1 .. P_QTDLINHAS
	Loop
		/* DESPESAS EXTRAS DE FRETE*/
		Begin
			v_NuChave := ACT_INT_FIELD(P_IDSESSAO, I, 'NUDEF');
		
			If v_nuchave Is Not Null Then
			
				v_NomeTab := 'AD_TSFDEF';
			
				Select * Into r_def From ad_tsfdef Where nudef = v_NuChave;
			
				--- se status diferente de Aguardando
				If r_def.status <> 'A' Then
				
					-- verifica se tem pedido 
					Select Count(*)
						Into v_count
						From ad_tblcmf c
					 Where c.nometaborig = 'AD_TSFDEF'
						 And c.nuchaveorig = v_NuChave;
				
					If v_count <> 0 Then
						-- verifica se o pedido de compra está confirmado.
						For c_PedConf In (Select *
																From ad_tblcmf c
															 Where c.nometaborig = 'AD_TSFDEF'
																 And c.nuchaveorig = v_NuChave)
						Loop
							-- verifica o status dos pedidos gerados
							Select (Case
												When statusnota = 'L' Then
												 0
												Else
												 1
											End)
								Into v_baixado
								From tgfcab
							 Where nunota = c_pedconf.nuchavedest;
							-- se pedido confirmado
							If v_baixado = 1 Then
								Errmsg := 'Pedido gerado já confirmado, autorização não pode ser desfeita.';
								Raise error;
							Else
								-- se pedido ainda pendente (exlcui liberação, altera status, exclui pedido)
								Delete From tsilib l
								 Where nvl(l.tabela, 0) = nvl(v_NomeTab, 0)
									 And l.nuchave = v_nuchave;
							
								Update ad_tsfdef d Set d.status = 'A' Where d.nudef = v_NuChave;
							
								Delete From tgfcab Where nunota = c_pedconf.nuchavedest;
							
							End If;
						End Loop;
					Else
						Begin
							Update ad_tsfdef d Set d.status = 'A' Where d.nudef = v_NuChave;
						End;
					End If;
				Else
					errmsg := 'lançamento ainda está pendente, não existe o que desfazer!';
					Raise error;
				End If;
			End If;
		End; -- fim despesa extras frete
	
		/* CONTROLE DE MULTAS */
		Begin
			If v_NuChave Is Null Then
				v_NuChave := ACT_INT_FIELD(P_IDSESSAO, I, 'CODMULCONT');
				v_NomeTab := 'AD_MULCONT';
				Select * Into r_Multa From ad_mulcontrol m Where m.codmulcont = v_NuChave;
			
				If r_Multa.Situacao = 'A' Or r_Multa.Situacao = 'AL' Then
				
					-- verifica se os lançamentos gerados estão baixados
					For c_DestFin In (Select c.nuchaveDest
															From ad_tblcmf c
														 Where (c.nometaborig = 'AD_MULCONTROL' Or c.nometaborig = 'AD_MULCONT')
															 And c.nuchaveorig = r_multa.codmulcont)
					Loop
						Select (Case
											When dhbaixa Is Null Then
											 0
											Else
											 1
										End)
							Into v_baixado
							From tgffin
						 Where nufin = c_DestFin.Nuchavedest;
					
						If v_baixado = 1 Then
							Errmsg := 'O financeiro gerado pela multa (Nufin <a target="_parent" href="' ||
												ad_fnc_urlskw('TGFFIN', c_destfin.nuchavedest) || '"><u>' || c_DestFin.Nuchavedest ||
												'</u></a>' || ') já está baixado, título não pode ser desfeito.';
							Raise Error;
						Else
							-- exclui o finaneiro
							Delete From tgffin Where nufin = c_Destfin.Nuchavedest;
						
							-- exclui a lligação
							Delete From ad_tblcmf c
							 Where (c.nometaborig = 'AD_MULCONTROL' Or c.nometaborig = 'AD_MULCONT')
								 And c.nuchaveorig = v_NuChave;
						
							-- exclui a liberação
							Delete From tsilib l
							 Where nvl(l.tabela, 0) = nvl('AD_MULCONT', 0)
								 And l.nuchave = v_nuchave;
						
							-- volta o status para pendente
							Update ad_mulcontrol m Set m.situacao = 'P' Where m.codmulcont = v_nuchave;
						
						End If;
					
					End Loop;
				
				Elsif r_Multa.Situacao = 'N' Then
					-- exclui a liberação
					Delete From tsilib l
					 Where nvl(l.tabela, 0) = nvl('AD_MULCONT', 0)
						 And l.nuchave = v_nuchave;
				
					-- volta o status para pendente
					Update ad_mulcontrol m Set m.situacao = 'P' Where m.codmulcont = v_nuchave;
				
				Elsif r_Multa.Situacao Not In ('A', 'N') Then
					errmsg := 'Não há o que desfazer para esse lançamento!';
					Raise error;
				End If;
			End If;
		End; -- fim controle de multas
	
		If v_NuChave Is Null Then
			Errmsg := 'Nro único não encontrado!';
			Raise error;
		End If;
	
	End Loop;
	P_MENSAGEM := 'Desfazimento realizado com sucesso!!!';
Exception
	When error Then
		Rollback;
		P_MENSAGEM := Errmsg;
	When Others Then
		Rollback;
		p_mensagem := Sqlerrm;
End;
/
