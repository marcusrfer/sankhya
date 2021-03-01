PL/SQL Developer Test script 3.0
61
declare

begin
  -- Test statements here
  insert into execparams
    (idsessao, sequencia, nome, tipo, numint, numdec, texto, dta)
  values
    ('2D3CC8D4001DB8FA73F9425DE0F4C80B', 0, 'CODTIPOPER', 'S', 217, 217, 217, null);
  -------------------------------------------------------------------------------------------------------

  insert into execparams
    (idsessao, sequencia, nome, tipo, numint, numdec, texto, dta)
  values
    ('2D3CC8D4001DB8FA73F9425DE0F4C80B', 0, 'CODPROJ', 'S', 0, 0, 0, null);
  -------------------------------------------------------------------------------------------------------

  insert into execparams
    (idsessao, sequencia, nome, tipo, numint, numdec, texto, dta)
  values
    ('2D3CC8D4001DB8FA73F9425DE0F4C80B', 0, 'CODEMPNEGOC', 'S', 3, 3, 3, null);
  -------------------------------------------------------------------------------------------------------

  insert into execparams
    (idsessao, sequencia, nome, tipo, numint, numdec, texto, dta)
  values
    ('2D3CC8D4001DB8FA73F9425DE0F4C80B', 0, 'CODNAT', 'S', 2010000, 2010000, 2010000, null);
  -------------------------------------------------------------------------------------------------------

  insert into execparams
    (idsessao, sequencia, nome, tipo, numint, numdec, texto, dta)
  values
    ('2D3CC8D4001DB8FA73F9425DE0F4C80B', 0, 'SERIENOTA', 'I', 2, null, null, null);
  -------------------------------------------------------------------------------------------------------

  insert into execparams
    (idsessao, sequencia, nome, tipo, numint, numdec, texto, dta)
  values
    ('2D3CC8D4001DB8FA73F9425DE0F4C80B', 0, 'CODPARC', 'S', 15589, 15589, 15589, null);
  -------------------------------------------------------------------------------------------------------

  insert into execparams
    (idsessao, sequencia, nome, tipo, numint, numdec, texto, dta)
  values ('2D3CC8D4001DB8FA73F9425DE0F4C80B', 0, 'CODCENCUS', 'S', 20200100, 20200100, 20200100, null);
  -------------------------------------------------------------------------------------------------------

  insert into execparams
    (idsessao, sequencia, nome, tipo, numint, numdec, texto, dta)
  values
    ('2D3CC8D4001DB8FA73F9425DE0F4C80B', 1, 'NUNOTA', 'I', 36150013, null, null, null);
  -------------------------------------------------------------------------------------------------------

  insert into execparams
    (idsessao, sequencia, nome, tipo, numint, numdec, texto, dta)
  values
    ('2D3CC8D4001DB8FA73F9425DE0F4C80B', 2, 'NUNOTA', 'I', 36151204, null, null, null);
  -------------------------------------------------------------------------------------------------------
  ad_stp_cab_gerarnotatransf_sf(0, '2D3CC8D4001DB8FA73F9425DE0F4C80B', 2, :p_mensagem);

  ad_set.remove_sessao('2D3CC8D4001DB8FA73F9425DE0F4C80B');

end;
1
p_mensagem
0
5
0
