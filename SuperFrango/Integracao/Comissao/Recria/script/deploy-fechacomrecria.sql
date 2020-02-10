--------------------------------------------------------
--  DDL for Trigger AD_TRG_BIUD_TSFFCRADT_SF
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE TRIGGER "SANKHYA"."AD_TRG_BIUD_TSFFCRADT_SF" 
  before insert or update or delete on ad_tsffcradt
  for each row
declare
  e varchar2(4000);
begin
  /*
    Autor: MARCUS.RANGEL 20/12/2019 11:18:00
    Processo: Fechamento de comissão do integrado - Recria
    Objetivo: Validações
  */

  if stp_get_atualizando then
    return;
  end if;
  
  if inserting then
   :new.vlrprev := round(:new.vlrprev,2);
  end if;

  if updating then
  
    :new.vlradiant := round(:new.vlradiant,2);
  
    -- permitir alterar o vencimento de adiantamentos pendentes
    if updating('DTVENC') and :new.nuacerto is null then
      return;
    end if;
  
    -- se acerto for desfeito
    if :old.nuacerto is not null and :new.nuacerto is null then
      :new.vlradiant := 0;
    end if;
  
  end if;

  if deleting then
  
    if :old.nuacerto is not null then
      e := ad_fnc_formataerro('Não é possível excluir adiantamentos que já foram gerados');
      raise_application_error(-20105, e);
    end if;
  
  end if;

  -- atualiza a dh alter do mainform em qualquer dml
  begin
    update ad_tsffcr r
       set r.dhalter   = sysdate,
           r.codusualt = stp_get_codusulogado
     where r.codcencus = nvl(:old.codcencus, :new.codcencus)
       and r.codparc = nvl(:old.codparc, :new.codparc)
       and r.numlote = nvl(:old.numlote, :new.numlote)
       and r.sexo = nvl(:old.sexo, :new.sexo);
  exception
    when others then
      e := ad_fnc_formataerro(sqlerrm);
      raise_application_error(-20105, e);
  end;

end ad_trg_biud_tsffcradt_sf;
/
ALTER TRIGGER "SANKHYA"."AD_TRG_BIUD_TSFFCRADT_SF" ENABLE;
--------------------------------------------------------
--  DDL for Trigger AD_TRG_BIUD_TSFFCR_SF
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE TRIGGER "SANKHYA"."AD_TRG_BIUD_TSFFCR_SF" 
  before insert or update or delete on ad_tsffcr
  for each row
declare
  e varchar2(4000);

begin

  /*
    Autor: MARCUS.RANGEL 20/12/2019 11:14:36
    Processo: Fechamento de Comissáo Recria
    Objetivo: Validação exigidas pelo processo
  */

  if stp_get_atualizando then
    return;
  end if;

  /*if inserting then
   null;
  end if;*/
  if updating then
  
    -- se alterando e o status continua diferente de pendente
    if :old.status != 'P' and :new.status != 'P' then
      e := ad_fnc_formataerro('Somente fechamentos com status ' ||
                              '"Pendente" podem ser alterados!');
      raise_application_error(-20105, e);
    end if;
  
    -- se limpando o nunota da tela (fk da tgfcab)
    if :old.nunota is not null and :new.nunota is null then
      :new.status := 'A';
    end if;
  
  end if;

  if deleting then
  
    if :old.status != 'P' then
      e := ad_fnc_formataerro('Somente fechamentos com status ' ||
                              '"Pendente" podem ser excluídos!');
      raise_application_error(-20105, e);
    end if;
  
  end if;

end;

/
ALTER TRIGGER "SANKHYA"."AD_TRG_BIUD_TSFFCR_SF" ENABLE;
--------------------------------------------------------
--  DDL for Procedure AD_STP_FCR_CALC_ADIANT_SF
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "SANKHYA"."AD_STP_FCR_CALC_ADIANT_SF" (p_codusu    number,
                                                      p_idsessao  varchar2,
                                                      p_qtdlinhas number,
                                                      p_mensagem  out varchar2) as

  p_dtvencini date;

  fcr ad_tsffcr%rowtype;
  i   int;
