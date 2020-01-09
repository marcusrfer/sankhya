Create Or Replace Trigger AD_TRG_CMP_TSFHQF_SF
  For Insert Or Update Or Delete On ad_tsfhqf
  Compound Trigger

  Type ty_tab_setor Is Table Of ad_tsfhqf%Rowtype;
  q         ty_tab_setor := ty_tab_setor();
  i         Int;
  analitico Boolean Default False;

  Before Statement Is
  Begin
    q.delete;
  End Before Statement;

  Before Each Row Is
  Begin
  
    If inserting Then
    
      -- tratativa para preenchimento automatico da empresa e da meta buscando do pai
      If Nvl(:new.Analitico, 'N') = 'S' Then
        analitico := True;
      
        q.extend;
        i := q.last;
      
        q(i).nuhqf := :new.nuhqf;
        q(i).grau := :new.grau;
        q(i).analitico := :new.analitico;
        q(i).nuhqfpai := :new.nuhqfpai;
        q(i).descrsetarea := :new.descrsetarea;
        q(i).codemp := :new.codemp;
        q(i).ativo := :new.ativo;
        q(i).numet := :new.numet;
      
      End If;
      ------------------------------
    
    End If;
  
  End Before Each Row;

  After Statement Is
  Begin
    -- tratativa para preenchimento automatico da empresa e da meta buscando do pai
    If analitico Then
      For l In q.first .. q.last
      Loop
        For x In (Select f.Codemp, f.Numet From ad_tsfhqf f Where f.Nuhqf = q(l).nuhqfpai)
        Loop
          Begin
            Update ad_tsfhqf
               Set codemp = x.Codemp,
                   numet  = x.Numet,
                   ativo  = 'S'
             Where nuhqf = q(l).nuhqf;
          Exception
            When Others Then
              raise_application_error(-20105,
                                      ad_fnc_formataerro('Erro ao atualizar os valores de empresa e meta. ' || Sqlerrm));
          End;
        End Loop;
      End Loop;
    End If;
    --------------------------------------
  
  End After Statement;

End AD_TRG_CMP_TSFHQF_SF;
/
