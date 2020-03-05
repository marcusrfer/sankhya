Create Or Replace Procedure "AD_STP_AHM_UPDVLRHORA"(p_codusu    Number,
																										p_idsessao  Varchar2,
																										p_qtdlinhas Number,
																										p_mensagem  Out Varchar2) As
	p_DtVigor  Date;
	p_VlrUnit  Float;
	p_Motivo   Varchar2(4000);
	r_apo      ad_tsfahmmaq%Rowtype;
	v_nuseqpmc Int := 0;
	Errmsg     Varchar2(4000);
	Error Exception;
Begin

	/*
  * Autor: Marcus Rangel
  * Processo: Apontamento de Horas Máquina
  * Objtivo: Permitir alterar o valor unitário do serviço antes da geração do pedido de compra
  */

	p_DtVigor := ACT_DTA_PARAM(P_IDSESSAO, 'DTVIGOR');
	p_VlrUnit := ACT_DEC_PARAM(P_IDSESSAO, 'VLRUNIT');
	p_Motivo  := ACT_TXT_PARAM(P_IDSESSAO, 'MOTIVO');

	/*Tratativa para faturar a partir do layou html5, os campos data estão sendo passados como float*/
	If p_DtVigor Is Null Then
		p_DtVigor := To_Date(Substr(Replace(act_dec_param(P_IDSESSAO, 'DTVIGOR'), '.', ''), 1, 8),
												 'yyyymmdd');
	End If;

	For I In 1 .. P_QTDLINHAS
	Loop
		r_apo.nuapont  := ACT_INT_FIELD(P_IDSESSAO, I, 'NUAPONT');
		r_apo.nuseqmaq := ACT_INT_FIELD(P_IDSESSAO, I, 'NUSEQMAQ');
		/*    
    r_apo.CodMaq   := ACT_INT_FIELD(P_IDSESSAO, I, 'CODMAQ');
    r_apo.CodProd  := ACT_INT_FIELD(P_IDSESSAO, I, 'CODPROD');
    r_apo.Codvol   := act_txt_field(P_IDSESSAO, 1, 'CODVOL');
    */
	
		Begin
			Select *
				Into r_apo
				From ad_tsfahmmaq m
			 Where m.nuapont = r_apo.nuapont
				 And m.nuseqmaq = r_apo.nuseqmaq;
		Exception
			When no_data_found Then
				Errmsg := 'Não foram encontrados dados de apontamento para: Apontamento: ' || r_apo.nuapont ||
									'; Serviço: ' || r_apo.codprod || '; Máquina:' || r_apo.codmaq || '; Un: ' ||
									r_apo.codvol;
				Raise error;
		End;
	
		If Length(p_Motivo) < 15 Then
			Errmsg := 'Motivo muito breve, por favor detalhe melhor o mesmo.';
			Raise error;
		End If;
	
		Begin
		
			Select Nvl(Max(nuseqpmc), 0) + 1
				Into v_nuseqpmc
				From ad_tsfpmc
			 Where numcontrato = r_apo.numcontrato
				 And codprod = r_apo.codprod;
		
			Insert Into ad_tsfpmc
				(numcontrato,
				 codprod,
				 nuseqpmc,
				 dtvigor,
				 vlrunit,
				 codsolst,
				 nussti,
				 seqmaq,
				 codmaq,
				 id,
				 codvol,
				 dhalter,
				 codusu,
				 motivo)
			Values
				(r_apo.numcontrato,
				 r_apo.codprod,
				 v_nuseqpmc,
				 p_DtVigor,
				 p_VlrUnit,
				 r_apo.codsolst,
				 r_apo.nussti,
				 r_apo.seqmaq,
				 r_apo.codmaq,
				 r_apo.id,
				 r_apo.codvol,
				 Sysdate,
				 P_CODUSU,
				 p_motivo);
		Exception
			When Others Then
				Errmsg := 'Erro ao inserir o novo preço. ' || Sqlerrm;
				Raise error;
		End;
	
	End Loop;
	p_mensagem := 'Preço Atualizado com sucesso!!!';
Exception
	When error Then
		P_MENSAGEM := Errmsg;
	When Others Then
		P_MENSAGEM := Sqlerrm;
End;
/
