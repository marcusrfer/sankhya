Create Or Replace Trigger AD_TRG_CIUD_TGFFIN_DUPL_SF
	For Insert Or Update On tgffin
	Compound Trigger

	v_Count Int := 0;
	r_Fin   tgffin%Rowtype;

	/*
  * Autor: Marcus Rangel
  * Data: 11/01/2018
  * Processo: Frete Coleta e Fob
  * Objetivo: Impedir que lançamentos, até o momento, da top 437 - Frete avulso
  * sejam lançadas em duplicidade na mov. financeira criticando a Chave do CTe,
  * o parceiro, o valor, o número, a série e a top.
  */

	Before Each Row Is
	Begin
	
		If inserting Or updating('CHAVECTE') Then
		
			If (:new.Codtipoper Not In (3, 437) And :new.origem <> 'F') Or :new.Nureneg Is Not Null Or
				 :new.Recdesp = 0 And :new.Desdobramento Is Not Null Then
			
				r_fin.nufin      := :new.Nufin;
				r_fin.nureneg    := :new.Nureneg;
				r_fin.vlrdesdob  := :new.Vlrdesdob;
				r_fin.dtneg      := :new.Dtneg;
				r_fin.chavecte   := :new.Chavecte;
				r_fin.codtipoper := :new.Codtipoper;
			
			End If;
		
		End If;
	
	End Before Each Row;

	After Statement Is
	Begin
	
		If r_fin.nufin Is Not Null And r_fin.nureneg Is Null Then
		
			Select Count(*)
				Into v_Count
				From tgffin
			 Where chavecte = r_fin.chavecte
				 And codtipoper = r_fin.codtipoper
				 And chavecte Is Not Null
				 And nufin <> r_fin.nufin
						--And codparc = v_Codparc
						--And recdesp > 0
						--And dhbaixa Is Null
						--And numnota = :new.Numnota
						--And vlrdesdob = v_VlrDesdob
						--And serienota = :new.Serienota
				 And dtneg Between add_months(Trunc(r_fin.Dtneg, 'mm'), -6) And add_months(Trunc(r_fin.Dtneg, 'mm'), 6);
		
			If v_count > 0 Then
				Raise_Application_Error(-20105,
																fc_formatahtml_sf(p_mensagem => 'Com exceção das renegociações e compesações, esse lançamento não pode ser inserido no financeiro.',
																									p_motivo   => 'Já existe outro lançamento igual a este',
																									p_solucao  => 'Verifique se não se trata de duplicidade (Chave do CTe, parceiro, valor, número, série e top)',
																									p_error    => 'Funcionalidade em carater experimental, qualquer dificuldade entre em contato com o suporte'));
			End If;
		
		End If;
	End After Statement;

End;
/
