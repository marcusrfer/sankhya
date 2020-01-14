Create Or Replace Trigger AD_TRG_CMP_TSFRKMC_SF
  For Insert Or Update Or Delete On ad_tsfrkmc
  Compound Trigger

  /* 
  * Autor: M. Rangel
  * Processo: Reembolso de KM
  * Objetivo: Controle de alterações
  */

  errmsg Varchar2(4000);

  Before Each Row Is
    i Int;
  Begin
  
    If inserting Then
      ad_stp_valida_natcrproj_sf(p_codemp => :new.Codemp, p_Codtipoper => Null,
                                 p_codnat => :new.Codnat, p_codcencus => :new.Codcencus,
                                 p_codproj => :new.Codproj, p_tipoSaida => 0, p_errmsg => errmsg);
    
      If errmsg Is Not Null Then
        Raise_Application_Error(-20105, ad_fnc_formataerro(errmsg));
      End If;
    End If;
  
    If updating Then
    
      If stp_get_atualizando Then
        Goto fim_update;
      End If;
    
      -- se já confirmado
      If (:old.Status = 'C' And :new.Status = 'C') Then
        errmsg := 'Lançamentos confirmados não podem ser alterados!';
        Raise_Application_Error(-20105, ad_fnc_formataerro(errmsg));
      End If;
    
      If :new.Status = :old.Status And :new.status != 'P' And Not stp_get_atualizando Then
        errmsg := 'Lançamentos com status ' ||
                  ad_get.Opcoescampo(:old.status, 'STATUS', 'AD_TSFRKMC') ||
                  ' não podem ser alterados!';
        Raise_Application_Error(-20105, ad_fnc_formataerro(errmsg));
      End If;
    
      If updating('CODCENCUS') Or updating('CODPROJ') Or updating('CODNAT') Then
      
        ad_stp_valida_natcrproj_sf(p_codemp => :new.Codemp, p_Codtipoper => Null,
                                   p_codnat => :new.Codnat, p_codcencus => :new.Codcencus,
                                   p_codproj => :new.Codproj, p_tipoSaida => 0, p_errmsg => errmsg);
      
        If errmsg Is Not Null Then
          Raise_Application_Error(-20105, ad_fnc_formataerro(errmsg));
        End If;
      
        -- se alterando CR, verifica se há liberações 
        If (:old.Codcencus <> :new.Codcencus) Then
        
          --existe lib
          Select Count(*)
            Into i
            From tsilib
           Where tabela = 'AD_TSFRKMC'
             And nuchave = :new.Nureemb
             And dhlib Is Not Null;
        
          If i > 0 Then
            /*
            TODO: owner="M.Rangel" category="Finish" priority="1 - High" created="23/10/2018"
            text="Criar rotina de desfazimento da solicitaçãa de liberação do reembolso de km"
            */
            errmsg := 'Já existem liberações para esse reembolso, utilize a opção de desfazer a liberação para que possa substituir o CR.';
            Raise_Application_Error(-20105, ad_fnc_formataerro(errmsg));
          Else
            Begin
              Delete From tsilib
               Where tabela = 'AD_TSFRKMC'
                 And nuchave = :new.Nureemb
                 And dhlib Is Not Null;
            Exception
              When Others Then
                errmsg := 'Erro ao excluir solicitação de liberação na mudança de CR - ' || Sqlerrm;
                Raise_Application_Error(-20105, ad_fnc_formataerro(errmsg));
            End;
          End If;
        
        End If;
      
      End If;
    
      -- se atualizando o NUFIN
      If :old.Nufin Is Not Null And :new.nufin Is Null And :new.Status = 'PLT' Then
        Null;
      End If;
    
      <<fim_update>>
      Null;
    End If; -- fim update
  
    If deleting Then
      Null;
    End If;
  
  End Before Each Row;

End;
/
