PL/SQL Developer Test script 3.0
27
-- Created on 27/11/2019 by MARCUS.RANGEL 
declare
  -- Local variables here
  i integer;
begin
  -- Test statements here
  ad_set.inseresessao('NUVISITA', 1, 'I', 6, :p_idsessao);
  --ad_set.inseresessao('NUVISITA', 2, 'I', 6, :p_idsessao);

  ad_set.inseresessao('HORAINI',
                      0,
                      'D',
                      to_date('29/11/2019 08:00:00', 'dd/mm/yyyy, hh24:mi:ss'),
                      :p_idsessao);

  ad_set.inseresessao('HORAFIM',
                      0,
                      'D',
                      to_date('29/11/2019 15:00:00', 'dd/mm/yyyy, hh24:mi:ss'),
                      :p_idsessao);

  ad_set.inseresessao('__CONFIRMACAO__', 1, 'S', 'S', :p_idsessao);

  ad_stp_avs_solicita_carro_sf(0, :p_idsessao, 1, :p_mensagem);

  ad_set.remove_sessao(:p_idsessao);
end;
2
p_idsessao
1
IwWUYWCDpVDNArQvXmJT
5
p_mensagem
1
Erro ao atualizar os dados na visita. ORA-02291: restrição de integridade (SANKHYA.AD_FK_F2DE516EA409D24E6FF51) violada - chave mãe não localizada
5
1
sol.nucapsol
