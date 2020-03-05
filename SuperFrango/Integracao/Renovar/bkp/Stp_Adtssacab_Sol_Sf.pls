CREATE OR REPLACE Procedure Stp_Adtssacab_Sol_Sf(p_Codusu    Number,
                                                 p_Idsessao  Varchar2,
                                                 p_Qtdlinhas Number,
                                                 p_Mensagem  Out Varchar2) As
   Field_Nunico Number;

   r_Cab  Ad_Adtssacab%Rowtype;
   r_Conf Ad_Adtssaconf%Rowtype;

   v_Aprfin           Number := 0;
   v_Count            Int;
   v_Diascarencia     Number;
   v_Dtvenc           Date;
   v_Log              Varchar2(100);
   v_Mensagemusu      Varchar2(500);
   v_Solicitacarencia Number := 0;
   v_Solicitajuro     Number := 0;
   v_Solicitaparcela  Number := 0;
   v_Solicitavalor    Number := 0;
   v_Tipojuro         Varchar2(30);
   v_Totdesp          Number;
   v_Totrec           Number;

   v_Titulo   Varchar(4000);
   v_Mensagem Varchar(4000);
   v_Incluir  Boolean;
   v_Count1 INT;
   p_Errmsg VARCHAR(200);
   Errmsg VARCHAR(200);

