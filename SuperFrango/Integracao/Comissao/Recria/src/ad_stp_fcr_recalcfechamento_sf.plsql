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
  ad_stp_fcp_getreftabela_sf(fcr.codcencus, p_dtref, fcr.sexo, fcr.codtabreal, fcr.dreftabreal, fcr.vlrcomfixa,
                             fcr.vlrcomatrat, fcr.vlrcomclist, fcr.vlrunitprev, fcr.vlrcomave);
														 
-- Created on 02/03/2021 by MARCUS.RANGEL 
 --- tratativa para quando a tabela de preço for atualizada no período da recria
 --- calcula a média dos valores individualmente para aplicar a proporção entre os períodos
 if fcr.dreftabprev < fcr.dreftabreal then
 
  declare
   old ad_tsffcr%rowtype;
  
   m1 int;
   m2 int;
   v1 float;
   v2 float;
  begin
   m1 := round((fcr.dreftabreal - fcr.dtaloj) / 30);
   m2 := fcr.qtdmeses - m1;
  
   ad_stp_fcp_getreftabela_sf(fcr.codcencus, fcr.dtaloj, fcr.sexo, old.codtabreal, old.dreftabreal,
                              old.vlrcomfixa, old.vlrcomatrat, old.vlrcomclist, old.vlrunitprev,
                              old.vlrcomave);
  
   v1             := old.vlrcomfixa * m1;
   v2             := fcr.vlrcomfixa * m2;
   fcr.vlrcomfixa := round((v1 + v2) / fcr.qtdmeses, 5);
  
   v1              := old.vlrcomatrat * m1;
   v2              := fcr.vlrcomatrat * m2;
   fcr.vlrcomatrat := round((v1 + v2) / fcr.qtdmeses, 5);
  
   v1              := old.vlrcomclist * m1;
   v2              := fcr.vlrcomclist * m2;
   fcr.vlrcomclist := round((v1 + v2) / fcr.qtdmeses, 5);
  
   fcr.vlrunitprev := fcr.vlrcomfixa + fcr.vlrcomatrat + fcr.vlrcomclist;
  end;
 
 end if;														 

  --fcr.vlrmesprev   := (fcr.vlrunitprev * fcr.qtdaves) / fcr.qtdmeses;
  --fcr.qtdavesliq   := fcr.qtdaves - nvl(fcr.qtdmortgranja, 0) - nvl(fcr.qtdaveselim, 0);
  fcr.qtdavesliq := round(fcr.qtdaves * (1 - (fcr.percmortprev / 100)));
  fcr.vlrtotreal := round(fcr.vlrunitprev * fcr.qtdavesliq, 2);
  --fcr.percparticip := (fcr.vlrtotreal / (fcr.qtdavesliq * fcr.vlrcomave)) * 100;
  -- atualiza dados no formulario principal
  begin
    update ad_tsffcr r
       set r.codtabreal  = fcr.codtabreal,
           r.dreftabreal = fcr.dreftabreal,
           r.vlrcomfixa  = fcr.vlrcomfixa,
           r.vlrcomatrat = fcr.vlrcomatrat,
           r.vlrcomclist = fcr.vlrcomclist,
           r.totremave   = round(fcr.vlrunitprev, 4),
           r.totremmes   = round(fcr.vlrunitprev / fcr.qtdmeses, 4),
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
