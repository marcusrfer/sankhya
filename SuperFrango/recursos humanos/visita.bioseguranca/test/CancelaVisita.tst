PL/SQL Developer Test script 3.0
12
-- Created on 27/11/2019 by MARCUS.RANGEL 
declare
  -- Local variables here
  i integer;
begin
  -- Test statements here
  ad_set.inseresessao('NUVISITA', 1, 'I', 6, :p_idsessao);
  ad_set.inseresessao('MOTIVOCANCEL', 0, 'S', 'TESTE DE CANCELAMENTO', :p_idsessao);
  ad_stp_avs_cancelvisita_sf(0, :p_idsessao, 1, :p_mensagem);
  ad_set.remove_sessao(:p_idsessao);
  rollback;
end;
2
p_idsessao
1
fafjalsjflajsçfjasçjfalfjaljjflajflajlfa
5
p_mensagem
1
Lançamento cancelado com sucesso!
5
0
