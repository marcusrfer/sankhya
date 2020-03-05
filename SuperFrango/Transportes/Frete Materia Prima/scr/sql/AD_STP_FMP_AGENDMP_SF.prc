CREATE OR REPLACE Procedure "AD_STP_FMP_AGENDMP_SF"(P_CODUSU    Number,
                                                    P_IDSESSAO  Varchar2,
                                                    P_QTDLINHAS Number,
                                                    P_MENSAGEM  Out Varchar2) As

  agd         ad_tcsamp%Rowtype;
  ite         ad_itecargto%Rowtype;
  car         ad_contcargto%Rowtype;
  con         tcscon%Rowtype;
  x           Int;
	v_Todos     Varchar(1);
  v_SomaQtd   Float := 0;
  debugando   Boolean Default False;

  Type tipo_tcsamp Is Table Of ad_tcsamp%Rowtype;
  t tipo_tcsamp := tipo_tcsamp();
  
  Function qtd_contrato(p_numcontrato Number) Return Float Is
    v_result Float;
  Begin
    Select p.qtdeprevista
    Into v_result 
    From tcscon c
    Join tcspsc p On c.numcontrato = p.numcontrato
    Where c.numcontrato = p_numcontrato;
    
    Return v_result ;
  Exception
    When Others Then
      Return 0;
  End;
  
  Function qtd_agend(p_numcontrato Number, p_nroagend Number) Return Float Is
   v_result Float;
  Begin
   Select a.qtdneg Into v_result
    From ad_tcsamp a
   Where a.numcontrato = p_numcontrato
    And a.nuagend = p_nroagend;
    
    Return v_result;
    
    Exception
      When Others Then
      Return 0;
  End;
  
Begin

  If debugando Then 
    agd.numcontrato := 3886;
    v_todos := 'N';
  Else 
  agd.numcontrato := ACT_INT_FIELD(P_IDSESSAO, 1, 'NUMCONTRATO');
  v_todos := act_escolher_simnao('Envio para Agendamento', 'Deseja enviar todas as programações pendentes?', P_IDSESSAO, 1);
  End If;
  
  If v_todos = 'N' Then
  
    For i In 1 .. p_qtdlinhas
    Loop
      
      If debugando Then 
       agd.nuagend := 1;
      Else
        agd.nuagend := ACT_INT_FIELD(P_IDSESSAO, i, 'NUAGEND');
      End If;
      
			Begin
        t.extend;
        x := t.last;
        
        Select CODBAI,CODCID,CODEND,CODPROD,COMPLEMENTO,DHPREVRET,LATLONG,NUAGEND,NUMCONTRATO,NUMCONTRCARGTO,
        NUNOTA,QTDNEG, codparcarmz
          Into t(x).CODBAI,t(x).CODCID,t(x).CODEND,t(x).CODPROD,t(x).COMPLEMENTO,t(x).DHPREVRET,t(x).LATLONG,
          t(x).NUAGEND,t(x).NUMCONTRATO,t(x).NUMCONTRCARGTO,t(x).NUNOTA,t(x).QTDNEG, t(x).codparcarmz
          From ad_tcsamp a
         Where numcontrato = agd.numcontrato
           And nuagend = agd.nuagend;
      Exception
        When Others Then
          Raise;
      End;
    
    End Loop;
  
  Else
  -- se todos
  
    Begin
      Select *
        Bulk Collect
        Into t
        From ad_tcsamp
       Where numcontrato = agd.numcontrato
         And numcontrcargto Is Null
         Order By dhprevret;
    Exception
      When Others Then
        Raise;
    End;
  
  End If;

  -- Contrato
  Begin
    Select *
      Into con
      From tcscon
     Where numcontrato = agd.numcontrato;
  Exception
    When Others Then
      Raise;
  End;
  
  -- soma a quantidade 
  For z In t.first .. t.last
    Loop
     v_somaqtd := v_somaQtd + qtd_agend( t(z).numcontrato, t(z).nuagend);
    End Loop;
  
  -- se qtd agendamento > qtd do contrato
  If v_somaqtd > qtd_contrato(agd.numcontrato) Then
   p_mensagem := 'Não foi possível gerar o agendamento. '||Chr(13)||
   'Quantidade agendada ('||Ltrim(ad_get.formatanumero(v_somaqtd))||
   ') é maior que a quantidade do contrato ('||Ltrim(ad_get.formatanumero(qtd_contrato(agd.numcontrato)))||').';
   Return;
  End If;

  For z In t.first .. t.last
  Loop
    
      If Nvl(t(z).codprod,0) = 0 Or Nvl(t(z).qtdneg,0) = 0 Then
        P_MENSAGEM := 'Produto e/ou Quantidade do agendamento precisa ser informada!';
				Return;
      End If;   
  
    stp_keygen_tgfnum('AD_CONTCARGTO', con.codemp, 'AD_CONTCARGTO', 'SEQUENCIA', 0, car.sequencia);
    
    Begin
      Select end.Nomeend||', '||a.complemento||Chr(13)||cid.nomecid ||', '||bai.nomebai  
      Into car.obs
      From ad_tcsamp a 
       Left Join tsicid cid On a.codcid = cid.codcid
       Left Join tsibai bai On a.codbai = bai.codbai
       Left Join tsiend End On a.codend = end.Codend
      Where numcontrato = t(z).numcontrato 
       And nuagend = t(z).nuagend;
    Exception
      When Others Then
        Raise;
      End;
     
  
    -- insere cabeçalho
    Begin
      Insert Into ad_contcargto
        (sequencia, obs, status, codusu, codemp, datahoralanc, dtaprevcarg, podeabastecer,
         lib_descarregar, tipomov, statusvei, analise_avulsa, codveiculo)
      Values
        (car.sequencia, car.obs, 'ABERTO', p_codusu, con.codemp, Sysdate, t(z).dhprevret, 'N',
         'NÃO', 'ENTRADA','AP', 'N', 0);
    Exception
      When Others Then
        Raise;
    End;
  
    -- insere item
    Begin
      Insert Into ad_itecargto
        (sequencia, ordem, codprod, qtde, codparc, codusu, dataalt, vlrfrete, vlrcte, nunota, coddest, numcontrato)
      Values
        (car.sequencia, z, t(z).codprod, t(z).qtdneg, con.codparc, p_codusu, Sysdate, 0, 0,
         con.nunota, t(z).codparcarmz, con.numcontrato);
    Exception
      When Others Then
        Raise;
    End;
  
    -- devolve nro do agendamento
    Begin
      Update ad_tcsamp a
         Set a.numcontrcargto = car.sequencia
       Where a.numcontrato = t(z).numcontrato
         And a.nuagend = t(z).nuagend;
    Exception
      When Others Then
        p_mensagem := 'Erro ao atualizar o número do agendamento! '||Sqlerrm;
				Return;
    End;
		
		p_mensagem := p_mensagem ||', '||car.sequencia;
  
  End Loop;
	
	p_mensagem := 'Foram gerados os agendamentos '||p_mensagem;

End;
/
