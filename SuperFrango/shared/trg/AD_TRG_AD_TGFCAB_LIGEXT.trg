Create Or Replace Trigger AD_TRG_AD_TGFCAB_LIGEXT
  After Delete On tgfcab
  For Each Row
Declare
  i Int := 0;
Begin
  /*
  Autor: Marcus Rangel
  Objetivo: desfazer a ligação entre os portais e as telas adicionais personalizadas.
  */

  Select Count(*)
    Into i
    From ad_tblcmf
   Where nuchavedest = :old.Nunota
      Or nuchaveorig = :old.Nunota;

  If i <> 0 Then
    Begin
      Delete From ad_tblcmf
       Where nuchavedest = :old.Nunota
          Or nuchaveorig = :old.Nunota;
    Exception
      When Others Then
        ad_set.insere_msglog('Erro ao desfazer ligação do NUNOTA ' || :old.nunota);
    End;
  End If;
End;
/
