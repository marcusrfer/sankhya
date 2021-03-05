create or replace trigger ad_trg_aiud_tgffin_acerto_sf
 after delete or insert or update on sankhya.tgffin
 referencing new as new old as old
 for each row
declare
 v_aprovacerto char(1);
 r_fin         tgffin%rowtype;
 v_codusulib   int;
 v_codevento   int;
 v_count       int := 0;
 v_codusu      int := stp_get_codusulogado;
 v_melhorvalor number;
 v_vlrfrete    number;
 v_percvar     number;
 v_obslib      tsilib.observacao%type;
 v_acerto      boolean;
 v_fretefob    boolean;
 v_terminal    varchar2(30);
 --v_Libpend     Int := 0;
 errmsg varchar2(4000);
 error exception;

begin
 /*
 Autor: Marcus Rangel
 Dt. Criação: 31/08/2016
 Objetivo: Atender o processo de autorização de pagamento de acerto.
 Ao inserir o lançamento oriundo do acerto, verifica se atende os requisitos e
 gera a solicitação de liberação
 */

 select distinct (upper(terminal)) into v_terminal from v$session where audsid = userenv('sessionid');

 -- verifica se a top exige aprovação de acerto
 begin
  select t.ad_aprovbaixaacerto
    into v_aprovacerto
    from tgftop t
   where t.codtipoper = nvl(:new.codtipoper, :old.codtipoper)
     and t.dhalter = nvl(:new.dhtipoper, :old.dhtipoper);
 exception
  when no_data_found then
   v_aprovacerto := 'N';
 end;

 /* sai se não encontra */
 if nvl(v_aprovacerto, 'N') = 'N' then
  return;
 end if;

 /*busca o liberador*/
 begin
  select codusu
    into v_codusulib
    from tsiusu u
   where ad_gertransp = 'S'
     and nvl(u.dtlimacesso, '31/12/2099') > trunc(sysdate);
 exception
  /*When Too_Many_Rows Then
    Select Codusu
      Into v_Codusulib
      From Tsiusu u
     Where Ad_Gertransp = 'S'
       And Rownum = 1
       And Nvl(u.Dtlimacesso, '31/12/2099') > Trunc(Sysdate);
  When No_Data_Found Then
    v_Codusulib := 0;*/
  when others then
   v_codusulib := 950;
 end;

 /* identifica o lançamento na inserção e gera a solicitaçao de liberação */
 if inserting then
 
  r_fin.nufin        := :new.nufin;
  r_fin.nunota       := :new.nunota;
  r_fin.vlrdesdob    := :new.vlrdesdob;
  r_fin.dhbaixa      := :new.dhbaixa;
  r_fin.codctabcoint := :new.codctabcoint;
  r_fin.recdesp      := :new.recdesp;
  r_fin.provisao     := :new.provisao;
  r_fin.desdobdupl   := :new.desdobdupl;
  r_fin.nucompens    := :new.nucompens;
  r_fin.codtipoper   := :new.codtipoper;
  r_fin.chavecte     := :new.chavecte;
  r_fin.origem       := :new.origem;
  r_fin.numdupl      := :new.numdupl;
  r_fin.codnat       := :new.codnat;
  r_fin.codcencus    := :new.codcencus;
 
  -- verifica se oriundo da rotina de acerto de ordem de carga
  if r_fin.dhbaixa is null
     and r_fin.codctabcoint is null
     and r_fin.recdesp = -1
     and r_fin.provisao = 'S'
     and (r_fin.desdobdupl is null or r_fin.desdobdupl = 'F') then
   v_acerto := true;
  end if;
 
  -- verifica se oriundo da rotina de entrada de frete FOB na nota de compra
  if r_fin.codtipoper = 3
     and r_fin.chavecte is not null
     and r_fin.origem = 'E'
     and r_fin.desdobdupl = 'F'
     and r_fin.numdupl is not null
     and r_fin.codnat = 4050300
     and r_fin.provisao = 'S'
     and r_fin.recdesp = -1 then
   v_fretefob := true;
  end if;
 
  if v_acerto then
  
   select evelibpagacert into v_codevento from ad_tsfelt e where e.nuelt = 1;
  
   v_obslib := 'Ref. Acerto de Ordem de Carga nº ' || r_fin.nucompens;
  
  elsif v_fretefob then
   begin
    select nvl(vlrfrete, 1) into v_vlrfrete from tgfcab c where nunota = r_fin.nunota;
   
    v_melhorvalor := to_number(substr(ad_pkg_fob.melhorvalor(r_fin.nunota),
                                      instr(ad_pkg_fob.melhorvalor(r_fin.nunota), '-') + 1));
   
    v_percvar := round(((1 - (v_melhorvalor / v_vlrfrete)) * 100), 2);
   
    -- Verifica se a variação dos valor e do valor sugerido é maior que a definição do paramêtro
   
    if v_percvar > nvl(get_tsipar_inteiro('VARMAXVLRFRETE'), 0) then
    
     select evelibvarprcfob into v_codevento from ad_tsfelt e where e.nuelt = 1;
    
     v_obslib := 'Ref. Coleta FOB nº único: ' || r_fin.nunota || '. Variação de ' || v_percvar || '.';
    
    else
     return;
    end if;
   exception
    when others then
     errmsg := 'Erro na busca do valor do frete ' || sqlerrm;
     raise error;
   end;
  end if;
 
  -- se preencheu na seção acima, gera liberação
  if v_codevento is null then
   --raise_application_error(-20105, 'Evento de liberação não encontrado!');
   return;
  else
   begin
    insert into tsilib
     (nuchave, tabela, evento, codususolicit, dhsolicit, codusulib, vlrlimite, vlratual, observacao)
    values
     (r_fin.nufin, 'TGFFIN', v_codevento, v_codusu, sysdate, v_codusulib, 1, r_fin.vlrdesdob, v_obslib);
   exception
    when others then
     errmsg := 'Erro ao inserir solicitação de liberação pendente. ' || sqlerrm;
     raise error;
   end;
  
  end if;
 
  /* Envia notificação do sistema */
  begin
   if v_codusulib > 0 then
    ad_set.ins_avisosistema(p_titulo     => 'Solicitação de liberação',
                            p_descricao  => 'Nova solicitação de liberação cadastrada por ' ||
                                            ad_get.nomeusu(v_codusu, 'resumido'),
                            p_solucao    => null,
                            p_usurem     => v_codusu,
                            p_usudest    => v_codusulib,
                            p_prioridade => 3,
                            p_tabela     => 'TGFFIN',
                            p_nrounico   => r_fin.nufin,
                            p_erro       => errmsg);
   
    if errmsg is not null then
     raise error;
    end if;
   end if;
  end;
 
  /* Envia e-mail para liberador */
  /* solicitado pelo Paulo
  Ad_Stp_Gravafilabi(p_Assunto  => 'Solicitação de Liberação',
  p_Mensagem => 'Uma nova solicitação de liberação foi cadastrada pelo financeiro, por favor verifique o quanto antes, devido as datas de vencimento',
  p_Email    => Ad_Get.Mailusu(v_Codusulib));
  */
 
 end if;
 /* tratativa para situação que ocorre na rotina de acerto, na correção do valor */
 if updating then
 
  if v_aprovacerto = 'S'
     and :new.dhbaixa is null
     and (:new.vlrdesdob <> :old.vlrdesdob) then
   begin
    select count(*)
      into v_count
      from tsilib l
     where l.nuchave = :new.nufin
       and tabela = 'TGFFIN'
       and l.evento = v_codevento;
   exception
    when no_data_found then
     errmsg := 'Não encontrou liberação';
     raise error;
   end;
  
   if v_count <> 0 then
    begin
     update tsilib l
        set l.vlratual  = :new.vlrdesdob,
            l.vlrdesdob = :new.vlrdesdob
      where nuchave = :new.nufin
        and tabela = 'TGFFIN'
        and dhlib is null;
    exception
     when others then
      errmsg := 'Erro na atualização da liberação ' || sqlerrm;
      raise error;
    end;
   end if;
  
  end if;
 
  /* Tratativa para quando é gerada solicitação para lançamentos baixados */
  if v_aprovacerto = 'S'
     and :new.dhbaixa is not null
     and :new.codctabcoint is null then
  
   begin
    select count(*)
      into v_count
      from tsilib
     where nuchave = :new.nufin
       and dhlib is null;
   exception
    when others then
     v_count := 0;
   end;
  
   if v_count <> 0 then
    begin
     delete from tsilib where nuchave = :new.nufin;
    exception
     when others then
      errmsg := 'Erro na atualização da liberação ' || sqlerrm;
      raise error;
    end;
   end if;
  
  end if;
 
  -- Ricardo e Marcus em 14/11/20107, esse update estava entrando em conflito com o UPDATE da TRG_U_TSILIB_PROVISAO_SF
  /*BEGIN
        SELECT COUNT(*)
          INTO v_Count
          FROM Tsilib l
         WHERE l.Nuchave = :New.Nufin;
  EXCEPTION
        WHEN No_Data_Found THEN
              v_Count := 0;
  END;
  
  IF v_Count <> 0 THEN
        BEGIN
              SELECT 1
                INTO v_Count
                FROM Tsilib l
               WHERE l.Nuchave = r_Fin.Nufin
                 AND l.Vlratual = r_Fin.Vlrdesdob;
        EXCEPTION
              WHEN No_Data_Found THEN
                    v_Count := 0;
        END;
        IF v_Count <> 1 THEN
              UPDATE Tsilib l
                 SET Vlratual = r_Fin.Vlrdesdob
               WHERE l.Nuchave = r_Fin.Nufin
                 AND l.Vlratual = r_Fin.Vlrdesdob;
        END IF;
  
  END IF;*/
 end if;

exception
 when error then
 
  insert into tsilog
   (codusu, dhevento, descricao, computador, sequencia)
  values
   (stp_get_codusulogado, sysdate, 'Acerto - ' || substr(errmsg, 1, 246), v_terminal, seq_tsilog_seq.nextval);
 
 -- raise_application_error(-20101, ad_fnc_formataerro(errmsg));
 when others then
  errmsg := sqlerrm;
 
  insert into tsilog
   (codusu, dhevento, descricao, computador, sequencia)
  values
   (stp_get_codusulogado, sysdate, 'Acerto - ' || substr(errmsg, 1, 246), v_terminal, seq_tsilog_seq.nextval);
 
 --raise_application_error(-20101, ad_fnc_formataerro(errmsg));*/
end;
/
