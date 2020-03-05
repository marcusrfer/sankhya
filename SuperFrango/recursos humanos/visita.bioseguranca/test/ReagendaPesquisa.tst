PL/SQL Developer Test script 3.0
9
declare

begin
  update ad_tsfpes p
     set p.status    = 'R',
         p.numotivo  = 4,
         p.dhreagend = to_date('02/12/2019 08:00:00', 'dd/mm/yyyy hh24:mi:ss')
   where p.codpesquisa = 21;
end;
0
0
