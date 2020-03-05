PL/SQL Developer Test script 3.0
50
Declare
  p_referencia Date;
  v_sufixo Varchar2(6);
  p_codemp Number;
  p_codune Number;
  p_coduf Number;
  p_codprod Number;
  v_vlrdesc Float;
  i Int := 0;
  stmt Varchar2(32000);
Begin

  p_referencia := '01/12/2018';
  v_sufixo := To_Char(p_referencia, 'YYYYMM');

  -- simula a execu��o da procedure
  For r In (Select codemp, codune, coduf, codprod, Sum(qtdneg) qtdneg
              From dre_baseindpad_201812
             Group By codemp, codune, coduf, codprod)
  Loop
    p_codemp := r.codemp;
    p_codune := r.codune;
    p_coduf := r.coduf;
    p_codprod := r.codprod;
  
    Stmt := 'Select vlrdesc ' || 'From dre_basevlrdesc_' || v_sufixo || '	Where codemp = :codemp
				 And codune = :codune
				 And coduf = :coduf
				 And codprod = :codprod';
  
    Begin
      Execute Immediate Stmt
        Into v_vlrdesc
        Using p_codemp, p_codune, p_coduf, p_codprod;
    Exception
      When no_data_found Then
        v_vlrdesc := 0;
        Null;
    End;
  

    If v_vlrdesc > 0 Then
			i := i + 1;
			v_vlrdesc := fc_divide(v_vlrdesc, r.qtdneg);
      Dbms_Output.put_line(i ||' - '||  r.codemp ||' - '|| r.codune ||' - '|| r.coduf ||' - '||  r.codprod || ' - ' || v_vlrdesc);
    End If;
  
  End Loop;
	
End;
0
0
