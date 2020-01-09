PL/SQL Developer Test script 3.0
47
-- Created on 03/04/2018 by M.RANGEL 
Declare
	-- Local variables here
	i Integer := 0;
	z Integer := 0;
Begin
	-- Test statements here
	For c_ite In (Select nupasta
									From ad_jurcab
								 Order By 1)
	Loop
		For Mbc In (Select *
									From ad_tmpmbcjur j
								 Where j.nupasta = c_ite.nupasta)
		Loop
		
			--i := ad_pkg_jur.get_nulog_ultcod(p_Nupasta => mbc.nupasta, p_sequencia => mbc.seq);
		
			i := i + 1;
		
			Begin
				Insert Into ad_jurlog
					(nulog, seq, nupasta, dhmov, nufin, nubco, descroper, codctabcoint, recdesp, vlrdesdob, conciliado)
				Values
					(i, mbc.seq, mbc.nupasta, mbc.dtlanc, mbc.nufin, mbc.nubco, 'Importado', mbc.codctabcoint, mbc.recdesp,
					 mbc.vlrlanc, mbc.conciliado);
			
				z := z + 1;
			
			Exception
				When Others Then
					Continue;
			End;
		
			Dbms_Output.put_line(mbc.nupasta || ' - ' || mbc.seq);
		
		End Loop;
	
		i := 0;
	
		If z = 10 Then
			Commit;
		End If;
	
	End Loop;

End;
0
1
z
