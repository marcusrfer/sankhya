Create Or Replace Procedure "AD_STP_REPROVLIB"(P_CODUSU Number, P_IDSESSAO Varchar2, P_QTDLINHAS Number,
                                               P_MENSAGEM Out Varchar2) As
  PARAM_MOTIVO     Varchar2(4000);
  FIELD_NUCHAVE    Number;
  FIELD_TABELA     Varchar2(4000);
  FIELD_EVENTO     Number;
  FIELD_SEQUENCIA  Number;
  FIELD_SEQCASCATA Number;
  FIELD_NUCLL      Number;
Begin

  PARAM_MOTIVO := ACT_TXT_PARAM(P_IDSESSAO, 'MOTIVO');

  For I In 1 .. P_QTDLINHAS -- Este loop permite obter o valor de campos dos registros envolvidos na execução.
  Loop
    -- A variável "I" representa o registro corrente.
    FIELD_NUCHAVE := ACT_INT_FIELD(P_IDSESSAO, I, 'NUCHAVE');
    FIELD_TABELA  := ACT_TXT_FIELD(P_IDSESSAO, I, 'TABELA');
  
    /*Alteração Gusttavo Lopes não alterar a regra*/
    If FIELD_TABELA = 'AD_CABSOLCPA' Then
      P_MENSAGEM := 'Não pode reprovar. Entrar na tela Solicitação de Compra para fazer a reprovação.';
      Return;
    End If;
  
    Select evento
      Into FIELD_EVENTO
      From tsilib
     Where nuchave = FIELD_NUCHAVE
       And tabela = FIELD_TABELA;
  
    Begin
      Update tsilib l
         Set l.reprovado = 'S', l.obslib = PARAM_MOTIVO, l.dhlib = Sysdate
       Where l.nuchave = FIELD_NUCHAVE
         And l.tabela = FIELD_TABELA
         And Nvl(l.evento, 0) = Nvl(FIELD_EVENTO, 0);
      If Sql%Rowcount = 0 Then
        P_MENSAGEM := 'O lançamento não foi encontrado. Nro:' || FIELD_NUCHAVE || '. Tabela: ' || FIELD_TABELA ||
                      '. Evento: ' || FIELD_EVENTO;
        Return;
      End If;
    Exception
      When Others Then
        P_MENSAGEM := 'Erro ao reprovar lançamento - ' || Sqlerrm;
        Return;
    End;
  
  End Loop;
  P_MENSAGEM := 'Lançameto(s) reprovado com sucesso.';

End;
/
