Create Or Replace Trigger AD_TRG_CMP_TSFSSTM_SF
	For Insert Or Update Or Delete On AD_TSFSSTM
	Compound Trigger

	r_maq ad_tsfsstm%Rowtype;

	After Each Row Is
	Begin
		r_maq.codsolst := Nvl(:new.Codsolst, :old.Codsolst);
		--r_maq.codserv  := Nvl(:new.Codserv, :old.Codserv);
		r_maq.nussti := Nvl(:new.Nussti, :old.Nussti);
	
	End After Each Row;

	After Statement Is
	Begin
	
		Begin
			Select Sum(m.qtdneg), Sum(m.vlrunit)
				Into r_maq.qtdneg, r_maq.vlrunit
				From ad_tsfsstm m
			 Where m.codsolst = r_maq.codsolst
				 And m.nussti = r_maq.nussti;
		Exception
			When no_data_found Then
				Raise_Application_Error(-20105, 'no data found');
		End;
	
		r_maq.vlrtot := r_maq.qtdneg * r_maq.vlrunit;
	
		Update ad_tsfssti i
			 Set i.qtdneg   = Nvl(r_maq.qtdneg, 0),
					 i.vlrunit  = Nvl(r_maq.vlrunit, 0),
					 i.vlrtot   = Nvl(r_maq.vlrtot, 0),
					 automatico = 'S'
		 Where codsolst = r_maq.codsolst
			 And nussti = r_maq.nussti;
	
	End After Statement;

End;
/
