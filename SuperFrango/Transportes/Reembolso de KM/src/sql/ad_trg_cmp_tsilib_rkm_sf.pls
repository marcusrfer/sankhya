create or replace trigger ad_trg_cmp_tsilib_rkm_sf
  for delete or insert or update on tsilib
  referencing new as new old as old
  compound trigger

  /* 
  * Autor: M. Rangel
  * Processo: Reembolso de KM
  * Objetivo: Processo de liberação dos reembolsos
  */

  l       tsilib%rowtype;
  f       tgffin%rowtype;
  v_nufin number;

  before each row is
  begin
  
    if updating then
    
      l.evento    := :new.evento;
      l.nuchave   := :new.nuchave;
      l.reprovado := :new.reprovado;
      l.codusulib := :new.codusulib;
      l.vlrlimite := :new.vlrlimite;
    
      --se liberando
      if (:new.dhlib is not null and :old.dhlib is null) then
      
        --se não é reprovado
        if nvl(l.reprovado, 'N') = 'N' then
        
          --get o nufin quando origem é reembolso
          if (:new.tabela = 'AD_TSFRKMC' and :new.evento = 1048) then
          
            begin
              select nufin into v_nufin from ad_tsfrkmc where nureemb = :new.nuchave;
            exception
              when others then
                raise;
            end;
          
            --get o nufin quando origem é a despesa
          elsif :new.tabela = 'TGFFIN' then
            begin
              select nufin into v_nufin from ad_tsfrkmc where nufin = :new.nuchave;
            exception
              when no_data_found then
                goto fim_after_each_row;
            end;
          else
            goto fim_after_each_row;
          end if;
        else
          -- reprovado
          l.reprovado := 'S';
        end if;
      end if;
    
    end if;
  
    <<fim_after_each_row>>
    null;
  end before each row;

  after statement is
    i int;
  
  begin
  
    if v_nufin is not null and l.reprovado = 'N' then
    
      select * into f from tgffin where nufin = v_nufin;
    
      if l.evento = 1048 then
      
        begin
          -- conta quantas libs pendentes
          select count(*)
            into i
            from tsilib lib
           where lib.tabela = 'AD_TSFRKMC'
             and lib.nuchave = l.nuchave
             and lib.codusulib != l.codusulib
             and lib.dhlib is null;
        
          -- se todas liberadas, altera o fin para provisão
          if i = 0 then
            update tgffin
               set recdesp  = -1,
                   provisao = 'S',
                   dtvenc   = ad_get.dia_util_ultimo(trunc(sysdate) + 4, 'P')
             where nufin = v_nufin
               and recdesp = 0;
          
            select count(*)
              into i
              from tsilib
             where tabela = 'TGFFIN'
               and nuchave = v_nufin
               and evento = 1035;
          
            if i = 0 then
              insert into tsilib
                (nuchave, tabela, evento, codususolicit, dhsolicit, vlratual, vlrlimite, codusulib,
                 observacao, codtipoper)
              values
                (f.nufin, 'TGFFIN', 1035, l.codusulib, sysdate, f.vlrdesdob, l.vlrlimite, 950,
                 f.historico, f.codtipoper);
            end if;
          
          end if;
        
        exception
          when others then
            raise;
        end;
        -- se lib financeira, atualiza o status do reembolso
      elsif l.evento = 1035 then
        begin
          update ad_tsfrkmc set status = 'C' where nufin = v_nufin;
        exception
          when others then
            raise;
        end;
      end if;
    
    elsif v_nufin is null and l.reprovado = 'S' then
    
      begin
        update ad_tsfrkmc set status = 'R' where nureemb = l.nuchave;
      exception
        when others then
          raise;
      end;
    
    end if;
  end after statement;

end;
/
