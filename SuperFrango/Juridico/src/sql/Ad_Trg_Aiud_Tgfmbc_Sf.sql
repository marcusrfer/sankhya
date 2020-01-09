Create Or Replace Trigger Ad_Trg_Aiud_Tgfmbc_Sf
	After Insert Or Update Or Delete On Tgfmbc
	For Each Row
Declare
	v_Tipotransf Number;
Begin
	/*
  * Autor: Marcus Rangel
  * Obejtivo: Tratar cen√°rios e processos customizados que necessitam de intera√ß√£o/continua√ß√£o ap√≥s atualiza√ß√£o na MBC
  */

	If Ad_Pkg_Jur.Processo_Juridico Then
		Return;
	End If;

	If Updating Then
		/*Processo Juridico*/
	
		-- replicar concilia√ß√£o na tela de lan√ßamentos da rotina de despesas jur√≠dicas
		If :New.Ad_Nufinproc Is Not Null And :New.Conciliado = 'S' Then
		
			Begin
				Update Ad_Jurlog l
					 Set l.Conciliado = 'S'
				 Where l.Nubco = :New.Nubco
					 And Nvl(l.Conciliado, 'N') = 'N';
			Exception
				When Others Then
					Raise_Application_Error(-20105,
																	Fc_Formatahtml('Erro ao atualizar o campo conciliaÁ„o no extrato do lanÁamento na tela de despesas',
																								 Sqlerrm,
																								 'Verifique com o suporte'));
			End;
		
		End If;
		/*Fim Processo Juridico*/
	
	End If;
	-- fim update

	If Deleting Then
	
		If :Old.Numtransf Is Not Null And :Old.Ad_Nufinproc Is Null Then
		
			Begin
				Select Case
								 When Numtransf Is Not Null Then
									'T'
								 When Numtransfret Is Not Null Then
									'R'
							 End
					Into v_Tipotransf
					From Ad_Jurmbctr
				 Where Numtransf = :Old.Numtransf
						Or Numtransfret = :Old.Numtransf;
			Exception
				When No_Data_Found Then
					v_Tipotransf := Null;
				When Others Then
					v_Tipotransf := Null;
			End;
		
			If v_Tipotransf Is Null Then
				Return;
				/* Raise_Application_Error(-20105,
        ad_fnc_formataerro('N„o foi possÌvel determinar o tipo de transferÍncia realizado.'));*/
			End If;
		
			Begin
				Update Ad_Jurmbctr m
					 Set m.Numtransf = Case
															 When v_Tipotransf = 'T' Then
																Null
															 Else
																m.Numtransf
														 End,
							 m.Codusutransf = Case
																	When v_Tipotransf = 'T' Then
																	 Null
																	Else
																	 m.Codusutransf
																End,
							 m.Dttransf = Case
															When v_Tipotransf = 'T' Then
															 Null
															Else
															 m.Dttransf
														End,
							 m.Numtransfret = Case
																	When v_Tipotransf = 'R' Then
																	 Null
																	Else
																	 m.Numtransfret
																End,
							 m.Codusuret = Case
															 When v_Tipotransf = 'R' Then
																Null
															 Else
																m.Codusuret
														 End,
							 m.Dtret = Case
													 When v_Tipotransf = 'R' Then
														Null
													 Else
														m.Dtret
												 End
				 Where (Numtransf = :Old.Numtransf Or m.Numtransfret = :Old.Numtransf)
					 And m.Vlrtransf = :Old.Vlrlanc
					 And m.Codcta = :Old.Codctabcoint;
			Exception
				When Others Then
					Raise_Application_Error(-20105,
																	'Erro ao atualizar o numero da transferÍncia no bloqueio em lotes. ' ||
																	Sqlerrm);
			End;
		
		Elsif :Old.Numtransf Is Not Null And :Old.Ad_Nufinproc Is Not Null Then
			Raise_Application_Error(-20105,
															'N„o È possÌvel excluir transferÍncia que est· vinculada a um processo judicial');
		End If;
	End If;

End Ad_Trg_Aiud_Tgfmbc_Sf;
/
