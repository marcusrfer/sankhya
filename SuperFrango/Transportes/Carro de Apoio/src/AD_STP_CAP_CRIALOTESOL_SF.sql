Create Or Replace Procedure "AD_STP_CAP_CRIALOTESOL_SF"(p_codusu Number, p_idsessao Varchar2, p_qtdlinhas Number,
																												p_mensagem Out Varchar2) As
	p_qtdviagens     Number;
	p_tipoviagem     Number;
	p_dhpartida      Date;
	p_dhretorno      Date;
	p_codcidorig     Varchar2(4000);
	p_codciddest     Varchar2(4000);
	p_qtdpassageiros Number;
	p_obs            Varchar2(4000);
	p_endereco       Varchar2(4000);

	r_sol   ad_tsfcapsol%Rowtype;
	r_itn   ad_tsfcapitn%Rowtype;
	v_Volta Boolean Default False;

	Type type_numsol Is Table Of Number;
	t_sol type_numsol := type_numsol();
	i_sol Int := 0;

	v_session Varchar2(4000);
Begin
	/* 
  * Autor: M. Rangel
  * Processo: Carro de Apoio
  * Objetivo: Ação "Criar solicitações em Lotes" da tela de solicitações de carro de apoio.
  */

	If Lower(p_idsessao) = 'debug' Then
		p_qtdviagens     := 1;
		p_tipoviagem     := To_Number('2');
		p_dhpartida      := To_Date('30/07/2018 08:00:00', 'dd/mm/yyyy hh24:mi:ss');
		p_dhretorno      := To_Date('30/07/2018 18:00:00', 'dd/mm/yyyy hh24:mi:ss');
		p_codcidorig     := 2;
		p_codciddest     := 3;
		p_qtdpassageiros := 4;
		p_endereco       := 'TESTE TESTE TESTE TESTE TESTE TESTE TESTE TESTE TESTE';
		p_obs            := 'TESTE TESTE TESTE TESTE TESTE TESTE TESTE TESTE TESTE';
	Else
		p_qtdviagens     := act_int_param(p_idsessao, 'QTDVIAGENS');
		p_tipoviagem     := To_Number(act_txt_param(p_idsessao, 'TIPOVIAGEM'));
		p_dhpartida      := act_dta_param(p_idsessao, 'DHPARTIDA');
		p_dhretorno      := act_dta_param(p_idsessao, 'DHRETORNO');
		p_codcidorig     := act_txt_param(p_idsessao, 'CODCIDORIG');
		p_codciddest     := act_txt_param(p_idsessao, 'CODCIDDEST');
		p_qtdpassageiros := act_int_param(p_idsessao, 'QTDPASSAGEIROS');
		p_obs            := act_txt_param(p_idsessao, 'OBS');
		p_endereco       := act_txt_param(p_idsessao, 'ENDERECO');
	End If;

	If p_tipoviagem = 2 And p_dhretorno Is Null Then
		p_mensagem := 'Para viagens Ida e Volta é necessário informar a data de retornno.';
		Return;
	End If;

	If p_dhretorno < p_dhpartida Then
		p_mensagem := 'A data de retorno não pode ser inferior à data de partida';
		Return;
	End If;

	<<inicio>>
	For v In 1 .. p_qtdviagens
	Loop
		Begin
			-- inicia o index da array
			i_sol := i_sol + 1;
		
			--busca o número da solicitação
			stp_keygen_tgfnum('AD_TSFCAPSOL', 1, 'AD_TSFCAPSOL', 'NUCAPSOL', 0, r_sol.nucapsol);
		
			-- preenche os demais campos da tabela
			r_sol.codusu := p_codusu;
		
			Select u.codcencuspad
				Into r_sol.codcencus
				From tsiusu u
			 Where codusu = p_codusu;
		
			r_sol.dhsolicit      := Sysdate;
			r_sol.tiposol        := 'A';
			r_sol.status         := 'P';
			r_sol.dtagend := Case
												 When v_Volta Then
													p_dhretorno + v - 1
												 Else
													p_dhpartida + v - 1
											 End;
			r_sol.nuap           := Null;
			r_sol.dhalter        := Sysdate;
			r_sol.qtdpassageiros := p_qtdpassageiros;
			r_sol.dhenvio        := Null;
			r_sol.motivo         := p_obs;
		
			-- insere a solicitação
			Insert Into ad_tsfcapsol
			Values r_sol;
		
		Exception
			When Others Then
				p_mensagem := 'Erro ao buscar os dados para a criação da solicitação. ' || Sqlerrm;
				Return;
		End;
	
		-- prepara para insert do itinerário
		Begin
			For i In 1 .. 2
			Loop
				r_itn.nuitn    := i;
				r_itn.nucapsol := r_sol.nucapsol;
				r_itn.tipotin := Case
													 When i = 1 Then
														'O'
													 Else
														'D'
												 End;
			
				-- se for a volta
				If v_volta Then
					r_itn.codcid := Case
														When i = 1 Then
														 p_codciddest
														Else
														 p_codcidorig
													End;
				Else
					r_itn.codcid := Case
														When i = 1 Then
														 p_codcidorig
														Else
														 p_codciddest
													End;
				End If;
			
				r_itn.codend      := 0;
				r_itn.codbai      := 0;
				r_itn.complemento := p_endereco;
				r_itn.referencia  := Null;
			
				-- insere o itinerário
				Insert Into ad_tsfcapitn
				Values r_itn;
			
			End Loop i;
		
		Exception
			When Others Then
				p_mensagem := 'Erro ao preencher as informações do itinerário. ' || Sqlerrm;
				Return;
		End;
	
		-- insere o rateio
		Begin
			Insert Into ad_tsfcaprat
				(nucapsol, nucaprat, codemp, codnat, codcencus, percentual, codproj)
			Values
				(r_sol.nucapsol, 1, 1, 4051300, r_sol.codcencus, 100, 0);
		Exception
			When Others Then
				p_mensagem := 'Erro ao preencher as informações sobre o rateio ' || Sqlerrm;
				Return;
		End;
	
		--iniciar e popula array
		t_sol.extend;
		t_sol(i_sol) := r_sol.nucapsol;
	
	End Loop v;

	-- verifica se ida e volta se for, reinicia com os destinos trocados
	If p_tipoviagem = 2 And v_Volta = False Then
		v_Volta := True;
		Goto inicio;
	End If;

	Begin
	
		If act_escolher_simnao(P_TITULO    => 'Envio para Agendamento',
													 P_TEXTO     => 'Deseja enviar diretamente as solicitações criadas para o agendamento dos carros?',
													 P_CHAVE     => p_idsessao,
													 P_SEQUENCIA => 1) = 'S' Then
		
			v_session := DBMS_Random.String('A', 20);
		
			For a In t_sol.first .. t_sol.last
			Loop
				ad_set.Inseresessao('NUCAPSOL', a, 'I', t_sol(a), v_session);
			End Loop;
		
			ad_stp_cap_enviaagend(p_Codusu, v_session, t_sol.last, p_mensagem);
		
			ad_set.Remove_Sessao(v_session);
		
		Else
			Null;
		End If;
	
	End;

	p_mensagem := 'Solicitações criadas com sucesso!';

End;
/
