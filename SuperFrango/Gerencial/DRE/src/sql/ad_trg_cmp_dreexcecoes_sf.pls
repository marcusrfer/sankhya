create or replace trigger ad_trg_cmp_dreexcecoes_sf
  for insert or update or delete on dre_excecoes
  compound trigger

  /*
    Author: MARCUS.RANGEL 11/09/2019 10:10:47
    A finalidade é validar a fórmula ou a ausência dela
    no momento da edição, visando garantir que a execução
    do cálculo ocorra sem possíveis erros de fórmulas
  */

  before each row is
    v_formula_ind varchar2(4000);
    v_query       varchar2(4000);
    v_dtref       date := add_months(trunc(sysdate, 'fmmm'), -1);
    v_msg         varchar2(4000);
    c             sys_refcursor;
    i             int;
    m             int := 2;
  begin
  
    if inserting
       or updating then
    
      -- se ativo
      if (:old.ativo = 'S' or :new.ativo = 'S') then
      
        -- se usa formula
        if (:new.tipovlr = 'F') then
        
          -- se formula está preenchida
          if (:new.formexc is null) then
            v_msg := ad_fnc_formataerro('Erro!!!<br>Quando o tipo "Fórmula" estiver selecionado, a fórmula deve ser informada!');
            raise_application_error(-20105, v_msg);
          else
            v_formula_ind := replace(upper(:new.formexc), 'SUM', '');
          end if;
        
          --possui lançamentos?
          select count(*) into i from dre_baseindpad where dtref = v_dtref;
        
          -- retroaje um mes caso não tenha dados da table no time selecionado
          if i = 0 then
            while i = 0
            loop
              v_dtref := add_months(trunc(sysdate, 'fmmm'), -m);
              select count(*) into i from dre_baseindpad where dtref = v_dtref;
              m := m + 1;
            end loop;
          end if;
        
          v_query := 'Select nunota, sequencia, ' || v_formula_ind || chr(13) ||
                     ' from DRE_BASEINDPAD where dtref = :dtref';
        
          dbms_output.put_line('query: ' || v_query);
        
          -- parse da formula para verificação
          begin
            open c for v_query
              using v_dtref;
          
            close c;
          exception
            when others then
              v_msg := ad_fnc_formataerro('Erro na fórmula!!!<br>' || sqlerrm);
              raise_application_error(-20105, v_msg);
          end;
        
        elsif (:new.tipovlr = 'V') then
          null;
        end if;
        -- fim se formula
      
      end if;
      -- fim se ativo
    
    end if;
    -- fim se ins/upd
  
  end before each row;

end;
/
