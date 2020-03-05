Create Or Replace Procedure "AD_STP_SST_GERACONTR"(P_CODUSU    Number,
                                                   P_IDSESSAO  Varchar2,
                                                   P_QTDLINHAS Number,
                                                   P_MENSAGEM  Out Varchar2) As
  r_Sol         ad_tsfsstc%Rowtype;
  v_NumContrato Number;
  v_Codtiptit   Number;
  errmsg        Varchar2(4000);
  error Exception;
  c              Int := 0;
  v_Qtdneg       Float;
  v_Vlrtot       Float;
  v_NroContratos Varchar2(2000);
  v_QtdContratos Int := 0;
  v_CodApontador Number;
  --t              ad_pkg_sst.ty_origem := ad_pkg_sst.ty_origem();
Begin
  /*****************************************************************************************
  * Autor: Marcus Rangel
  * Processo: Solicitação de Serviços de Transporte
  * Objetivo: Procedure usada com bot?o de ac?o na tela de  "solicitac?o de servicos de transporte".
  * Gerar o contrato a partir das informac?es contidas na solicitac?o.
  ********************************************************************************************/

  For I In 1 .. P_QTDLINHAS
  Loop
    r_Sol.Codsolst := ACT_INT_FIELD(P_IDSESSAO, I, 'CODSOLST');
    v_CodApontador := act_int_param(P_CHAVE => P_IDSESSAO, P_NOME => 'CODRESPAPONT');
  
    Begin
      Select *
        Into r_Sol
        From ad_tsfsstc c
       Where c.codsolst = r_sol.codsolst;
    Exception
      When no_data_found Then
        errmsg := 'Nro da Solicitac?o de Origem n?o foi encontrado.';
        Raise error;
    End;
  
    -- valida status pendente
    If r_sol.status <> 'L' Then
      errmsg := 'Somente lancamento <b><font color="#FF0000">Liberados</FONT></b> podem gerar Contratos. Confirme o lancamento primeiro.';
      Raise error;
    End If;
  
    For c_Itens In (Select i.nussti, i.codserv, i.codparc, Nvl(i.temmed, 'N') temmed
                      From ad_tsfssti i
                     Where i.codsolst = r_sol.codsolst
                       And i.numcontrato Is Null
                     Order By i.codserv)
    Loop
    
      /*se o contrato sera lancado considerando o parceiro da maquina e não do servico*/
      If c_itens.codparc Is Null Then
      
        For c_Maq In (Select Distinct codparc, Nvl(temmed, 'N') temmed
                        From ad_tsfsstm m
                       Where numcontrato Is Null
                         And m.codsolst = r_sol.codsolst
                            --And m.codserv = c_Itens.codserv
                         And m.nussti = c_Itens.Nussti
                         And m.codparc Is Not Null
                       Order By codparc)
        Loop
          /*busca a quantidade e o valor total das maquinas*/
          Begin
            Select Sum(qtdneg), Sum(vlrtot)
              Into v_qtdneg, v_vlrtot
              From ad_tsfsstm m
             Where m.codparc = c_maq.codparc
                  --And m.codserv = c_itens.codserv
               And m.nussti = c_Itens.Nussti
               And m.codsolst = r_sol.codsolst
               And m.temmed = c_maq.temmed;
          End;
        
          If c_maq.temmed = 'S' And v_CodApontador Is Null Then
            p_mensagem := 'Por favor informe o código do Usuário responsável pelo Apontamento';
            Return;
          End If;
        
          /*insere o contrato pela maquina*/
          ad_pkg_sst.Insere_Contrato(p_CodSol => r_sol.codsolst, p_CodParc => c_Maq.codparc,
                                     P_NUSSTI => c_itens.nussti, p_Codserv => c_itens.codserv,
                                     p_Qtdneg => v_Qtdneg, p_Vlrtot => v_Vlrtot,
                                     p_TemMed => c_Maq.Temmed, v_NumContrato => v_NumContrato,
                                     errmsg => errmsg);
          If errmsg Is Not Null Then
            Raise error;
          End If;
        
          -- informa o usuário resp do parametro no contrato
          -- solicit. 28/08/2018, Marçel Eng.
          Begin
            Update tcscon con
               Set con.ad_codusuapont = v_CodApontador
             Where con.numcontrato = v_NumContrato;
          Exception
            When Others Then
              p_mensagem := 'Erro ao atualizar o usuário responsável pelo apontamento no contrato.' ||
                            Chr(13) || Sqlerrm;
              Return;
          End;
        
          /*atualiza o numero do contrato no equipamento*/
          Update ad_tsfsstm m
             Set m.numcontrato = v_NumContrato
           Where codsolst = r_Sol.Codsolst
             And codparc = c_Maq.codparc
                --And codserv = c_itens.codserv
             And nussti = c_Itens.Nussti
             And numcontrato Is Null;
        
          /*Concatena os numeros dos contratos gerados*/
          If v_NroContratos Is Null Then
            v_NroContratos := v_NumContrato;
          Else
            v_NroContratos := v_NroContratos || ',' || v_NumContrato;
          End If;
        
          v_QtdContratos := v_QtdContratos + 1;
        
        End Loop c_Maq;
      
        --Se o contrato sera gerado pelo servico      
      Else
      
        Begin
          /*Busca quantidade e valor, totais, do servicos*/
          Select Sum(qtdneg), Sum(vlrtot)
            Into v_qtdneg, v_vlrtot
            From ad_tsfssti i
           Where i.codparc = c_Itens.codparc
             And i.codserv = c_Itens.codserv
             And i.codsolst = r_sol.codsolst
             And i.nussti = c_Itens.Nussti
             And i.temmed = c_Itens.Temmed;
        End;
      
        If c_itens.temmed = 'S' And v_CodApontador Is Null Then
          p_mensagem := 'Por favor informe o código do Usuário responsável pelo Apontamento';
          Return;
        End If;
      
        /*Insere o contrato baseado no servico*/
        ad_pkg_sst.Insere_Contrato(p_CodSol => r_Sol.Codsolst, p_CodParc => c_Itens.codparc,
                                   p_nussti => c_itens.nussti, p_Codserv => c_Itens.codserv,
                                   p_Qtdneg => v_Qtdneg, p_Vlrtot => v_Vlrtot,
                                   p_temmed => c_Itens.temmed, v_NumContrato => v_NumContrato,
                                   errmsg => errmsg);
      
        If errmsg Is Not Null Then
          Raise error;
        End If;
      
        -- informa o usuário resp do parametro no contrato
        -- solicit. 28/08/2018, Marçel Eng.
        Begin
          Update tcscon con
             Set con.ad_codusuapont = v_CodApontador
           Where con.numcontrato = v_NumContrato;
        Exception
          When Others Then
            p_mensagem := 'Erro ao atualizar o usuário responsável pelo apontamento no contrato.' ||
                          Chr(13) || Sqlerrm;
            Return;
        End;
      
        /*Atualiza o numero do contrato no servico*/
        Update ad_tsfssti
           Set numcontrato = v_NumContrato
         Where codsolst = r_Sol.Codsolst
           And nussti = c_Itens.Nussti
           And codparc = c_itens.codparc
           And codserv = c_Itens.codserv
           And numcontrato Is Null;
      
        /*Concatena o numero dos contratos*/
        If v_NroContratos Is Null Then
          v_NroContratos := v_NumContrato;
        Else
          v_NroContratos := v_NroContratos || ',' || v_NumContrato;
        End If;
      
        v_QtdContratos := v_QtdContratos + 1;
      
      End If;
    
      /*Busca o tipo de titulo do parametro e atualiza os contratos*/
      Begin
        Select tiptitcontr
          Into v_codtiptit
          From ad_tsfelt elt
         Where elt.nuelt = 1;
      
        Update tcscon con
           Set con.tipotitulo   = v_Codtiptit,
               con.dttermino    = r_sol.dtfim,
               con.dtrefproxfat = Add_Months(Trunc(Sysdate, 'mm'), 1),
               con.parcelaqtd = (Case
                                  When c_Itens.temmed = 'N' Then
                                   v_Qtdneg
                                End)
         Where numcontrato = v_NumContrato;
      
      Exception
        When Others Then
          errmsg := 'Erro ao atualizar informac?es adicionais no contrato ' || v_NumContrato ||
                    ' - ' || Sqlerrm;
          Raise error;
      End;
    
    End Loop S;
  
  End Loop I;

  If v_QtdContratos = 1 Then
    P_MENSAGEM := 'Foi gerado o contrato nro ' ||
                  '<font color="#0000FF"><b><a target="_parent" href="' ||
                  ad_fnc_urlskw('TCSCON_AD', v_NumContrato) || '" >' || v_numcontrato ||
                  '</b></font>';
  
  Else
    If v_NroContratos Is Null Then
      p_mensagem := 'Não foram encontradas máquinas/serviços disponíveis para geração de contratos';
    Else
      p_mensagem := 'Foram gerados os contratos ' || v_NroContratos;
    End If;
  End If;

Exception
  When error Then
    Rollback;
    P_MENSAGEM := errmsg;
  When Others Then
    Rollback;
    P_MENSAGEM := Sqlerrm;
End;
/
