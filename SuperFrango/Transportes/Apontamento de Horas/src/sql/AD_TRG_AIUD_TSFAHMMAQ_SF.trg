Create Or Replace Trigger AD_TRG_AIUD_TSFAHMMAQ_SF
	After Insert Or Update Or Delete On AD_TSFAHMMAQ
	For Each Row
Declare
	v_Count       Pls_Integer := 0;
	v_QtdPrevista Float;
	Errmsg        Varchar2(4000);
Begin
	/*******************************************************************
   * Dt criaçao: 28/11/2016
   * Autor: Marcus Rangel
   * Objetivo: Popular tabela de horas previstas
  ********************************************************************/
	If inserting Or updating Then
	
		-- verifica se já existe!
		-- não tratado na FK pois a rotina permite preenchimento automatico
		-- pela geração a partir do contrato, quanto o preechimento manual
		Begin
			Select Count(*)
				Into v_Count
				From ad_tsfahmqpa
			 Where nuapont = :new.Nuapont
				 And nuseqmaq = :new.Nuseqmaq;
		Exception
			When Others Then
				errmsg := Sqlerrm;
				Raise_Application_Error(-20105, ad_fnc_formataerro(errmsg));
		End;
	
		If v_Count = 0 Then
			Begin
			
				Select m.qtdneg
					Into v_QtdPrevista
					From ad_tsfsstm m
				 Where m.codsolst = :new.Codsolst
					 And m.seqmaq = :new.Seqmaq
					 And m.nussti = :new.Nussti;
			
				Insert Into AD_TSFAHMQPA
					(NUAPONT, NUMCONTRATO, CODPROD, CODMAQ, CODVOL, CODSOLST, QTDPREVISTA, NUSEQMAQ)
				Values
					(:new.NuApont, :new.numcontrato, :new.codprod, :new.codmaq, :new.codvol, :new.codsolst, v_QtdPrevista,
					 :new.Nuseqmaq);
			Exception
				When Others Then
					errmsg := 'Erro ao inserir quantidades previstas para a máquina. ' || Sqlerrm;
					Raise_Application_Error(-20105, ad_fnc_formataerro(errmsg));
			End;
		
		End If;
	
	End If;

	If deleting Then
		Begin
			Select Count(*)
				Into v_Count
				From AD_TSFAHMQPA q
			 Where q.nuapont = :old.Nuapont
				 And q.nuseqmaq = :old.Nuseqmaq;
		Exception
			When Others Then
				errmsg := Sqlerrm;
				Raise_Application_Error(-20105, ad_fnc_formataerro(errmsg));
		End;
	
		If v_Count <> 0 Then
			Begin
				Delete From ad_tsfahmqpa q
				 Where nuapont = :old.Nuapont
					 And nuseqmaq = :old.Nuseqmaq;
			
			Exception
				When Others Then
					errmsg := Sqlerrm;
					Raise_Application_Error(-20105, ad_fnc_formataerro(errmsg));
			End;
		
		End If;
	
	End If;

End;
/
