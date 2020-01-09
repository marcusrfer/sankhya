declare
 v_session varchar2(100) := 'fjasjfçajsçfjaçjç';
 v_numlote int := 57692;
 v_tiponota varchar2(1) := 'M';
 v_msg varchar2(4000);
begin

 ad_set.inseresessao('NUMLOTE', 1, 'I', v_numlote, v_session);
 ad_set.inseresessao('TIPONOTA', 0, 'S', v_tiponota, v_session);
 ad_stp_fci_fatura_sf(0, v_session, 1, v_msg);
 ad_set.remove_sessao(v_session);

end;
