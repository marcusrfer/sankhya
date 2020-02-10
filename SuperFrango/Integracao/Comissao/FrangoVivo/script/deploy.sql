--------------------------------------------------------
--  DDL for Trigger AD_TRG_BIUD_TSFFCIBNF_SF
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE TRIGGER "AD_TRG_BIUD_TSFFCIBNF_SF" 
  before insert or update or delete on ad_tsffcibnf
  for each row

begin
  if stp_get_atualizando then
    return;
  end if;

  if updating then
  
    update ad_tsffci f
       set f.codusualter = stp_get_codusulogado,
           f.dhalter     = sysdate
     where f.numlote = nvl(:old.numlote, :new.numlote);
  
    if :old.nunota is not null and :new.nunota is null then
      update ad_tsffci f
         set f.statusbonif = 'A'
       where f.numlote = nvl(:new.numlote, :old.numlote);
    end if;
  
  end if;

end;

/
ALTER TRIGGER "AD_TRG_BIUD_TSFFCIBNF_SF" ENABLE;
--------------------------------------------------------
--  DDL for Trigger AD_TRG_CMP_TSFFCIFIN_SF
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE TRIGGER "AD_TRG_CMP_TSFFCIFIN_SF" 
  for insert or update or delete on ad_tsffcifin
  compound trigger

  conf   ad_tsffciconf%rowtype;
  modelo ad_tsfmgn%rowtype;

  e varchar2(4000);
  i int;

  before each row is
    v_atualiza boolean default false;
  
  begin
    -- quando limpa o nufin da tabela pela FK
    if :old.nufin is not null and :new.nufin is null then
      goto final_trgigger;
    end if;
  
    -- preenchendo a data de vencimento
    if (updating('DTVENC') or updating('VLRDESDOB')) and :new.nufin is not null then
      e := 'Lançamentos com financeiro gerados não podem ser alterados!';
      raise_application_error(-20105, ad_fnc_formataerro(e));
    else
      stp_set_atualizando('S');
      update ad_tsffci f
         set f.codusualter = stp_get_codusulogado,
             f.dhalter     = sysdate
       where numlote = nvl(:old.numlote, :new.numlote);
      stp_set_atualizando('N');
    end if;
  
    /* if updating('DTVENC') and :new.origem = 'COM' then
    
      -- busca a top da configuração    
      ad_pkg_fci.get_config(trunc(sysdate), conf);
    
      select * into modelo from ad_tsfmgn where numodelo = conf.numodcpafrv;
    
      -- verifica se a nota de compra já foi gerada
      select count(*)
        into i
        from ad_tsffcinf n
       where n.numlote = :new.numlote
         and n.codtipoper = modelo.codtipoper;
    
      if i > 0 then
        v_atualiza := true;
      end if;
    
    else
      v_atualiza := true;
    end if;*/
  
    /*if v_atualiza then
      begin
      
      exception
        when others then
          e := 'Erro ao atulizar a data de alteração na tela principal. ' ||
               sqlerrm;
          raise_application_error(-20105, ad_fnc_formataerro(e));
      end;
    end if;*/
  
    <<final_trgigger>>
    null;
  end before each row;

end;

/
ALTER TRIGGER "AD_TRG_CMP_TSFFCIFIN_SF" ENABLE;
--------------------------------------------------------
--  DDL for Trigger AD_TRG_CMP_TSFFCI_SF
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE TRIGGER "AD_TRG_CMP_TSFFCI_SF" 
  for insert or update or delete on ad_tsffci
  compound trigger

  i int;
  e varchar2(4000);

  /*before statement is
  begin
    null;
  end before statement;*/

  before each row is
  begin
  
    if inserting then
      null;
    elsif updating then
    
      if (:old.statuslote = :new.statuslote) and :new.statuslote in ('F', 'L') and
         not variaveis_pkg.v_atualizando then
        e := 'Lotes <b>"Finalizados"</b> ou <b>"Em faturamento"</b> ' ||
             'não podem ser editados';
        raise_application_error(-20105, ad_fnc_formataerro(e));
      end if;
    
      -- atualiza status bonificação quando nota confirmada    
      if :old.statusbonif = 'F' then
      
        select count(*)
          into i
          from ad_tsffcibnf b
          join ad_tsffcinf n
            on b.nunota = n.nunota
         where n.statusnota = 'L';
      
        if i > 0 then
          :new.statusbonif := 'L';
        end if;
      
      end if;
    
      if :old.statuslote = 'F' then
      
        select count(*)
          into i
          from ad_tsffcinf n
         where n.codtipoper in (152, 329, 401, 365)
           and n.statusnota != 'L';
      
        if i = 4 then
          :new.statuslote := 'L';
        elsif i = 0 then
          :new.statuslote := 'A';
        end if;
      end if;
    
      if updating('QTDAVES') or updating('QTDABAT') or updating('QTDRACAO') or
         updating('PESO') or updating('IDADE') then
      
        :new.viabilidade := round(snk_dividir(:new.qtdabat, :new.qtdaves) * 100,
                                  3);
        :new.pesolote    := round(:new.peso / :new.qtdabat, 3);
        :new.ganholote   := round((:new.pesolote / :new.idade) * 1000, 2);
        :new.calote      := round(snk_dividir(:new.qtdracao, :new.peso), 3);
        :new.fplote      := round(snk_dividir((:new.viabilidade *
                                              :new.ganholote),
                                              (:new.calote * 10)),
                                  2);
        :new.qtdmortes   := :new.qtdaves - :new.qtdabat;
        :new.ipsulote    := round((:new.viabilidade * 0.1) *
                                  (:new.ganholote * 0.35) /
                                  (:new.calote * 0.55),
                                  3);
        :new.percom      := round(ad_pkg_fci.get_perc_com(:new.ipsulote,
                                                          :new.ipsumedio),
                                  2);
        :new.pesocom     := round(:new.peso * (:new.percom / 100), 3);
        :new.vlrcom      := round(:new.pesocom * :new.vlrunit, 3);
        :new.vlrcomliq   := round(:new.vlrcom - :new.vlrdespesas, 3);
        :new.dhinclusao  := sysdate;
      end if;
    
    elsif deleting then
    
      if :old.statuslote in ('F', 'L') then
        e := 'Lotes <b>"Finalizados"</b> ou <b>"Em faturamento"</b> ' ||
             'não podem ser editados';
        raise_application_error(-20105, ad_fnc_formataerro(e));
      end if;
    
    end if;
  
  end before each row;

  /*After each row is
  begin
    if inserting then
      null;
    elsif updating then
      null;
    elsif deleting then
      null;
    end if;
  end After each row;*/

  /*After Statement
  Is
  Begin
    Null;
  End After Statement;*/

end;

/
ALTER TRIGGER "AD_TRG_CMP_TSFFCI_SF" ENABLE;
--------------------------------------------------------
--  DDL for Procedure AD_STP_FCI_APROVABONIF_SF
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "AD_STP_FCI_APROVABONIF_SF" (p_codusu    number,
                                                      p_idsessao  varchar2,
                                                      p_qtdlinhas number,
                                                      p_mensagem  out varchar2) as
  b ad_tsffcibnf%rowtype;
  i int;
