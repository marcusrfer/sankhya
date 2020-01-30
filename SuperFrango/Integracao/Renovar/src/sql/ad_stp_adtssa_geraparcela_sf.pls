create or replace procedure ad_stp_adtssa_geraparcela_sf(p_codusu    number,
                                                         p_idsessao  varchar2,
                                                         p_qtdlinhas number,
                                                         p_mensagem  out varchar2) as

 /*
   Autor: MARCUS.RANGEL 29/10/2019 09:53:37
   Processo: Adiantamento ; Emprestimo SSA
   Objetivo: Botão de ação "Gerar Parcelas" da tela de adiantamentos SSA. Gera as 
             parcelas das receitas e despesas dos adiantamentos
 */

 cab  ad_adtssacab%rowtype;
 conf ad_adtssaconf%rowtype;

 v_dif         float;
 v_dt          int := 1;
 v_dtvenc      date;
 v_maxparcela  int;
 v_mensagemusu varchar2(200);
 v_nufin       number;
 v_nrparcela   number := 1;
 v_recdesp     number;
 v_sequencia   int := 0;
 v_solcarencia int := 0;
 v_soljuro     int := 0;
 v_solparc     number := 0;
 v_solvalor    number := 0;

 p_vlrtot       float;
 p_vlr_jur_parc float;
 p_vlr_parc     float;
 p_vlrtot_juro  float;
 v_prazo        int;

 v_titulo   varchar(4000);
 v_mensagem varchar(4000);
 p_count    int;
 v_incluir  boolean;

