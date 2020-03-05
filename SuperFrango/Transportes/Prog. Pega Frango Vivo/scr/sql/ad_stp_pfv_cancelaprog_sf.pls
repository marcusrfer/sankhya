create or replace procedure ad_stp_pfv_cancelaprog_sf(p_codusu    number,
                                                      p_idsessao  varchar2,
                                                      p_qtdlinhas number,
                                                      p_mensagem  out varchar2) as
  v_motivo varchar2(4000);
  pfv      ad_tsfpfv2%rowtype;
  cab      tgfcab%rowtype;

begin

  /* 
  * Dt. Criação: 20/12/2018
  * Autor: M. Rangel
  * Processo: Programação Frango Vivo
  * Objetivo: Cancelar as programações geradas automaticamente pelo sistema
  */

  v_motivo := act_txt_param(p_idsessao, 'MOTIVO');

  for i in 1 .. p_qtdlinhas
  loop
  
    pfv.nupfv := act_int_field(p_idsessao, i, 'NUPFV');
  
    select * into pfv from ad_tsfpfv2 where nupfv = pfv.nupfv;
  
    -- IMPLEMENTAR    
    -- se tem nota gerada
    if pfv.nunota is not null then
      p_mensagem := 'Nota confirmada, programação não pode ser cancelada!';
      return;
    end if;
  
    begin
    
      insert into ad_tsfcpfv
        select p.nupfv,
               p.codune,
               p.nucleo,
               p.sexo,
               p.codcid,
               p.distancia,
               p.dtmarek,
               p.dtbouba,
               p.dtgumboro,
               p.dtagend,
               p.qtdneg,
               p.status,
               p.codparc,
               p.codprod,
               p.tecnico,
               p.pegador,
               p.dtdescarte,
               p.horapega,
               p.numtfv,
               p.dhpega,
               p.qtdpega,
               p.dhalter,
               p.codusu,
               p.numlfv,
               p.prioridade,
               p.codveiculo,
               p.codparctransp,
               p.codmotorista,
               p.qtdnegalt,
               p.qtdvolalt,
               p.statusvei,
               p.nunota,
               p.origpinto,
               p.qtdmortes,
               sysdate,
               p_codusu,
               v_motivo
          from ad_tsfpfv2 p
         where p.nupfv = pfv.nupfv;
    
      delete from ad_tsfpfv2 p where p.nupfv = pfv.nupfv;
    
      begin
        select * into cab from tgfcab where nunota = pfv.nunota;
        if cab.statusnota != 'L' then
          delete from tgfcab where nunota = pfv.nunota;
        else
          rollback;
          p_mensagem := 'Nota confirmada, programação não pode ser cancelada!';
          return;
        end if;
      exception
        when no_data_found then
          null;
      end;
    
      p_mensagem := 'Cancelamento Frango Vivo - ' || v_motivo;
    
    exception
      when others then
        p_mensagem := 'Erro ao cancelar a programação. Erro: ' || sqlerrm;
        return;
    end;
  
  end loop;

  p_mensagem := 'Lançamentos cancelados com sucesso!!!';

end;
/
