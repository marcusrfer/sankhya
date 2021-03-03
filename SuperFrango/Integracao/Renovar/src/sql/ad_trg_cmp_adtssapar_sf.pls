create or replace trigger ad_trg_cmp_adtssapar_sf
  for delete or insert or update on sankhya.ad_adtssapar
  referencing new as new old as old
  compound trigger

  adto ad_adtssacab%rowtype;
  new  ad_adtssapar%rowtype;

  v_podeusartela int;
  v_ajustavenc   int;
  v_altvlrdesdob varchar(1);
  v_altvlrjuros  varchar2(1);
  v_renovar      varchar2(1);

  errm varchar2(4000);

  /**************************
  Autor:     Ricardo Soares de Oliveira
  Criado em: 09/02/2018
  Objetivo:  Controle de Alterações feitas pelo usuário em tela, procedure vinculado a evento da tabela.
  
  Autor:     Ricardo Soares de Oliveira
  Alterado:  24/07/2018
  Objetivo:  Foi habilitado para alterações o campo VLRDESDOB e criado um campo na AD_ADTSSACONFUSU
  para identificar se o usuário tem permissão de alterar o valor do desdobramento,
  que até então era bloqueado para alterações, e criado aqui uma regra que valida se o usuário pode ou não alterar.
  
  
  Revisão: Marcus Rangel
  Dt. Revisão: 16/10/2019
  
  **************************/

  -- * Importante: As ações que geram os lançamentos e parcelas

  before each row is
  
  begin
  
    if stp_get_atualizando or ad_pkg_var.permite_update then
      goto end_of_line;
    end if;
  
    select * into adto from ad_adtssacab c where c.nunico = nvl(:new.nunico, :old.nunico);
  
    -- verifica permissões do usuário
    begin
      select nvl(conf.ajustavenc, 0), nvl(usu.altvlrdesdob, 'N'), nvl(usu.altvlrjuros, 'N'),
             nvl(conf.renovar, 'N')
        into v_ajustavenc, v_altvlrdesdob, v_altvlrjuros, v_renovar
        from ad_adtssaconf conf
        join ad_adtssaconfusu usu
          on conf.codigo = usu.codigo
         and usu.codusu = stp_get_codusulogado
        join ad_adtssacab cab
          on conf.codigo = cab.tipo
       where cab.nunico = :new.nunico;
    exception
      when no_data_found then
        errm := 'Usuário não possui permissão para utilizar esse processo!';
        raise_application_error(-20105, ad_fnc_formataerro(errm));
    end;
  
    -- dispara validações da tela master
    begin
    
      ---stp_set_atualizando('S'); --- BY RODRIGO ACERTADO COM O MARCUS DIA 20/02/2020
      update ad_adtssacab c set c.dhalter = sysdate where c.nunico = nvl(:new.nunico, :old.nunico);
      --stp_set_atualizando('N');
    exception
      when others then
        raise_application_error(-20105, 'Erro!' || sqlerrm);
    end;
  
    if inserting then
    
      -- verifica se inserindo a partir da procedure de gerar parcelas
      if not ad_pkg_var.permite_update then
        raise_application_error(-20101,
                                fc_formatahtml_sf('Inclusão não permitida',
                                                   'Utilize a ação <quote>Gerar Parcelas</quote>',
                                                   null));
      end if;
    
    end if;
  
    if updating then
    
      -- valida se já existem lançamentos descendentes
      if :new.nufin > 0 then
        raise_application_error(-20105,
                                fc_formatahtml_sf(p_mensagem => 'Alteração Cancelada!',
                                                   p_motivo => 'Já existe número único gerado para o lançamento.',
                                                   p_solucao => 'Verifique se o lançamento está correto.',
                                                   p_error => sqlerrm));
      
        -- valida alteração de data de vencimento
        if :new.dtvenc <> :old.dtvenc then
        
          if (:new.dtvenc - :new.dtvencinic) > 0 and (:new.dtvenc - :new.dtvencinic) > v_ajustavenc then
            raise_application_error(-20101,
                                    fc_formatahtml_sf('Alteração Cancelada',
                                                       'Ajuste vencimento superior ao permitido', null));
          end if;
        end if;
      end if;
    
      -- valida permissão para alteração de valor
    
      if updating('VLRDESDOB') then
      
        if v_altvlrdesdob = 'N' and (:new.vlrdesdob <> :old.vlrdesdob) then
          errm := 'Alteração Cancelada!<br>Usuário logado não tem permissões ' ||
                  'para realizar alterações no campo Vlr. Desdobramento.';
          raise_application_error(-20105, ad_fnc_formataerro(errm));
        end if;
      
      end if;
    
      if updating('VLRJUROS') then
        if v_altvlrjuros = 'N' then
          errm := 'Alteração Cancelada!<br>Usuário logado não tem'' permissões ' ||
                  'para realizar alterações no campo Vlr. Juros.';
          raise_application_error(-20105, ad_fnc_formataerro(errm));
        end if;
      end if;
    
      -- valida se dtvenc é dia util
      if ad_get.dia_util(:new.dtvenc) > 0 then
        errm := 'Inclusão Cancelada! \n Vencimento não pode ser programado ' ||
                'para finais de semana e feriados!!';
        raise_application_error(-20101, ad_fnc_formataerro(errm));
      
      end if;
    
    end if;
  
    if deleting then
    
      if not ad_pkg_var.permite_update then
        errm := 'Exclusão não permitida, as parcelas são geradas ' ||
                'automáticamente ao executar a opção "Gerar Parcelas" ' ||
                'ou então ao alterar algum registro no cabeçalho';
        raise_application_error(-20101, ad_fnc_formataerro(errm));
      end if;
    
    end if;
  
    <<end_of_line>>
    null;
  end before each row;

  after statement is
  begin
    null;
  end after statement;

end;
/
