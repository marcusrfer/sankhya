create or replace procedure ad_stp_fci_aprovfech_sf(p_codusu    number,
                                                    p_idsessao  varchar2,
                                                    p_qtdlinhas number,
                                                    p_mensagem  out varchar2) as
  field_numlote number;
begin

 /*
 * Autor: mrangel
 * Processo: Comissão integrado frango vivo
 * Objetivo: Marcar o lote como aprovado (substituindo a auditoria)
 */

  for i in 1 .. p_qtdlinhas
  loop
    field_numlote := act_int_field(p_idsessao, i, 'NUMLOTE');
    stp_set_atualizando('S');
  
    update ad_tsffci f
       set f.statuslote  = 'A',
           f.dhalter     = sysdate,
           f.codusualter = p_codusu,
           f.codusuaprov = p_codusu,
           f.dhaprov = sysdate
     where f.numlote = field_numlote;

    stp_set_atualizando('N');  
  end loop;

  p_mensagem := 'Lote Aprovado com sucesso!';

end;
/
