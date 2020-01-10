create or replace trigger ad_trg_cmp_tsfpes_sf
  for insert or update or delete on ad_tsfpes
  compound trigger

  /*
  * Autor: M. Rangel
  * Processo: Pesquisas
  * Objetivo: Tratativas para os processos que utilizam o m�dulo de pesquisa
  */

  /* log de mudan�as
     mrangel - 10/11/2019 - atualiza��o do status da visita sanitaria
  */

  errmsg varchar2(4000);

  after each row is
  begin
  
    if stp_get_atualizando then
      goto fim_da_linha;
    end if;
  
    if updating then
    
      --valida altera��es ap�s a finaliza��o da pesquisa
      if (:new.status = 'F' and :old.status = 'F') then
        errmsg := 'Pesquisas finalizadas n�o podem ser alteradas!';
        raise_application_error(-20105, ad_fnc_formataerro(errmsg));
      end if;
    
      -- se reagendada
      if :old.status = 'P' and (:new.status = 'R' Or :new.dhreagend is Not null ) then
      
        -- se motivo n�o informado
        if nvl(:new.numotivo, 0) = 0 then
          errmsg := 'Motivo da n�o realiza��o da pesquisa n�o informado';
          raise_application_error(-20105, ad_fnc_formataerro(errmsg));
        end if;
      
        if :new.dhreagend is null then
          errmsg := 'Data de reagendamento da pesquisa n�o informado';
          raise_application_error(-20105, ad_fnc_formataerro(errmsg));
        end if;
      
        -- chama reagendamento
        if :new.nometab = 'AD_TSFAVS' and :new.valorpk is not null then
        
          ad_pkg_avs.set_reagendado(p_nuvisita => :new.valorpk,
                                    p_newdata  => :new.dhreagend,
                                    p_numotivo => :new.numotivo);
        
        end if;
      
      end if;
    
      --> se concluindo pesquisa
      if :old.status = 'P' and :new.status = 'F' then
      
        --> se processo de visitas
        if :new.nometab = 'AD_TSFAVS' then
          begin
          
            -- atualiza o status da visita
            stp_set_atualizando('S');
            update ad_tsfavs a
               set a.dhvisita = sysdate,
                   a.status   = 'conc'
             where a.nuvisita = :new.valorpk;
            stp_set_atualizando('N');
          exception
            when others then
              raise_application_error(-20105,
                                      ad_fnc_formataerro('Erro ao finalizar visita! ' || sqlerrm));
          end;
        
        end if;
      
      end if;
    
    end if;
  
    <<fim_da_linha>>
    null;
  end after each row;

end;
/
