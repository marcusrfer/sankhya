Create Or Replace Procedure AD_STP_CAP_REFAZRATEIO_SF(P_CODUSU    Number,
                                                      P_IDSESSAO  Varchar2,
                                                      P_QTDLINHAS Number,
                                                      P_MENSAGEM  Out Varchar2) As
  r_cap ad_tsfcap%Rowtype;
Begin
  /* 
  * Autor: M. Rangel
  * Processo: Carro de Apoio
  * Objetivo: Corrigir o rateio na aba de mesmo nome na tela de agendamento de carro de apoio
  */

  For i In 1 .. P_QTDLINHAS
  Loop
    r_cap.nuap := ACT_INT_FIELD(P_IDSESSAO, I, 'NUAP');
  
    If r_cap.status Not In ('A', 'P') Then
      p_mensagem := 'Somente agendamentos não finalizados podem ser refeitos';
      Return;
    End If;
  
    Delete From ad_tsfcapfrt t
     Where t.nuap = r_cap.nuap;
  
    For r_sol In (With filhos As
                     (Select nuap, nuappai, nucapsol
                       From ad_tsfcap c
                      Where c.nuappai = r_cap.nuap)
                    Select rownum,
                           r.codemp,
                           r.codnat,
                           r.codcencus,
                           Nvl(r.codproj, 0) codproj,
                           Round(ratio_to_report(Count(*)) Over() * 100, 4) As Percentual
                      From ad_tsfcap c
                      Left Join filhos f
                        On f.nuappai = c.nuap
                      Join ad_tsfcapsol s
                        On s.nucapsol = Nvl(c.nucapsol, f.nucapsol)
                      Join ad_tsfcaprat r
                        On s.nucapsol = r.nucapsol
                     Where c.nuap = r_cap.nuap
                     Group By rownum, r.codemp, r.codnat, r.codcencus, Nvl(r.codproj, 0)
                     Order By Rownum)
    Loop
      Dbms_Output.Put_Line(r_cap.nuap || ' | ' || r_sol.codcencus || ' | ' || r_sol.percentual);
    
      Insert Into ad_tsfcapfrt
        (nuap, numfrt, codemp, codcencus, codnat, codproj, percentual)
      Values
        (r_cap.nuap, r_sol.rownum, r_sol.codemp, r_sol.codcencus, r_sol.codnat, r_sol.codproj,
         r_sol.percentual);
    
    End Loop r_sol;
  
  End Loop i;

  P_MENSAGEM := 'Rateio recalculado com sucesso!!!';
Exception
  When Others Then
    p_mensagem := 'Ocorreu um erro ao realizar o processo. <br> Detalhes: ' || Sqlerrm;
End;
/
