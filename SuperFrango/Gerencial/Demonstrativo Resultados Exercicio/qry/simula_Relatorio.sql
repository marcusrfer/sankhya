PL/SQL Developer Test script 3.0
24
Begin
 
      Dbms_Output.put_line('Codune - Sigla  -  Codmeta  -  Descrmeta - Ufparc - codprod - VlrMeta');

  For R In (Select Distinct d.ufparc, d.coduf, d.codprod, p.descrprod
              From ad_basedre d
              Join tgfpro p On d.codprod = p.codprod
             Where dtfatur Between :dataini And :datafin
               And d.codprod = :codprod
             Order By d.ufparc)
  Loop
    For S In (Select u.codune, u.sigla, d.codmeta, d.descrmeta, d.ufparc, d.codprod, d.vlrmeta
                From ad_tsfune u,
                     Table(ad_pkg_dre.report_dre(:dataini, :datafin, r.coduf, r.codprod)) D
               Where u.codune = d.codune(+)
               Order By D.UFPARC, d.codmeta, u.sigla)
    Loop
    
      Dbms_Output.put_line(s.Codune || ' - ' || s.Sigla || ' - ' || s.Codmeta || ' - ' || s.Descrmeta ||
                           ' - ' || s.Ufparc || ' - ' || s.codprod || ' - ' || s.VlrMeta);
    End Loop S;
  End Loop R;

End;
3
dataini
1
01/03/2017
12
datafin
1
31/03/2017
12
codprod
1
41107
3
0
