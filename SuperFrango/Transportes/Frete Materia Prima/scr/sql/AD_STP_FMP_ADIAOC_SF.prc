Create Or Replace Procedure "AD_STP_FMP_ADIAOC_SF"(p_codusu    Number,
                                                   p_idsessao  Varchar2,
                                                   p_qtdlinhas Number,
                                                   p_mensagem  Out Varchar2) As
  v_newdtval Date;
  v_motivo   Varchar2(256);
  c          ad_contcargto%Rowtype;
Begin

  /* 
  Autor: M. Rangel
  Processo: Log�stica Mat�ria Prima
  Objetivo: Realizar o adiamento da data de vencimento e atualizar a obs da ordem.
  */

  v_newdtval := act_dta_param(p_idsessao, 'NEWDTVAL');
  v_motivo   := act_txt_param(p_idsessao, 'MOTIVO');

  For i In 1 .. p_qtdlinhas
  Loop
    c.sequencia := act_int_field(p_idsessao, i, 'SEQUENCIA');
  
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
  
    -- valida��es
    If c.status != 'ABERTO' Then
      p_mensagem := 'Somente carregamentos abertos podem alterar a data de validade!';
      Return;
    Elsif c.statusvei Not In ('P', 'T', Null) Then
      p_mensagem := 'Somente carregamentos "Aguardando Programa��o",' ||
                    ' "Programado" e "em Tr�nsito" podem alterar a data de validade da ordem';
      Return;
    End If;
  
    -- altera a data de validade
    Begin
      Update ad_contcargto
         Set dtvalidade = v_newdtval,
             obs        = obs || Chr(13) || 'Vencimento alterado para ' ||
                          To_Char(v_newdtval, 'DD/MM/YYYY') || ', devido ' || v_motivo ||
                          ', registrado por ' || ad_get.Nomeusu(p_codusu, 'resumido')
       Where sequencia = c.sequencia;
    Exception
      When Others Then
        p_mensagem := 'Erro ao atualizar a data de validade da Ordem.' || Chr(13) || Sqlerrm;
        Return;
    End;
  
  End Loop;

  p_mensagem := 'Altera��o realizada com sucesso!!!';

End;
/
