Create Or Replace Procedure AD_STP_LIB_CONFPEDTRANSP(p_Nunota Int, p_Sucesso Out Varchar, p_Mensagem Out Varchar2, p_Codusulib Out Number) Is
	r_Lib       Tsilib%Rowtype;
	r_Cab       tgfcab%Rowtype;
	v_Codevento Int;
	v_Count     Int := 0;
Begin
	/*
  * Autor: Marcus Rangel
  * Processo: Contratação de Serviços de Transporte
  * Objetivo: Procedure utilizada na rotina "Regras de Negócio" do sistema para realizar 
  * uma validação no momento da confirmação do pedido de compras oriundo desse processo.
  */

	--> Busca Evento Conf. Ped. Cpa.
	Select e.Evelibconfped
		Into v_Codevento
		From Ad_Tsfelt e
	 Where e.Nuelt = 1;

	Select *
		Into r_cab
		From tgfcab
	 Where nunota = p_nunota;

	/* Alterado por M. Rangel em 08/11/2017
   * Conforme solicitado, os pedidos de despesa extra de fretes
   * serão liberados pelo dono do CR e pelo transporte somente 
   * na confirmação da nota (Autorização de Pagamento) e não mais na 
   * confirmação do pedido conforme o processo desenhado no financeiro.
  */
	If r_Cab.Codnat = 4053600 Then
		p_Sucesso := 'S';
		Return;
	End If;

	If r_Cab.Tipmov = 'O' Then
	
		Select Count(*)
			Into v_Count
			From Tsilib l
		 Where Nuchave = p_Nunota
			 And l.Evento = v_Codevento
			 And (l.dhlib Is Null Or l.reprovado = 'S');
	
		Begin
			Select *
				Into r_Lib
				From Tsilib l
			 Where Nuchave = p_Nunota
				 And l.Evento = v_Codevento;
		Exception
			When No_Data_Found Then
				p_Sucesso := 'S';
			When Too_Many_Rows Then
				p_Sucesso  := 'N';
				p_Mensagem := 'Existem mais de uma liberação pendente para este pedido.';
				Return;
		End;
	
		--If r_Lib.Dhlib Is Null Then
		If v_Count > 0 Then
			p_Sucesso := 'N';
			-- p_Codusulib := r_Lib.Codusulib;
			/*
      p_Mensagem := Fc_Formatahtml_Sf(p_Mensagem => 'O pedido em questão não pode ser confirmado!',
      p_Motivo   => 'Existem liberações pendentes ou o mesmo foi reprovado. <br>Entre em contato com liberador e verique os motivos.',
      p_Solucao  => 'Entrar em contato com ' || Ad_Get.Nomeusu(r_Lib.Codusulib, 'completo') || '.');
      */
		
			p_mensagem := ad_fnc_formataerro('O pedido em questão não pode ser confirmado!<br>Existem liberações pendentes ou a' ||
																			 ' mesma foi reprovada. <br>Entrar em contato com ' || Ad_Get.Nomeusu(r_Lib.Codusulib, 'completo') || '.');
		
		Else
			p_Sucesso := 'S';
		End If;
	
		/*  
    Elsif r_cab.tipmov = 'C' And r_cab.tipfrete = 'F' Then
    -- inserir tratativa para fretes fob
    
    Select f.melhorparc, f.melhorValor
      Into v_MelhorParc, v_MelhorValor
      From ad_vw_fretefob f
     Where f.nunota = p_Nunota;
    
    Select p.nomeparc Into v_NomeMelhorParc From tgfpar p Where p.codparc = v_MelhorParc;
    
    If (r_Cab.Vlrfrete * 1.2) > v_MelhorValor Then
      p_Sucesso  := 'N';
      p_Mensagem := Fc_Formatahtml_Sf(p_Mensagem => 'O valor do frete excede em 20% o melhor valor calculado pelo sistema',
                                      p_Motivo => 'Melhor Parceiro: ' || v_NomeMelhorParc || chr(13) || 'Melhor Valor: ' ||
                                                   v_MelhorValor,
                                      p_Solucao => 'Entrar em contato com ' ||
                                                    Ad_Get.Nomeusu(r_Lib.Codusulib, 'completo') || '.');
    End If;
    */
	End If;

End;
/
