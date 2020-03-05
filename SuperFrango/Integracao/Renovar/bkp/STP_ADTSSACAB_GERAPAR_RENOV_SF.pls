CREATE OR REPLACE PROCEDURE "STP_ADTSSACAB_GERAPAR_RENOV_SF" (
       P_CODUSU NUMBER,        -- Código do usuário logado
       P_IDSESSAO VARCHAR2,    -- Identificador da execução. Serve para buscar informações dos parâmetros/campos da execução.
       P_QTDLINHAS NUMBER,     -- Informa a quantidade de registros selecionados no momento da execução.
       P_MENSAGEM OUT VARCHAR2 -- Caso seja passada uma mensagem aqui, ela será exibida como uma informação ao usuário.
) AS
       FIELD_NUNICO NUMBER;
         

   r_Cab  Ad_Adtssacab%Rowtype;
   r_Conf Ad_Adtssaconf%Rowtype;

   v_Dif              Float;
   v_Dt               Int := 1;
   v_Dtvenc           Date;
   v_Maxparcela       Int;
   v_Mensagemusu      Varchar2(200);
   v_Nufin            Number;
   v_Nrparcela        Number := 1;
   v_Recdesp          Number;
   v_Sequencia        Number;
   v_Solicitacarencia Number := 0;
   v_Solicitajuro     Number := 0;
   v_Solicitaparcela  Number := 0;
   v_Solicitavalor    Number := 0;
   p_nufind number := 0;
   --v_Valorjuro        Float;
   --v_Valortotal       Float;
   p_Vlrtot       Float;
   p_Vlr_Jur_Parc Float;
   p_Vlr_Parc     Float;
   p_Vlrtot_Juro  Float;

   v_Titulo   Varchar(4000);
   v_Mensagem Varchar(4000);
   v_Incluir  Boolean;
   p_nufinrecdesp number := 0;
   p_nuacerto number := 0;
   v_Codusu      Number := Stp_Get_Codusulogado;
   p_nufinrec  number := 0;
   P_VLRDESDOB NUMBER := 0;
   p_sequencia NUMBER := 0;
BEGIN

       -- Os valores informados pelo formulário de parâmetros, podem ser obtidos com as funções:
       --     ACT_INT_PARAM
       --     ACT_DEC_PARAM
       --     ACT_TXT_PARAM
       --     ACT_DTA_PARAM
       -- Estas funções recebem 2 argumentos:
       --     ID DA SESSÃO - Identificador da execução (Obtido através de P_IDSESSAO))
       --     NOME DO PARAMETRO - Determina qual parametro deve se deseja obter.


       FOR I IN 1..P_QTDLINHAS -- Este loop permite obter o valor de campos dos registros envolvidos na execução.
       LOOP                    -- A variável "I" representa o registro corrente.
           -- Para obter o valor dos campos utilize uma das seguintes funções:
           --     ACT_INT_FIELD (Retorna o valor de um campo tipo NUMÉRICO INTEIRO))
           --     ACT_DEC_FIELD (Retorna o valor de um campo tipo NUMÉRICO DECIMAL))
           --     ACT_TXT_FIELD (Retorna o valor de um campo tipo TEXTO),
           --     ACT_DTA_FIELD (Retorna o valor de um campo tipo DATA)
           -- Estas funções recebem 3 argumentos:
           --     ID DA SESSÃO - Identificador da execução (Obtido através do parâmetro P_IDSESSAO))
           --     NÚMERO DA LINHA - Relativo a qual linha selecionada.
           --     NOME DO CAMPO - Determina qual campo deve ser obtido.
           FIELD_NUNICO := ACT_INT_FIELD(P_IDSESSAO, I, 'NUNICO');



