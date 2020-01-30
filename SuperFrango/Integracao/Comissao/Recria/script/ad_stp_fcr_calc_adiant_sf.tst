PL/SQL Developer Test script 3.0
36
declare
  v_sessao varchar2(4000);
begin
  ad_set.inseresessao(p_nome      => 'CODCENCUS',
                      p_sequencia => 1,
                      p_tipo      => 'I',
                      p_valor     => 110400303,
                      p_idsessao  => v_sessao);

  ad_set.inseresessao(p_nome      => 'CODPARC',
                      p_sequencia => 1,
                      p_tipo      => 'I',
                      p_valor     => 662206,
                      p_idsessao  => v_sessao);

  ad_set.inseresessao(p_nome      => 'NUMLOTE',
                      p_sequencia => 1,
                      p_tipo      => 'I',
                      p_valor     => 46,
                      p_idsessao  => v_sessao);

  ad_set.inseresessao(p_nome      => 'DTVENCINI',
                      p_sequencia => 0,
                      p_tipo      => 'D',
                      p_valor     => '31/01/2020',
                      p_idsessao  => v_sessao);

  -- Call the procedure
  ad_stp_fcr_calc_adiant_sf(p_codusu    => 0,
                            p_idsessao  => v_sessao,
                            p_qtdlinhas => 1,
                            p_mensagem  => :p_mensagem);

  ad_set.remove_sessao(v_sessao);

end;
4
p_codusu
1
0
-4
p_idsessao
0
-5
p_qtdlinhas
0
-4
p_mensagem
0
5
0
