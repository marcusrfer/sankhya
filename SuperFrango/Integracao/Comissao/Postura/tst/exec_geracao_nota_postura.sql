declare
 v_sessao varchar2(100);
begin
  -- Call the procedure
  ad_set.inseresessao('CODCENCUS', 1, 'I', 110400403, v_sessao);
  ad_set.inseresessao('DTREF', 1, 'D', '01/01/2020', v_sessao);
  ad_set.inseresessao('TIPONOTA', 0, 'S', 'R', v_sessao);
  ad_set.inseresessao('__CONFIRMACAO__', 1, 'S', 'S', v_sessao);

  ad_stp_fcp_gerarnota_sf(p_codusu    => 0,
                          p_idsessao  => v_sessao,
                          p_qtdlinhas => 1,
                          p_mensagem  => ad_pkg_var.errmsg);

  ad_set.remove_sessao(v_sessao);

end;
