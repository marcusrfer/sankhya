create or replace procedure ad_stp_fcr_fechamento_sf(p_codusu    number,
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
