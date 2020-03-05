PL/SQL Developer Test script 3.0
169
Declare
  p_Nunota    Number;
  p_Sequencia Int;
  p_Codmeta   Number;
  r_Dre       Ad_basedre % Rowtype;
  v_Nroregra  Int;
  v_Nroex     Int;
  v_Unneg     Boolean;
  v_Uf        Boolean;
  v_Produto   Boolean;
  v_Grupo     Boolean;
  v_Valor     Float;
  stmt        Varchar2(4000);
  Pragma Autonomous_Transaction;
Begin
  p_Nunota    := :nunota;
  p_Sequencia := :seq;
  p_Codmeta   := :codmeta;

  Select *
    Into r_Dre
    From Ad_basedre
   Where Nunota = p_Nunota
     And Sequencia = p_Sequencia;

  Select Nudrec
    Into v_Nroregra
    From Ad_tsfdrec C
   Where Codemp = r_Dre.Codemp
     And C.Dhvigencia = (Select Max(Dhvigencia) From Ad_tsfdrec Where Codemp = r_Dre.Codemp);

  For C_exc In (Select *
                  From Ad_tsfdrer r
                 Where r.Nudrec = v_Nroregra
                   And r.Codmeta = p_Codmeta
                 Order By r.Nudrer)
  Loop
  
    For C_neg In (Select *
                    From Ad_tsfdree E
                   Where E.Nudrec = C_exc.Nudrec
                     And E.Nudrer = C_exc.Nudrer)
    Loop
    
      If C_exc.Tipoexcuneg = 'I' Then
      
        If C_neg.Codune = r_Dre.Codune Then
          v_Unneg := True;
        End If;
      
      Else
      
        If C_neg.Codune <> r_Dre.Codune Then
          v_Unneg := True;
        End If;
      
      End If;
    
    End Loop C_neg;
  
    If v_Unneg Is Null Then
      v_Unneg := True;
    End If;
  
    For C_uf In (Select *
                   From Ad_tsfdreu u
                  Where u.Nudrec = C_exc.Nudrec
                    And u.Nudrer = C_exc.Nudrer)
    Loop
    
      If C_uf.Coduf = r_Dre.Coduf Then
        v_Uf := True;
      End If;
    
    End Loop;
  
    If v_Uf Is Null Then
      v_Uf := True;
    End If;
  
    For C_prod In (Select *
                     From Ad_tsfdrep P
                    Where P.Nudrec = C_exc.Nudrec
                      And P.Nudrer = C_exc.Nudrer)
    Loop
    
      If C_exc.Tipoexcpro = 'I' Then
      
        If C_prod.Codprod = r_Dre.Codprod Then
          v_Produto := True;
        End If;
      
      Else
      
        If C_prod.Codprod <> r_Dre.Codprod Then
          v_Produto := True;
        End If;
      
      End If;
    
    End Loop;
  
    If v_Produto Is Null Then
      v_Produto := True;
    End If;
  
    For C_gru In (Select *
                    From Ad_tsfdreg g
                   Where g.Nudrec = C_exc.Nudrec
                     And g.Nudrer = C_exc.Nudrer)
    Loop
    
      If C_exc.Tipoexcgru = 'I' Then
      
        If C_gru.Codgrupoprod = r_Dre.Codgrupoprod Then
          v_Grupo := True;
        End If;
      
      Else
      
        If C_gru.Codgrupoprod <> r_Dre.Codgrupoprod Then
          v_Grupo := True;
        End If;
      
      End If;
    
    End Loop;
  
    If v_Grupo Is Null Then
      v_Grupo := True;
    End If;
  
    If (v_Unneg = True And v_Uf = True And v_Produto = True And v_Grupo = True) Then
      v_Nroregra := C_exc.Nudrec;
      v_Nroex    := C_exc.Nudrer;
    
      If C_exc.Tipovalor = 'P' Then
        v_Valor := (C_exc.Vlrmeta / 100);
      Elsif C_exc.Tipovalor = 'V' Then
        v_Valor := C_exc.Vlrmeta;
      Elsif C_exc.Tipovalor = 'F' Then
        stmt := 'Select ' || C_exc.Formula || ' from ad_basedre where nunota = ' || p_Nunota || ' and sequencia = ' ||
                p_Sequencia;
        Dbms_output.Put_line(stmt);
      
        Execute Immediate stmt
          Into v_Valor;
      
      End If;
    
      Exit;
    End If;
  
  End Loop;

  If v_Valor = 0 Then
    v_Valor := 1;
  End If;

  Dbms_output.Put_line(Nvl(v_Valor, 1));

Exception
  When No_data_found Then
    v_Valor := 0;
    Dbms_output.Put_line(v_Valor);
  When Too_many_rows Then
    v_Valor := 0;
    Dbms_output.Put_line(v_Valor);
End Get_vlrmeta;
3
nunota
1
25224700
3
seq
1
1
3
codmeta
1
102002
3
0
