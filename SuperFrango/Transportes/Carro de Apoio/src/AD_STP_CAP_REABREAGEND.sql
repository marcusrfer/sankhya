create or replace Procedure "AD_STP_CAP_REABREAGEND"(P_CODUSU Number, P_IDSESSAO Varchar2, P_QTDLINHAS Number, P_MENSAGEM Out Varchar2) As
	r_Cap  ad_tsfcap%Rowtype;
	errmsg Varchar2(4000);
	error Exception;
Begin
	/*
  * Autor: Marcus Rangel
  * Processo: Carro de Apoio
  * Objetivo: Reabrir o agendamento para correção, o procedimento defaz todas as ações realizadas no fechamento do agendamento
  */

	For I In 1 .. P_QTDLINHAS
	Loop
		r_cap.nuap := ACT_INT_FIELD(P_IDSESSAO, I, 'NUAP');

		Select *
			Into r_cap
			From ad_tsfcap
		 Where nuap = r_cap.nuap;

		r_cap.motivoreabre := act_txt_param(p_IdSessao, 'MOTIVO');

		If R_Cap.Status Not In ('R','C') Then
			errmsg := 'Somente agendamentos finalizados/cancelados podem ser reabertos.';
			Raise error;
		End If;

		If Length(r_cap.motivoreabre) < 15 Then
			errmsg := 'Motivo informado incompleto. Detalhe mais o motiva da reabertura.';
			Raise error;
		End If;

		-- encontra o acerto do agendamento em questão, verifica se o acerto ainda está pendente
    if r_cap.status = 'R' then
      ad_pkg_cap.exclui_acerto(p_nroagend => r_cap.nuap, p_errmsg => errmsg);
      If errmsg Is Not Null Then
        Raise error;
      End If;
    end if;

		-- atualiza o status do agendamento de origem
		Begin
			Update Ad_Tsfcap Cap
				 Set Cap.Status = case When R_Cap.Status = 'R' Then 'A' Else 'P' End, 
             Cap.Dtreabre = Sysdate, 
             Cap.Codusureabre = P_Codusu, 
             cap.motivoreabre = r_cap.motivoreabre
			 Where nuap = r_cap.nuap;

			Ad_Pkg_Cap.Atualiza_Statussol(P_Nroagendamento => R_Cap.Nuap,
																		p_statussolicit  => case when r_cap.status = 'R' then 'A' else 'E' end,
																		p_enviaemail     => 'N',
																		p_enviaaviso     => 'N',
																		p_errmsg         => errmsg);
			If errmsg Is Not Null Then
				Raise error;
			End If;
		Exception
			When Others Then
				errmsg := 'Erro ao atualizar o status do agendamento ' || r_cap.nuap || '. - ' || Sqlerrm;
				Raise error;
		End;

	End Loop I;

	P_MENSAGEM := 'Agendamento reaberto com sucesso!';

Exception
	When error Then
		Rollback;
		P_MENSAGEM := errmsg;
	When Others Then
		P_MENSAGEM := Sqlerrm;
End;