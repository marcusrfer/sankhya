CREATE OR REPLACE Procedure Stp_Adtssacab_Gerapar_Sf(p_Codusu    Number,
                                                     p_Idsessao  Varchar2,
                                                     p_Qtdlinhas Number,
                                                     p_Mensagem  Out Varchar2) As
   Field_Nunico Number;

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
   --v_Valorjuro        Float;
   --v_Valortotal       Float;
   p_Vlrtot       Float;
   p_Vlr_Jur_Parc Float;
   p_Vlr_Parc     Float;
   p_Vlrtot_Juro  Float;

   v_Titulo   Varchar(4000);
   v_Mensagem Varchar(4000);
   P_COUNT INT;
   v_Incluir  Boolean;

Begin

   /**************************
   Autor:     Ricardo Soares de Oliveira
   Criado em: 09/02/2018
   Objetivo:  Gerar as parcelas, primeiro faço essa geração para que o usuário possa por exemplo mudar a data de vencimento, se eu mando direto como despesa vai bloquear
              tanto por conta de sábado/domingo/feriado quanto por causa do teto.
   **************************/

   If p_Qtdlinhas > 1 Then
      Raise_Application_Error(-20101, Fc_Formatahtml_Sf('Selecione apenas um registro por vez', Null, Null));
   End If;

   Field_Nunico := Act_Int_Field(p_Idsessao, 1, 'NUNICO');
   
 --- by rodrigo 05/07/2019  projeto renovar  
  SELECT COUNT(*) INTO P_COUNT  FROM AD_ADTSSAPARRENOVAR A WHERE A.NUNICO = Field_Nunico;
  
  IF P_COUNT > 0 THEN
        Raise_Application_Error(-20101,
                              Fc_Formatahtml_Sf('Existe parcela lançada na aba  <i>Adiantamento SSA Renovar</i>',
                                                 'Cancelando.', Null));
  
  END IF;
   

   Select c.* Into r_Cab From Ad_Adtssacab c Where c.Nunico = Field_Nunico;

   If r_Cab.Situacao Not In ('E', 'R') Then
      Raise_Application_Error(-20101,
                              Fc_Formatahtml_Sf('Registro com situação diferente de <i>Elaborando</i>',
                                                 'Se necessário reabra a solicitação.', Null));
   End If;

   Select Max(Data) Into v_Dtvenc From Table(Func_Dias_Uteis_Mmac(Trunc(Sysdate), Trunc(Sysdate) + 10, 1, 4));
