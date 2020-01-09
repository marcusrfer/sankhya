PL/SQL Developer Test script 3.0
21
-- Created on 22/10/2019 by MARCUS.RANGEL 
declare
 -- Local variables here
 i integer;
begin
 -- Test statements here
 delete from ad_tsfpesr r where r.codpesquisa = :codpesq;

 update ad_tsfpes p
    set p.dhrealizacao = null,
        p.status       = 'P'
  where p.codpesquisa = :codpesq;

 stp_set_atualizando('S');
 update ad_tsfavs a
    set a.dhvisita = null,
        a.status   = 'conf'
  where a.nuvisita = 1;
 stp_set_atualizando('N');

end;
1
codpesq
1
20
5
0
