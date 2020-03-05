Create Or Replace Procedure ad_stp_cmp_fixstatusvei_sf Is
		c ad_contcargto%Rowtype;
Begin
		/* 
  * Dt. Criação: 13/03/2019
  * Autor: M. Rangel
  * Processo: Carregamento de MP
  * Objetivo: Corrigir os status dos veículos dos carregamentos
  */

		For cgt In (Select *
																From ad_contcargto c
															Where status In ('ABERTO', 'FECHADO')
																	And codveiculo Is Not Null
																	And c.datahoralanc >= Sysdate - 60)
		Loop
		
				If Nvl(cgt.Codveiculo, 0) = 0 And cgt.Datasaidatrans Is Null Then
						c.Statusvei := 'AP';
				Elsif (cgt.Datasaidatrans Is Not Null And To_Char(cgt.Datasaidatrans, 'hh24:mi:ss') <> '00:00:00' And
										(cgt.Datachegadapatio Is Null And cgt.Dataentradadesc Is Null And cgt.Datafimdescarga Is Null) And
										Nvl(cgt.Codlocal, 0) <> 0) Then
						c.Statusvei := 'T';
				Elsif cgt.Datasaidatrans Is Null Or To_Char(cgt.Datasaidatrans, 'hh24:mi:ss') = '00:00:00' Then
						c.Statusvei := 'A';
				Elsif cgt.Datachegadapatio Is Not Null And To_Char(cgt.Datachegadapatio, 'hh24:mi:ss') <> '00:00:00' And
										((cgt.Dataentradadesc Is Null Or To_Char(cgt.Dataentradadesc, 'hh24:mi:ss') = '00:00:00') And
										cgt.Datafimdescarga Is Null) Then
						c.Statusvei := 'P';
				Elsif cgt.Datachegadapatio Is Null Or To_Char(cgt.Datachegadapatio, 'hh24:mi:ss') = '00:00:00' Then
						c.Statusvei := 'T';
				Elsif cgt.Dataentradadesc Is Not Null And To_Char(cgt.Dataentradadesc, 'hh24:mi:ss') <> '00:00:00' And
										(cgt.Datafimdescarga Is Null Or To_Char(cgt.Datafimdescarga, 'hh:mi:ss') = '00:00:00') Then
						c.Statusvei := 'D';
						c.Status    := 'ABERTO';
				Elsif cgt.Datafimdescarga Is Not Null And To_Char(cgt.Datafimdescarga, 'hh24:mi:ss') <> '00:00:00' Then
						c.Statusvei := 'C';
				End If;
		
				If cgt.statusvei != c.statusvei Then
						Begin
								variaveis_pkg.v_atualizando := True;
								Update ad_contcargto
											Set statusvei = cgt.statusvei,
															status = Nvl(c.status, cgt.status)
									Where sequencia = cgt.sequencia;
								ad_pkg_var.Errmsg := 'Sequencia: ' || cgt.sequencia || ' - ' || ', Old Status: ' || cgt.statusvei ||
																													' - ' || ', New Status: ' || c.statusvei;
								Dbms_Output.Put_Line(ad_pkg_var.Errmsg);
								variaveis_pkg.v_atualizando := False;
						Exception
								When Others Then
										Dbms_Output.Put_Line('Erro sequencia ' || cgt.sequencia || ' - ' || Sqlerrm);
										Continue;
						End;
				End If;
		
				c.statusvei := Null;
		
		End Loop;

End;
/
