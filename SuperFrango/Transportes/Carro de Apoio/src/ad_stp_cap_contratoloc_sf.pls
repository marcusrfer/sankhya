create or replace procedure ad_stp_cap_contratoloc_sf(p_codusu    number,
                                                      p_idsessao  varchar2,
                                                      p_qtdlinhas number,
                                                      p_mensagem  out varchar2) as
  p_numloc    varchar2(4000);
  v_codcencus int;
  cap         ad_tsfcap%rowtype;
  loc         ad_loccab%rowtype;
  i           int;
  finalizar   boolean := false;
begin

  /*
  *Autor: M. Rangel
  *Processo: Carro de apoio
  *Objetivo: Gerar o contrato de locação de veículos
  */

  if p_qtdlinhas > 1 then
    p_mensagem := 'Selecione apenas um registro por vez!!!';
    return;
  end if;

  cap.nuap        := act_int_field(p_idsessao, 1, 'NUAP');
  loc.numcontrato := upper(act_txt_param(p_idsessao, 'NUMCONTRATO'));
  loc.codemp      := act_txt_param(p_idsessao, 'CODEMP');

  begin
    select * into cap from ad_tsfcap where nuap = cap.nuap;
    select r.codcencus into v_codcencus from ad_tsfcaprat r where r.nucapsol = cap.nucapsol;
  exception
    when others then
      p_mensagem := sqlerrm;
      return;
  end;

  if cap.status = 'C' then
    p_mensagem := 'Agendamento está cancelado, não pode gerar contrato.';
  elsif cap.status = 'P' then
    p_mensagem := 'Agendamento pendente de confirmação!';
  else
    select count(*) into i from ad_loccab l where l.localizador = cap.numloc;
  
    if i > 0 then
      p_mensagem := 'Já existe contrato gerado para este localizador.';
      return;
    else
      finalizar := true;
    end if;
  
  end if;

  if nvl(cap.codveiculo, 0) = 0 or nvl(cap.codparctransp, 0) = 0 then
    p_mensagem := 'Informe o veículo e o parceiro transportador!';
    return;
  end if;

  begin
    insert into ad_loccab
      (numcontrato, status, codparc, codemp, saida, retorno, codusuinc, dhinc, localizador)
    values
      (loc.numcontrato, 'P', cap.codparctransp, loc.codemp, cap.dtagend, cap.dtagendfim, p_codusu,
       sysdate, cap.numloc);
    commit;
  exception
    when others then
      p_mensagem := 'Erro ao inserir o cabeçalho do contrato. ' || sqlerrm;
      return;
  end;

  begin
    insert into ad_locvei
      (numcontrato, codveiculo, codparc, dtini, dtdev, codcencus, atual, motivo, kminicial)
    values
      (loc.numcontrato, cap.codveiculo, cap.codparctransp, cap.dtagend, cap.dtagendfim, v_codcencus,
       'S', cap.motivo, null);
  exception
    when others then
      delete from ad_loccab where numcontrato = loc.numcontrato;
      p_mensagem := 'Erro ao inserir o veículo. ' || sqlerrm;
      return;
  end;

  if finalizar then
  
    ad_stp_cap_finalizagend(p_codusu => p_codusu, p_idsessao => p_idsessao, p_qtdlinhas => 1,
                            p_mensagem => p_mensagem);
  end if;

  p_mensagem := 'Contrato gravado com sucesso!';

end;
/
