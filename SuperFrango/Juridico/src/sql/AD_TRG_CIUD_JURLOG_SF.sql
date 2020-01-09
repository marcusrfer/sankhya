Create Or Replace Trigger AD_TRG_CIUD_JURLOG_SF
	For Update On ad_jurlog
	Compound Trigger

	/*
  * Autor: Marcus Rangel
  * Processo: Despesas Jurídicas
  * Objetivo: Conciliação automática da conta destino dos adiantamento e bloqueios judiciais
  */

	Type type_numtransf Is Table Of Number;
	t type_numtransf := type_numtransf();

	After Each Row Is
		i Int;
	Begin
		If updating('CONCILIADO') Then
			If Nvl(:new.Conciliado, 'N') = 'S' Then
				t.extend;
				i := t.last;
				t(i) := :new.Nubco;
			End If;
		End If;
	End After Each Row;

	After Statement Is
	Begin
		For x In t.first .. t.Last
		Loop
			For mbc In (Select *
										From tgfmbc
									 Where nubco = t(x))
			Loop
			
				Begin
					Update tgfmbc
						 Set dhconciliacao = mbc.dhconciliacao, conciliado = 'S'
					 Where numtransf = mbc.numtransf
						 And conciliado = 'N';
				Exception
					When Others Then
						Raise_Application_Error(-20105,
																		fc_formatahtml_sf(P_MENSAGEM => 'Erro ao conciliar lançamento jurídico',
																											P_MOTIVO   => Sqlerrm,
																											P_SOLUCAO  => 'Verifique com o Suporte',
																											P_ERROR    => Null));
				End;
			
			End Loop mbc;
		End Loop x;
	End After Statement;

End AD_TRG_CIUD_JURLOG_SF;
/
