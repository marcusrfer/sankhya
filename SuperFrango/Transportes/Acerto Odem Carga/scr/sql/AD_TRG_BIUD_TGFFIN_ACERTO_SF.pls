Create Or Replace Trigger AD_TRG_BIUD_TGFFIN_ACERTO_SF
  Before Insert Or Update Or Delete On Tgffin
  For Each Row
Declare
  v_Aprovacerto Char(1);
  --v_Libpend     Int := 0;
  --v_Nomelib     Varchar2(40);
Begin
  /*
  Autor: Marcus Rangel
  Dt. Criação: 31/08/2016
  Objetivo: Atender o processo de autorização de pagamento de acerto
  */

  /* Verifica se é do processo de acerto */
  Select Nvl(t.Ad_Aprovbaixaacerto, 'N')
    Into v_Aprovacerto
    From Tgftop t
   Where t.Codtipoper = Nvl(:New.Codtipoper, :Old.Codtipoper)
     And t.Dhalter = Nvl(:New.Dhtipoper, :Old.Dhtipoper);
  /* se não for, sai*/
  If v_Aprovacerto <> 'S' Then
    Return;
  End If;

  /* Marca o lançamento como provisão*/
  If Inserting Then
    If :New.Recdesp = -1 And :New.Provisao = 'N' And :New.Dhbaixa Is Null And
       :New.Codctabcoint Is Null Then
      :New.Provisao  := 'S';
      :New.Codtiptit := 8;
    End If;
  End If;

  If Updating Then
    /* tratativa para atender  a rotina de acerto */
    If :New.Dhbaixa Is Not Null Or (:Old.Codtipoper <> :New.Codtipoper) Then
      :New.Provisao := 'N';
      If Nvl(:New.Codtiptit, 0) = 0 Then
        :New.Codtiptit := 8;
      End If;
    
    End If;
  
    -- Ricardo 14/11/2017 - descomentei esse trecho por conta do teste de lan�amento NUFIN 21475368, fazendo o Select para buscar v_Libpend funcinou,
    -- notar que nesse momento a linha 224 da Ad_Trg_Aiud_Tsilib_Sf estava comentada      
    /*SELECT COUNT(*)
      INTO v_Libpend
      FROM Tsilib l
     WHERE l.Nuchave = :New.Nufin
       AND Dhlib IS NULL;
    \* inibe mudança do campo se houver lib pendnete *\
    IF Updating('PROVISAO') AND v_Libpend <> 0 THEN
          SELECT Nomeusu
            INTO v_Nomelib
            FROM Tsiusu u,
                 Tsilib l
           WHERE u.Codusu = l.Codusulib
             AND Nuchave = :New.Nufin;
    
          Raise_Application_Error(-20105, Ad_Fnc_Formataerro('Lan�amento aguardando libera��o de: ' ||
                                                      v_Nomelib));
    END IF;*/
  
  End If;

End;
/
