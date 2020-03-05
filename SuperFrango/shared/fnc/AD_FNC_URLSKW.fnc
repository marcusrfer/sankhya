Create Or Replace Function Ad_fnc_urlskw(p_Tabela Varchar2, p_Nuchave Number, p_Nomedet Varchar2 Default Null,
                                         p_Iditem Varchar2 Default Null) Return Varchar2 Is
  v_Urlskw    Varchar2(100);
  v_Protocolo Varchar2(10);
  v_Url       Varchar2(100);
  v_Porta     Varchar2(10);
  v_Resource  Varchar2(100);
  v_Nomepk    Varchar2(100);
  v_Nuchave   Varchar2(100);
  v_Link      Varchar2(2000);
  v_Jsonpk    Varchar2(100);
  v_Jsonpkdsb Varchar2(200);
  Errmsg      Varchar2(4000);

  Function To_base64(t In Varchar2) Return Varchar2 Is
  Begin
    Return Utl_raw.Cast_to_varchar2(Utl_encode.Base64_encode(Utl_raw.Cast_to_raw(t)));
  End To_base64;

Begin
  v_Urlskw    := Get_tsipar_texto('URLSANKHYAW');
  v_Urlskw    := Replace(v_Urlskw, '/', '');
  v_Protocolo := Substr(v_Urlskw, 1, Instr(v_Urlskw, ':') - 1);
  v_Url       := Substr(v_Urlskw,
                        Instr(v_Urlskw, ':', 1, 1) + 1,
                        (Instr(v_Urlskw, ':', 1, 2) - Instr(v_Urlskw, ':', 1, 1) - 1));
  Begin
    v_Porta := Substr(v_Urlskw, Instr(v_Urlskw, ':', 1, 2) + 1, Length(v_Urlskw));
  
  Exception
    When Others Then
      v_Urlskw := Get_tsipar_texto('URLSANKHYAW');
      v_Porta  := Null;
  End;

  v_Nuchave := To_Char(p_Nuchave);

  If p_Tabela = 'TGFFIN' Then
    v_Resource := 'br.com.sankhya.fin.cad.movimentacaoFinanceira';
  Elsif p_Tabela = 'TGFCAB' Then
    v_Resource := 'br.com.sankhya.com.mov.CentralNotas';
  Elsif p_Tabela = 'TCSCON' Then
    v_Resource := 'br.com.sankhya.os.cad.contratos';
  Elsif p_Tabela = 'TSILIB' Then
    v_Resource := 'br.com.sankhya.hnzliberacao.mov.liberacao.limites'; -- esse é o link que redireciona para Configurações » Avançado » Liberação de Limites - SSA
    -- 'br.com.sankhya.liberacao.limites'; esse é o link padrão do Sankhya
    v_Nomepk := 'NUCHAVE';
  Elsif p_Tabela = 'TSIDSB' Then
    v_Resource  := 'br.com.sankhya.menu.adicional.';
    v_Nomepk    := 'nuDsb.';
    v_Nuchave   := v_Nuchave || '.1';
    v_Jsonpkdsb := v_Nomepk || v_Nuchave;
  Elsif p_Tabela Like 'AD_%' Then
    v_Resource := 'br.com.sankhya.menu.adicional.' || Replace(p_Tabela, 'AD_', '');
  Elsif p_tabela = 'TCSCON_AD' Then
    v_Resource := 'br.com.sankhya.os.cad.contratos__1481549812553.1';
    v_Nomepk   := 'NUMCONTRATO';
  Elsif p_Tabela = 'AD_VALMES' Then
    v_Nomepk := 'VADTREFER';
  Else
    Select i.Resourceid
      Into V_resource
      From Tddins i
     Where Nometab = P_tabela
       And Raiz = 'S';
  End If;

  If v_Nomepk Is Null Then
    Select COLS.Column_name
      Into V_nomepk
      From All_constraints Cons, All_cons_columns COLS
     Where COLS.Table_name = P_tabela
       And Cons.Constraint_type = 'P'
       And Cons.Constraint_name = COLS.Constraint_name
       And Cons.Owner = COLS.Owner;
  End If;

  If p_Nomedet Is Not Null And p_Iditem Is Not Null Then
    v_Jsonpk := '{"' || v_Nomepk || '":"' || v_Nuchave || '","' || p_Nomedet || '":"' || p_Iditem || '"}';
  Else
    v_Jsonpk := '{"' || v_Nomepk || '":"' || v_Nuchave || '"}';
  End If;

  If v_Porta Is Not Null Then
  
    If p_Tabela = 'TSIDSB' Then
      v_Link := v_Protocolo || '://' || v_Url || ':' || v_Porta || '/mge/system.jsp#app/' || To_base64(v_Resource) ||
                To_base64(v_Jsonpkdsb);
    Else
      v_Link := v_Protocolo || '://' || v_Url || ':' || v_Porta || '/mge/system.jsp#app/' || To_base64(v_Resource) || '/' ||
                To_base64(v_Jsonpk);
    End If;
  
  Else
  
    If p_Tabela = 'TSIDSB' Then
      v_Link := v_Urlskw || '/mge/system.jsp#app/' || To_base64(v_Resource) || To_base64(v_Jsonpkdsb);
    Else
      v_Link := v_Urlskw || '/mge/system.jsp#app/' || To_base64(v_Resource) || '/' || To_base64(v_Jsonpk);
    End If;
  
  End If;

  Return v_Link;

  Dbms_output.Put_line(v_Link);
  Return v_Link;

Exception
  When Others Then
    Errmsg := Sqlerrm;
    Return Null;
End;
/
