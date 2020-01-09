PL/SQL Developer Test script 3.0
183
Declare
  p_CodIndPad   Int;
  i             Int := 0;
  v_formula_ind Clob;
  v_formula_all Clob;
  v_query       Clob;
  stmt          Clob;

  v_offset     Number Default 1;
  v_chunk_size Number := 32000;

  /*Type rec_resultados Is Record(
    nunota        Number,
    sequencia     Int,
    VlrTransf     Float,
    PrecoVdaSemST Float,
    DescConced    Float,
    PrecoVenda    Float,
    IcmsVenda     Float,
    CredOutVenda  Float,
    CredOutTransf Float,
    CredPresumido Float,
    IcmsTransf    Float,
    Pis           Float,
    Cofins        Float,
    CredPisCofins Float,
    QtdTotal      Float,
    CustoProd     Float,
    CrossDock     Float,
    OverAdm       Float,
    OverProd      Float,
    OverUn        Float,
    FreteTerra    Float,
    FreteMar      Float,
    Comissao      Float,
    ProtGOVenda   Float,
    ProtGOTrans   Float,
    ProtEduTribDF Float,
    FunGerEmpDF   Float,
    SubstTrib     Float,
    AntecipIcms   Float,
    DespFin       Float,
    RecFin        Float,
    Descontos     Float,
    DespDir       Float,
    CredIcmTransf Float);

  Type tab_resultados Is Table Of rec_resultados;
  t tab_resultados := tab_resultados();*/
  
  type tab_resultados is table of DRE_RENTABCOM%rowtype;
  t tab_resultados := tab_resultados();

  c Sys_Refcursor;

Begin

  --p_CodIndPad := 49;

  For l In (Select dc.codindpad,
                   dc.descrindpad,
                   Replace(Upper(fp.formindpad), 'SUM', '') formindpad,
                   dc.ativo,
                   dc.totalizador,
                   dc.temexc,
                   fp.dhvigor,
                   fp.codforpad,
                   dc.abrev
              From Dre_cadindpad dc
              Join dre_forindpad fp
                On dc.codindpad = fp.codindpad
             Where Nvl(dc.Ativo, 'N') = 'S'
               And Nvl(dc.totalizador, 'N') = 'N'
               And fp.Formindpad Is Not Null
               --And (dc.codindpad = p_CodIndPad Or Nvl(p_CodIndPad, 0) = 0)
               --And dc.codindpad = 23
               And fp.dhvigor = (Select Max(dhvigor)
                                   From dre_forindpad ff
                                  Where ff.codindpad = fp.codindpad
                                    And ff.dhvigor <= Sysdate)
             Order By dc.totalizador, dc.codindpad)
  Loop
  
    v_formula_ind := Null;
  
    If (l.temexc = 'S') Then
    
      For txt In (Select e.codindpad,
                         p.abrev,
                         e.dhvigor,
                         codemp,
                         codune,
                         codgrupoprod,
                         codprod,
                         coduf,
                         'when (codemp = ' || e.codemp || ' or ' || e.codemp || ' = 0)' || Chr(13) || ' and (codune = ' ||
                         e.codune || ' or ' || e.codune || ' = 0)' || Chr(13) || ' and (codgrupoprod = ' ||
                         e.codgrupoprod || ' or ' || e.codgrupoprod || ' = 0 )' || Chr(13) || ' and (codprod = ' ||
                         e.codprod || ' or ' || e.codprod || ' = 0)' || Chr(13) || ' and (coduf = ' || e.coduf || ' or ' ||
                         e.coduf || ' = 0) then ' || Chr(13) || Case
                           When e.tipovlr = 'F' Then
                            Replace(e.formexc, 'SUM', '')
                           Else
                            To_Char(e.vlrperc)
                         End As formula
                    From dre_excecoes e
                    Join dre_cadindpad p
                      On p.codindpad = e.codindpad
                   Where Nvl(e.ativo, 'N') = 'S'
                     And e.codindpad = L.CODINDPAD
                     And e.dhvigor = (Select Max(dhvigor)
                                        From dre_excecoes ei
                                       Where ei.codindpad = e.codindpad
                                         And Nvl(ativo, 'N') = 'S'
                                         And ei.codemp = e.codemp
                                         And ei.codune = e.codune
                                         And ei.coduf = e.coduf
                                         And ei.codgrupoprod = e.codgrupoprod
                                         And ei.codprod = e.codprod)
                   Order By e.codindpad)
      Loop
        v_formula_ind := v_formula_ind || Chr(13) || Nvl(txt.formula, l.formindpad);
      End Loop txt;
    
      If (v_formula_ind Is Not Null) Then
        v_formula_ind := ' case ' || v_formula_ind || ' else ' || l.formindpad || ' end as ' || l.abrev;
      Else
        v_formula_ind := l.formindpad || ' as ' || l.abrev;
      End If;
    
    Else
    
      v_formula_ind := l.formindpad || ' as ' || l.abrev;
    
    End If;
  
    dbms_output.put_line(v_formula_ind);
  
    If (v_formula_all Is Null) Then
      v_formula_all := v_formula_ind;
    Else
      v_formula_all := v_formula_all || ', ' || Chr(13) || v_formula_ind;
    End If;
    
    dbms_output.put_line('--Indicador: ' || l.codindpad);
  
  End Loop l;

  /*
  dbms_output.put_line( 'select ''01/05/2019'' DTREF,  nunota, sequencia, codemp, codune codgrupoprod, codprod, coduf, vlrunit, qtdneg, ' ); 
  Loop
    Exit When v_offset > dbms_lob.getlength(v_formula_all);
      dbms_output.put_line( dbms_lob.substr( v_formula_all, v_chunk_size, v_offset ) );
      v_offset := v_offset + v_chunk_size;
    End Loop;
    dbms_output.put_line( 'from DRE_BASEINDPAD_201905');
    dbms_output,put_line(' where codemp = 1 and codgrupoprod = 3030100 and coduf = 5' ); 
*/
  
  v_query := 'Select ''01/05/2019'' as dtref, nunota, sequencia, ' || v_formula_all || Chr(13) || ' from DRE_BASEINDPAD_201905';

  --dbms_output.put_line( v_query ); 

  Open c For v_query;
  Fetch c Bulk Collect
    Into t;
  Close c;
  
  forall x in t.first .. t.last
   insert into dre_rentabcom
   values t(x);

  /*
   Dbms_Output.put_line(  
   --dbms_lob.getlength(v_formula_all )
   dbms_lob.substr(v_formula_all, 32000, 1)||Chr(13)|| dbms_lob.substr(v_formula_all, 64000,32001)||Chr(13)|| dbms_lob.substr(v_formula_all, 76000,64001)
   --||Chr(13)||dbms_lob.substr(v_formula_all, 8000, 4001) ||Chr(13)|| dbms_lob.substr(v_formula_all, 12000, 8001)
   );
  */

  --dbms_output.put_line('--tamanho do clob: ' || dbms_lob.getlength(v_formula_all));

End;
0
3
l.codindpad
v_formula_ind
v_formula_all
