Create Or Replace Trigger AD_TRG_CIUD_TCSAMZ_SF
  For Insert Or Update Or Delete On ad_tcsamz
  Compound Trigger

  v_numcontrato Number;
  i             Int := 0;

  /*
  * Autor: M.Rangel
  * Processo: Matéria Prima
  * Objetivo: Atualizar os dados no contrato
  */

  Before Each Row Is
  Begin
  
    If :new.Numcontrato Is Null Then
      stp_keygen_tgfnum('TCSCON', 1, 'TCSCON', 'NUMCONTRATO', 0, v_numcontrato);
    
      :new.Numcontrato := v_numcontrato;
    
    End If;
  
    If updating('NUNOTA') Then
      Begin
        Select cab.numcontrato
          Into v_numcontrato
          From tgfcab cab
         Where cab.nunota = :NEW.Nunota;
      
        :new.Numcontratocpa := v_numcontrato;
      
      Exception
        When Others Then
          Null;
      End;
    End If;
  
  End Before Each Row;

  After Each Row Is
  Begin
  
    If Variaveis_Pkg.v_atualizando Then
      Goto FinalDaTrigger;
    End If;
  
    Select Count(*)
      Into i
      From tgfcab
     Where numcontrato = Nvl(:old.Numcontrato, :new.Numcontrato)
       And numcontrato > 0;
  
    If inserting Then
    
      Begin
      
        Insert Into tcscon
          (numcontrato, dtcontrato, codcontato, codemp, codparc, codnat, codmoeda, codcencus, ativo, codtdc, tipoarm,
           codsaf, codusu, dtbasereaj, recdesp, codgpc, ad_objcontrato, nunota)
        Values
          (v_numcontrato, :new.dtcontrato, 0, :new.codemp, :new.codparc, :new.codnat, :new.codmoeda, :new.codcencus,
           :new.ativo, :new.codtdc, :new.tipoarm, :new.codsaf, stp_get_codusulogado, :new.dtcontrato, 0, :new.codgpc,
           'Armazem', :new.Nunota);
      
        Insert Into tcspsc
          (numcontrato, codprod, numusuarios, kitservicos, tipcobkit, respquebratec, respkitserv, resparmaz,
           unidconversao, qtdisencao, tipoarea, areatotal, areaplant, qtdeprevista, dtinicioisencao, dtfimisencao)
        Values
          (:new.numcontrato, :new.codprod, 1, :new.Kitservicos, :new.tipcobkit, :new.respquebratec, :new.respkitserv,
           :new.resparmaz, :new.unidconversao, :new.qtdisencao, Nvl(:new.tipoarea, 'P'), :new.areatotal, :new.areaplant,
           :new.qtdprevista, :new.dtinicioisencao, :new.dtfimisencao);
      
        Insert Into tcspre
          (numcontrato, codprod, referencia, valor, codserv)
        Values
          (v_numcontrato, :new.codprod, :new.dtcontrato, :new.valor, :new.codserv);
      Exception
        When Others Then
          Raise;
      End;
    
    Elsif updating Then
    
      variaveis_pkg.v_atualizando := True;
    
      Begin
      
        Update tcscon
           Set dtcontrato = :new.dtcontrato,
               codemp     = :new.Codemp,
               codparc    = :new.Codparc,
               codnat     = :new.Codnat,
               codmoeda   = :new.Codmoeda,
               codcencus  = :new.Codcencus,
               ativo      = :new.Ativo,
               codtdc     = :new.Codtdc,
               tipoarm    = :new.Tipoarm,
               codsaf     = :new.Codsaf,
               codusu     = :new.Codusu,
               codgpc     = :new.Codgpc,
               codproj    = :new.Codproj,
               nunota     = :new.Nunota,
               codempresp = :new.Codempresp
         Where numcontrato = :new.Numcontrato;
      
        Update tcspsc
           Set codprod         = :new.Codprod,
               tipcobkit       = :new.Tipcobkit,
               respquebratec   = :new.Respquebratec,
               respkitserv     = :new.Respkitserv,
               resparmaz       = :new.Resparmaz,
               unidconversao   = :new.Unidconversao,
               qtdisencao      = :new.Qtdisencao,
               tipoarea        = Nvl(:new.Tipoarea, 'P'),
               areatotal       = :new.Areatotal,
               areaplant       = :new.Areaplant,
               qtdeprevista    = :new.Qtdprevista,
               dtinicioisencao = :new.Dtinicioisencao,
               dtfimisencao    = :new.Dtfimisencao
         Where numcontrato = :new.Numcontrato
           And codprod = :new.Codprod;
      
        Dbms_Output.Put_Line(:new.Qtdprevista);
      
        Update tcspre
           Set codprod    = :new.Codprod,
               referencia = :new.Dtcontrato,
               valor      = :new.Valor,
               codserv    = :new.Codserv
         Where numcontrato = :new.Numcontrato
           And codprod = :new.Codprod
           And codserv = :new.Codserv;
      
        variaveis_pkg.V_ATUALIZANDO := False;
      
      Exception
        When Others Then
          Raise;
      End;
    
    Else
    
      If i > 0 Then
        Raise_Application_Error(-20105, 'Contrato possui lançamentos, não pode ser excluído!');
      Else
        ad_pkg_sst.exclui_contrato(:old.Numcontrato);
      End If;
    
    End If;
    <<FinalDaTrigger>>
    Null;
  End After Each Row;

End AD_TRG_CIUD_TCSAMZ_SF;
/
