Create Or Replace Procedure "AD_STP_DEF_ENVIARECAPRV"(P_CODUSU    Number,
                                                      P_IDSESSAO  Varchar2,
                                                      P_QTDLINHAS Number,
                                                      P_MENSAGEM  Out Varchar2) As
  v_Nudef     Number;
  v_valorOC   Float;
  r_Def       ad_tsfdef%Rowtype;
  v_percRep   Float;
  v_valorLib  Float;
  v_Count     Int := 0;
  v_Sequencia Int := 0;
  v_CodUSuLog Number := stp_get_codusulogado();
  v_CodUsuLib Int;
Begin
  /*
   Dt. criação: 27/09/2016
   Autor: Marcus Rangel
   Processo: Despesas Extras de Frete
   Objetivo: Inserir a solicitação de liberação para as despesas extras de frete.
   Realizar o rateio considerando os centros de resultados ou da ordem de carga ou do recibo
  */

  For I In 1 .. P_QTDLINHAS
  Loop
    v_Nudef := Nvl(ACT_INT_FIELD(P_IDSESSAO, I, 'NUDEF'), 15);
  
    Select *
      Into r_Def
      From ad_tsfdef d
     Where d.nudef = v_Nudef;
  
    -- valor total da ordem de carga
    Begin
      Select Sum(vlrnota)
        Into v_valorOC
        From tgfcab
       Where ordemcarga = r_def.ordemcarga;
    Exception
      When Others Then
        P_MENSAGEM := 'Não foi possível buscar o total da ordem de carga. <br>' || Sqlerrm;
        Return;
    End;
  
    -- verifica os recibos para identificar se o rateio será manual ou automatico pela OC
    For c_Rec In (Select *
                    From ad_tsfdefr
                   Where nudef = v_Nudef)
    Loop
      If c_rec.rateio_oc = 'S' Then
        -- Cursor por usuário responsável pelo centro de resultado.
        For c_lib In (
                      
                      --Select u.codusuresp, Sum(c.vlrnota) valor
                      Select l.codusu codusuresp, Sum(c.vlrnota) valor
                        From tgfcab c
                        Join tsicus u
                          On c.codcencus = u.codcencus
                        Left Join ad_itesolcpalibcr l
                          On c.codcencus = l.codcencus
                       Where c.ordemcarga = r_Def.Ordemcarga
                         And Nvl(l.aprova, 'N') = 'S'
                       Group By l.codusu
                      
                      )
        Loop
          v_sequencia := v_Sequencia + 1;
        
          -- % de participação pelo valor no total da OC
          v_percRep := (c_lib.valor / v_valorOC);
        
          -- total de recibos lançados
        
          /*          comentado para a buscar o valor individual do recibo
          Begin
                      Select Sum(r.vlrdesdob) Into v_totalRec From ad_tsfdefr r Where r.nudef = v_Nudef;
                    Exception
                      When no_data_found Then
                        Errmsg := 'Não foram encontrados recibos com valores para o envio para liberação.';
                        Raise error;
                    End;*/
        
          v_valorLib := Round(c_rec.vlrdesdob * v_percRep, 4);
        
          /* comentado para tratar o rateio pelo cr manual e da oc
          verifica se já existe solicitação de liberação
          Begin
            Select Count(*)
              Into v_Count
              From tsilib l
             Where nuchave = v_nudef
               And tabela = 'AD_TSFDEF'
               And l.codusulib = c_lib.codusuresp
               And sequencia = v_sequencia;
            If v_count <> 0 Then
              Errmsg := 'Solicitação de liberação já existe. Desfaça a solicitação ou entre em contato com o liberador.';
              Raise error;
            End If;
          End;*/
        
          -- insere registro na tsilib
          Begin
            v_count := 0;
          
            Select Count(*)
              Into v_Count
              From tsilib l
             Where l.nuchave = v_nudef
               And l.tabela = 'AD_TSFDEF'
               And l.codusulib = c_lib.codusuresp
            --And l.codususolicit = v_CodUSuLog            
            --And l.dhlib Is Null
            ;
          
            If v_count = 0 Then
              ad_set.ins_liberacao(p_tabela => 'AD_TSFDEF', p_nuchave => v_Nudef, p_evento => r_def.nuevento,
                                   p_valor => v_valorLib, p_codusulib => c_lib.codusuresp,
                                   p_obslib => 'Ref. despesas OC ' || r_def.ordemcarga, p_errmsg => P_MENSAGEM);
              If p_mensagem Is Not Null Then
                Return;
              End If;
            
            Else
              Begin
                Update tsilib l
                   Set l.vlratual      = l.vlratual + v_valorLib,
                       l.dhlib         = Null,
                       l.reprovado     = 'N',
                       l.codususolicit = v_CodUSuLog
                 Where l.nuchave = v_nudef
                   And l.tabela = 'AD_TSFDEF'
                   And l.codusulib = c_lib.codusuresp;
              Exception
                When Others Then
                  P_MENSAGEM := 'Não foi possível atualizar os valores na liberação. <br>' || Sqlerrm;
                  Return;
              End;
            
            End If;
          End;
        
        End Loop; -- loop c_lib
      Else
        -- RATEIO_OC = N (se utiliza o rateio manual)
      
        Begin
          Select l.codusu
            Into v_CodUsuLib
            From tsicus c
            Join ad_itesolcpalibcr l
              On c.codcencus = l.codcencus
            Join tsiusu u
              On u.codusu = l.codusu
           Where C.Codcencus = c_rec.codcencus
             And Nvl(l.ativo, 'N') = 'SIM'
             And Nvl(l.aprova, 'N') = 'S'
                --And l.vlrfinal >= c_rec.vlrdesdob
             And Nvl(u.dtlimacesso, Sysdate + 100) >= Sysdate;
        Exception
          When no_data_found Then
            P_MENSAGEM := 'Não foi encontrado o liberador para o centro de resultados ' || c_rec.codcencus ||
                          'Por favor verifique o cadastro de alçadas de liberadores por C.R.';
            Return;
        End;
      
        Begin
          v_sequencia := v_Sequencia + 1;
          v_count     := 0;
        
          Select Count(*)
            Into v_Count
            From tsilib l
           Where l.nuchave = c_rec.nudef
             And l.tabela = 'AD_TSFDEF'
             And l.codusulib = v_CodUsuLib
          --And l.codususolicit = v_CodUSuLog
          --And l.dhlib Is Null
          ;
        
          If v_count = 0 Then
          
            ad_set.ins_liberacao(p_tabela => 'AD_TSFDEF', p_nuchave => v_nudef, p_evento => r_def.nuevento,
                                 p_valor => c_rec.vlrdesdob, p_codusulib => v_CodUsuLib,
                                 p_obslib => 'Ref. despesas extras de frete OC Nº ' || r_def.ordemcarga,
                                 p_errmsg => P_MENSAGEM);
            If p_mensagem Is Not Null Then
              Return;
            End If;
          
          Else
          
            Update tsilib l
               Set l.vlratual      = l.vlratual + c_rec.vlrdesdob,
                   l.codususolicit = v_CodUSuLog,
                   l.dhlib         = Null,
                   l.reprovado     = 'N'
             Where l.nuchave = c_rec.nudef
               And l.tabela = 'AD_TSFDEF'
               And l.codusulib = v_CodUsuLib
            --And l.codususolicit = v_CodUSuLog            
            --And l.dhlib Is Null
            ;
          
          End If;
        Exception
          When Others Then
            p_mensagem := 'Erro ao inserir solicitação de liberação pendente. (CR Manual)' || Sqlerrm;
            Return;
        End;
      End If;
    End Loop; -- c_rec
  
    v_Sequencia := 0;
    P_MENSAGEM  := 'Despesas enviadas para aprovação com sucesso!';
  
    Begin
      Update ad_tsfdef d
         Set d.status = 'AL'
       Where nudef = v_nudef;
    Exception
      When Others Then
        p_mensagem := 'Não foi possível atualizar o status. ' || Sqlerrm;
        Return;
    End;
  
  End Loop; -- loop I

End;
/
