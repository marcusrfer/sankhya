Create Or Replace Package AD_PKG_ROC Is

  -- Author  : M.RANGEL
  -- Created : 03/07/2018 16:05:25
  -- Purpose :
  /*atualizando_tgford Boolean Default False;
  atualizando_tgfroc Boolean Default False;
  permite_update     Boolean Default False;*/

  Procedure zera_ordem_carga(p_numrocc Number,
                             p_numrocp Number);
  Procedure zera_ordem_carga(p_numrocc Number);

  Procedure zera_sequencia_ordcarga(p_numrocc Number,
                                    p_numrocp Number);
  Procedure zera_sequencia_ordcarga(p_numrocc Number);

  Procedure atualizar_ordcarga(p_numrocc Number,
                               p_numrocp Number);
  Procedure atualizar_ordcarga(p_numrocc Number);

  Procedure atualiza_dados_parceiros(p_numrocc Number);

  Procedure atualiza_dados(p_numrocc  Number,
                           p_mensagem Out Nocopy Varchar2);

End AD_PKG_ROC;
/
Create Or Replace Package Body AD_PKG_ROC Is

  --
  Procedure zera_ordem_carga(p_numrocc Number,
                             p_numrocp Number) Is
  Begin
    Update ad_tsfrocp
       Set ordemcarga = 0
     Where numrocc = p_numrocc
       And numrocp = p_numrocp;
  Exception
    When Others Then
      Raise;
  End;

  Procedure zera_ordem_carga(p_numrocc Number) Is
  Begin
    Update ad_tsfrocp
       Set ordemcarga = 0
     Where numrocc = p_numrocc;
  Exception
    When Others Then
      Raise;
  End;

  Procedure zera_sequencia_ordcarga(p_numrocc Number) Is
  Begin
    ad_pkg_var.permite_update := True;
  
    Update ad_tsfrocp
       Set sequencia = 0
     Where numrocc = p_numrocc;
  
    Update ad_tsfrocc c
       Set c.Distrota = 0,
           c.Vlrrota  = 0
     Where c.Numrocc = P_numrocc;
  
  Exception
    When Others Then
      Raise;
  End;

  Procedure zera_sequencia_ordcarga(p_numrocc Number,
                                    p_numrocp Number) Is
  Begin
    Update ad_tsfrocp
       Set sequencia = 0
     Where numrocc = p_numrocc
       And numrocp = p_numrocp;
  
    Update ad_tsfrocc c
       Set c.Distrota = Null,
           c.Vlrrota  = Null
     Where c.Numrocc = P_numrocc;
  
  Exception
    When Others Then
      Raise;
  End;

  Procedure atualizar_ordcarga(p_numrocc Number) Is
    v_Ordcarga Number;
  Begin
  
    Select ordemcarga
      Into v_Ordcarga
      From ad_tsfrocc
     Where numrocc = p_numrocc;
  
    Update ad_tsfrocp
       Set ordemcarga = v_Ordcarga
     Where numrocc = p_numrocc;
  
  Exception
    When Others Then
      Raise_Application_Error(-20105, 'Erro ao buscar o código da Ordem de Carga do cabeçalho');
  End;

  Procedure atualizar_ordcarga(p_numrocc Number,
                               p_numrocp Number) Is
    v_Ordcarga Number;
  Begin
  
    Select ordemcarga
      Into v_Ordcarga
      From ad_tsfrocc
     Where numrocc = p_numrocc;
  
    Update ad_tsfrocp
       Set ordemcarga = v_Ordcarga
     Where numrocc = p_numrocc
       And numrocp = p_numrocp;
  Exception
    When Others Then
      Raise;
  End;

  Procedure atualiza_dados_parceiros(p_numrocc Number) Is
    lat Varchar2(20);
    Lot Varchar2(20);
    reg Number;
  Begin
    For r In (
              
              Select Rowid,
                      p.numrocp,
                      p.codparc
                From ad_tsfrocp p
               Where p.numrocc = p_numrocc
              -- And (p.latitude Is Null Or p.longitude Is Null Or p.codregfre Is Null)
              
              )
    Loop
      Begin
        Select par.latitude,
               par.longitude,
               par.ad_codregfre
          Into lat,
               Lot,
               reg
          From tgfpar par
         Where par.codparc = r.codparc;
      Exception
        When Others Then
          Raise;
      End;
    
      Begin
        Update ad_tsfrocp p
           Set latitude  = lat,
               Longitude = lot,
               codregfre = reg
         Where Rowid = r.rowid
           And (Nvl(p.latitude, '0') != Nvl(lat, '0') Or Nvl(p.longitude, '0') != Nvl(lot, '0'));
      Exception
        When Others Then
          Raise;
      End;
    End Loop;
  End;

  Procedure atualiza_dados(p_numrocc  Number,
                           p_mensagem Out Nocopy Varchar2) Is
    r ad_tsfrocc%Rowtype;
    o tgford%Rowtype;
  Begin
  
    Select *
      Into r
      From ad_tsfrocc roc
     Where numrocc = p_numrocc;
  
    If r.status = 'C' Then
      p_mensagem := 'Sequenciamento de carga já sinalisado como "Concluído", não pode ser alterado.';
      Return;
    End If;
  
    Select *
      Into o
      From tgford ord
     Where codemp = r.codemp
       And ordemcarga = r.ordemcarga;
  
    Begin
      Update ad_tsfrocc rocc
         Set codveiculo        = o.codveiculo,
             codparcorig       = o.codparcorig,
             codparctransp     = o.codparctransp,
             rocc.codusu       = stp_get_codusulogado,
             rocc.dhalter      = Sysdate,
             rocc.dtinic       = o.dtinic,
             status            = 'P',
             rocc.libacertopen = o.ad_libacertopen,
             rocc.liberado     = o.ad_liberado
       Where numrocc = r.numrocc;
    Exception
      When Others Then
        atualiza_dados_parceiros(p_numrocc);
        Return;
    End;
  
    Begin
      atualiza_dados_parceiros(p_numrocc);
    End;
  
  End atualiza_dados;

End AD_PKG_ROC;
/
