create or replace procedure ad_stp_adtssa_valida_cab_sf(p_nunico      in number,
                                                        p_val_total   in varchar2,
                                                        p_solcarencia out int,
                                                        p_solvalor    out int,
                                                        p_soljuro     out int,
                                                        p_solparc     out int,
                                                        p_mensagem    out varchar2) as

 cab       ad_adtssacab%rowtype;
 conf      ad_adtssaconf%rowtype;
 v_dtvenc  date;
 v_totrec  float;
 v_totdesp float;

begin

 select c.* into cab from ad_adtssacab c where c.nunico = p_nunico;

 select max(data) into v_dtvenc from table(func_dias_uteis_mmac(trunc(sysdate), trunc(sysdate) + 10, 1, 4));

 select c.* into conf from ad_adtssaconf c where c.codigo = cab.tipo;

 -- Test statements here
 if cab.situacao not in ('E') then
  p_mensagem := 'Registro com situação diferente de <i>Elaborando</i>.';
  return;
 end if;

 --- data de vencimento
 if cab.dtvenc <= trunc(sysdate) + 1 then
  p_mensagem := 'Data informada no campo "Débito / Crédito em" inválida';
  return;
 end if;

 if v_dtvenc > cab.dtvenc then
  p_mensagem := 'Altere a data informada no campo "Débito / Crédito em"' ||
                'A solicitação deve ser para pelo menos 3 dias uteis a partir da solicitação.';
  return;
 end if;

 -- valor total
 if p_val_total = 'S' then
 
  select sum(decode(p.recdesp, 1, p.vlrdesdob, 0)),
         sum(decode(p.recdesp, -1, p.vlrdesdob, 0))
    into v_totrec,
         v_totdesp
    from ad_adtssapar p
   where p.nunico = cab.nunico;
 
  if cab.vlrdesdob <> v_totrec then
   p_mensagem := 'A soma da coluna "Vlr Desdobramento" para Receitas da aba parcelas não bate com o "Valor do Empréstimo"';
   return;
  end if;
 
  if cab.vlrdesdob <> v_totdesp then
   p_mensagem := 'A soma da coluna "Vlr Desdobramento" para Despesas da aba parcelas não bate com o "Valor do Empréstimo"';
   return;
  end if;
 end if;

 -- Verifica se exige aprovação e se informou CR Aprovador
 if conf.exigaprdesp = 'S' and nvl(cab.codcencusresp, 0) = 0 then
  p_mensagem := 'Informe o CR responsável pela aprovação da despesa';
  return;
 end if;

 -- Verifica se a carencia é maior que o permitido
 if nvl(conf.carencia, 0) > 0 and nvl(conf.carencia, 0) < (cab.dtvenc1 - cab.dtvenc) and
    conf.carenciamaior = 'B' then
  p_mensagem := 'Carência de vencimento da primeira parcela maior que o permitido para o tipo de processo selecionado!';
  return;
 elsif nvl(conf.carencia, 0) > 0 and nvl(conf.carencia, 0) < (cab.dtvenc1 - cab.dtvenc) and
       conf.carenciamaior = 'S' and conf.carenciamaior = 'S' and
       cab.codnat not in (9053900, 9054000, 9054200, 9054300) then
  p_solcarencia := 1;
  return;
 end if;

 -- Verifica se o valor concedido esta dentro do limite permitido
 if nvl(conf.vlrmax, 1) < nvl(cab.vlrdesdob, 1) and conf.vlrmaior = 'B' then
  p_mensagem := 'Valor máximo nesse tipo de processo não pode ser superior a ' ||
                fmt.valor_moeda(conf.vlrmax);
  return;
 elsif nvl(conf.vlrmax, 1) < nvl(cab.vlrdesdob, 1) and conf.vlrmaior = 'S' and
       cab.codnat not in (9053900, 9054000, 9054200, 9054300) then
  p_solvalor := 1;
  return;
 end if;

 -- Verifica se o número de parcelas informado esta dentro do limite permitido
 if nvl(conf.parcela, 12) < nvl(cab.nrparcelas, 1) and conf.parcelamaior = 'B' then
  p_mensagem := 'Número de parcelas nesse tipo de processo não pode ser superior a ' || conf.parcela;
  return;
 elsif nvl(conf.parcela, 12) < nvl(cab.nrparcelas, 1) and conf.parcelamaior = 'S' and
       cab.codnat not in (9053900, 9054000, 9054200, 9054300) then
  p_solparc := 1;
  return;
 end if;

 -- Verifica se o juro informado esta dentro do limite permitido
 if nvl(conf.juro, 0) > 0 and nvl(conf.juro, 0) > nvl(cab.taxa, 0) and conf.juromenor = 'B' then
  p_mensagem := 'Juro cobrado nesse tipo de processo não pode ser inferior a ' || conf.juro || '%';
  return;
 elsif nvl(conf.juro, 0) > 0 and nvl(conf.juro, 0) > nvl(cab.taxa, 0) and conf.juromenor = 'S' and
       cab.codnat not in (9053900, 9054000, 9054200, 9054300) then
  p_soljuro := 1;
  return;
 end if;

 -- FIM VALIDAÇÕES
end ad_stp_adtssa_valida_cab_sf;
/
