Create Or Replace Trigger AD_TRG_BIUD_TSFDVT_SF
  Before Insert Or Update Or Delete On AD_TSFDVT
  For Each Row
Declare
  v_NomeCampo   Varchar2(100);
  v_NewVlrDesp  Float;
  v_OldVlrDesp  Float;
  v_NewVlrChar  Varchar2(10);
  v_OldVlrChar  Varchar2(10);
  v_CodCat      Number;
  v_Codreg      Number;
  v_Dtref       Date;
  despVei       Ad_Tsfcdv%Rowtype;
  v_Form        Varchar2(4000);
  stmt          Varchar2(4000);
  busca_formula Boolean;
Begin

  /*
  * Autor: Marcus Rangel
  * Processo: Viabilidade de Veículos
  * Objetivo: Atualizar a tabela master e provocar a atualização dos campos de soma
  */

  Begin
    Select * Into despVei From Ad_Tsfcdv D Where D.Coddespvei = Nvl(:new.Coddespvei, :old.Coddespvei);
  Exception
    When no_data_found Then
      Null;
  End;

  If :new.Tipodesp = 'F' Or :old.Tipodesp = 'F' Then
    v_nomecampo  := 'VLRCUSTOFIXO';
    v_NewVlrdesp := :new.Vlrdespfixa;
    v_Oldvlrdesp := :old.Vlrdespfixa;
  Else
    v_nomecampo  := 'VLRCUSTOVAR';
    v_NewVlrDesp := :new.Vlrdespvar;
    v_oldvlrdesp := :old.Vlrdespvar;
  End If;

  If inserting Or updating Then
    If :new.Tipodesp = 'F' And Nvl(:new.Vlrdespvar, 0) > 0 Then
      Raise_Application_Error(-20105,
                              ad_fnc_formataerro('Se o tipo da despesa é <b>Fixa</b>,' ||
                                                  ' não poderá ter o valor variável preenchido.'));
    End If;
  
    If :new.Tipodesp = 'V' And Nvl(:new.Vlrdespfixa, 0) > 0 Then
      Raise_Application_Error(-20105,
                              ad_fnc_formataerro('Se o tipo da despesa é <b>Variável</b>,' ||
                                                  ' não poderá ter o valor fixo preenchido.'));
    End If;
  
    If :new.Vlrdespfixa > 0 And :new.Vlrdespvar > 0 Then
      Raise_Application_Error(-20105,
                              ad_fnc_formataerro('Informe apenas um valor para a despesa,' ||
                                                  ' a mesma não pode ser fixa e variável ao mesmo tempo.'));
    End If;
  
    If :new.Tipodesp <> :old.Tipodesp Then
      Raise_Application_Error(-20105,
                              ad_fnc_formataerro('Por favor exclua o lançamento e lançe novamente com o tipo de despesa correto'));
    End If;
  
    -- busca a categoria e a região do cabeçalho
  
    Begin
      Select V.Codregfre, V.Codcat, V.Dtref
        Into v_codreg, v_codcat, v_dtref
        From ad_tsfvvt v
       Where v.numvvt = :New.Numvvt;
    
    Exception
      When Others Then
        Raise_Application_Error(-20105, ad_fnc_formataerro(Sqlerrm));
    End;
  
    -- busca a formula para o calculo do valor da despesa variável
    -- a busca pesquisa inicialmente as exceções registradas no
    -- cadastro de regiões de frete (ad_tsfrc), se nada for encontrado
    -- a busca é feita na tabela do cadastro de despesas obtendo a fórmula
    -- padrão para a despesa
		
		If Nvl(despvei.Manual,'N') = 'N' then
      busca_formula := True;
		Elsif Nvl(despvei.Manual,'N') = 'S' And Nvl(v_newvlrdesp,0) = 0 Then
			busca_formula := True;
		Elsif Nvl(despvei.manual,'N') = 'S' And Nvl(v_newvlrdesp,0) > 0 Then
			busca_formula := False;
  end if; 
  
    If busca_formula Then
      Begin
        Select Replace(d.formula, ',', '.'), Nvl(d.imposto, 'N')
          Into v_form, despvei.imposto
          From ad_tsfrfc c
          Join ad_tsfrfr r
            On r.codregfre = c.codregfre
          Join ad_tsfrfd d
            On d.codregfre = c.codregfre
           And d.nurfr = r.nurfr
         Where c.codregfre = v_codreg
           And r.codcat = v_codcat
           And D.Coddespvei = :New.Coddespvei
           And (R.Dtvigor = (Select Max(dtvigor)
                               From ad_tsfrfr R2
                              Where R2.CODREGFRE = r.codregfre
                                And R2.CODCAT = r.codcat
                                And r2.Dtvigor < Sysdate) Or r.dtvigor = v_dtref);
      
      Exception
        When no_data_found Then
          Select Replace(formula, ',', '.'), Nvl(imposto, 'N')
            Into v_form, despvei.imposto
            From ad_tsfcdv c
           Where c.coddespvei = :New.Coddespvei;
        When too_many_rows Then
          Select Replace(d.formula, ',', '.'), Nvl(d.imposto, 'N')
            Into v_form, despvei.imposto
            From ad_tsfrfc c
            Join ad_tsfrfr r
              On r.codregfre = c.codregfre
            Join ad_tsfrfd d
              On d.codregfre = c.codregfre
             And d.nurfr = r.nurfr
           Where c.codregfre = v_codreg
             And r.codcat = v_codcat
             And D.Coddespvei = :New.Coddespvei
             And (R.Dtvigor = (Select Max(dtvigor)
                                 From ad_tsfrfr R2
                                Where R2.CODREGFRE = r.codregfre
                                  And R2.CODCAT = r.codcat
                                  And r2.Dtvigor < Sysdate) Or r.dtvigor = v_dtref)
             And Rownum = 1;
        When Others Then
          Raise_Application_Error(-20105, ad_fnc_formataerro(Sqlerrm));
      End;
    
    End If;
  
  End If;

  /*
  Begin
    Select Replace(formula, ',', '.'), Nvl(imposto, 'N')
      Into v_form, despvei.imposto
      From ad_tsfcdv c
     Where c.coddespvei = :New.Coddespvei;
  Exception
    When Others Then
      Null;
  End;
  */

  /* Atualiza os totais na master table */
  -- só atualiza o valor do campo com o da fórmula ou o da região se o valor for nulo ou zero
  --If inserting then
  If inserting Then
    Begin
    
      If v_form Is Not Null Then
        stmt := 'select round(' || v_form || ',2) from ad_tsfvvt where numvvt = :numvvt';
        Execute Immediate stmt
          Into v_newvlrdesp
          Using :new.Numvvt;
        V_Newvlrchar := Replace(To_Char(V_Newvlrdesp), ',', '.');
      Else
        V_Newvlrchar := Replace(To_Char(V_Newvlrdesp), ',', '.');
      End If;
    
      stmt := 'Update AD_TSFVVT V ' || 'SET ' || v_Nomecampo || ' = ' || v_nomecampo || ' + ' || v_newvlrchar || ', ' ||
              'VLRTOTCUSTO = VLRTOTCUSTO + ' || v_newvlrchar || ', ' || 'VLRCUSTOTEMP = VLRCUSTOTEMP + ' ||
              'CASE WHEN ''S'' = ''' || Nvl(despvei.imposto, 'N') || '''' || ' then 0 ELSE ' || v_newvlrchar || ' END ' ||
              'WHERE V.NUMVVT = :numvvt';
    
      Execute Immediate stmt
        Using :new.Numvvt;
    
    Exception
      When Others Then
        Raise_Application_Error(-20105,
                                'Erro ao executar a consulta com a fórmula da despesa (' || :new.Numvvt || '). <br>' ||
                                 Sqlerrm);
    End;
  Elsif updating Then
    Begin
      If v_form Is Not Null Then
        stmt := 'select round(' || v_form || ',2) from ad_tsfvvt where numvvt = :numvvt';
        Execute Immediate stmt
          Into v_newvlrdesp
          Using :new.Numvvt;
        V_Newvlrchar := Replace(To_Char(V_Newvlrdesp), ',', '.');
        v_OldVlrChar := Replace(To_Char(v_oldvlrdesp), ',', '.');
      Else
        V_Newvlrchar := Replace(To_Char(V_Newvlrdesp), ',', '.');
        v_OldVlrChar := Replace(To_Char(v_oldvlrdesp), ',', '.');
      End If;
    
      stmt := 'UPDATE AD_TSFVVT V ' || 'SET ' || v_nomecampo || ' = ' || v_nomecampo || ' + ' || v_newvlrchar || ' - ' ||
              v_oldvlrchar || ' , VLRTOTCUSTO = VLRTOTCUSTO + ' || v_newvlrchar || ' - ' || v_oldvlrchar || ' , ' ||
              'VLRCUSTOTEMP = VLRCUSTOTEMP + CASE WHEN ''S'' <> ''' || Nvl(despvei.imposto, 'N') || ''' THEN ' ||
              v_newvlrchar || ' - ' || v_oldvlrchar || ' ELSE 0 END WHERE V.NUMVVT = :numvvt';
    
      Execute Immediate stmt
        Using :new.Numvvt;
    Exception
      When Others Then
        Raise;
    End;
  Elsif deleting Then
    Begin
      v_OldVlrChar := Replace(To_Char(v_oldvlrdesp), ',', '.');
      stmt         := 'Update AD_TSFVVT V ' || 'SET ' || v_Nomecampo || ' = ' || v_nomecampo || ' - ' || v_oldvlrchar || ', ' ||
                      'VLRTOTCUSTO = VLRTOTCUSTO - ' || v_oldvlrchar || ', ' || 'VLRCUSTOTEMP = VLRCUSTOTEMP - ' ||
                      'CASE WHEN ''S'' = ''' || Nvl(despvei.imposto, 'N') || '''' || ' THEN 0 ELSE ' || v_oldvlrchar ||
                      ' END ' || 'WHERE V.NUMVVT = :numvvt';
    
      Execute Immediate stmt
        Using :old.Numvvt;
    Exception
      When Others Then
        Raise;
    End;
  End If;

  If inserting Or updating Then
    If :new.Tipodesp = 'F' Then
      :New.Vlrdespfixa := v_newvlrdesp;
    Else
      :new.Vlrdespvar := v_newvlrdesp;
    End If;
  End If;

  Begin
    Update ad_tsfvvt
       Set codusu  = stp_get_codusulogado(),
           dhalter = Sysdate
     Where numvvt = Nvl(:new.Numvvt, :old.Numvvt);
  
  Exception
    When Others Then
      Raise;
  End;

End;
/
