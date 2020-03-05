create or replace procedure ad_stp_def_enviarecaprv(p_codusu    number,
                                                    p_idsessao  varchar2,
                                                    p_qtdlinhas number,
                                                    p_mensagem  out varchar2) as
  v_valoroc   float;
  def         ad_tsfdef%rowtype;
  v_percrep   float;
  v_valorlib  float;
  v_count     int := 0;
  v_sequencia int := 0;
  v_codusulib int;
begin
  /*
   Dt. criação: 27/09/2016
   Autor: Marcus Rangel
   Processo: Despesas Extras de Frete
   Objetivo: Inserir a solicitação de liberação para as despesas extras de frete.
   Realizar o rateio considerando os centros de resultados ou da ordem de carga ou do recibo
  */

  for i in 1 .. p_qtdlinhas
  loop
  
    select *
      into def
      from ad_tsfdef d
     where d.nudef = nvl(act_int_field(p_idsessao, i, 'NUDEF'), 15);
  
    -- BY RODRIGO DIA 12/09/2019 O.S 53124
    if def.status = 'L' then
      --raise_application_error(-20101, 'Atenção: Cancelando, foi liberado!!');
      p_mensagem := 'Registro já liberado!';
      return;
    end if;
  
    -- valor total da ordem de carga
    begin
      select sum(vlrnota) into v_valoroc from tgfcab where ordemcarga = def.ordemcarga;
    exception
      when others then
        p_mensagem := 'Não foi possível buscar o total da ordem de carga. <br>' || sqlerrm;
        return;
    end;
  
    -- verifica os recibos para identificar se o rateio será manual ou automatico pela OC
    for recibo in (select * from ad_tsfdefr where nudef = def.nudef)
    loop
      if recibo.rateio_oc = 'S' then
        -- Cursor por usuário responsável pelo centro de resultado.
        for lib in (
                    
                    --Select u.codusuresp, Sum(c.vlrnota) valor
                    select l.codusu codusuresp, sum(c.vlrnota) valor
                      from tgfcab c
                      join tsicus u
                        on c.codcencus = u.codcencus
                      left join ad_itesolcpalibcr l
                        on c.codcencus = l.codcencus
                     where c.ordemcarga = def.ordemcarga
                       and nvl(l.aprova, 'N') = 'S'
                     group by l.codusu
                    
                    )
        loop
          v_sequencia := v_sequencia + 1;
        
          -- % de participação pelo valor no total da OC
          v_percrep := (lib.valor / v_valoroc);
        
          -- total de recibos lançados
        
          /*          comentado para a buscar o valor individual do recibo
          Begin
                      Select Sum(r.vlrdesdob) Into v_totalRec From ad_tsfdefr r Where r.nudef = v_Nudef;
                    Exception
                      When no_data_found Then
                        Errmsg := 'Não foram encontrados recibos com valores para o envio para liberação.';
                        Raise error;
                    End;*/
        
          v_valorlib := round(recibo.vlrdesdob * v_percrep, 4);
        
          /* comentado para tratar o rateio pelo cr manual e da oc
          verifica se já existe solicitação de liberação
          Begin
            Select Count(*)
              Into v_Count
              From tsilib l
             Where nuchave = v_nudef
               And tabela = 'AD_TSFDEF'
               And l.codusulib = lib.codusuresp
               And sequencia = v_sequencia;
            If v_count <> 0 Then
              Errmsg := 'Solicitação de liberação já existe. Desfaça a solicitação ou entre em contato com o liberador.';
              Raise error;
            End If;
          End;*/
        
          -- insere registro na tsilib
          begin
            v_count := 0;
          
            select count(*)
              into v_count
              from tsilib l
             where l.nuchave = def.nudef
               and l.tabela = 'AD_TSFDEF'
               and l.codusulib = lib.codusuresp
            --And l.codususolicit = v_CodUSuLog            
            --And l.dhlib Is Null
            ;
          
            if v_count = 0 then
              ad_set.ins_liberacao(p_tabela    => 'AD_TSFDEF',
                                   p_nuchave   => def.nudef,
                                   p_evento    => def.nuevento,
                                   p_valor     => v_valorlib,
                                   p_codusulib => lib.codusuresp,
                                   p_obslib    => substr('Ref. desp. OC ' || def.ordemcarga ||
                                                         recibo.historico,
                                                         1,
                                                         255),
                                   p_errmsg    => p_mensagem);
              if p_mensagem is not null then
                return;
              end if;
            
            else
              begin
                update tsilib l
                   set l.vlratual      = l.vlratual + v_valorlib,
                       l.dhlib         = null,
                       l.reprovado     = 'N',
                       l.codususolicit = p_codusu
                 where l.nuchave = def.nudef
                   and l.tabela = 'AD_TSFDEF'
                   and l.codusulib = lib.codusuresp;
              exception
                when others then
                  p_mensagem := 'Não foi possível atualizar os valores na liberação. <br>' ||
                                sqlerrm;
                  return;
              end;
            
            end if;
          end;
        
        end loop; -- loop lib
      else
        -- RATEIO_OC = N (se utiliza o rateio manual)
      
        begin
          select l.codusu
            into v_codusulib
            from tsicus c
            join ad_itesolcpalibcr l
              on c.codcencus = l.codcencus
            join tsiusu u
              on u.codusu = l.codusu
           where c.codcencus = recibo.codcencus
             and nvl(l.ativo, 'N') = 'SIM'
             and nvl(l.aprova, 'N') = 'S'
                --And l.vlrfinal >= recibo.vlrdesdob
             and nvl(u.dtlimacesso, sysdate + 100) >= sysdate;
        exception
          when no_data_found then
            p_mensagem := 'Não foi encontrado o liberador para o centro de resultados ' ||
                          recibo.codcencus ||
                          'Por favor verifique o cadastro de alçadas de liberadores por C.R.';
            return;
        end;
      
        begin
          v_sequencia := v_sequencia + 1;
          v_count     := 0;
        
          select count(*)
            into v_count
            from tsilib l
           where l.nuchave = recibo.nudef
             and l.tabela = 'AD_TSFDEF'
             and l.codusulib = v_codusulib
          --And l.codususolicit = v_CodUSuLog
          --And l.dhlib Is Null
          ;
        
          if v_count = 0 then
          
            ad_set.ins_liberacao(p_tabela    => 'AD_TSFDEF',
                                 p_nuchave   => def.nudef,
                                 p_evento    => def.nuevento,
                                 p_valor     => recibo.vlrdesdob,
                                 p_codusulib => v_codusulib,
                                 p_obslib    => 'Ref. despesas extras de frete OC Nº ' ||
                                                def.ordemcarga,
                                 p_errmsg    => p_mensagem);
            if p_mensagem is not null then
              return;
            end if;
          
          else
          
            update tsilib l
               set l.vlratual      = l.vlratual + recibo.vlrdesdob,
                   l.codususolicit = p_codusu,
                   l.dhlib         = null,
                   l.reprovado     = 'N'
             where l.nuchave = recibo.nudef
               and l.tabela = 'AD_TSFDEF'
               and l.codusulib = v_codusulib
            --And l.codususolicit = v_CodUSuLog            
            --And l.dhlib Is Null
            ;
          
          end if;
        exception
          when others then
            p_mensagem := 'Erro ao inserir solicitação de liberação pendente. (CR Manual)' ||
                          sqlerrm;
            return;
        end;
      end if;
    end loop; -- recibo
  
    v_sequencia := 0;
    p_mensagem  := 'Despesas enviadas para aprovação com sucesso!';
  
    begin
      update ad_tsfdef d set d.status = 'AL' where nudef = def.nudef;
    exception
      when others then
        p_mensagem := 'Não foi possível atualizar o status. ' || sqlerrm;
        return;
    end;
  
  end loop; -- loop I

end;
/
