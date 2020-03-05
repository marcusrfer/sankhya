PL/SQL Developer Test script 3.0
33
-- Created on 28/06/2017 by M.RANGEL 
--- credito outorgado
Declare
  -- Local variables here
  i Float := 0;
Begin
  For dre In (Select *
                From AD_TEMPDRE01
               Where nunota = :nunota
                 And sequencia = :seq)
  Loop
  
    If dre.codgrupoprod = 3020200 Then
      If dre.codemp = 1 And dre.coduf <> 9 Then
        i := i + (dre.vlrunit + dre.vlripi - dre.vlrdesc) * 0.02 * dre.qtdneg;
      Elsif dre.codemp = 5 And dre.codune In (3, 7) Then
        i := i + 1 * (Nvl(dre.vlrtrx, 0) * 0.02 * dre.qtdneg);
      Elsif dre.codemp = 7 And dre.codune = 6 Then
        i := i + Nvl(dre.vlrtrx, 0) * 0.02 * dre.qtdneg;
      Elsif dre.codemp = 14 Then
        i := i + 1 * (Nvl(dre.vlrtrx, 0) * 0.02 * dre.qtdneg);
      Else
        i := i + (dre.vlrunit + dre.vlripi - dre.vlrdesc) * 0.07;
      End If;
    End If;
  
    i := i / dre.qtdneg;
  
    :Result := Round(i, 6);
  
  End Loop;
  Dbms_Output.put_line(i);
End;
4
nunota
1
25436768
3
seq
1
1
3
resul
1
,152
-5
Result
1
,152
5
1
i
