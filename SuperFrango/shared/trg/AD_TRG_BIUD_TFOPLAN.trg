Create Or Replace Trigger "AD_TRG_BIUD_TFOPLAN"
	Before Insert Or Update Or Delete On ad_tfoplan
	For Each Row
Declare
	vNuaviso     Number;
	vNuPlan      Number;
	vDescricao   Varchar2(2000);
	vDescrStatus Varchar2(100);
	vStatus      Char(1);
	vTipo        ad_tfoplan.tipo%Type;
	vDescrTipo   Varchar2(20);
	vResp        ad_tfoplan.respplan%Type;
	vNomeResp    Varchar2(100);
	vAtividade   ad_tfoplan.tarefa%Type;
	ErrMsg       Varchar2(4000);
Begin
	vNuplan    := :new.Nuplan;
	vtipo      := :new.Tipo;
	vResp      := :new.Respplan;
	vStatus    := :new.Status;
	vAtividade := :new.Tarefa;

	If inserting Then
		Select Max(nuaviso) + 1
			Into vNuaviso
			From tsiavi;
		vDescrTipo := ad_get.opcoescampo(p_Valor => vTipo, p_Nomecampo => 'TIPO', p_Nometab => 'AD_TFOPLAN');
		vNomeResp  := ad_get.opcoescampo(p_Valor => vResp, p_Nomecampo => 'RESPPLAN', p_Nometab => 'AD_TFOPLAN');
		vdescricao := 'Nova atividade cadastrada no registro de atividade
		<table style="width:100%">
		<tr>
		<td>Tipo:' || vdescrtipo || '</td>
		</tr>
		<tr>
		<td>Responsável: ' || vnomeResp || '</td>
		</tr>
		<tr>
		<td>Atividade: ' || ad_fnc_urlskw('AD_TFOPLAN', vNuPlan) || '</a> - ' || vAtividade || '</td>
		</tr>
		</table>';
	
		ad_set.ins_avisosistema(p_titulo     => 'Nova Atividade registrada',
														p_descricao  => vdescricao,
														p_solucao    => '',
														p_usurem     => :new.Codususolicit,
														p_usudest    => :new.Codusuresp,
														p_prioridade => 1,
														p_tabela     => 'AD_TFOPLAN',
														p_nrounico   => vNuplan,
														p_erro       => errmsg);
	End If;

	If updating('STATUS') Then
		If :new.Status = 'A' Then
			:new.Dtexec   := To_Date(Sysdate, 'DD/MM/YYYY');
			:New.Hrinicio := To_Number(To_Char(Sysdate, 'HH24MI'));
		Elsif :new.status = 'C' Then
			:new.Hrtermino := To_Number(To_Char(Sysdate, 'HH24MI'));
		End If;
	
		Select Max(nuaviso) + 1
			Into vNuaviso
			From tsiavi;
		vStatus      := :new.Status;
		vdescrstatus := ad_get.opcoescampo(p_Valor => vStatus, p_Nomecampo => 'STATUS', p_Nometab => 'AD_TFOPLAN');
		vDescricao   := 'Atividade atualizada
		<table style="width:100%">
		<tr>
<td>Atividade: ' || ad_fnc_urlskw('AD_TFOPLAN', vNuPlan) || '</a> - ' || vAtividade || '</td>
		</tr>
		<tr>
		<td>Status: ' || vdescrstatus || '</td>
		</tr>
		</table>';
	
		ad_set.ins_avisosistema(p_titulo     => 'Nova Atividade registrada',
														p_descricao  => vdescricao,
														p_solucao    => '',
														p_usurem     => :new.Codusuresp,
														p_usudest    => :new.Codususolicit,
														p_prioridade => 1,
														p_tabela     => 'AD_TFOPLAN',
														p_nrounico   => vNuplan,
														p_erro       => errmsg);
	End If;

End;
/
