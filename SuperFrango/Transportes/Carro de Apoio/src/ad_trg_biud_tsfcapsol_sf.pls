create or replace trigger ad_trg_biud_tsfcapsol_sf
  before delete or insert or update on ad_tsfcapsol
  for each row
declare
  v_codcencus number;
  errmsg      varchar2(4000);
  r_cus       tsicus%rowtype;
begin
  /*
   * Autor: Marcus Rangel
   * Processo: Carro de Apoio 
   * Objetivo: Controle de alteraÁıes / status
  */

  if stp_get_atualizando then
    return;
  end if;

  if inserting then
  
    /*
     If :new.Dtagend < :new.Dhsolicit Then
      ErrMSg := 'A data de <i>agendamento</i> n√£o pode ser menor que a data de <i>solicita√ß√£o</i>';
      Raise Error;
    End If;
    */
  
    :new.dhsolicit := sysdate;
  
    if to_char(:new.dtagend, 'hh24:mi:ss') = '00:00:00' then
      errmsg := 'Necess·rio informar o hor·rio na data do agendamento.';
      raise_application_error(-20105, ad_fnc_formataerro(errmsg));
    end if;
  
    if :new.codcencus is null or :new.codcencus = 0 then
    
      select nvl(codcencuspad, 0)
        into v_codcencus
        from tsiusu
       where codusu = :new.codusu;
    
      :new.codcencus := v_codcencus;
    end if;
  
    if :new.qtdpassageiros is null then
      errmsg := 'Por favor, informe a quantidade de passageiros.';
      raise_application_error(-20105, ad_fnc_formataerro(errmsg));
    end if;
  
    if :new.tipo is null then
      :new.tipo := 'CAP';
    end if;
  
    if :new.dtagend < :new.dhsolicit then
      errmsg := 'A data de <i>agendamento</i> n„o pode ser menor que a data de ' ||
                '<i>solicitaÁ„o</i> data do agendamento ' || to_char(:new.dtagend, 'dd/mm/yyyy HH24:MI:SS') ||
                ' solicitaÁ„o: ' || to_char(:new.dhsolicit, 'dd/mm/yyyy HH24:MI:SS');
      raise_application_error(-20105, ad_fnc_formataerro(errmsg));
    end if;
  
    /*If :new.codcencus Not Between 10000001 And 20000000 - 1 Then
      errmsg := 'Somente Centros de Resultados do Abatedouro podem ser utilizados.';
      Raise_Application_Error(-20105, Ad_fnc_formataerro(errmsg));
    End If;*/
  
    if :new.codcencus > 0 then
      begin
        select *
          into r_cus
          from tsicus
         where codcencus = :new.codcencus;
      
        if r_cus.ativo != 'S' or r_cus.analitico != 'S' then
          errmsg := 'Centro de Resultados n„o est· ativo ou n„o È analÌtico.';
          raise_application_error(-20105, ad_fnc_formataerro(errmsg));
        end if;
      
      exception
        when others then
          raise;
      end;
    else
      errmsg := 'Centro de Resultado n„o informado!';
      raise_application_error(-20000, errmsg);
    end if;
  
  end if;

  if updating then
  
    /*
    If :new.Dtagend < :new.Dhsolicit Then
      ErrMSg := 'A data de <i>agendamento</i> n√£o pode ser menor que a data de <i>solicita√ß√£o</i>';
      Raise Error;
    End If;
    */
  
    if :new.codcencus is null or :new.codcencus = 0 then
      begin
        select nvl(codcencuspad, 0)
          into v_codcencus
          from tsiusu
         where codusu = :new.codusu;
      
        :new.codcencus := v_codcencus;
      exception
        when others then
          raise;
      end;
    end if;
  
    -- se Status = Enviado ou Aguardando ou Realizado ou Cancelado
    --Dbms_Output.Put_Line(:old.Status);
    --Dbms_Output.Put_Line(Case When ad_pkg_cap.v_permite_edicao = False Then 'false' Else 'true' End);
  
    /*
    A - Agendada
    AL - Aguard. Libera√ß√£o
    C - Cancelada
    E - Enviada
    L - Liberada
    P - Pendente
    R - Realizada
    SR - Sol. Reprovada
    */
  
    if :old.status <> 'P' then
    
      if not ad_pkg_cap.v_permite_edicao then
      
        /* If Updating('CODUSU') Then
          errmsg := 'Usu√°rio n√£o pode ser alterado em lan√ßamentos j√° agendados/realizados/cancelados.';
          Raise Error;
        Elsif Updating('CODCENCUS') Then
          errmsg := 'Centro de resultados n√£o pode ser alterado em lan√ßamentos j√° agendados/realizados/cancelados.';
          Raise Error;
        Elsif Updating('DTAGEND') Then
          errmsg := 'Data de agendamento n√£o pode ser alterada em lan√ßamentos j√° agendados/realizados/cancelados.';
          Raise Error;
        Elsif Updating('DHALTER') Then
          errmsg := 'lan√ßamentos j√° agendados/realizados/cancelados n√£o podem ser alterados.';
          Raise Error;
        End If;*/
      
        dbms_output.put_line('old stsatus' || :old.status);
      
        errmsg := 'LanÁamentos Enviados, Agendados, Aguardando LiberaÁ„o, ' ||
                  'Cancelados e Realizados n„o podem ser alterados.';
        raise_application_error(-20105, ad_fnc_formataerro(errmsg));
      
      end if;
    
    end if;
  
    if (:old.nuap is null and :new.nuap is null) and :old.status = 'A' then
      :new.status := 'P';
    end if;
  
    if (:old.nuap is not null and :new.nuap is null and :old.status = 'E') then
      :new.status := 'P';
    end if;
  
  end if;

  if deleting then
  
    if (:old.status = 'A' or :old.status = 'R' or :old.status = 'C') and ad_pkg_cap.v_permite_edicao = false then
      --:old.Nuap Is Not Null Then
      errmsg := 'LanÁamentos j· agendados/realizados/cancelados n„o podem ser excluÌdos.';
      raise_application_error(-20105, ad_fnc_formataerro(errmsg));
    end if;
  
  end if;

end;
/
