Create Or Replace Trigger AD_TRG_CIUD_TGFORD_SF
  For Insert Or Update Or Delete On TGFORD
  Compound Trigger

  /*
  Autor: M. Rangel
  Processo: Sequencia de entrega pela distancia
  Objetivo: atualizar no sequenciamento, possíveis mudanças na oc
  */

  Before Each Row Is
    i Int;
  Begin
  
    If updating And ad_pkg_var.atualizando_tgfroc = False Then
    
      ad_pkg_var.atualizando_tgford := True;
    
      Select Count(*)
        Into i
        From ad_tsfrocc r
       Where r.codemp = :new.Codemp
         And r.ordemcarga = :New.Ordemcarga;
    
      If i > 0 Then
      
        If updating('CODVEICULO') Or updating('CODPARCTRANSP') Or updating('CODPARCORIG') Or
           updating('AD_LIBERADO') Then
        
          Update ad_tsfrocc
             Set codveiculo    = :new.Codveiculo,
                 codparctransp = :new.Codparctransp,
                 codparcorig   = :new.Codparcorig,
                 liberado      = :new.Ad_Liberado
           Where codemp = :new.Codemp
             And ordemcarga = :new.Ordemcarga;
        
        End If;
      
      End If;
    
    End If;
  
  Exception
    When Others Then
      Raise;
      /*      Raise_Application_Error(-20105,
      fc_formatahtml(Sqlerrm,
                      'Erro ao atualizar sequencia de entrega para esta OC',
                      'Verifique os detalhes do veículo, se estão cadastrados corretamente.'));*/
  End Before Each Row;

End;
/
