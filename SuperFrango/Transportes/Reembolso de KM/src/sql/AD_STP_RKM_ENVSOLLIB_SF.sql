Create Or Replace Procedure "AD_STP_RKM_ENVSOLLIB_SF"(p_codusu    Number,
                                                      p_idsessao  Varchar2,
                                                      p_qtdlinhas Number,
                                                      p_mensagem  Out Varchar2) As
  c         ad_tsfrkmc%Rowtype;
  i         ad_tsfrkmi%Rowtype;
  con       tcscon%Rowtype;
  p         ad_tsfelt%Rowtype;
  x         Int;
  v_perctot Float;
  t         ad_type_of_number := ad_type_of_number();
Begin

  /* 
  * Autor: M. Rangel
  * Processo: Reembolso de KM
  * Objetivo: Gerar a solicitação de liberação e atualiza o status
  */

  For z In 1 .. p_qtdlinhas
  Loop
    c.nureemb := Nvl(act_int_field(p_idsessao, z, 'NUREEMB'), 1);
  
    -- cabeçalho do reembolso
    Begin
      Select *
        Into c
        From ad_tsfrkmc
       Where nureemb = c.nureemb;
    Exception
      When Others Then
        p_mensagem := Sqlerrm;
        Return;
    End;
  
    -- check viagens registradas
    Select Count(*)
      Into x
      From ad_tsfrkmi
     Where nureemb = c.nureemb;
  
    -- valida status, valor e viagens
    If c.status != 'P' Then
      p_mensagem := 'Somente reembolsos pendentes!';
      Return;
    Elsif x = 0 Then
      p_mensagem := 'Não existem viagens registradas para esse reembolso!';
      Return;
    End If;
  
    x := 0;
  
    -- get percentual do rateio
    Select Count(*), Sum(percentual)
      Into x, v_perctot
      From ad_tsfrkmr
     Where nureemb = c.nureemb;
  
    -- valida percentual de rateio
    If x > 0 And v_perctot <> 100 Then
      p_mensagem := 'Por favor, verifique o total do percentual de rateio, pois o mesmo está diferente de 100';
      Return;
    End If;
  
    -- get parametros transporte
    Begin
      Select *
        Into p
        From ad_tsfelt
       Where nuelt = 1;
    Exception
      When Others Then
        p_mensagem := Sqlerrm;
        Return;
    End;
  
    Begin
      Select Count(*)
        Into x
        From tsilib
       Where nuchave = c.nureemb
         And tabela = 'AD_TSFRKMC'
         And evento = p.nueventoreembkm;
    Exception
      When Others Then
        p_mensagem := 'Erro ao verificar se já existem liberações para esse reemboolso ' || Chr(13) || Sqlerrm;
        Return;
    End;
  
    -- get dados do contrato
    Begin
      Select *
        Into con
        From tcscon
       Where numcontrato = p.numcontratokm;
    Exception
      When Others Then
        p_mensagem := 'Não foi possível encontrar o contrato base. Verifique o número do contrato informado na tela de parâmetros.<br>' ||
                      Sqlerrm;
        Return;
    End;
  
    -- total de km
    Begin
      Select Sum(totalkm), Sum(vlrtotal)
        Into i.totalkm, i.vlrtotal
        From ad_tsfrkmi
       Where nureemb = c.nureemb;
    Exception
      When Others Then
        p_mensagem := 'Não foi possível coletar o total de Km das viagens informadas. <br>' || Sqlerrm;
        Return;
    End;
  
    If Nvl(i.totalkm, 0) = 0 Then
      p_mensagem := 'Reembolso não possui total de Km calculado!';
      Return;
    Elsif Nvl(i.vlrtotal, 0) = 0 Then
      p_mensagem := 'Reembolso não possui valor total calculado!';
      Return;
    End If;
  
    -- liberador do CR
    Begin
      t.extend;
    
      /*Select codusuresp
       Into t(t.last)
       From tsicus
      Where codcencus = c.codcencus;*/
    
      -- M. Rangel - 17/12/2018
      -- alteração para buscar o liberador do CR de fonte alteranativa
      -- conforme instrução enviada por e-mail
      Select u.codusu
        Into t(t.last)
        From ad_itesolcpalibcr l
        Join tsiusu u
          On u.codusu = l.codusu
       Where codcencus = c.codcencus
         And ativo = 'SIM'
         And Nvl(aprova, 'N') = 'S'
            --And l.vlrfinal >= i.vlrtotal
         And (u.Dtlimacesso Is Null Or u.Dtlimacesso > Trunc(Sysdate));
    
      If Nvl(t(t.last), 0) = 0 Then
        p_mensagem := 'Não existe usuário responsável cadastrado para o centro de resultados informado! Por favor verifique com seu gestor ou com a área de transporte sobre "Liberadores por CR".';
        Return;
      End If;
    
    Exception
      When Others Then
        p_mensagem := 'Não foi possível buscar os dados do usuário liberador do centro de resultados informado! <br>Por favor verifique o cadastro de Alçada de Liberação por C.R.' ||
                      Sqlerrm;
        Return;
    End;
  
    t.extend;
    t(t.last) := p.codusulibrkm;
  
    -- insere liberações
    For z In t.first .. t.last
    Loop
      Begin
        Insert Into tsilib
          (nuchave, tabela, evento, sequencia, codususolicit, dhsolicit, vlratual, vlrlimite, codusulib, codparc,
           codcencus, codnat, codproj, observacao)
        Values
          (c.nureemb, 'AD_TSFRKMC', p.nueventoreembkm, z, p_codusu, Sysdate, i.vlrtotal, i.vlrtotal, t(z), c.codparc,
           c.codcencus, c.codnat, c.codproj,
           'Ref. Reembolso de KM nº ' || c.nureemb || ', de ' || ad_get.Nome_Parceiro(c.codparc, 'completo') || ' (' ||
            i.totalkm || ' Km)');
      Exception
        When dup_val_on_index Then
          Null;
        When Others Then
          p_mensagem := 'Erro na geração das liberações. <br> ' || Sqlerrm;
          Return;
      End;
    End Loop;
  
    Begin
      ad_stp_rkm_inslibkm_sf(c.nureemb);
    Exception
      When Others Then
        p_mensagem := 'Erro ao inserir a liberação do transporte.<br>' || Sqlerrm;
        Return;
    End;
  
    -- atualiza status na origem
    Begin
      Update ad_tsfrkmc
         Set status      = 'PL', --pendente de liberação CR
             CODUSULIBCR = t(1)
       Where nureemb = c.nureemb;
    Exception
      When Others Then
        p_mensagem := 'Ocorreu um erro ao atualizar o status do reembolso. <br>' || Sqlerrm;
        Return;
    End;
  
  End Loop;

  p_mensagem := 'Reembolso enviado para liberação do usuário ' || ad_get.Nomeusu(t(1), 'completo') || ' com sucesso!';

End;
/