begin

 if p_qtdlinhas > 1 then
  p_mensagem := 'Selecione apenas um registro por vez';
  return;
 end if;

 cab.nunico := act_int_field(p_idsessao, 1, 'NUNICO');

 -- busca dados relacionados com o lançamento
 begin
  select c.* into cab from ad_adtssacab c where c.nunico = cab.nunico;
  select max(data)
    into v_dtvenc
    from table(func_dias_uteis_mmac(trunc(sysdate), trunc(sysdate) + 10, 1, 4));
  select c.* into conf from ad_adtssaconf c where c.codigo = cab.tipo;
 exception
  when others then
   p_mensagem := 'Erro ao buscar os dados do registro selecionado (' || cab.nunico || ' - ' ||
                 cab.tipo || ' ). ' || sqlerrm;
   return;
 end;

 -- VALIDAÇÕES

 /*Naturezas 9053900,9054000,9054200,9054300 relativo a Fundo de Retenção, 
 as parcelas serão geradas todas para a mesma data, 
 neste caso não há necessidade de solicitar aprovação do financeiro*/

 ad_stp_adtssa_valida_cab_sf(p_nunico      => cab.nunico,
                             p_val_total   => case
                                               when nvl(conf.renovar, 'N') = 'S' then
                                                'N'
                                               else
                                                'S'
                                              end,
                             p_solcarencia => v_solcarencia,
                             p_solvalor    => v_solvalor,
                             p_soljuro     => v_soljuro,
                             p_solparc     => v_solparc,
                             p_mensagem    => p_mensagem);
 if p_mensagem is not null then
  return;
 end if;

 /* Se o registro esta pendente de aprovação em função de juro, nr de parcelas ou valor 
 do adiantamento envia uma requisição de aprovação para o financeiro, caso contrário 
 faz a inclusão na TGFFIN pela Stp_ADTSSAcab_Gerafin_Sf e a solicitação de aprovação 
 vai direto para o responsável. Se estiver pendente de aprovação financeira, quem vai 
 chamar a inclusão do financeiro vai ser a trigger da LIB*/

 begin
 
  if (v_soljuro = 1 or v_solparc = 1 or v_solvalor = 1 or v_solcarencia = 1) and
     conf.exigaprdesp = 'S' then
  
   if v_soljuro = 1 then
    v_mensagemusu := ' Juro';
   end if;
  
   if v_solparc = 1 then
    v_mensagemusu := case
                      when v_mensagemusu is not null then
                       v_mensagemusu || ' e Nr. de Parcelas'
                      else
                       v_mensagemusu || ' Nr. de Parcelas'
                     end;
   end if;
  
   if v_solvalor = 1 then
    v_mensagemusu := case
                      when v_mensagemusu is not null then
                       v_mensagemusu || ' e Valor '
                      else
                       v_mensagemusu || ' Valor'
                     end;
   end if;
  
   if v_solcarencia = 1 then
    v_mensagemusu := case
                      when v_mensagemusu is not null then
                       v_mensagemusu || ' e Carência '
                      else
                       v_mensagemusu || ' Carência'
                     end;
   
   end if;
  
   v_titulo   := 'Verifique dados do adiantamento!';
   v_mensagem := 'As configurações de ' || v_mensagemusu ||
                 ' estão divergentes das regras definidas para esse tipo de adiantamento.' ||
                 '\n\n<font color="#FF0000">Ao gerar a solicitação, alem da aprovação do responsável ' ||
                 'será também encaminhado uma solicitação de aprovação para o departamento financeiro' ||
                 '</font>.\n\nDeseja Continuar?';
  
   v_incluir := act_confirmar(v_titulo, v_mensagem, p_idsessao, 1);
  
  end if;
 
 end;

 -- geração das parcelas
 begin
 
  ad_pkg_var.permite_update := true;
 
  --- limpa registros existentes
  delete from ad_adtssapar where nunico = cab.nunico;
 
  update ad_adtssacab c
     set c.dhsolicitacao = null,
         c.codusufin     = null,
         c.dhaprovfin    = null,
         c.codusuapr     = null,
         c.dhaprovadt    = null,
         c.situacao      = 'E'
   where c.nunico = cab.nunico;
 
  --- determina prazo que será usado
  if conf.calculavenc = 'B' then
   v_prazo := 2;
  elsif conf.calculavenc = 'S' then
   v_prazo := 6;
  elsif conf.calculavenc = 'A' then
   v_prazo := 12;
  else
   v_prazo := 1;
  end if;
 
  --- tratativa para renovar, insere apenas a receita
  if conf.renovar = 'S' then
   v_recdesp := 1;
  else
  
   v_recdesp := case
                 when conf.parcelar = '-1' then
                  1
                 else
                  -1
                end;
  
   v_sequencia := 1;
  
   insert into ad_adtssapar
    (nunico, sequencia, nufin, dtvenc, vlrdesdob, vlrjuros, vlrtotal, recdesp, provisao, nrparcela,
     dtvencinic)
   values
    (cab.nunico, v_sequencia, null, cab.dtvenc, cab.vlrdesdob, 0, cab.vlrdesdob, v_recdesp, 'S', 1,
     cab.dtvenc);
  
   -- Inserindo a(s) contrapartida
   -- Se o tipo selecionado está configurado para parcelar receita ou despesa
   v_recdesp := case
                 when conf.parcelar = '-1' then
                  -1
                 else
                  1
                end;
   --v_sequencia := 2;
  end if;
 
  while v_nrparcela <= cab.nrparcelas
  loop
  
   -- Tipo de Cálculo M - Mensal, B - Bimestral, S - Semestral, A - Anual
   p_vlr_parc     := round(cab.vlrdesdob / cab.nrparcelas, 2);
   p_vlr_jur_parc := case
                      when nvl(cab.taxa, 0) > 0 then
                       ad_get.calculajuroprice(i             => cab.taxa,
                                               n             => cab.nrparcelas,
                                               pv            => cab.vlrdesdob,
                                               p_dtneg       => cab.dtvenc,
                                               p_dtprimvenc  => cab.dtvenc1,
                                               p_parcela     => v_nrparcela,
                                               p_tipojuro    => cab.tipojuro,
                                               p_tipocalculo => conf.calculavenc)
                      else
                       0
                     end;
  
   --- monta o dtvenc
   if v_nrparcela = 1 or cab.codnat in (9053900, 9054000, 9054200, 9054300) then
    v_dtvenc := cab.dtvenc1;
   else
    v_dtvenc := ad_get.dia_util_ultimo(add_months(cab.dtvenc1, (v_nrparcela * v_prazo) - v_prazo),
                                       'P');
   end if;
  
   v_sequencia := v_sequencia + 1;
  
   --- insert da parcela
   insert into ad_adtssapar
    (nunico, sequencia, nufin, dtvenc, vlrdesdob, vlrjuros, vlrtotal, recdesp, provisao, nrparcela,
     dtvencinic)
   values
    (cab.nunico, v_sequencia, v_nufin, v_dtvenc, round(p_vlr_parc, 2), round(p_vlr_jur_parc, 2),
     round(p_vlr_parc + p_vlr_jur_parc, 2), v_recdesp, 'S', v_nrparcela, v_dtvenc);
  
   v_dt          := v_dt + 1;
   v_nrparcela   := v_nrparcela + 1;
   v_maxparcela  := v_maxparcela + 1;
   p_vlrtot      := nvl(p_vlrtot, 0) + p_vlr_parc;
   p_vlrtot_juro := nvl(p_vlrtot_juro, 0) + p_vlr_jur_parc;
  
  end loop;
 
  ad_pkg_var.permite_update := false;
 
 exception
  when others then
   p_mensagem := 'Erro ao inserir as parcelas. <br>' || sqlerrm;
   return;
 end;

 v_dif := cab.vlrdesdob - p_vlrtot;

 if v_dif <> 0 then
  begin
   update ad_adtssapar p
      set p.vlrdesdob = p.vlrdesdob + v_dif,
          p.vlrtotal  = p.vlrtotal + v_dif
    where p.sequencia = 2
      and p.nunico = cab.nunico;
  exception
   when others then
    p_mensagem := 'Erro ao atualizar a diferença.<br>' || sqlerrm;
    return;
  end;
 
 end if;

 if conf.exigaprdesp = 'S' then
 
  p_mensagem := 'Parcelas Geradas! Verifique se as informações estão de acordo ' ||
                'com o solicitado e encaminhe o registro para aprovação ' ||
                'executando a rotina "Confirma / Solicita Aprovação"';
 
 else
  p_mensagem := 'Parcelas Geradas! Verifique se as informações estão ' ||
                'de acordo com o solicitado e finalize executando a ' ||
                'rotina "Confirma / Solicita Aprovação"';
 
 end if;

end;
/
