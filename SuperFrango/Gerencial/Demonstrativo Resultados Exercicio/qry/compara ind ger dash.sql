PL/SQL Developer Test script 3.0
176
Declare
  p_codindger  Number;
  p_referencia Date;
	v_Nufin      Number;
  stmt         Varchar2(32000);
  head_fin     Varchar2(32000);
  head_cab     Varchar2(32000);
  ind_stmt     Varchar2(32000);
  head_stmt    Varchar2(32000);
  foot_stmt    Varchar2(32000);
  base_stmt    Varchar2(32000);

  /*Type tipo_tabela_baseindger Is Table Of ad_pkg_dre.tipo_rec_baseindger;
  t tipo_tabela_baseindger := tipo_tabela_baseindger();
  v tipo_tabela_baseindger := tipo_tabela_baseindger();
	d tipo_tabela_baseindger := tipo_tabela_baseindger();
	t tipo_tab_baseindger;
	v tipo_tab_baseindger;
	d tipo_tab_baseindger;*/
	t ad_pkg_dre.tab_rec_baseindger := ad_pkg_dre.tab_rec_baseindger();
	v ad_pkg_dre.tab_rec_baseindger := ad_pkg_dre.tab_rec_baseindger();
  c Sys_Refcursor;

Begin
  p_codindger  := :codindger;
  p_referencia := :mes;

  head_fin := 'Select 
	     upper(Substr(NCC.AD_CLACUS, 1, 2)) As PREFIXO,
       Trunc(dtentsai, ''mm'') As dtref,
       nvl(rat.nunota, rat.nufin) nunota,
       rat.codctabcoint,
       rat.numnota,
       1 as codemp,
       rat.dtneg,
       rat.dtentsai,
       rat.codparc,
       0 as coduf,
       rat.codtipoper,
       cus.ad_clacus,
       cus.ad_clacus2,
       ncc.ad_clacus clacusncc,
       rat.codcencus,
       cus.descrcencus,
       rat.codnat,
       cus.ad_codune as codune,
       rat.recdesp,
       rat.vlrdesdob,
       rat.vlrdesc,
       rat.vlrjuro,
       rat.vlrmulta,
       (RAT.VLRDESDOB - RAT.VLRDESC + RAT.VLRJURO + RAT.VLRMULTA) vlrliquido';

  head_cab := 'Select
	     case 
				  when cus.ad_clacus like ''Comercial%'' and cus.ad_clacus2 like ''O%'' then 
						''VD'' 
					else 
						upper(Substr(cus.ad_CLACUS, 1, 2))
					end As PREFIXO,
       Trunc(dtentsai, ''mm'') As dtref,
			 0 as nufin,
       cab.nunota,
       0 As codctabcoint,
       cab.numnota,
       1 as codemp,
       cab.dtneg,
       cab.dtentsai,
       cab.codparc,
       0 as coduf,
       cab.codtipoper,
       cus.ad_clacus as clacus,
       cus.ad_clacus2 as clacus2,
       Null As clacusncc,
       cab.codcencus,
       cus.descrcencus,
       cab.codnat,
       cus.ad_codune as codune,
       ite.atualestoque As recdesp,
       ite.qtdneg As vlrdesdob,
       0 As vlrdesc,
       0 vlrjuro,
       0 As vlrmulta,
       (ite.atualestoque * ite.qtdneg) vlrliquido';

  For i In (Select f.sigla,
                   f.codemp,
                   f.codune,
                   f.coduf,
                   f.clacus,
                   f.clacuscont,
                   cf.query     queryind,
                   fp.query     querybase
              From dre_cadindger c
              Join dre_forindger f
                On f.codindger = c.codindger
              Join dre_formulas cf
                On f.codform = cf.codform
              Join dre_formulas fp
                On cf.codformpai = fp.codform
             Where c.codindger = p_codindger)
  Loop
  
    ind_stmt := i.queryind;
    ind_stmt := Substr(i.queryIND, Instr(i.queryIND, 'WHERE'),
                       Length(I.queryIND) - Instr(I.queryIND, 'WHERE') + 1);
  
    ind_stmt := Substr(ind_stmt, 1, Instr(ind_stmt, 'GROUP BY') - 1);
  
    ind_stmt := 'Select * from DRE_BASEINDGER_' || To_Char(p_referencia, 'YYYYMM') || Chr(13) ||
                ind_stmt;
  
    --Dbms_Output.Put_Line(ind_stmt);
  
    foot_stmt := ') ' || Chr(13) ||
                 Substr(ind_stmt, Instr(ind_stmt, 'WHERE'),
                        Length(ind_stmt) - Instr(ind_stmt, 'WHERE'));
  
    --Dbms_Output.Put_Line(foot_stmt);
  
    /*Open c For ind_stmt
      Using p_referencia, i.codemp, i.codune, i.coduf, i.clacus, i.clacuscont;
    Fetch c Bulk Collect
      Into t;
    Close c;*/
  
    stmt := 'Select utl_raw.cast_to_varchar2( query ) 
		From tsffor f
		Where (f.descricao Like ''%' || Nvl(i.clacuscont, 'NULO') || '%''' ||
            'or nomequery like ''%' || i.sigla || '%'')' ||
            ' and dbms_lob.getlength(Query) < 4000 ';
  
    --Dbms_Output.put_Line(stmt);
  
    Execute Immediate stmt
      Into base_stmt;
    base_stmt := Replace(base_stmt, ':P_MES', '''' || To_Char(p_referencia, 'MM') || '''');
    base_stmt := Replace(base_stmt, ':P_ANO', '''' || To_Char(p_referencia, 'YYYY') || '''');
  
    If Instr(base_stmt, 'TGFCAB') > 0 Then
      head_stmt := head_cab;
    Else
      head_stmt := head_fin;
    End If;
  
    head_stmt := 'Select * from (' || Chr(13) || head_stmt || Chr(13);
  
    base_stmt := Substr(base_stmt, Instr(base_stmt, 'FROM'),
                        Length(base_stmt) - Instr(base_stmt, 'FROM') + 1) || ')';
    base_stmt := Substr(base_stmt, 1, Instr(base_stmt, 'GROUP BY') - 1);
  
    base_stmt := head_stmt || Chr(13) || base_stmt || Chr(13) || foot_stmt;
  
    --Dbms_Output.Put_Line(base_stmt);
  
    /*Open c For base_stmt
      Using p_referencia, i.codemp, i.codune, i.coduf, i.clacus, i.clacuscont;
    Fetch c Bulk Collect
      Into v;
    Close c;*/
		
		
		
		stmt := 'Select * from ('||ind_stmt ||Chr(13)||' minus '||chr(13)||base_stmt||')';
	  Dbms_Output.put_Line( stmt );
		
		Open c For stmt
		 Using p_referencia, i.codemp, i.codune, i.coduf, i.clacus, i.clacuscont;
		Fetch c Bulk Collect Into t;
		Close c;
		
    
  
  End Loop i;

End;
3
codindger
1
66
3
mes
1
01/08/2018
12
CLACUS
0
-5
0