begin

  /**
  * Autor: M. rangel
  * Processo: Fechamento de Comissão - Integrado Recria
  * Objetivo: Popular a aba adiantamentos da tela de fechamento de comissão recria
  **/

  -- verifica linhas selecionadas
  if nvl(p_qtdlinhas, 0) > 1 then
    p_mensagem := 'Selecione apenas 1 lote!';
    return;
  end if;

  p_dtvencini := act_dta_param(p_idsessao, 'DTVENCINI');

  --- get dados do registro
  begin
    select *
      into fcr
      from ad_tsffcr
     where codcencus = act_int_field(p_idsessao, 1, 'CODCENCUS')
       and codparc = act_int_field(p_idsessao, 1, 'CODPARC')
       and numlote = act_int_field(p_idsessao, 1, 'NUMLOTE')
       and sexo = act_txt_field(p_idsessao, 1, 'SEXO');
  exception
    when others then
      p_mensagem := 'Erro ao buscar os dados do registro selecionado. ' ||
                    sqlerrm;
      return;
  end;

  -- valida preenchimento de campos importantes
  if nvl(fcr.codemp, 0) = 0 or fcr.dtaloj is null or nvl(fcr.qtdmeses, 0) = 0 or
     nvl(fcr.qtdaves, 0) = 0 or nvl(fcr.sexo, 'N') = 'N' then
    p_mensagem := 'As informações complementares sobre o lote, como <b>Empresa</b>, ' ||
                  '<b>Data de Alojamento, Sexo</b> e <b>Quantidade de meses</b> ' ||
                  'são necessárias para a geração das parcelas.';
    return;
  end if;

  -- valida status
  if fcr.status = 'F' then
    p_mensagem := 'Lote já finalizado!';
    return;
  end if;

  -- verifica adiantamentos gerados
  select count(nuacerto)
    into i
    from ad_tsffcradt
   where 1 = 1
     and codcencus = fcr.codcencus
     and codparc = fcr.codparc
     and numlote = fcr.numlote
     and sexo = fcr.sexo;

  -- Não possui adiantamentos
  if i = 0 then
  
    if p_dtvencini is null and fcr.status = 'P' then
      p_mensagem := 'Necessário informar o vencimento para o primeiro cálculo!';
      return;
    end if;
  
    --** método de calculo/recalculo
    ad_stp_fcr_recalcfechamento_sf(fcr.codcencus,
                                   fcr.codparc,
                                   fcr.numlote,
                                   fcr.sexo,
                                   trunc(sysdate),
                                   fcr);
  
    -- atualizar os valores previstos
    stp_set_atualizando('S');
  
    fcr.vlrmesprev  := snk_dividir(fcr.totremave * fcr.qtdavesliq, fcr.qtdmeses);
    fcr.qtdmortperm := fcr.qtdaves * (fcr.percmortprev / 100);
    begin
      update ad_tsffcr r
         set r.codtabprev  = fcr.codtabreal,
             r.dreftabprev = fcr.dreftabreal,
             r.vlrunitprev = fcr.totremave,
             r.vlrtotprev  = fcr.totremave * fcr.qtdavesliq,
             r.vlrmesprev  = fcr.vlrmesprev,
             r.pontuacao   = 100,
             r.status      = 'A',
             r.statuslote  = 'A',
             r.qtdmortperm = fcr.qtdmortperm
      /*r.codusualt   = p_codusu, sendo atualizado pela proc do recalculo
      r.dhalter     = sysdate*/
       where codcencus = fcr.codcencus
         and codparc = fcr.codparc
         and numlote = fcr.numlote
         and sexo = fcr.sexo;
    exception
      when others then
        p_mensagem := 'Erro ao atualizar os valores previstos. ' || sqlerrm;
        return;
    end;
  
    -- exclui lançamentos existentes
    begin
      delete from ad_tsffcradt
       where codcencus = fcr.codcencus
         and codparc = fcr.codparc
         and numlote = fcr.numlote
         and sexo = fcr.sexo;
    exception
      when others then
        p_mensagem := 'Erro ao excluir previsões de adiantamentos existentes' ||
                      sqlerrm;
        return;
    end;
  
    -- insere previsões de adiantamentos
    for m in 1 .. fcr.qtdmeses
    loop
    
      begin
        insert into ad_tsffcradt
          (codcencus, codparc, numlote, sexo, nuadt, desdobramento, dtref,
           vlrprev, vlradiant, nuacerto, dtvenc, dtvencini)
        values
          (fcr.codcencus, fcr.codparc, fcr.numlote, fcr.sexo, m, m,
           trunc(add_months(fcr.dtaloj, m - 1), 'fmmm'), fcr.vlrmesprev, 0, null,
           add_months(p_dtvencini, m - 1), add_months(p_dtvencini, m - 1));
      exception
        when others then
          p_mensagem := 'Erro ao inserir previsão de adiantamento. ' || sqlerrm;
          return;
      end;
    
    end loop;
    stp_set_atualizando('N');
    --Sim, possui adiantamentos gerados
  else
    -- recalcula os valores reais
    ad_stp_fcr_recalcfechamento_sf(fcr.codcencus,
                                   fcr.codparc,
                                   fcr.numlote,
                                   fcr.sexo,
                                   trunc(sysdate),
                                   fcr);
  
    -- tratativa para quando há reajuste de valor
  
    /* caso de uso
    Inicialmente foram calculadas 6 parcelas de R$ 10.000,00 cada,
    sendo que já foi feito adiantamento de 2 parcelas, ou seja, foram adiantados R$ 20.000,00.
    Ao conceder o terceiro adiantamento, em função de nova tabela o valor de cada parcela
    passou de R$ 10.000,00 para R$ 12.000,00, como o reajuste é retroativo,
    o integrado passa a ter direito a receber R$ 12.000,00 da terceira parcela,
    e a diferença do reajuste das duas parcelas anteriores, ou seja, R$ 2.000,00 da parcela 1
    e R$ 2.000,00 da parcela 2, logo a terceira parcela será gerada no valor total de R$ 16.000,00.*/
    declare
      v_vlrdif float := 0;
      d        int := 0;
    begin
      i := 0;
      for m in (select a.*, rowid
                  from ad_tsffcradt a
                 where a.codcencus = fcr.codcencus
                   and a.codparc = fcr.codparc
                   and a.numlote = fcr.numlote
                   and a.sexo = fcr.sexo
                 order by a.desdobramento)
      loop
      
        --- verifica se há alteração de valor, se houver, captura a diferença
        if m.vlrprev != fcr.vlrmesprev and m.nuacerto is not null then
          v_vlrdif := v_vlrdif + (fcr.vlrmesprev - m.vlrprev);
          continue;
        end if;
      
        -- se já possui adiantamento gerado, pula
        if m.nuacerto is not null then
          continue;
        end if;
      
        -- se possui nova data de vencimento
        --- altera o valor e a dt venc
        if p_dtvencini is not null then
          update ad_tsffcradt a
             set a.vlradiant = fcr.vlrmesprev,
                 a.dtvenc    = add_months(p_dtvencini, d)
           where a.rowid = m.rowid;
        
          d := d + 1;
          --- se não, altera só o valor
        else
          update ad_tsffcradt a
             set a.vlradiant = fcr.vlrmesprev
           where a.rowid = m.rowid;
        end if;
      
        -- corrige o valor com as diferenças retroativas
        if v_vlrdif > 0 and i = 0 then
          update ad_tsffcradt a
             set a.vlradiant = fcr.vlrmesprev + v_vlrdif
           where a.rowid = m.rowid;
          i := i + 1;
        end if;
      
      end loop;
    
    end;
  
  end if;

  /*@Nesse momento o fechamento estatrá "Em andamento", as previsões de adiantamento estarão
  geradas, de acordo com a quantidade de meses, não será possível alterar manualmente os
  valores no mainform, será possível recalcular*/
  stp_set_atualizando('N');

  p_mensagem := 'Cálculo realizado com Sucesso!!!';

