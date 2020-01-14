create or replace procedure "AD_STP_CAP_INFOAGEND_SF"(p_codusu number,
                                                      p_idsessao varchar2,
                                                      p_qtdlinhas number,
                                                      p_mensagem out varchar2) as
  field_nucapsol number;
  r_cap          ad_tsfcap%rowtype;
begin

  /* Autor: M. Rangel
  * Processo: Carro de Apoio
  * Objetivo: Exibir um popup na tela contendo informações básicas sobre o agendamento
  */

  for i in 1 .. p_qtdlinhas
  loop
    field_nucapsol := act_int_field(p_idsessao, i, 'NUCAPSOL');
  
    begin
      select c.* into r_cap from ad_tsfcapsol s join ad_tsfcap c on s.nuap = c.nuap where s.nucapsol = field_nucapsol;
    
      p_mensagem := 'O agendamento encontra-se <b>' || ad_get.opcoescampo(r_cap.status, 'STATUS', 'AD_TSFCAP') ||
                    '</b>.<br>';
      p_mensagem := p_mensagem || chr(13) || ' <b>Dt. Agendamento: </b>' ||
                    to_char(r_cap.dtagend, 'dd/mm/yyyy hh24:mi:ss') || '<br>';
      p_mensagem := p_mensagem || chr(13) || '<b>Motorista: </b>' || r_cap.motorista || ' - ' ||
                    ad_get.nome_parceiro(r_cap.motorista, 'completo') || '<br>';
      p_mensagem := p_mensagem || chr(13) || '<b>Veículo: </b>' || ad_get.formataplaca(r_cap.codveiculo) || '<br><br>';
      p_mensagem := p_mensagem || chr(13) ||
                    '<p style="color:red">As informações são melhor visualizadas no layout Novo.';
    
    exception
      when no_data_found then
        p_mensagem := 'Solicitação não foi agendada ainda!';
        return;
      when others then
        p_mensagem := 'Erro ao consultar informações do agendamento. ' || chr(13) || sqlerrm;
        return;
    end;
  
  end loop;

end;
/
