PL/SQL Developer Test script 3.0
21
declare
 v_sessao varchar2(100);
begin
 -- Test statements here
 ad_set.inseresessao(p_nome      => 'TIPONOTA',
                     p_sequencia => 0,
                     p_tipo      => 'S',
                     p_valor     => 'M',
                     p_idsessao  => v_sessao);

 ad_set.inseresessao(p_nome      => 'NUMLOTE',
                     p_sequencia => 1,
                     p_tipo      => 'I',
                     p_valor     => 57692,
                     p_idsessao  => v_sessao);

 ad_stp_fci_fatura_sf(0, v_sessao, 1, :msg);

 delete execparams where idsessao = v_sessao;

end;
1
msg
1
Registro aprovado com sucesso!
5
0
