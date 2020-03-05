Create Or Replace Procedure "AD_STP_FMP_CANCSUBST_SF"(p_codusu    Number,
                                                      p_idsessao  Varchar2,
                                                      p_qtdlinhas Number,
                                                      p_mensagem  Out Varchar2) As
  c          ad_contcargto%Rowtype;
  v_confirma Varchar2(1);
  v_motivo   Varchar2(256);
  v_newOrdem Number;
Begin
  /* 
  Autor: M. Rangel
  Processo: Frete Matéria Prima
  Objetivo: Realizar o cancelamento e a inserção automática de nova programação de carregamento
  */

  If p_qtdlinhas > 1 Then
    p_mensagem := 'Selecione apenas uma ordem para cancelamento/substituição!';
    Return;
  End If;

  c.sequencia := act_int_field(p_idsessao, 1, 'SEQUENCIA');
  v_motivo    := act_txt_param(p_idsessao, 'MOTIVO');

  If Length(v_motivo) < 20 Then
    p_mensagem := 'Motivo informado não possui informações suficientes!';
    Return;
  End If;

  v_confirma := act_escolher_simnao('Substituição de Ordem de Carregamento',
                                    'A ordem atual será cancelada e será gerada outra Ordem para nova programação. <br>Confirma o cancelamento da ordem de carregamento?',
                                    p_idsessao, 1);

  If v_confirma = 'S' Then
  
    -- get dados do registro
    Begin
      Select *
        Into c
        From ad_contcargto
       Where sequencia = c.sequencia;
    Exception
      When Others Then
        p_mensagem := 'Erro ao buscar os dados da ordem de carregamento.' || Chr(13) || Sqlerrm;
        Return;
    End;
  
    -- validações
    If c.status != 'ABERTO' Then
      p_mensagem := 'Somente carregamentos abertos podem ser substituídos!';
      Return;
    Elsif c.statusvei Not In ('P', 'T', Null) Then
      p_mensagem := 'Somente carregamentos "Aguardando Programação",' ||
                    ' "Programado" e "em Trânsito" podem ser substituídos.';
      Return;
    End If;
  
    -- cancela ordem atual
    Begin
      Update ad_contcargto
         Set status = 'CANCELADO',
             obs    = obs || Chr(13) || 'Cancelada em ' || To_Char(Sysdate, 'dd/mm/yyyy hh24:mi:ss') ||
                      ' por ' || ad_get.nomeusu(p_codusu, 'resumido') || ', devido à ' || v_motivo
       Where sequencia = c.sequencia;
    Exception
      When Others Then
        p_mensagem := fc_formatahtml('Erro ao cancelar Ordem atual', Sqlerrm, Null);
        Return;
    End;
  
    -- gera nova ordem
    ---- insere produto
    Begin
    
      stp_keygen_tgfnum('AD_CONTCARGTO', c.codemp, 'AD_CONTCARGTO', 'SEQUENCIA', 0, v_newOrdem);
      c.obs := c.obs || Chr(13) || 'Ordem substituta da Ordem nº ' || c.sequencia ||
               ', criada por ' || ad_get.Nomeusu(p_codusu, 'resumido') || ' em ' ||
               To_Char(Sysdate, 'dd/mm/yyyy hh24:mi:ss') || ' devido ' || v_motivo;
    
      Insert Into ad_contcargto
        (sequencia, obs, status, codusu, codemp, datahoralanc, dtaprevcarg, podeabastecer,
         lib_descarregar, tipomov, statusvei, analise_avulsa, codveiculo)
      Values
        (v_newOrdem, c.obs, 'AP', p_codusu, c.codemp, Sysdate, c.dtaprevcarg, 'N', 'NÃO', 'ENTRADA',
         Null, 'N', 0);
    
    Exception
      When Others Then
        p_mensagem := fc_formatahtml('Erro ao criar nova ordem de carregamento', Sqlerrm, Null);
        Return;
    End;
  
    For i In (Select *
                From ad_itecargto
               Where sequencia = c.sequencia
               Order By ordem)
    Loop
      Begin
        Insert Into ad_itecargto
          (sequencia, ordem, codprod, qtde, numnota, codparc, codusu, dataalt, seqcorteprod,
           umidade, cancelado, vlrfrete, vlrcte, coddest, nfe_ssa, nunota, nunotaorig, chavenfe)
        Values
          (v_newOrdem, ad_seq_session.nextval, i.codprod, i.qtde, i.numnota, i.codparc, p_codusu,
           Sysdate, i.seqcorteprod, i.umidade, i.cancelado, 0, 0, i.coddest, i.nfe_ssa, i.nunota,
           i.nunotaorig, i.chavenfe);
      Exception
        When Others Then
          p_mensagem := fc_formatahtml('Erro ao criar itens da ordem de carregamento', Sqlerrm, Null);
          Return;
      End;
    End Loop;
  
    Begin
      Update ad_tcsamp a
         Set a.nuagend = v_newOrdem
       Where a.nuagend = c.sequencia;
    Exception
      When no_data_found Then
        Null;
      When Others Then
        p_mensagem := fc_formatahtml('Erro ao atualizar agendamento de origem', Sqlerrm, Null);
        Return;
    End;
  
  End If;

  p_mensagem := 'Substituição concluída com sucesso! <br> Gerada a Ordem nº ' ||
                '<a title="Visualizar lançamento" target="_parent" href="' ||
                ad_fnc_urlskw('AD_CONTCARGTO', v_newOrdem) || '"><font color="#0000FF">' ||
                v_newOrdem || '</font></a>';

End;
/
