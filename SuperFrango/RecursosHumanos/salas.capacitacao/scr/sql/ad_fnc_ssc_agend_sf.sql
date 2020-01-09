Create Or Replace Function ad_fnc_ssc_agend_sf(p_ano     Varchar2,
                                               p_mes     Varchar2,
                                               p_dian    Varchar2,
                                               p_dia     Number,
                                               p_codsala Number) Return Varchar2 Is
  v_data   Date;
  v_result Varchar2(2000);
Begin

  Begin
    v_data := To_Date(To_Char(p_dia) || '/' || To_Char(To_Date(p_mes, 'mm'), 'mm') || '/' || p_ano, 'dd/mm/yyyy');
  
    For t In (Select a.hrini || ' - ' || a.hrfin || ' - ' || s.nomesala As resumo
                From ad_tsfssca a
                Join ad_prhsalas s
                  On a.codsala = s.codsala
               Where Trunc(a.dtreserva) = v_data
                 And To_Char(a.dtreserva, 'DY') = p_dian
                 And a.codsala = p_codsala
                 And a.status In ('A', 'P'))
    Loop
      If v_result Is Null Then
        v_result := '<p>' || Upper(t.resumo) || '</p>';
      Else
        v_result := v_result || '<p>' || Upper(t.resumo) || '</p>';
      End If;
    End Loop;
  
    --backup antes da alteração danilo
    /*for t in (select a.hrini || ' - ' || a.hrfin ||' - '||s.nomesala as resumo
                from ad_tsfssca a
                  join ad_prhsalas s on a.codsala = s.codsala
               where trunc(a.dtreserva) = v_data
                 and to_char(a.dtreserva, 'DY') = p_dian
                 and a.codsala = p_codsala
                 and a.status in ('A', 'P'))
    loop
       if v_result is null then
          v_result := t.resumo;
       else
          v_result := v_result ||'*'||chr(13) || t.resumo;
       end if;
    end loop;*/
  
  Exception
    When Others Then
      v_result := Null;
  End;

  /*if p_dia is not null then
     return nvl(upper(v_result), 'Nenhum agendamento');
  else
     return upper(v_result);
  end if;*/

  Return v_result;

End;
/
