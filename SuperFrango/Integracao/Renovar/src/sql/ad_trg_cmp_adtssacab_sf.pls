create or replace trigger ad_trg_cmp_adtssacab_sf
  for insert or update or delete on ad_adtssacab
  compound trigger

  v_codusu int := stp_get_codusulogado;

  errtitle varchar2(200);
  errmsg   varchar2(4000);
  errfix   varchar2(400);

  before each row is
    v_count         int;
    v_vlrdesdob     float;
    v_tipoparcadt   tgfpar.ad_tipadt%type;
    v_codparcmatriz int;
    conf            ad_adtssaconf%rowtype;
  begin
  
    if stp_get_atualizando then
      goto end_of_line;
    end if;
  
    select * into conf from ad_adtssaconf c where c.codigo = nvl(:new.tipo, :old.tipo);
  
    if inserting then
      :new.situacao  := 'E';
      :new.codusuinc := v_codusu;
      :new.dhinc     := sysdate;
    
      if :new.codnat in (9053900, 9054000, 9054200, 9054300) then
        :new.historico := ad_get.descrnatureza(:new.codnat) || '  - ' ||
                          ad_get.nome_parceiro(:new.codparc, 'razaosocial');
      
      end if;
    
      -- se renovar
      if nvl(conf.renovar, 'N') = 'S' then
      
        -- busca o cr da configura��o
        select cr.codcencus
          into :new.codcencus
          from ad_adtssaconfcr cr
         where cr.codigo = :new.tipo
           and rownum = 1;
      
        :new.codcencusresp := :new.codcencus;
      
        :new.historico := 'RENOVAR - ADTO ' || :new.nunico || '  - ' ||
                          ad_get.nome_parceiro(:new.codparcrec, 'razaosocial');
      
      end if;
    
    end if;
  
    if inserting or updating then
    
      -- valida situa��o
      if updating then
        if (:old.situacao = 'P' and :new.situacao = 'P') or (:old.situacao = 'A' and :new.situacao = 'A') or
           (:old.situacao = 'R' and :new.situacao = 'R') then
          errtitle := 'Cancelando Altera��es';
          errmsg   := 'Altera��o n�o permitida pois Situa��o diferente de <i>Elaborando</i>' || :old.situacao ||
                      '  - ' || :new.situacao;
          errfix   := null;
          raise_application_error(-20101, fc_formatahtml_sf(errtitle, errmsg, errfix));
          --raise_application_error(-20105, ad_fnc_formataerro(errtitle || '<br>' || errmsg));
        end if;
      end if;
    
      select count(*)
        into v_count
        from ad_adtssaconfusu u
       where u.codusu = v_codusu
         and u.codigo = :new.tipo;
    
      -- valida acesso
      if v_count = 0 then
        errtitle := 'Cancelando Inclus�o/Edi��o';
        errmsg   := 'Usu�rio logado n�o tem permiss�o para incluir/editar esse tipo de adiantamento!';
        errfix   := 'Solicite a revis�o de suas permiss�es ou a config. do processo ' || :new.tipo;
        raise_application_error(-20101, fc_formatahtml_sf(errtitle, errmsg, errfix));
      end if;
    
      -- valida parceiro
      if :new.codparc <> nvl(:new.codparcrec, :new.codparc) and conf.permparcdif = 'N' then
        errtitle := 'Inclus�o / Edi��o Cancelada';
        errmsg   := 'Tipo de Processo selecionado n�o permite que o parceiro da receita seja diferente do parceiro da despesa';
        errfix   := 'Revise o parceiro ou solicite revis�o da config do processo ' || :new.tipo;
        raise_application_error(-20101, fc_formatahtml_sf(errtitle, errmsg, errfix));
      end if;
    
      if :new.forma <> '4' and conf.forma = 'C' then
        errtitle := 'Inclus�o / Edi��o Cancelada';
        errmsg   := 'Tipo de Processo selecionado s� permite selecionar a forma "Compensa��o"';
        errfix   := 'Revise a forma de pagamento ou solicite a revis�o das config. do processo ' || :new.tipo;
        raise_application_error(-20101, fc_formatahtml_sf(errtitle, errmsg, errfix));
      end if;
    
      /*15 - Clientes - Adiantamento de Vendas, Se o tipo for 15 pode acontecer fora do prazo, 
      vai barrar apenas no DATAFECHA, que j� � padr�o do sistema.*/
      if :new.dtneg < trunc(sysdate) - 5 and :new.tipo not in (15) then
        errtitle := 'Inclus�o / Edi��o Cancelada';
        errmsg   := 'Data Negocia��o n�o pode ser inferior a ' || to_date(trunc(sysdate) - 5, 'DD/MM/YYYY');
        errfix   := 'Corrija as datas informadas';
        raise_application_error(-20101, fc_formatahtml_sf(errtitle, errmsg, errfix));
      end if;
    
      -- Valida se data de negocia��o � muito superior a data atual
      if :new.dtneg > trunc(sysdate) + 30 then
        errtitle := 'Inclus�o / Edi��o Cancelada';
        errmsg   := 'Data Negocia��o n�o pode ser superior a ' || to_date(trunc(sysdate) + 30, 'DD/MM/YYYY');
        errfix   := 'Corrija as datas informadas';
        raise_application_error(-20101, fc_formatahtml_sf(errtitle, errmsg, errfix));
      end if;
    
      -- Data de vencimento n�o pode ser programada para final de semana e feriados
      if ad_get.dia_util(p_data => :new.dtvenc) > 0 or ad_get.dia_util(p_data => :new.dtvenc1) > 0 then
        errtitle := 'Inclus�o / Edi��o Cancelada';
        errmsg   := 'Vencimento n�o pode ser programado para finais de semana e feriados!!';
        errfix   := 'Corrija as datas informadas';
        raise_application_error(-20101, fc_formatahtml_sf(errtitle, errmsg, errfix));
      end if;
    
      if :new.dtvenc1 < :new.dtvenc then
        errtitle := 'Inclus�o / Edi��o Cancelada';
        errmsg   := 'Data Vencimento da Primeira Parcela n�o pode ser inferior a Data de Vencimento da Despesa';
        errfix   := 'Corrija as datas informadas';
        raise_application_error(-20101, fc_formatahtml_sf(errtitle, errmsg, errfix));
      end if;
    
      -- Valor n�o pode ser menor que zero
      if :new.vlrdesdob <= 0 then
        errtitle := 'Inclus�o / Edi��o Cancelada';
        errmsg   := 'Valor deve ser maior que zero';
        errfix   := 'Corrija os valores informados';
        raise_application_error(-20101, fc_formatahtml_sf(errtitle, errmsg, errfix));
      end if;
    
      -- Valida n�mero de parcelas
      if :new.nrparcelas <= 0 or :new.nrparcelas > 360 then
        errtitle := 'Inclus�o / Edi��o Cancelada';
        errmsg   := 'N�mero de parcelas informadas � inv�lido';
        errfix   := 'Corrija o n�mero de parcelas';
        raise_application_error(-20101, fc_formatahtml_sf(errtitle, errmsg, errfix));
      end if;
    
      -- Valida o CR  
      if nvl(:new.codcencusresp, 0) > 0 then
        select count(*)
          into v_count
          from tsicus c
         where c.codcencus = :new.codcencusresp
           and c.analitico = 'S'
           and exists (select 1
                  from ad_itesolcpalibcr cr
                 where c.codcencus = cr.codcencus
                   and nvl(cr.aprova, 'N') = 'S');
      
        if v_count = 0 then
          errtitle := 'Inclus�o / Edi��o Cancelada';
          errmsg   := 'CR Aprovador informado n�o est� ativo ou n�o � anal�tico ou n�o tem aprovador vinculado!';
          errfix   := 'Reveja o cadastro de CR e corrija as informa��es';
          raise_application_error(-20101, fc_formatahtml_sf(errtitle, errmsg, errfix));
        end if;
      
      end if;
    
      -- Valida se a natureza ou o centro de resultado exige projeto
      select count(*)
        into v_count
        from ad_adtssaconfnat c
       where c.codnat = :new.codnat
         and nvl(c.exigeprojeto, 'N') = 'S'
         and c.codigo = :new.tipo;
    
      if v_count > 0 and :new.codproj = 0 then
        errtitle := 'Inclus�o / Edi��o Cancelada';
        errmsg   := 'Natureza exige que seja informado projeto';
        errfix   := 'Verifique e informe o projeto que melhor se adequa � necessidade';
        raise_application_error(-20101, fc_formatahtml_sf(errtitle, errmsg, errfix));
      end if;
    
      -- valida projeto
      if :new.codproj > 0 then
        select count(*)
          into v_count
          from tcsprj p
         where p.codproj = :new.codproj
           and p.analitico = 'S';
      
        if v_count = 0 then
          errtitle := 'Inclus�o / Edi��o Cancelada';
          errmsg   := 'Projeto informado n�o est� ativo ou n�o � anal�tico!';
          errfix   := 'Reveja o projeto informado e/ou o cadastro do mesmo';
          raise_application_error(-20101, fc_formatahtml_sf(errtitle, errmsg, errfix));
        end if;
      
        select nvl(p.ad_tipadt, 'N�o Informado')
          into v_tipoparcadt
          from tgfpar p
         where p.codparc = ad_analise_credito.codparcmatriz(nvl(:new.codparcrec, :new.codparc));
      
        if v_tipoparcadt = 'N�o Informado' then
          errtitle := 'Inclus�o / Edi��o Cancelada';
          errmsg   := 'O processo ' || :new.tipo || ' exige "Tipo de Parceiro Adto"';
          errfix   := 'Necess�ria corre��o o cadastro do parceiro' ||
                      ad_analise_credito.codparcmatriz(:new.codparc);
          raise_application_error(-20101, fc_formatahtml_sf(errtitle, errmsg, errfix));
        end if;
      
      end if;
    
      if conf.seacumular = 'B' then
      
        select count(*)
          into v_count
          from ad_centparampar p
         where p.codparc = :new.codparc
           and p.nupar = 9;
      
        if v_count = 0 then
          -- Se o parceiro esta na lista de exce��es � porque pode lan�ar mais de um adiantamento para ele
          v_codparcmatriz := ad_analise_credito.codparcmatriz(p_codparc => :new.codparc);
        
          begin
            select sum(vlrdesdob)
              into v_vlrdesdob
              from tgffin f, tgfpar p
             where f.codparc = p.codparc
               and p.codparcmatriz = v_codparcmatriz
               and f.recdesp = 1
               and f.provisao = 'N'
               and f.dhbaixa is null;
          exception
            when no_data_found then
              v_vlrdesdob := 0;
            when others then
              raise;
          end;
        
          if v_vlrdesdob > 0 then
            errtitle := 'Inclus�o / Edi��o Cancelada';
            errmsg   := 'Existem valores pendentes para esse parceiro, n�o � permitido lan�ar um segundo adiantamento';
            errfix   := 'Verifique a situa��o junto ao financeiro';
            raise_application_error(-20101, fc_formatahtml_sf(errtitle, errmsg, errfix));
          end if;
        
        end if;
      
      end if;
    
      -- Se alterar valor, n�mero de parcelas ou algum dos vencimentos deve gerar novamente as parcelas
      if updating('VLRDESDOB') or updating('NRPARCELAS') or updating('DTVENC') or updating('DTVENC1') or
         updating('TIPO') or nvl(:new.taxa, 0) <> nvl(:old.taxa, 0) then
      
        declare
          v_sessao varchar2(100);
        begin
          stp_set_atualizando('S');
        
          if (:new.vlrdesdob <> :old.vlrdesdob and :new.vlrdesdob > 0) or
             (:new.taxa <> :old.taxa and :new.taxa > 0) or (:new.taxa = 0 and :new.vlrdesdob > 0) then
          
            begin
              delete from ad_adtssapar where nunico = :new.nunico;
            exception
              when others then
                raise_application_error(-20105,
                                        'Erro ao excluir parcelas (' || :new.nunico || ')! ' || sqlerrm);
            end;
          
            /*
             ad_set.inseresessao(p_nome      => 'NUNICO',
                                 p_sequencia => 1,
                                 p_tipo      => 'I',
                                 p_valor     => :new.nunico,
                                 p_idsessao  => v_sessao);
            
             ad_set.inseresessao(p_nome      => '__CONFIRMACAO__',
                                 p_sequencia => 1,
                                 p_tipo      => 'S',
                                 p_valor     => 'S',
                                 p_idsessao  => v_sessao);
            
             ad_stp_adtssa_geraparcela_sf(p_codusu    => v_codusu,
                                          p_idsessao  => v_sessao,
                                          p_qtdlinhas => 1,
                                          p_mensagem  => errmsg);
            
             ad_set.remove_sessao(v_sessao);
            
             if errmsg is not null then
              raise_application_error(-20105, 'Erro ao gerar as parcelas! ' || errmsg);
             end if;
            */
          
          end if;
          stp_set_atualizando('N');
        
        end;
      
        :new.codusufin     := null;
        :new.codusuapr     := null;
        :new.dhaprovadt    := null;
        :new.dhaprovfin    := null;
        :new.dhsolicitacao := null;
      end if;
    
    end if;
  
    if deleting then
    
      if nvl(:old.nuacerto, 0) > 0 then
        errtitle := 'Exclus�o n�o permitida';
        errmsg   := 'Adiantamento j� gerado, a exclus�o do registro n�o � permitida';
        errfix   := 'Reabra a solicita��o';
        --raise_application_error(-20101, fc_formatahtml_sf(errtitle, errmsg, errfix));
        raise_application_error(-20105,
                                ad_fnc_formataerro(errtitle || '. ' || errmsg || '. ' || errfix || '!'));
      end if;
    
    end if;
  
    <<end_of_line>>
    null;
  end before each row;

  after each row is
    v_acao varchar2(20);
  begin
    -- insere o log
  
    if inserting then
      v_acao := 'Inclus�o';
    elsif deleting then
      v_acao := 'Exclus�o';
    end if;
  
    begin
      if v_acao is not null then
        insert into ad_adtssalgtt
          (nunico, dhalter, acao, codusu)
        values
          (nvl(:new.nunico, :old.nunico), sysdate, v_acao, v_codusu);
      end if;
    
    exception
      when others then
        raise;
    end;
  
  end after each row;
end;
/
