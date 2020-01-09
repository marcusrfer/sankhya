PL/SQL Developer Test script 3.0
62
begin

 --ad_pkg_var.count := 0;

 insert into ad_tsfpesr
  (codpesquisa, nuseqresp, codquest, codperg, tiporesp, resposta, obs, anexo, convertido)
 values
  (:codpesquisa, 1, 1, 1, 'lista', '2-Não', 'NENHUM ANIMAL', null, 0);

 insert into ad_tsfpesr
  (codpesquisa, nuseqresp, codquest, codperg, tiporesp, resposta, obs, anexo, convertido)
 values
  (:codpesquisa, 2, 1, 2, 'lista', '2-Não', 'NÃO HÁ PARENTES NO GOIÁS', null, 0);

 insert into ad_tsfpesr
  (codpesquisa, nuseqresp, codquest, codperg, tiporesp, resposta, obs, anexo, convertido)
 values
  (:codpesquisa, 3, 1, 3, 'lista', '1-Sim', 'OUVI SONS DE AVES, ARARA', null, 0);

 insert into ad_tsfpesr
  (codpesquisa, nuseqresp, codquest, codperg, tiporesp, resposta, obs, anexo, convertido)
 values
  (:codpesquisa, 4, 1, 4, 'lista', '2-Não', 'NÃO MAS ÚLTIMAS DUAS SEMANAS', null, 0);

 insert into ad_tsfpesr
  (codpesquisa, nuseqresp, codquest, codperg, tiporesp, resposta, obs, anexo, convertido)
 values
  (:codpesquisa, 5, 1, 5, 'lista', '2-Não', 'ESPOSA TRABALHA NO COMÉRCIO', null, 0);

 insert into ad_tsfpesr
  (codpesquisa, nuseqresp, codquest, codperg, tiporesp, resposta, obs, anexo, convertido)
 values
  (:codpesquisa, 6, 1, 6, 'lista', '2-Não', 'NÃO SOUBE INFORMAR', null, 0);

 insert into ad_tsfpesr
  (codpesquisa, nuseqresp, codquest, codperg, tiporesp, resposta, obs, anexo, convertido)
 values
  (:codpesquisa, 7, 1, 7, 'lista', '1-Sim', 'EXISTE UM ACÚMULO DE LIXO NO FIM DA RUA', null, 1);

 insert into ad_tsfpesr
  (codpesquisa, nuseqresp, codquest, codperg, tiporesp, resposta, obs, anexo, convertido)
 values
  (:codpesquisa, 8, 1, 8, 'lista', '2-Não', null, null, 0);

 insert into ad_tsfpesr
  (codpesquisa, nuseqresp, codquest, codperg, tiporesp, resposta, obs, anexo, convertido)
 values
  (:codpesquisa, 9, 1, 9, 'lista', '3-Boa', 'LIMPO E ORGANIZADO NA MEDIDA DO POSSÍVEL', null, 0);

 insert into ad_tsfpesr
  (codpesquisa, nuseqresp, codquest, codperg, tiporesp, resposta, obs, anexo, convertido)
 values
  (:codpesquisa, 10, 1, 10, 'lista', '1-Ruim', 'RUA SUJA, LIXO SEM RECOLHER.', null, 0);

 update ad_tsfpes p
    set p.dhrealizacao = sysdate,
        p.status       = 'F'
  where p.codpesquisa = :codpesquisa;

 commit;

end;
1
codpesquisa
1
20
3
1
t.count