----- o.s 57656 by rodrigo dia 26/11/2019
   If v_Dtvenc > r_Cab.Dtvenc AND r_Cab.CODNAT NOT IN ( 9053900,9054000,9054200, 9054300) Then
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

   -- Se o registro esta pendente de aprovação em função de juro, nr de parcelas ou valor do adiantamento envia uma requisição de aprovação para o financeiro, caso contrário faz a inclusão na TGFFIN pela
   -- Stp_ADTSSAcab_Gerafin_Sf e a solicitação de aprovação vai direto para o responsável. 
   -- Se estiver pendente de aprovação financeira, quem vai chamar a inclusão do financeiro vai ser a trigger da LIB
   If (v_Solicitajuro = 1 Or v_Solicitaparcela = 1 Or v_Solicitavalor = 1 Or v_Solicitacarencia = 1) And
      r_Conf.Exigaprdesp = 'S' Then
   
      If v_Solicitajuro = 1 Then
         v_Mensagemusu := ' Juro';
      End If;
   
      If v_Solicitaparcela = 1 Then
         v_Mensagemusu := Case
                             When v_Mensagemusu Is Not Null Then
                              v_Mensagemusu || ' e Nr. de Parcelas'
                             Else
                              v_Mensagemusu || ' Nr. de Parcelas'
                          End;
      End If;
   
      If v_Solicitavalor = 1 Then
         v_Mensagemusu := Case
                             When v_Mensagemusu Is Not Null Then
                              v_Mensagemusu || ' e Valor '
                             Else
                              v_Mensagemusu || ' Valor'
                          End;
      End If;
   
      If v_Solicitacarencia = 1 Then
         v_Mensagemusu := Case
                             When v_Mensagemusu Is Not Null Then
                              v_Mensagemusu || ' e Carência '
                             Else
                              v_Mensagemusu || ' Carência'
                          End;
      
      End If;
   
      v_Titulo   := 'Verifique dados do adiantamento!';
      v_Mensagem := 'As configurações de ' || v_Mensagemusu ||
                    ' estão divergentes das regras definidas para esse tipo de adiantamento.\n\n<font color="#FF0000">Ao gerar a solicitação, alem da aprovação do responsável será também encaminhado uma solicitação de aprovação para o departamento financeiro</font>.\n\nDeseja Continuar?';
      v_Incluir  := Act_Confirmar(v_Titulo, v_Mensagem, p_Idsessao, 1);
   
   End If;

   -- Gerando a Receita / Despesa Despesa

   Delete From Ad_Adtssapar Where Nunico = r_Cab.Nunico;

   Update Ad_Adtssacab c
      Set c.Dhsolicitacao = Null,
          c.Codusufin     = Null,
          c.Dhaprovfin    = Null,
          c.Codusuapr     = Null,
          c.Dhaprovadt    = Null,
          c.Situacao      = 'E'
    Where c.Nunico = Field_Nunico;

   v_Recdesp := Case
                   When r_Conf.Parcelar = '-1' Then
                    1
                   Else
                    -1
                End;

   Insert Into Ad_Adtssapar
      (Nunico,
       Sequencia,
       Nufin,
       Dtvenc,
       Vlrdesdob,
       Vlrjuros,
       Vlrtotal,
       Recdesp,
       Provisao,
       Nrparcela,
       Dtvencinic)
   Values
      (r_Cab.Nunico,
       1,
       Null,
       r_Cab.Dtvenc,
       r_Cab.Vlrdesdob,
       0,
       r_Cab.Vlrdesdob,
       v_Recdesp,
       'S',
       1,
       r_Cab.Dtvenc);

   -- Inserindo a(s) contrapartida
   -- Se o tipo selecionado está configurado para parcelar receita ou despesa
   v_Recdesp := Case
                   When r_Conf.Parcelar = '-1' Then
                    -1
                   Else
                    1
                End;
   v_Sequencia := 2;

   While v_Nrparcela <= r_Cab.Nrparcelas
   Loop
   
      --p_Vlr_Parc     := Round(v_Valortotal / r_Cab.Nrparcelas, 2);
      p_Vlr_Parc     := Round(r_Cab.Vlrdesdob / r_Cab.Nrparcelas, 2);
      p_Vlr_Jur_Parc := Case
                           When Nvl(r_Cab.Taxa, 0) > 0 Then
                            Ad_Get.Calculajuroprice(i => r_Cab.Taxa --Taxa
                                                   , n => r_Cab.Nrparcelas
                                                    --Nr de Parcelas
                                                   , Pv => r_Cab.Vlrdesdob
                                                    --Valor Empréstimo*/
                                                   , p_Dtneg => r_Cab.Dtvenc
                                                    --Data em que o empréstimo foi concedido
                                                   , p_Dtprimvenc => r_Cab.Dtvenc1
                                                    --Data primeiro vencimento
                                                   , p_Parcela => v_Nrparcela
                                                    -- Nr. Parcela 
                                                   , p_Tipojuro => r_Cab.Tipojuro
                                                    -- Tipo de Parcela S Simples ou C Composto
                                                   , p_Tipocalculo => r_Conf.Calculavenc
                                                    -- Tipo de Cálculo M - Mensal, B - Bimestral, S - Semestral, A - Anual
                                                    )
                           Else
                            0
                        End;
   
      Insert Into Ad_Adtssapar
         (Nunico,
          Sequencia,
          Nufin,
          Dtvenc,
          Vlrdesdob,
          Vlrjuros,
          Vlrtotal,
          Recdesp,
          Provisao,
          Nrparcela,
          Dtvencinic)
      Values
         (Field_Nunico,
          v_Sequencia,
          v_Nufin,
          Case When v_Nrparcela = 1 Or r_Cab.Codnat In (9053900, 9054000, 9054200, 9054300)
          -- Naturezas 9053900,9054000,9054200,9054300 relativo a Fundo de Retenção, as parcelas serão geradas todas para a mesma data
           Then r_Cab.Dtvenc1 Else
           Ad_Get.Dia_Util_Ultimo(Add_Months(r_Cab.Dtvenc1,
                                             (v_Nrparcela * Case When r_Conf.Calculavenc = 'B' Then 2 When
                                               r_Conf.Calculavenc = 'S' Then 6 When r_Conf.Calculavenc = 'A' Then 12 Else 1 End) - Case When
                                              r_Conf.Calculavenc = 'B' Then 2 When r_Conf.Calculavenc = 'S' Then 6 When
                                              r_Conf.Calculavenc = 'A' Then 12 Else 1 End)
                                  
                                 , 'P') End,
          Round(p_Vlr_Parc, 2),
          Round(p_Vlr_Jur_Parc, 2),
          Round(p_Vlr_Parc + p_Vlr_Jur_Parc, 2),
          v_Recdesp,
          'S',
          v_Nrparcela,
          Case When v_Nrparcela = 1 Then r_Cab.Dtvenc1 Else
          Ad_Get.Dia_Util_Ultimo(Add_Months(r_Cab.Dtvenc1,
                                            (v_Nrparcela * Case When r_Conf.Calculavenc = 'B' Then 2 When
                                              r_Conf.Calculavenc = 'S' Then 6 When r_Conf.Calculavenc = 'A' Then 12 Else 1 End) - Case When
                                             r_Conf.Calculavenc = 'B' Then 2 When r_Conf.Calculavenc = 'S' Then 6 When
                                             r_Conf.Calculavenc = 'A' Then 12 Else 1 End)
                                 
                                , 'P') End);
   
      v_Dt          := v_Dt + 1;
      v_Nrparcela   := v_Nrparcela + 1;
      v_Maxparcela  := v_Maxparcela + 1;
      v_Sequencia   := v_Sequencia + 1;
      p_Vlrtot      := Nvl(p_Vlrtot, 0) + p_Vlr_Parc;
      p_Vlrtot_Juro := Nvl(p_Vlrtot_Juro, 0) + p_Vlr_Jur_Parc;
   
   End Loop;

   v_Dif := r_Cab.Vlrdesdob - p_Vlrtot;

   If v_Dif <> 0 Then
      Update Ad_Adtssapar p
         Set p.Vlrdesdob = p.Vlrdesdob + v_Dif,
             p.Vlrtotal  = p.Vlrtotal + v_Dif
       Where p.Sequencia = 2
         And p.Nunico = Field_Nunico;
   End If;

   If r_Conf.Exigaprdesp = 'S' Then
   
      p_Mensagem := 'Parcelas Geradas! Verifique se as informações estão de acordo com o solicitado e encaminhe o registro para aprovação executando a rotina "Confirma / Solicita Aprovação"';
   
   Else
      p_Mensagem := 'Parcelas Geradas! Verifique se as informações estão de acordo com o solicitado e finalize executando a rotina "Confirma / Solicita Aprovação"';
   
   End If;
End;
/
