create or replace procedure ad_stp_ssc_solaprov_sf(p_codusu    number,
                                                   p_idsessao  varchar2,
                                                   p_qtdlinhas number,
                                                   p_mensagem  out varchar2) as

 v_itinerario varchar2(4000);
 hierarquia   varchar2(4000);
 v_confirma   boolean;
 v_link       varchar2(1000);
 ssc          ad_tsfsscc%rowtype;
 sca          ad_tsfssca%rowtype;
 sl           ad_prhsalas%rowtype;
 i            int;
begin
 /*
 ** Autor: M. Rangel
 ** Processo: Reserva sala de capacitação - RH
 ** Objetivo: Realizar a solicitação de reserva da sala
 */

 select * into ssc from ad_tsfsscc where nussc = act_int_field(p_idsessao, 1, 'NUSSC');

 select *
   into sl
   from ad_prhsalas
  where nuprh = 1
    and codsala = ssc.codsala;

 -- envio de 1 registro por vez
 if p_qtdlinhas > 1 then
  p_mensagem := 'Selecione uma solicitação por vez!!!';
  return;
 end if;

 -- valida se já foi enviada   
 if ssc.status = 'C' then
  p_mensagem := 'Solicitações Canceladas não podem ser enviadas para aprovação!';
  return;
 elsif ssc.status = 'A' then
  p_mensagem := 'Solicitação já aprovada!';
  return;
 elsif ssc.status = 'AL' then
  p_mensagem := 'Solicitação já enviada, aguardando liberação!';
  return;
 elsif ssc.status = 'R' then
  v_confirma := act_confirmar(p_titulo    => 'Reenvio de Solicitação',
                              p_texto     => 'Essa solicitação já foi reprovada uma vez, deseja reenviar a mesma?',
                              p_chave     => p_idsessao,
                              p_sequencia => 1);
 
  if not v_confirma then
   return;
  end if;
 
 end if;

 --exige tamanho mínimo do motivo
 --p_motivo := act_txt_param(p_idsessao, 'MOTIVO');

 if length(ssc.finalidade) < 50 then
  p_mensagem := 'Por favor, informe a finalidade da lotação com mais detalhes.';
  return;
 end if;

 --valida CR bloqueado
 begin
 
  p_mensagem := '<span style="color:#ff0000"><b>Solicitação não será enviada!!!</b></span>';
 
  for salcr in (select count(*) as count
                  from ad_prhsalacr cr
                  join ad_prhsalas sl
                    on sl.nuprh = cr.nuprh
                   and sl.codsala = cr.codsala
                 where cr.nuprh = 1
                   and cr.codsala = ssc.codsala
                   and cr.codcencus = ssc.codcencus
                   and nvl(cr.ativo, 'N') = 'S')
  loop
   i := salcr.count;
  end loop;
 
  if i > 0 then
   p_mensagem := p_mensagem || '<br> O CR ' || ssc.codcencus ||
                 ' está na lista de bloqueados da Central de Parametrizações!' ||
                 '<br>Entre em contato com o responsável pela lotação para maiores informações';
   return;
  else
  
   begin
    select substr(sys_connect_by_path('' || codcencus || '', ','),
                   2,
                   length(sys_connect_by_path('' || codcencus || '', ',')))
      into hierarquia
      from tsicus
     where codcencus = ssc.codcencus
       and rownum = 1
    connect by prior codcencus = codcencuspai
     start with codcencus > 0;
   exception
    when others then
     p_mensagem := 'Necessário informar o centro de resultado.';
     return;
   end;
  
   execute immediate 'Select count(*) from ad_prhsalacr where nuprh = 1 ' ||
                     'and nvl(ativo,''N'') = ''S'' and codsala = :sala and  codcencus in (' ||
                     hierarquia || ') '
   into i
   using ssc.codsala;
  
   if i > 0 then
    p_mensagem := p_mensagem || '<br>O CR do usuário pertence a uma hierarquia de CR (' ||
                  hierarquia || ') que está bloqueada na Central de Parametrizações!' ||
                  '<br>Entre em contato com o responsável pela lotação para maiores informações';
    return;
   end if;
  
  end if;
 
 end;

 -- exibe o termo de aceite
 if v_confirma is null then
 
  for link in (select *
                 from tsianx
                where nomeinstancia = 'AD_TSFPRH'
                  and nuattach = 16783)
  loop
   /*v_link := '<a href="/mge/visualizadorArquivos.mge?chaveArquivo=ARQUIVOANEXO' || Upper(link.chavearquivo) || '"' ||
   ' target="_blank">Normativa</a>';*/
   v_link := 'http://assinaturas.ssa-br.com/normas_salas.pdf';
  end loop;
 
  --v_link := '<b><u>Normativa</u></b>';
 
  v_confirma := act_confirmar('Termo de Aceite e Responsabilidades',
                              '<script>' || '
																        function open_win() 
																										{ window.open("' || v_link ||
                              '"); }
																										</script>' ||
                              'Ao confirmar o envio desta solicitação de reserva, ' ||
                              'você está afirmando que leu a' ||
                              ' normativa (download <a target="_blank"  href="' || v_link || '">' ||
                              '<span style="color:blue">aqui</span></a>)' ||
                              ' de uso dos ambientes internos e externos de capacitação oferecidos pela empresa.' ||
                              '<p>Comprometendo-se a seguir e respeitar todas as regras e normas' ||
                              ' para utilização do ambiente,' ||
                              ' assumindo inteira e total responsabilidade pelas atividades alí' ||
                              ' realizadas conforme determinado na normativa.' ||
                              ' <p><b>Aviso:</b> Esta reserva somente é para o ambiente.' ||
                              ' Os lanches deverão ser solicitados ao departamento social da empresa.' ||
                              '<p> Você afirma estar ciente do que consta na normativa e deseja continuar?',
                              p_idsessao,
                              2);
 
 end if;

 if not v_confirma then
  return;
 end if;

 -- valida prazo mínimo, capacidade e disponibilidade da solicitação e recorrências
 begin
  ad_pkg_ssc.valida_envio_reserva(ssc.nussc, p_mensagem);
 
  if (p_mensagem is not null) then
   if (p_mensagem like ('%?%')) then
    v_confirma := act_confirmar(p_titulo    => 'Reservas conflitantes',
                                p_texto     => p_mensagem,
                                p_chave     => p_idsessao,
                                p_sequencia => 3);
   
    if not v_confirma then
     return;
    end if;
   
   else
   
    return;
   
   end if;
  
  end if;
 end;

 -- insere agendamento
 begin
 
  for l in (select c.dtreserva, hrini, hrfin, c.qtdparticipantes
              from ad_tsfsscc c
             where nussc = ssc.nussc
            union
            select r.dtreserva, hrini, hrfin, r.qtdparticipantes
              from ad_tsfsscr r
             where nussc = ssc.nussc)
  loop
  
   stp_keygen_tgfnum('AD_TSFSSCA', 1, 'AD_TSFSSCA', 'NUSSCA', 0, sca.nussca);
   sca.nussc            := ssc.nussc;
   sca.codususol        := ssc.codususol;
   sca.dtsol            := ssc.dhinclusao;
   sca.dtreserva        := l.dtreserva;
   sca.hrini            := l.hrini;
   sca.hrfin            := l.hrfin;
   sca.codsala          := ssc.codsala;
   sca.tipevento        := ssc.tipevento;
   sca.motivo           := ssc.finalidade || chr(13) || ssc.obs;
   sca.status           := 'P';
   sca.dhaprovneg       := null;
   sca.qtdparticipantes := l.qtdparticipantes;
  
   insert into ad_tsfssca values sca;
  
   if v_itinerario is null then
    v_itinerario := ' nos dias <b>' || to_char(l.dtreserva, 'dd/mm/yyyy') || '</b>( das ' ||
                    fmt.hora(l.hrini) || ' às ' || fmt.hora(l.hrfin) || ' ), ';
   else
    v_itinerario := v_itinerario || to_char(l.dtreserva, 'dd/mm/yyyy') || '</b>( das ' ||
                    fmt.hora(l.hrini) || ' às ' || fmt.hora(l.hrfin) || ' ), ';
   end if;
  
  end loop;
 
  v_itinerario := substr(v_itinerario, 1, length(v_itinerario) - 1);
 
 exception
  when others then
   p_mensagem := 'Erro ao enviar a solicitação! ' || sqlerrm;
   return;
 end;

 -- atualiza data de envio na solicitação
 begin
  variaveis_pkg.v_atualizando := true;
 
  update ad_tsfsscc
     set dhenvio = sysdate,
         status  = 'AL'
   where nussc = ssc.nussc;
 exception
  when others then
   p_mensagem := 'Erro ao registrar a data de envio na solicitação. ' || sqlerrm;
   return;
 end;

 variaveis_pkg.v_atualizando := false;

 -- notifica responsável
 declare
  v_fila_mail tmdfmg.email%type;
 begin
 
  sca.codusulib := sl.codgestor;
 
  v_fila_mail := ad_get.mailusu(sl.codgestor);
 
  for m in (select codususupl
              from tsisupl
             where codusu = sl.codgestor
               and dtfim >= trunc(sysdate))
  loop
   v_fila_mail := v_fila_mail || ', ' || ad_get.mailusu(m.codususupl);
  end loop;
 
  ad_stp_gravafilabi(p_assunto  => 'Reserva de Ambiente de Treinamento/Reunião',
                     p_mensagem => 'Venho por meio deste, solicitar a reserva da sala/ambiente ' ||
                                   sl.nomesala || v_itinerario || ', com a finalidade de ' ||
                                   ssc.finalidade || '.' || chr(13) || '<br><p>Obs.: ' || ssc.obs ||
                                   chr(13) || '<br><p>Solicitante: ' ||
                                   nvl(ad_get.nomeusu(ssc.codususol, 'completo'),
                                       ad_get.nomeusu(ssc.codususol, 'resumido')) || ' - ' || 'CR: ' ||
                                   ssc.codcencus || ' - ' || ad_get.descrcencus(ssc.codcencus),
                     p_email    => v_fila_mail);
 
 end;

 p_mensagem := 'Solicitação enviada com sucesso para o responsável pelo Ambiente/Sala!';

end;
/
