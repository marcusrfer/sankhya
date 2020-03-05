PL/SQL Developer Test script 3.0
27
Declare
  p_referencia Date := '01/12/2018';
  v_sufixo Varchar2(6);
  v_nometab Varchar2(30);
  stmt Varchar2(32000);
  i Int := 0;
Begin

  v_sufixo := To_Char(p_referencia, 'YYYYMM');
  v_nometab := 'DRE_BASEVLRDESC_' || v_sufixo;

  Select Count(*) Into i From User_Tables ut Where ut.TABLE_NAME = v_nometab;

  If i > 0 Then
    Execute Immediate ' drop table ' || v_nometab;
  End If;

  Select f.query Into Stmt From dre_formulas f Where f.codform = 18;

  stmt := 'Create Table ' || v_nometab || ' As  ' ||
          'Select codemp, codune, codparc, codvend, codcencus, coduf, codprod, Sum(vlrdesc) vlrdesc from (' || stmt ||
          ') where trunc(dhbaixa,''mm'') = ''' || p_referencia || '''' ||
          ' group by codemp, codune, codparc, codvend, codcencus, coduf, codprod';

  Execute Immediate Stmt;

End;
0
0
