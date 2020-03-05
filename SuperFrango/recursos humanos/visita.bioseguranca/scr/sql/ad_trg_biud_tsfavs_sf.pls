create or replace trigger ad_trg_biud_tsfavs_sf
  before insert or update or delete on ad_tsfavs
  for each row
declare

  errmsg    varchar2(4000);
  v_hist    varchar2(4000);
  v_matfunc number;
begin

  if stp_get_atualizando then
    return;
  end if;

  if inserting then
    -- set status automatico inicial
    if :new.dhprevis is not null then
      :new.status := 'prog';
    end if;
  
    -- se não é terceiro
    if :new.tipovisita != 'T' then
      --exige empresa
      if :new.codemp is null then
        errmsg := 'Código da empresa não informado!';
        raise_application_error(-20105, ad_fnc_formataerro(errmsg));
      end if;
    
      -- se visita de manutenção vai exigir matricula
      if :new.tipovisita = 'M' and :new.matfunc is null then
        begin
          select fu.fumatfunc
            into v_matfunc
            from fpwpower.funciona fu
           where fu.fucodemp = :new.codemp
             and fu.funomfunc = :new.nomevisitado;
        exception
          when others then
            errmsg := 'Informe o número da matrícula do funcionário';
            raise_application_error(-20105, ad_fnc_formataerro(errmsg));
        end;
      end if;
    
    end if; -- fim tipo T
  
  end if; -- fim insert

  if updating then
  
    if (:old.status = :new.status) and :new.status = 'conf' and
       stp_get_codusulogado not in (729) then
      errmsg := 'Visitas confimardas não podem ser alteradas.';
      raise_application_error(-20105, ad_fnc_formataerro(errmsg));
    end if;
  
    if (:old.resultvis = :new.resultvis) and :new.resultvis = 'L' then
      errmsg := 'Visitas aguardando liberação não podem ser alteradas.';
      raise_application_error(-20105, ad_fnc_formataerro(errmsg));
    end if;
  
    --- se visita está concluída
    if :old.status = 'conc' and :new.status = 'conc' and
       stp_get_codusulogado not in (729) then
      errmsg := 'Visitas concluídas não podem ser alteradas.';
      raise_application_error(-20105, ad_fnc_formataerro(errmsg));
    end if;
  
    if (:old.status = :new.status) and :new.status = 'canc' then
      errmsg := 'Visitas canceladas não podem ser alteradas.';
      raise_application_error(-20105, ad_fnc_formataerro(errmsg));
    end if;
  
    if :new.dhprevis is null then
      :new.status := 'pend';
      v_hist      := 'Status alterado para "Pendente".';
      ad_pkg_avs.insere_historico(:new.nuvisita, v_hist);
    end if;
  
    if :old.dhprevis is null and :new.dhprevis is not null then
      :new.status := 'prog';
      v_hist      := 'Status alterado para "Programado".';
      ad_pkg_avs.insere_historico(:new.nuvisita, v_hist);
    end if;
  
    if :old.dhvisita is null and :new.dhvisita is not null then
      :new.status := 'conc';
      v_hist      := 'Status alterado para "Concluído".';
      ad_pkg_avs.insere_historico(:new.nuvisita, v_hist);
    end if;
  
    if (:old.statuscar != :new.statuscar) and
       :new.statuscar in ('E', 'P', 'AL') then
      :new.status := 'aconf';
      v_hist      := 'Status alterado para "Aguard. Confirmação".';
      ad_pkg_avs.insere_historico(:new.nuvisita, v_hist);
    end if;
  
    if (:old.statuscar != :new.statuscar and
       :old.dhagendcarro != :new.dhagendcarro) and
       (:new.dhagendcarro is not null and :new.statuscar = 'A') then
      :new.status := 'aconf';
      v_hist      := 'Status alterado para "Aguard. Confirmação".';
      ad_pkg_avs.insere_historico(:new.nuvisita, v_hist);
    end if;
  
    -- ao remover solicitacoes de carro pendentes
    if (:new.nucapsol is null and :old.nucapsol > 0) then
      :new.dhcapsol     := null;
      :new.dhagendcarro := null;
      :new.codveiculo   := null;
      :new.statuscar    := null;
      :new.status       := 'prog';
      v_hist            := 'Solicitação de carro de apoio desfeita';
      ad_pkg_avs.insere_historico(:new.nuvisita, v_hist);
    end if;
  
    -- cancelamento do carro de apoio
    if (:old.statuscar != :new.statuscar) and :new.statuscar = 'C' then
      :new.status := 'prog';
      v_hist      := 'Solicitação de carro de apoio cancelada.';
      ad_pkg_avs.insere_historico(:new.nuvisita, v_hist);
    end if;
  
    -- cancelamento da visita
    if :new.status = 'canc' then
      v_hist := 'Visita cancelada.';
      ad_pkg_avs.insere_historico(:new.nuvisita, v_hist);
    end if;
  
    :new.dhalter := sysdate;
    :new.codusu  := stp_get_codusulogado;
  
    /*if v_hist is not null then
      stp_set_atualizando('S');
      ad_pkg_avs.insere_historico(:new.nuvisita, v_hist);
      stp_set_atualizando('N');
    end if;*/
  
    if :new.tipovisita = 'C' and :new.dhvisita is not null and
       :new.matfunc is not null then
      begin
        insert into ad_tsfprgvis
          (matfunc, codemp, codlot, codcargo, codcid, coduf, dtultvis, ativo)
        values
          (:new.matfunc, :new.codemp, :new.codlot, :new.codcargo, :new.codcid,
           :new.coduf, :new.dhvisita, 'S');
      exception
        when dup_val_on_index then
          begin
            update ad_tsfprgvis
               set dtultvis = :new.dhvisita
             where codemp = :new.codemp
               and matfunc = :new.matfunc;
          exception
            when others then
              raise_application_error(-20105,
                                      'Erro ao atualizar a dt. da última visita na programação ' ||
                                      ' de visitas de manutenção' || sqlerrm);
          end;
        when others then
          raise_application_error(-20105,
                                  'Erro ao inserir o funcionário na programação ' ||
                                  ' de visitas de manutenção' || sqlerrm);
      end;
    
    end if;
  
    -- visitas sanitárias de manutenção
    if :new.tipovisita = 'M' and :new.dhvisita is not null and
       :new.matfunc is not null then
      begin
        update ad_tsfprgvis v
           set v.dtultvis = :new.dhvisita
         where v.codemp = :new.codemp
           and v.matfunc = :new.matfunc;
      exception
        when others then
          raise;
      end;
    end if;
  
  end if;

  if deleting then
  
    if :old.status = 'conc' then
      errmsg := 'Visitas concluídas não podem ser excluídas.';
      raise_application_error(-20105, ad_fnc_formataerro(errmsg));
    end if;
  
  end if;

end;
/
