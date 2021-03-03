create or replace procedure ad_stp_antt_filltipotransp_sf(p_codusu    number,
                                                          p_idsessao  varchar2,
                                                          p_qtdlinhas number,
                                                          p_mensagem  out varchar2) as
  v_codtabela number;
  i           int;
begin
  /*
  ** autor: m. rangel
  ** processo: calculo de frete ANTT
  ** objetivo: popular a tela de ocupação com os tipos de transportes
  */

  v_codtabela := act_int_field(p_idsessao, 0, 'MASTER_CODTABELA');

  select count(*) into i from ad_tsfofo where codtabela = v_codtabela;

  if i > 0 then
    if act_escolher_simnao(p_titulo => 'Popular tabela de ocupação',
                           p_texto => 'Existem ocupações já inseridas, ' ||
                                       'deseja apagar as existentes e preencher ' ||
                                       'com os valores padrões?', p_chave => p_idsessao,
                           p_sequencia => 0) = 'S' then
      begin
        delete from ad_tsfofo where codtabela = v_codtabela;
      exception
        when others then
          raise;
      end;
    else
      return;
    end if;
  end if;

  -- popula campo texto do tipo de transporte

  begin
    -- Test statements here
  
    for l in (select * from ad_tsfctt)
    loop
    
      i := i + 1;
    
      insert into ad_tsfofo
        (codtabela, nuofo, tipo, percentual, codtiptransp)
      values
        (v_codtabela, i, 'I', 50, l.codtiptransp);
    
      i := i + 1;
    
      insert into ad_tsfofo
        (codtabela, nuofo, tipo, percentual, codtiptransp)
      values
        (v_codtabela, i, 'V', 50, l.codtiptransp);
    
    end loop l;
  exception
    when others then
      p_mensagem := sqlerrm;
      return;
  end;

  p_mensagem := 'Valores preenchidos com sucesso!!!';

end;
/
