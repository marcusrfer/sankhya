Create Or Replace Procedure "AD_STP_CONFTAXI"(p_codusu    Number,
																							p_idsessao  Varchar2,
																							p_qtdlinhas Int,
																							p_mensagem  Out Varchar2) Is
	v_nuAp   Number;
	v_Motivo Varchar2(400);
	errmsg   Varchar2(4000);
	error Exception;
Begin
	/*
  * Autor: Marcus Rangel
  * Processo: Carro de Apoio
  * Objetivo: Informar o motivo da necessidade de táxi no agendamento da corrida.
  */
	For I In 1 .. p_qtdlinhas
	Loop
		v_nuAp   := act_int_field(p_idsessao, I, 'NUAP');
		v_Motivo := act_txt_param(p_idsessao, 'MOTIVOTAXI');
	
		Begin
			Update ad_tsfcap c
				 Set c.taxi = 'S', c.motivotaxi = v_Motivo
			 Where c.nuap = v_nuAp;
		Exception
			When Others Then
				errmsg := 'Erro ao atualizar as informações do Táxi. ' || Sqlerrm;
				Raise error;
		End;
	End Loop;
	p_mensagem := 'Informações atualizadas com sucesso!!!';
Exception
	When error Then
		p_mensagem := errmsg;
End;
/
