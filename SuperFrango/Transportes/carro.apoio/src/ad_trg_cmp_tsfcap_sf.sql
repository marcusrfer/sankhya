create or replace trigger ad_trg_cmp_tsfcap_sf
 for update or delete on sankhya.ad_tsfcap
 compound trigger

 type t_nuaporig is table of number;
 t      t_nuaporig := t_nuaporig();
 errmsg varchar2(4000);
 error exception;

 /*
   Dt. Criação:= 06/12/2016
   Autor: Marcus Rangel
   Objetivo: "Descombinar" os agendamentos de origem quando um agendamento combinado for excluído, excluir a ligação, atualizar o status das solicitações dos agendamentos originais
 
   Atenção: Não é necessário adicionar tratativas para a exclusão do agendamento sem combinação, pois ao excluir o agendamento, a constraint seta o nuap da solicitação pra null
   e na solicitação tem um gatilho que realiza validações e existe uma regra para quando o status da solicitação for enviado e o nro do agendamento for setado para null, o gailho
   altera o status para pendente.
 */

 /* Status
 A - Agendado
 C - Cancelado
 P - Pendente
 R - Realizado
 M - Combinada*/
 before statement is
 begin
  t.delete;
  ad_pkg_cap.v_permite_edicao := true;
  stp_set_atualizando('S');
 end before statement;

 before each row is
 begin
 
  if updating then
   if :old.status in ('C', 'R') and :new.motivoreabre is null then
    errmsg := 'Agendamentos Realizados, não podem ser alterados!';
    raise error;
   end if;
  
   /* 
     * Solicitado dia 23/06/2017, caso: Motorista saiu dia 26, dormiu por lá
     * e retornou no dia 27/06
   
     If Trunc(:new.Dtagend) <> Trunc(:new.Dtagendfim) Then
       ErrMsg := 'Agendamentos devem ser realizados dentro do mesmo dia.';
       Raise error;
     End If;
   */
  end if;
 
  if deleting then
   if :old.status in ('C', 'R') then
    errmsg := 'Lançamentos Cancelados ou Concluídos, não podem ser excluídos!';
    raise error;
   elsif :old.status in ('P', 'A') then
    t.extend;
    t(t.last) := :old.nuap;
   end if;
  end if;
 exception
  when error then
   raise_application_error(-20105, ad_fnc_formataerro(errmsg));
 end before each row;

 after each row is
 begin
  if deleting then
   begin
    insert into ad_tsfcapexc
     (nuap, codususol, dhsolicit, ordemcarga, codusuexc, codparctransp, codveiculo, status, taxi,
      motivotaxi, kminicial, kmfinal, totalkm, vlrcorrida, nucapsol, dtagend, rota, dtagendfim,
      combinada, codcontato, qtdpassageiros, motorista, motivo, deptosol, codciddest, codcidorig,
      nomecidorig, nomeciddest, dhmov, dtreabre, codusureabre, motivoreabre, nuappai, dhexclusao,
      codusudel)
    values
     (:old.nuap, :old.codususol, :old.dhsolicit, :old.ordemcarga, :old.codusuexc,
      :old.codparctransp, :old.codveiculo, :old.status, :old.taxi, :old.motivotaxi, :old.kminicial,
      :old.kmfinal, :old.totalkm, :old.vlrcorrida, :old.nucapsol, :old.dtagend, :old.rota,
      :old.dtagendfim, :old.combinada, :old.codcontato, :old.qtdpassageiros, :old.motorista,
      :old.motivo, :old.deptosol, :old.codciddest, :old.codcidorig, :old.nomecidorig,
      :old.nomeciddest, :old.dhmov, :old.dtreabre, :old.codusureabre, :old.motivoreabre,
      :old.nuappai, sysdate, stp_get_codusulogado);
   exception
    when others then
     ad_set.insere_msglog(p_mensagem => 'Erro ao gravar log de exclusão de agendamento de carro de apoio. ' ||
                                        sqlerrm);
   end;
  end if;
 
 end after each row;

 after statement is
 begin
 
  if deleting then
   if t.count <> 0 then
   
    for c_idx in t.first .. t.last
    loop
    
     for c_lig in (select * from ad_tsfcap c where c.nuappai = t(c_idx))
     loop
     
      for c_orig in (select nucapsol
                       from ad_tsfcap
                      where nucapsol is not null
                        and status = 'M'
                      start with nuap = c_lig.nuap
                     connect by prior nuap = nuappai
                     union
                     select nucapsol
                       from ad_tsfcap
                      where status <> 'M'
                        and nuap = c_lig.nuap
                        and nucapsol is not null)
      loop
       -- volta o agendamento para pendente e desfaz o vínculo com o combinado
       begin
        stp_set_atualizando('S');
        update ad_tsfcap
           set nuappai = null,
               status  = 'P'
         where nuap = c_lig.nuap
           and status = 'M';
        stp_set_atualizando('N');
       exception
        when others then
         ad_pkg_var.errmsg := 'Erro ao atualizar o status da solicitação. ' || sqlerrm;
         raise_application_error(-20105, ad_fnc_formataerro(ad_pkg_var.errmsg));
       end;
      
       -- volta o agendamento anterior ao agendamento na solicitação.
       begin
        stp_set_atualizando('S');
        update ad_tsfcapsol s
           set nuap   = c_lig.nuap,
               status = 'P'
         where nucapsol = c_orig.nucapsol;
        stp_set_atualizando('N');
       exception
        when others then
         ad_pkg_var.errmsg := 'Erro ao atualizar o status da solicitação. ' || sqlerrm;
         raise_application_error(-20105, ad_fnc_formataerro(ad_pkg_var.errmsg));
       end;
      
      end loop;
     end loop;
    end loop;
   end if;
  
  end if;
 
 end after statement;

end;
/