-- <ESCREVA SEU CÓDIGO AQUI (SERÁ EXECUTADO PARA CADA REGISTRO SELECIONADO)> --



       END LOOP;
       
       
     If p_Qtdlinhas > 1 Then
      Raise_Application_Error(-20101, Fc_Formatahtml_Sf('Selecione apenas um registro por vez', Null, Null));
   End If;

   Field_Nunico := Act_Int_Field(p_Idsessao, 1, 'NUNICO');

   Select c.* Into r_Cab From Ad_Adtssacab c Where c.Nunico = Field_Nunico;

   If r_Cab.Situacao Not In ('E', 'R') Then
      Raise_Application_Error(-20101,
                              Fc_Formatahtml_Sf('Registro com situação diferente de <i>Elaborando</i>',
                                                 'Se necessário reabra a solicitação.', Null));
   End If;

   Select Max(Data) Into v_Dtvenc From Table(Func_Dias_Uteis_Mmac(Trunc(Sysdate), Trunc(Sysdate) + 10, 1, 4));

   If v_Dtvenc > r_Cab.Dtvenc Then
      Raise_Application_Error(-20101,
                              Fc_Formatahtml_Sf('Ação não permitida!',
                                                 'Altere a data informada no campo "Débito / Crédito em"',
                                                 'A solicitação deve ser para pelo menos 3 dias uteis a partir da solicitação.'));
   
   End If;

   Select c.* Into r_Conf From Ad_Adtssaconf c Where c.Codigo = r_Cab.Tipo;

   -- Verifica se a carencia é maior que o permitido
   If Nvl(r_Conf.Carencia, 0) > 0 And Nvl(r_Conf.Carencia, 0) < (r_Cab.Dtvenc1 - r_Cab.Dtvenc) And
      r_Conf.Carenciamaior = 'B' Then
      Raise_Application_Error(-20101,
                              Fc_Formatahtml_Sf('Ação Cancelada!',
                                                 'Carência de vencimento da primeira parcela maior que o permitido para o tipo de processo selecionado!',
                                                 Null));
   
   Elsif Nvl(r_Conf.Carencia, 0) > 0 And Nvl(r_Conf.Carencia, 0) < (r_Cab.Dtvenc1 - r_Cab.Dtvenc) And
         r_Conf.Carenciamaior = 'S' And r_Cab.Codnat Not In (9053900, 9054000, 9054200, 9054300) Then
      -- Naturezas 9053900,9054000,9054200,9054300 relativo a Fundo de Retenção, as parcelas serão geradas todas para a mesma data, neste caso não há necessidade de solicitar aprovação do financeiro 
      v_Solicitacarencia := 1;
   End If;

   -- Verifica se o valor concedido esta dentro do limite permitido
   If Nvl(r_Conf.Vlrmax, 1) < Nvl(r_Cab.Vlrdesdob, 1) And r_Conf.Vlrmaior = 'B' Then
      Raise_Application_Error(-20101,
                              Fc_Formatahtml_Sf('Ação Cancelada!',
                                                 'Valor máximo nesse tipo de processo não pode ser superior a ' ||
                                                  To_Char(Ad_Get.Formatavalor(r_Conf.Vlrmax)), Null));
   
   Elsif Nvl(r_Conf.Vlrmax, 1) < Nvl(r_Cab.Vlrdesdob, 1) And r_Conf.Vlrmaior = 'S' And
         r_Cab.Codnat Not In (9053900, 9054000, 9054200, 9054300) Then
      -- Naturezas 9053900,9054000,9054200,9054300 relativo a Fundo de Retenção, as parcelas serão geradas todas para a mesma data, neste caso não há necessidade de solicitar aprovação do financeiro
      v_Solicitavalor := 1;
   End If;

   -- Verifica se o número de parcelas informado esta dentro do limite permitido.
   If Nvl(r_Conf.Parcela, 12) < Nvl(r_Cab.Nrparcelas, 1) And r_Conf.Parcelamaior = 'B' Then
      Raise_Application_Error(-20101,
                              Fc_Formatahtml_Sf('Ação Cancelada!',
                                                 'Número de parcelas nesse tipo de processo não pode ser superior a ' ||
                                                  r_Conf.Parcela, Null));
   
   Elsif Nvl(r_Conf.Parcela, 12) < Nvl(r_Cab.Nrparcelas, 1) And r_Conf.Parcelamaior = 'S' And
         r_Cab.Codnat Not In (9053900, 9054000, 9054200, 9054300) Then
      -- Naturezas 9053900,9054000,9054200,9054300 relativo a Fundo de Retenção, as parcelas serão geradas todas para a mesma data, neste caso não há necessidade de solicitar aprovação do financeiro
      v_Solicitaparcela := 1;
   End If;

   -- Verifica se o juro informado esta dentro do limite permitido.
   If Nvl(r_Conf.Juro, 0) > 0 And Nvl(r_Conf.Juro, 0) > Nvl(r_Cab.Taxa, 0) And r_Conf.Juromenor = 'B' Then
      Raise_Application_Error(-20101,
                              Fc_Formatahtml_Sf('Ação Cancelada!',
                                                 'Juro cobrado nesse tipo de processo não pode ser inferior a ' ||
                                                  r_Conf.Juro || '%', Null));
   
   Elsif Nvl(r_Conf.Juro, 0) > 0 And Nvl(r_Conf.Juro, 0) > Nvl(r_Cab.Taxa, 0) And r_Conf.Juromenor = 'S' And
         r_Cab.Codnat Not In (9053900, 9054000, 9054200, 9054300) Then
      -- Naturezas 9053900,9054000,9054200,9054300 relativo a Fundo de Retenção, as parcelas serão geradas todas para a mesma data, neste caso não há necessidade de solicitar aprovação do financeiro
      v_Solicitajuro := 1;
   End If;
   
   SELECT SUM(VLRDESDOB) INTO P_VLRDESDOB FROM AD_ADTSSAPARRENOVAR WHERE NUNICO =FIELD_NUNICO;
   
   IF r_Cab.vlrdesdob <> P_VLRDESDOB THEN
         Raise_Application_Error(-20101,
                              Fc_Formatahtml_Sf('Ação Cancelada!',
                                                 'Valor das parcelas difere do valor total - Erro verifique por favor ', Null));
   END IF;
   
     
   IF R_CAB.NUACERTO > 0 THEN
              Raise_Application_Error(-20101,
                              Fc_Formatahtml_Sf('Ação Cancelada!',
                                                 'Já foi gerado o adiantamento - CANCELANDO ', Null));
   END IF;
   
   
     ----- INSERE DESPESA
   
      stp_obtemid('TGFFIN', p_nufind);
    
      p_nufinrecdesp := p_nufind; -- usado para o update mais abaixo
    
      select max(ultcod) + 1
        into p_nuacerto
        from tgfnum
       where arquivo = 'TGFFRE'
         and serie = 'E';
    
      --tgfnum
      update tgfnum
         set ultcod = p_nuacerto
       where arquivo = 'TGFFRE'
         and serie = 'E';
     COMMIT;   
        
       p_sequencia := 1; 
        

    
      
    
     -- Gerando a Receita / Despesa Despesa
      Insert Into Tgffin
         (Nufin,
          Codemp,
          Numnota,
          Dtneg,
          Desdobramento,
          Dhmov,
          Dtvenc,
          Dtvencinic,
          Codparc,
          Codtipoper,
          Dhtipoper,
          Codctabcoint,
          Codnat,
          Codcencus,
          Codproj,
          Codtiptit,
          Vlrdesdob,
          Vlrjuroembut,
          Recdesp,
          Provisao,
          Origem,
          Codusu,
          Dtalter,
          Desdobdupl,
          Historico,
          Codbco,
          Ad_Variacao,
          Ad_Modcred,
          nucompens,
          Numdupl
         )
      Values
         (p_nufind,
          r_Cab.Codemp,
          Nvl(r_Cab.Numnota, r_Cab.Nunico),
          r_Cab.Dtneg, --Trunc(Sysdate), alterado por Ricardo Soares em 25/07/2018 conforme solicitação do João Paulo
          1,
          Sysdate,
          r_Cab.Dtvenc,
          r_Cab.Dtvenc,--r.Dtvenc,
          r_Cab.Codparc,--Case When r.Recdesp = -1 Then r_Cab.Codparc Else Nvl(r_Cab.Codparcrec, r_Cab.Codparc) End,
          169,
          (SELECT MAX(TOP.DHALTER) FROM TGFTOP TOP WHERE TOP.CODTIPOPER = 169),
          Nvl(r_Cab.Codctabcoint, r_Conf.Codctabcoint),
          r_Cab.Codnat,
          r_Cab.Codcencus,
          r_Cab.Codproj,
          0,--Case When r.Sequencia = 1 Then Case When r_Cab.Forma = '1' /*Crédito em conta*/ Then 56 When VERIFICAR
          --0,--r_Cab.Forma = '2' /*Cheque*/ Then 4 When r_Cab.Forma = '3' /*Espécie*/ Then 6 When r_Cab.Forma = '4' /*Compensação*/ Then 61 When VERIFICAR
          --r_Cab.Forma= '36' /*Boleto*/ Then 5 Else 3 End Else 61 End,
          Round( r_Cab.VLRDESDOB, 2),
          0,
          -1,
          'N',--Case When r_Conf.Exigaprdesp = 'N' Then 'N' Else r.Provisao End,
          'F',
          v_Codusu,
          Sysdate,
          'ZZ',
          r_Cab.Historico,
          1,
          'adtSsa',
          r_Cab.Modcred,
          p_nuacerto,
          p_nuacerto);
          
          
      insert into tgffre
        (codusu, dhalter, nuacerto, nufin, sequencia, tipacerto)
      values
        (p_codusu, sysdate, p_nuacerto, p_nufind, p_sequencia, 'A');    
         
      commit;
   
    FOR CUR IN (SELECT DTVENC,NUNICO,VLRDESDOB,SEQUENCIA FROM AD_ADTSSAPARRENOVAR WHERE NUNICO = Field_Nunico ) LOOP
    
      stp_obtemid('TGFFIN', p_nufinrec);
    
       
      Insert Into Tgffin
         (Nufin,
          Codemp,
          Numnota,
          Dtneg,
          Desdobramento,
          Dhmov,
          Dtvenc,
          Dtvencinic,
          Codparc,
          Codtipoper,
          Dhtipoper,
          Codctabcoint,
          Codnat,
          Codcencus,
          Codproj,
          Codtiptit,
          Vlrdesdob,
          Vlrjuroembut,
          Recdesp,
          Provisao,
          Origem,
          Codusu,
          Dtalter,
          Desdobdupl,
          Historico,
          Codbco,
          Ad_Variacao,
          Ad_Modcred,
          nucompens,
          Numdupl)
      Values
         (p_nufinrec,
          r_Cab.Codemp,
          Nvl(r_Cab.Numnota, r_Cab.Nunico),
          r_Cab.Dtneg, --Trunc(Sysdate), alterado por Ricardo Soares em 25/07/2018 conforme solicitação do João Paulo
          1,
          Sysdate,
          TRUNC(CUR.DTVENC),--r.Dtvenc,
          TRUNC(CUR.DTVENC),--r.Dtvenc,
          r_Cab.CodparcREC,--Case When r.Recdesp = -1 Then r_Cab.Codparc Else Nvl(r_Cab.Codparcrec, r_Cab.Codparc) End,
          182,
          (SELECT MAX(TOP.DHALTER) FROM TGFTOP TOP WHERE TOP.CODTIPOPER = 182),
          Nvl(r_Cab.Codctabcoint, r_Conf.Codctabcoint),
          r_Cab.Codnat,
          r_Cab.Codcencus,
          r_Cab.Codproj,
          3,--Case When r.Sequencia = 1 Then Case When r_Cab.Forma = '1' /*Crédito em conta*/ Then 56 When VERIFICAR
          --0,--r_Cab.Forma = '2' /*Cheque*/ Then 4 When r_Cab.Forma = '3' /*Espécie*/ Then 6 When r_Cab.Forma = '4' /*Compensação*/ Then 61 When VERIFICAR
          --r_Cab.Forma= '36' /*Boleto*/ Then 5 Else 3 End Else 61 End,
          Round( CUR.VLRDESDOB, 2),
          0,
          1,
          'N',--Case When r_Conf.Exigaprdesp = 'N' Then 'N' Else r.Provisao End,
          'F',
          v_Codusu,
          Sysdate,
          'ZZ',
          r_Cab.Historico,
          1,
          'adtSsa',
          r_Cab.Modcred,
          p_nuacerto,
           p_nuacerto);
         
          
          
         p_sequencia := p_sequencia + 1; 
        
       insert into tgffre
        (codusu, dhalter, nuacerto, nufin, sequencia, tipacerto)
      values
        (p_codusu, sysdate, p_nuacerto,p_nufinrec, p_sequencia, 'A');    
      
          
        UPDATE AD_ADTSSAPARRENOVAR SET NUFINREC = p_nufinrec, NUFINDESP = p_nufind  WHERE NUNICO = CUR.NUNICO AND SEQUENCIA = CUR.SEQUENCIA;
      
           
    END LOOP;
    
    
     UPDATE Ad_Adtssacab c SET C.NUFIN  = p_nufind , C.NUACERTO = p_nuacerto   Where c.Nunico = Field_Nunico;
   
   
   P_MENSAGEM := 'Gerado, favor conferir!!!';

   commit;

-- <ESCREVA SEU CÓDIGO DE FINALIZAÇÃO AQUI> --



END;
/