begin

  if p_qtdlinhas = 0 then
    p_mensagem := 'Selecione pelo menos 1 registro para aprovar.';
    return;
  end if;

  if p_qtdlinhas > 1 then
    p_mensagem := 'Selecione apenas um registro para aprovação!';
    return;
  end if;

  b.nufcibnf := act_int_field(p_idsessao, 1, 'NUFCIBNF');
  b.numlote  := act_int_field(p_idsessao, 1, 'NUMLOTE');

  select *
    into b
    from ad_tsffcibnf
   where numlote = b.numlote
     and nufcibnf = b.nufcibnf;

  if b.tipobonif = 'LR' then
    p_mensagem := 'Não há necessidade de aprovar o lote real, pois o mesmo é apenas ' ||
                  'uma demonstração dos valores calculados na tela principal.';
    return;
  end if;

  select count(*)
    into i
    from ad_tsffcibnf
   where numlote = b.numlote
     and nunota is not null;

  if i > 0 then
    p_mensagem := 'Já existe nota gerada para este lote, ' ||
                  'não é possível aprovar lançamentos após a geração da nota!';
    return;
  else
    -- se não possui nota gerada
  
    if b.vlrbonific = 0 then
      if act_confirmar('Bonificação sem valor.',
                       'A linha selecionada não possui valor de bonificação.' ||
                       ' Deseja aprová-la assim mesmo? Não será possível gerar nota com valor ZERO.',
                       p_idsessao,
                       0) then
        null;
      else
        return;
      end if;
    end if;
    stp_set_atualizando('S');
    update ad_tsffcibnf
       set aprovado = 'N'
     where numlote = b.numlote
       and nufcibnf != b.nufcibnf
       and tipobonif != 'LR';
  
    update ad_tsffcibnf
       set aprovado = 'S',
           codusu   = p_codusu,
           dhalter  = sysdate
     where numlote = b.numlote
       and nufcibnf = b.nufcibnf;
    stp_set_atualizando('N');
  
    if b.vlrbonific = 0 then
      return;
    end if;
  
    -- insere um linha na aba financeiro para programação
    declare
      fin ad_tsffcifin%rowtype;
      cfg ad_tsffciconf%rowtype;
    begin
      stp_set_atualizando('S');
      delete from ad_tsffcifin where origem = 'BNF';
      fin.numlote := b.numlote;
      fin.origem  := 'BNF';
    
      select nvl(max(f.nufcifin), 0) + 1, nvl(max(f.desdobramento), 0) + 1
        into fin.nufcifin, fin.desdobramento
        from ad_tsffcifin f
       where numlote = b.numlote;
    
      -- get dados da tela de parametros
      begin
        ad_pkg_fci.get_config(trunc(sysdate), cfg);
      
        select m.codnat, m.codcencus
          into fin.codnat, fin.codcencus
          from ad_tsfmgn m
         where m.numodelo = cfg.numodbnffrv;
      exception
        when others then
          raise;
      end;
    
      fin.dtvenc    := null;
      fin.vlrdesdob := b.vlrbonific;
      fin.codtiptit := cfg.codtiptitcom;
      fin.historico := 'Ref. Ajuda de Custo/Bonificação';
      fin.nufin     := null;
    
      insert into ad_tsffcifin values fin;
    
      update ad_tsffci f
         set f.tipobonif   = b.tipobonif,
             f.codusualter = p_codusu,
             f.dhalter     = sysdate
       where numlote = b.numlote;
    
      stp_set_atualizando('N');
    
    exception
      when others then
        p_mensagem := sqlerrm;
        return;
    end;
  
  end if;

  p_mensagem := 'Registro aprovado com sucesso!';

end;

/
--------------------------------------------------------
--  DDL for Procedure AD_STP_FCI_APROVFECH_SF
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "AD_STP_FCI_APROVFECH_SF" (p_codusu    number,
                                                    p_idsessao  varchar2,
                                                    p_qtdlinhas number,
                                                    p_mensagem  out varchar2) as
  field_numlote number;
begin

 /*
 * Autor: mrangel
 * Processo: Comissão integrado frango vivo
 * Objetivo: Marcar o lote como aprovado (substituindo a auditoria)
 */

  for i in 1 .. p_qtdlinhas
  loop
    field_numlote := act_int_field(p_idsessao, i, 'NUMLOTE');
    stp_set_atualizando('S');
  
    update ad_tsffci f
       set f.statuslote  = 'A',
           f.dhalter     = sysdate,
           f.codusualter = p_codusu,
           f.codusuaprov = p_codusu,
           f.dhaprov = sysdate
     where f.numlote = field_numlote;

    stp_set_atualizando('N');  
  end loop;

  p_mensagem := 'Lote Aprovado com sucesso!';

end;

/
--------------------------------------------------------
--  DDL for Procedure AD_STP_FCI_AUDITAVECOM_SF
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "AD_STP_FCI_AUDITAVECOM_SF" (p_codusu    number,
                                                      p_idsessao  varchar2,
                                                      p_qtdlinhas number,
                                                      p_mensagem  out varchar2) as

  /*
    Autor: MARCUS.RANGEL 07/11/2019 10:38:12
    Processo: fechamento de Comissão Integrado - FV
    Objetivo: Comparar os dados digitados pelo usuário com os valores inseridos na tela
  */
  p_qtdaves   number;
  p_qtdabat   number;
  p_qtdracao  float;
  p_peso      float;
  p_sexo      varchar2(1);
  p_pesolote  float;
  /*p_calote    float;
  p_ganholote float;
  p_fpmedio   float;
  p_ipsumedio float;
  p_percom    float;
  p_pesocom   float;
  p_vlrcom    float;*/
  v_sexo      varchar2(1);
  v_html      clob := null;

  lote ad_tsffci%rowtype;

  type rec_diff is record(
    nome   varchar2(100),
    vlrold float,
    vlrnew float,
    vlrdif float);

  type tab_diff is table of rec_diff;
  t tab_diff := tab_diff();
  i int;

