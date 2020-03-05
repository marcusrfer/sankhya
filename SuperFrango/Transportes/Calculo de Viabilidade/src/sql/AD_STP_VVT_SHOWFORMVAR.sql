Create Or Replace Procedure "AD_STP_VVT_SHOWFORMVAR"(P_CODUSU    Number,
                                                     P_IDSESSAO  Varchar2,
                                                     P_QTDLINHAS Number,
                                                     P_MENSAGEM  Out Varchar2) As

Begin

  For r In (Select nomecampo, descrcampo
              From tddcam
             Where nometab = 'AD_TSFVVT'
               And tipcampo = 'F')
  Loop
    P_MENSAGEM := P_MENSAGEM || Chr(13) || r.nomecampo || ' - ' || r.descrcampo || '<br>';
  End Loop;

End;
/
