create or replace trigger ad_trg_cmp_tsfpes_sf
  for insert or update or delete on ad_tsfpes
  compound trigger

  /*
  * Autor: M. Rangel
  * Processo: Pesquisas
  * Objetivo: Tratativas para os processos que utilizam o módulo de pesquisa
  */

  /* log de mudanças
     mrangel - 10/11/2019 - atualização do status da visita sanitaria
  */

  errmsg  varchar2(4000);
  p_count number;

  after each row is
  begin
  
    if stp_get_atualizando then
      goto fim_da_linha;
    end if;
  
    if updating then
    
      --valida alterações após a finalizaçõo da pesquisa
      if (:new.status = 'F' and :old.status = 'F') then
        errmsg := 'Pesquisas finalizadas não podem ser alteradas!';
        raise_application_error(-20105, ad_fnc_formataerro(errmsg));
      end if;
    
      -- se reagendada
      if :old.status = 'P' and (:new.status = 'R' /*or :new.dhreagend is not null*/
         ) then
      
        -- se motivo não informado
        if nvl(:new.numotivo, 0) = 0 then
          errmsg := 'Motivo da não realização da pesquisa não informado';
          raise_application_error(-20105, ad_fnc_formataerro(errmsg));
        end if;
      
        if :new.dhreagend is null then
          errmsg := 'Data de reagendamento da pesquisa não informado';
          raise_application_error(-20105, ad_fnc_formataerro(errmsg));
        end if;
      
        -- chama reagendamento
        if :new.nometab = 'AD_TSFAVS' and :new.valorpk is not null then
        
          ad_pkg_avs.set_reagendado(p_nuvisita => :new.valorpk,
                                    p_newdata  => :new.dhreagend,
                                    p_numotivo => :new.numotivo);
        
        end if;
      
      end if;
    
      -- se cancelando a pesquisa
      if :old.status = 'P' and :new.status = 'C' then
        declare
          pk_name varchar2(100);
          stmt    varchar2(4000);
        begin
        
          select t.column_name
            into pk_name
            from user_cons_columns t
           where 1 = 1
             and t.table_name = :new.nometab
             and t.constraint_name like ('PK%');
        
          stmt := 'update ' || :new.nometab || ' set status = ''canc'' where ' ||
                  pk_name || ' = ' || :new.valorpk;
        
          execute immediate stmt;
        
        exception
          when others then
            errmsg := 'Erro ao cancelar origem. ' || sqlerrm;
            raise_application_error(-20105, ad_fnc_formataerro(errmsg));
        end;
      end if;
    
      --> se concluindo pesquisa
      if :old.status = 'P' and :new.status = 'F' then
      
        --> se processo de visitas
        if :new.nometab = 'AD_TSFAVS' then
          begin
          
            -- atualiza o status da visita
            stp_set_atualizando('S');
          
            select count(*)
              into p_count
              from ad_tsfavs a
             where a.nuvisita = :new.valorpk;
            if (p_count > 0) then
              update ad_tsfavs a
                 set a.dhvisita = sysdate,
                     a.status   = 'conc'
               where a.nuvisita = :new.valorpk;
            
            end if;
            stp_set_atualizando('N');
          
          exception
            when others then
              raise_application_error(-20105,
                                      ad_fnc_formataerro('Erro ao finalizar visita! ' ||
                                                         sqlerrm));
          end;
        
        end if;
      
      end if;
    
    end if;
  
    <<fim_da_linha>>
    null;
  end after each row;

end;
/
