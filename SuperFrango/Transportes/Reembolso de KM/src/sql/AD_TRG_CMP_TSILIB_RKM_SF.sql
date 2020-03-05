Create Or Replace Trigger AD_TRG_CMP_TSILIB_RKM_SF
  For Delete Or Insert Or Update On SANKHYA.TSILIB
  Referencing New As New Old As Old
  Compound Trigger

  /* 
  * Autor: M. Rangel
  * Processo: Reembolso de KM
  * Objetivo: Processo de liberação dos reembolsos
  */

  l       tsilib%Rowtype;
  v_Nufin Number;

  Before Each Row Is
  Begin
  
    If updating Then
    
      l.evento    := :new.Evento;
      l.nuchave   := :new.Nuchave;
      l.reprovado := :new.Reprovado;
      l.codusulib := :new.Codusulib;
    
      If (:new.dhlib Is Not Null And :old.Dhlib Is Null) Then
      
        If Nvl(l.reprovado, 'N') = 'N' Then
        
          If (:new.tabela = 'AD_TSFRKMC' And :new.Evento = 1048) Then
            Begin
              Select nufin
                Into v_nufin
                From ad_tsfrkmc
               Where nureemb = :new.Nuchave;
            Exception
              When Others Then
                Raise;
            End;
          Elsif :new.Tabela = 'TGFFIN' Then
            Begin
              Select nufin
                Into v_nufin
                From ad_tsfrkmc
               Where nufin = :new.Nuchave;
            Exception
              When no_data_found Then
                Goto fim_After_Each_Row;
            End;
          Else
            Goto fim_After_Each_Row;
          End If;
        Else
          -- reprovado
          l.reprovado := 'S';
        End If;
      End If;
    
    End If;
  
    <<fim_After_Each_Row>>
    Null;
  End Before Each Row;

  After Statement Is
    i Int;
  Begin
    If v_nufin Is Not Null And l.reprovado = 'N' Then
    
      If l.evento = 1048 Then
        Begin
        
          -- conta quantas libs pendentes
          Select Count(*)
            Into i
            From tsilib lib
           Where lib.tabela = 'AD_TSFRKMC'
             And lib.nuchave = l.nuchave
             And lib.codusulib != l.codusulib
             And lib.dhlib Is Null;
        
          -- se todas liberadas, altera o fin para provisão
          If i = 0 Then
            Update tgffin
               Set recdesp  = -1,
                   provisao = 'S',
                   --dtvenc   = ad_get.Datavencimento(dtvenc, 'S')
                   dtvenc = ad_get.Dia_Util_Ultimo(Trunc(Sysdate) + 4, 'P')
            --dtvenc   = dtvenc + 4
             Where nufin = v_nufin
               And recdesp = 0;
          End If;
        Exception
          When Others Then
            Raise;
        End;
        -- se lib financeira, atualiza o status do reembolso
      Elsif l.evento = 1035 Then
        Begin
          Update ad_tsfrkmc
             Set status = 'C'
           Where nufin = v_nufin;
        Exception
          When Others Then
            Raise;
        End;
      End If;
    
    Elsif v_nufin Is Null And l.reprovado = 'S' Then
    
      Begin
        Update ad_tsfrkmc
           Set status = 'R'
         Where nureemb = l.nuchave;
      Exception
        When Others Then
          Raise;
      End;
    
    End If;
  End After Statement;

End;
/
