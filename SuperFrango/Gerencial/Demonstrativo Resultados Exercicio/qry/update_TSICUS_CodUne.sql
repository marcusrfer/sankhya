PL/SQL Developer Test script 3.0
22
Declare
	vCodUne Int;
Begin
	For UN In (Select Distinct ad_sigla
														From Tsicus t
													Where Ad_sigla Is Not Null
															And Ad_codune Is Null)
	Loop
		Begin
			Select Codune Into vCodUne From Ad_tsfune at Where trim(Upper(Sigla)) = TRIM(Upper(Un.Ad_sigla));
		Exception
			When No_data_found Then
			 Dbms_Output.put_line('Not Found '||un.ad_sigla); 
				Continue;
		End;
		For Cus In (Select codcencus, ad_sigla From tsicus Where trim(upper(Ad_sigla)) = trim(upper(un.Ad_sigla)))
		Loop
			Update Tsicus Set Ad_codune = vCodUne Where Codcencus = cus.Codcencus;
			Dbms_output.put_line(cus.Codcencus||' - '||Trim(upper(cus.ad_sigla)));
		End Loop cus;
	End Loop UN;
End;
0
0