begin

  if p_qtdlinhas > 1 then
    p_mensagem := 'Selecione apenas 1 registro!';
    return;
  end if;

  lote.numlote := act_int_field(p_idsessao, 1, 'NUMLOTE');
  p_qtdaves    := act_int_param(p_idsessao, 'QTDAVES');
  p_qtdabat    := act_int_param(p_idsessao, 'QTDABAT');
  p_qtdracao   := act_dec_param(p_idsessao, 'QTDRACAO');
  p_peso       := act_dec_param(p_idsessao, 'PESO');
  p_sexo       := act_txt_param(p_idsessao, 'SEXO');
  p_pesolote   := act_dec_param(p_idsessao, 'PESOLOTE');
  --p_calote     := act_dec_param(p_idsessao, 'CALOTE');
  --p_ganholote  := act_dec_param(p_idsessao, 'GANHOLOTE');
  --p_fpmedio    := act_dec_param(p_idsessao, 'FPMEDIO');
  --p_ipsumedio  := act_dec_param(p_idsessao, 'IPSUMEDIO');
  --p_percom     := act_dec_param(p_idsessao, 'PERCOM');
  --p_pesocom    := act_dec_param(p_idsessao, 'PESOCOM');
  --p_vlrcom     := act_dec_param(p_idsessao, 'VLRCOM');

  if variaveis_pkg.v_atualizando then
    lote.numlote := 57199;
    p_qtdaves    := 21000;
    p_qtdabat    := 20351;
    p_qtdracao   := 101273;
    p_peso       := 53700;
    p_sexo       := 'F';
    p_pesolote   := 2.6387;
    /*p_calote     := 1.8859;
    p_ganholote  := 56.1;
    p_fpmedio    := 320.15;
    p_ipsumedio  := 203.73;
    p_percom     := 7.1;
    p_pesocom    := 3812.70;
    p_vlrcom     := 11438.10;*/
  end if;

  select * into lote from ad_tsffci where numlote = lote.numlote;

  if lote.qtdfem > 0 and lote.qtdmachos = 0 then
    v_sexo := 'F';
  elsif lote.qtdmachos > 0 and lote.qtdfem = 0 then
    v_sexo := 'M';
  elsif lote.qtdfem > 0 and lote.qtdmachos > 0 then
    v_sexo := 'X';
  end if;

  if p_qtdaves != lote.qtdaves then
    t.extend;
    i := t.last;
    t(i).nome := 'Aves Alojadas';
    t(i).vlrold := lote.qtdaves;
    t(i).vlrnew := p_qtdaves;
    t(i).vlrdif := t(i).vlrold - t(i).vlrnew;
  end if;

  if p_qtdabat != lote.qtdabat then
    t.extend;
    i := t.last;
    t(i).nome := 'Aves Abatidas';
    t(i).vlrold := lote.qtdabat;
    t(i).vlrnew := p_qtdabat;
    t(i).vlrdif := t(i).vlrold - t(i).vlrnew;
  end if;

  if p_qtdracao != lote.qtdracao then
    t.extend;
    i := t.last;
    t(i).nome := 'Ração Consumida';
    t(i).vlrold := lote.qtdracao;
    t(i).vlrnew := p_qtdracao;
    t(i).vlrdif := t(i).vlrold - t(i).vlrnew;
  end if;

  if p_peso != lote.peso then
    t.extend;
    i := t.last;
    t(i).nome := 'Peso Total Aves';
    t(i).vlrold := lote.peso;
    t(i).vlrnew := p_peso;
    t(i).vlrdif := t(i).vlrold - t(i).vlrnew;
  end if;

  if p_sexo != v_sexo then
    t.extend;
    i := t.last;
    t(i).nome := 'Sexo';
    t(i).vlrold := 0;
    t(i).vlrnew := 0;
    t(i).vlrdif := 0;
  end if;
 /*
  if p_pesolote != lote.pesolote then
    t.extend;
    i := t.last;
    t(i).nome := 'Peso Médio';
    t(i).vlrold := lote.pesolote;
    t(i).vlrnew := p_pesolote;
    t(i).vlrdif := t(i).vlrold - t(i).vlrnew;
  end if;

  if p_calote != lote.calote then
    t.extend;
    i := t.last;
    t(i).nome := 'CA';
    t(i).vlrold := lote.calote;
    t(i).vlrnew := p_calote;
    t(i).vlrdif := t(i).vlrold - t(i).vlrnew;
  end if;

  if p_ganholote != lote.ganholote then
    t.extend;
    i := t.last;
    t(i).nome := 'GMD';
    t(i).vlrold := lote.ganholote;
    t(i).vlrnew := p_ganholote;
    t(i).vlrdif := t(i).vlrold - t(i).vlrnew;
  end if;

  if p_fpmedio != lote.fpmedio then
    t.extend;
    i := t.last;
    t(i).nome := 'FP Médio';
    t(i).vlrold := lote.fpmedio;
    t(i).vlrnew := p_fpmedio;
    t(i).vlrdif := t(i).vlrold - t(i).vlrnew;
  end if;

  if p_ipsumedio != lote.ipsumedio then
    t.extend;
    i := t.last;
    t(i).nome := 'IPSU Médio';
    t(i).vlrold := lote.ipsumedio;
    t(i).vlrnew := p_ipsumedio;
    t(i).vlrdif := t(i).vlrold - t(i).vlrnew;
  end if;

  if p_percom != lote.percom then
    t.extend;
    i := t.last;
    t(i).nome := '% Comissão';
    t(i).vlrold := lote.percom;
    t(i).vlrnew := p_percom;
    t(i).vlrdif := t(i).vlrold - t(i).vlrnew;
  end if;

  if p_pesocom != lote.pesocom then
    t.extend;
    i := t.last;
    t(i).nome := 'Comissão KG';
    t(i).vlrold := lote.pesocom;
    t(i).vlrnew := p_pesocom;
    t(i).vlrdif := t(i).vlrold - t(i).vlrnew;
  end if;

  if p_vlrcom != lote.vlrcom then
    t.extend;
    i := t.last;
    t(i).nome := 'Resultado do Lote';
    t(i).vlrold := lote.vlrcom;
    t(i).vlrnew := p_vlrcom;
    t(i).vlrdif := t(i).vlrold - t(i).vlrnew;
  end if;

 */
 
  v_html := '<!DOCTYPE html>
 <html>
 <head>
 <style>
  table {
   font-family: arial, sans-serif;
   border-collapse: collapse;
   width: 100%;
   }

  td, th {
   border: 1px solid #dddddd;
   text-align: left;
   padding: 8px;
   }

  tr:nth-child(even) {
   background-color: #dddddd;
  } 
 </style>
 </head>
 <body>
 <table>
  <tr>
    <th>Onde</th>
    <th>Valor Snk-W</th>
    <th>Valor Digitado</th>
    <th>Diferença</th>
  </tr>';

  if t.count > 0 then
    for x in t.first .. t.last
    loop
      dbms_lob.append(v_html, chr(13) || '<tr>' || chr(13));
      dbms_lob.append(v_html, ' <td>' || t(x).nome || '</td>');
      dbms_lob.append(v_html, ' <td>' || t(x).vlrold || '</td>');
      dbms_lob.append(v_html, ' <td>' || t(x).vlrnew || '</td>');
      dbms_lob.append(v_html, ' <td>' || t(x).vlrdif || '</td>');
      dbms_lob.append(v_html, chr(13) || '</tr>');
    end loop;
  
    v_html     := v_html || chr(13) || '</table>
 </body>
 </html>';
    p_mensagem := v_html;
  else
  
    begin
      update ad_tsffci f
         set f.statuslote  = 'A',
             f.dhalter     = sysdate,
             f.codusualter = p_codusu
       where f.numlote = lote.numlote;
    exception
      when others then
        p_mensagem := 'Erro ao atualizar o status do fechamento. ' || '  - ' || sqlerrm;
        return;
    end;
  
    p_mensagem := 'O lote ' || lote.numlote || ' foi auditado com sucesso!';
  
  end if;

end;

/
--------------------------------------------------------
--  DDL for Procedure AD_STP_FCI_CALCBONIFICA_SF
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "AD_STP_FCI_CALCBONIFICA_SF" (p_codusu    number,
                                                       p_idsessao  varchar2,
                                                       p_qtdlinhas number,
                                                       p_mensagem  out varchar2) as
  p_tipobonif varchar2(4000);
  p_vlrcusto  float;
  --p_vlrbnfpinto float;
  p_vlrmedcom  float;
  p_sem1       number;
  p_sem2       number;
  p_sem3       number;
  p_sem4       number;
  v_qtdmortsem number;
  v_confirma   boolean;
  lote         lote_ave%rowtype;
  l            ad_tsffci%rowtype;
  b            ad_tsffcibnf%rowtype;
  c            ad_tsffciconf%rowtype;
  t            ad_tsftci%rowtype;
  i            int;

  pacote_invalido exception;
  pragma exception_init(pacote_invalido, -04061);
  --pragma exception_init(pacote_invalido, -06512);
