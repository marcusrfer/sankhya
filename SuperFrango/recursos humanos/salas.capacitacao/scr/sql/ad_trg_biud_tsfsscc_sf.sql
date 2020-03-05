create or replace trigger ad_trg_biud_tsfsscc_sf
 before insert or update or delete on ad_tsfsscc
 for each row
declare
 -- local variables here
 v_codcencus number;
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
 
  -- valida horarios e uso do "dia todo"
  if nvl(:new.diatodo, 'N') = 'N' and (:new.hrini is null or :new.hrfin is null) then
   raise_application_error(-20105,
                           fc_formatahtml_sf('Necessário informar os horários quando a atividade não é "O dia todo"',
                                             'Somente lançamentos marcados como "Dia Todo" não requerem que o ' ||
                                             'horário seja informado',
                                             'Informe os horários de início e de término de utilização da sala!',
                                             null));
  end if;
 
  -- preenche horário quando dia todo
  if :new.diatodo = 'S' then
   :new.hrini := '0800';
   :new.hrfin := '1800';
  end if;
 
 end if;

 if updating then
 
  -- valida quando status pendente
  if :old.status != 'P' then
   raise_application_error(-20105,
                           ad_fnc_formataerro('Somente Solicitações "Pendentes" podem ser alteradas!'));
  end if;
 end if;

 if (inserting or updating) then
 
  -- preenche centro de resultados  
  if :new.codususol is not null and :new.codcencus is null then
  
   :new.codcencus := ad_get.codcencus_usuario(:new.codususol);
  
  end if;
 
 end if;

 if deleting then
  null;
 end if;

end ad_trg_biud_ad_tsfsscc_sf;
/
