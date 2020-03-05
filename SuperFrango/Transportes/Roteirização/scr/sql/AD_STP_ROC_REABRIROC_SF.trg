Create Or Replace Procedure "AD_STP_ROC_REABRIROC_SF"(p_codusu    Number,
                                                      p_idsessao  Varchar2,
                                                      p_qtdlinhas Number,
                                                      p_mensagem  Out Varchar2) As
  field_numrocc Number;
Begin
  For i In 1 .. p_qtdlinhas
  Loop
    field_numrocc               := act_int_field(p_idsessao, i, 'NUMROCC');
    variaveis_pkg.V_ATUALIZANDO := True;
  
    Begin
      Update ad_tsfrocc
         Set status = 'P'
       Where numrocc = field_numrocc;
    Exception
      When Others Then
        Raise;
    End;
  
  End Loop;

End;
/