Begin

   /**************************
   Autor:     Ricardo Soares de Oliveira
   Criado em: 27/07/2017
   Objetivo:  Gerar o adiantamento com provisão = S, vai gerar receita e despesa, e após aprovado (TSILIB) a provisão para para N
   
   Autor:     Ricardo Soares de Oliveira
   Alterado:  24/07/2018
   Objetivo:  Foi habilitado para alterações o campo VLRDESDOB e criado um campo na AD_ADTSSACONFUSU para identificar se o usuário tem permissão de alterar o valor do desdobramento, que até então era bloqueado para alterações, e criado aqui uma regra que valida se o usuário pode ou não alterar e com isso houve a necessidade de validar se o valor total bate com o valor do adiantamento
   
   **************************/
   If p_Qtdlinhas > 1 Then
      Raise_Application_Error(-20101, Fc_Formatahtml_Sf('Selecione apenas um registro por vez', Null, Null));
   End If;

   Field_Nunico := Act_Int_Field(p_Idsessao, 1, 'NUNICO');

   Select Count(*) Into v_Count From Ad_Adtssapar p Where p.Nunico = Field_Nunico;
   --- BY RODRIGO DIA 4/07/2019 O.S 49204 projeto renovar
   Select Count(*) Into v_Count1 From AD_ADTSSAPARRENOVAR  p Where p.Nunico = Field_Nunico;

   If v_Count = 0  and v_Count1 = 0 Then
      Raise_Application_Error(-20101,
                              Fc_Formatahtml_Sf('Gere as parcelas antes de encaminhar para aprovação', Null, Null));
   End If;

   Select c.* Into r_Cab From Ad_Adtssacab c Where c.Nunico = Field_Nunico;

   If r_Cab.Situacao Not In ('E') Then
      Raise_Application_Error(-20101,
                              Fc_Formatahtml_Sf('Registro com situação diferente de <i>Elaborando</i>', Null, Null));
   End If;

   If r_Cab.Dtvenc <= Trunc(Sysdate) + 1 Then
      Raise_Application_Error(-20101,
                              Fc_Formatahtml_Sf('Ação não permitida!',
                                                 'Data informada no campo "Débito / Crédito em" inválida', Null));
   End If;

   Select Max(Data) Into v_Dtvenc From Table(Func_Dias_Uteis_Mmac(Trunc(Sysdate), Trunc(Sysdate) + 10, 1, 4));
  ----- o.s 57656 by rodrigo dia 26/11/2019
   If v_Dtvenc > r_Cab.Dtvenc AND r_Cab.CODNAT NOT IN ( 9053900,9054000,9054200, 9054300) Then
      Raise_Application_Error(-20101,
                              Fc_Formatahtml_Sf('Ação não permtitida!',
                                                 'Altere a data informada no campo "Débito / Crédito em"',
                                                 'A solicitação deve ser para pelo menos 3 dias uteis a partir da solicitação.'));
   
   End If;

   Select Sum(Decode(p.Recdesp, 1, p.Vlrdesdob, 0)),
          Sum(Decode(p.Recdesp, -1, p.Vlrdesdob, 0))
     Into v_Totrec,
          v_Totdesp
     From Ad_Adtssapar p
    Where p.Nunico = Field_Nunico;

   If r_Cab.Vlrdesdob <> v_Totrec Then
      Raise_Application_Error(-20101,
                              Fc_Formatahtml_Sf('Ação Cancelada!',
                                                 'A soma da coluna "Vlr Desdobramento" para Receitas da aba parcelas não bate com o "Valor do Empréstimo"',
                                                 Null));
   
   End If;

   If r_Cab.Vlrdesdob <> v_Totdesp Then
      Raise_Application_Error(-20101,
                              Fc_Formatahtml_Sf('Ação Cancelada!',
                                                 'A soma da coluna "Vlr Desdobramento" para Despesas da aba parcelas não bate com o "Valor do Empréstimo"',
                                                 Null));
   
   End If;

   Select c.* Into r_Conf From Ad_Adtssaconf c Where c.Codigo = r_Cab.Tipo;

   -- Verifica se exige aprovação e se informou CR Aprovador
   If r_Conf.Exigaprdesp = 'S' And Nvl(r_Cab.Codcencusresp, 0) = 0 Then
      Raise_Application_Error(-20101,
                              Fc_Formatahtml_Sf('Ação Cancelada!', 'Informe o CR responsável pela aprovação da despesa',
                                                 Null));
   
   End If;

   -- Verifica se a carencia é maior que o permitido
   If Nvl(r_Conf.Carencia, 0) > 0 And Nvl(r_Conf.Carencia, 0) < (r_Cab.Dtvenc1 - r_Cab.Dtvenc) And
      r_Conf.Carenciamaior = 'B' Then
      Raise_Application_Error(-20101,
                              Fc_Formatahtml_Sf('Ação Cancelada!',
                                                 'Carência de vencimento da primeira parcela maior que o permitido para o tipo de processo selecionado!',
                                                 Null));
   
   Elsif Nvl(r_Conf.Carencia, 0) > 0 And Nvl(r_Conf.Carencia, 0) < (r_Cab.Dtvenc1 - r_Cab.Dtvenc) And
         r_Conf.Carenciamaior = 'S' And r_Conf.Carenciamaior = 'S' And
         r_Cab.Codnat Not In (9053900, 9054000, 9054200, 9054300) Then
      -- Naturezas 9053900,9054000,9054200,9054300 relativo a Fundo de Retenção, as parcelas serão geradas todas para a mesma data, neste caso não há necessidade de solicitar aprovação do financeiro 
      v_Solicitacarencia := 1;
      v_Diascarencia     := (r_Cab.Dtvenc1 - r_Cab.Dtvenc);
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

   -- Verifica se o número de parcelas informado esta dentro do limite permitido
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

   -- Verifica se o juro informado esta dentro do limite permitido
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

   --Raise_Application_Error(-20105, v_Solicitavalor);
   -- Se o registro esta pendente de aprovação em função de juro, nr de parcelas ou valor do adiantamento envia uma requisição de aprovação para o financeiro, caso contrário faz a inclusão na TGFFIN pela
   If (v_Solicitajuro = 1 Or v_Solicitaparcela = 1 Or v_Solicitavalor = 1 Or v_Solicitacarencia = 1) And
      r_Conf.Exigaprdesp = 'S' Then
   
      If v_Solicitajuro = 1 Then
         v_Mensagemusu := 'Juro Minimo: ' || Nvl(r_Conf.Juro, 0) || '% - Juro Negociado: ' || Nvl(r_Cab.Taxa, 0) ||
                          '%. ';
      End If;
   
      If v_Solicitaparcela = 1 Then
         v_Mensagemusu := Case
                             When v_Mensagemusu Is Not Null Then
                              v_Mensagemusu || '\nNr. Máximo Parcelas: ' || r_Conf.Parcela || ' Nr. Parcelas Negociado: ' || r_Cab.Nrparcelas || '. '
                             Else
                              v_Mensagemusu || 'Nr. Máximo Parcelas: ' || r_Conf.Parcela || ' Nr. Parcelas Negociado: ' || r_Cab.Nrparcelas || '. '
                          End;
      End If;
   
      If v_Solicitavalor = 1 Then
         v_Mensagemusu := Case
                             When v_Mensagemusu Is Not Null Then
                              v_Mensagemusu || '\nVlr Máx Configurado: ' || Ad_Get.Formatavalor(r_Conf.Vlrmax) || ' Vlr Negociado: ' ||
                              Ad_Get.Formatavalor(r_Cab.Vlrdesdob) || '. '
                             Else
                              v_Mensagemusu || 'Vlr Máx Configurado: ' || Ad_Get.Formatavalor(r_Conf.Vlrmax) || ' Vlr Negociado: ' ||
                              Ad_Get.Formatavalor(r_Cab.Vlrdesdob) || '. '
                          End;
      End If;
   
      If v_Solicitacarencia = 1 Then
         v_Mensagemusu := Case
                             When v_Mensagemusu Is Not Null Then
                              v_Mensagemusu || '\nDias Máximo Carência: ' || r_Conf.Carencia || ' Dias Carência Negociado: ' || v_Diascarencia || '. '
                             Else
                              v_Mensagemusu || 'Dias Máximo Carência: ' || r_Conf.Carencia || ' Dias Carência Negociado: ' || v_Diascarencia || '. '
                          End;
      
      End If;
   
      v_Titulo   := 'Verifique dados do adiantamento!';
      v_Mensagem := 'Divergência de:\n' || v_Mensagemusu ||
                    '\n\n<font color="#FF0000">Será encaminhado uma solicitação de aprovação para o departamento financeiro</font>.\n\nDeseja Continuar?';
      v_Incluir  := Act_Confirmar(v_Titulo, v_Mensagem, p_Idsessao, 1);
   
      If v_Incluir Then
      
         v_Aprfin := 1;
      
         p_Mensagem := 'Solicitação encaminhada para Responsável CR e Departamento Financeiro. Caso tenha urgência no processo entre em contato e informe sua necessidade!';
      
         v_Log := 'Aguardando Aprovação Financeira e da Gerência';
      
      Else
         v_Log := 'Aguardando aprovação da gerência!';
      End If;
   
   End If;

   -- Gera Movimento Financeiro de Receita e Despesa
   IF v_Count1 = 0 THEN -- CASO EXISTA PARCELA DO RENOVAR NÃO HA GEREAÇÃO DE PARCELAS
        Stp_Adtssacab_Gerafin_Sf(Field_Nunico, v_Aprfin, v_Mensagemusu);
     else
          Ad_Set.Ins_Liberacao(p_Tabela => 'AD_ADTSSACAB', p_Nuchave => Field_Nunico, p_Evento => 1035, p_Valor =>r_Cab.VLRDESDOB,
                              p_Codusulib => 114,
                              p_Obslib => 'Adiantamento ' || r_Cab.NUACERTO,
                              p_Errmsg => Errmsg);
   END IF;

   If p_Mensagem Is Not Null Then
      p_Mensagem := p_Mensagem;
   Elsif r_Conf.Exigaprdesp = 'N' Then
      p_Mensagem := 'Adiantamento Finalizado com Sucesso!';
   Else
      p_Mensagem := 'Solicitação encaminhada para aprovação do Responsável CR. Caso tenha urgência no processo entre em contato com o aprovador e informe sua necessidade!';
   End If;

End;
/
