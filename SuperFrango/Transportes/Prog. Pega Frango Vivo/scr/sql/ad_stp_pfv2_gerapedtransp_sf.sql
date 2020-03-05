create or replace procedure ad_stp_pfv2_gerapedtransp_sf(p_codusu    number,
                                                         p_idsessao  varchar2,
                                                         p_qtdlinhas number,
                                                         p_mensagem  out varchar2) as

 pfv            ad_tsfpfv2%rowtype;
 cab            tgfcab%rowtype;
 v_nutab        number;
 v_vlrunit      float;
 v_nunotas      varchar2(400);
 v_geraordcarga varchar2(1) := 'S';
 erro_confirma exception;
 pragma exception_init(erro_confirma, -20101);

begin
 /* Autor: Marcus Rangel
  * Processo: Programação Frango Vivo
  * Objetivo: Gerar as notas no portal de vendas de acordo com a programação de coleta do frango vivo.
 */

 ad_pkg_pfv.v_gerapedido := true;

 for i in 1 .. p_qtdlinhas
 loop
  pfv.nupfv := act_int_field(p_idsessao, i, 'NUPFV');
 
  select * into pfv from ad_tsfpfv2 where nupfv = pfv.nupfv;
 
  if pfv.numlfv is null then
  
   if act_escolher_simnao(p_titulo    => 'Geração de notas de transportes',
                          p_texto     => 'As datas de vacinação não foram preenchidas, ' ||
                                         'deseja gerar os documentos assim mesmmo?',
                          p_chave     => p_idsessao,
                          p_sequencia => 1) = 'S' then
    null;
   else
    return;
   end if;
  
  end if;
 
  if pfv.status = 'P' then
   p_mensagem := 'Verifique os agendamentos pois o status da pega ainda está ' ||
                 'como "Pendente" e precisa ser "Agendado"';
   return;
  end if;
 
  /* bloco comentado, pois já é realizado incodicionalmente por trigger
  --Begin*/
  v_geraordcarga := act_escolher_simnao(p_titulo    => 'Geração de Ordem de Carga',
                                        p_texto     => 'Deseja gerar Ordem de Carga para a(s) ' ||
                                                       'nota(s) que será(ão) gerada(s)?',
                                        p_chave     => p_idsessao,
                                        p_sequencia => 2);
  /* Exception
    When erro_confirma Then
      v_GeraOrdCarga := 'S';
  End;*/
 
  /* Retorna se status diferente de Programado ou se Nunota preenchido */
  if nvl(pfv.statusvei, 'N') = 'N' then
   p_mensagem := 'Lançamentos sem status não podem ser faturados';
   return;
  end if;
 
  if pfv.nunota is not null then
   p_mensagem := 'Pedido/Nota já gerado! Nro Único: ' || pfv.nunota;
   return;
  end if;
 
  /* Valida se os campos foram informados corretamente */
  if nvl(pfv.codparctransp, 0) = 0 or nvl(pfv.codparc, 0) = 0 or nvl(pfv.codprod, 0) = 0 or
     nvl(pfv.codveiculo, 0) = 0 then
   p_mensagem := 'Verifique se o código dos parceiros/veículos foram informados corretamente.';
   return;
  end if;
 
  /*Busca os valores na central de parametros*/
  begin
   select e.codemp, u.codcencus, n.codnat, t.codtipoper, v.codtipvenda
     into cab.codemp, cab.codcencus, cab.codnat, cab.codtipoper, cab.codtipvenda
     from ad_centparam c
     join ad_centparamemp e
       on c.nupar = e.nupar
     join ad_centparamcus u
       on c.nupar = u.nupar
     join ad_centparamnat n
       on c.nupar = n.nupar
     join ad_centparamtop t
       on c.nupar = t.nupar
     join ad_centparamtpv v
       on c.nupar = v.nupar
    where c.nupar = 7;
  exception
   when others then
    p_mensagem := 'Erro ao consutar os parâmetros na Central de Parâmetros, regra 7. ' ||
                  'Verifique se a mesma existe.';
    return;
  end;
 
  cab.codparc       := pfv.codparc;
  cab.codveiculo    := pfv.codveiculo;
  cab.codparctransp := pfv.codparctransp;
  cab.codmotorista  := pfv.codmotorista;
 
  -- valida cr nat proj
  begin
   ad_stp_valida_natcrproj_sf(p_codemp     => cab.codemp,
                              p_codtipoper => cab.codtipoper,
                              p_codnat     => cab.codnat,
                              p_codcencus  => cab.codcencus,
                              p_codproj    => 0,
                              p_tiposaida  => 0,
                              p_errmsg     => p_mensagem);
  
   if p_mensagem is not null then
    return;
   end if;
  
  end;
 
  -- valida distância entre parceiros, necessária para o cálculo do frete
  begin
   if nvl(pfv.distancia, 0) = 0 then
   
    pfv.distancia := ad_pkg_fre.distancia_entre_parceiros(38, pfv.codparc);
   
    if nvl(pfv.distancia, 0) = 0 then
     p_mensagem := 'Não foi encontrada a distância entre os parceiros, ' ||
                   'favor atualize o cadastro para continuarmos.';
     return;
    end if;
   
   end if;
  end;
 
  /*insere o cabeçalho da nota*/
  ad_set.ins_pedidocab(p_codemp      => cab.codemp,
                       p_codparc     => cab.codparc,
                       p_codvend     => 0,
                       p_codtipoper  => cab.codtipoper,
                       p_codtipvenda => cab.codtipvenda,
                       p_dtneg       => trunc(sysdate),
                       p_vlrnota     => 0,
                       p_codnat      => cab.codnat,
                       p_codcencus   => cab.codcencus,
                       p_codproj     => 0,
                       p_obs         => null,
                       p_nunota      => cab.nunota);
 
  /*Busca a tabela de preços*/
  select e.codtabfrangovivo into v_nutab from ad_tsfelt e where e.nuelt = 1;
 
  /*Busca o valor*/
  stp_obtem_preco2(p_nutab   => v_nutab,
                   p_codprod => pfv.codprod,
                   p_dtvigor => trunc(sysdate),
                   p_preco   => v_vlrunit);
 
  /*Insere o produto na nota*/
  ad_set.ins_pedidoitens(p_nunota   => cab.nunota,
                         p_codprod  => pfv.codprod,
                         p_qtdneg   => pfv.qtdneg,
                         p_vlrunit  => v_vlrunit,
                         p_vlrtotal => pfv.qtdneg * v_vlrunit,
                         p_mensagem => p_mensagem);
  if p_mensagem is not null then
   return;
  end if;
 
  -- add 04/11/2019 por M. Rangel
  -- atualizar o nro do lote do avecom 
  begin
   update tgfite ite
      set ite.ad_nloteavec = pfv.numlote
    where ite.nunota = cab.nunota
      and ite.codprod = pfv.codprod
      and ite.qtdneg = pfv.qtdneg;
  exception
   when others then
    p_mensagem := 'Erro ao atualizar o nro do lote. ' || sqlerrm;
    return;
  end;
 
  /* Busca a ordem de carga e o veiculo 
  Bloco comentado pelo fato de que já existe esse método
  que gera a ordem de carga incondicionalmente, código incluído
  no objeto TRG_UPD_TGFCAB_SF, linha 172*/
 
  begin
  
   if v_geraordcarga = 'S' then
   
    stp_keygen_tgfnum(p_arquivo => 'TGFORD',
                      p_codemp  => cab.codemp,
                      p_tabela  => 'TGFORD',
                      p_campo   => 'ORDEMCARGA',
                      p_dsync   => 0,
                      p_ultcod  => cab.ordemcarga);
   
    begin
     insert into tgford
      (codemp, ordemcarga, dtinic, codparcorig, codparctransp, codveiculo, situacao, codreg,
       roteiro, ad_tipofrete, tipcalcfrete)
     values
      (cab.codemp, cab.ordemcarga, sysdate, 38, cab.codparc, cab.codveiculo, 'A', 1010101,
       'Frete Frango Vivo', 'CIF', 1);
    exception
     when others then
      p_mensagem := 'Erro ao Inserir a Ordem de carga. ' || sqlerrm;
      return;
    end;
   
   else
    null;
   end if;
  end;
 
  /*Atualiza os campo especificos do processo na nota*/
  begin
  
   -- busca a sequencia de carga
   select count(*) + 1
     into cab.seqcarga
     from tgfcab c
    where dtneg = cab.dtneg
      and codparc = cab.codparc
      and codtipoper = cab.codtipoper
      and nunota != cab.nunota;
  
   cab.vlrfrete := ad_pkg_fre.get_vlrfrete_formula(cab.nunota,
                                                   cab.codemp,
                                                   cab.codparc,
                                                   cab.ordemcarga,
                                                   cab.codveiculo);
  
   update tgfcab c
      set c.serienota     = 5,
          c.ad_dtmarek    = pfv.dtmarek,
          c.ad_dtbouba    = pfv.dtbouba,
          c.ad_dtgumboro  = pfv.dtgumboro,
          c.ad_origpto    = pfv.origpinto,
          c.codparctransp = cab.codparctransp,
          c.codveiculo    = cab.codveiculo,
          c.codmotorista  = cab.codmotorista,
          c.cif_fob       = 'C',
          c.observacao    = 'Gerado a partir da programação nro ' || pfv.nupfv,
          c.codusuinc     = p_codusu,
          c.dtfatur       = trunc(sysdate), --Trunc(pfv.dtdescarte)/*pfv.dtagend  + 1*/,
          c.dtentsai      = trunc(sysdate), --Trunc(pfv.dtdescarte),
          c.vlrfrete      = cab.vlrfrete,
          c.ordemcarga    = cab.ordemcarga,
          c.seqcarga      = pfv.seqabate,
          c.dtval         = trunc(pfv.dtdescarte) + 3,
          c.tipfrete      = 'N'
    where nunota = cab.nunota;
  
  exception
   when others then
    p_mensagem := 'Erro ao atualizar dados no cabeçalho da nota.<br>' || sqlerrm;
    return;
  end;
 
  begin
   insert into ad_tblcmf
    (nometaborig, nuchaveorig, nometabdest, nuchavedest)
   values
    ('AD_TSFAFV', pfv.nupfv, 'TGFCAB', cab.nunota);
  exception
   when others then
    null;
  end;
 
  begin
   update ad_tsfpfv2 set nunota = cab.nunota where nupfv = pfv.nupfv;
  exception
   when others then
    p_mensagem := 'Erro ao atualizar o número único no agendamento. <br>' || sqlerrm;
    return;
  end;
 
 end loop i;

 if p_qtdlinhas = 1 then
  p_mensagem := 'Nota de Trasnporte Nro Único <a title="Abrir Tela" target="_parent" href="' ||
                ad_fnc_urlskw(p_tabela  => 'TGFCAB',
                              p_nuchave => cab.nunota,
                              p_nomedet => null,
                              p_iditem  => null) || '"><b><span style="color:blue">' || cab.nunota ||
                '</span>' || '</b></a> gerada com sucesso.';
 elsif p_qtdlinhas > 1 then
  p_mensagem := 'Foram geradas as seguintes notas de transporte: ' || v_nunotas;
 end if;

end;
/