end;

/
--------------------------------------------------------
--  DDL for Procedure AD_STP_FCR_FECHAMENTO_SF
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "SANKHYA"."AD_STP_FCR_FECHAMENTO_SF" (p_codusu    number,
                                                     p_idsessao  varchar2,
                                                     p_qtdlinhas number,
                                                     p_mensagem  out varchar2) as
  p_dtvenc date;
  --p_pontuacao number;
  --p_qtdmortransp  number;
  --p_qtdenvlab     number;
  --p_qtdmortgranja number;
  --p_qtdavesvda    number;
  --p_qtdaveselim   number;

  fcr ad_tsffcr%rowtype;
  adt ad_tsffcradt%rowtype;
  i   int;

begin

  /*
  * Autor: M. Rangel
  * Processo: Fechamento de comissão do integrado recria
  * Objetivo: Realizar o fechamento do lote, botão de ação homônima na tela.
              O mesmo só pode ser realizado quando apenas a última parcela estiver
              pendente de geração.
  */

  if p_qtdlinhas > 1 then
    p_mensagem := 'Selecione apenas um registro!';
    return;
  end if;

  select *
    into fcr
    from ad_tsffcr
   where codcencus = act_int_field(p_idsessao, 1, 'CODCENCUS')
     and codparc = act_int_field(p_idsessao, 1, 'CODPARC')
     and numlote = act_int_field(p_idsessao, 1, 'NUMLOTE');

  p_dtvenc          := act_dta_param(p_idsessao, 'DTVENC');
  fcr.pontuacao     := act_int_param(p_idsessao, 'PONTUACAO');
  fcr.qtdmortransp  := act_int_param(p_idsessao, 'QTDMORTRANSP');
  fcr.qtdenvlab     := act_int_param(p_idsessao, 'QTDENVLAB');
  fcr.qtdmortgranja := act_int_param(p_idsessao, 'QTDMORTGRANJA');
  fcr.qtdavesvda    := act_int_param(p_idsessao, 'QTDAVESVDA');
  fcr.qtdaveselim   := act_int_param(p_idsessao, 'QTDAVESELIM');

  begin
    select *
      into adt
      from ad_tsffcradt a
     where 1 = 1
       and a.codcencus = fcr.codcencus
       and a.codparc = fcr.codparc
       and a.numlote = fcr.numlote
          --and a.desdobramento != fcr.qtdmeses
       and a.nuacerto is null;
  exception
    when no_data_found then
      p_mensagem := 'A última parcela tem que estar pendente de adiantamento.<br>' ||
                    'Cancelando operação!';
      return;
    when too_many_rows then
      p_mensagem := 'É necessário que somente a última parcela esteja pendente.<br>' ||
                    'Cancelando a operação!';
      return;
    when others then
      raise;
  end;

  --get valores da tabela
  ad_stp_fcp_getreftabela_sf(p_codcencus => fcr.codcencus,
                             p_dtref     => adt.dtref,
                             p_sexo      => fcr.sexo,
                             p_codtab    => fcr.codtabreal,
                             p_dtreftab  => fcr.dreftabreal,
                             p_recoper   => fcr.vlrcomfixa,
                             p_recatrat  => fcr.vlrcomatrat,
                             p_recbonus  => fcr.vlrcomclist,
                             p_rectotal  => fcr.vlrunitprev,
                             p_custo     => fcr.vlrcomave);

  -- atualiza dados no formulario principal
  begin
    fcr.totremave     := fcr.vlrcomfixa + fcr.vlrcomatrat + fcr.vlrcomclist;
    fcr.qtdavesliq    := (fcr.qtdaves - fcr.qtdmortransp - fcr.qtdenvlab);
    fcr.totavestransf := fcr.qtdavesliq -
                         (fcr.qtdmortgranja + fcr.qtdavesvda + fcr.qtdaveselim);
    fcr.vlrtotreal    := fcr.totremave * fcr.qtdavesliq;
  
    stp_set_atualizando('S');
    update ad_tsffcr r
       set r.codtabreal    = fcr.codtabreal,
           r.dreftabreal   = fcr.dreftabreal,
           r.vlrcomfixa    = fcr.vlrcomfixa,
           r.vlrcomatrat   = fcr.vlrcomatrat,
           r.vlrcomave     = fcr.vlrcomave,
           r.pontuacao     = fcr.pontuacao,
           r.vlrcomclist   = fcr.vlrcomclist * (fcr.pontuacao / 100),
           r.totremave     = fcr.totremave,
           r.totremmes     = fcr.totremave / r.qtdmeses,
           r.qtdavesliq    = fcr.qtdavesliq,
           r.qtdmortgranja = fcr.qtdmortgranja,
           r.qtdavesvda    = fcr.qtdavesvda,
           r.qtdaveselim   = fcr.qtdaveselim,
           r.qtdenvlab     = fcr.qtdenvlab,
           r.qtdmortransp  = fcr.qtdmortransp,
           r.totavestransf = fcr.totavestransf,
           r.vlrtotreal    = fcr.vlrtotreal,
           r.vlrmedreal    = fcr.vlrtotreal / fcr.qtdmeses,
           r.statuslote    = 'F',
           r.codusualt     = p_codusu,
           r.dhalter       = sysdate
     where r.codcencus = fcr.codcencus
       and r.codparc = fcr.codparc
       and r.numlote = fcr.numlote;
    stp_set_atualizando('S');
  exception
    when others then
      p_mensagem := 'Erro ao atualizar o formulário principal. ' || sqlerrm;
      return;
  end;

  <<valida_venc>>
  begin
    if p_dtvenc is not null and to_char(p_dtvenc, 'd') in (1, 7) then
      p_dtvenc := p_dtvenc + 1;
      goto valida_venc;
    end if;
  end;

  begin
    update ad_tsffcradt a
       set a.vlradiant = fcr.vlrtotreal - fcr.vlrtotadiant,
           a.dtvenc    = nvl(p_dtvenc, a.dtvenc)
     where a.codcencus = fcr.codcencus
       and a.codparc = fcr.codparc
       and a.numlote = fcr.numlote
       and a.desdobramento = fcr.qtdmeses;
  exception
    when others then
      p_mensagem := 'Erro ao atualizar os dados do adiantamento. ' || sqlerrm;
      return;
  end;

  p_mensagem := 'Lote de Comissão fechado com sucesso!!!';

