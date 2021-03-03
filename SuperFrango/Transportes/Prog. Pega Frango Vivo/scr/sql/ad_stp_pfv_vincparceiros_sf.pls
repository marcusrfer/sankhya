create or replace procedure ad_stp_pfv_vincparceiros_sf(p_codusu    number,
                                                        p_idsessao  varchar2,
                                                        p_qtdlinhas number,
                                                        p_mensagem  out varchar2) as
  p_unidade  varchar2(20);
  p_nomeparc varchar2(4000);
  v_unidades varchar2(4000);
  p_perfil   int;
  pfv        ad_tsfpfv2%rowtype;
  i          int;
begin

  /*
    Autor: MARCUS.RANGEL 21/07/2020 09:02:13
    Processo: Pega de Frango Vivo
    Objetivo: Vincular parceiros às unidades Matriz ou Nv. Veneza para permitir filtrar
              as programações na tela para melhor organização das ações
  */

  p_unidade  := act_txt_param(p_idsessao, 'UNIDADE');
  p_nomeparc := act_txt_param(p_idsessao, 'NOMEPARC');

  if p_unidade = '1' then
    p_perfil := 11110200;
  elsif p_unidade = '2' then
    p_perfil := 11130100;
  end if;

  if p_qtdlinhas > 1 then
    p_mensagem := 'Selecione apenas 1 linha!';
    return;
  
  elsif p_qtdlinhas = 0 then
  
    for l in (select codparc || '  - ' || nomeparc unidade
                from tgfpar p
               where nomeparc like ('%UNIDADE ' || p_nomeparc || '%'))
    loop
      v_unidades := trim(v_unidades) || '<br>' || l.unidade;
    end loop;
  
    if act_escolher_simnao(p_titulo => 'Vinculação de Parceiros',
                           p_texto => 'Confirmar a vinculação desses parceiros?' || chr(13) || v_unidades,
                           p_chave => p_idsessao, p_sequencia => 0) = 'S' then
    
      for l in (select codparc
                  from tgfpar p
                 where nomeparc like ('%UNIDADE ' || p_nomeparc || '%'))
      loop
      
        begin
          insert into tgfppa
            (codparc, codcontato, codtipparc, codusu, dtalter)
          values
            (l.codparc, 0, nvl(p_perfil, 11130100), p_codusu, sysdate);
        exception
          when dup_val_on_index then
            p_mensagem := 'Parceiro já está vinculado!';
            return;
          when others then
            p_mensagem := sqlerrm;
            return;
        end;
      
      end loop;
    
    else
      return;
    end if;
  
  elsif p_qtdlinhas = 1 then
  
    select *
      into pfv
      from ad_tsfpfv2
     where nupfv = act_int_field(p_idsessao, 1, 'NUPFV');
  
    select count(*)
      into i
      from tgftpp
     where codtipparc = p_perfil;
  
    if i = 0 then
      p_mensagem := 'perfil não cadastrado';
      return;
    end if;
  
    begin
      delete from tgfppa ppa
       where codparc = pfv.codparc
         and exists (select 1
                from tgftpp p
               where p.codtipparc = ppa.codtipparc
                 and p.codtipparcpai in (11130000, 11110000));
    
      insert into tgfppa
        (codparc, codcontato, codtipparc, codusu, dtalter)
      values
        (pfv.codparc, 0, p_perfil, p_codusu, sysdate);
    exception
      when others then
        p_mensagem := 'Erro ao vincular parceiro. ' || sqlerrm;
        return;
    end;
  
  end if;

  p_mensagem := 'Parceiros vinculados com sucesso!';

end;
/
