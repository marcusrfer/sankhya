create or replace trigger ad_trg_cmp_tsfpesr_sf
  for insert or update or delete on ad_tsfpesr
  compound trigger

  /*
  Autor: M. Rangel
  Dt. Criação: 10/12/2019
  Processo: Pesquisas
  Objetivo: Realizar as tratativas a nível de resposta para os processos
            adjacentes que utilizam a pesquisa
  */

  /* log de mudanças
  mrangel 22/11/19 adcionada tratativa para execução de ações de acordo com as respostas
  
  
  */

  pes      ad_tsfpes%rowtype;
  pergunta ad_tsfpesp %rowtype;
  lista    ad_tsfpesl%rowtype;

  before each row is
  begin
  
    if inserting then
    
      pes.codpesquisa := :new.codpesquisa;
      pes.codquest    := :new.codquest;
      --t.extend;
      --t(t.last).valor := dbms_random.value;
    
      ad_pkg_var.count := ad_pkg_var.count + 1;
    
      --dbms_output.put_line(ad_pkg_var.count);
    
      -- tratativas para respostas do processo de visita sanitaria
      begin
      
        select *
          into pergunta
          from ad_tsfpesp p
         where p.codquest = :new.codquest
           and p.codperg = :new.codperg;
      
        if nvl(pergunta.execacao, 'N') = 'S' then
        
          -- percorre as ligações para encontrar a ação executada
          for action in (select l.codquest, l.codperg, l.acao, p.nometab
                           from ad_tsfpesl l
                           join ad_tsfpes p
                             on p.codpesquisa = :new.codpesquisa
                          where l.codquest = pergunta.codquest
                            and l.codperg = pergunta.codperg
                            and l.valor = to_char(:new.resposta))
          loop
            if action.nometab = 'AD_TSFAVS' then
              declare
                v_nuvisita number;
              begin
                select nuvisita
                  into v_nuvisita
                  from ad_tsfavs
                 where codpesquisa = :new.codpesquisa;
              
                execute immediate 'call ' || action.acao
                using v_nuvisita;
              
              end;
            
            end if;
          end loop;
        
        end if;
      exception
        when others then
          raise;
      end;
    
    end if;
  
  end before each row;

  after statement is
    v_count int;
  begin
    if ad_pkg_var.count > 0 then
      select count(*) into v_count from ad_tsfpesp q where q.codquest = pes.codquest;
    
      if ad_pkg_var.count = v_count then
      
        begin
        
          --> finaliza pesquisa
        
          update ad_tsfpes p
             set p.dhalter      = sysdate,
                 p.dhrealizacao = sysdate,
                 status         = Case When p.dhreagend Is Null then 'F' Else 'R' End
           where codpesquisa = pes.codpesquisa;
        
          --dbms_output.put_line('entrou no update');
        
        exception
          when others then
            raise;
        end;
      
      end if;
    
    end if;
  end after statement;

end;
