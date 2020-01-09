PL/SQL Developer Test script 3.0
29
declare
  pes  ad_tsfpes%rowtype;
  resp ad_tsfpesr%rowtype;
  stmt varchar2(4000);
begin

  for l in (select * from ad_tsfpesr where codpesquisa = 2)
  loop
    resp.codpesquisa := 4;
    resp.nuseqresp   := l.nuseqresp;
    resp.codquest    := l.codquest;
    resp.codperg     := l.codperg;
    resp.tiporesp    := l.tiporesp;
    resp.resposta    := l.resposta;
    resp.obs         := l.obs;
    resp.anexo       := l.anexo;
  
    insert into ad_tsfpesr values resp;
  
  end loop;

  update ad_tsfpes p
     set status         = 'F',
         p.dhrealizacao = sysdate,
         p.codusu       = 0,
         p.nomeusu      = 'Marcus Rangel'
   where codpesquisa = 4;

end;
0
0
