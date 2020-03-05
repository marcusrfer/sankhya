Create Or Replace Procedure "AD_STP_CAP_CANCAGEND"(p_codUsu    Number,
                                                   p_IdSessao  Varchar2,
                                                   p_qtdLinhas Int,
                                                   p_Mensagem  Out Varchar2) Is
  v_NroUnico Number;
  v_Motivo   Varchar2(400);
  r_Sol      ad_tsfcapsol%Rowtype;
  r_Cap      ad_tsfcap%Rowtype;
  v_Msg      Varchar2(4000);
  Errmsg     Varchar2(4000);
  Error Exception;
Begin
  /*
   Autor: Marcus Rangel
   Processo: Carro de Apoio
   Objetivo: Realizar o processo de solicitação e cancelamento tanto da solicitação quanto do agendamento, verificando se existe fechamento e tratando o mesmo.
  */

  ad_pkg_cap.v_permite_edicao := True;

  For I In 1 .. p_qtdlinhas
  Loop
    v_NroUnico := act_int_field(p_idsessao, I, 'NUCAPSOL');
    v_Motivo   := act_txt_param(p_IdSessao, 'MOTIVO');
  
    If v_NroUnico Is Not Null Then
    
      Select * Into r_Sol From ad_tsfcapsol Where nucapsol = v_NroUnico;
    
      /*If r_sol.status Not In ('E', 'A') Then
        p_Mensagem := 'Somente solicitações com status "<font color="#FF0000">Enviada</font>"' ||
                      'ou "<font color="#FF0000">Agendada</font>" podem ser canceladas.<br><br>' ||
                      'Procure o responsável pelo agendamento para corrgir essa situação.';
        Return;
      End If;*/
    
      Begin
        Select * Into r_Cap From ad_tsfcap Where nuap = R_SOL.NUAP;
      Exception
        When no_data_found Then
          -- se não tem agendamento, só cancela
          Update ad_tsfcapsol Set status = 'C' Where nucapsol = r_sol.nucapsol;
        
          p_mensagem := 'Cancelamento efetuado com sucesso!';
          Return;
      End;
    
      ad_set.Ins_Avisosistema(p_Titulo => 'Solicitação de Cancelamento.',
                              p_Descricao => 'O usuário ' || ad_get.nomeUsu(r_sol.codusu, 'resumido') ||
                                              ' solicitou o cancelamento do agendamento ' || r_sol.nuap ||
                                              ', resultante da solicitação ' || v_NroUnico ||
                                              ', alegando o seguinte motivo: <b> ' || v_motivo || '</b>',
                              p_Solucao => 'Para maiores detalhes, acesse o registro ',
                              p_Usurem => r_sol.codusu, p_Usudest => r_cap.codusuexc, p_Prioridade => 1,
                              p_Tabela => 'AD_TSFCAP', p_Nrounico => r_sol.nuap, p_Erro => Errmsg);
    
      If Errmsg Is Not Null Then
        Raise error;
      End If;
    
      v_msg := 'Solicitação de Cancelamento enviada com Sucesso!!!';
    
    Else
      --entra no cancelamento real
    
      v_NroUnico := act_int_field(p_idsessao, I, 'NUAP');
    
      Select * Into r_Cap From ad_tsfcap Where nuap = v_NroUnico;
    
      If r_cap.status Not In ('P', 'A') Then
        Errmsg := 'Somente agendamentos com status "<font color="#FF0000">Pendente</font>"' ||
                  'ou "<font color="#FF0000">Agendado</font>" podem ser cancelados.<br><br>';
        Raise error;
      End If;
    
      /*Verifica se existe acerto*/
      -- encontra o acerto do agendamento em questão, verifica se o acerto ainda está pendente    
      ad_pkg_cap.exclui_acerto(p_nroagend => r_cap.nuap, p_errmsg => p_mensagem);
      If p_Mensagem Is Not Null Then
        Return;
      End If;
    
      /*Atualiza o status das solicitações de origem, envia e-mail para os solicitantes e aviso via sistema*/
      Begin
        ad_pkg_cap.atualiza_statussol(p_nroagendamento => r_cap.nuap, p_statussolicit => 'C',
                                      p_enviaemail => 'S', p_enviaaviso => 'S', p_errmsg => p_Mensagem);
      
        If p_Mensagem Is Not Null Then
          Return;
        End If;
      
      End;
    
      Begin
        Update ad_tsfcap c
           Set c.status       = 'C',
               c.dtreabre     = Sysdate,
               c.motivoreabre = v_Motivo,
               c.codusureabre = stp_get_codusulogado
         Where c.nuap = r_cap.nuap;
      Exception
        When Others Then
          p_Mensagem := 'Erro ao atulizar o status do agendamento. ' || Sqlerrm;
          Return;
      End;
    
      p_Mensagem := 'Cancelamento realizado com sucesso!!!';
    
    End If;
  
  End Loop;

End;
/
