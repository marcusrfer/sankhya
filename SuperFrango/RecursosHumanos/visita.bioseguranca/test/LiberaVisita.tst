PL/SQL Developer Test script 3.0
14
-- Created on 27/11/2019 by MARCUS.RANGEL 
declare 
  -- Local variables here
  i integer;
begin
  -- Test statements here
  update tsilib l
   set l.codusulib   = 216,
       l.vlrliberado = 1,
       l.dhlib       = sysdate
 where l.tabela = 'AD_TSFAVS'
   and l.nuchave = 11;
   
end;
0
0
