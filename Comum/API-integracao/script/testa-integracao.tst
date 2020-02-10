PL/SQL Developer Test script 3.0
32
-- Created on 09/02/2020 by MARCUS.RANGEL 
declare
  -- Local variables here
  p_cab   varchar2(4000);
  p_itens varchar2(4000);
  p_fin   varchar2(4000);
begin
  -- Test statements here
  p_cab   := '<NUNOTA/><CODEMP>1</CODEMP><CODPARC>1</CODPARC><TIPMOV>C</TIPMOV><CODTIPOPER>9</CODTIPOPER><CODTIPVENDA>11</CODTIPVENDA><DTNEG>06/02/2020</DTNEG><DTENTSAI>06/02/2020</DTENTSAI><CODVEND>0</CODVEND><CODNAT>0</CODNAT><CODCENCUS>0</CODCENCUS><OBSERVACAO>Teste</OBSERVACAO>';
  p_itens := '<CODPROD>1</CODPROD><QTDNEG>10</QTDNEG><CODVOL>UN</CODVOL><VLRUNIT>1000</VLRUNIT><PERCDESC>0</PERCDESC>';

  ad_pkg_apiskw.acao_inserir_nota(p_cab, p_itens, :nunota, :errmsg);

  delete from tgffin where nunota = :nunota;
  commit;

  dbms_output.put_line(:nunota);

  p_fin := '<NUMNOTA>0</NUMNOTA><RECDESP>-1</RECDESP><CODPARC>1</CODPARC><CODTIPOPER>9</CODTIPOPER><CODTIPTIT>4</CODTIPTIT>';
  p_fin := p_fin ||
           '<CODEMP>1</CODEMP><CODCENCUS>0</CODCENCUS><CODNAT>0</CODNAT><CODPROJ>0</CODPROJ>';
  p_fin := p_fin || '<DTNEG>' || to_char(sysdate, 'DD/MM/YYYY') || '</DTNEG>';
  p_fin := p_fin || '<DTVENC>' || to_char(sysdate + 22, 'DD/MM/YYYY') ||
           '</DTVENC>';
  p_fin := p_fin ||
           '<VLRDESDOB>10000</VLRDESDOB><DESDOBRAMENTO>1</DESDOBRAMENTO>';
  p_fin := p_fin || '<NUNOTA>' || :nunota || '</NUNOTA>';
  p_fin := p_fin || '<ORIGEM>E</ORIGEM><PROVISAO>S</PROVISAO>';

  ad_pkg_apiskw.acao_inserir_financeiro(p_fin, :nufin, :errmsg);

end;
3
nunota
1
15
5
errmsg
0
5
nufin
1
35
5
0
