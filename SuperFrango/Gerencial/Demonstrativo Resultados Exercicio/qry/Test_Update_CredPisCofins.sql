PL/SQL Developer Test script 3.0
26
-- Created on 31/03/2017 by MARCUSR 
Declare
		-- Local variables here
		i Integer;
Begin
		For m In (Select *
														From Ad_Tsfdre d
													Where Codmeta = :codmeta
															And d.Nomecampo Is Not Null
															And d.Formula Is Not Null)
		Loop
				Begin
						v_Count := v_Count + 1;
						Sql_Stmt := 'Update ad_basedre d
							Set ' || m.Nomecampo || ' = ' || m.Formula || '
					Where trunc(dtfatur) Between ''' || :Dataini || ''' And ''' || :Datafin || '''';
				
						Execute Immediate Sql_Stmt;
				
				Exception
						When Others Then
								p_Mensagem := Sqlcode || ' - ' || Sqlerrm;
				End;
		End Loop;

End;
3
codmeta
1
103003
3
Dataini
1
01/02/2017
12
Datafin
1
28/02/2017
12
0
