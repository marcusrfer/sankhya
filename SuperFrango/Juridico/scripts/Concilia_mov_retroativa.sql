PL/SQL Developer Test script 3.0
46
Declare
	v_Numtransf Number;
	v_Dtconc    Date;
Begin
	-- Test statements here
	For T In (Select Distinct l.nupasta, l.seq
							From ad_jurlog l
						 Order By nupasta)
	Loop
	
		For l In (
							
							Select i.nupasta, i.seq, i.nufin, m.nubco, m.dtlanc, m.vlrlanc, m.conciliado, m.dhconciliacao, m.numtransf,
											m.recdesp, m.codctabcocontra, m.nubcocp, m.ad_nufinproc, m.codctabcoint
								From tgfmbc m
								Join ad_jurite i
									On m.ad_nufinproc = i.nufin
							 Where m.ad_nufinproc Is Not Null
								 And i.nupasta = t.nupasta
								 And i.seq = t.seq
							
							)
		Loop
			If l.dhconciliacao Is Not Null Then
				v_Numtransf := l.numtransf;
				v_Dtconc    := l.dhconciliacao;
			End If;
		End Loop l;
	
		If v_Numtransf Is Not Null Then
		
			Begin
				Update tgfmbc m
					 Set m.dhconciliacao = v_Dtconc, m.conciliado = 'S'
				 Where m.numtransf = v_Numtransf
					 And m.dhconciliacao Is Null
					 And Nvl(m.conciliado, 'N') = 'N';
			Exception
				When Others Then
					Dbms_Output.put_line(v_Numtransf||' - '||sqlerrm); 
			End;
		
		End If;
	
	End Loop T;
End;
0
0
