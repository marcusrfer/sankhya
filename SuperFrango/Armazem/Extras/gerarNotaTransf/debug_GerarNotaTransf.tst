PL/SQL Developer Test script 3.0
16
begin
  -- Call the procedure
  ad_set.inseresessao('CODEMPNEGOC', 0, 'S', '3', :p_idsessao);
  ad_set.inseresessao('CODPARC', 0, 'S', '14289', :p_idsessao);
  ad_set.inseresessao('CODTIPOPER', 0, 'S', '604', :p_idsessao);
  ad_set.inseresessao('CODNAT', 0, 'S', '2010000', :p_idsessao);
  ad_set.inseresessao('CODCENCUS', 0, 'S', '20200100', :p_idsessao);
  ad_set.inseresessao('CODPROJ', 0, 'S', '0', :p_idsessao);
  ad_set.inseresessao('SERIENOTA', 0, 'I', 2, :p_idsessao);
  ad_set.inseresessao('CODLOCALDEST', 0, 'I', 4900, :p_idsessao);
  ad_set.inseresessao('QTDNEG', 0, 'F', 35000, :p_idsessao);
  ad_set.inseresessao('NUNOTA', 1, 'I', 37091221, :p_idsessao);
  ad_stp_cab_gerarnotatransf_sf(p_codusu => :p_codusu, p_idsessao => :p_idsessao, p_qtdlinhas => :p_qtdlinhas,
                                p_mensagem => :p_mensagem);
  ad_set.remove_sessao(:p_idsessao);
end;
4
p_codusu
1
134
3
p_idsessao
1
fjaksdjfajsfjasjfajfak
5
p_qtdlinhas
1
1
3
p_mensagem
4
Nota gerada com sucesso!
    <a href="javascript:workspace.reloadApp('br.com.sankhya.com.mov.CentralNotas', 
    {'NUNOTA': 37528589});document.getElementsByClassName('btn-popup-ok')[0].click();">
    <b>Clique AQUI</b></a>para acessar o registro
5
2
cab.nunota
ite.pendente