end;

/
--------------------------------------------------------
--  DDL for Procedure AD_STP_FCR_GERA_ADIANT_SF
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "SANKHYA"."AD_STP_FCR_GERA_ADIANT_SF" (p_codusu    number,
                                                      p_idsessao  varchar2,
                                                      p_qtdlinhas number,
                                                      p_mensagem  out varchar2) as

  fcr        ad_tsffcr%rowtype;
  cfg        ad_adtssaconf%rowtype;
  fci        ad_tsffciconf%rowtype;
  fin        tgffin%rowtype;
  fre        tgffre%rowtype;
  v_dtreftab date;
  v_confirma boolean;
  v_gerou    int := 0;

  type linhas_adiant is table of ad_tsffcradt%rowtype;
  adt linhas_adiant := linhas_adiant();

begin
  /*
  * Autor: M. Rangel
  * Processo: Fechamento de comissão Recria
  * Objetivo: Validação e geração dos adiantamentos. Ação "Gerar adiantamento"
              da aba adiantamentos da tela de fechamento recria.
  */

  /*
   a rotina gera sequencialmente o adiantamento, ordenado pela pk, logo, não é
   necessário que o usuário selecione alguma linha, sempre seguirá a ordem da pk
  */

  -- popula com as informações do fechamento

  select *
    into fcr
    from ad_tsffcr f
   where f.codcencus = act_int_field(p_idsessao, 0, 'MASTER_CODCENCUS')
     and f.codparc = act_int_field(p_idsessao, 0, 'MASTER_CODPARC')
     and f.numlote = act_int_field(p_idsessao, 0, 'MASTER_NUMLOTE')
     and f.sexo = act_txt_field(p_idsessao, 0, 'MASTER_SEXO');

  if fcr.status = 'P' then
    p_mensagem := 'Necessário calcular o adiantamento antes!';
    return;
  end if;

  -- armazena as previsões de adiantmento
  select *
    bulk collect
    into adt
    from ad_tsffcradt a
   where a.codcencus = fcr.codcencus
     and a.codparc = fcr.codparc
     and a.numlote = fcr.numlote
     and a.sexo = fcr.sexo
   order by a.nuadt --dtvenc
  ;

  -- percorre os adiantamentos
  for l in adt.first .. adt.last
  loop
  
    -- ignora os registros  com nufin gerado
    if adt(l).nuacerto is not null then
      continue;
    else
    
      if nvl(adt(l).vlradiant, 0) = 0 then
        adt(l).vlradiant := adt(l).vlrprev;
      end if;
    
      -- busca os dados da tela de parametros do Fech. Com. Integrado
      -- cabe um  exception pra tratar a msg de config not found --
      ad_pkg_fci.get_config(adt(l).dtref, fci);
      -- busca set de parametros
    
      -- busca a ultima data de atualização de tabela
      begin
        select ref.dtref
          into v_dtreftab
          from ad_tsftcp tab
          join ad_tsftcpcus cus
            on cus.codtabpos = tab.codtabpos
          join ad_tsftcpref ref
            on ref.codtabpos = tab.codtabpos
         where cus.codcencus = fcr.codcencus
           and tab.sexo = fcr.sexo
           and ref.dtref = (select max(dtref)
                              from ad_tsftcpref r2
                             where r2.codtabpos = tab.codtabpos
                               and r2.dtref <= adt(l).dtref);
      exception
        when no_data_found then
          p_mensagem := 'Tabela não encontrada para o CR ' || fcr.codcencus ||
                        ' na referência ' || adt(l).dtref;
          return;
      end;
    
      --- se data do ultimo calculo do lote for menor que a ultima atualização da tabela
      if fcr.dreftabreal < v_dtreftab then
        v_confirma := act_confirmar('Geração de Adiantamentos',
                                    'Existe uma atualização de tabela, indicando ' ||
                                    'que o lote não foi recalculado, deseja recalcular ' ||
                                    'antes de gerar o adiantamento?',
                                    p_idsessao,
                                    0);
        if v_confirma then
          -- recalcula o lote
          ad_stp_fcr_recalcfechamento_sf(fcr.codcencus,
                                         fcr.codparc,
                                         fcr.numlote,
                                         fcr.sexo,
                                         adt(l).dtref,
                                         fcr);
        
          adt(l).vlradiant := ((fcr.totremave * fcr.qtdaves) / fcr.qtdmeses);
        
          --calcular a diferença retroativa de valores
          declare
            vlrdiff float := 0;
            vlrnovo float := adt(l).vlradiant;
          begin
            for val in (select vlrprev, vlradiant
                          from ad_tsffcradt
                         where codcencus = fcr.codcencus
                           and codparc = fcr.codparc
                           and numlote = fcr.numlote
                           and sexo = fcr.sexo
                           and dtref < adt(l).dtref)
            loop
              vlrdiff := vlrdiff + (vlrnovo - val.vlradiant);
            end loop;
            adt(l).vlradiant := vlrnovo + abs(vlrdiff);
          end;
        
        else
          p_mensagem := 'Efetue o recalculo do lote ou a correção da tabela para ' ||
                        'gerar a parcela do adiantamento.';
          return;
        end if;
      
      end if;
    
      -- busca os dados da tela de parametros para adiantamentos ssa
      select *
        into cfg
        from ad_adtssaconf c
       where c.codigo = fci.codconfemprec;
    
    end if;
  
    -- se for a última parcela
    if l = fcr.qtdmeses and fcr.statuslote != 'F' then
      p_mensagem := 'A última parcela do adiantamento só poderá ser gerada ' ||
                    'após a realização da ação de fechamento, pois é necessário ' ||
                    'obter o valor residual dos adiantamentos';
      return;
    end if;
  
    <<valida_venc>>
    begin
      if to_char(adt(l).dtvenc, 'd') in (1, 7) then
        adt(l).dtvenc := adt(l).dtvenc + 1;
        goto valida_venc;
      end if;
    end;
  
    -- confirmação de geração da parcela X
    v_confirma := act_confirmar('Geração de Adiantamentos',
                                'Confirma a geração da parcela ' || l ||
                                ' no valor de ' ||
                                fmt.valor_moeda(adt(l).vlradiant) ||
                                ' com vencimento para ' ||
                                to_char(adt(l).dtvenc, 'dd/MM/yyyy'),
                                p_idsessao,
                                1);
  
    if not v_confirma then
      return;
    end if;
  
    -- inicio da geração do adiantamento
    begin
    
      stp_keygen_tgfnum('TGFFRE', 1, 'TGFFRE', 'NUACERTO', 0, fre.nuacerto);
      fre.sequencia := 0;
    
      -- prepara para inserir uma receita e uma despesa
      for rec_desp in -1 .. 1
      loop
      
        if rec_desp = 0 then
          continue;
        end if;
      
        stp_keygen_nufin(p_ultcod => fin.nufin);
      
        if rec_desp = 1 then
          fin.codtipoper := cfg.codtipoperrec;
          fin.codtiptit  := cfg.tipotitrec;
          fin.provisao   := 'N';
          fin.dtvenc     := adt(adt.last).dtvenc; -- se receita gera para o fim do processo
          fin.dtvencinic := adt(l).dtvenc;
        else
          fin.codtipoper := cfg.codtipoperdesp;
          fin.codtiptit := 4;
          fin.provisao := 'S';
          adt(l).nuacerto := fre.nuacerto;
          fin.dtvenc := adt(l).dtvenc;
          fin.dtvencinic := adt(l).dtvenc;
        end if;
      
        fin.dhtipoper := ad_get.maxdhtipoper(fin.codtipoper);
        fin.historico := 'Ref. fechamento comissão recriar - lote ' || adt(l).numlote || '. ' ||
                         'Parcela ' || adt(l).desdobramento || ' de ' ||
                         adt.count;
      
        insert into tgffin
          (nufin, codemp, numnota, dtneg, desdobramento, dhmov, dtvenc,
           dtvencinic, codparc, codtipoper, dhtipoper, codctabcoint, codnat,
           codcencus, codproj, codtiptit, vlrdesdob, vlrjuronegoc, recdesp,
           provisao, origem, codusu, dtalter, desdobdupl, historico, codbco,
           ad_variacao)
        values
          (fin.nufin, fcr.codemp, fcr.numlote, trunc(sysdate),
           adt(l).desdobramento, sysdate, fin.dtvenc, fin.dtvencinic,
           fcr.codparc, fin.codtipoper, fin.dhtipoper, cfg.codctabcoint,
           fci.codnatrecria, fci. codcradiant, 0, fin.codtiptit,
           adt(l).vlradiant, 0, rec_desp, fin.provisao, 'F', p_codusu, sysdate,
           'ZZ', fin.historico, 1, 'comrecria');
      
        fre.sequencia := fre.sequencia + 1;
      
        insert into tgffre
          (nuacerto, nunota, nufin, nufinorig, codusu, dhalter, tipacerto,
           sequencia, nuedi)
        values
          (fre.nuacerto, null, fin.nufin, null, p_codusu, sysdate, 'A',
           fre.sequencia, null);
      
        update tgffin f
           set f.nucompens = fre.nuacerto,
               f.numdupl   = fre.nuacerto
         where nufin = fin.nufin;
      
        -- se exige aprovação e é a despesa do adiantmento
        if cfg.exigaprdesp = 'S' and rec_desp = -1 then
          -- insere liberação
          ad_set.ins_liberacao('TGFFIN',
                               fin.nufin,
                               1035,
                               adt(l).vlradiant,
                               cfg.codusuapr,
                               'Ref. Com. Recria, lote ' || fcr.numlote ||
                               ', parcela ' || to_char(adt(l).desdobramento) ||
                               ' de ' || adt.count,
                               p_errmsg => p_mensagem);
        
          if p_mensagem is not null then
            return;
          end if;
        
        end if;
      
      end loop;
      -- loop do financeiro
    
      begin
        -- atualiza o total do adiantamento gerado no mainform
        stp_set_atualizando('S');
      
        select sum(vlradiant)
          into fcr.vlrtotadiant
          from ad_tsffcradt
         where codcencus = fcr.codcencus
           and codparc = fcr.codparc
           and numlote = fcr.numlote
           and sexo = fcr.sexo;
      
        fcr.vlrtotreal := fcr.totremave * fcr.qtdavesliq;
      
        update ad_tsffcr f
           set f.vlrtotreal   = fcr.vlrtotreal,
               f.vlrtotadiant = fcr.vlrtotadiant + adt(l).vlradiant,
               f.saldo = case
                           when nvl(f.vlrtotreal, 0) > 0 then
                            fcr.vlrtotreal - fcr.vlrtotadiant
                         --(fcr.vlrtotadiant + adt(l).vlradiant)
                           else
                            0
                         end
         where f.codcencus = fcr.codcencus
           and f.codparc = fcr.codparc
           and f.numlote = fcr.numlote
           and f.sexo = fcr.sexo;
      
        -- devolve o nuacerto gerado
        update ad_tsffcradt a
           set a.nuacerto  = fre.nuacerto,
               a.vlradiant = adt(l).vlradiant
         where a.codcencus = fcr.codcencus
           and a.codparc = fcr.codparc
           and a.numlote = fcr.numlote
           and a.nuadt = adt(l).nuadt
           and a.sexo = fcr.sexo;
      
        stp_set_atualizando('N');
      exception
        when others then
          p_mensagem := 'Erro ao atualizar o número único do adiantamento. ' ||
                        sqlerrm;
          return;
      end;
    
    end;
    -- fim da geração do adiantamento
  
    exit;
  
  end loop;

  p_mensagem := 'Adiantamento gerado com sucesso!!!';

