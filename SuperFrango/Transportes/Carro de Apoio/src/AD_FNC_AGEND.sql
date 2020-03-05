Create Or Replace Function AD_FNC_AGEND(p_ano Varchar2, p_Mes Varchar2, p_dian Varchar2, p_dia Number) Return Varchar2 Is
	v_data   Date;
	v_Result Varchar2(2000);
Begin

	/*For C In (
     Select ano, mes, sem, 'QUA' diaN, cal.qua dia
   From ad_vw_calendar cal
  Where cal.MES = to_char(Sysdate, 'Month')
    And cal.qua = 19
  Order By cal.MES, sem)
  Loop
    p_ano := c.ano;
    p_mes := c.mes;
    p_dian := c.dian;
    p_dia := c.dia;
  
  End Loop;*/
	Begin
		v_data := to_date(to_char(p_dia) || '/' || to_char(to_date(p_mes, 'mm'), 'mm') || '/' || p_ano, 'dd/mm/yyyy');
	
		For T In (Select
							--c.nuap || ' - ' || p.nomeparc || ' - ' || v.marcamodelo || ' - ' ||
							--to_char(c.dtagend, 'HH24:mi') || ' / ' || to_char(c.dtagendfim, 'HH24:mi') resumo
							--v.marcamodelo || ' - ' ||
							--regexp_replace(v.placa, '([A-Z]{3})([0-9]{4})', '\1-\2') || ' - ' ||
							 p.nomeparc || ' - ' || to_char(c.dtagend, 'HH24:mi') || ' / ' || to_char(c.dtagendfim, 'HH24:mi') resumo
								From ad_tsfcap c
							 Inner Join tgfpar p On c.codparctransp = p.codparc
							 Inner Join tgfvei v On c.codveiculo = v.codveiculo
							 Where trunc(dtagend) = v_data
								 And to_char(dtagend, 'DY') = p_dian
								 And c.status = 'A')
		Loop
			If v_Result Is Null Then
				v_Result := t.resumo;
			Else
				v_Result := v_result || chr(13) || t.resumo;
			End If;
		End Loop;
	Exception
		When Others Then
			v_result := Null;
	End;

	If p_dia Is Not Null Then
		Return nvl(upper(v_Result), 'Nenhum agendamento');
	Else
		Return upper(v_result);
	End If;

End;
/