begin

  /*
   Autor: M. Rangel
   Processo: Fechamento de comissao do Integrado - Frango Vivo
   Objetivo: Calcular as diversas possibilidades de bonifica¿¿es
  */

  /* Log de altera¿¿es 
   15/01/2020 - mrangel - remo¿¿o do par¿metro vlrbnfpinto
  
  */

  stp_set_atualizando('S');

  <<inicio>>
  begin
  
    if p_qtdlinhas > 1 then
      p_mensagem := 'Selecione apenas 1 lote por vez';
      return;
      rollback;
    end if;
  
    l.numlote   := act_int_field(p_idsessao, 1, 'NUMLOTE');
    p_tipobonif := act_txt_param(p_idsessao, 'TIPOBONIF');
    p_vlrcusto  := act_dec_param(p_idsessao, 'VLRCUSTO');
    --  p_vlrbnfpinto := act_dec_param(p_idsessao, 'VLRBNFPINTO');
    p_vlrmedcom := act_dec_param(p_idsessao, 'VLRMEDCOM');
    p_sem1      := act_int_param(p_idsessao, 'QTDMORT1');
    p_sem2      := act_int_param(p_idsessao, 'QTDMORT2');
    p_sem3      := act_int_param(p_idsessao, 'QTDMORT3');
    p_sem4      := act_int_param(p_idsessao, 'QTDMORT4');
  
    lote := ad_pkg_fci.get_dados_lote(l.numlote);
    ad_pkg_fci.get_dados_fechamento(l.numlote, l, c);
  
    -- valida status do lote antes de iniciar o procedimento
    if l.statuslote = 'P' then
      p_mensagem := 'Lote ainda não foi Auditado. Por favor realize a conferência do lote ' ||
                    'para que seja possível realizar o cálculo das bonificações.';
      return;
      rollback;
    elsif l.statuslote = 'L' then
      p_mensagem := 'Lote já finalizado, o que impossibilita alterações no lote.';
      return;
      rollback;
    elsif l.statuslote = 'A' then
      null;
    end if;
  
    -- valida status da bonificação
    if l.statusbonif in ('F', 'L') then
      p_mensagem := 'Bonificaçõo já foi calculada e possui nota gerada, ' ||
                    'o que impossibilita alterações no cálculo já realizado.';
      return;
      rollback;
    end if;
  
    -- inicio dos calculos
    begin
      delete from ad_tsffcibnf where numlote = l.numlote;
    exception
      when others then
        p_mensagem := 'Erro ao limpar bonificações existentes. ' || sqlerrm;
        return;
        rollback;
    end;
  
    -- insere a linha do cálculo do lote real
    begin
      ad_pkg_fci.set_bnf_lotereal(l.numlote, p_mensagem);
      if p_mensagem is not null then
        stp_set_atualizando('N');
        p_mensagem := 'Erro ao gravar o lote real. ' || p_mensagem;
        return;
        rollback;
      end if;
    end;
  
    for x in 1 .. 4
    loop
      if x = 1 then
        p_tipobonif := 'M';
      elsif x = 2 then
        p_tipobonif := 'C';
      elsif x = 3 then
        p_tipobonif := 'ITA';
      elsif x = 4 then
        p_tipobonif := 'NVZ';
      end if;
    
      -- calcula bonifica¿¿es
      begin
        -- mortalidade
        if p_tipobonif = 'M' then
        
          -- valida input
          if p_sem1 is null or p_sem2 is null or p_sem3 is null or
             p_sem4 is null then
            stp_set_atualizando('N');
            p_mensagem := 'Preencha a quantidade de mortes para todas as semanas!';
            return;
            rollback;
          end if;
        
          --efetua opera¿¿o
          ad_pkg_fci.set_bnf_mortalidade(l.numlote,
                                         p_sem1,
                                         p_sem2,
                                         p_sem3,
                                         p_sem4,
                                         p_mensagem);
        
          --valida resultado opera¿¿o
          if p_mensagem is not null then
            stp_set_atualizando('N');
            p_mensagem := 'Erro ao calcular a bonificação da mortalidade. ' ||
                          p_mensagem;
            return;
            rollback;
          end if;
        
          -- carca¿a GPA
        elsif p_tipobonif = 'C' then
        
          ad_pkg_fci.set_bnf_carcaca(l.numlote, p_vlrmedcom, p_mensagem);
        
          if p_mensagem is not null then
            stp_set_atualizando('N');
            p_mensagem := 'Erro ao calcular a bonificação pela carcaça. ' ||
                          p_mensagem;
            return;
            rollback;
          end if;
        
        elsif p_tipobonif = 'ITA' then
          begin
          
            if nvl(p_vlrcusto, 0) = 0 then
              ad_pkg_fci.get_dados_tabela(l.numlote, l.codemp, t);
              p_vlrcusto := t.vlrcustoave;
            end if;
          
            --p_vlrbnfpinto := nvl(p_vlrbnfpinto, 0);
            b.vlrcom     := l.vlrcom; --+ p_vlrbnfpinto;
            b.vlrbonific := greatest((l.qtdabat * p_vlrcusto) - b.vlrcom);
            b.vlrunitbnf := snk_dividir(b.vlrbonific, l.qtdabat);
          
            b.obs := 'Utilizando tabela ' || t.codtab || '/' || t.codemp ||
                     ', custo da ave de 0' || fmt.numero(p_vlrcusto);
            --||' e com ajuda extra de ' || fmt.numero(p_vlrbnfpinto);
          
            select max(nufcibnf) + 1
              into i
              from ad_tsffcibnf
             where numlote = l.numlote;
          
            insert into ad_tsffcibnf
              (numlote, nufcibnf, tipobonif, percmortprev, qtdmortprev,
               saldoprev, percmortreal, qtdmortreal, saldoreal, qtdavesbnf,
               percavesbnf, viabilidade, percmortlote, perccom, vlrcom,
               vlrunitcom, vlrbonific, vlrunitbnf, aprovado, obs)
            values
              (l.numlote, i, 'ITA', c.percmortprev,
               l.qtdaves * (c.percmortprev / 100),
               l.qtdaves - (l.qtdaves * (c.percmortprev / 100)),
               (l.qtdmortes / l.qtdaves) * 100, l.qtdmortes,
               l.qtdaves - l.qtdmortes, 0, 0, l.viabilidade, 100 - l.viabilidade,
               l.percom, b.vlrcom, b.vlrcom / l.qtdabat, b.vlrbonific,
               b.vlrunitbnf, 'N', b.obs);
          
          exception
            when others then
              rollback;
              p_mensagem := 'Erro ao inserir o cálculo da bonificação Itaberaí. ' ||
                            sqlerrm;
              return;
          end;
        elsif p_tipobonif = 'NVZ' then
          begin
          
            ad_pkg_fci.get_dados_tabela(l.numlote, 19, t);
          
            l.ipsumedio := case
                             when l.tipopreco = 'F' then
                              t.ipsufemea
                             when l.tipopreco = 'M' then
                              t.ipsumacho
                             when l.tipopreco = 'X' then
                              t.ipsusexado
                           end;
          
            l.percom     := trunc(ad_pkg_fci.get_perc_com(l.ipsulote,
                                                          l.ipsumedio),
                                  2);
            l.pesocom    := l.peso * (l.percom / 100);
            b.vlrcom     := (l.pesocom * l.vlrunit);
            b.vlrbonific := greatest(b.vlrcom - l.vlrcom, 0);
            b.vlrunitbnf := snk_dividir(b.vlrbonific, l.qtdabat);
            b.obs        := 'Utilizando tabela ' || t.codtab || '/' || t.codemp ||
                            ', custo da ave de 0' || fmt.numero(p_vlrcusto)
            --||' e com ajuda de ' || fmt.numero(p_vlrbnfpinto)
             ;
          
            select max(nufcibnf) + 1
              into i
              from ad_tsffcibnf
             where numlote = l.numlote;
          
            insert into ad_tsffcibnf
              (numlote, nufcibnf, tipobonif, percmortprev, qtdmortprev,
               saldoprev, percmortreal, qtdmortreal, saldoreal, qtdavesbnf,
               percavesbnf, viabilidade, percmortlote, perccom, vlrcom,
               vlrunitcom, vlrbonific, vlrunitbnf, aprovado)
            values
              (l.numlote, i, 'NVZ', c.percmortprev,
               l.qtdaves * (c.percmortprev / 100),
               l.qtdaves - (l.qtdaves * (c.percmortprev / 100)),
               (l.qtdmortes / l.qtdaves) * 100, l.qtdmortes,
               l.qtdaves - l.qtdmortes, 0, 0, l.viabilidade, 100 - l.viabilidade,
               l.percom, b.vlrcom, b.vlrcom / l.qtdabat, b.vlrbonific,
               b.vlrunitbnf, 'N');
          end;
        end if;
      
      end;
    
    end loop x;
  
    -- atualiza dados no formulario principal
    begin
      update ad_tsffci f
         set /*f.tipobonif   = p_tipobonif,*/ f.statusbonif = 'A',
             f.codusualter = p_codusu,
             f.dhalter     = sysdate
       where f.numlote = l.numlote;
    exception
      when others then
        p_mensagem := 'Erro ao atualizar os dados na tela do fechamento. ' ||
                      sqlerrm;
        return;
        rollback;
    end;
  
    -- atualiza dados no formulario das bonifica¿¿es
    begin
      update ad_tsffcibnf b
         set b.codusu  = p_codusu,
             b.dhalter = sysdate
       where b.numlote = l.numlote
      --and b.tipobonif = p_tipobonif
      ;
    exception
      when others then
        p_mensagem := 'Erro ao atualizar os dados na tela do cálculo da bonificação. ' ||
                      sqlerrm;
        return;
        rollback;
    end;
  
    /* envia mail para liberador */
    declare
      mail      tmdfmg%rowtype;
      enviamail boolean;
    begin
      select usu.codusu, usu.email
        into mail.codusu, mail.email
        from tsiusu usu
        join ad_tsfmgn m
          on m.numodelo = c.numodbnffrv
        join tsicus cus
          on cus.codusuresp = usu.codusu
         and cus.codcencus = m.codcencus;
    
      enviamail := act_confirmar(p_titulo    => 'cálculo de bonificação',
                                 p_texto     => 'Deseja enviar um e-mail para ' ||
                                                ad_get.nomeusu(mail.codusu,
                                                               'completo') ||
                                                ' solicitando a aprovação das simulações?',
                                 p_chave     => p_idsessao,
                                 p_sequencia => 0);
    
      if enviamail then
      
        mail.assunto := 'Nova aprovação de bonficação de comissão do integrado.';
      
        mail.mensagem := 'Uma nova solicitação de aprovação de bonificação foi gerada ' ||
                         'para o lote ' || l.numlote || ' (' ||
                         ad_get.nome_parceiro(l.codparc, 'fantasia') || '; ' ||
                         l.tipopreco || '; ' || fmt.numero(l.qtdaves) || ')' ||
                         ', por ' || ad_get.nomeusu(825, 'completo') || '.<br>' ||
                         chr(13) ||
                         'Acesse o link abaixo para maiores detalhes.<br>' ||
                         chr(13) || '<a href="' ||
                         ad_fnc_urlskw('AD_TSFFCI', l.numlote) ||
                         '">Qlique Aqui</a>';
      
        ad_set.insere_mail_fila_fmg(p_assunto  => mail.assunto,
                                    p_mensagem => mail.mensagem,
                                    p_email    => mail.email,
                                    p_nunota   => null,
                                    p_evento   => null);
      
      end if;
    
    end;
  
    p_mensagem := 'cálculo da bonificação concluída com sucesso!';
  exception
    when pacote_invalido then
      goto inicio;
  end;

  stp_set_atualizando('N');

