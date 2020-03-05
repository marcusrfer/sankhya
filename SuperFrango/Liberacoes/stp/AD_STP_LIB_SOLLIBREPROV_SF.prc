Create Or Replace Procedure "AD_STP_LIB_SOLLIBREPROV_SF"(p_codusu Number, p_idsessao Varchar2, p_qtdlinhas Number, p_mensagem Out Varchar2) As
	v_Nunota Number;
	r_lib    tsilib%Rowtype;
	v_simnao Char(1);
Begin

	/*
    Autor: Marcus Rangel
    Processo: Aquisição de serviços de transportes 
    Objetivo: Quando um pedido tem sua solicitação negada, o usuário teria que excluir o pedido para gerar nova solicitação,
              logo, foi criada essa ação para que o usuário reenvie o pedido para nova liberação após demonstrar os motivos
              pelos quais o pedido deve ser aprovado para o liberador.
  */
	For i In 1 .. p_qtdlinhas
	Loop
		v_Nunota := act_int_field(p_idsessao, i, 'NUNOTA');
	
		Begin
			Select *
				Into r_lib
				From tsilib
			 Where tabela = 'TGFCAB'
				 And nuchave = v_Nunota;
		Exception
			When no_data_found Then
				p_mensagem := 'Esse recurso pode ser usado apenas para lançamentos que foram reprovados.';
				Return;
		End;
	
		r_lib.obscompl := act_txt_param(P_CHAVE => p_idsessao, P_NOME => 'OBS');
	
		If r_lib.dhlib Is Null And nvl(r_lib.reprovado, 'N') = 'N' Then
			p_mensagem := 'Esse recurso pode ser usado apenas para lançamentos que foram reprovados.';
			Return;
		Else
			v_simnao := act_escolher_simnao(P_TITULO    => 'Solicitar liberação de Reprovado',
																			P_TEXTO     => 'Deseja reenviar esse lançamento para nova revisão de ' ||
																										 ad_get.Nomeusu(r_lib.codusulib, 'completo'),
																			P_CHAVE     => p_idsessao,
																			P_SEQUENCIA => 0);
		
			If v_simnao = 'S' Then
				Begin
					Update tsilib l
						 Set l.dhlib = Null, l.reprovado = 'N', l.vlrliberado = 0, l.observacao = l.observacao || chr(13) || r_lib.obscompl
					 Where tabela = 'TGFCAB'
						 And l.nuchave = v_nunota
						 And l.codusulib = r_lib.codusulib;
				Exception
					When Others Then
						p_mensagem := Sqlerrm;
						Return;
				End;
			End If;
		
		End If;
	
	End Loop;

	p_mensagem := 'Operação realizada com Sucesso!!!';

End;
/
