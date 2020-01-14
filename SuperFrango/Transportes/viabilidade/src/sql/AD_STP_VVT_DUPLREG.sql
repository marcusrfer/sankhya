Create Or Replace Procedure "AD_STP_VVT_DUPLREG"(p_codusu    Number,
                                                 p_idsessao  Varchar2,
                                                 p_qtdlinhas Number,
                                                 p_mensagem  Out Varchar2) As
  v_Numvvt Number;
  r_vvt    ad_tsfvvt%Rowtype;
Begin
  /* Autor: M. Rangel | 15/06/2018
  * Processo: Viabilidade de Veículos de TRansporte
  * Objetivo: Duplicar o cabeçalho e as desapesas.
  */

  For i In 1 .. p_qtdlinhas
  Loop
  
    v_numvvt := act_int_field(p_idsessao, i, 'NUMVVT');
  
    Select * Into r_vvt From ad_tsfvvt Where numvvt = v_numvvt;
  
    Begin
    
      stp_keygen_tgfnum('AD_TSFVVT', 1, 'AD_TSFVVT', 'NUMVVT', 0, r_vvt.numvvt);
    
      r_vvt.vlrcustofixo := 0;
      r_vvt.vlrcustovar  := 0;
      r_vvt.vlrcustotemp := 0;
      r_vvt.vlrtotcusto  := 0;
      r_vvt.ativo        := 'N';
      r_vvt.dtref        := Trunc(Sysdate, 'mm');
      r_vvt.dhvigor      := Sysdate;
    
      Insert Into ad_tsfvvt Values r_vvt;
    
    Exception
      When Others Then
        p_mensagem := 'Erro ao inserir o cabeçalho da viabilidade. <br>' || Sqlerrm;
        Return;
    End;
  
    For d In (Select * From ad_tsfdvt Where numvvt = v_numvvt)
    Loop
      Begin
        Insert Into ad_tsfdvt
          (numvvt, numdvt, coddespvei, tipodesp, vlrdespfixa, vlrdespvar)
        Values
          (r_vvt.numvvt, d.numdvt, d.coddespvei, d.tipodesp, d.vlrdespfixa, d.vlrdespvar);
      Exception
        When Others Then
          p_mensagem := 'Erro ao inserir as despesas da viabilidade nro ' || r_vvt.numvvt;
          Return;
      End;
    End Loop;
  
  End Loop i;

  p_Mensagem := 'Lançamento duplicado com sucesso!!!<br>' || 'Foi gerado o lançamento nro ' ||
                '<a target="_parent" href="' || ad_fnc_urlskw('AD_TSFVVT', r_vvt.numvvt, Null, Null) || '">' ||
                r_vvt.numvvt || '</a>';

End;
/
