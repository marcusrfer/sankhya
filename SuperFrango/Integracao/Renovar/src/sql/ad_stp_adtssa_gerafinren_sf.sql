create or replace procedure ad_stp_adtssa_gerafinren_sf(p_nunico      number,
                                                        p_aprov_fin   int,
                                                        p_mensagemusu varchar2) as
 /*
   Autor: MARCUS.RANGEL 16/10/2019 11:05:52
   Objetivos: geração das receitas e despesas dos adiantamentos  e  emprestimo do processo renovar.
 */

 cab  ad_adtssacab%rowtype;
 conf ad_adtssaconf%rowtype;
 fin  tgffin%rowtype;
 mail tmdfmg%rowtype;

 v_nuacerto    number;
 v_sequencia   int := 0;
 v_codusu      int := stp_get_codusulogado;
 v_codusulibib int;
 errmsg        varchar2(4000);

begin

 --p_nunico    := 3501;
 --p_aprov_fin := 0;

 select c.* into cab from ad_adtssacab c where c.nunico = p_nunico;
 select c.* into conf from ad_adtssaconf c where c.codigo = cab.tipo;

 if nvl(conf.renovar, 'N') = 'N' then
  return;
 end if;

 for r in (select *
             from (select p.sequencia, p.nunico, p.nufin, nvl(cab.codparcrec, cab.codparc) codparc,
                           p.dtvenc, p.vlrdesdob, p.vlrjuros, p.vlrtotal, p.recdesp, p.provisao,
                           p.nrparcela, p.dtvencinic, '' historico, cab.numnota
                      from ad_adtssapar p
                      join ad_adtssacab cab
                        on cab.nunico = p.nunico
                     where p.recdesp = 1
                    union all
                    select sequencia, nunico, nufindesp, codparc, dtvenc, vlrdesdob, 0, vlrdesdob, '-1',
                           'S', sequencia, dtvenc, historico, numnota
                      from ad_adtssaparrenovar)
            where nunico = p_nunico)
 loop
 
  stp_keygen_nufin(fin.nufin);
  fin.numnota := case
                  when r.recdesp = -1 then
                   r.numnota
                  else
                   cab.nunico
                 end;
  fin.codparc      := r.codparc;
  fin.codtipoper := case
                     when r.recdesp = 1 then
                      conf.codtipoperrec
                     else
                      conf.codtipoperdesp
                    end;
  fin.dhtipoper    := ad_get.maxdhtipoper(fin.codtipoper);
  fin.codctabcoint := nvl(cab.codctabcoint, conf.codctabcoint);
  fin.historico := case
                    when r.recdesp = -1 then
                     cab.historico || '  - ' || r.historico
                    else
                     cab.historico
                   end;
  fin.provisao := case
                   when conf.exigaprdesp = 'S' and p_aprov_fin = 1 then
                    'S'
                   else
                    'N'
                  end;
  fin.codtiptit := case
                    when r.recdesp = -1 then
                     case
                      when cab.forma = '1' then
                       56 --cred conta
                      when cab.forma = '2' then
                       4 --Cheque
                      when cab.forma = '3' then
                       6 --Espécie
                      when cab.forma = '4' then
                       61 --Compensação
                      when cab.forma = '36' then
                       5 --Boleto
                      else
                       3
                     end
                    else
                     61
                   end;
 
  fin.vlrjuronegoc := r.vlrjuros;
 
  begin
   -- insere as receitas
   insert into tgffin
    (nufin, codemp, numnota, dtneg, desdobramento, dhmov, dtvenc, dtvencinic, codparc, codtipoper,
     dhtipoper, codctabcoint, codnat, codcencus, codproj, codtiptit, vlrdesdob, vlrjuronegoc,
     recdesp, provisao, origem, codusu, dtalter, desdobdupl, historico, codbco, ad_variacao,
     ad_modcred)
   values
    (fin.nufin, cab.codemp, fin.numnota, cab.dtneg, r.nrparcela, sysdate, r.dtvenc, r.dtvencinic,
     fin.codparc, fin.codtipoper, fin.dhtipoper, fin.codctabcoint, cab.codnat, cab.codcencus,
     cab.codproj, fin.codtiptit, r.vlrdesdob, fin.vlrjuronegoc, r.recdesp, fin.provisao, 'F',
     stp_get_codusulogado, sysdate, 'ZZ', fin.historico, 1, 'adtSsa', cab.modcred);
  exception
   when others then
    raise;
  end;
 
  -- atualiza as parcelas
  begin
   stp_set_atualizando('S');
  
   if r.recdesp = 1 then
    update ad_adtssapar p
       set p.nufin    = fin.nufin,
           p.provisao = fin.provisao
     where p.nunico = r.nunico
       and p.sequencia = r.sequencia;
   else
    update ad_adtssaparrenovar ren
       set ren.nufindesp = fin.nufin
     where ren.nunico = r.nunico
       and ren.sequencia = r.sequencia;
   end if;
  
   stp_set_atualizando('S');
  
  exception
   when others then
    raise;
  end;
 
  -- insere o acerto
  begin
  
   if v_nuacerto is null then
    stp_keygen_tgfnum('TGFFRE', 1, 'TGFFRE', 'NUACERTO', 0, v_nuacerto);
   end if;
  
   v_sequencia := v_sequencia + 1;
  
   insert into tgffre
    (codusu, dhalter, nuacerto, nufin, nufinorig, nunota, sequencia, tipacerto)
   values
    (v_codusu, sysdate, v_nuacerto, fin.nufin, null, null, v_sequencia, 'A');
  exception
   when others then
    raise;
  end;
 
  -- atualiza o nro do acerto no financeiro
  begin
   update tgffin
      set dtalter   = sysdate,
          nucompens = v_nuacerto,
          numdupl   = v_nuacerto,
          numnota   = fin.numnota
    where tgffin.nufin = fin.nufin;
  exception
   when others then
    raise_application_error(-20105,
                            'Erro! ao atualizar o nro do acerto no financeiro. ' || sqlerrm);
  end;
 
  -- insere ligação
  begin
   insert into ad_tblcmf
    (nometaborig, nuchaveorig, nometabdest, nuchavedest)
   values
    ('AD_ADTSSACAB', cab.nunico, 'TGFFIN', fin.nufin);
  exception
   when others then
    raise_application_error(-20105, 'Erro! Criação da ligação entre as tabelas. ' || sqlerrm);
  end;
 
 end loop;

 -- se tipo de processo exige aprov despesa
 if conf.exigaprdesp = 'S' then
 
  --se foi identificado necessidade de lib financeira
  if p_aprov_fin = 1 then
  
   ad_set.ins_liberacao(p_tabela    => 'AD_ADTSSACAB',
                        p_nuchave   => p_nunico,
                        p_evento    => 1042,
                        p_valor     => 1,
                        p_codusulib => nvl(conf.codusuapr, 946),
                        p_obslib    => 'Adiantamento ' || p_nunico || ', com Divergência de ' ||
                                       p_mensagemusu,
                        p_errmsg    => errmsg);
  
   if errmsg is not null then
    raise_application_error(-20105, errmsg);
   end if;
  
   -- Busca usuários que estão vinculados ao perfil 13 (>>Bi Móvel >>Cadastro >>Perfil)
   mail.email := ad_get.mailfila(13);
  
   ad_stp_gravafilabi(p_assunto  => 'Liberação Adiantamento Financeiro',
                      p_mensagem => 'Acaba de ser incluido o adiantamento ' || p_nunico ||
                                    '. Favor verificar as liberações pendentes!' || chr(13) ||
                                    chr(10) || 'Obrigado.' || chr(13) || chr(10) ||
                                    'Stp_Adtssacab_Gerafin_Sf' || chr(13) || chr(10) ||
                                    'e-mail enviado para: ' || mail.email,
                      p_email    => mail.email);
  
  end if;
 
  v_codusulibib := ad_confirma_fin.usulibfin(p_codtipoper => conf.codtipoperdesp,
                                             p_exige      => 'F',
                                             p_codnat     => cab.codnat,
                                             p_codcencus  => cab.codcencusresp,
                                             p_codcencusr => cab.codcencusresp);
 
  ad_set.ins_liberacao(p_tabela    => 'AD_ADTSSACAB',
                       p_nuchave   => p_nunico,
                       p_evento    => 1035,
                       p_valor     => cab.vlrdesdob,
                       p_codusulib => v_codusulibib,
                       p_obslib    => 'Adiantamento ' || cab.nunico,
                       p_errmsg    => errmsg);
 
  if errmsg is not null then
   raise_application_error(-20105, errmsg);
  end if;
 
  begin
   update tsilib l
      set l.ad_nuadto = v_nuacerto,
          l.vlrlimite = 1
    where l.nuchave = p_nunico
      and l.tabela = 'AD_ADTSSACAB';
  exception
   when others then
    raise_application_error(-20105, 'Erro! Ao atualizar a lib. ' || sqlerrm);
  end;
 
 end if;

 begin
  update ad_adtssacab c
     set c.situacao = case
                       when conf.exigaprdesp = 'N' then
                        'A'
                       else
                        'P'
                      end,
         c.nuacerto      = v_nuacerto,
         c.codusufin = case
                        when p_aprov_fin = 1 then
                         nvl(conf.codusuapr, 946)
                        else
                         null
                       end,
         c.dhsolicitacao = sysdate,
         c.codusuapr = case
                        when conf.exigaprdesp = 'N' then
                         v_codusu
                        else
                         v_codusulibib
                       end,
         c.dhaprovadt = case
                         when conf.exigaprdesp = 'N' then
                          sysdate
                         else
                          null
                        end
   where c.nunico = p_nunico;
 exception
  when others then
   raise_application_error(-20105, 'Erro! Ao atualizar o adiantemento. ' || sqlerrm);
 end;

end;
/
