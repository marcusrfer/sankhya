Create Or Replace Trigger AD_TRG_AIUD_TSFSSTM_SF
  After Insert Or Update Or Delete On ad_tsfsstm
  For Each Row
  Disable

Begin
  /*
  Rotina: Solicitação de Serviços de Transporte
  Dt Criação: 09/11/2016
  Autor: Marcus Rangel
  Objetivo: Atualizar o valor total do serviço com a soma dos valores das maquinas.
  
  desabilitada dia 15/05/2017 por Marcus Rangel, a mesma foi substituida pela trigger AD_TRG_CMP_TSFSSTM_SF
  */
  If inserting Then
    Update ad_tsfssti i
       Set qtdneg       = Nvl(i.qtdneg, 0) + :new.Qtdneg,
           i.vlrtot     = Nvl(i.vlrtot, 0) + :new.Vlrtot,
           i.vlrunit    = Nvl(i.vlrunit, 0) + fc_divide(:new.Vlrtot, :new.Qtdneg),
           i.automatico = 'S'
     Where i.codsolst = :New.Codsolst
       And i.codserv = :new.Codserv;
  End If;

  If updating('VLRUNIT') Or updating('QTDNEG') Or updating('VLRTOT') Then
  
    Update ad_tsfssti i
       Set i.qtdneg     = i.qtdneg - :old.Qtdneg,
           i.vlrunit    = i.vlrunit - :old.Vlrunit,
           i.vlrtot     = i.vlrtot - :old.Vlrtot,
           i.automatico = 'S'
     Where i.codsolst = :old.Codsolst
       And i.codserv = :old.Codserv;
  
    Update ad_tsfssti i
       Set i.qtdneg     = i.qtdneg + :new.Qtdneg,
           i.vlrunit    = i.vlrunit + :new.Vlrunit,
           i.vlrtot     = i.vlrtot + :new.Vlrtot,
           i.automatico = 'S'
     Where i.codsolst = :New.Codsolst
       And i.codserv = :new.Codserv;
  
  End If;

  If deleting Then
    Update ad_tsfssti i
       Set i.qtdneg     = i.qtdneg - :old.Qtdneg,
           i.vlrunit    = i.vlrunit - :old.Vlrunit,
           i.vlrtot     = i.vlrtot - :old.Vlrtot,
           i.automatico = 'S'
     Where i.codsolst = :old.Codsolst
       And i.codserv = :old.Codserv;
  End If;

Exception
  When Others Then
  
    ad_set.insere_msglog('Erro ao atualizar valor unitário do item ' || Nvl(:old.Codserv, :new.Codserv) ||
                         'solicitação nro ' || Nvl(:old.Codsolst, :new.Codsolst) || ' ' || ad_get.nomemaquina);
End;
/
