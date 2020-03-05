Create Or Replace Trigger AD_TRG_AIUD_TABCOTFORN_SF
	After Insert Or Update Or Delete On ad_tabcotforn
	For Each Row
Declare
	v_CodSol Number;
	v_Seq    Int := 0;
Begin
	/*
  Autor: Marcus Rangel
  Objetivo: Popular com os serviços e máquinas da solicitação de origem ao informar um fornecedor
  */
	If inserting Then
	
		Select c.codsolst Into v_codsol From ad_tabcotcab c Where c.numcotacao = :new.Numcotacao;
		If Sql%Rowcount = 0 Then
			Return;
		End If;
	
		If v_codsol Is Not Null Then
			For c_Serv In (Select * From ad_tsfssti i Where i.codsolst = v_codsol)
			Loop
				For c_Maq In (Select *
												From ad_tsfsstm m
											 Where m.codsolst = v_codsol
												 And m.codserv = c_Serv.Codserv)
				Loop
					Begin
						v_seq := v_seq + 1;
						Insert Into ad_tabcotite
							(numcotacao, nuregforn, sequencia, codprod, qtdneg, codvol, codmaq, vlrunit, vlrdesconto, vlrtotal)
						Values
							(:new.numcotacao,
							 :new.Nuregforn,
							 v_seq,
							 c_Maq.Codserv,
							 c_maq.qtdneg,
							 c_maq.codvol,
							 c_maq.codmaq,
							 0,
							 0,
							 0);
					Exception
						When Others Then
							raise_application_error(-20105, ad_fnc_formataerro(Sqlerrm));
					End;
				End Loop c_Maq;
			End Loop c_Serv;
		End If;
	
	End If;
End;
/
