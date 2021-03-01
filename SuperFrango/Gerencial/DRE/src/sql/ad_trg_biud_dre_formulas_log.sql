create or replace trigger ad_trg_biud_dre_formulas_log
  after insert or update or delete on dre_formulas
  for each row
declare
  v_seqhist number;
begin
  /* Autor: Marcus Rangel
  * Processo: DRE
  * Objetivo: Gravar as alterações na tabela de fórmulas
  */

  begin
    select nvl(max(seqhist), 0)
      into v_seqhist
      from dre_formulas_log
     where codform = nvl(:new.codform, :old.codform);
  exception
    when others then
      raise;
  end;

  v_seqhist := v_seqhist + 1;

  if inserting then
    insert into dre_formulas_log
      (seqhist, operacao, codusu, dhalter, codform, tipoind, query, base)
    values
      (v_seqhist, 'INSERT', stp_get_codusulogado, sysdate, :new.codform, :new.tipoind, :new.query, :new.base);
  elsif updating then
    insert into dre_formulas_log
      (seqhist, operacao, codusu, dhalter, codform, tipoind, query, base)
    values
      (v_seqhist, 'UPDATE NEW VALUES', stp_get_codusulogado, sysdate, :new.codform, :new.tipoind, :new.query, :new.base);
  
    insert into dre_formulas_log
      (seqhist, operacao, codusu, dhalter, codform, tipoind, query, base)
    values
      (v_seqhist + 1, 'UPDATE OLD VALUES', stp_get_codusulogado, sysdate, :old.codform, :old.tipoind, :old.query,
       :old.base);
  elsif deleting then
    raise_application_error(-20105,
                            fc_formatahtml_sf(p_mensagem => 'Fórmulas não podem ser excluídas.',
                                               p_motivo => 'Para garantir o histórico de alterações.',
                                               p_solucao => 'Cadastre uma nova fórmula e a vincule ao indicador desejado.',
                                               p_error => sqlerrm));
    /*Insert Into dre_formulas_log
      (operacao, machine, codusu, dhalter, codform, descrfor, tipoind, query, base)
    Values
      ('DELETE', sys_context('USERENV', 'HOST'), stp_get_codusulogado, Sysdate, :old.Codform, :old.Codform, :old.Tipoind,
       :old.Query, :old.Base);*/
  end if;

end;
/
