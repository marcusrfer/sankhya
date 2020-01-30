create or replace trigger trg_u_tsilib_provisao_sf
 for insert or update on sankhya.tsilib
 referencing new as new old as old
 compound trigger

 r_lib          tsilib%rowtype;
 p_executar     boolean := false; -- Procedimento que ir� definir se ser� excutado
 v_codusulogado int := stp_get_codusulogado;
 v_count        int;
 v_forma        char(1);
 v_junior       int;
 errmsg         varchar2(4000);

 /*
  AUTOR:        Ricardo Soares de Oliveira 
  OBJETIVO:     01) Altera a provis�o do movimento financeiro quando o evento � o 1035. Precisar criar como compound pois preciso fazer a valida��o na pr�pria TSILIB, e
                com o compound evito o pragma
                
  AUTOR:        Ricardo Soares de Oliveira em 01/08/2017
  OBJETIVO:     02) O mesmo processo passa a valer tamb�m para o evento 1042 - Aprova��es de adiantamento
  
  AUTOR:        Ricardo Soares de Oliveira em 07/08/2017
  OBJETIVO:     03) Tratar comprador Jr.
 
  AUTOR:        Ricardo Soares de Olivera em 21/08/2017
  OBJETIVO:     04) Tratar aprova��o 1043 - Devolu��es
            
  AUTOR:        Ricardo Soares de Olivera em 22/08/2017
  OBJETIVO:     05) Quando h� uma pendencia com o eveto 1001 eu verifico se realmente o vencimento est� pr�ximo, pois ele pode ter sido alterado pelo usu�rio posteriormente
                logo isso se torna desnecess�rio.
                                     
  AUTOR:        Ricardo Soares de Olivera em 31/10/2017
  OBJETIVO:     06) Foi necess�rio um ajuste para identificar se o lan�amento tem origem uma TOP cujo tipo de aprova��o do financeiro � 'O', 'R' ou 'S' pois neste caso 
                o SEQCASCASCATA deve ser 1, pois n�o ser� enviado para aprova��o do comprador. Estava ocorrendo casos em que o registro estava vinculado a um contrato
                e quando a aprova��o n�o era feita por um usu�rio comprador direcionava para ele, mesmo sem necessidade
                
  AUTOR:        Por Ricardo Soares em 16/11/2017
  OBJETIVO      07) O Evento 1017 passou a ser validado por aqui
                    Passou a ser populado AD_TSILIBLOG.NUADTO
                   
  AUTOR:        Por Ricardo Soares em 01/02/2018
  Objetivo      08) Se estiver liberando uma despesa de cart�rio faz o update, at� entao despesa de cart�rio era 1014, a partir daqui passou para 1035
  
  AUTOR:        Por Ricardo em 15/10/2018 
  Objetivo:     09) Jo�o Paulo estava reclamando que as aprova��es de empr�stimo a funcion�rio n�o estavam fluindo conforme esperado, em tese n�o havia problemas pois o usu�rio do RH havia configurado 
                corretamente a rotina de libera��o de limites para "tentar confirmar na aprova��o" e mesmo assim a solicita��o n�o era enviada para o financeiro. Combinei com o Jo�o Paulo ent�o
                de colocar para disparar as duas aprova��es juntas, e n�o permitir que ele fa�a a aprova��o (evento 1006) sem antes o RH ter feito a libera��o da parte dele (evento 1007). Alem
                do ajuste nessa trigger, ajustei tambem a procedure Stp_Libemprestimo_Fin_Sf para disparar a solicita��o logo na confirma��o do movimento da TGFCAB
            
 */
 before each row is
  v_diasemana number;
  v_exige     char(1);
  x           int := 0;
 begin
 
  if :new.nuchave in (23166721, 22818423) or
     (:new.codtipoper = 404 and :new.evento = 1035 and :new.seqcascata = 2) then
   --31/01 M. Rangel, escape problema uniq chk  na lib 
   p_executar := false;
   goto sai_before;
   null;
  end if;
 
  -- Esse evento � inserido a partir da Trg_u_Tgfcab_Valfin_Sf quando o usu�rio do compras autoriza o lan�amento da nota no sistema, por
  -- algum motivo o usuario liberador esta indo 0 e isso n�o pode acontecer, tem que ir o usu�rio que esta executando a a��o
  -- ent�o eu criei essa trigger justamente para saber quem fez
  -- Ricardo
  if :new.dhlib is not null and :new.codusulib = 0 then
   raise_application_error(-20101,
                           fc_formatahtml_sf('Favor fechar os execut�veis do MGE que est�o abertos para em seguida refazer a opera��o',
                                             null,
                                             null));
  end if;
 
  /* Exce��o � regra adicionada por Marcus Rangel a pedido de Ricardo Soares */
  /* Dever� permancer at� a an�lise definitiva por Ricardo Soares             
     Por Ricardo em 08/01/2018 - Identifiquei que ocorre situa��o em que o liberador do contrato � o 950, inseri o count abaixo para avaliar 
     nessas situa��es
  */
 
  if inserting and :new.codusulib = 950 and :new.seqcascata = 2 and :new.evento = 1035
  --And :New.Codtipoper Not In (404) -- DESABILITADO PARA QUE O ERRO OCORRA E POSSAMOS ANALISAR ESSE PROBLEMA
   then
   select count(*)
     into x
     from ad_tcsconapr c, tgfcab cab
    where c.numcontrato = cab.numcontrato
      and cab.nunota = :new.nuchave
      and :new.tabela = 'TGFCAB'
      and c.nuevento = 1035
      and (c.dtlim is null or c.dtlim > trunc(sysdate));
  
   if x = 9999 /* 0 */
    then
    raise_application_error(-20101,
                            'Por favor entre em contato com o Ricardo da Sankhya para que ele possa acompanhar a libera��o desse lan�amento');
   else
    :new.seqcascata := 1;
   end if;
  end if;
 
  if updating('DHLIB') and :old.dhlib is not null and :new.dhlib is null and
     :new.evento in (1003, 1004, 1005, 1017, 1035, 1042, 1043) then
   -- Por Ricardo Soares - At� 12/06/2017 apenas o evento 1035 fazia parte dessa regra, mas verifiquei que tambem os evento 1003, 1004 e 1005 deviam participar dessa regra afim de evitar que alguem desfa�a o procedimento quando este j� foi enviado para outro usu�rio.
   raise_application_error(-20101, fc_formatahtml_sf('Registro j� foi liberado', null, null));
  end if;
 
  if updating('REPROVADO') and (:new.reprovado = 'S' and :new.evento in (1035, 1043)) and
     :new.tabela <> 'AD_ADTSSACAB' then
   raise_application_error(-20101,
                           fc_formatahtml_sf('Registro n�o pode ser reprovado.',
                                             'Caso n�o esteja de acordo com esse processo inicie o processo de devolu��o, uma vez que a nota j� foi emitida e o caminho correto � entrar com ela em sistema e efetuar sua devolu��o',
                                             null));
  end if;
 
  if updating('DHLIB') and :new.dhlib is not null and :new.tabela in ('AD_ADTSSACAB', 'AD_ADTOCAB') then
   -- AD_ADTSSACAB Por Ricardo Soares de Oliveira em 20/03/2018 processo Adiantamento SSA
   -- AD_ADTOCAB Por Ricardo em 16/04/2018 - Processo Adiantamento SSA / Subprocesso Rateio de valores por parceiro
  
   stp_set_atualizando('S');
   p_executar          := true;
   r_lib.ad_nuadto     := :new.ad_nuadto;
   r_lib.codtipoper    := :new.codtipoper;
   r_lib.codusulib     := :new.codusulib;
   r_lib.ad_codusulib  := :new.ad_codusulib;
   r_lib.codususolicit := :new.codususolicit;
   r_lib.dhlib         := :new.dhlib;
   r_lib.dhsolicit     := :new.dhsolicit;
   r_lib.evento        := :new.evento;
   r_lib.nuchave       := :new.nuchave;
   r_lib.obslib        := :new.obslib;
   r_lib.observacao    := :new.observacao;
   r_lib.sequencia     := :new.sequencia;
   r_lib.tabela        := :new.tabela;
   r_lib.vlratual      := :new.vlratual;
   r_lib.vlrliberado   := :new.vlrliberado;
   r_lib.reprovado     := :new.reprovado;
   stp_set_atualizando('N');
  elsif updating('DHLIB') and :new.dhlib is not null and :new.evento in (1015, 1028, 1035 /*, 1042*/) then
   -- Por Ricardo em 15/05/2018 inclui a 1015, pois o Rodrigo passou a tratar o teto, com isso n�o existe a necessidade de gerar a despesa financeira como provis�o para ser alterada pela contabilidade.
  
   p_executar := true;
  
   if :new.seqcascata = 2 then
    -- Fa�o isso para os casos em que o suplente n�o � comprador, mas esta liberando no lugar de um que �
    select count(*)
      into v_count
      from tsiusu u, tgfven v
     where u.codvend = v.codvend
       and u.codusu = :new.ad_codusulib
       and v.tipvend = 'C';
   
    -- Inicio de 06, implementado em 31/10/2017 por ricardo soares
    begin
    
     select nvl(t.ad_exigaprvde, 'Z')
       into v_exige
       from tgftop t, tgfcab c
      where t.codtipoper = c.codtipoper
        and t.dhalter = c.dhtipoper
        and t.tipatualfin = 'I'
        and t.atualfin = -1
        and c.nunota = :new.nuchave
        and :new.tabela = 'TGFCAB';
    
    exception
     -- Se entra aqui � porque o tipo de opera��o n�o gera uma despesa, nesse caso n�o me interessa
     when no_data_found then
      v_exige := 'Z';
     
    end;
    -- Fim de 06, implementado em 31/10/2017 por ricardo soares
   
    if v_count > 0 or v_exige in ('O', 'R', 'S') then
     -- Se entrou aqui � porque o liberador de origem era um comprador
     :new.seqcascata := 1;
     null;
    end if;
   
   end if;
  
   r_lib.ad_nuadto     := :new.ad_nuadto;
   r_lib.codtipoper    := :new.codtipoper;
   r_lib.codusulib     := :new.codusulib;
   r_lib.ad_codusulib  := :new.ad_codusulib;
   r_lib.codususolicit := :new.codususolicit;
   r_lib.dhlib         := :new.dhlib;
   r_lib.dhsolicit     := :new.dhsolicit;
   r_lib.evento        := :new.evento;
   r_lib.nuchave       := :new.nuchave;
   r_lib.obslib        := :new.obslib;
   r_lib.observacao    := :new.observacao;
   r_lib.seqcascata := case
                        when :new.seqcascata = 0 then
                         1
                        else
                         nvl(:new.seqcascata, 1)
                       end;
   r_lib.sequencia     := :new.sequencia;
   r_lib.tabela        := :new.tabela;
   r_lib.vlratual      := :new.vlratual;
   r_lib.vlrliberado   := :new.vlrliberado;
  
  elsif updating('DHLIB') and :new.dhlib is not null and :new.evento in (1017) then
  
   update tgffin f
      set f.provisao    = 'N',
          f.ad_variacao = 'liberacaolimites'
    where f.nufin = :new.nuchave
      and f.dhbaixa is null;
  
   -- inclui esse bloco em 14/11 - teste com NUFIN 21475368 TOP 3, antes quem fazia isso era um insert na AD_TSILIBLOG a partir da
   -- TRG_U_TSILIB_PROVISAO, mas estava dando loop
  
  elsif updating('DHLIB') and :new.dhlib is not null and :new.evento in (1010) and :new.tabela = 'TGFFIN' then
  
   update tgffin f
      set f.provisao    = 'N',
          f.ad_variacao = 'liberacaolimites'
    where f.nufin = :new.nuchave
      and f.dhbaixa is null;
  
  elsif updating('DHLIB') and :new.dhlib is not null and :new.evento in (1043) then
   /*Libera��o devolu��o venda feita pelo departamento comercial*/
  
   begin
    select nvl(d.forma, 'A') into v_forma from ad_tgfdev d where d.nunota = :new.nuchave;
   exception
    when no_data_found then
     v_forma := 'R';
   end;
  
   if v_forma = 'A' then
    raise_application_error(-20101,
                            fc_formatahtml_sf('A��o Cancelada',
                                              'Necess�rio informar se a devolu��o de venda ser� efetuada por reembolso ou compensa��o',
                                              'Acesse <i>>>Outras Op��es >>Outras A��es >>Definir Forma Devolu��o</i>!'));
   
   else
    update ad_tgfdev d set d.codusulib = :new.codusulib where d.nunota = :new.nuchave;
   
    v_diasemana := to_char(trunc(sysdate) + 3, 'd');
   
    update tgffin f
       set f.provisao = 'N',
           f.dtvenc = case
                       when to_char(f.dtvenc, 'd') = 7 then
                        f.dtvenc + 2
                       when to_char(f.dtvenc, 'd') = 1 then
                        f.dtvenc + 1
                       else
                        f.dtvenc
                      end,
           --f.Codtiptit = Decode(v_Forma, 'R', 8, 'B', 5, 61),
           f.codtiptit = decode(v_forma, 'R', 56, 'B', 5, 61),
           
           f.nossonum = case
                         when v_forma = 'R' then
                          'PG' || nufin
                         else
                          f.nossonum
                        end,
           -- Por Ricardo Soares em 28/02/2018, conforme solicita��o Fl�vio e Abel, quando for cr�dito em conta passa para tipo de t�tulo 56 - Transf. Banc�ria Individual
           f.historico = decode(v_forma,
                                'R',
                                'Reembolso cr�dito em conta autorizado por ' || :new.codusulib || ' - ' ||
                                ad_get.nomeusu(:new.codusulib, 'Resumido') || ' / ' || f.historico,
                                'B',
                                'Reembolso com pagto boleto autorizado por ' || :new.codusulib || ' - ' ||
                                ad_get.nomeusu(:new.codusulib, 'Resumido') || ' / ' || f.historico,
                                'Compensa��o autorizado por ' || :new.codusulib || ' - ' ||
                                ad_get.nomeusu(:new.codusulib, 'Resumido') || ' / ' || f.historico)
     where f.nunota = :new.nuchave
       and f.dhbaixa is null;
   end if;
  
  elsif updating('DHLIB') and :new.dhlib is not null and :new.evento in (1006) then
   -- Ajuste 009 - Por Ricardo em 15/10/2018 incluir evento 1006 pois estavam ocorrendo situa��es em que o RH aprovava mas n�o aparecia para o financeiro      
   p_executar    := true;
   r_lib.evento  := :new.evento;
   r_lib.nuchave := :new.nuchave;
   r_lib.tabela  := :new.tabela;
  
  else
   p_executar := false;
  end if;
 
  <<sai_before>>
  null;
 
 end before each row;

 after statement is
  v_codger     int;
  v_codusu     int;
  v_count      int;
  v_diasatual  int;
  v_dhlib      date;
  v_reprovado  varchar2(10);
  v_observacao varchar2(400);
 
 begin
  /*
    If r_Lib.Nuchave In (22819315, 22807310) Then
      Goto Sai_After;
    End If;
  */
  if nvl(p_executar, false) then
  
   if r_lib.tabela = 'TGFCAB' and r_lib.evento = 1006 then
    -- Ajuste 009 - Por Ricardo em 15/10/2018 incluir evento 1006 pois estavam ocorrendo situa��es em que o RH aprovava mas n�o aparecia para o financeiro      
    begin
     select 1, l.observacao, l.reprovado, l.dhlib
       into v_count, v_observacao, v_reprovado, v_dhlib
       from tsilib l
      where l.nuchave = r_lib.nuchave
        and l.evento = 1007
        and l.tabela = r_lib.tabela;
    
    exception
     when no_data_found then
      v_count := 0;
    end;
   
    if v_count > 0 and v_dhlib is null then
     raise_application_error(-20101,
                             fc_formatahtml_sf('A��o Cancelada',
                                               'Essa libera��o s� pode ocorrer depois de feita a libera��o por parte do RH',
                                               'Entre em contato com o RH e oriente o mesmo quanto a libera��o do evento.'));
    
    else
     goto sai_after;
    end if;
   end if;
  
   if r_lib.tabela = 'AD_ADTSSACAB' then
   
    if r_lib.reprovado = 'S' then
    
     update ad_adtssacab c
        set c.codusufin     = r_lib.codusulib,
            c.situacao      = 'R',
            c.nuacerto      = null,
            c.dhsolicitacao = null,
            c.dhaprovfin    = null,
            c.dhaprovadt    = null,
            c.codusuapr     = null
      where c.nunico = r_lib.nuchave;
    
     --Variaveis_Pkg.v_Atualizando := True;
     delete from tgffre f where f.nuacerto = r_lib.ad_nuadto;
     delete from tgffin f where f.numdupl = r_lib.ad_nuadto;
     ---Commit;
     --Variaveis_Pkg.v_Atualizando := False;
    
     update ad_adtssapar p set p.nufin = null where p.nunico = r_lib.nuchave;
    
     --If r_Lib.Evento = 1035 Then
     delete from tsilib l
      where l.nuchave = r_lib.ad_nuadto
        and l.tabela = 'AD_ADTSSACAB';
     --End If;
    
    elsif r_lib.evento = 1042 then
    
     begin
      select 1, l.observacao, l.reprovado, l.dhlib
        into v_count, v_observacao, v_reprovado, v_dhlib
        from tsilib l
       where l.nuchave = r_lib.nuchave
         and l.evento = 1035
         and l.tabela = 'AD_ADTSSACAB';
     
     exception
      when no_data_found then
       v_count := 0;
      
     end;
    
     if v_count > 0 and v_dhlib is null then
      raise_application_error(-20101,
                              fc_formatahtml_sf('A��o Cancelada', 'Aguardando libera��o respons�vel CR', null));
     
     end if;
    
     update ad_adtssacab c
        set c.codusufin  = r_lib.codusulib,
            c.dhaprovfin = sysdate,
            c.situacao   = 'A'
      where c.nunico = r_lib.nuchave;
    
     update ad_adtssapar p set p.provisao = 'N' where p.nunico = r_lib.nuchave;
    
     stp_set_atualizando('N');
    
     -- altera��o para contemplar as despesas oriundas do renovar
     update tgffin f
        set provisao = 'N'
      where f.numdupl = r_lib.ad_nuadto
        and (exists (select 1
                       from ad_adtssapar p
                      where p.nunico = r_lib.nuchave
                        and p.nufin = f.nufin) or exists
             (select 1
                from ad_adtssaparrenovar r
               where r.nunico = r_lib.nuchave
                 and r.nufindesp = f.nufin));
    
    else
     -- Entra quando 1035
    
     begin
      select 1, l.observacao, l.reprovado, l.dhlib -- Caso tenha uma libera��o pendente por parte do financeiro o liberador principal n�o esta autorizado a fazer a libera��o, Ricardo 20/03/2018 - Adiantamento SSA
        into v_count, v_observacao, v_reprovado, v_dhlib
        from tsilib l
       where l.nuchave = r_lib.nuchave
         and l.evento = 1042
         and l.tabela = 'AD_ADTSSACAB';
     
     exception
      when no_data_found then
       v_count := 0;
      
     end;
    
     if v_count > 0 then
      -- Se tem libera��o do financeiro e ela ainda n�o foi feita ent�o s� registra que aprovou mas n�o executa mais nada
     
      ad_set.ins_ad_tsiliblog(p_nuchave     => r_lib.nuchave,
                              p_tabela      => 'AD_ADTSSACAB',
                              p_dhsolicit   => r_lib.dhsolicit,
                              p_dhlib       => r_lib.dhlib,
                              p_codususol   => r_lib.codususolicit,
                              p_codusulib   => r_lib.codusulib,
                              p_vlratual    => r_lib.vlratual,
                              p_vlrliberado => r_lib.vlrliberado,
                              p_evento      => 1035,
                              p_observacao  => r_lib.observacao,
                              p_obslib      => r_lib.obslib,
                              p_operacao    => 'Aprovou Adiantamento',
                              p_nuadto      => r_lib.ad_nuadto);
     
      /*Insert Into Ad_Tsiliblog (Nuchave, Tabela, Dhsolicit, Dhlib, Codususol, Codusulib, Codusuexc, Vlratual, Vlrliberado, Evento, Observacao, Obslib, Operacao, Dhoper, Seqlog, Nuadto)
      Values (r_Lib.Nuchave, 'AD_ADTSSACAB', r_Lib.Dhsolicit, r_Lib.Dhlib, r_Lib.Codususolicit, r_Lib.Codusulib, v_Codusulogado, r_Lib.Vlratual, r_Lib.Vlrliberado, 1035, r_Lib.Observacao, r_Lib.Obslib, 'Aprovou Adiantamento', Sysdate, Ad_Seq_Tsilib_Log.Nextval, r_Lib.Ad_Nuadto);*/
     
      update ad_adtssacab c
         set c.dhaprovadt = sysdate,
             c.codusuapr  = r_lib.codusulib
       where c.nunico = r_lib.nuchave;
     
     else
     
      ad_set.ins_ad_tsiliblog(p_nuchave     => r_lib.nuchave,
                              p_tabela      => 'AD_ADTSSACAB',
                              p_dhsolicit   => r_lib.dhsolicit,
                              p_dhlib       => r_lib.dhlib,
                              p_codususol   => r_lib.codususolicit,
                              p_codusulib   => r_lib.codusulib,
                              p_vlratual    => r_lib.vlratual,
                              p_vlrliberado => r_lib.vlrliberado,
                              p_evento      => 1035,
                              p_observacao  => r_lib.observacao,
                              p_obslib      => r_lib.obslib,
                              p_operacao    => 'Aprovou Adiantamento',
                              p_nuadto      => r_lib.ad_nuadto);
     
      /*Insert Into Ad_Tsiliblog (Nuchave, Tabela, Dhsolicit, Dhlib, Codususol, Codusulib, Codusuexc, Vlratual, Vlrliberado, Evento, Observacao, Obslib, Operacao, Dhoper, Seqlog, Nuadto)
      Values
         (r_Lib.Nuchave, 'AD_ADTSSACAB', r_Lib.Dhsolicit, r_Lib.Dhlib, r_Lib.Codususolicit, r_Lib.Codusulib, v_Codusulogado, r_Lib.Vlratual, r_Lib.Vlrliberado, 1035, r_Lib.Observacao, r_Lib.Obslib, 'Aprovou Adiantamento', Sysdate, Ad_Seq_Tsilib_Log.Nextval, r_Lib.Ad_Nuadto);*/
     
      update ad_adtssacab c
         set c.situacao   = 'A',
             c.dhaprovadt = sysdate,
             c.codusuapr  = r_lib.codusulib
       where c.nunico = r_lib.nuchave;
     
      update ad_adtssapar p set p.provisao = 'N' where p.nunico = r_lib.nuchave;
     
      update tgffin f
         set provisao = 'N'
       where f.numdupl = r_lib.ad_nuadto
         and exists (select 1
                from ad_adtssapar p
               where p.nunico = r_lib.nuchave
                 and p.nufin = f.nufin);
      -- by rodrigo novo processo renovar 
      update tgffin f
         set provisao = 'N'
       where exists (select 1
                from ad_adtssaparrenovar p
               where p.nunico = r_lib.nuchave
                 and (p.nufinrec = f.nufin));
     
      update tgffin f
         set provisao = 'N'
       where exists (select 1
                from ad_adtssaparrenovar p
               where p.nunico = r_lib.nuchave
                 and (p.nufindesp = f.nufin));
     
     end if;
    
    end if;
   
   end if;
  
   if r_lib.tabela = 'AD_ADTOCAB' then
    -- em 16/04/2018 Rateio de Valores por Parceiro, o processo de integrado n�o entra aqui no momento
   
    if r_lib.reprovado = 'S' then
    
     update ad_adtocab c
        set c.dhinclusao = sysdate,
            c.codusu     = v_codusulogado,
            c.situacao   = 'E'
      where c.nuseq = r_lib.nuchave;
    
     delete from tgffre f where f.nuacerto = r_lib.ad_nuadto;
     delete from tgffin f where f.numdupl = r_lib.ad_nuadto;
    
     update ad_adtodet d
        set d.nuadto = null,
            d.dtadto = null
      where d.nuseq = r_lib.nuchave;
    
     delete from tsilib l
      where l.nuchave = r_lib.ad_nuadto
        and l.tabela = 'AD_ADTOCAB';
    
    else
     -- Entra quando aprovado
    
     ad_set.ins_ad_tsiliblog(p_nuchave     => r_lib.nuchave,
                             p_tabela      => 'AD_ADTOCAB',
                             p_dhsolicit   => r_lib.dhsolicit,
                             p_dhlib       => r_lib.dhlib,
                             p_codususol   => r_lib.codususolicit,
                             p_codusulib   => r_lib.codusulib,
                             p_vlratual    => r_lib.vlratual,
                             p_vlrliberado => r_lib.vlrliberado,
                             p_evento      => 1035,
                             p_observacao  => r_lib.observacao,
                             p_obslib      => r_lib.obslib,
                             p_operacao    => 'Aprovou Rateio',
                             p_nuadto      => r_lib.ad_nuadto);
    
     update ad_adtocab c
        set c.dhinclusao = sysdate,
            c.codusu     = v_codusulogado,
            c.situacao   = 'F'
      where c.nuseq = r_lib.nuchave;
    
     update tgffin f
        set provisao = 'N'
      where f.numdupl = r_lib.ad_nuadto
        and exists (select 1 from ad_adtodet d where d.nuadto = r_lib.ad_nuadto);
    
    end if;
   
   end if;
  
   select count(*)
     into v_count
     from tsilib l
    where l.nuchave = r_lib.nuchave
      and l.tabela = r_lib.tabela --'TGFCAB' Por Ricardo Soares em 22/08/2017 
      and l.dhlib is null
      and l.evento = 1001;
  
   /*IF v_Count IS NOT NULL AND v_Count > 0 THEN
         -- Por Ricardo em 22/08/2017, comentei esse bloco e inseri um novo que analisa se o registro no financeiro ainda esta fora do prazo
         Raise_Application_Error(-20101, Fc_Formatahtml_Sf('Dias uteis para vencimento da primeira parcela inferior ao estabelecido pelo financeiro', 'Entre em contato com o departamento financeiro e solicite a aprova��o desse lan�amento para dar seguimento a sua aprova��o', NULL));
   
   END IF;*/
  
   if v_count is not null and v_count > 0 then
   
    select min(fc_difdata_dias_uteis1(trunc(sysdate), f.dtvenc) +
                (case
                  when to_char(sysdate, 'HH24') > 16 then
                   1
                  else
                   0
                 end))
      into v_diasatual
      from tgffin f
     where (f.nufin = r_lib.nuchave and r_lib.tabela = 'TGFFIN')
        or (f.nunota = r_lib.nuchave and r_lib.tabela = 'TGFCAB');
   
    if v_diasatual = 0 then
     -- T�tulo vencido
     raise_application_error(-20101,
                             fc_formatahtml_sf('T�tulo Vencido.',
                                               'Renegocie o vencimento com o fornecedor e solicite a altera��o do vencimento para a data negociada',
                                               null));
    
    elsif v_diasatual < 3 then
     -- Se maior que zero existe uma pendencia relativa ao vencimento do t�tulo que precisa ser resolvida
     raise_application_error(-20101,
                             fc_formatahtml_sf('Dias uteis ' || v_diasatual ||
                                               ' para vencimento da primeira parcela inferior ao estabelecido pelo financeiro',
                                               'Entre em contato com o departamento financeiro e solicite a aprova��o desse lan�amento para dar seguimento a sua aprova��o',
                                               null));
    
    else
     ad_set.del_liberacao(r_lib.nuchave, r_lib.tabela, 1001);
    end if;
   
   end if;
  
   if r_lib.evento = 1035 and r_lib.tabela = 'TGFCAB' and r_lib.nuchave not in (22819315, 22807310, 30627426) then
   
    if r_lib.seqcascata = 2 then
    
     --raise_application_error(-20105,'Depura��o de problema de libera��o - Marcus. Desculpe o transtorno.');
    
     -- Se entrou aqui � porque a libera��o esta sendo feita pelo dono do CR, ent�o � nesse momento que eu direciono para o comprador
     begin
      select u.codusu
        into v_codusu
        from tsiusu u, tgfcab c
       where u.codvend = c.codvend
         and c.nunota = r_lib.nuchave;
     exception
      when no_data_found then
       raise_application_error(-20101,
                               fc_formatahtml_sf('A��o CAncelada',
                                                 'O Comprador referenciado na nota de compra n�o esta vinculado a nenhum usu�rio v�lido',
                                                 null));
     end;
    
     select count(*)
       into v_count
       from tsilib l
      where l.nuchave = r_lib.nuchave
        and l.seqcascata = 2
        and l.sequencia <> r_lib.sequencia
        and l.evento = 1035
        and l.dhlib is null;
    
     if v_count = 0 then
      -- SE V_COUNT = 0 � proque n�o existem pendencias e posso direcionar para o comprador
      ad_set.ins_liberacao1035('TGFCAB',
                               r_lib.nuchave,
                               1035,
                               r_lib.vlrliberado,
                               v_codusu,
                               r_lib.observacao,
                               1,
                               r_lib.codtipoper,
                               errmsg);
     
      if errmsg is not null then
       raise_application_error(-20105, errmsg);
      end if;
     
     end if;
    
    else
    
     select count(*)
       into v_count
       from tsilib l
      where l.nuchave = r_lib.nuchave
        and l.tabela = 'TGFCAB'
        and l.dhlib is null
        and l.evento = 1035
        and l.codtipoper not in (404) --ACERTADO COM O RICARDO DIA 06/08/2018 BY RODRIGO
           --And l.Sequencia <> r_Lib.Sequencia
           --And Nvl(l.Seqcascata, 1) = 1
        and nvl(l.seqcascata, 0) < 2
        and l.codusulib <> r_lib.codusulib;
    
     if v_count = 0 then
      -- Se n�o encontrou nenhuma outra libera��o pendente ent�o pode alterar o campo PROVISAO da TGFFIN,
      -- mas antes verifica se o comprador tem al�ada.
     
      begin
       select count(*)
         into v_junior
         from tsiusu u, tgfven v
        where u.codvend = decode(u.codvend, 5025, 418, v.codvend)
          and u.codusu = r_lib.codusulib
          and nvl(v.ad_alcadaaprpgt, 0) < r_lib.vlrliberado
          and v.codvend > 0 -- Por Ricardo Soares em 08/08, existem situa��es que mesmo o cara n�o sendo 
       --comprador � feita a prova��o, e assim deve ir direto pro ELSE assim como j� ia anteriormente
       ;
      
      exception
       when no_data_found then
        v_count := 0;
      end;
     
      if v_junior > 0 and r_lib.codusulib <> 950 then
       -- Se v_count > 0 � porque o comprador � Jr                                
       begin
        select nvl(ul.codusu, 0)
          into v_codger
          from tsiusu u, tgfven v, tgfven g, tsiusu ul
         where u.codvend = v.codvend
           and u.codusu = r_lib.codusulib
           and v.tipvend = 'C'
           and v.codger > 0
           and v.codger = g.codvend
           and nvl(ul.codvend, 0) = g.codvend;
       
       exception
        when no_data_found then
         v_codger := 0;
       end;
      
       if v_codger = 0 then
        raise_application_error(-20101,
                                fc_formatahtml_sf('A��o Cancelada',
                                                  'Esse lan�amento exige a aprova��o do supervisor e o mesmo n�o est� vinculado ao cadastro do comprador',
                                                  'Entre em contato com o Admnistrador do Sistema e solicite a vincula��o do <b>supervisor</b> ao seu c�digo de comprador! ' ||
                                                  v_junior));
       
       else
       
        ad_set.ins_liberacao1035('TGFCAB',
                                 r_lib.nuchave,
                                 1035,
                                 r_lib.vlrliberado,
                                 v_codger,
                                 r_lib.observacao,
                                 1,
                                 r_lib.codtipoper,
                                 errmsg);
       
        if errmsg is not null then
         raise_application_error(-20105, errmsg);
        end if;
        --raise_application_error(-20105,'Depura��o de problema de libera��o - Marcus. Desculpe o transtorno.');
       
       end if;
      else
      
       ad_set.ins_ad_tsiliblog(p_nuchave     => r_lib.nuchave,
                               p_tabela      => 'TGFCAB',
                               p_dhsolicit   => r_lib.dhsolicit,
                               p_dhlib       => r_lib.dhlib,
                               p_codususol   => r_lib.codususolicit,
                               p_codusulib   => r_lib.codusulib,
                               p_vlratual    => r_lib.vlratual,
                               p_vlrliberado => r_lib.vlrliberado,
                               p_evento      => 1035,
                               p_observacao  => r_lib.observacao,
                               p_obslib      => r_lib.obslib,
                               p_operacao    => 'Liberou Pagamento',
                               p_nuadto      => r_lib.ad_nuadto);
      
       /*Insert Into Ad_Tsiliblog (Nuchave, Tabela, Dhsolicit, Dhlib, Codususol, Codusulib, Codusuexc, Vlratual, Vlrliberado, Evento, Observacao, Obslib, Operacao, Dhoper, Seqlog, Nuadto)
       Values
          (r_Lib.Nuchave, 'TGFCAB', r_Lib.Dhsolicit, r_Lib.Dhlib, r_Lib.Codususolicit, r_Lib.Codusulib, v_Codusulogado, r_Lib.Vlratual, r_Lib.Vlrliberado, 1035, r_Lib.Observacao, r_Lib.Obslib, 'Liberou Pagamento', Sysdate, Ad_Seq_Tsilib_Log.Nextval, r_Lib.Ad_Nuadto);*/
      
      end if;
     
     end if;
    end if;
   
   elsif r_lib.evento in (1015, 1035) and r_lib.tabela = 'TGFFIN' then
   
    ad_set.ins_ad_tsiliblog(p_nuchave     => r_lib.nuchave,
                            p_tabela      => 'TGFFIN',
                            p_dhsolicit   => r_lib.dhsolicit,
                            p_dhlib       => r_lib.dhlib,
                            p_codususol   => r_lib.codususolicit,
                            p_codusulib   => r_lib.codusulib,
                            p_vlratual    => r_lib.vlratual,
                            p_vlrliberado => r_lib.vlrliberado,
                            p_evento      => r_lib.evento,
                            p_observacao  => r_lib.observacao,
                            p_obslib      => r_lib.obslib,
                            p_operacao    => 'Liberou Pagamento',
                            p_nuadto      => r_lib.ad_nuadto);
   
    /*Insert Into Ad_Tsiliblog (Nuchave, Tabela, Dhsolicit, Dhlib, Codususol, Codusulib, Codusuexc, Vlratual, Vlrliberado, Evento, Observacao, Obslib, Operacao, Dhoper, Seqlog, Nuadto)
    Values (r_Lib.Nuchave, 'TGFFIN', r_Lib.Dhsolicit, r_Lib.Dhlib, r_Lib.Codususolicit, r_Lib.Codusulib, v_Codusulogado, r_Lib.Vlratual, r_Lib.Vlrliberado, 1035, r_Lib.Observacao, r_Lib.Obslib, 'Liberou Pagamento', Sysdate, Ad_Seq_Tsilib_Log.Nextval, r_Lib.Ad_Nuadto);*/
   
    update ad_jurite
       set situacao  = 'F',
           codusujur = r_lib.codusulib,
           dhjur     = sysdate
     where nufin = r_lib.nuchave;
   
    update ad_reqcart
       set situacao  = 'F',
           codusualt = r_lib.codusulib,
           dtalter   = sysdate
     where nufinreq = r_lib.nuchave;
   
   end if;
  else
   goto sai_after;
  end if;
 
  <<sai_after>>
  null;
 end after statement;
end;
/