end;

/
--------------------------------------------------------
--  DDL for Procedure AD_STP_FCI_FATURA_SF
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "AD_STP_FCI_FATURA_SF" (p_codusu    number,
                                                 p_idsessao  varchar2,
                                                 p_qtdlinhas number,
                                                 p_mensagem  out varchar2) as
  p_tiponota varchar2(3);
  v_modelo   number;
  v_origem   varchar2(5);
  v_nufin    number;
  lote       ad_tsffci%rowtype;
  conf       ad_tsffciconf%rowtype;
  bnf        ad_tsffcibnf%rowtype;
  cab        tgfcab%rowtype;
  ite        tgfite%rowtype;
  fin        tgffin %rowtype;
  top        tgftop%rowtype;
  stm        varchar2(4000);
  i          int := 0;

  pacote_invalidado exception;
  pragma exception_init(pacote_invalidado, -04061);

  n ad_type_of_number := ad_type_of_number();

begin

  <<inicio>>

  begin
  
    stp_set_atualizando('S');
  
    -- selecionou mais de 1 registro
    if p_qtdlinhas > 1 then
      p_mensagem := 'Selecione apenas um lote para geração de notas.';
      return;
    end if;
  
    -- não selecionou nenhum registro
    if p_qtdlinhas = 0 then
      p_mensagem := 'Selecione pelo menos um lote para geração de notas';
      return;
    end if;
  
    p_tiponota   := act_txt_param(p_idsessao, 'TIPONOTA');
    lote.numlote := act_int_field(p_idsessao, 1, 'NUMLOTE');
    cab.dtentsai := act_dta_param(p_idsessao, 'DTENTSAI');
  
    -- get dados lote e configurações
    ad_pkg_fci.get_dados_fechamento(lote.numlote, lote, conf);
  
    -- se lote finalizado
    if lote.statuslote = 'L' then
      p_mensagem := 'Lote já finalizado, não permite edições ou gerações de documentos.';
      return;
    end if;
  
    -- seleciona o modelo de nota de acordo com o parametro
    if p_tiponota = 'C' then
      v_modelo := conf.numodcpafrv;
      v_origem := 'COM';
    elsif p_tiponota = 'V' then
      v_modelo := conf.numodremfrv;
    elsif p_tiponota = 'M' then
      v_modelo := conf.numodmorfrv;
    elsif p_tiponota = 'B' then
      v_modelo := conf.numodbnffrv;
      v_origem := 'BNF';
    end if;
  
    -- get dados modelo
    select m.serienota, m.codvend, m.codtipvenda, m.codcencus, m.codnat,
           m.obspadrao, nvl(m.confauto, 'N'), m.codprod, m.codvol, m.codlocal,
           m.codtipoper, m.codctabcoint
      into cab.serienota, cab.codvend, cab.codtipvenda, cab.codcencus,
           cab.codnat, cab.observacao, cab.confirmnotafat, ite.codprod,
           ite.codvol, ite.codlocalorig, cab.codtipoper, fin.codctabcoint
      from ad_tsfmgn m
     where m.numodelo = v_modelo;
  
    -- verifica se nota com a top do modelo consta na aba de notas da tela
    select count(*)
      into i
      from ad_tsffcinf
     where codtipoper = cab.codtipoper
       and numlote = lote.numlote;
  
    if i > 0 then
      p_mensagem := 'Já existe uma nota com essa top na lista de notas emitidas.';
      return;
    end if;
  
    -- get dados top do modelo
    select *
      into top
      from tgftop
     where codtipoper = cab.codtipoper
       and dhalter = ad_get.maxdhtipoper(cab.codtipoper);
  
    -- checa data de vencimento previamente
    begin
      stm := 'Select count(*) from ad_tsffcifin where numlote = :lote ' ||
             'and origem = :origem and dtvenc is null';
      execute immediate stm
        into i
        using lote.numlote, v_origem;
    
      if i > 0 then
        p_mensagem := 'Data de vencimento na aba "Financeiro" não informada.';
        return;
      end if;
    end;
  
    begin
      stm := 'Select count(*) from ad_tsffcifin where numlote = :lote ' ||
             'and origem = :origem and nufin is null';
      execute immediate stm
        into i
        using lote.numlote, v_origem;
    
      if i = 0 and top.atualfin <> 0 then
        p_mensagem := 'Não existem lançamentos pendentes de geração de nota!';
        return;
      end if;
    end;
  
    -- bonificação, valida se há aprovados
    if p_tiponota = 'B' then
    
      select count(*)
        into i
        from ad_tsffcibnf
       where numlote = lote.numlote
         and aprovado = 'S'
         and nunota is null;
    
      if i = 0 then
        p_mensagem := 'Não existem bonificações aprovadas e pendentes para geração da nota!';
        return;
      elsif i > 1 then
        p_mensagem := 'Existem mais de 1 bonificação aprovada, o que não é permitido!';
        return;
      end if;
    
      cab.observacao := 'Complemento de comissão / ajuda de custo. Lote nº: ' ||
                        lote.numlote;
    
      -- obtem o valor da bonificação
      begin
        select vlrbonific
          into cab.vlrnota
          from ad_tsffcibnf
         where numlote = lote.numlote
           and aprovado = 'S';
      exception
        when no_data_found then
          p_mensagem := 'Valor unitário da bonificação não encontrado!';
          return;
        when too_many_rows then
          p_mensagem := 'Existem mais de uma bonificação aprovada!';
          return;
      end;
    
      ite.codprod := case
                       when lote.tipopreco = 'F' then
                        ad_pkg_fci.c_prodfemeabnf
                       when lote.tipopreco = 'M' then
                        ad_pkg_fci.c_prodmachobnf
                       when lote.tipopreco = 'X' then
                        ad_pkg_fci.c_prodsexadobnf
                     end;
    
      ite.qtdneg  := 1;
      ite.vlrunit := cab.vlrnota;
    
    elsif p_tiponota = 'C' then
    
      ite.codprod := case
                       when lote.tipopreco = 'F' then
                        ad_pkg_fci.c_prodfemeabnf
                       when lote.tipopreco = 'M' then
                        ad_pkg_fci.c_prodmachobnf
                       when lote.tipopreco = 'X' then
                        ad_pkg_fci.c_prodsexadobnf
                     end;
    
      ite.qtdneg  := lote.pesocom;
      ite.vlrunit := lote.vlrunit;
      cab.vlrnota := lote.pesocom * lote.vlrunit;
    
    elsif p_tiponota = 'V' then
      ite.codprod := case
                       when lote.tipopreco = 'F' then
                        ad_pkg_fci.c_codprodfemea
                       when lote.tipopreco = 'M' then
                        ad_pkg_fci.c_codprodmacho
                       when lote.tipopreco = 'X' then
                        ad_pkg_fci.c_codprodsexado
                     end;
    
      ite.qtdneg     := lote.pesocom;
      ite.vlrunit    := lote.vlrunit;
      cab.vlrnota    := lote.pesocom * lote.vlrunit;
      cab.observacao := cab.observacao || ' ' || lote.numlote;
    
    elsif p_tiponota = 'M' then
      ite.codprod := case
                       when lote.tipopreco = 'F' then
                        ad_pkg_fci.c_mortfemea
                       when lote.tipopreco = 'M' then
                        ad_pkg_fci.c_mortmacho
                       when lote.tipopreco = 'X' then
                        ad_pkg_fci.c_mortsexado
                     end;
    
      with dados as
       (select i.nunota, c.dtfatur, i.codprod, i.vlrunit
          from tgfite i
          join tgfcab c
            on i.nunota = c.nunota
         where 1 = 1
           and c.codparc = lote.codparc
           and c.dtfatur between lote.dtaloj and lote.dtsaida
           and c.codtipoper = 195
           and i.codprod = ite.codprod
           and i.sequencia > 0),
      maxdate as
       (select min(dtfatur) dtfatur from dados)
      select nunota, vlrunit
        into cab.observacao, ite.vlrunit
        from dados d
        join maxdate md
          on md.dtfatur = d.dtfatur;
    
      cab.observacao := 'Ref. Nota Transf. Interna nº único: ' ||
                        cab.observacao;
      ite.qtdneg     := lote.qtdmortes;
      cab.vlrnota    := ite.qtdneg * ite.vlrunit;
    end if;
    -- insere cabeçalho do pedido/nota
    begin
      ad_set.ins_pedidocab(p_codemp      => lote.codemp,
                           p_codparc     => lote.codparc,
                           p_codvend     => cab.codvend,
                           p_codtipoper  => cab.codtipoper,
                           p_codtipvenda => cab.codtipvenda,
                           p_dtneg       => nvl(cab.dtentsai, trunc(sysdate)),
                           p_vlrnota     => cab.vlrnota,
                           p_codnat      => cab.codnat,
                           p_codcencus   => cab.codcencus,
                           p_codproj     => 0,
                           p_obs         => cab.observacao,
                           p_nunota      => cab.nunota);
    
      update tgfcab
         set serienota      = cab.serienota,
             dtfatur        = nvl(cab.dtentsai, trunc(sysdate)),
             dtentsai       = nvl(cab.dtentsai, trunc(sysdate)),
             confirmnotafat = cab.confirmnotafat
       where nunota = cab.nunota;
    
    end;
  
    -- insere itens
    begin
      ad_set.ins_pedidoitens(p_nunota   => cab.nunota,
                             p_codprod  => ite.codprod,
                             p_qtdneg   => ite.qtdneg,
                             p_codvol   => ite.qtdvol,
                             p_codlocal => ite.codlocalorig,
                             p_controle => ite.controle,
                             p_vlrunit  => ite.vlrunit,
                             p_vlrtotal => ite.vlrunit * ite.qtdneg,
                             p_mensagem => p_mensagem);
    
      if p_mensagem is not null then
        return;
      end if;
    
      begin
        update tgfite i
           set i.ad_nloteavec = lote.numlote
        --i.codcfo       = ite.codcfo
         where i.nunota = cab.nunota;
      exception
        when others then
          p_mensagem := 'Erro ao atualizar dados no item do pedido/nota. ' ||
                        sqlerrm;
          return;
      end;
    
    end;
  
    -- insere financeiro
    if top.atualfin <> 0 then
      begin
        stp_set_atualizando('S');
        for cfin in (select *
                       from ad_tsffcifin
                      where numlote = lote.numlote
                        and origem = v_origem)
        loop
        
          select c.codbco
            into fin.codbco
            from tsicta c
           where codctabcoint = fin.codctabcoint;
        
          stp_keygen_nufin(fin.nufin);
        
          insert into tgffin
            (autorizado, bloqvar, codbco, codctabcoint, codcencus, codemp,
             codnat, codparc, codproj, codtipoper, codtipoperbaixa, codtiptit,
             codusu, codvend, desdobramento, despcart, dhmov, dhtipoper,
             dhtipoperbaixa, dtalter, dtentsai, dtneg, dtvenc, dtvencinic,
             irfretido, issretido, nufin, numcontrato, numnota, nunota,
             ordemcarga, origem, provisao, rateado, recdesp, tipjuro,
             tipmarccheq, tipmulta, vlrbaixa, vlrdesc, vlrdesdob, historico)
          values
            ('N', 'N', fin.codbco, fin.codctabcoint, cab.codcencus, lote.codemp,
             cab.codnat, lote.codparc, 0, cab.codtipoper, 0, cfin.codtiptit,
             p_codusu, cab.codvend, 1, 0, sysdate, top.dhalter,
             ad_get.maxdhtipoper(0), sysdate, cab.dtentsai, trunc(cab.dtentsai),
             cfin.dtvenc, cfin.dtvenc, 'N', 'N', fin.nufin, 0, 0, cab.nunota, 0,
             'E', 'S', 'N', top.atualfin, 1, 'I', 1, 0, 0, cfin.vlrdesdob,
             cab.observacao);
        
          n.extend;
          n(cfin.nufcifin) := fin.nufin;
        
        end loop;
      
        stp_set_atualizando('N');
      
      exception
        when others then
          p_mensagem := 'Erro ao gerar/atualizar o financeiro. ' || sqlerrm;
          return;
      end;
    
    end if;
  
    if p_tiponota = 'B' then
      -- atualiza informações na bonificação
      begin
        stp_set_atualizando('S');
        update ad_tsffcibnf b
           set b.nunota = cab.nunota
         where numlote = lote.numlote
           and aprovado = 'S';
      
        update ad_tsffci f
           set f.statusbonif = 'F',
               f.codusualter = p_codusu,
               f.dhalter     = sysdate
         where f.numlote = lote.numlote;
        stp_set_atualizando('N');
      exception
        when others then
          p_mensagem := 'Erro ao atualizar as informações na bonificação aprovada. ' ||
                        sqlerrm;
          rollback;
          return;
      end;
    
    else
    
      -- atualiza detalhes no lote
      begin
        stp_set_atualizando('S');
        update ad_tsffci f
           set f.statuslote  = 'F',
               f.codusualter = p_codusu,
               f.dhalter     = sysdate
         where f.numlote = lote.numlote;
        stp_set_atualizando('N');
      exception
        when others then
          p_mensagem := 'Erro ao atualizar status do lote! ' || sqlerrm;
          rollback;
          return;
      end;
    
    end if;
  
    -- insere as notas no lote sendo fechado
    begin
      stp_set_atualizando('S');
      delete from ad_tsffcinf where nunota = cab.nunota;
    
      select * into cab from tgfcab where nunota = cab.nunota;
    
      select max(nufcinf) + 1
        into i
        from ad_tsffcinf
       where numlote = lote.numlote;
    
      insert into ad_tsffcinf
        (numlote, nufcinf, codemp, nunota, nufin, numnota, serienota, dtneg,
         dtfatur, vlrnota, codtipoper, tipmov, statusnota, statusnfe, qtdneg)
      values
        (lote.numlote, i, lote.codemp, cab.nunota, v_nufin, cab.numnota,
         cab.serienota, cab.dtneg, cab.dtneg, cab.vlrnota, cab.codtipoper,
         top.tipmov, 'A', cab.statusnfe, ite.qtdneg);
      stp_set_atualizando('N');
    exception
      when others then
        p_mensagem := 'Erro ao inserir a nota gerada na aba "Notas" do lote. ' ||
                      sqlerrm;
        rollback;
        return;
    end;
  
    -- insert na tabela de ligação
    begin
      insert into ad_tblcmf
        (nometaborig, nuchaveorig, nometabdest, nuchavedest)
      values
        ('AD_TSFFCI', lote.numlote, 'TGFCAB', cab.nunota);
    exception
      when others then
        p_mensagem := 'Erro ao atulizar tabela de ligação. ' || sqlerrm;
        rollback;
        return;
    end;
  
    -- controle de notas emitidas e confirmadas
    declare
      qtd_emit int := 0;
      qtd_conf int := 0;
    begin
      select count(*)
        into qtd_emit
        from ad_tsffcinf nf
       where nf.numlote = lote.numlote;
    
      select count(*)
        into qtd_conf
        from ad_tsffcinf nf
       where nf.numlote = lote.numlote
         and nf.statusnota = 'L';
    
      if qtd_emit = qtd_conf then
        begin
          stp_set_atualizando('S');
          update ad_tsffci set statuslote = 'L' where numlote = lote.numlote;
          stp_set_atualizando('N');
        exception
          when others then
            p_mensagem := 'Erro ao atualizar o status do lote. ' || sqlerrm;
            return;
        end;
      end if;
    
    end;
  
    p_mensagem := 'Nota nº único ' ||
                  '<a title="Clique aqui" target="_parent" href="' ||
                  ad_fnc_urlskw('TGFCAB', cab.nunota) || '">' || cab.nunota ||
                  '</a>' || ' gerada com sucesso!';
  
    for x in n.first .. n.last
    loop
      update ad_tsffcifin f
         set f.nufin = n(x)
       where f.numlote = lote.numlote
         and f.nufcifin = x;
    end loop;
  
    if p_tiponota in ('V', 'M') then
    
      if nvl(cab.confirmnotafat, 'N') = 'S' then
        if not act_confirmar('Confirmação de Nota',
                             'Deseja confirmar a nota Gerada?',
                             p_idsessao,
                             1) then
          return;
        else
          commit;
          stp_confirmanota_java_sf(cab.nunota);
        
          select * into cab from tgfcab where nunota = cab.nunota;
        
          stp_set_atualizando('S');
          update ad_tsffcinf
             set numnota    = cab.numnota,
                 statusnota = cab.statusnota,
                 statusnfe  = cab.statusnfe
           where nunota = cab.nunota;
          stp_set_atualizando('N');
        end if;
      end if;
    end if;
  
    stp_set_atualizando('N');
  
  exception
    when pacote_invalidado then
      goto inicio;
  end;

