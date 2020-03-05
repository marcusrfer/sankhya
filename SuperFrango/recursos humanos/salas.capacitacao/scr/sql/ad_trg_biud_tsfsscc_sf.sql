create or replace trigger ad_trg_biud_tsfsscc_sf
 before insert or update or delete on ad_tsfsscc
 for each row
declare
 -- local variables here
 v_codcencus number;
begin

 /*
 ** Autor: m. rangel
 ** processo: reserva de salas de capacita��o
 ** objetivo: controle de opera��o, dados e valida��es diversas
 */

 if stp_get_atualizando then
  return;
 end if;

 if inserting then
 
  -- valida horarios e uso do "dia todo"
  if nvl(:new.diatodo, 'N') = 'N' and (:new.hrini is null or :new.hrfin is null) then
   raise_application_error(-20105,
                           fc_formatahtml_sf('Necess�rio informar os hor�rios quando a atividade n�o � "O dia todo"',
                                             'Somente lan�amentos marcados como "Dia Todo" n�o requerem que o ' ||
                                             'hor�rio seja informado',
                                             'Informe os hor�rios de in�cio e de t�rmino de utiliza��o da sala!',
                                             null));
  end if;
 
  -- preenche hor�rio quando dia todo
  if :new.diatodo = 'S' then
   :new.hrini := '0800';
   :new.hrfin := '1800';
  end if;
 
 end if;

 if updating then
 
  -- valida quando status pendente
  if :old.status != 'P' then
   raise_application_error(-20105,
                           ad_fnc_formataerro('Somente Solicita��es "Pendentes" podem ser alteradas!'));
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
