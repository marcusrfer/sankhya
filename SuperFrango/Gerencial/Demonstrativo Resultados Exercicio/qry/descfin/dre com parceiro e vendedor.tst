PL/SQL Developer Test script 3.0
205
Declare

  Type rec_baseindpad2 Is Record(
    dtref        Date,
    codemp       Number,
    codune       Number,
    codparc      Number,
    codvend      Number,
    codcencus    Number,
    codgrupoprod Number,
    codprod      Number,
    coduf        Number);

  Type tipo_record_dre Is Record(
    dtref         Date,
    codemp        Number,
    codune        Number,
    codparc       Number,
    codvend       Number,
    codcencus     Number,
    codgrupoprod  Number,
    codprod       Number,
    coduf         Number,
    PrecoVenda    Float Default 0,
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
    VlrTransf     Float,
    PrecoVdaSemST Float,
    CredIcmTransf Float,
    DescConced    Float);

  Type tipo_tabela_dre Is Table Of tipo_record_dre;
  t tipo_tabela_dre := tipo_tabela_dre();

  Type tipo_tab_baseindpad2 Is Table Of rec_baseindpad2;
  t_base tipo_tab_baseindpad2 := tipo_tab_baseindpad2();

  c_base Sys_Refcursor;
  stmt Varchar2(32000);

  p_referencia Date;
  v_formula Varchar2(32000);
  v_query Varchar2(32000);
  v_valor Float;

  x Int;
  z Int;
