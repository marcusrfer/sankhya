create or replace procedure ad_stp_avs_getdadosfunc_sf(p_codusu    number,
                                                       p_idsessao  varchar2,
                                                       p_qtdlinhas number,
                                                       p_mensagem  out varchar2) as
 p_tipocoleta varchar2(4000);
 vis          ad_tsfavs%rowtype;

begin
 /*
 * Processo: Visita sanitária / RH
 * Autor: M. Rangel
 * Objetivo: ação "buscar funcionário / candidato" que dependendo do tipo
             irá buscar os dados cadastrais do funcionário ou o do candidato
             informado de acordo com o cód da vaga.
 */

 p_tipocoleta   := act_txt_param(p_idsessao, 'TIPOCOLETA');
 vis.matfunc    := act_int_param(p_idsessao, 'MATFUNC');
 vis.codemp     := 1;
 vis.tipovisita := 'C';
 vis.dhinclusao := sysdate;
 vis.status     := 'pend';

 if p_tipocoleta = 1 then
  ad_pkg_avs.set_nova_visita_funcionario(1, vis.matfunc, 'C', null, vis.nuvisita, p_mensagem);
  if p_mensagem is not null then
   return;
  end if;
 else
 
  begin
   select can.cannome nome, ad_get.codend_pelo_nome(ce.endlogradouro) codend, ce.endnumero numend,
          ad_get.codbai_pelo_nome(ce.endbairro) codbai, ce.endcep cep, ce.endcomplemento compl,
          ad_get.codcid_pelo_nome(mun.munnome) codcid, ad_get.coduf_pelo_nome(mun.munestado) coduf,
          p.posicodlot codlot
     into vis.nomevisitado, vis.codend, vis.numend, vis.codbai, vis.cep, vis.complemento, vis.codcid,
          vis.coduf, vis.codlot
     from fpwpower.vw_recr_vaga vag
     join fpwpower.recr_participantedavaga part
       on vag.id = part.pdvidvaga
     join fpwpower.recr_candidato can
       on part.pdvidorigemparticipante = can.id
     left join fpwpower.comp_endereco ce
       on can.canidendereco = ce.id
     left join fpwpower.comp_municipio mun
       on mun.id = ce.endidmunicipio
     left join fpwpower.posicao p
       on p.posicodpos = vag.vagcodigoposicao
    where 1 = 1
         --and etp.etpdescricao like '%DOMICILIAR'
      and vag.vagcodigo = vis.matfunc;
  exception
   when no_data_found then
    p_mensagem := 'Candidato/código da vaga não encontrada!';
    return;
   when others then
    p_mensagem := 'Erro ao buscar o candidato. ' || sqlerrm;
    return;
  end;
 
  stp_keygen_tgfnum('AD_TSFAVS', 1, 'AD_TSFAVS', 'NUVISITA', 0, vis.nuvisita);
 
  begin
   select max(q.codquest)
     into vis.codquest
     from ad_tsfpesq q
    where exists (select 1 from tddins i where lower(i.nomeinstancia) like ('%tsfavs%'));
  exception
   when others then
    p_mensagem := 'Erro ao buscar o questionário! Erro: ' || sqlerrm;
    return;
  end;
 
  begin
   insert into ad_tsfavs values vis;
  exception
   when others then
    p_mensagem := 'Erro ao inserir visita. Erro: ' || '  - ' || sqlerrm;
    return;
  end;
 
 end if;
 
  ad_pkg_avs.insere_historico(vis.nuvisita, 'Visita inserida por ' ||ad_get.nomeusu(p_codusu, 'completo'));

 p_mensagem := 'Visita ' || vis.nuvisita || ' inserida com sucesso!!!';

end;
/
