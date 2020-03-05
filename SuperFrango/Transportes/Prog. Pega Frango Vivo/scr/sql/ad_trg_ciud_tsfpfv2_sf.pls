create or replace trigger ad_trg_ciud_tsfpfv2_sf
  for insert or update or delete on ad_tsfpfv2
  compound trigger

  /*
  * Autor: Marcus Rangel
  * Processo: Programação Coleta de Frango Vivo
  * Objetivo: Realizar validações e tratativas nos dados oriundos da integração com o AVECOM
  */

  gerandopedido varchar2(1);

  before statement is
  begin
    if ad_pkg_pfv.v_gerapedido then
      gerandopedido := 'S';
    else
      gerandopedido := 'N';
    end if;
  end before statement;

  before each row is
    v_codparc number;
  begin
  
    if (inserting or updating) and gerandopedido = 'N' then
    
      -- teoricamente, a única entrada de dados nessa tabela será pela trigger da TSFTFV
      -- e já existe essa tratativa lá, permanceu aqui sem raise só para o fato de, futuramente,
      -- se permitir a inclusão pela tela.
    
      -- tratativa para parceiro nulo
      if :new.codparc is null then
        begin
          select codparc
            into v_codparc
            from tgfpar
           where (upper(nomeparc) like '%UNIDADE%' || :new.codune || '%NUCLEO%' || :new.nucleo || '%' or
                 upper(nomeparc) like '%UNIDADE%' || :new.codune || '%AVIARIO%' || :new.nucleo || '%');
        
          :new.codparc := v_codparc;
        exception
          when others then
            null;
        end;
      
      end if;
    
      if nvl(:new.codcid, 0) = 0 then
        begin
          select codcid into :new.codcid from tgfpar where codparc = v_codparc;
        exception
          when no_data_found then
            null;
        end;
      
      end if;
    
      -- tratativa para produto nulo
      if :new.codprod is null then
        if :new.sexo = 'M' then
          :new.codprod := ad_pkg_pfv.v_codprodmacho;
        elsif :new.sexo = 'F' then
          :new.codprod := ad_pkg_pfv.v_codprodfemea;
        elsif :new.sexo = 'S' then
          :new.codprod := ad_pkg_pfv.v_codprodsexado;
        end if;
      end if;
    
      -- tratativa para prioridade, usuário conseguir ordenar por regra
      if :new.dtdescarte > trunc(:new.dtagend) and :new.horapega between 1800 and 2359 then
        :new.prioridade := 0;
      else
        :new.prioridade := 1;
      end if;
    
    end if;
  
    -- Ao atualizar, verifica se o laudo foi importado, se não, busca realizar a vinculação.  
    if updating and gerandopedido = 'N' then
    
      if :old.codveiculo is null and :new.codveiculo is not null and :old.statusvei is null then
        :new.statusvei := 'P';
      end if;
    
      if :old.codveiculo is not null and :new.codveiculo is null then
        :new.codparctransp := null;
        :new.codmotorista  := null;
        :new.statusvei     := null;
      end if;
    
      if :new.statusvei is not null and :new.codveiculo is not null and gerandopedido = 'N' then
        :new.status := 'A';
      end if;
      /*
      TODO: owner="Marcus Rangel" category="Review" priority="1 - High" created="13/02/2019"
      text="tratar processo de cancelamento de nota e/ou programação com pedido gerado"
      */
      -- se cancelando a nota fiscal
      if :old.nunota is not null and :new.nunota is null then
        null;
      end if;
    
      if :old.numlfv is null then
      
        begin
          select l.numlfv,
                 to_date(l.dtalojamento - 1, 'dd/mm/yyyy'),
                 to_date(l.dtalojamento - 1, 'dd/mm/yyyy'),
                 to_date(l.dtalojamento + 14, 'dd/mm/yyyy'),
                 l.gta || ' - ' || par.cgc_cpf,
                 l.qtdaves,
                 l.qtdmortes
            into :new.numlfv,
                 :new.dtmarek,
                 :new.dtbouba,
                 :new.dtgumboro,
                 :new.origpinto,
                 :new.qtdpega,
                 :new.qtdmortes
            from ad_tsflfv l
            join tgfpar par
              on l.codparc = par.codparc
           where l.codparc = :new.codparc
             and l.codprod = :new.codprod
             and to_char(l.dhpega, 'dd/mm/yyyy hh24:mi:ss') = to_char(:new.dhpega, 'dd/mm/yyyy hh24:mi:ss')
             and rownum = 1
          --And l.dtabate = To_Date(:new.Dtdescarte, 'dd/mm/yyyy')
          ;
        exception
          when no_data_found then
            :new.dtmarek   := null;
            :new.dtbouba   := null;
            :new.dtgumboro := null;
            :new.origpinto := null;
            :new.qtdpega   := null;
            :new.qtdmortes := null;
        end;
      
      end if;
    
    end if;
  
  end before each row;

end;
/
