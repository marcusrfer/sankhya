Create Or Replace
Procedure "AD_STP_AHM_QTDRESUMO_SF"(P_codusu    Number,
                                   P_idsessao  Varchar2,
                                   P_qtdlinhas Number,
                                   P_mensagem Out Varchar2)

As
p_dtini Date;
p_dtfim Date;
p_codmaq Number;
Begin
/***************************************************************************
  * Autor: Marcus Rangel
  * Dt. Crea��o: 04/09/2017
  * Processo: Apontamento de Horas M�quinas/Ve�culos
  * Objetivo: Exibir na tela o resumo de medi��o de determinada m�quina/ve�culo
  *****************************************************************************/

    p_codmaq := Act_int_param (
                              P_chave = > P_idsessao,
                              P_nome = > 'CODMAQ');

    p_dtini := Act_dta_param (
                             P_idsessao,
                             'DTINI');

    If p_dtini Is Null Then
        p_dtini := TO_DATE (
                           SUBSTR (
                                  Replace (
                                          Act_dec_param (
                                                        P_idsessao,
                                                        'DTINI'),
                                          '.',
                                          ''),
                                  1,
                                  8),
                           'yyyymmdd');
    End If;

    p_dtfim := Act_dta_param (
                             P_idsessao,
                             'DTFIM');

    If p_dtfim Is Null Then
        p_dtfim := TO_DATE (
                           SUBSTR (
                                  Replace (
                                          Act_dec_param (
                                                        P_idsessao,
                                                        'DTFIM'),
                                          '.',
                                          ''),
                                  1,
                                  8),
                           'yyyymmdd');
    End If;

    For i In 1 .. P_qtdlinhas
    Loop
        P_mensagem := SUBSTR ('<b>Maq/Veículo: </b>' ||p_codmaq ||' - ' ||
                          Ad_pkg_ahm.Descrmaquina (p_codmaq),1,50) ||' (' ||
                   TO_CHAR (p_dtini,'dd/mm/yy') ||' a ' ||TO_CHAR (p_dtfim,'dd/mm/yy') ||')';

        For D In (Select --Substr('<b>Maq/Ve�culo: </b>' || r.codmaq || ' - ' || m.descrmaq, 1, 50) ||
                      '<br>' ||
                      '<b>Un. Medi��o: </b>' ||
                      am.Codvol ||
                      ' - ' ||
                      v.Descrvol ||
                      ' / ' ||
                      '<b>Quantidade: </b>' ||
                      SUM (r.Tothoras) mensagem
                  From Ad_tsfahmrad r
                       Join Ad_tsfahmmaq am On
                                            R.Nuseqmaq = am.Nuseqmaq And
                                            r.Nuapont = am.Nuapont
                       Join Ad_tsfcme m On am.Codmaq = m.Codmaq
                       Join Tgfvol v On am.Codvol = v.Codvol
                  Where
                      r.Dtapont Between p_dtini And p_dtfim And
                      am.Codmaq = P_codmaq
                      Group By
                      am.Codmaq,
                      m.Descrmaq,
                      am.Codvol,
                      v.Descrvol)
        Loop
            If P_mensagem Is Null Then
                P_mensagem := d.mensagem; Else
                                              P_mensagem :=
                                                         P_mensagem ||
                                                         d.mensagem;
            End If;
        End Loop;

    End Loop;

End;
/
