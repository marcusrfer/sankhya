create or replace procedure ad_stp_fcr_recalcfechamento_sf(p_codcencus number,
                                                           p_codparc   number,
                                                           p_numlote   number,
                                                           p_dtref     date,
                                                           p_fcr       out ad_tsffcr%rowtype) as
 fcr ad_tsffcr %rowtype;
begin
 /*
 * Autor: M. Rangel
 * Processo: Fechamneto de comissão do integrado - recria
 * Objetivo: Procedure auxiliar que retorna os valors da tela de paramentros
 */

 stp_set_atualizando('S');

 -- Le os dados do fechamento
 select *
   into fcr
   from ad_tsffcr
  where codcencus = p_codcencus
    and codparc = p_codparc
    and numlote = p_numlote;

 -- Lê os dados da tabela de comissão do integrado
 ad_stp_fcp_getreftabela_sf(p_codcencus => fcr.codcencus,
                            p_dtref     => p_dtref,
                            p_codtab    => fcr.codtabreal,
                            p_dtreftab  => fcr.dreftabreal,
                            p_recoper   => fcr.vlrcomfixa,
                            p_recatrat  => fcr.vlrcomatrat,
                            p_recbonus  => fcr.vlrcomclist,
                            p_rectotal  => fcr.vlrunitprev,
                            p_custo     => fcr.vlrcomave);

 --fcr.vlrmesprev   := (fcr.vlrunitprev * fcr.qtdaves) / fcr.qtdmeses;
 --fcr.qtdavesliq   := fcr.qtdaves - nvl(fcr.qtdmortgranja, 0) - nvl(fcr.qtdaveselim, 0);
 fcr.qtdavesliq   := fcr.qtdaves * (1 - (fcr.percmortprev / 100));
 fcr.vlrtotreal   := (fcr.vlrunitprev * fcr.qtdavesliq);
 fcr.percparticip := (fcr.vlrtotreal / (fcr.qtdavesliq * fcr.vlrcomave)) * 100;
 -- atualiza dados no formulario principal
 begin
  update ad_tsffcr r
     set r.codtabreal   = fcr.codtabreal,
         r.dreftabreal  = fcr.dreftabreal,
         r.vlrcomfixa   = fcr.vlrcomfixa,
         r.vlrcomatrat  = fcr.vlrcomatrat,
         r.vlrcomclist  = fcr.vlrcomclist,
         r.totremave    = fcr.vlrunitprev,
         r.totremmes    = fcr.vlrunitprev / fcr.qtdmeses,
         r.vlrcomave    = fcr.vlrcomave,
         r.qtdavesliq   = fcr.qtdavesliq,
         r.percparticip = fcr.percparticip,
         r.participacao = snk_dividir((fcr.qtdavesliq * fcr.percparticip), 100),
         r.vlrtotreal   = fcr.vlrtotreal,
         r.codusualt    = stp_get_codusulogado,
         r.dhalter      = sysdate
   where r.codcencus = fcr.codcencus
     and r.codparc = fcr.codparc
     and r.numlote = fcr.numlote;
 
  select *
    into p_fcr
    from ad_tsffcr
   where codcencus = fcr.codcencus
     and codparc = fcr.codparc
     and numlote = fcr.numlote;
 
 exception
  when others then
   raise;
 end;

 stp_set_atualizando('N');

end;
/
