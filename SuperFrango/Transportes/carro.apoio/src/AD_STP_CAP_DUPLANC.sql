Create Or Replace Procedure "AD_STP_CAP_DUPLANC"(P_CODUSU Number, P_IDSESSAO Varchar2, P_QTDLINHAS Number,
																								 P_MENSAGEM Out Varchar2) As
	v_NuCapSol Number;
	v_NuCap    Number;
	v_ProxNum  Number;
	v_NumLink  Varchar2(4000);
	Errmsg     Varchar2(4000);
	Error Exception;
Begin
	/* 
  * Autor: M. Rangel
  * Processo: Carro de Apoio
  * Objetivo: Duplicar o lançamento, a aba intinerário e rateio.
  */

	For L In 1 .. P_QTDLINHAS
	Loop
	
		v_NuCapSol := ACT_INT_FIELD(P_IDSESSAO, L, 'NUCAPSOL');
		v_NuCap    := ACT_INT_FIELD(P_IDSESSAO, L, 'NUAP');
	
		If v_NuCapSol Is Not Null And v_NuCap Is Null Then
		
			/*Prenche o cabeçalho*/
			For C In (Select *
									From ad_tsfcapsol
								 Where nucapsol = v_NucapSol)
			Loop
			
				--v_ProxNum := ad_get.ultCod('AD_TSFCAPSOL', 1, ' ') + 1;
			
				stp_keygen_tgfnum('AD_TSFCAPSOL', 1, 'AD_TSFCAPSOL', 'NUCAPSOL', 0, v_proxnum);
			
				Begin
					Insert Into ad_tsfcapsol
						(nucapsol, codusu, dhsolicit, codcencus, tiposol, status, dtagend, nuap, dhalter, qtdpassageiros)
					Values
						(v_ProxNum, P_CODUSU, Sysdate, c.codcencus, c.tiposol, 'P', Null, Null, Sysdate, 1);
				Exception
					When Others Then
						P_MENSAGEM := 'Erro ao duplicar o cabeçalho da solicitação. ' || Sqlerrm;
						Return;
				End;
			
				/*preenche o itinerário*/
				For I In (Select *
										From ad_tsfcapitn
									 Where nucapsol = v_NucapSol)
				Loop
					<<insert_sol>>
					Begin
						Insert Into ad_tsfcapitn
							(nucapsol, nuitn, tipotin, codcid, codend, codbai, complemento, referencia)
						Values
							(v_ProxNum, i.nuitn, i.tipotin, i.codcid, i.codend, i.codbai, i.complemento, i.referencia);
					Exception
						When dup_val_on_index Then
							v_ProxNum := v_ProxNum + 1;
							Goto insert_sol;
						When Others Then
							P_MENSAGEM := 'Erro ao duplicar o itinerário. ' || Sqlerrm;
							Return;
					End;
				
				End Loop I;
			
				/*Preenche o rateio*/
				For R In (Select *
										From ad_tsfcaprat
									 Where nucapsol = v_NucapSol)
				Loop
				
					Begin
						Insert Into ad_tsfcaprat
							(nucapsol, nucaprat, codemp, codnat, codcencus, percentual)
						Values
							(v_ProxNum, r.nucaprat, r.codemp, r.codnat, r.codcencus, r.percentual);
					Exception
						When Others Then
							Errmsg := 'Erro ao duplicar o rateio da solicitação. ' || Sqlerrm;
							Raise error;
					End;
				
				End Loop R;
			
				/*Update tgfnum
          Set ultcod = v_ProxNum
        Where arquivo = 'AD_TSFCAPSOL';*/
			
				v_NumLink := '<a target="_top" href="' || ad_fnc_urlskw('AD_TSFCAPSOL', v_ProxNum, Null, Null) || '">' || v_ProxNum ||
										 '</a>';
			
			End Loop C;
		
		Else
		
			For C In (Select *
									From Ad_tsfcap
								 Where Nuap = v_nucap)
			Loop
			
				--v_ProxNum := ad_get.ultcod('AD_TSFCAP', 1, ' ') + 1;
			
				stp_keygen_tgfnum('AD_TSFCAP', 1, 'AD_TSFCAP', 'NUAP', 0, v_ProxNum);
			
				<<Insert_cap>>
				Begin
					Insert Into Ad_tsfcap
						(Nuap, Codususol, Dhsolicit, Ordemcarga, Codusuexc, Codparctransp, Codveiculo, Status, Taxi, Motivotaxi, Kminicial,
						 Kmfinal, Totalkm, Vlrcorrida, Nucapsol, Dtagend, Rota, Dtagendfim, Combinada, Codcontato, Qtdpassageiros, Motorista,
						 Motivo, Deptosol, Codcidorig, Codciddest, Nomeciddest, Nomecidorig, Dhmov, Dtreabre, Motivoreabre, Codusureabre,
						 Nuappai, Temacerto)
					Values
						(v_ProxNum, C.Codususol, C.Dhsolicit, C.Ordemcarga, C.Codusuexc, C.Codparctransp, C.Codveiculo, 'P', C.Taxi,
						 C.Motivotaxi, 0, 0, 0, 0, C.Nucapsol, C.Dtagend, C.Rota, Null, 'N', C.Codcontato, C.Qtdpassageiros, C.Motorista,
						 C.Motivo, C.Deptosol, C.Codcidorig, C.Codciddest, C.Nomeciddest, C.Nomecidorig, Sysdate, Null, Null, Null, Null, 'N');
				Exception
					When dup_val_on_index Then
						v_ProxNum := v_ProxNum + 1;
						Goto insert_cap;
					When Others Then
						errmsg := 'Erro ao duplicar o agendamento. ' || Sqlerrm;
						Raise error;
				End;
			
				For R In (Select *
										From Ad_tsfcapdoc d
									 Where Nuap = v_Nucap)
				Loop
				
					Begin
						Insert Into Ad_tsfcapdoc
							(Seqdoc, Nuap, Codcencus, Codsolicit, Entregue, Codusuresp, Entreguetransp)
						Values
							(R.Seqdoc, v_ProxNum, R.Codcencus, R.Codsolicit, 'N', R.Codusuresp, 'N');
					Exception
						When Others Then
							errmsg := 'Erro ao duplicar os documentos do agendamento. ' || Sqlerrm;
							Raise error;
					End;
				
				End Loop R;
			
				v_NumLink := '<a target="_top" href="' || ad_fnc_urlskw('AD_TSFCAP', v_ProxNum, Null, Null) || '">' || v_ProxNum ||
										 '</a>';
			
			End Loop C;
		
		End If;
	
	End Loop L;

	/*Update tgfnum
    Set ultcod = v_ProxNum
  Where arquivo = 'AD_TSFCAP';*/

	P_MENSAGEM := 'Lançamento duplicado com sucesso.<br> Lançamento nro: ' || v_NumLink;

Exception
	When ERROR Then
		Rollback;
		P_MENSAGEM := Errmsg;
	When Others Then
		P_MENSAGEM := 'Erro: ' || Sqlerrm;
End;
/
