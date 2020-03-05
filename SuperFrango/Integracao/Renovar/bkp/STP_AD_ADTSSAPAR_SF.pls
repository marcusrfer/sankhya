CREATE OR REPLACE PROCEDURE "STP_AD_ADTSSAPAR_SF" (p_Tipoevento Int,
                                                p_Idsessao   Varchar2,
                                                p_Codusu     Int) As
   Before_Insert Int;
   After_Insert  Int;
   Before_Delete Int;
   After_Delete  Int;
   Before_Update Int;
   After_Update  Int;
   Before_Commit Int;

   r_Par          Ad_Adtssapar%Rowtype;
   v_Ajustavenc   Int;
   v_Altvlrdesdob Char(1);

Begin
   Before_Insert := 0;
   After_Insert  := 1;
   Before_Delete := 2;
   After_Delete  := 3;
   Before_Update := 4;
   After_Update  := 5;
   Before_Commit := 10;

   /**************************
   Autor:     Ricardo Soares de Oliveira
   Criado em: 09/02/2018
   Objetivo:  Controle de Alterações feitas pelo usuário em tela, procedure vinculado a evento da tabela.

   Autor:     Ricardo Soares de Oliveira
   Alterado:  24/07/2018
   Objetivo:  Foi habilitado para alterações o campo VLRDESDOB e criado um campo na AD_ADTSSACONFUSU para identificar se o usuário tem permissão de alterar o valor do desdobramento, que até então era bloqueado para alterações, e criado aqui uma regra que valida se o usuário pode ou não alterar.

   **************************/

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

   If p_Tipoevento = Before_Insert Then
      Raise_Application_Error(-20101, Fc_Formatahtml_Sf('Inclusão não permitida', 'Utilize a ação gerar parcela', Null));
   End If;

   If p_Tipoevento = Before_Delete Then
      Raise_Application_Error(-20101,
                              Fc_Formatahtml_Sf('Exclusão não permitida, as parcelas são geradas automáticamente ao executar a opção "Gerar Parcelas" ou então ao alterar algum registro no cabeçalho',
                                                 Null, Null));
   End If;

   If p_Tipoevento = Before_Update Then
      -- r_par = Recebe o valor atual ou seja o Old
      -- Evp_Get = Recebe o novo valor ou seja o New
      Select p.*
        Into r_Par
        From Ad_Adtssapar p
       Where p.Nunico = Evp_Get_Campo_Int(p_Idsessao, 'NUNICO')
         And p.Sequencia = Evp_Get_Campo_Int(p_Idsessao, 'SEQUENCIA');
   
      Select Nvl(Conf.Ajustavenc, 0),
             Nvl(Usu.Altvlrdesdob, 'N')
        Into v_Ajustavenc,
             v_Altvlrdesdob
        From Ad_Adtssaconf    Conf,
             Ad_Adtssacab     Cab,
             Ad_Adtssaconfusu Usu
       Where Conf.Codigo = Cab.Tipo
         And Conf.Codigo = Usu.Codigo
         And Cab.Nunico = Evp_Get_Campo_Int(p_Idsessao, 'NUNICO')
         And Usu.Codusu = p_Codusu;
   
      If Evp_Get_Campo_Dta(p_Idsessao, 'DTVENC') <> r_Par.Dtvenc Then
      
         If ((Evp_Get_Campo_Dta(p_Idsessao, 'DTVENC') - Evp_Get_Campo_Dta(p_Idsessao, 'DTVENCINIC')) > 0 And
            (Evp_Get_Campo_Dta(p_Idsessao, 'DTVENC') - Evp_Get_Campo_Dta(p_Idsessao, 'DTVENCINIC')) > v_Ajustavenc) Then
            Raise_Application_Error(-20101,
                                    Fc_Formatahtml_Sf('Alteração Cancelada', 'Ajuste vencimento superior ao permitido',
                                                       Null));
         End If;
      End If;
   
      If r_Par.Vlrdesdob <> Evp_Get_Campo_Dec(p_Idsessao, 'VLRDESDOB') And v_Altvlrdesdob = 'N' Then
         Raise_Application_Error(-20101,
                                 Fc_Formatahtml_Sf('Alteração Cancelada',
                                                    'Usuário logado não tem permissão para promover alterações no campo valor do desdobramento!',
                                                    Null));
      End If;
   
      If Ad_Get.Dia_Util(p_Data => Evp_Get_Campo_Dta(p_Idsessao, 'DTVENC')) > 0 Then
         Raise_Application_Error(-20101,
                                 Fc_Formatahtml_Sf('Inclusão Cancelada',
                                                    'Vencimento não pode ser programado para finais de semana e feriados!!',
                                                    Null));
      
      End If;
   
   End If;

End;
/
