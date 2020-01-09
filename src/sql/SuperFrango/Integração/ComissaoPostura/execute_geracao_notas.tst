PL/SQL Developer Test script 3.0
11
begin
  -- Call the procedure
  ad_set.inseresessao('CODCENCUS', 1, 'I', 110800301, :p_idsessao);
  ad_set.inseresessao('DTREF', 1, 'D', '01/12/2019', :p_idsessao);
  ad_stp_fcp_gerarnota_sf(p_codusu    => :p_codusu,
                          p_idsessao  => :p_idsessao,
                          p_qtdlinhas => :p_qtdlinhas,
                          p_mensagem  => :p_mensagem);

  ad_set.remove_sessao(:p_idsessao);
end;
4
p_codusu
1
0
4
p_idsessao
1
fsajkfjasçljflçasjlj
5
p_qtdlinhas
1
1
4
p_mensagem
0
5
0
