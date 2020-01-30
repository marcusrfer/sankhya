create or replace procedure ad_stp_fcr_recalcfechamento_sf(p_codcencus number,
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
  * Processo: Fechamneto de comiss�o do integrado - recria
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

  -- L� os dados da tabela de comiss�o do integrado
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