end;

/
--------------------------------------------------------
--  DDL for Procedure AD_STP_FCI_INSNOVOLOTE_SF
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "AD_STP_FCI_INSNOVOLOTE_SF" (p_codusu    number,
                                                      p_idsessao  varchar2,
                                                      p_qtdlinhas number,
                                                      p_mensagem  out varchar2) as
  p_nrolote number;
  confirma  boolean;
  i         int := 0;

  pacote_invalido exception;

  pragma exception_init(pacote_invalido, -04061);

  procedure apaga_tudo(p_nrolote number) as
  begin
    delete from ad_tsffcinf where numlote = p_nrolote;
    delete from ad_tsffcifin where numlote = p_nrolote;
    delete from ad_tsffcibnf where numlote = p_nrolote;
  end;

begin
  -- Autor: M. Rangel
  -- Processo: Fechamento de Comiss?o Integrado - Frango Vivo
  -- Objetivo: Popular os dados na tela de comiss?o;

  <<inicio>>
  begin
    p_nrolote := act_int_param(p_idsessao, 'NROLOTE');
    --p_nrolote := act_int_field(p_idsessao,1,'NUMLOTE');
  
    select count(*)
      into i
      from lote_ave
     where numlote = p_nrolote
       and status = 'F';
  
    if i = 0 then
      p_mensagem := 'Lote não existe, não está fechado ou não foi importado!';
      return;
    end if;
  
    select count(*) into i from ad_tsffci where numlote = p_nrolote;
  
    -- valida duplicidade
    if i > 1 then
      confirma := act_confirmar(p_titulo    => 'Lote duplicado',
                                p_texto     => 'Já existe um fechamento para este lote, ' ||
                                               'gostaria de atualizá-lo?',
                                p_chave     => p_idsessao,
                                p_sequencia => 1);
    
      if confirma then
        apaga_tudo(p_nrolote);
      else
        return;
      end if;
    
    end if;
  
    stp_set_atualizando('S');
  
    -- insere dados do lote
    begin
      ad_pkg_fci.set_dados_lote(p_nrolote, p_mensagem);
      if p_mensagem is not null then
        p_mensagem := 'Erro ao inserir lote. ' || p_mensagem;
        stp_set_atualizando('N');
        return;
      end if;
    end;
  
    -- insere os dados do financeiro
    begin
      ad_pkg_fci.set_dados_financeiro(p_nrolote, p_mensagem);
      if p_mensagem is not null then
        p_mensagem := 'Erro ao inserir parcelas. ' || p_mensagem;
        stp_set_atualizando('N');
        return;
      end if;
    end;
  
    -- insere os movimentos de notas
    begin
      ad_pkg_fci.set_dados_notas(p_nrolote, p_mensagem);
      if p_mensagem is not null then
        p_mensagem := 'Erro ao inserir notas. ' || p_mensagem;
        stp_set_atualizando('N');
        return;
      end if;
    end;
  
    begin
      update ad_tsffci i
         set i.dhalter     = sysdate,
             i.codusualter = p_codusu
       where numlote = p_nrolote;
    exception
      when others then
        apaga_tudo(p_nrolote);
        p_mensagem := 'Erro ao atualizar o registro. ' || sqlerrm;
        return;
    end;
  
    stp_set_atualizando('N');
  
    p_mensagem := q'[Lote calculado com Sucesso!<a href="javascript:workspace.reloadApp('br.com.sankhya.menu.adicional.AD_TSFFCI', {'NUMLOTE': nrolote});document.getElementsByClassName('btn-popup-ok')[0].click();"><b> Clique AQUI </b></a>para acessar o registro]';
    p_mensagem := replace(p_mensagem, 'nrolote', p_nrolote);
  
  exception
    when pacote_invalido then
      goto inicio;
  end;