Begin

  p_referencia := '01/12/2018';

  stmt := 'Select dtref, codemp, codune, codparc, codvend, codcencus, codgrupoprod, codprod, coduf' ||
          ' from dre_baseindpad_' || To_Char(p_referencia, 'YYYYMM') ||
          ' where tipmov = ''V'' and qtdneg > 0  and codprod = 18856' ||
          ' group by dtref, codemp, codune, codparc, codvend, codcencus, codgrupoprod, codprod, coduf';

  Open c_base For stmt;
  Fetch c_base Bulk Collect
    Into t_base;
  Close c_base;

  For i In t_base.first .. t_base.last
  Loop
    t.extend;
    x := t.last;
    t(x).dtref := t_base(i).dtref;
    t(x).codemp := t_base(i).codemp;
    t(x).codune := t_base(i).codune;
    t(x).codparc := t_base(i).codparc;
    t(x).codvend := t_base(i).codvend;
    t(x).codcencus := t_base(i).codcencus;
    t(x).codgrupoprod := t_base(i).codgrupoprod;
    t(x).codprod := t_base(i).codprod;
    t(x).coduf := t_base(i).coduf;
  
    For c_Ind In (Select dc.codindpad, dc.descrindpad, fp.formindpad, dc.ativo, dc.totalizador, dc.temexc,
                         fp.dhvigor, fp.codforpad, dc.abrev
                    From Dre_cadindpad dc
                    Join dre_forindpad fp
                      On dc.codindpad = fp.codindpad
                   Where Nvl(dc.Ativo, 'N') = 'S'
                     And fp.Formindpad Is Not Null
                     And fp.dhvigor = (Select Max(dhvigor)
                                         From dre_forindpad ff
                                        Where ff.codindpad = fp.codindpad
                                          And ff.dhvigor <= Sysdate)
                   Order By dc.totalizador, dc.codindpad)
    Loop
    
      v_query := 'Select :FORMULA from dre_baseindpad_' || To_Char(p_referencia, 'YYYYMM') ||
                 ' Where dtref = :dtref ' || ' and codemp = :codemp ' || ' and codune = :codune ' ||
                 ' and codparc = :codparc ' || ' and codvend = :codvend ' || ' and codcencus = :codcencus ' ||
                 ' and codgrupoprod  = :codgrupoprod ' || ' and codprod = :codprod ' || ' and coduf = :coduf' ||
                 ' Group by dtref, codemp, codune, codparc, codvend, codcencus, codgrupoprod, codprod, coduf';
    
      If Nvl(c_Ind.Totalizador, 'N') = 'N' Then
      
        If Nvl(c_Ind.temexc, 'N') = 'S' Then
        
          ad_pkg_dre.get_formula_excecao_codexc(p_codind => c_ind.codindpad, p_codemp => t_base(i).codemp,
                                                p_codune => t_base(i).codune,
                                                p_codgrupoprod => t_base(i).codgrupoprod,
                                                p_codprod => t_base(i).codprod, p_coduf => t_base(i).coduf,
                                                p_formula => v_formula, p_codexc => z);
        
          -- se não encontrou nenhuma exceção, usa a fórmula do cadastro
          If v_Formula Is Null Then
            v_Formula := c_Ind.formindpad;
          End If;
        Else
          v_Formula := c_Ind.formindpad;
        End If;
      
        v_Query := Replace(v_query, ':FORMULA', v_Formula);
      
      Else
        -- tratativa para o usuário consegui utilizar nomes mais amigáveis das funções de valor
        v_Formula := c_Ind.formindpad;
        v_formula := Replace(v_formula, 'VALOR_INDICADOR(', 'AD_PKG_DRE.GET_RESINDPAD(DTREF,');
        v_formula := Replace(v_formula, 'VLRIND_GERENCIAL(', 'AD_PKG_DRE.GET_RESINDGER(DTREF,');
        v_Formula := Replace(v_formula, ')', ',CODPROD,CODEMP,CODUNE,CODUF)');
        v_Query := Replace(v_query, ':FORMULA', v_Formula);
      End If;
    
      Begin
        Execute Immediate v_query
          Into v_valor
          Using t(x).dtref, t(x).codemp, t(x).codune, t(x).codparc, t(x).codvend, t(x).codcencus, t(x).codgrupoprod, t(x).codprod, t(x).coduf;
      Exception
        When Others Then
          dbms_output.put_line(Sqlerrm);
          dbms_output.put_line(v_query);
          ad_pkg_var.errmsg := t(x).dtref || ' - ' || t(x).codemp || ' - ' || t(x).codune || ' - ' || t(x)
                               .codparc || ' - ' || t(x).codvend || ' - ' || t(x).codcencus || ' - ' || t(x)
                               .codgrupoprod || ' - ' || t(x).codprod || ' - ' || t(x).coduf;
          dbms_output.put_line(ad_pkg_var.errmsg);
      End;
    
      -- NoFormat Start
               if c_Ind.abrev ='PrecoVenda' then t(x).PrecoVenda := v_valor;
              elsif c_Ind.abrev ='IcmsVenda' then t(x).IcmsVenda := v_valor;
              elsif c_Ind.abrev ='CredOutVenda' then t(x).CredOutVenda := v_valor;
              elsif c_Ind.abrev ='CredOutTransf' then t(x).CredOutTransf := v_valor;
              elsif c_Ind.abrev ='CredPresumido' then t(x).CredPresumido := v_valor;
              elsif c_Ind.abrev ='IcmsTransf' then t(x).IcmsTransf := v_valor;
              elsif c_Ind.abrev ='Pis' then t(x).Pis := v_valor;
              elsif c_Ind.abrev ='Cofins' then t(x).Cofins := v_valor;
              elsif c_Ind.abrev ='CredPisCofins' then t(x).CredPisCofins := v_valor;
              elsif c_Ind.abrev ='QtdTotal' then t(x).QtdTotal := v_valor;
              elsif c_Ind.abrev ='CustoProd' then t(x).CustoProd := v_valor;
              elsif c_Ind.abrev ='CrossDock' then t(x).CrossDock := v_valor;
              elsif c_Ind.abrev ='OverAdm' then t(x).OverAdm := v_valor;
              elsif c_Ind.abrev ='OverProd' then t(x).OverProd := v_valor;
              elsif c_Ind.abrev ='OverUn' then t(x).OverUn := v_valor;
              elsif c_Ind.abrev ='FreteTerra' then t(x).FreteTerra := v_valor;
              elsif c_Ind.abrev ='FreteMar' then t(x).FreteMar := v_valor;
              elsif c_Ind.abrev ='Comissao' then t(x).Comissao := v_valor;
              elsif c_Ind.abrev ='ProtGOVenda' then t(x).ProtGOVenda := v_valor;
              elsif c_Ind.abrev ='ProtGOTrans' then t(x).ProtGOTrans := v_valor;
              elsif c_Ind.abrev ='ProtEduTribDF' then t(x).ProtEduTribDF := v_valor;
              elsif c_Ind.abrev ='FunGerEmpDF' then t(x).FunGerEmpDF := v_valor;
              elsif c_Ind.abrev ='SubstTrib' then t(x).SubstTrib := v_valor;
              elsif c_Ind.abrev ='AntecipIcms' then t(x).AntecipIcms := v_valor;
              elsif c_Ind.abrev ='DespFin' then t(x).DespFin := v_valor;
              elsif c_Ind.abrev ='RecFin' then t(x).RecFin := v_valor;
              elsif c_Ind.abrev ='Descontos' then t(x).Descontos := v_valor;
              elsif c_Ind.abrev ='DespDir' then t(x).DespDir := v_valor;
              elsif c_Ind.abrev ='VlrTransf' then t(x).VlrTransf := v_valor;
              elsif c_Ind.abrev ='PrecoVdaSemST' then t(x).PrecoVdaSemST := v_valor;
              elsif c_Ind.abrev ='CredIcmTransf' then t(x).CredIcmTransf := v_valor;
              elsif c_Ind.abrev ='DescConced' then t(x).DescConced := v_valor;
               End If;
               -- NoFormat End
    End Loop c_ind;
  
  End Loop i;

  Forall z In t.first .. t.last
    Insert Into dre_basecom_201812 Values t (z);
End;
1
codexc
0
-5
0
