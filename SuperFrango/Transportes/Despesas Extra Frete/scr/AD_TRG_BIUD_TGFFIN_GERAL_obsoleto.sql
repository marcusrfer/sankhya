Create Or Replace Trigger AD_TRG_BIUD_TGFFIN_GERAL
  Before Insert Or Update Or Delete On TGFFIN
  For Each Row
Declare
  i        Int := 0;
  v_Nunota Number;
  r_cab    tgfcab%Rowtype;
  /*
  Autor: Marcus Rangel
  Objetivo: Aqui deverão estar contidas todas as regras adicionais relacionadas a inclusão, alteração, exclusão, regras de validação que envolvam a TGFFIN
  */
Begin

  If INSERTING Then
    /* Quando o sistema refaz o financeiro e usa o CR do usuário ao invés do cabeçalho do pedido */
    If :new.origem = 'E' Then
      Select * Into r_cab From tgfcab Where nunota = :new.nunota;
    
      If :new.Codcencus <> r_cab.codcencus And r_cab.codcencus <> 0 Then
        :new.Codcencus := r_cab.codcencus;
      End If;
    
    End If;
  
  End If;

  If updating Then
    Null;
  End If;

  If deleting Then
    /*  Objetivo: desfazer a ligação entre os portais e as telas adicionais personalizadas.  */
  
    Select Count(*)
      Into i
      From ad_tblcmf
     Where nuchavedest = :old.Nufin
        Or nuchaveorig = :old.Nufin;
  
    If i <> 0 Then
      Begin
        Delete From ad_tblcmf
         Where nuchavedest = :old.Nufin
            Or nuchaveorig = :old.Nufin;
      Exception
        When Others Then
          ad_set.insere_msglog('Erro ao desfazer ligação do NUFIN ' || :old.Nufin);
      End;
    End If;
  End If;

End;
/
