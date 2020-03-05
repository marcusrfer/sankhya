Create Or Replace Procedure "AD_STP_GERACOTSST"(P_CODUSU    Number,
																								P_IDSESSAO  Varchar2,
																								P_QTDLINHAS Number,
																								P_MENSAGEM  Out Varchar2) As
	r_Sol    ad_tsfsstc%Rowtype;
	r_Cot    ad_tabcotcab%Rowtype;
	v_CodUsu Number := stp_get_codusulogado;
	v_Count  Int := 0;
	Error Exception;
	ErrMsg Varchar2(4000);
Begin
	/*
  Autor: Marcus Rangel
  
  Objetivo: Confirmar a solicitação de serviços, notificar o solicitante.
  */
	For I In 1 .. P_QTDLINHAS
	Loop
	
		-- popula variáveis
		Begin
			r_sol.codsolst := ACT_INT_FIELD(P_IDSESSAO, I, 'CODSOLST');
		
			Select * Into r_Sol From ad_tsfsstc c Where c.codsolst = r_sol.codsolst;
			--Select Count(*) Into v_Count From ad_tabcotcab c Where Nvl(c.codsolst, 0) = r_sol.codsolst;
		Exception
			When no_data_found Then
				ErrMsg := 'Erro ao popular as variáveis. ' || Sqlerrm;
				Raise error;
		End;
	
--		Begin
--			Select Nvl(ultcod, 0) + 1 Into r_Cot.Numcotacao From tgfnum Where arquivo = 'AD_TABCOTCAB';
--			Update tgfnum
--				 Set ultcod = r_cot.numcotacao
--			 Where arquivo = 'AD_TABCOTCAB'
--				 And codemp = 1;
--		Exception
--			When Others Then
--				errmsg := 'Erro ao atualizar numeração. ' || Sqlerrm;
--		End;
    
    stp_keygen_tgfnum(
      P_Arquivo=>'AD_TABCOTCAB',
      p_Codemp=>1,
      p_Tabela=>'AD_TABCOTCAB',
      p_Campo=>'NUMCOTACAO',
      p_Dsync=>0,
      p_Ultcod=> r_Cot.Numcotacao 
    );
	
		/* Verifica se já não foi gerada cotação */
		If v_Count <> 0 Then
			Select numcotacao
				Into r_Cot.Numcotacao
				From ad_tabcotcab
			 Where Nvl(codsolst, 0) = r_sol.codsolst;
		
			ErrMsg := 'Essa solicitação já deu origem à Cotação Nro <a target="_parent" color="#FF0000" href="' ||
								ad_fnc_urlskw('AD_Tabcotcab', r_Cot.Numcotacao) || '"><b>' || r_cot.numcotacao ||
								'</b></a>';
			Raise error;
		End If;
	
		/* Insere Cotação */
		<<ins_cotacao>>
		Begin
			Insert Into ad_tabcotcab
				(numcotacao,
				 codemp,
				 codnat,
				 codcencus,
				 codproj,
				 dtneg,
				 codusu,
				 situacao,
				 codsolst,
				 nunota,
				 obs)
			Values
				(r_cot.numcotacao,
				 r_sol.codemp,
				 r_sol.codnat,
				 r_sol.codcencus,
				 r_sol.codproj,
				 Sysdate,
				 v_codusu,
				 'A',
				 r_sol.codsolst,
				 r_Sol.Nunotaorig,
				 r_Sol.Obs);
		Exception
			When dup_val_on_index Then
				r_cot.numcotacao := r_cot.numcotacao + 1;
				Goto ins_cotacao;
			When Others Then
				ErrMsg := 'Erro ao gerar a cotação. ' || Sqlerrm;
				Raise error;
		End;
	
	End Loop;

	p_mensagem := 'Cotação Número <a target="_parent" href="' ||
								ad_fnc_urlskw('AD_Tabcotcab', r_Cot.Numcotacao) || '"><b><font color="#0000FF">' ||
								r_cot.numcotacao || '</font></b></a> gerada com sucesso.';

Exception
	When Error Then
		P_MENSAGEM := '<p><font color="#FF0000" size="14"><b>Atenção!!!</b></font></p>' || ErrMsg;
		/*When Others Then
    P_MENSAGEM := '<p><font color="#FF0000" size="14"><b>Atenção!!!</b></font></p>' || Sqlerrm;*/
End;
/
