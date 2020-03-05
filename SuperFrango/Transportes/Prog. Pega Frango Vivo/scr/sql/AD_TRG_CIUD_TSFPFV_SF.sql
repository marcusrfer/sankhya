Create Or Replace Trigger AD_TRG_CIUD_TSFPFV_SF
  For Insert Or Update Or Delete On ad_tsfpfv
  Compound Trigger

  /*
  * Autor: Marcus Rangel
  * Processo: Programação Coleta de Frango Vivo
  * Objetivo: Realizar validações e tratativas nos dados oriundos da integração com o AVECOM
  */

  v_AtualizaQtd Boolean Default False;
  v_Nupfv       Number;
  v_ErrMsg      Varchar2(4000);
  gerandoPedido Varchar2(1);

  Before Statement Is
  Begin
    If ad_pkg_pfv.v_GeraPedido Then
      gerandoPedido := 'S';
    Else
      gerandoPedido := 'N';
    End If;
  End Before Statement;

  Before Each Row Is
    v_Codparc Number;
  Begin
  
    If (inserting Or updating) And gerandoPedido = 'N' Then
    
      -- teoricamente, a única entrada de dados nessa tabela será pela trigger da TSFTFV
      -- e já existe essa tratativa lá, permanceu aqui sem raise só para o fato de, futuramente,
      -- se permitir a inclusão pela tela.
    
      -- tratativa para parceiro nulo
      If :new.Codparc Is Null Then
        Begin
          Select codparc
            Into v_Codparc
            From tgfpar
           Where (Upper(nomeparc) Like
                 '%UNIDADE%' || :new.codune || '%NUCLEO%' || :new.nucleo || '%' Or
                 Upper(nomeparc) Like
                 '%UNIDADE%' || :new.codune || '%AVIARIO%' || :new.nucleo || '%');
        
          :new.Codparc := v_codparc;
        Exception
          When Others Then
            Null;
        End;
      
      End If;
    
      -- tratativa para produto nulo
      If :new.Codprod Is Null Then
        If :new.Sexo = 'M' Then
          :new.Codprod := ad_pkg_pfv.v_codprodmacho;
        Elsif :new.Sexo = 'F' Then
          :new.Codprod := ad_pkg_pfv.v_codprodfemea;
        Elsif :new.Sexo = 'S' Then
          :new.Codprod := ad_pkg_pfv.v_codprodsexado;
        End If;
      End If;
    
      -- tratativa para update na quantidade
      If :new.Qtdneg != :old.Qtdneg And :old.qtdneg Is Not Null Then
        v_AtualizaQtd := True;
        v_Nupfv       := :new.Nupfv;
      End If;
    
      -- tratativa para prioridade, usuário conseguir ordenar por regra
      If :new.Dtdescarte > Trunc(:new.Dtagend) And :new.Horapega Between 1800 And 2359 Then
        :new.prioridade := 0;
      Else
        :new.Prioridade := 1;
      End If;
    
    End If;
  
    -- Ao atualizar, verifica se o laudo foi importado, se não, busca realizar a vinculação.  
    If updating And gerandopedido = 'N' Then
      If :old.Numlfv Is Null Then
        Begin
          Select To_Date(l.dtalojamento - 1, 'dd/mm/yyyy'),
                 To_Date(l.dtalojamento - 1, 'dd/mm/yyyy'),
                 To_Date(l.dtalojamento + 14, 'dd/mm/yyyy'),
                 l.gta || ' - ' || par.cgc_cpf,
                 l.qtdaves,
                 l.qtdmortes
            Into :new.dtmarek,
                 :new.dtbouba,
                 :new.dtgumboro,
                 :new.origpinto,
                 :new.qtdpega,
                 :new.qtdmortes
            From ad_tsflfv l
            Join tgfpar par
              On l.codparc = par.codparc
           Where l.codparc = :new.codparc
             And l.codprod = :new.codprod
             And l.dtabate = To_Date(:new.Dtdescarte, 'dd/mm/yyyy');
        Exception
          When no_data_found Then
            :new.dtmarek   := Null;
            :new.dtbouba   := Null;
            :new.dtgumboro := Null;
            :new.origpinto := Null;
            :new.qtdpega   := Null;
            :new.qtdmortes := Null;
        End;
      End If;
    End If;
  
    /*    
    If deleting Then
      t.extend;
      i := t.last;
      t(i).nupfv := :old.nupfv;
      t(i).nutfv := :old.Numtfv;
    End If;*/
  
  End Before Each Row;

  After Statement Is
  Begin
  
    If v_AtualizaQtd Then
      Begin
      
        Delete From ad_tsfafv t
         Where nupfv = v_Nupfv
           And t.codveiculo Is Null;
      
        If Sql%Rowcount > 0 Then
          ad_pkg_pfv.insere_agendamento(v_Nupfv, v_errmsg);
        Else
          Null;
        End If;
      Exception
        When Others Then
          Raise;
      End;
    
    End If;
  
    /*    
    If t.count > 0 Then
    
      For x In t.first .. t.last
      Loop
        Begin
        
          Delete From ad_tsfafv a
           Where a.nupfv = t(x).nupfv;
        
          Delete From ad_tsftfv
           Where numtfv = t(x).nutfv;
        
        Exception
          When Others Then
            Raise;
        End;
      
      End Loop;
    End If;*/
  
  End After Statement;

End;
/
