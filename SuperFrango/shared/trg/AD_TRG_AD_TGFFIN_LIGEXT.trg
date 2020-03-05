Create Or Replace Trigger AD_TRG_AD_TGFFIN_LIGEXT
  After Delete On TGFFIN
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
End;
/
