create or replace procedure ad_stp_fmp_geraprog2_sf(p_codusu    number,
                                                    p_idsessao  varchar2,
                                                    p_qtdlinhas number,
                                                    p_mensagem  out varchar2) as

  cab ad_contcargto%rowtype;
  ite ad_itecargto%rowtype;

  /*
  ** Autor: M. Rangel
  ** Processo: Programação de carregamentos de MP
  ** Objetivo: Permitir a criação de lançamentos na tela de controle de carregamentos a partir de contratos de 
  ** de compras, permitindo a seleção dos veículos, tendo controle de peso e saldo disponível.
  */

  type tipo_rec_dados is record(
    numcontrato number,
    codveiculo  number,
    codprod     number,
    codparc     number,
    codparcarmz number,
    qtdneg      float,
    saldo       float);

  type tipo_tab_dados is table of tipo_rec_dados;

  t tipo_tab_dados := tipo_tab_dados();

  v_codemp    number;
  v_qtdnegtot float := 0;
  confirma    boolean := false;

begin

  v_codemp := act_int_param(p_idsessao, 'CODEMP');

  if v_codemp is null then
    p_mensagem := 'Não capturou a Empresa';
    return;
  end if;

  t.delete;

  for i in 1 .. p_qtdlinhas
  loop
    t.extend;
    t(i).codveiculo := act_int_field(p_idsessao, i, 'CODVEICULO');
    t(i).numcontrato := act_int_field(p_idsessao, i, 'CONTRATOCPA');
    t(i).codprod := act_int_field(p_idsessao, i, 'PRODUTO');
    t(i).codparc := act_int_field(p_idsessao, i, 'PARCEIRO');
    t(i).codparcarmz := act_int_field(p_idsessao, i, 'CODPARCARMZ');
    t(i).saldo := act_dec_field(p_idsessao, i, 'SALDO');
  
    /* m. rangel - 31/07/20 - em stand-by, aguardando reunião com William pra definir
    if t(i).saldo <= 0 then
      p_mensagem := 'O contrato ' || t(i).numcontrato || ' não possui saldo disponível para gerar ' ||
                    'novos carregamentos! <br> Por favor, finalize o contrato através da ação ' ||
                    '<b>"Concluir Contrato Compra MP</b>".';
      return;
    end if;*/
  
    --t(i).qtdneg := ROUND(ad_pkg_fmp.get_qtdneg_media_vei( t(i).codveiculo, t(i).codprod ));
  
    -- busca a quantidade do cadastro de categoria/veículo
    begin
      select nvl(v.pesomax, c.pesomax)
        into t(i).qtdneg
        from tgfvei v
        join ad_tsfcat c
          on c.codcat = v.ad_codcat
       where v.codveiculo = t(i).codveiculo;
    exception
      when others then
        p_mensagem := 'Erro ao buscar o peso do veículo/categoria. ' || sqlerrm;
        return;
    end;
  
    v_qtdnegtot := v_qtdnegtot + t(i).qtdneg;
    --p_mensagem  := p_mensagem || ' - ' || t(i).codparc;
  
    if t(i).codveiculo is null then
      p_mensagem := 'Não capturou o veículo';
      return;
    elsif t(i).numcontrato is null then
      p_mensagem := 'Selecione um Contrato no painel superior!';
      return;
    elsif t(i).codprod is null then
      p_mensagem := 'Não capturou o produto';
      return;
    elsif t(i).codparc is null then
      p_mensagem := 'Não capturou o paceiro';
      return;
    end if;
  
  end loop;

  confirma := act_confirmar('Geração de Programações',
                            'Serão geradas ' || p_qtdlinhas || ' Ordens de Carregamento, totalizando ' ||
                             ad_get.formatanumero(v_qtdnegtot) || ' Kgs. <br>Confirma?', p_idsessao, 0);

  if not confirma then
    return;
  end if;

  for l in t.first .. t.last
  loop
  
    begin
    
      --if ite.coddest is not null then
      if t(l).codparcarmz is not null then
        ite.codparc := t(l).codparcarmz;
        ite.coddest := t(l).codparc;
      else
        ite.codparc := t(l).codparc;
        ite.coddest := null;
      end if;
    
    exception
      when no_data_found then
        ite.coddest := null;
    end;
  
    begin
    
      stp_keygen_tgfnum('AD_CONTCARGTO', v_codemp, 'AD_CONTCARGTO', 'SEQUENCIA', 0, cab.sequencia);
      cab.codveiculo       := t(l).codveiculo;
      cab.datasaidatrans   := trunc(sysdate);
      cab.datachegadapatio := null;
      cab.dataentradadesc  := null;
      cab.datafimdescarga  := null;
      cab.ordemdesc        := null;
      cab.obs              := ad_pkg_fmp.get_endereco_contrato(t(l).numcontrato);
      cab.status           := 'ABERTO';
      cab.codusu           := p_codusu;
      cab.codlocal         := null;
      cab.classificacao    := null;
      cab.codemp           := v_codemp;
      cab.datahoralanc     := sysdate;
      cab.dtaprevcarg      := sysdate;
      cab.podeabastecer    := null;
      cab.ordemcarga       := null;
      cab.lib_descarregar  := null;
      cab.emitiu_espelho   := null;
      cab.tipomov          := null;
      cab.statusvei        := 'A';
      cab.nunota           := null;
      cab.dthenvioord      := null;
      cab.analise_avulsa   := null;
      cab.dtvalidade       := sysdate + 3;
    
      insert into ad_contcargto
      values cab;
    
    exception
      when others then
        p_mensagem := 'Erro ao inserir cabeçalho da programação. ' || sqlerrm;
        return;
    end;
  
    begin
      ite.sequencia    := cab.sequencia;
      ite.ordem        := 1;
      ite.codprod      := t(l).codprod;
      ite.qtde         := t(l).qtdneg;
      ite.numnota      := null;
      ite.codusu       := p_codusu;
      ite.dataalt      := sysdate;
      ite.seqcorteprod := null;
      --ite.codparc      := t(l).codparc;
      ite.umidade     := null;
      ite.cancelado   := 'NÃO';
      ite.vlrfrete    := null;
      ite.vlrcte      := null;
      ite.nfe_ssa     := null;
      ite.nunota      := null;
      ite.nunotaorig  := null;
      ite.chavenfe    := null;
      ite.percquebra  := null;
      ite.qtdnegcompl := null;
      ite.vlrdesconto := null;
      --ite.coddest      := null;
      ite.numcontrato := t(l).numcontrato;
    
      -- tratativa para o parceiro e parceiro destinatário
      -- não comentar esse bloco, caso algum cenário seja diferente do desenhado,
      -- deverá ser analisado e proposta alguma solução alternativa
    
      if t(l).numcontrato is null then
        p_mensagem := 'Sem nro do contrato';
        return;
      end if;
    
      insert into ad_itecargto
      values ite;
    
    end;
  
  end loop;

  p_mensagem := 'Foram geradas ' || t.count || ' ordens de carregamento com sucesso!';

end;
/
