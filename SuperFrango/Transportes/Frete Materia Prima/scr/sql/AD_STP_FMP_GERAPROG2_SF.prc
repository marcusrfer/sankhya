create or replace procedure "AD_STP_FMP_GERAPROG2_SF"(p_codusu    number,
                                                      p_idsessao  varchar2,
                                                      p_qtdlinhas number,
                                                      p_mensagem  out varchar2) as

  cab ad_contcargto%rowtype;
  ite ad_itecargto%rowtype;

  /*
  ** Autor: M. Rangel
  ** Processo: Programa��o de carregamentos de MP
  ** Objetivo: Permitir a cria��o de lan�amentos na tela de controle de carregamentos a partir de contratos de 
  ** de compras, permitindo a sele��o dos ve�culos, tendo controle de peso e saldo dispon�vel.
  */

  type tipo_rec_dados is record(
    numcontrato number,
    codveiculo  number,
    codprod     number,
    codparc     number,
    qtdneg      float);

  type tipo_tab_dados is table of tipo_rec_dados;

  t tipo_tab_dados := tipo_tab_dados();

  v_codemp number;
  v_qtdnegtot float := 0;
  confirma boolean := false;

begin

  v_codemp := act_int_param(p_idsessao, 'CODEMP');

  if v_codemp is null then
    p_mensagem := 'N�o capturou a Empresa';
    return;
  end if;

  t.delete;

  for i in 1 .. p_qtdlinhas
  loop
  
    t.extend;
  
    t(i).codveiculo := act_int_field(p_idsessao, i, 'CODVEICULO');
  
    t(i).numcontrato := act_int_field(p_idsessao, i, 'CONTRATOCPA');
  
    t(i).codprod := act_int_field(p_idsessao, i, 'CODPROD');
  
    t(i).codparc := act_int_field(p_idsessao, i, 'PARCEIRO');
  
    if nvl(t(i).codprod, 0) = 0 or nvl(t(i).codparc, 0) = 0 then
      p_mensagem := 'Por favor, selecione um Contrato/Parceiro!';
      return;
    end if;
  
    --t(i).qtdneg := ROUND(ad_pkg_fmp.get_qtdneg_media_vei( t(i).codveiculo, t(i).codprod ));
  
    -- busca a quantidade do cadastro de categoria/ve�culo
    begin
      select nvl(v.pesomax, c.pesomax)
        into t(i).qtdneg
        from tgfvei v
        join ad_tsfcat c
          on c.codcat = v.ad_codcat
       where v.codveiculo = t(i).codveiculo;
    exception
      when others then
        p_mensagem := 'Erro ao buscar o peso do ve�culo/categoria. ' || sqlerrm;
        return;
    end;
  
    v_qtdnegtot := v_qtdnegtot + t(i).qtdneg;
  
    p_mensagem := p_mensagem || ' - ' || t(i).codparc;
  
    if t(i).codveiculo is null then
      p_mensagem := 'N�o capturou o ve�culo';
      return;
    elsif t(i).numcontrato is null then
      p_mensagem := 'Selecione um Contrato no painel superior!';
      return;
    elsif t(i).codprod is null then
      p_mensagem := 'N�o capturou o produto';
      return;
    elsif t(i).codparc is null then
      p_mensagem := 'N�o capturou o paceiro';
      return;
    end if;
  
  end loop;

  confirma := act_confirmar('Gera��o de Programa��es',
                            'Ser�o geradas ' || p_qtdlinhas || ' Ordens de Carregamento, totalizando ' ||
                             ad_get.formatanumero(v_qtdnegtot) || ' Kgs. <br>Confirma?', p_idsessao, 1);

  if not confirma then
    return;
  end if;

  for l in t.first .. t.last
  loop
  
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
    
      insert into ad_contcargto values cab;
    
    exception
      when others then
        p_mensagem := 'Erro ao inserir cabe�alho da programa��o. ' || sqlerrm;
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
      ite.codparc      := t(l).codparc;
      ite.umidade      := null;
      ite.cancelado    := 'N�O';
      ite.vlrfrete     := null;
      ite.vlrcte       := null;
      ite.nfe_ssa      := null;
      ite.nunota       := null;
      ite.nunotaorig   := null;
      ite.chavenfe     := null;
      ite.percquebra   := null;
      ite.qtdnegcompl  := null;
      ite.vlrdesconto  := null;
      ite.coddest      := null;
      ite.numcontrato  := t(l).numcontrato;
    
      -- tratativa para o parceiro e parceiro destinat�rio
      begin
      
        select a.codparcarmz
          into ite.coddest
          from tcscon c
          join ad_tcsamp a
            on c.numcontrato = a.numcontrato
         where a.dhprevret = (select max(dhprevret) from ad_tcsamp a2 where a2.numcontrato = a.numcontrato)
           and c.numcontrato = t(l).numcontrato;
      
        if ite.coddest is not null then
          ite.codparc := ite.coddest;
          ite.coddest := t(l).codparc;
        else
          ite.codparc := t(l).codparc;
        end if;
      
      exception
        when no_data_found then
          ite.coddest := null;
      end;
    
      if t(l).numcontrato is null then
        p_mensagem := 'Sem nro do contrato';
        return;
      end if;
    
      insert into ad_itecargto values ite;
    
      begin
        merge into ad_contador c
        using (select 'AD_CONTCARGTO' as tablename from dual) d
        on (c.nometab = d.tablename)
        when matched then
          update set qtdreg = qtdreg + 1
        when not matched then
          insert values ('AD_CONTCARGTO', 1);
      exception
        when others then
          null;
      end;
    
    end;
  
  end loop;

  p_mensagem := 'Foram geradas ' || t.count || ' ordens de carregamento com sucesso!';

end;
/