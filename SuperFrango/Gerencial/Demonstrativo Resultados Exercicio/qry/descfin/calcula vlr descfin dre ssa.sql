PL/SQL Developer Test script 3.0
80
Declare
  p_referencia Date;
  v_sufixo Varchar2(10);
  stmt Varchar2(32000);

  Type tipo_record_resumo_cab Is Record(
    nunota     Number,
    sequencia  Number,
    qtdneg     Float,
    vlrtot     Float,
    vlrnota    Float,
    vlrdescfin Float);

  Type tipo_tabela_resumo_cab Is Table Of tipo_record_resumo_cab;

  t tipo_tabela_resumo_cab := tipo_tabela_resumo_cab();

  c Sys_Refcursor;

Begin
  p_referencia := :referencia;

  v_Sufixo := To_Char(p_referencia, 'YYYYMM');

  Update dre_baseindpad_201812 Set vlrdesc = 0 Where vlrdesc != 0;

  Open c For 'Select nunota, sequencia, qtdneg, vlrtot, 0, 0 From dre_baseindpad_' || v_sufixo;
  Fetch c Bulk Collect
    Into t;
  Close c;
	
	Dbms_Output.put_line( 'Tamando da coleção pad: '||t.last); 

  For z In t.first .. t.last
  Loop
    Begin
      /*Select c.vlrnota , f.vlrdesdob
      Into t(z).vlrnota , t(z).vlrdescfin
      From tgfcab c 
       Left Join ad_tmpmovdescfin f
        On f.nunota = c.nunota
      Where c.nunota = t(z).nunota;*/
      Select c.vlrnota Into t(z).vlrnota From tgfcab c Where c.nunota = t(z).nunota;
    
      stmt := 'Select vlrdesdob from dre_baseindger_' || v_sufixo ||
              ' where prefixo = ''DESCFIN'' and nunota = :nunota';
    
      Execute Immediate stmt
        Into t(z).vlrdescfin
        Using t(z).nunota;
     Dbms_Output.put_line( 'Existe no desconto: '||t(z).nunota);
    
      t(z).vlrdescfin := t(z).vlrdescfin * ( t(z).vlrtot / t(z).vlrnota ) /  t(z).qtdneg;
			
			Dbms_Output.put_line( 'Valor do desconto: '||t(z).vlrdescfin);
    
    Exception
      When no_data_found Then
        Continue;
    End;
  End Loop;

  /*For x In t.first .. t.last
  Loop
    Begin
      If Nvl(t(x).vlrdescfin, 0) > 0 Then
				
        Dbms_Output.put_line(t(x).nunota || ' - ' || t(x).vlrtot || ' - ' || t(x).vlrnota || ' - ' || t(x).vlrdescfin);
      
        stmt := 'Update dre_baseindpad_' || v_sufixo || ' Set vlrdesc = :vlrdescfin * qtdneg
         Where nunota = :nunota
           And sequencia = :sequencia';
      
        Execute Immediate stmt Using t(x).vlrdescfin, t(x).nunota, t(x).sequencia;
      
      End If;
    End;
  End Loop;*/

End;
1
referencia
1
01/12/2018
12
0
