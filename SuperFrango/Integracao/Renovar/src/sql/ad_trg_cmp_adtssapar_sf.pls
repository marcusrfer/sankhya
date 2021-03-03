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
  Objetivo:  Controle de Altera��es feitas pelo usu�rio em tela, procedure vinculado a evento da tabela.
  
  Autor:     Ricardo Soares de Oliveira
  Alterado:  24/07/2018
  Objetivo:  Foi habilitado para altera��es o campo VLRDESDOB e criado um campo na AD_ADTSSACONFUSU
  para identificar se o usu�rio tem permiss�o de alterar o valor do desdobramento,
  que at� ent�o era bloqueado para altera��es, e criado aqui uma regra que valida se o usu�rio pode ou n�o alterar.
  
  
  Revis�o: Marcus Rangel
  Dt. Revis�o: 16/10/2019
  
  **************************/

  -- * Importante: As a��es que geram os lan�amentos e parcelas

  before each row is
  
  begin
  
    if stp_get_atualizando or ad_pkg_var.permite_update then
      goto end_of_line;
    end if;
  
    select * into adto from ad_adtssacab c where c.nunico = nvl(:new.nunico, :old.nunico);
  
    -- verifica permiss�es do usu�rio
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
        errm := 'Usu�rio n�o possui permiss�o para utilizar esse processo!';
        raise_application_error(-20105, ad_fnc_formataerro(errm));
    end;
  
    -- dispara valida��es da tela master
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
                                fc_formatahtml_sf('Inclus�o n�o permitida',
                                                   'Utilize a a��o <quote>Gerar Parcelas</quote>',
                                                   null));
      end if;
    
    end if;
  
    if updating then
    
      -- valida se j� existem lan�amentos descendentes
      if :new.nufin > 0 then
        raise_application_error(-20105,
                                fc_formatahtml_sf(p_mensagem => 'Altera��o Cancelada!',
                                                   p_motivo => 'J� existe n�mero �nico gerado para o lan�amento.',
                                                   p_solucao => 'Verifique se o lan�amento est� correto.',
                                                   p_error => sqlerrm));
      
        -- valida altera��o de data de vencimento
        if :new.dtvenc <> :old.dtvenc then
        
          if (:new.dtvenc - :new.dtvencinic) > 0 and (:new.dtvenc - :new.dtvencinic) > v_ajustavenc then
            raise_application_error(-20101,
                                    fc_formatahtml_sf('Altera��o Cancelada',
                                                       'Ajuste vencimento superior ao permitido', null));
          end if;
        end if;
      end if;
    
      -- valida permiss�o para altera��o de valor
    
      if updating('VLRDESDOB') then
      
        if v_altvlrdesdob = 'N' and (:new.vlrdesdob <> :old.vlrdesdob) then
          errm := 'Altera��o Cancelada!<br>Usu�rio logado n�o tem permiss�es ' ||
                  'para realizar altera��es no campo Vlr. Desdobramento.';
          raise_application_error(-20105, ad_fnc_formataerro(errm));
        end if;
      
      end if;
    
      if updating('VLRJUROS') then
        if v_altvlrjuros = 'N' then
          errm := 'Altera��o Cancelada!<br>Usu�rio logado n�o tem'' permiss�es ' ||
                  'para realizar altera��es no campo Vlr. Juros.';
          raise_application_error(-20105, ad_fnc_formataerro(errm));
        end if;
      end if;
    
      -- valida se dtvenc � dia util
      if ad_get.dia_util(:new.dtvenc) > 0 then
        errm := 'Inclus�o Cancelada! \n Vencimento n�o pode ser programado ' ||
                'para finais de semana e feriados!!';
        raise_application_error(-20101, ad_fnc_formataerro(errm));
      
      end if;
    
    end if;
  
    if deleting then
    
      if not ad_pkg_var.permite_update then
        errm := 'Exclus�o n�o permitida, as parcelas s�o geradas ' ||
                'autom�ticamente ao executar a op��o "Gerar Parcelas" ' ||
                'ou ent�o ao alterar algum registro no cabe�alho';
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
