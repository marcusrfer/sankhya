Create Or Replace Procedure "AD_STP_SST_EXCLANC"(P_CODUSU    Number,
																								 P_IDSESSAO  Varchar2,
																								 P_QTDLINHAS Number,
																								 P_MENSAGEM  Out Varchar2) As
	v_CodSol Number;
Begin

	/* 
  Autor: Marcus Rangel
  Processo: Solicitação de Serviços de Transportes
  Objetivo: Excluir contratos ou cotações geradas 
  a partir de uma solicitação de serviços 
  */

	For I In 1 .. P_QTDLINHAS
	Loop
		Begin
			v_CodSol := ACT_INT_FIELD(P_IDSESSAO, I, 'CODSOLST');
		
			Execute Immediate 'alter trigger  AD_TRG_BIUD_TCSCON_SF disable';
			Execute Immediate 'alter trigger AD_TRG_AIUD_TCSCON_SF disable';
		
			ad_pkg_ahm.desfaz_lanacamentos(v_codsol);
		
			Execute Immediate 'alter trigger AD_TRG_AIUD_TCSCON_SF enable';
			Execute Immediate 'alter trigger AD_TRG_BIUD_TCSCON_SF enable';
		
			p_mensagem := 'Lançamentos Excluídos com sucesso!';
		
		Exception
			When Others Then
				Rollback;
				p_mensagem := Sqlerrm;
		End;
	End Loop;
End;
/
