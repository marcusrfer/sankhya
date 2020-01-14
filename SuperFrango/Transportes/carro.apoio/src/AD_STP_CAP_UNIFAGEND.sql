Create Or Replace Procedure "AD_STP_CAP_UNIFAGEND"(p_codusu    Number,
                                                   p_idsessao  Varchar2,
                                                   p_qtdlinhas Int,
                                                   p_mensagem  Out Varchar2) Is
  r_Cap       ad_TSFCAP%Rowtype;
  r_New       ad_tsfcap%Rowtype;
  v_proxNuap  Number;
  v_Seqdoc    Int := 0;
  v_count     Int := 0;
  v_mergeRota Clob;
  v_qtdPsg    Number := 0;
  T_Nuap      Dbms_utility.Maxname_array;

Begin
  /*
  * Autor: Marcus Rangel.
  * Processo: Agendamento de Carro de Apoio.
  * Objetivo: Realizar a combina√ß√£o de agendamentos, para atender corridas distintas com o mesmo destino.
  */

  r_cap.codusuexc := p_codusu;

  For I In 1 .. p_qtdlinhas
  Loop
    r_cap.nuap := Act_int_field(p_idsessao, I, 'NUAP');
    T_Nuap(I) := r_cap.nuap;
  End Loop;

  If p_qtdlinhas < 2 Then
    p_Mensagem := 'Selecione no mÌnimo 2 lanÁamentos para combinar.';
    Return;
  End If;

  /*Insere o novo agendamento*/
  Begin
  
    -- v_msg := Ad_pkg_cap.Msg_combinacao(v_proxnuap);
    For r In T_Nuap.first .. T_Nuap.last
    Loop
    
      Select *
        Into r_Cap
        From ad_tsfcap
       Where nuap = T_Nuap(r);
    
      /*tratativa para preencher alguns campos da tela como o parceiro, As cidades*/
      If r_new.codparctransp Is Null Then
        r_new.codparctransp := r_cap.codparctransp;
      End If;
    
      If r_new.codveiculo Is Null Then
        r_new.codveiculo := r_cap.codveiculo;
      End If;
    
      If r_new.codcidorig Is Null Then
        r_new.codcidorig := r_cap.codcidorig;
      End If;
    
      If r_new.codciddest Is Null Then
        r_new.codciddest := r_cap.codciddest;
      End If;
    
      If r_new.kminicial Is Null Or r_new.kminicial = 0 Then
        r_new.kminicial := r_cap.kminicial;
      End If;
    
      If r_new.kmfinal Is Null Or r_new.kmfinal = 0 Then
        r_new.kmfinal := r_cap.kmfinal;
      End If;
    
      If r_new.totalkm Is Null Or r_new.totalkm = 0 Then
        r_new.totalkm := r_cap.totalkm;
      End If;
    
      If v_mergerota Is Null Then
        v_mergerota := r_Cap.Rota || Chr(13) || 'Motivo: ' || r_cap.motivo || Chr(13) ||
                       ' Hor·rio: ' || To_Char(r_cap.dtagend, 'dd/mm/yyyy hh24:mi:ss');
      
      Else
        v_mergerota := v_mergerota || Chr(13) ||
                       '----------------------------------------------------------------------------------------' ||
                       Chr(13) || r_Cap.Rota || Chr(13) || 'Motivo: ' || r_cap.motivo || Chr(13) ||
                       ' Hor·rio: ' || To_Char(r_cap.dtagend, 'dd/mm/yyyy hh24:mi:ss');
      End If;
    
      v_qtdPsg := v_qtdPsg + r_cap.qtdpassageiros;
    
    End Loop;
  
  End;

  <<insere_agend>>

  Declare
    v_nomecidorig Varchar2(200);
    v_nomeciddest Varchar2(200);
  Begin
  
    stp_keygen_tgfnum('AD_TSFCAP', 1, 'AD_TSFCAP', 'NUAP', 0, v_proxNuap);
  
    Select nomecid
      Into v_nomecidorig
      From tsicid
     Where codcid = r_new.codcidorig;
  
    Select nomecid
      Into v_nomeciddest
      From tsicid
     Where codcid = r_new.codciddest;
  
    Insert Into Ad_tsfcap
      (Nuap, Dhsolicit, Status, Combinada, rota, Codusuexc, Codveiculo, Codparctransp, Motorista,
       Kminicial, Kmfinal, Totalkm, Qtdpassageiros, codcidorig, nomecidorig, codciddest, nomeciddest)
    Values
      (v_proxNuap, Sysdate, 'P', 'S', v_mergeRota, r_cap.codusuexc, r_Cap.codveiculo,
       r_new.CodParcTransp, r_Cap.Motorista, r_new.kminicial, r_new.kmfinal, r_new.totalkm, v_qtdPsg,
       r_new.codcidorig, r_new.nomecidorig, r_new.codciddest, r_new.nomeciddest);
  
  Exception
    When dup_val_on_index Then
      Merge Into tgfnum n
      Using (Select Max(Nuap) MaxNuap
               From Ad_Tsfcap) c
      On (n.arquivo = 'AD_TSFCAP' And n.codemp = 1 And n.serie = ' ')
      When Matched Then
        Update
           Set n.ultcod = c.MaxNuap
      When Not Matched Then
        Insert
          (arquivo, codemp, serie, automatico, ultcod)
        Values
          ('AD_TSFCAP', 1, ' ', 'S', c.maxNuap);
    
      Goto insere_agend;
    When Others Then
      p_Mensagem := 'Erro ao inserir o agendamento. ' || Sqlcode || ' - ' || Sqlerrm;
      Return;
  End;

  /* Atualiza o status dos lan√ßamento de origem */
  For P In T_Nuap.First .. T_Nuap.Last
  Loop
    Begin
      Update Ad_tsfcap C
         Set C.Status = 'M',
             --C.Rota    = C.Rota || Chr(13) || 'Agendamento combinado, resultando no agendamento nro ' || v_proxNuap,
             c.nuappai = v_proxNuap
       Where Nuap = T_Nuap(P);
    Exception
      When Others Then
        p_Mensagem := 'Erro ao atualizar agendamentos de origem. ' || Sqlerrm;
        Return;
    End;
  End Loop P;

  -- atualiza o NUAP das solicita√ß√µes
  Begin
    ad_pkg_cap.atualiza_StatusSol(p_NroAgendamento => v_proxNuap, p_StatusSolicit => 'E',
                                  p_enviaEmail => 'N', p_enviaAviso => 'N', p_errmsg => p_mensagem);
    If p_Mensagem Is Not Null Then
      Return;
    End If;
  End;

  -- insere os documentos
  For Origdoc In (Select nuap
                    From ad_tsfcap
                   Where Nuappai = v_proxNuap)
  Loop
  
    For Doc In (Select *
                  From Ad_tsfcapdoc
                 Where Nuap = Origdoc.Nuap)
    Loop
      v_Seqdoc := v_seqdoc + 1;
      v_count  := 0;
    
      Select Count(*)
        Into v_count
        From Ad_tsfcapdoc
       Where Nuap = v_proxNuap
         And Codcencus = Doc.Codcencus
         And Codsolicit = Doc.Codsolicit;
    
      If v_count = 0 Then
        Begin
          Insert Into Ad_tsfcapdoc
            (Nuap, Seqdoc, Codcencus, Codsolicit, Entregue)
          Values
            (v_proxNuap, v_Seqdoc, Doc.Codcencus, Doc.Codsolicit, 'N');
        Exception
          When DUP_VAL_ON_INDEX Then
            v_proxNuap := v_proxNuap + 1;
        End;
      Else
        Continue;
      End If;
    
    End Loop Doc;
  
  End Loop Origdoc;

  -- insere o rateio
  Declare
    v_seqRat Int;
  Begin
  
    Delete From ad_tsfcapfrt
     Where nuap = v_proxNuap;
  
    Select Nvl(Max(r.numfrt), 1)
      Into v_seqRat
      From ad_tsfcapfrt r
     Where nuap = v_proxNuap;
  
    For c_Rat In (Select r.codemp,
                         r.codcencus,
                         r.codnat,
                         Nvl(r.codproj, 0) codproj,
                         ratio_to_report(Count(*)) over() * 100 As percentual
                    From ad_tsfcapfrt r
                    Join ad_tsfcap c
                      On r.nuap = c.nuap
                   Where c.nuappai = v_proxNuap
                   Group By r.codemp, r.codcencus, r.codnat, Nvl(r.codproj, 0))
    Loop
      v_seqRat := v_seqRat + 1;
      Insert Into ad_tsfcapfrt
        (nuap, numfrt, codemp, codcencus, codnat, codproj, percentual)
      Values
        (v_proxNuap, v_seqRat, c_rat.codemp, c_rat.codcencus, c_rat.codnat, c_rat.codproj,
         c_rat.percentual);
    End Loop;
  End;

  p_mensagem := 'Lan√ßamentos combinados com sucesso! Foi gerado o agendamento n√∫mero <a  target ="_parent" href="' ||
                Ad_fnc_urlskw('AD_TSFCAP', v_proxnuap) || '"><font color="#0000FF">' || v_proxNuap ||
                '</font></a>';

End;
/
