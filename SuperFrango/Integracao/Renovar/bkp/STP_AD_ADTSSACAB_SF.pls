CREATE OR REPLACE PROCEDURE "STP_AD_ADTSSACAB_SF" (p_Tipoevento Int, -- Identifica o tipo de evento
                                                p_Idsessao   Varchar2, -- Identificador da execução. Serve para buscar informações dos campos da execução.
                                                p_Codusu     Int -- Código do usuário logado
                                                ) As
   Before_Insert Int;
   After_Insert  Int;
   --Before_Delete Int;
   --After_Delete  Int;
   Before_Update Int;
   After_Update  Int;
   --Before_Commit Int;

   r_Cab           Ad_Adtssacab%Rowtype;
   r_Conf          Ad_Adtssaconf%Rowtype;
   v_Codparcmatriz Number;
   v_Count         Number;
   v_Descrnat      Varchar2(50);
   v_Nomeparc      Varchar2(50);
   v_Tipoparcadt   Varchar(30);
   v_Vlrdesdob     Float;
Begin
   Before_Insert := 0;
   After_Insert  := 1;
   --Before_Delete := 2;
   --After_Delete  := 3;
   Before_Update := 4;
   After_Update  := 5;
   --Before_Commit := 10;

   /*******************************************************************************
      É possível obter o valor dos campos através das Functions:
      
     EVP_GET_CAMPO_DTA(P_IDSESSAO, 'NOMECAMPO') -- PARA CAMPOS DE DATA
     EVP_GET_CAMPO_INT(P_IDSESSAO, 'NOMECAMPO') -- PARA CAMPOS NUMÉRICOS INTEIROS
     EVP_GET_CAMPO_DEC(P_IDSESSAO, 'NOMECAMPO') -- PARA CAMPOS NUMÉRICOS DECIMAIS
     EVP_GET_CAMPO_TEXTO(P_IDSESSAO, 'NOMECAMPO')   -- PARA CAMPOS TEXTO
     
     O primeiro argumento é uma chave para esta execução. O segundo é o nome do campo.
     
     Para os eventos BEFORE UPDATE, BEFORE INSERT e AFTER DELETE todos os campos estarão disponíveis.
     Para os demais, somente os campos que pertencem à PK
     
     * Os campos CLOB/TEXT serão enviados convertidos para VARCHAR(4000)
     
     Também é possível alterar o valor de um campo através das Stored procedures:
     
     EVP_SET_CAMPO_DTA(P_IDSESSAO,  'NOMECAMPO', VALOR) -- VALOR DEVE SER UMA DATA
     EVP_SET_CAMPO_INT(P_IDSESSAO,  'NOMECAMPO', VALOR) -- VALOR DEVE SER UM NÚMERO INTEIRO
     EVP_SET_CAMPO_DEC(P_IDSESSAO,  'NOMECAMPO', VALOR) -- VALOR DEVE SER UM NÚMERO DECIMAL
     EVP_SET_CAMPO_TEXTO(P_IDSESSAO,  'NOMECAMPO', VALOR) -- VALOR DEVE SER UM TEXTO
   ********************************************************************************/

   -- Inicio de Validações antes de incluir
   If p_Tipoevento = Before_Insert Then
   
      Evp_Set_Campo_Texto(p_Idsessao, 'SITUACAO', 'E');
      Evp_Set_Campo_Int(p_Idsessao, 'CODUSUINC', p_Codusu);
      Evp_Set_Campo_Dta(p_Idsessao, 'DHINC', Sysdate);
   
      r_Cab.Codcencusresp := Evp_Get_Campo_Int(p_Idsessao, 'CODCENCUSRESP');
      r_Cab.Codnat        := Evp_Get_Campo_Int(p_Idsessao, 'CODNAT');
      r_Cab.Codparc       := Evp_Get_Campo_Int(p_Idsessao, 'CODPARC');
      r_Cab.Codparcrec    := Evp_Get_Campo_Int(p_Idsessao, 'CODPARCREC');
      r_Cab.Codproj       := Evp_Get_Campo_Int(p_Idsessao, 'CODPROJ');
      r_Cab.Dtneg         := Evp_Get_Campo_Dta(p_Idsessao, 'DTNEG');
      r_Cab.Dtvenc        := Evp_Get_Campo_Dta(p_Idsessao, 'DTVENC');
      r_Cab.Dtvenc1       := Evp_Get_Campo_Dta(p_Idsessao, 'DTVENC1');
      r_Cab.Forma         := Evp_Get_Campo_Texto(p_Idsessao, 'FORMA');
      r_Cab.Nrparcelas    := Evp_Get_Campo_Int(p_Idsessao, 'NRPARCELAS');
      r_Cab.Tipo          := Evp_Get_Campo_Int(p_Idsessao, 'TIPO');
      r_Cab.Vlrdesdob     := Evp_Get_Campo_Dec(p_Idsessao, 'VLRDESDOB');
   
      Select Count(*)
        Into v_Count
        From Ad_Adtssaconfusu u
       Where u.Codusu = p_Codusu
         And u.Codigo = Evp_Get_Campo_Int(p_Idsessao, 'TIPO');
   
      If v_Count = 0 Then
         Raise_Application_Error(-20101,
                                 Fc_Formatahtml_Sf('Cancelando Inclusão',
                                                    'Usuário logado não tem permissão para incluir esse tipo de adiantamento!',
                                                    Null));
      
      End If;
   
      Select Nvl(c.Permparcdif, 'N'), Nvl(c.Seacumular, 'B'), Nvl(c.Forma, 'C'), Nvl(c.Exigaprdesp, 'S')
        Into r_Conf.Permparcdif, r_Conf.Seacumular, r_Conf.Forma, r_Conf.Exigaprdesp
        From Ad_Adtssaconf c
       Where c.Codigo = r_Cab.Tipo;
   
      -- Só é permitido parceiro de despesa diferente do parceiro da receita se o processo de adiantamento estiver configurado para tal.
      If r_Cab.Codparc <> Nvl(r_Cab.Codparcrec, r_Cab.Codparc) And r_Conf.Permparcdif = 'N' Then
         Raise_Application_Error(-20101,
                                 Fc_Formatahtml_Sf('Inclusão Cancelada',
                                                    'Tipo de Processo selecionado não permite que o parceiro da receita seja diferente do parceiro da despesa',
                                                    Null));
      End If;
   
      If r_Cab.Forma <> '4' And r_Conf.Forma = 'C' Then
         Raise_Application_Error(-20101,
                                 Fc_Formatahtml_Sf('Inclusão Cancelada',
                                                    'Tipo de Processo selecionado só permite selecionar a forma "Compensação"',
                                                    Null));
      
      End If;
   
      If r_Conf.Seacumular = 'B' Then
      
         Select Count(*)
           Into v_Count
           From Ad_Centparampar p
          Where p.Codparc = r_Cab.Codparc
            And p.Nupar = 9;
      
         If v_Count = 0 Then
            -- Se o parceiro esta na lista de exceções é porque pode lançar mais de um adiantamento para ele
            v_Codparcmatriz := Ad_Analise_Credito.Codparcmatriz(p_Codparc => r_Cab.Codparc);
         
            Begin
               Select Sum(Vlrdesdob)
                 Into v_Vlrdesdob
                 From Tgffin f, Tgfpar p
                Where f.Codparc = p.Codparc
                  And p.Codparcmatriz = v_Codparcmatriz
                  And f.Recdesp = 1
                  And f.Provisao = 'N'
                  And f.Dhbaixa Is Null;
            Exception
               When No_Data_Found Then
                  v_Vlrdesdob := 0;
            End;
         
            If v_Vlrdesdob > 0 Then
               Raise_Application_Error(-20101,
                                       Fc_Formatahtml_Sf('Inclusão Cancelada',
                                                          'Existem valores pendentes para esse parceiro, não é permitido lançar um segundo adiantamento',
                                                          Null));
            End If;
         
         End If;
      End If;
   
      -- Valida se data de negociação é inferior a data atual
      If r_Cab.Dtneg < Trunc(Sysdate) - 5 And r_Cab.Tipo Not In (15) 
				--15 - Clientes - Adiantamento de Vendas, Se o tipo for 15 pode acontecer fora do prazo, vai barrar apenas no DATAFECHA, que já é padrão do sistema.
       Then
         Raise_Application_Error(-20101,
                                 Fc_Formatahtml_Sf('Inclusão Cancelada',
                                                    'Data Negociação não pode ser inferior a ' ||
                                                     To_Date(Trunc(Sysdate) - 5, 'DD/MM/YYYY'), Null));
      End If;
   
      -- Valida se data de negociação é muito superior a data atual
      If r_Cab.Dtneg > Trunc(Sysdate) + 30
       Then
         Raise_Application_Error(-20101,
                                 Fc_Formatahtml_Sf('Inclusão Cancelada',
                                                    'Data Negociação não pode ser superior a ' ||
                                                     To_Date(Trunc(Sysdate) + 30, 'DD/MM/YYYY'), Null));
      End If;
      -- Data de vencimento não pode ser programada para final de semana e feriados
      If Ad_Get.Dia_Util(p_Data => r_Cab.Dtvenc) > 0 Or Ad_Get.Dia_Util(p_Data => r_Cab.Dtvenc1) > 0 Then
         Raise_Application_Error(-20101,
                                 Fc_Formatahtml_Sf('Inclusão Cancelada',
                                                    'Vencimento não pode ser programado para finais de semana e feriados!!',
                                                    Null));
      
      End If;
   
      If r_Cab.Dtvenc1 < r_Cab.Dtvenc Then
         Raise_Application_Error(-20101,
                                 Fc_Formatahtml_Sf('Cancelando Alterações',
                                                    'Data Vencimento da Primeira Parcela não pode ser inferior a Data de Vencimento da Despesa',
                                                    Null));
      End If;
   
      -- Valor não pode ser menor que zero
      If r_Cab.Vlrdesdob <= 0 Then
         Raise_Application_Error(-20101, Fc_Formatahtml_Sf('Valor deve ser maior que zero', Null, Null));
      End If;
   
      -- Valida número de parcelas
      If r_Cab.Nrparcelas <= 0 Or r_Cab.Nrparcelas > 360 Then
         Raise_Application_Error(-20101, Fc_Formatahtml_Sf('Número de Parcelas inválido', Null, Null));
      End If;
   
      -- Valida o CR
      /*If Nvl(r_Cab.Codcencusresp, 0) = 0 Then
         Raise_Application_Error(-20101, Fc_Formatahtml_Sf('Obrigatório informar CR Aprovador', Null, Null));
      
      Else*/
      If Nvl(r_Cab.Codcencusresp, 0) > 0 Then
         Select Count(*)
           Into v_Count
           From Tsicus c
          Where c.Codcencus = r_Cab.Codcencusresp
            And c.Analitico = 'S'
            And Exists (Select 1
                   From Ad_Itesolcpalibcr Cr
                  Where c.Codcencus = Cr.Codcencus
                    And Nvl(Cr.Aprova, 'N') = 'S');
      
         If v_Count = 0 Then
            Raise_Application_Error(-20101,
                                    Fc_Formatahtml_Sf('CR Aprovador informado não está ativo ou não é analítico ou não tem aprovador vinculado!',
                                                       Null, Null));
         End If;
      
      End If;
   
      -- Valida se a natureza ou o centro de resultado exige projeto
   
      Select Count(*)
        Into v_Count
        From Ad_Adtssaconfnat c
       Where c.Codnat = r_Cab.Codnat
         And Nvl(c.Exigeprojeto, 'N') = 'S'
         And c.Codigo = r_Cab.Tipo;
   
      If v_Count > 0 And r_Cab.Codproj = 0 Then
         Raise_Application_Error(-20101, Fc_Formatahtml_Sf('Natureza exige que seja informado projeto', Null, Null));
      End If;
   
      If r_Cab.Codproj > 0 Then
         Select Count(*)
           Into v_Count
           From Tcsprj p
          Where p.Codproj = r_Cab.Codproj
            And p.Analitico = 'S';
      
         If v_Count = 0 Then
            Raise_Application_Error(-20101,
                                    Fc_Formatahtml_Sf('Projeto informado não está ativo ou não é analítico!', Null, Null));
         End If;
      
      End If;
   
      Select Nvl(p.Ad_Tipadt, 'Não Informado')
        Into v_Tipoparcadt
        From Tgfpar p
       Where p.Codparc = Ad_Analise_Credito.Codparcmatriz(p_Codparc => Nvl(r_Cab.Codparcrec, r_Cab.Codparc));
   
      If v_Tipoparcadt = 'Não Informado' Then
         Raise_Application_Error(-20101,
                                 Fc_Formatahtml_Sf('Ação Cancelada',
                                                    'O processo de adiantamento exige que o campo "Tipo de Parceiro Adto" do cadastro do parceiro seja informado',
                                                    'Corrija ou solicite ao responsável pelo cadastro que efetue a correção no parceiro ' ||
                                                     Ad_Analise_Credito.Codparcmatriz(p_Codparc => r_Cab.Codparc)));
      
      End If;
   
      If r_Cab.Codnat In (9053900, 9054000, 9054200, 9054300) Then
         --Raise_Application_Error(-20101, 'erro');
         Select Descrnat Into v_Descrnat From Tgfnat n Where n.Codnat = r_Cab.Codnat;
         Select Nomeparc Into v_Nomeparc From Tgfpar p Where p.Codparc = r_Cab.Codparc;
      
         Evp_Set_Campo_Texto(p_Idsessao, 'HISTORICO', v_Descrnat || ' - ' || v_Nomeparc);
      End If;
   
   End If;
   -- Fim de validações antes de incluir

   -- Inicio das ações após inserir
   If p_Tipoevento = After_Insert Then
      Insert Into Ad_Adtssalgtt
         (Nunico, Dhalter, Acao, Codusu)
      Values
         (Evp_Get_Campo_Int(p_Idsessao, 'NUNICO'), Sysdate, 'Inclusão', p_Codusu);
   End If;
   -- Fim das ações após inserir

   -- Inicio das ações antes de alterar
   If p_Tipoevento = Before_Update Then
      -- Obtem valores antigos
      Select c.* Into r_Cab From Ad_Adtssacab c Where c.Nunico = Evp_Get_Campo_Int(p_Idsessao, 'NUNICO');
   
      -- Não é permitido efetuar alterações se o adiantamento não esta em elaboração. O usuário deve desfazer e reiniciar o processo
      If r_Cab.Situacao <> 'E' Then
         Raise_Application_Error(-20101,
                                 Fc_Formatahtml_Sf('Cancelando Alterações',
                                                    'Alteração não permitida pois Situação diferente de <i>Elaborando</i>',
                                                    Null));
      
      End If;
   
      Select Nvl(c.Permparcdif, 'N'), Nvl(c.Seacumular, 'B'), Nvl(c.Forma, 'C')
        Into r_Conf.Permparcdif, r_Conf.Seacumular, r_Conf.Forma
        From Ad_Adtssaconf c
       Where c.Codigo = Evp_Get_Campo_Int(p_Idsessao, 'TIPO');
   
      If Evp_Get_Campo_Texto(p_Idsessao, 'FORMA') <> '4' And r_Conf.Forma = 'C' Then
         Raise_Application_Error(-20101,
                                 Fc_Formatahtml_Sf('Alteração Cancelada',
                                                    'Tipo de Processo selecionado só permite selecionar a forma "Compensação"',
                                                    Null));
      
      End If;
   
      Select Count(*)
        Into v_Count
        From Ad_Adtssaconfusu u
       Where u.Codusu = p_Codusu
         And u.Codigo = Evp_Get_Campo_Int(p_Idsessao, 'TIPO');
   
      If v_Count = 0 Then
         Raise_Application_Error(-20101,
                                 Fc_Formatahtml_Sf('Cancelando Alterações',
                                                    'Usuário logado não tem permissão para editar esse tipo de adiantamento!',
                                                    Null));
      
      End If;
   
      -- Se alterar valor, número de parcelas ou algum dos vencimentos deve gerar novamente as parcelas
      If r_Cab.Vlrdesdob <> Evp_Get_Campo_Dec(p_Idsessao, 'VLRDESDOB') Or
         r_Cab.Nrparcelas <> Evp_Get_Campo_Int(p_Idsessao, 'NRPARCELAS') Or
         r_Cab.Dtvenc <> Evp_Get_Campo_Dta(p_Idsessao, 'DTVENC') Or
         r_Cab.Dtvenc1 <> Evp_Get_Campo_Dta(p_Idsessao, 'DTVENC1') Or
         r_Cab.Tipo <> Evp_Get_Campo_Int(p_Idsessao, 'TIPO') Or
         Nvl(r_Cab.Taxa, 0) <> Nvl(Evp_Get_Campo_Dec(p_Idsessao, 'TAXA'), 0) Then
      
         Delete From Ad_Adtssapar Where Nunico = Evp_Get_Campo_Int(p_Idsessao, 'NUNICO');
      
         Evp_Set_Campo_Int(p_Idsessao, 'CODUSUFIN', Null);
         Evp_Set_Campo_Int(p_Idsessao, 'CODUSUAPR', Null);
         Evp_Set_Campo_Dta(p_Idsessao, 'DHAPROVADT', Null);
         Evp_Set_Campo_Dta(p_Idsessao, 'DHAPROVFIN', Null);
         Evp_Set_Campo_Dta(p_Idsessao, 'DHSOLICITACAO', Null);
      
      End If;
   
      Select Nvl(p.Ad_Tipadt, 'Não Informado')
        Into v_Tipoparcadt
        From Tgfpar p
       Where p.Codparc = Ad_Analise_Credito.Codparcmatriz(p_Codparc => Evp_Get_Campo_Int(p_Idsessao, 'CODPARC'));
   
      If v_Tipoparcadt = 'Não Informado' Then
         Raise_Application_Error(-20101,
                                 Fc_Formatahtml_Sf('Ação Cancelada',
                                                    'O processo de adiantamento exige que o campo "Tipo de Parceiro Adto" do cadastro do parceiro seja informado',
                                                    'Corrija ou solicite ao responsável pelo cadastro que efetue a correção no parceiro ' ||
                                                     Ad_Analise_Credito.Codparcmatriz(p_Codparc => r_Cab.Codparc)));
      
      End If;
   
      If r_Cab.Codparc <> Evp_Get_Campo_Int(p_Idsessao, 'CODPARC') Then
         -- Verifica se o processo escolhido permite acumular mais de um adiantamento em aberto               
      
         If r_Conf.Seacumular = 'B' Then
         
            Select Count(*)
              Into v_Count
              From Ad_Centparampar p
             Where p.Codparc = Evp_Get_Campo_Int(p_Idsessao, 'CODPARC')
               And p.Nupar = 9;
         
            If v_Count = 0 Then
               -- Se o parceiro esta na lista de exceções é porque pode lançar mais de um adiantamento para ele
               v_Codparcmatriz := Ad_Analise_Credito.Codparcmatriz(p_Codparc => Evp_Get_Campo_Int(p_Idsessao, 'CODPARC'));
            
               Begin
                  Select Sum(Vlrdesdob)
                    Into v_Vlrdesdob
                    From Tgffin f, Tgfpar p
                   Where f.Codparc = p.Codparc
                     And p.Codparcmatriz = v_Codparcmatriz
                     And f.Recdesp = 1
                     And f.Provisao = 'N'
                     And f.Dhbaixa Is Null;
               Exception
                  When No_Data_Found Then
                     v_Vlrdesdob := 0;
               End;
            
               If v_Vlrdesdob > 0 Then
                  Raise_Application_Error(-20101,
                                          Fc_Formatahtml_Sf('Inclusão Cancelada',
                                                             'Existem valores pendentes para esse parceiro, não é permitido lançar um segundo adiantamento',
                                                             Null));
               End If;
            
            End If;
         End If;
      
      End If;
   
      -- Valida o CR
      --If r_Cab.Codcencusresp <> Evp_Get_Campo_Int(p_Idsessao, 'CODCENCUSRESP') Then
      /*If Nvl(r_Cab.Codcencusresp, 0) = 0 Then
         Raise_Application_Error(-20101, Fc_Formatahtml_Sf('Obrigatório informar CR Aprovador', Null, Null));
      
      Else*/
      If Evp_Get_Campo_Int(p_Idsessao, 'CODCENCUSRESP') > 0 Then
         Select Count(*)
           Into v_Count
           From Tsicus c
          Where c.Codcencus = Evp_Get_Campo_Int(p_Idsessao, 'CODCENCUSRESP')
            And c.Analitico = 'S'
            And Exists (Select 1
                   From Ad_Itesolcpalibcr Cr
                  Where c.Codcencus = Cr.Codcencus
                    And Nvl(Cr.Aprova, 'N') = 'S');
      
         If v_Count = 0 Then
            Raise_Application_Error(-20101,
                                    Fc_Formatahtml_Sf('CR Aprovador informado não está ativo ou não é analítico ou não tem aprovador vinculado!',
                                                       Null, Null));
         End If;
      
      End If;
   
      --End If;
   
   End If;
   -- Fim das ações Before_Update

   -- Inicio das ações depois de alterar
   If p_Tipoevento = After_Update Then
   
      Select c.* Into r_Cab From Ad_Adtssacab c Where c.Nunico = Evp_Get_Campo_Int(p_Idsessao, 'NUNICO');
   
      -- Só é permitido parceiro de despesa diferente do parceiro da receita se o processo de adiantamento estiver configurado para tal.
      If r_Cab.Codparc <> Nvl(r_Cab.Codparcrec, r_Cab.Codparc) Then
      
         Select Count(*)
           Into v_Count
           From Ad_Adtssaconf c
          Where c.Codigo = r_Cab.Tipo
            And Nvl(c.Permparcdif, 'N') = 'N';
      
         If v_Count > 0 Then
            Raise_Application_Error(-20101,
                                    Fc_Formatahtml_Sf('Inclusão Cancelada',
                                                       'Tipo de Processo selecionado não permite que o parceiro da receita seja diferente do parceiro da despesa',
                                                       Null));
         End If;
      End If;
   
      -- Valida inclusão das datas
      -- Data de vencimento não pode ser programada para final de semana e feriados
      If Ad_Get.Dia_Util(p_Data => r_Cab.Dtvenc) > 0 Or Ad_Get.Dia_Util(p_Data => r_Cab.Dtvenc1) > 0 Then
         Raise_Application_Error(-20101,
                                 Fc_Formatahtml_Sf('Inclusão Cancelada',
                                                    'Vencimento não pode ser programado para finais de semana e feriados!',
                                                    Null));
      
      End If;
   
      If r_Cab.Dtvenc1 < r_Cab.Dtvenc Then
         Raise_Application_Error(-20101,
                                 Fc_Formatahtml_Sf('Cancelando Alterações',
                                                    'Data Vencimento da Primeira Parcela não pode ser inferior a Data de Vencimento da Despesa',
                                                    Null));
      End If;
   
      If r_Cab.Vlrdesdob <= 0 Then
         Raise_Application_Error(-20101, Fc_Formatahtml_Sf('Cancelando Alterações', 'Valor Inválido!', Null));
      End If;
   
      If r_Cab.Nrparcelas < 1 Or r_Cab.Nrparcelas > 360 Then
         Raise_Application_Error(-20101, Fc_Formatahtml_Sf('Cancelando Alterações', 'Nr. de Parcelas inválido!', Null));
      
      End If;
   
   End If;
   -- Fim das ações After_Update

End;
/
