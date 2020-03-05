PL/SQL Developer Test script 3.0
53
-- Created on 12/05/2017 by M.RANGEL 
Declare
  Type Cur_Typ Is Ref Cursor;
  c         Cur_Typ;
  d         ad_pkg_dre.Ty_Basedre;
  Stmt      Varchar2(4000);
  Errmsg    Varchar2(4000);
  p_Dataini Date;
  p_Datafin Date;
  p_Coduf   Int;
  p_Codprod Number;
Begin
  p_Coduf   := 7;
  p_Codprod := 41107;
  p_Dataini := '01/03/2017';
  p_Datafin := '31/03/2017';

  For m In (Select *
              From Ad_Tsfdre
             Where Analitico = 'S'
               And codmeta = :CODMETA 
             Order By Codmeta)
  Loop
    Begin
      d.Codmeta   := m.Codmeta;
      d.Descrmeta := m.Descrmeta;
    
      Stmt := 'SELECT CODUNE, CODUF, UFPARC, CODPROD, ' || Nvl(m.Formrel, 0) || '
                FROM AD_BASEDRE
               WHERE DTFATUR BETWEEN ''' || p_Dataini || ''' AND ''' || p_Datafin || '''
                AND CODPROD = ' || p_Codprod || '
                AND CODUF =' || p_Coduf || '
                GROUP BY CODUNE, CODUF, UFPARC, CODPROD';
    
      Open c For Stmt;
      Loop
        Fetch c
          Into d.Codune, d.Coduf, d.Ufparc, d.Codprod, d.Vlrmeta;
        Exit When c % Notfound;
      
        If d.Vlrmeta Is Not Null Then
          --d.Vlrmeta := 0;
          --Pipe Row(d);
        
          Dbms_Output.Put_Line(d.Codmeta || ' - ' || d.Descrmeta || ' - ' || d.Codune || ' - ' ||
                               d.Ufparc || ' - ' || d.Codprod || ' - ' || d.Vlrmeta);
        End If;
      
      End Loop;
      Close c;
    End;
  End Loop m;
End;
1
CODMETA
1
102001
3
0
