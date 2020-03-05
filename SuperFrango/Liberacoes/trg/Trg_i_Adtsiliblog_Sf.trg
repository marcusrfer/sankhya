Create Or Replace Trigger Trg_i_Adtsiliblog_Sf
  Before Insert On Ad_Tsiliblog
  For Each Row
  When (New.Evento In (1028, 1035) And (New.Dhlib Is Not Null))
Declare
  /*Por Ricardo Soares: Criei essa trigger porque o que esta sendo aprovado para pagamento 
  n�o precisa mais passar por valida��o do teto, uma vez que o teto j� foi solicitado no momento
  em que o usu�rio confirmou a nota*/
Begin
  If :New.Evento = 1035 And :New.Operacao = 'Liberou Pagamento' Then
  
    Begin
      Variaveis_Pkg.v_Atualizando := True;
      Update Tgffin f
         Set Provisao = 'N', f.Autorizado = 'S'
       Where Nunota = :New.Nuchave
         And f.Codtipoper Not In (3, 171, 284, 286, 355, 437, 438)
         And f.Provisao = 'S';
      Variaveis_Pkg.v_Atualizando := False;
    End;
    -- comentado por Marcus Rangel dia 26/05/2017, pois estava gerando erro na libera��o do evento 1028, despesas de transporte
    -- o case dever� ser analisado antes da reativa��o dessa trigger.
  Elsif :New.Evento = 1028 And :NEW.Tabela = 'TGFCAB' Then
  
    Begin
      Variaveis_Pkg.v_Atualizando := True;
      Update Tgffin f
         Set Provisao = 'N', f.Autorizado = 'S'
       Where Nunota = :New.Nuchave
         And f.Codtipoper In (3, 171, 284, 286, 355, 437, 438)
         And f.Provisao = 'S';
      Variaveis_Pkg.v_Atualizando := False;
    End;
  
  End If;

End Trg_i_Adtsiliblog_Sf;
/
