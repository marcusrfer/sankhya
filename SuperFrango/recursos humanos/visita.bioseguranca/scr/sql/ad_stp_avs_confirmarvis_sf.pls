create or replace procedure ad_stp_avs_confirmarvis_sf(p_codusu    number,
                                                       p_idsessao  varchar2,
                                                       p_qtdlinhas number,
                                                       p_mensagem  out varchar2) as

  ispesquisa boolean;
  tem_carro  boolean;
  --pes        ad_tsfpes%rowtype;
  vis     ad_tsfavs%rowtype;
  v_count int;
  --v_compl varchar2(4000);
begin
  /*
  * Autor: m. rangel
  * Processo: Visita Sanitaria/Pesquisa
  * Objetivo: promover a integra��o com o m�dulo de pesquisa atrav�s da confirma��o
  */

  for i in 1 .. p_qtdlinhas
  loop
  
    vis := ad_pkg_avs.get_dados_visita(act_int_field(p_idsessao, i, 'NUVISITA'));
  
    -- valida status e data de previs�o, se informados
    if vis.status is null or vis.dhprevis is null then
      p_mensagem := 'Somente visitas programadas (com data de previs�o informada) ' ||
                    'podem ser confirmadas!';
      return;
    end if;
  
    if vis.status = 'conf' then
    
      select count(*)
        into v_count
        from ad_tsfpes p
       where p.nometab = 'AD_TSFAVS'
         and p.valorpk = vis.nuvisita;
    
      if v_count > 0 then
        p_mensagem := 'Visita (' || vis.nuvisita || ') j� est� confirmada e gerou a pesquisa ' ||
                      vis.codpesquisa;
        return;
      else
        null;
      end if;
    
    end if;
  
    /*--> regra de valida��o para quando for confirmar, precisando de carro e sem solicita��o feita
    if (nvl(vis.carroapoio, 'N') = 'S' and vis.nucapsol is null) or
       (nvl(vis.carroapoio, 'N') = 'S' and vis.nucapsol is not null and vis.statuscar = 'C') then
      p_mensagem := 'Foi informada a necessidade de carro de apoio, mas n�o foi encontrada nenhuma solicita��o! ' ||
                    '<br>Realize a solicita��o do carro de apoio ou desmarque a op��o.';
      return;
    end if;*/
  
    -- valida se confirmando sem carro de apoio
    begin
      if nvl(vis.nucapsol, 0) = 0 then
        tem_carro := act_confirmar(p_titulo => 'Confirma��o de Visita',
                                   p_texto => 'N�o foi encontrada nenhuma solicita��o de carro de apoio, ' ||
                                               'deseja solicitar um carro de apoio?',
                                   p_chave => p_idsessao, p_sequencia => 0);
      
        if tem_carro then
          ad_pkg_avs.set_carro_apoio(p_nuvisita => vis.nuvisita, p_nucapsol => vis.nucapsol,
                                     p_errmsg => p_mensagem);
          if p_mensagem is not null then
            return;
          end if;
        else
          null;
        end if;
      
      end if;
    end;
  
    -- confirma gera��o de pesquisa
    ispesquisa := act_confirmar(p_titulo => 'Confirma��o de Visita',
                                p_texto => 'Deseja gerar uma pesquisa para essa visita?',
                                p_chave => p_idsessao, p_sequencia => 1);
  
    -- insere pesquisa
    if ispesquisa then
    
      if nvl(vis.codusuapp, 0) = 0 then
        p_mensagem := 'Informe o c�digo do usu�rio que executar� a pesquisa';
        return;
      end if;
    
      ad_pkg_avs.set_nova_pesquisa(vis.nuvisita, vis.codpesquisa, p_mensagem);
      ad_pkg_avs.insere_historico(vis.nuvisita, 'Pesquisa ' || vis.codpesquisa || ' gerada.');
      if p_mensagem is not null then
        return;
      end if;
    
    end if;
  
    -- atualiza status
    begin
      update ad_tsfavs s
         set s.status = 'conf', s.codpesquisa = vis.codpesquisa, s.nucapsol = vis.nucapsol
       where s.nuvisita = vis.nuvisita;
      ad_pkg_avs.insere_historico(vis.nuvisita, 'Visita Confirmada.');
    exception
      when others then
        p_mensagem := 'Erro ao atulizar o status da visita. ' || sqlerrm;
        return;
    end;
  
  end loop;

  p_mensagem := 'Visita confirmada com sucesso!!!';

end;
/