end;

/
--------------------------------------------------------
--  DDL for Package AD_PKG_FCI
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "AD_PKG_FCI" is

  -- Author  : MARCUS.RANGEL
  -- Created : 04/11/2019 17:24:19
  -- Purpose : agrupar os objetos utilizados na rotina de 
  -- fechamento de comissão de integrado frango vivo

  lote lote_ave%rowtype;

  c_prodfemeabnf  number := 3602; -- FRANGO VIVO FEMEA (BNF)
  c_prodmachobnf  number := 3603; -- FRANGO VIVO MACHO (BNF)
  c_prodsexadobnf number := 3604; -- FRANGO VIVO SEXADO (BNF)

  c_codprodfemea  number := 3607; -- FRANGO VIVO FEMEA (VND)
  c_codprodmacho  number := 3606; -- FRANGO VIVO MACHO (VND)
  c_codprodsexado number := 3605; -- FRANGO VIVO SEXADO (VND)

  c_mortfemea  number := 21196;
  c_mortmacho  number := 21197;
  c_mortsexado number := 15054;

  type t_dados_notas is table of ad_tsffcinf%rowtype;

  -- M. Rangel - Busca as informações da LOTE_AVE
  function get_dados_lote(p_nrolote number) return lote_ave%rowtype;

  function get_dados_tabela(p_nrolote number, p_tipo varchar2) return number
    deterministic;
  procedure get_dados_tabela(p_nrolote number,
                             p_codemp  number,
                             p_tabela  out ad_tsftci%rowtype);

  procedure get_dados_fechamento(p_nrolote number,
                                 p_lote    out ad_tsffci%rowtype,
                                 p_conf    out ad_tsffciconf%rowtype);

  -- M. Rangel, retorna as notas de ração
  function get_notas_racao(p_nrolote number) return t_dados_notas
    pipelined;

  function get_notas_transp(p_nrolote number) return t_dados_notas
    pipelined;

  function get_notas_fin(p_nrolote number) return t_dados_notas
    pipelined;

  -- total de ração transf para integrado no periodo do lote tops 331,334
  function get_total_racao_lote(p_nrolote number) return float deterministic;

  function get_config(p_nrolote number) return int;
  procedure get_config(p_dtref in date, conf out ad_tsffciconf%rowtype);

  -- total transp top 27 de frango do integrado
  function get_qtd_transp_lote(p_nrolote number) return float deterministic;

  function get_codemp_lote(p_nrolote number) return int deterministic;

  function get_qtd_sexo_lote(p_nrolote number, p_sexo varchar2) return float
    deterministic;

  function get_qtd_abatida(p_nrolote number) return float deterministic;

  function get_pesoliq_balanca(p_nrolote number) return float deterministic;

  function get_total_despesas(p_nrolote number) return float;

  function get_perc_com(p_ipsul float, p_ipsum float) return float;

  -- calcula/recalcula valores básicos da tela de comissão por lote
  procedure set_dados_lote(p_nrolote number, p_errmsg out varchar2);

  -- popula a aba financeiro da tela de fechamento de comissao
  procedure set_dados_financeiro(p_nrolote number, p_errmsg out varchar2);

  procedure set_dados_notas(p_nrolote number, p_errmsg out varchar2);

  procedure set_bnf_lotereal(p_nrolote number, p_errmsg out varchar2);

  procedure set_bnf_carcaca(p_nrolote number, p_errmsg out varchar2);

  procedure set_bnf_mortalidade(p_nrolote in number,
                                p_sem1    in number,
                                p_sem2    in number,
                                p_sem3    in number,
                                p_sem4    in number,
                                p_errmsg  out varchar2);

  procedure set_bnf_carcaca(p_nrolote   number,
                            p_vlrmedcom float,
                            p_errmsg    out varchar2);

end ad_pkg_fci;

/
