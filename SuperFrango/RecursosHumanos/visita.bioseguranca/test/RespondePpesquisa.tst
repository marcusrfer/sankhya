PL/SQL Developer Test script 3.0
69
-- Created on 27/11/2019 by MARCUS.RANGEL 
declare
  -- Local variables here
  i             integer;
  v_codpesquisa int;
  v_status      int;
begin
  -- Test statements here
  v_status      := sys.diutil.bool_to_int(stp_get_atualizando);
  v_codpesquisa := 24;

  insert into ad_tsfpesr
    (codpesquisa, nuseqresp, codquest, codperg, tiporesp, resposta, obs, anexo, convertido)
  values
    (v_codpesquisa, 1, 1, 1, 'lista', 'Não', null, null, null);

  insert into ad_tsfpesr
    (codpesquisa, nuseqresp, codquest, codperg, tiporesp, resposta, obs, anexo, convertido)
  values
    (v_codpesquisa, 2, 1, 2, 'lista', 'Não', null, null, null);

  insert into ad_tsfpesr
    (codpesquisa, nuseqresp, codquest, codperg, tiporesp, resposta, obs, anexo, convertido)
  values
    (v_codpesquisa, 3, 1, 3, 'lista', 'Não', null, null, null);

  insert into ad_tsfpesr
    (codpesquisa, nuseqresp, codquest, codperg, tiporesp, resposta, obs, anexo, convertido)
  values
    (v_codpesquisa, 4, 1, 4, 'lista', 'Não', null, null, null);

  insert into ad_tsfpesr
    (codpesquisa, nuseqresp, codquest, codperg, tiporesp, resposta, obs, anexo, convertido)
  values
    (v_codpesquisa, 5, 1, 5, 'lista', 'Não', null, null, null);

  insert into ad_tsfpesr
    (codpesquisa, nuseqresp, codquest, codperg, tiporesp, resposta, obs, anexo, convertido)
  values
    (v_codpesquisa, 6, 1, 6, 'lista', 'Não', null, null, null);

  insert into ad_tsfpesr
    (codpesquisa, nuseqresp, codquest, codperg, tiporesp, resposta, obs, anexo, convertido)
  values
    (v_codpesquisa, 7, 1, 7, 'lista', 'Não', null, null, null);

  insert into ad_tsfpesr
    (codpesquisa, nuseqresp, codquest, codperg, tiporesp, resposta, obs, anexo, convertido)
  values
    (v_codpesquisa, 8, 1, 8, 'lista', 'Sim', null, null, null);

  insert into ad_tsfpesr
    (codpesquisa, nuseqresp, codquest, codperg, tiporesp, resposta, obs, anexo, convertido)
  values
    (v_codpesquisa, 9, 1, 9, 'lista', 'Boa', null, null, null);

  insert into ad_tsfpesr
    (codpesquisa, nuseqresp, codquest, codperg, tiporesp, resposta, obs, anexo, convertido)
  values
    (v_codpesquisa, 10, 1, 10, 'lista', 'Boa', null, null, null);

  insert into ad_tsfpesr
    (codpesquisa, nuseqresp, codquest, codperg, tiporesp, resposta, obs, anexo, convertido)
  values
    (v_codpesquisa, 11, 1, 11, 'lista', 'Necessita Aprov.', 'Eu acho que o cara tá me enganando',
     null, null);

  -- 'Necessita Aprov.'
end;
0
1
v_status
