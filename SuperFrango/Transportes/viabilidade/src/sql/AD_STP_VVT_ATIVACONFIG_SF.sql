Create Or Replace Procedure "AD_STP_VVT_ATIVACONFIG_SF"(p_codusu    Number,
                                                        p_idsessao  Varchar2,
                                                        p_qtdlinhas Number,
                                                        p_mensagem  Out Varchar2) As
  v_numvvt Number;
  r_vvt    ad_tsfvvt%Rowtype;
  l        Int := 0;
Begin
  /* Autor: M. Rangel
  * Processo: Viabilidade de Ve�culos
  * Objetivo: Ativar a configura��o para que a mesma possa enviar os valores para a tela de regi�es de frete.
              A ideia � exista um controle de altera��es e hist�rico de vers�es das regras, para isso, ap�s ativar
              a mesma, altera��es n�o ser�o poss�veis, ent�o ser� necess�rio criar outra configura��o com outra
              data de vigor.
  */
  For i In 1 .. p_qtdlinhas
  Loop
    v_numvvt := act_int_field(p_idsessao, i, 'NUMVVT');
  
    -- popula record
    Select * Into r_vvt From ad_tsfvvt Where numvvt = v_numvvt;
  
    -- valida atual status de ativa��o
    If Nvl(r_vvt.ativo, 'N') = 'S' And p_qtdlinhas > 1 Then
      Continue;
    Elsif Nvl(r_vvt.ativo, 'N') = 'S' And p_qtdlinhas = 1 Then
      p_mensagem := 'Configura��o j� ativa.';
      Return;
    End If;
  
    If r_vvt.dtref Is Null Or r_vvt.dhvigor Is Null Then
      p_mensagem := 'Os campos Dt. Refer�ncia ou Dh. Vigor n�o podem ser nulos (' || r_vvt.numvvt || ')';
      Return;
    End If;
  
    -- percorre demais configura��es ativas no per�odo
    For r In (Select v.numvvt
                From ad_tsfvvt v
               Where v.dtref = r_vvt.dtref
                 And v.codregfre = r_vvt.codregfre
                 And v.codcat = r_vvt.codcat
                 And v.numvvt != r_vvt.numvvt
                 And Nvl(v.ativo, 'N') = 'S')
    Loop
      Begin
        Update ad_tsfvvt
           Set ativo   = 'N',
               codusu  = stp_get_codusulogado,
               dhalter = Sysdate
         Where numvvt = r.numvvt
           And Nvl(ativo, 'N') = 'S';
      Exception
        When Others Then
          p_mensagem := 'Erro ao atualizar as demais configura��es ativas na mesma refer�ncia. (' || r.numvvt || ')';
          Return;
      End;
    
    End Loop;
  
    -- ativa configura��o atual 
    Begin
      Update ad_tsfvvt
         Set ativo   = 'S',
             codusu  = stp_get_codusulogado,
             dhalter = Sysdate
       Where numvvt = r_vvt.numvvt
         And Nvl(ativo, 'N') = 'N';
      l := Sql%Rowcount;
    Exception
      When Others Then
        p_mensagem := 'N�o foi poss�vel ativar esta configura��o. (' || Sqlerrm || ')';
        Return;
    End;
  
  End Loop;

  If l > 1 Then
    p_mensagem := l || ' Lan�amentos foram ativados';
  Elsif l = 1 Then
    p_mensagem := 'Lan�amento ativado com sucesso!';
  Elsif l = 0 Then
    p_mensagem := 'Nenhum lan�amento ativado.';
  End If;

End;
/
