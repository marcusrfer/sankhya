CREATE OR REPLACE Trigger ad_trg_cmp_tsfrkmr_sf
  For Insert Or Update Or Delete On ad_tsfrkmr
  Compound Trigger

  /* 
  * Autor: M. Rangel
  * Processo: Reembolso de KM
  * Objetivo: Controle de alterações
  */

  v_NuReemb Number;

  Before Each Row Is
  Begin
    v_NuReemb := Nvl(:new.Nureemb, :old.Nureemb);
  
    Update ad_tsfrkmc
       Set dhalter = Sysdate
     Where nureemb = v_NuReemb;
  End Before Each Row;

End;
/
