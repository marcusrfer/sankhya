PL/SQL Developer Test script 3.0
61
Declare
  r         ad_tsfdrer%Rowtype;
  saida     Varchar2(4000);
  v_codmeta Number;
Begin
  -- Test statements here
  v_codmeta := 102001;

  For dre In (Select *
                From ad_basedre bd
               Where Trunc(bd.dtfatur, 'mm') = '01/05/2017'
                 And bd.codemp = 7
                 And tipmov = 'V')
  Loop
    Select f.nudrec, f.nudrer, f.tipovalor, f.vlrmeta, f.formula
      Into r.nudrec, r.nudrer, r.tipovalor, r.vlrmeta, r.formula
      From (Select Distinct c.nudrec, r.nudrer, r.tipovalor, r.vlrmeta, r.formula
              From ad_tsfdrec c
              Join ad_tsfdrer r On c.nudrec = r.nudrec
                               And r.codmeta = v_codmeta
                               And Nvl(r.ativo, 'N') = 'S'
                               And Nvl(r.tipoexcecao, 'E') = 'I'
              Left Join ad_tsfdree e On e.nudrer = r.nudrer
              Left Join ad_tsfdreg g On g.nudrer = r.nudrer
              Left Join ad_tsfdrep p On p.nudrer = r.nudrer
              Left Join ad_tsfdreu u On u.nudrer = r.nudrer
             Where c.codemp = dre.codemp
               And Nvl(e.codune, 0) = Nvl(&codune, 0)
               And Nvl(g.codgrupoprod, 0) = Nvl(&codgrupo, 0)
               And Nvl(p.codprod, 0) = Nvl(&codprod, 0)
               And Nvl(u.coduf, 0) = Nvl(&coduf, 0)
            Union
            Select Distinct c.nudrec, r.nudrer, r.tipovalor, r.vlrmeta, r.formula
              From ad_tsfdrec c
              Join ad_tsfdrer r On c.nudrec = r.nudrec
                               And r.codmeta = v_codmeta
                               And Nvl(r.ativo, 'N') = 'S'
                               And Nvl(r.tipoexcecao, 'I') = 'E'
             Where c.codemp = dre.codemp
               And Not Exists (Select 1
                      From ad_tsfdree e
                     Where e.nudrer = r.nudrer
                       And e.codune = dre.codemp)
               And Not Exists (Select 1
                      From ad_tsfdreg g
                     Where g.nudrer = r.nudrer
                       And g.codgrupoprod = dre.codgrupoprod)
               And Not Exists (Select 1
                      From ad_tsfdrep p
                     Where p.nudrer = r.nudrer
                       And p.codprod = dre.codprod)
               And Not Exists (Select 1
                      From ad_tsfdreu u
                     Where u.nudrer = r.nudrer
                       And u.coduf = dre.coduf)) F;
  
    saida := dre.nunota || ' - ' || dre.sequencia || ' - ' || v_codmeta || ' - ' || r.nudrec || ' - ' || r.nudrer ||
             ' - ' || r.formula;
    Dbms_Output.put_line(saida);
  End Loop;
End;
1
codmeta
1
102001
-3
6
dre.nunota
dre.codgrupoprod
dre.codprod
dre.coduf
dre.codune
dre.sequencia
