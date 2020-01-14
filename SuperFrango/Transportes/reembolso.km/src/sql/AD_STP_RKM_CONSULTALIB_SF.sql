Create Or Replace Procedure "AD_STP_RKM_CONSULTALIB_SF"(p_codusu    Number,
                                                        p_idsessao  Varchar2,
                                                        p_qtdlinhas Number,
                                                        p_mensagem  Out Varchar2) As
  c             ad_tsfrkmc%Rowtype;
  v_descrevento Varchar2(250);
  v_statuslib   Varchar2(100);
  v_nomellib    Varchar2(100);
Begin
  If p_qtdlinhas > 1 Then
    p_mensagem := 'Selecione apenas uma linha!';
    Return;
  End If;

  c.nureemb := act_int_field(p_idsessao, 1, 'NUREEMB');

  Select *
    Into c
    From ad_tsfrkmc
   Where nureemb = c.nureemb;

  If c.status = 'P' Then
    p_mensagem := 'Não existem liberações para esse lançamento!';
  End If;

  For l In (Select *
              From tsilib
             Where tabela = 'AD_TSFRKMC'
               And nuchave = c.nureemb
            Union
            Select *
              From tsilib
             Where tabela = 'TGFFIN'
               And nuchave = c.nufin)
  Loop
    If l.evento In (44) Or l.evento >= 1000 Then
    
      Select Substr(e.descricao, 1, 23)
        Into v_descrevento
        From tgflibeve e
       Where e.nuevento = l.evento;
    
      If l.dhlib Is Null Then
        v_statuslib := '<font color="#FF0000">' || To_Char(l.dhsolicit, 'dd/mm/yyyy') || ' - ' ||
                       v_descrevento || '</font>';
      Else
        v_statuslib := '<font color="#0000FF">' || To_Char(l.dhlib, 'dd/mm/yyyy') || ' - ' ||
                       v_descrevento || '</font>';
      End If;
    
      v_nomellib := ad_get.nomeusu(l.codusulib, 'resumido') || ' (' || l.codusulib || ')';
    
      If p_mensagem Is Null Then
        p_mensagem := v_nomellib || ' - ' || v_statuslib;
      Else
        p_mensagem := p_mensagem || '<br>' || Chr(13) || v_nomellib || ' - ' || v_statuslib;
      End If;
    End If;
  
  End Loop;

End;
/
