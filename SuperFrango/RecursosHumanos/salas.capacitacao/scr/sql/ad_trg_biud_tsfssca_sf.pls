create or replace trigger ad_trg_biud_tsfssca_sf
  before insert or update or delete on ad_tsfssca
  for each row
declare
  mail       tmdfmg%rowtype;
  v_codusu   int := stp_get_codusulogado;
  issuplente int := 0;
begin
  /*
  ** Autor: m. rangel
  ** processo: reserva de salas de capacitação
  ** objetivo: controle de operação, dados e validações diversas
  */
  if stp_get_atualizando then
    return;
  end if;

  if inserting then
    null;
  elsif updating then
  
    select count(*)
      into issuplente
      from tsisupl s
     where s.codusu = :new.codusulib
       and s.codususupl = v_codusu
       and s.dtfim > sysdate;
  
    if :old.status != 'P' and
       v_codusu not in (:old.codusulib, 0, :old.codmonitor) and issuplente = 0 then
      raise_application_error(-20105,
                              ad_fnc_formataerro('Solicitações "Aprovadas" não podem ser alteradas!'));
    end if;
  
    if updating('CODSALA') or updating('DTRESERVA') or updating('HRINI') or
       updating('HRFIN') then
    
      mail.assunto := 'Alteração de reserva de Sala/Ambiente';
    
      if nvl(:new.codmonitor, :old.codmonitor) is null then
        mail.email := ad_get.mailusu(:new.codususol);
      else
        mail.email := ad_get.mailusu(:new.codususol) || ', ' ||
                      ad_get.mailusu(:new.codmonitor);
      end if;
    
      mail.mensagem := 'Venho por meio deste informar que houve alterações na sua solicitação de reserva.' ||
                       '<br><b>Sala:</b>' || :new.codsala || ' - ' ||
                       ad_pkg_ssc.get_nomesala(:new.codsala) ||
                       '<br><b>Dt. Reserva: </b>' || :new.dtreserva ||
                       ' <b>Horário:</b> ' || fmt.hora(:new.hrini) || ' ~ ' ||
                       fmt.hora(:new.hrfin) ||
                       '<br> Alterações realizadas por ' ||
                       initcap(ad_get.nomeusu(stp_get_codusulogado, 'completo')) ||
                       ' as ' || to_char(sysdate, 'dd/mm/yyyy hh24:mi:ss');
    
      ad_stp_gravafilabi(mail.assunto, mail.mensagem, mail.email);
    
    end if;
  
  elsif deleting then
    if :old.nussc is not null then
      begin
        update ad_tsfsscc
           set status     = 'P',
               dhenvio    = null,
               dhaprovneg = null
         where nussc = :old.nussc;
      exception
        when others then
          raise;
      end;
    end if;
  end if;

end;
/
