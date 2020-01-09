create or replace trigger ad_trg_biud_tsffcradt_sf
 before insert or update or delete on ad_tsffcradt
 for each row
declare
 -- local variables here
begin
 /*
   Autor: MARCUS.RANGEL 20/12/2019 11:18:00
   Processo: Fechamento de comissão do integrado - Recria
   Objetivo: Validações
 */

 -- atualiza a dh alter do mainform em qualquer dml
 begin
  update ad_tsffcr r
     set r.dhalter   = sysdate,
         r.codusualt = stp_get_codusulogado
   where r.codcencus = nvl(:old.codcencus, :new.codcencus)
     and r.codparc = nvl(:old.codparc, :new.codparc)
     and r.numlote = nvl(:old.numlote, :new.numlote);
 end;

end ad_trg_biud_tsffcradt_sf;
    
/
