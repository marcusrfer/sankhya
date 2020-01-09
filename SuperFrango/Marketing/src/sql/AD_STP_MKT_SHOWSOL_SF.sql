Create Or Replace Procedure "AD_STP_MKT_SHOWSOL_SF"(p_codusu Number,
                                                    p_idsessao Varchar2,
                                                    p_qtdlinhas Number,
                                                    p_mensagem Out Varchar2) As
   c ad_tsfcmkt%Rowtype;
   s ad_tsfsmkt%Rowtype;
Begin

   If p_qtdlinhas > 1 Then
      p_mensagem := 'Selecione uma linha de cada vez!';
      Return;
   End If;

   c.nucmkt := act_int_field(p_idsessao, 1, 'NUCMKT');
   Select * Into c From ad_tsfcmkt Where nucmkt = c.nucmkt;
   Select * Into s From ad_tsfsmkt Where nusmkt = c.nusmkt;

   p_mensagem := s.mailtext;

End;
/
