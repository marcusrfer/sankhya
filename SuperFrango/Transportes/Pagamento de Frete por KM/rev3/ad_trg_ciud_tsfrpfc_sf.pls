create or replace trigger ad_trg_ciud_tsfrpfc_sf
  for insert or update or delete on ad_tsfrpfc
  compound trigger

  i         int;
  e         varchar2(4000);
  liberado  boolean := false;
  precifica varchar2(1);
  rpf       ad_tsfrpfc%rowtype;

  /*
  * autor: m. rangel
  * processo: revisao de pagamento de frete km
  * objetivo: controlar o preenchimento dos campos da tela
  */

  before each row is
    v_qtdreg int;
  begin
  
    if variaveis_pkg.v_atualizando then
      goto end_section;
    end if;
  
    if inserting then
    
      if :new.codemp is null or :new.ordemcarga is null then
        e := 'As revisões devem ser inseridas pelo botão de ação "Adicionar Revisão"';
        raise_application_error(-20105, ad_fnc_formataerro(e));
      end if;
    
      if :new.peso is null then
        select sum(c.peso)
          into :new.peso
          from tgfcab c
         where c.codemp = :new.codemp
           and c.ordemcarga = :new.ordemcarga
           and tipmov = 'V'
           and statusnota = 'L';
      end if;
    
      if (:new.codregfre is not null and :new.codcat is not null) and :new.vlrfrereg is null then
      
        :new.vlrfrereg := ad_pkg_fkm.get_vlr_regfrete(p_codregfre => :new.codregfre, p_codcat => :new.codcat,
                                                      p_codparcorig => :new.codparcorig, p_distancia => 1);
      end if;
    
      if nvl(:new.distkm, 0) > 0 and nvl(:new.vlrfrereg, 0) > 0 then
        :new.vlrfrete := :new.distkm * :new.vlrfrereg;
      end if;
    
    elsif updating then
    
      -- quando preenchendo o codreg
      if :old.codregfre is null and :new.codregfre is not null then
      
        -- verifica a quantidade de regiões da oc
        select count(distinct codregfre)
          into v_qtdreg
          from table(ad_pkg_fkm.get_dados_frete(null, null, :new.codemp, :new.ordemcarga));
      
        -- se houver + q 1, permitir informar apenas as regiões presentes na oc
        if v_qtdreg > 1 then
        
          -- verifica se existe
          select count(distinct codregfre)
            into i
            from table(ad_pkg_fkm.get_dados_frete(null, null, :new.codemp, :new.ordemcarga))
           where codregfre = :new.codregfre;
        
          -- se não existir, erro!
          if i > 0 then
            precifica := ad_pkg_fkm.aux_check_precifica(null, null, :new.codregfre, :new.codcat);
          else
            e := q'[<html>
										</head>
										<style>table {width: 100%}</style>
										</head>
										<body>
										<p>Somente as regiões listadas abaixo podem ser utilizadas!!!</p>
										<table class="table-bordered">
										<tr><th>Cód. Região</th><th>Região</th><th class="text-center">%Peso</th></tr>]';
            for err in (with pesototal as
                           (select codemp, ordemcarga, sum(peso) pesototal
                             from tgfcab
                            where tipmov = 'V'
                              and statusnota = 'L'
                              and codemp = :new.codemp
                              and ordemcarga = :new.ordemcarga
                            group by codemp, ordemcarga)
                          select codregfre, descrregfre nomereg, round((sum(peso) / t.pesototal) * 100) varpeso,
                                 ad_pkg_fkm.aux_check_precifica(null, null, c.codregfre, c.codcat) precifica
                            from table(ad_pkg_fkm.get_dados_frete(null, null, :new.codemp, :new.ordemcarga)) c
                            join pesototal t
                              on t.codemp = c.codemp
                             and t.ordemcarga = c.ordemcarga
                           where 1 = 1
                          --and ad_pkg_fkm.aux_check_precifica(null, null, c.codregfre, c.codcat) = 'S'
                           group by codregfre, descrregfre, t.pesototal, codcat)
            loop
              if nvl(err.precifica, 'N') = 'S' then
                e := e || '<tr><td>' || err.codregfre || '</td><td>' || err.nomereg || '</td><td class="text-center">' ||
                     err.varpeso || '</td></tr>';
              else
                e := e || '<tr style="color:red;"><td>' || err.codregfre || '</td><td>' || err.nomereg ||
                     '</td><td class="text-center">' || err.varpeso || '</td></tr>';
              end if;
            
            end loop;
            e := e || '</table><br><p>***As regiões em vermelho não participam do frete por km.</p></body></html>';
            raise_application_error(-20105, ad_fnc_formataerro(e));
          end if;
        
        else
        
          precifica := ad_pkg_fkm.aux_check_precifica(null, null, :new.codregfre, :new.codcat);
        
        end if;
      
        :new.vlrfrereg := ad_pkg_fkm.get_vlr_regfrete(:new.codregfre, :new.codcat, null, 1);
      
      end if;
    
      -- new codregfre is null
      if :old.codregfre is not null and :new.codregfre is null then
      
        :new.vlrfrereg := null;
        :new.vlrfrete  := null;
      
      end if;
    
      if nvl(:new.distkm, 0) > 0 and nvl(:new.vlrfrereg, 0) > 0 then
        :new.vlrfrete := ad_pkg_fkm.get_vlr_regfrete(:new.codregfre, :new.codcat, null, :new.distkm);
      end if;
    
      -- impedir alrações quando revisão já foi liberada    
      if :old.status = 'L' then
        e := 'Revisões liberadas não podem ser alteradas';
        raise_application_error(-20105, ad_fnc_formataerro(e));
      end if;
    
      -- tratativa para quando há variação de distância
      if :old.motivo = '2' and :old.distkm > 0 and (:new.distkm != :old.distkm) then
        :new.motivo := '3';
      end if;
    
      :new.vlrfrete := nvl(:new.distkm, 0) * nvl(:new.vlrfrereg, 0);
    
      -- "marca para precificar no after
      if :new.status = 'L' then
        liberado       := true;
        precifica      := ad_pkg_fkm.aux_check_precifica(null, null, :new.codregfre, :new.codcat);
        rpf.nurpfc     := :new.nurpfc;
        rpf.codemp     := :new.codemp;
        rpf.ordemcarga := :new.ordemcarga;
        rpf.motivo     := :new.motivo;
        rpf.vlrfrete   := :new.vlrfrete;
        rpf.peso       := :new.peso;
      end if;
    
    elsif deleting then
      null;
    end if;
  
    <<end_section>>
    null;
  
  end before each row;

  after statement is
    cab ad_tsfdef%rowtype;
    rec ad_tsfdefr%rowtype;
  begin
    -- precifica se liberado
    if liberado then
    
      if rpf.motivo in ('1', '2') then
      
        if precifica = 'S' then
          ad_pkg_fkm.set_vlrfrete_notas(rpf.codemp, rpf.ordemcarga, e);
        
          if e is not null then
            raise_application_error(-20105, ad_fnc_formataerro(e));
          end if;
        
        else
        
          begin
            update tgford
               set tipcalcfrete = null
             where codemp = rpf.codemp
               and ordemcarga = rpf.ordemcarga;
          exception
            when others then
              e := 'Erro ao voltar OC para precificação por rota. ' || sqlerrm;
              raise_application_error(-20105, ad_fnc_formataerro(e));
          end;
        
        end if; --precifica
      
      else
        --header
        begin
          stp_keygen_tgfnum('AD_TSFDEF', 1, 'AD_TSFDEF', 'NUDEF', 0, cab.nudef);
        
          select o.codparctransp, o.codveiculo
            into cab.codparctransp, cab.codveiculo
            from tgford o
           where o.codemp = rpf.codemp
             and o.ordemcarga = rpf.ordemcarga;
        
          insert into ad_tsfdef
            (nudef, codemp, ordemcarga, tipo, codparctransp, codveiculo, codusuinc, dtinclusao, status, codnatped,
             codcencusped, codtipoperped, codprod, codtipvendaped, codempfin, nuevento)
          values
            (cab.nudef, rpf.codemp, rpf.ordemcarga, 'KM', cab.codparctransp, cab.codveiculo, stp_get_codusulogado,
             sysdate, 'A', 4053600, 100100800, 170, 35815, 54, rpf.codemp, 1011);
        exception
          when others then
            e := 'Erro ao inserir cabeçalho da despesa extra frete. ' || sqlerrm;
            raise_application_error(-20105, ad_fnc_formataerro(e));
        end;
      
        -- recibo
        begin
          stp_set_atualizando('S');
        
          begin
            select codcencus
              into rec.codcencus
              from tgfcab c
             where c.codemp = rpf.codemp
               and c.ordemcarga = rpf.ordemcarga
               and tipmov = 'V'
               and statusnota = 'L'
             group by codcencus;
          exception
            when too_many_rows then
              rec.codcencus := 804000000;
              rec.rateio_oc := 'S';
            when others then
              rec.codcencus := 0;
          end;
        
          insert into ad_tsfdefr
            (nurecibo, nudef, dtneg, numnota, vlrdesdob, codnat, codcencus, codproj, historico, codmotpai, codmot,
             rateio_oc, usacrmot, nutabela)
          values
            (1, cab.nudef, to_date(sysdate, 'dd/mm/yyyy'), null, rpf.vlrfrete, 4053600, rec.codcencus, 0,
             'Ref. diferença de frete', 900, 901, rec.rateio_oc, null, null);
        
          stp_set_atualizando('N');
        exception
          when others then
            e := 'Erro ao inserir o recibo da despesa extra de frete.' || sqlerrm;
            raise_application_error(-20105, ad_fnc_formataerro(e));
        end;
      
        -- ligação externa
        begin
          insert into ad_tblcmf
            (nometaborig, nuchaveorig, nometabdest, nuchavedest)
          values
            ('AD_TSFRPFC', rpf.nurpfc, 'AD_TSFDEF', cab.nudef);
        exception
          when others then
            raise;
        end;
      
        -- log da revisão
        begin
          stp_set_atualizando('S');
          update ad_tsfrpfc
             set log = log || chr(13) || to_date(sysdate, 'dd/mm/yyyy hh24:mi:ss') || ' - ' ||
                       ad_get.nomeusu(stp_get_codusulogado, 'completo') || ' - ' ||
                       'Geração da despesa extra de frete nro ' || cab.nudef
           where nurpfc = rpf.nurpfc;
          stp_set_atualizando('N');
        exception
          when others then
            raise;
        end;
      end if;
    
    end if;
  end after statement;

end;
/