end;

/
--------------------------------------------------------
--  DDL for Procedure AD_STP_FCR_GERA_NOTA_SF
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "SANKHYA"."AD_STP_FCR_GERA_NOTA_SF" (p_codusu    number,
                                                    p_idsessao  varchar2,
                                                    p_qtdlinhas number,
                                                    p_mensagem  out varchar2) as

  fcr ad_tsffcr%rowtype;
  cfg ad_tsffciconf%rowtype;
  mgn ad_tsfmgn%rowtype;

  v_nufin  number;
  v_dtvenc date;
  v_modelo int;
  i        int;
begin

  /*
  * Autor: M. Rangel
  * Processo: Fechamento da comissão da Recria
  * Objetivo: Ação "Gerar notas" da tela de fechamento da comissão da recria.
              Tem por objetivo permitir a criação dos documentos exigidos pelo
              processo, considerando a questão de dentro ou fora da UF GO, permitindo
              escolher entre gerar a nota de compra ou o pedido de compra (no caso do PR).
              As informações para a geração da nota, como top, natureza, estão na tela de
              modelos para geração de notas (TSFMGN).
  */

  if p_qtdlinhas > 1 then
    p_mensagem := 'Selecione apenas 1 registro.';
    return;
  end if;

  select *
    into fcr
    from ad_tsffcr a
   where a.codcencus = act_int_field(p_idsessao, 1, 'CODCENCUS')
     and a.codparc = act_int_field(p_idsessao, 1, 'CODPARC')
     and a.numlote = act_int_field(p_idsessao, 1, 'NUMLOTE');

  -- valida nunota
  if fcr.nunota is not null then
    p_mensagem := 'Comissão já possui nota gerada!';
    return;
  end if;

  -- valida se adiantamentos estão gerados
  select count(*)
    into i
    from ad_tsffcradt a
   where a.codcencus = fcr.codcencus
     and a.codparc = fcr.codparc
     and a.numlote = fcr.numlote
     and a.nuacerto is null;

  if i > 0 then
    p_mensagem := 'Para a geração das notas, é necessário que todos os ' ||
                  'adiantamentos tenham sido gerados';
    return;
  end if;

  -- busca set de parametros
  ad_pkg_fci.get_config(trunc(sysdate), cfg);

  /*begin
   select *
     into conf
     from ad_tsffciconf c
    where c.dtvigor = (select max(dtvigor)
                         from ad_tsffciconf c2
                        where c2.nuconf = c.nuconf
                          and c2.dtvigor <= sysdate);
  exception
   when no_data_found then
    p_mensagem := 'Erro ao buscar as configuração da ' || 'tela de parâmetros. ' || sqlerrm;
    return;
  end;*/

  if ad_get.ufparcemp(fcr.codparc, 'P') = ad_get.ufparcemp(fcr.codemp, 'E') then
    v_modelo := cfg.numodcparec;
  else
    v_modelo := cfg.numodpcarec;
  end if;

  begin
    select * into mgn from ad_tsfmgn where numodelo = v_modelo;
  exception
    when others then
      raise;
  end;

  begin
    -- insere cabeçalho
    ad_set.ins_pedidocab(p_codemp      => fcr.codemp,
                         p_codparc     => fcr.codparc,
                         p_codvend     => mgn.codvend,
                         p_codtipoper  => mgn.codtipoper,
                         p_codtipvenda => mgn.codtipvenda,
                         p_dtneg       => trunc(sysdate),
                         p_vlrnota     => fcr.vlrtotreal,
                         p_codnat      => mgn.codnat,
                         p_codcencus   => fcr.codcencus,
                         p_codproj     => 0,
                         p_obs         => 'Fech. Com. Recria - nº lote: ' ||
                                          fcr.numlote,
                         p_nunota      => fcr.nunota);
    -- insere item
    ad_set.ins_pedidoitens(p_nunota   => fcr.nunota,
                           p_codprod  => mgn.codprod,
                           p_qtdneg   => fcr.participacao,
                           p_codvol   => mgn.codvol,
                           p_codlocal => mgn.codlocal,
                           p_controle => null,
                           p_vlrunit  => fcr.vlrcomave,
                           p_vlrtotal => fcr.vlrtotreal,
                           p_mensagem => p_mensagem);
  
    if p_mensagem is not null then
      return;
    end if;
  
    begin
    
      -- try dia do vencimento fds
      v_dtvenc := add_months(sysdate, 12);
      <<check_dia_vencto>>
      begin
        if to_number(to_char(v_dtvenc, 'd')) in (1, 7) then
          v_dtvenc := v_dtvenc + 1;
          goto check_dia_vencto;
        end if;
      end;
    
      ad_set.ins_financeiro(p_codemp     => fcr.codemp,
                            p_numnota    => 0,
                            p_dtneg      => trunc(sysdate),
                            p_dtvenc     => v_dtvenc,
                            p_codparc    => fcr.codparc,
                            p_top        => mgn.codtipoper,
                            p_contabanco => mgn.codctabcoint,
                            p_codnat     => mgn.codnat,
                            p_codcencus  => fcr.codcencus,
                            p_codproj    => 0,
                            p_codtiptit  => mgn.codtiptit,
                            p_origem     => 'E',
                            p_nunota     => fcr.nunota,
                            p_valor      => fcr.vlrtotreal,
                            p_nufin      => v_nufin,
                            p_errmsg     => p_mensagem);
    
      if p_mensagem is not null then
        return;
      end if;
    
    exception
      when others then
        p_mensagem := sqlerrm;
        return;
    end;
  
    -- atualiza dados na origem
  
    stp_set_atualizando('S');
  
    begin
      update ad_tsffcr r
         set r.nunota     = fcr.nunota,
             r.status     = 'F',
             r.statusnota = 'A'
       where r.codcencus = fcr.codcencus
         and r.codparc = fcr.codparc
         and r.numlote = fcr.numlote;
    exception
      when others then
        p_mensagem := sqlerrm;
        return;
    end;
  
    -- confirma pedido de compra
    if nvl(mgn.confauto, 'N') = 'S' then
    
      if act_confirmar('Confirmação de Nota',
                       'Deseja confirmar a nota Gerada?',
                       p_idsessao,
                       1) then
      
        stp_confirmanota_java_sf(fcr.nunota);
      
        --select * into cab from tgfcab where nunota = fcr.nunota;
      
        -- atualiza informações na origem
        update ad_tsffcr r
           set r.statusnota = 'L',
               r.dhalter    = sysdate,
               r.codusualt  = p_codusu
         where nunota = fcr.nunota;
      
      end if;
    
    end if;
  
    stp_set_atualizando('N');
  
  end;

  p_mensagem := 'Nota nº único ' ||
                '<a title="Clique aqui" target="_parent" href="' ||
                ad_fnc_urlskw('TGFCAB', fcr.nunota) || '">' || fcr.nunota ||
                '</a>' || ' gerada com sucesso!';

