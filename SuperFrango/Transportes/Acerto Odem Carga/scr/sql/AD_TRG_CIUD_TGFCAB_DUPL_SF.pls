Create Or Replace Trigger AD_TRG_CIUD_TGFCAB_DUPL_SF
  For Insert Or Update On tgfcab
  Compound Trigger

  v_ChaveCte Varchar2(44);
  v_Nunota   Number;
  v_Dtneg    Date;

  /*
  * Autor: M. Rangel
  * Dt. Criação: 15/01/2018
  * Objetivo: Impedir que notas de compras com a chave CTE repetidas sejam lançadas
  */

  Before Each Row Is
  
  Begin
  
    If (inserting Or updating('CHAVECTE')) And :new.Tipmov = 'C' And :New.Chavecte Is Not Null Then
      v_chavecte := :new.Chavecte;
      v_Nunota   := :new.Nunota;
      v_Dtneg    := :new.Dtneg;
    End If;
  
  End Before Each Row;

  After Statement Is
    v_Count Int := 0;
  Begin
  
    If v_chavecte Is Not Null Then
    
      Select Count(*)
        Into v_count
        From tgfcab c
       Where c.tipmov = 'C'
         And c.chavecte Is Not Null
         And c.chavecte = v_chavecte
         And c.nunota <> v_Nunota
         And c.dtneg Between add_months(v_dtneg, -3) And add_months(v_Dtneg, 3);
    
      If v_count > 0 Then
        Raise_Application_Error(-20105,
                                fc_formatahtml_sf(p_mensagem => 'Nota não pode ser inserida ou alterada.',
                                                  p_motivo   => 'Já existe outro lançamento com a mesma chave CTE',
                                                  p_solucao  => 'Verifique se não se trata de duplicidade (Chave do CTe, parceiro, valor, número, série e top)',
                                                  p_error    => ''));
      End If;
    End If;
  
  End After Statement;

End;
