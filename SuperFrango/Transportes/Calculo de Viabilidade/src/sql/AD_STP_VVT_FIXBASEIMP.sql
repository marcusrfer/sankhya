Create Or Replace Procedure "AD_STP_VVT_FIXBASEIMP"(p_codusu    Number,
                                                    p_idsessao  Varchar2,
                                                    p_qtdlinhas Number,
                                                    p_mensagem  Out Varchar2) As
  v_numvvt Number;
  v_Soma   Float;
Begin
  /* Autor: Marcus Rangel
     Processo: Viabilidade de Veículos
     Objetivo: Utilizado na ação "Refazer Base de cálculo do Imposto", da tela de viabilidade,
     tem como finalidade, somar todas as despesas com exceção do imposto, para criar a base
     sobre a qual será calculado o valor do imposto.
  */
  For i In 1 .. p_qtdlinhas
  Loop
    v_numvvt := act_int_field(p_idsessao, i, 'NUMVVT');
  
    Begin
      Select Sum(vlrdespfixa) + Sum(vlrdespvar)
        Into v_soma
        From ad_tsfdvt
       Where Numvvt = v_numvvt
         And coddespvei <> 10;
    Exception
      When Others Then
        Raise;
    End;
  
    Begin
      Update ad_tsfvvt v Set v.vlrcustotemp = v_soma Where numvvt = v_numvvt;
    Exception
      When Others Then
        Raise;
    End;
  End Loop;

  p_mensagem := 'Base refeita, insira novamente o imposto.';

End;
/
