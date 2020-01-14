Create Or Replace Trigger AD_TRG_CMP_TSFRKMI_SF
  For Insert Or Update Or Delete On ad_tsfrkmi
  Compound Trigger

  /* 
  * Autor: M. Rangel
  * Processo: Reembolso de KM
  * Objetivo: Controle de alterações
  */

  v_nureemb  Number;
  v_nureemi  Number;
  v_kmini    Float;
  v_kmfin    Float;
  v_contrato Number;
  v_codprod  Number;

  Before Each Row Is
  Begin
  
    If inserting Or updating Then
    
      v_nureemb    := :new.Nureemb;
      v_nureemi    := :new.Nurkmi;
      v_kmini      := :new.Kminicial;
      v_kmfin      := :new.Kmfinal;
      :new.Totalkm := Nvl(:New.Kmfinal, 0) - Nvl(:new.Kminicial, 0);
    
      If :new.Totalkm > 0 Then
        Begin
          Select e.numcontratokm
            Into v_contrato
            From ad_tsfelt e
           Where e.nuelt = 1;
        
          Select codprod
            Into v_codprod
            From ad_tsfrkmc
           Where nureemb = :new.Nureemb;
        
          Select Count(*)
            Into ad_pkg_var.Count
            From tcspre p
           Where p.numcontrato = v_contrato
             And p.referencia < :new.Dtviagem;
        
          If ad_pkg_var.Count = 0 Then
            ad_pkg_var.ErrMsg := fc_formatahtml('Não existem preços cadastrados para esta data no contrato ' ||
                                                v_contrato,
                                                'Na data da viagem, não havia nenhum preço para o km',
                                                'Corrija a data da viagem ou insira um preço no contrato que seja anterior à data informada');
          
            Raise_Application_Error(-20105, ad_pkg_var.ErrMsg);
          
          End If;
        
          :new.Vlrtotal := ad_get.ultimo_valor_contrato(v_contrato, v_codprod, :new.Dtviagem) *
                           :new.Totalkm;
        
          Dbms_Output.Put_Line(v_contrato || ' | ' || v_codprod || ' | ' || :new.Dtviagem || ' | ' ||
                               :new.Totalkm);
        Exception
          When Others Then
            :new.Vlrtotal := 0;
        End;
      End If;
    
      Begin
        Update ad_tsfrkmc c
           Set c.dhalter = Sysdate
         Where c.nureemb = Nvl(:new.nureemb, :old.nureemb);
      Exception
        When Others Then
          Raise;
      End;
    
      If Nvl(:new.Dtviagem, Last_Day(:new.Dtviagem)) > Trunc(Sysdate) Then
        Raise_Application_Error(-20105,
                                ad_fnc_formataerro('Não é permitido o lançamento de datas futuras!'));
      End If;
    
      If :new.Kminicial = :new.Kmfinal Then
        Raise_Application_Error(-20105,
                                ad_fnc_formataerro('O Km inicial (' ||
                                                    ad_get.Formatanumero(:new.Kminicial) ||
                                                    ') é igual ao Km final (' ||
                                                    ad_GET.Formatanumero(:new.Kmfinal) || ')!'));
      Elsif :new.Kminicial <= 0 Then
        Raise_Application_Error(-20105,
                                ad_fnc_formataerro('O valor do Km Inicial não pode ser 0 ou menor que 0.'));
      Elsif :new.Kmfinal < :new.Kminicial Then
        Raise_Application_Error(-20105,
                                ad_fnc_formataerro('O valor do Km final não pode ser menor que o KM Inicial.'));
      End If;
    
    End If;
  
    If deleting Then
      Begin
        Update ad_tsfrkmc c
           Set c.dhalter = Sysdate
         Where nureemb = :old.Nureemb;
      Exception
        When Others Then
          Raise;
      End;
    End If;
  
  End Before Each Row;

  After Statement Is
    v_maxkm Float;
  Begin
    If v_kmini Is Not Null Then
    
      Begin
        Select kmfinal
          Into v_maxkm
          From ad_tsfrkmi
         Where nureemb = v_nureemb
           And nurkmi < v_nureemi
           And dtviagem = (Select Max(d2.dtviagem)
                             From ad_tsfrkmi d2
                            Where d2.nureemb = v_nureemb
                              And d2.nurkmi < v_nureemi)
         Order By nurkmi Desc Fetch First 1 Rows Only;
      Exception
        When no_data_found Then
          v_maxkm := 0;
      End;
    
      If v_kmini < v_maxkm /*Or v_kmfin < v_maxkm*/
       Then
        Raise_Application_Error(-20105,
                                ad_fnc_formataerro('Divergência na quilometragem! O Km inicial é menor que o Km final da última data de viagem válida'));
      End If;
    
    End If;
  
  End After Statement;

End;
/
