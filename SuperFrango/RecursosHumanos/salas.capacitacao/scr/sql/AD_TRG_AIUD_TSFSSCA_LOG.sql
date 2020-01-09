CREATE OR REPLACE Trigger AD_TRG_AIUD_TSFSSCA_LOG
   After Insert Or Update Or Delete On ad_tsfssca
   For Each Row
Declare
   v_nuseq Number;
   v_codusu tsiusu.codusu%Type;
Begin
   Select Nvl(Max(nuseq), 0) + 1 Into v_nuseq From ad_tsfssca_log;
   v_codusu := stp_get_codusulogado;

   If inserting Then
      Insert Into ad_tsfssca_log
         (nuseq, dhalter, operacao, codusu, nomeusu, maquina, nussca, nussc, codususol, codusulib, dtsol, dtreserva,
          hrini, hrfin, codsala, motivo, status, dhaprovneg)
      Values
         (v_nuseq, Sysdate, 'Insert', v_codusu, ad_get.Nomeusu(v_codusu, 'resumido'), ad_get.Nomemaquina, :new.Nussca,
          :new.Nussc, :new.Codususol, :new.Codusulib, :new.Dtsol, :new.Dtreserva, :new.Hrini, :new.Hrfin, :new.Codsala,
          :new.Motivo, :new.Status, :new.Dhaprovneg);
   Elsif updating Then
      Insert Into ad_tsfssca_log
         (nuseq, dhalter, operacao, codusu, nomeusu, maquina, nussca, nussc, codususol, codusulib, dtsol, dtreserva,
          hrini, hrfin, codsala, motivo, status, dhaprovneg)
      Values
         (v_nuseq, Sysdate, 'Update - New Values', v_codusu, ad_get.Nomeusu(v_codusu, 'resumido'), ad_get.Nomemaquina,
          :new.Nussca, :new.Nussc, :new.Codususol, :new.Codusulib, :new.Dtsol, :new.Dtreserva, :new.Hrini, :new.Hrfin,
          :new.Codsala, :new.Motivo, :new.Status, :new.Dhaprovneg);
   
      Insert Into ad_tsfssca_log
         (nuseq, dhalter, operacao, codusu, nomeusu, maquina, nussca, nussc, codususol, codusulib, dtsol, dtreserva,
          hrini, hrfin, codsala, motivo, status, dhaprovneg)
      Values
         (v_nuseq, Sysdate, 'Update - Old Values', v_codusu, ad_get.Nomeusu(v_codusu, 'resumido'), ad_get.Nomemaquina,
          :old.Nussca, :old.Nussc, :old.Codususol, :old.Codusulib, :old.Dtsol, :old.Dtreserva, :old.Hrini, :old.Hrfin,
          :old.Codsala, :old.Motivo, :old.Status, :old.Dhaprovneg);
   Elsif deleting Then
      Insert Into ad_tsfssca_log
         (nuseq, dhalter, operacao, codusu, nomeusu, maquina, nussca, nussc, codususol, codusulib, dtsol, dtreserva,
          hrini, hrfin, codsala, motivo, status, dhaprovneg)
      Values
         (v_nuseq, Sysdate, 'Delete', v_codusu, ad_get.Nomeusu(v_codusu, 'resumido'), ad_get.Nomemaquina, :old.Nussca,
          :old.Nussc, :old.Codususol, :old.Codusulib, :old.Dtsol, :old.Dtreserva, :old.Hrini, :old.Hrfin, :old.Codsala,
          :old.Motivo, :old.Status, :old.Dhaprovneg);
   End If;
End;
/
