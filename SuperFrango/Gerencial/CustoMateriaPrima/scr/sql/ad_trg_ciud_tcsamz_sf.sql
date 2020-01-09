create or replace trigger ad_trg_ciud_tcsamz_sf
 for insert or update or delete on ad_tcsamz
 compound trigger

 v_numcontrato number;
 i             int := 0;

 /*
 * Autor: M.Rangel
 * Processo: Matéria Prima
 * Objetivo: Atualizar os dados no contrato
 */

 before each row is
 begin
 
  if :new.numcontrato is null then
   stp_keygen_tgfnum('TCSCON', 1, 'TCSCON', 'NUMCONTRATO', 0, v_numcontrato);
  
   :new.numcontrato := v_numcontrato;
  
  end if;
 
  -- busca o contrato de compra pelo número do pedido de capacitação
  if updating('NUNOTA') or (inserting and :new.nunota is not null) then
  
   begin
    select cab.numcontrato into v_numcontrato from tgfcab cab where cab.nunota = :new.nunota;
   exception
    when others then
     v_numcontrato := 0;
   end;
  
   if nvl(v_numcontrato, 0) = 0 then
    begin
     select numcontrato
       into v_numcontrato
       from tcscon
      where nunota = :new.nunota
        and codemp = :new.codemp
        and codparc = :new.codparc;
    exception
     when no_data_found then
      v_numcontrato := 0;
    end;
   end if;
  
   :new.numcontratocpa := v_numcontrato;
  
  end if;
 
 end before each row;

 after each row is
 begin
 
  if variaveis_pkg.v_atualizando then
   goto finaldatrigger;
  end if;
 
  select count(*)
    into i
    from tgfcab
   where numcontrato = nvl(:old.numcontrato, :new.numcontrato)
     and numcontrato > 0;
 
  if inserting then
  
   begin
   
    insert into tcscon
     (numcontrato, dtcontrato, codcontato, codemp, codparc, codnat, codmoeda, codcencus, ativo,
      codtdc, tipoarm, codsaf, codusu, dtbasereaj, recdesp, codgpc, ad_objcontrato, nunota)
    values
     (v_numcontrato, :new.dtcontrato, 0, :new.codemp, :new.codparc, :new.codnat, :new.codmoeda,
      :new.codcencus, :new.ativo, :new.codtdc, :new.tipoarm, :new.codsaf, stp_get_codusulogado,
      :new.dtcontrato, 0, :new.codgpc, 'Armazem', :new.nunota);
   
    insert into tcspsc
     (numcontrato, codprod, numusuarios, kitservicos, tipcobkit, respquebratec, respkitserv,
      resparmaz, unidconversao, qtdisencao, tipoarea, areatotal, areaplant, qtdeprevista,
      dtinicioisencao, dtfimisencao)
    values
     (:new.numcontrato, :new.codprod, 1, :new.kitservicos, :new.tipcobkit, :new.respquebratec,
      :new.respkitserv, :new.resparmaz, :new.unidconversao, :new.qtdisencao, nvl(:new.tipoarea, 'P'),
      :new.areatotal, :new.areaplant, :new.qtdprevista, :new.dtinicioisencao, :new.dtfimisencao);
   
    insert into tcspre
     (numcontrato, codprod, referencia, valor, codserv)
    values
     (v_numcontrato, :new.codprod, :new.dtcontrato, :new.valor, :new.codserv);
   exception
    when others then
     raise;
   end;
  
  elsif updating then
  
   variaveis_pkg.v_atualizando := true;
  
   begin
    dbms_output.put_line('KitServiços => ' || :new.kitservicos);
   
    begin
     update tcscon
        set dtcontrato = :new.dtcontrato,
            codemp     = :new.codemp,
            codparc    = :new.codparc,
            codnat     = :new.codnat,
            codmoeda   = :new.codmoeda,
            codcencus  = :new.codcencus,
            ativo      = :new.ativo,
            codtdc     = :new.codtdc,
            tipoarm    = :new.tipoarm,
            codsaf     = :new.codsaf,
            codusu     = nvl(:new.codusu, stp_get_codusulogado),
            codgpc     = :new.codgpc,
            codproj    = nvl(:new.codproj, 0),
            nunota     = :new.nunota,
            codempresp = :new.codempresp
      where numcontrato = :new.numcontrato;
    exception
     when others then
      raise_application_error(-20105,
                              'Erro ao atualizar dados do cabeçalho do contrato. ' || sqlerrm);
    end;
   
    begin
     update tcspsc
        set codprod         = :new.codprod,
            tipcobkit       = :new.tipcobkit,
            respquebratec   = :new.respquebratec,
            kitservicos     = nvl(:new.kitservicos, 'N'),
            respkitserv     = :new.respkitserv,
            resparmaz       = :new.resparmaz,
            unidconversao   = :new.unidconversao,
            qtdisencao      = :new.qtdisencao,
            tipoarea        = nvl(:new.tipoarea, 'P'),
            areatotal       = :new.areatotal,
            areaplant       = :new.areaplant,
            qtdeprevista    = :new.qtdprevista,
            dtinicioisencao = :new.dtinicioisencao,
            dtfimisencao    = :new.dtfimisencao
      where numcontrato = :new.numcontrato
        and codprod = :new.codprod;
    exception
     when others then
      raise_application_error(-20105,
                              'Erro ao atualizar dados do produto do contrato. ' || sqlerrm);
    end;
   
    dbms_output.put_line(:new.qtdprevista);
   
    begin
     update tcspre
        set codprod    = :new.codprod,
            referencia = :new.dtcontrato,
            valor      = :new.valor,
            codserv    = :new.codserv
      where numcontrato = :new.numcontrato
        and codprod = :new.codprod
        and codserv = :new.codserv;
    exception
     when others then
      raise_application_error(-20105, 'Erro ao atualizar dados do valor do contrato. ' || sqlerrm);
    end;
   
    variaveis_pkg.v_atualizando := false;
   
   end;
  
  else
  
   if i > 0 then
    raise_application_error(-20105, 'Contrato possui lançamentos, não pode ser excluído!');
   else
    ad_pkg_sst.exclui_contrato(:old.numcontrato);
   end if;
  
  end if;
  <<finaldatrigger>>
  null;
 end after each row;

end ad_trg_ciud_tcsamz_sf;
/