end;

/
--------------------------------------------------------
--  DDL for Procedure AD_STP_FCR_RECALCFECHAMENTO_SF
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "SANKHYA"."AD_STP_FCR_RECALCFECHAMENTO_SF" (p_codcencus number,
                                                           p_codparc   number,
                                                           p_numlote   number,
                                                           p_sexo      varchar2,
                                                           p_dtref     date,
                                                           p_fcr       out ad_tsffcr%rowtype) as
  fcr ad_tsffcr %rowtype;
  cursor c_fcr is(
    select *
      from ad_tsffcr
     where codcencus = p_codcencus
       and codparc = p_codparc
       and numlote = p_numlote
       and sexo = p_sexo);
begin
  /*
  * Autor: M. Rangel
  * Processo: Fechamneto de comissão do integrado - recria
  * Objetivo: Procedure auxiliar que retorna os valors da tela de paramentros
  */

  stp_set_atualizando('S');

  -- Le os dados do fechamento
  /*select *
   into fcr
   from ad_tsffcr
  where codcencus = p_codcencus
    and codparc = p_codparc
    and numlote = p_numlote
    and sexo = p_sexo;*/

  open c_fcr;
  fetch c_fcr
    into fcr;

  -- Lê os dados da tabela de comissão do integrado
  ad_stp_fcp_getreftabela_sf(p_codcencus => fcr.codcencus,
                             p_dtref     => p_dtref,
                             p_sexo      => fcr.sexo,
                             p_codtab    => fcr.codtabreal,
                             p_dtreftab  => fcr.dreftabreal,
                             p_recoper   => fcr.vlrcomfixa,
                             p_recatrat  => fcr.vlrcomatrat,
                             p_recbonus  => fcr.vlrcomclist,
                             p_rectotal  => fcr.vlrunitprev,
                             p_custo     => fcr.vlrcomave);

  --fcr.vlrmesprev   := (fcr.vlrunitprev * fcr.qtdaves) / fcr.qtdmeses;
  --fcr.qtdavesliq   := fcr.qtdaves - nvl(fcr.qtdmortgranja, 0) - nvl(fcr.qtdaveselim, 0);
  fcr.qtdavesliq := fcr.qtdaves * (1 - (fcr.percmortprev / 100));
  fcr.vlrtotreal := (fcr.vlrunitprev * fcr.qtdavesliq);
  --fcr.percparticip := (fcr.vlrtotreal / (fcr.qtdavesliq * fcr.vlrcomave)) * 100;
  -- atualiza dados no formulario principal
  begin
    update ad_tsffcr r
       set r.codtabreal  = fcr.codtabreal,
           r.dreftabreal = fcr.dreftabreal,
           r.vlrcomfixa  = fcr.vlrcomfixa,
           r.vlrcomatrat = fcr.vlrcomatrat,
           r.vlrcomclist = fcr.vlrcomclist,
           r.totremave   = fcr.vlrunitprev,
           r.totremmes   = fcr.vlrunitprev / fcr.qtdmeses,
           r.vlrcomave   = fcr.vlrcomave,
           r.qtdavesliq  = fcr.qtdavesliq,
           --r.percparticip = fcr.percparticip,
           --r.participacao = snk_dividir((fcr.qtdavesliq * fcr.percparticip), 100),
           r.vlrtotreal = fcr.vlrtotreal,
           r.codusualt  = stp_get_codusulogado,
           r.dhalter    = sysdate
     where r.codcencus = fcr.codcencus
       and r.codparc = fcr.codparc
       and r.numlote = fcr.numlote
       and r.sexo = fcr.sexo;
  
    close c_fcr;
  
    /*select *
     into p_fcr
     from ad_tsffcr
    where codcencus = fcr.codcencus
      and codparc = fcr.codparc
      and numlote = fcr.numlote;*/
    open c_fcr;
    fetch c_fcr
      into p_fcr;
  
    close c_fcr;
  
  exception
    when others then
      raise;
  end;

  stp_set_atualizando('N');

end;

/
