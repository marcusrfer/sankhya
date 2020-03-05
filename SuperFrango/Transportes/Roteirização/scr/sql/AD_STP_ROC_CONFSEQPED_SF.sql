Create Or Replace Procedure "AD_STP_ROC_CONFSEQPED_SF"(p_codusu    Number,
                                                       p_idsessao  Varchar2,
                                                       p_qtdlinhas Number,
                                                       p_mensagem  Out Nocopy Varchar2) As
  r_ord       tgford%Rowtype;
  r_roc       ad_tsfrocc%Rowtype;
  v_codregfre Number;
  v_CodCat    Number;
  v_VlrRota   Float;
  t           Int := 0;
  t1          Int := 0;
  validacao   Boolean Default False;
Begin
  /*
  * Autor:
  * Processo: Roteirizador/sequenciador de ordens de carga (subprocesso frete OC)
  * Objetivo: Atualiza o status do status da rotina, atualiza a ordem de carga, sequência de carga, valor do frete dos pedidos/notas.
  */

  For i In 1 .. p_qtdlinhas
  Loop
    r_roc.numrocc := act_int_field(p_idsessao, i, 'NUMROCC');
  
    Select *
      Into r_roc
      From ad_tsfrocc
     Where numrocc = r_roc.numrocc;
  
    If Nvl(r_roc.teste, 'N') = 'S' Then
      validacao := True;
    End If;
  
    Select Count(Distinct codregfre)
      Into t
      From ad_tsfrocp
     Where numrocc = r_roc.numrocc;
  
    If t > 1 Then
      p_mensagem := 'Não é possível executar a ação, pois existem mais de uma região de frete. <br>' ||
                    'Utilize a ação "Atualizar Região de Frete" para unificar as regiões.';
      Return;
    End If;
  
    Select Count(*)
      Into t
      From ad_tsfrocp
     Where numrocc = r_roc.numrocc;
  
    If t = 0 Then
      p_mensagem := 'Não há necessidade de se confirmar uma OC vazia!';
      Return;
    End If;
  
    For c In (Select *
                From ad_tsfrocc
               Where numrocc = r_roc.numrocc)
    Loop
    
      If Nvl(c.teste, 'N') = 'S' Then
        validacao := True;
      End If;
    
      -- verifica status
      If c.status = 'C' And p_qtdlinhas > 1 Then
        Continue;
      Elsif c.status = 'C' And p_qtdlinhas = 1 Then
        p_mensagem := 'Esta ordem de carga já está confirmada.';
        Return;
      Elsif c.codveiculo = 0 Then
        p_mensagem := 'Veículo não informado!!!';
        Return;
      Elsif Nvl(c.distrota, 0) = 0 Then
        p_mensagem := 'Distância não calculada, impossível confirmar formação de carga.';
        Return;
        /*Elsif Nvl(c.vlrrota, 0) = 0 Then
        p_mensagem := 'Valor da rota não calculada, impossível confirmar formação de carga.';*/
        Return;
      End If;
    
      -- nos casos em que várias linhas serão cnfirmadas as ordens que não possuírem valor/distância não interromperão o processo
      -- itera contador de erro pra exibir na mensgem de saída.
    
      If Nvl(c.distrota, 0) = 0 And p_qtdlinhas > 1 Then
        t1 := t1 + 1;
        Continue;
      Elsif Nvl(c.distrota, 0) = 0 And p_qtdlinhas = 1 Then
        p_mensagem := 'Não foi possível confirmar esta roteirização, pois a ordem de carga não possui distância total';
        --Return;
      End If;
    
      -- exclui os lançamentos com OC diferente do cabeçalho
      Begin
        ad_pkg_var.permite_update := True;
      
        For dif In (Select *
                      From ad_tsfrocp p
                     Where p.numrocc = c.numrocc
                       And p.ordemcarga != c.ordemcarga)
        Loop
        
          If validacao Then
            Null;
          Else
            Update tgfcab
               Set ordemcarga = dif.ordemcarga
             Where nunota = dif.nunota;
          End If;
        End Loop;
      
        Delete From ad_tsfrocp
         Where numrocc = c.numrocc
           And Nvl(ordemcarga, 0) != c.ordemcarga;
      Exception
        When Others Then
          p_mensagem := 'Erro ao remover as ordens de carga diferentes. ' || Sqlerrm;
          Return;
      End;
    
      Begin
        Select *
          Into r_ord
          From tgford
         Where codemp = c.Codemp
           And ordemcarga = c.Ordemcarga;
      Exception
        When Others Then
          p_mensagem := 'Erro ao buscar dados do cadastro da Ordem de Carga';
          Return;
      End;
    
      -- verifica se é carona
      If Nvl(r_ord.ad_carona, 'N') = 'S' Or ad_pkg_fre.check_carona(c.Codemp, c.Ordemcarga) = True Then
        ad_pkg_fre.set_dist_vlr_carona(c.codemp, c.ordemcarga, c.distrota);
      Else
      
        Begin
          Select v.ad_codcat
            Into v_codcat
            From tgfvei v
           Where v.codveiculo = c.Codveiculo;
        
          If v_codcat = 0 Then
            p_mensagem := 'Categoria do veículo não informada.<br>' || 'Veículo: <a href="' ||
                          ad_fnc_urlskw('TGFVEI', c.Codveiculo) || '" target="_parent">' ||
                          '<font color="#FF0000"><b>' || c.Codveiculo || '</b></font></a>';
            Return;
          End If;
        Exception
          When Others Then
            p_mensagem := 'Erro inesperado ao consultar categoria do veículo. ' || Sqlerrm;
            Return;
        End;
      
        Begin
          Select Distinct codregfre
            Into v_codregfre
            From ad_tsfrocp
           Where numrocc = c.numrocc
             And ordemcarga = c.ordemcarga;
        Exception
          When Others Then
            p_mensagem := Sqlerrm;
            Return;
        End;
      
        Declare
          i Int;
        Begin
          Select r.codcat
            Into i
            From ad_tsfrfr r
           Where r.codregfre = v_codregfre
             And r.codcat = v_CodCat
             And r.dtvigor = (Select Max(dtvigor)
                                From ad_tsfrfr R2
                               Where r.codregfre = R2.CODREGFRE
                                 And r.codcat = r2.Codcat);
        Exception
          When no_data_found Then
            p_mensagem := 'Não existe preço cadastrado para essa categoria (' || v_CodCat ||
                          ') nessa região (' || v_codregfre || ').<br>' ||
                          'Visite o cadastro de Regiões de Frete e cadastre a mesma antes de continuar.';
            Return;
          When Others Then
            --Raise_Application_Error(-20105, v_codregfre || ' | ' || v_codcat);
            Raise;
        End;
      
        v_Vlrrota := ad_pkg_fre.get_vlr_regfrete(v_codregfre, v_CodCat, Nvl(c.DistRota, 0));
      
        If ad_pkg_fre.soma_pedagio = 'S' Then
          v_Vlrrota := v_Vlrrota + ad_pkg_fre.get_vlr_pedagio(c.codemp, c.ordemcarga, v_CodCat);
        End If;
      
      End If;
    
      Merge Into ad_tsfrfv v
      Using (Select c.Codemp     As codemp,
                    c.Ordemcarga As ordemcarga,
                    c.Distrota   As distancia,
                    v_Vlrrota    As vlrrota
               From dual) D
      On (v.codemp = d.codemp And v.ordemcarga = d.ordemcarga)
      When Matched Then
        Update
           Set v.distrota = d.distancia,
               v.vlrrota  = d.vlrrota
      When Not Matched Then
        Insert
          (v.codemp, v.ordemcarga, v.distrota, v.vlrrota)
        Values
          (d.codemp, d.ordemcarga, d.distancia, d.vlrrota);
    
      Begin
        Update ad_tsfrocc
           Set vlrrota = v_VlrRota
         Where numrocc = c.numrocc;
      Exception
        When Others Then
          p_mensagem := 'Erro ao atualizar o valor da Ordem de Carga. <br>' || Sqlerrm;
          Return;
      End;
    
      -- atualiza ordem de carga, para atender processos herdados
      /*Begin
        If validacao Then
          Null;
        Else
          Update tgford ord
             Set ord.ad_liberado = Nvl(c.liberado, ord.ad_liberado),
                 ord.ad_libacertopen = Nvl(c.libacertopen, ord.ad_libacertopen)
           Where codemp = c.codemp
             And ordemcarga = c.ordemcarga;
        End If;
      Exception
        When Others Then
          p_mensagem := 'Erro ao atualizar liberações na ordem de carga! ' || Sqlerrm;
          Return;
      End;*/
    
      -- cursor para o cálculo do frete de cada nunota em relação ao peso
      For p In (
                
                Select numrocp,
                        codparctransp,
                        nunota,
                        sequencia,
                        peso,
                        Round(ratio_to_report(peso) Over(Partition By numrocc) * 100, 2) As perc,
                        Round(ratio_to_report(peso) Over(Partition By numrocc) * vlrrota, 2) As vlrfrete
                  From (Select roc.codparctransp,
                                poc.numrocc,
                                poc.numrocp,
                                poc.nunota,
                                poc.sequencia,
                                poc.peso,
                                (Select Sum(peso)
                                   From ad_tsfrocp p2
                                  Where p2.numrocc = poc.numrocc) As pesototal,
                                roc.vlrrota
                           From ad_tsfrocp poc
                           Join ad_tsfrocc roc
                             On poc.numrocc = roc.numrocc
                          Where poc.numrocc = c.numrocc
                            And poc.ordemcarga = c.ordemcarga)
                 Order By sequencia
                
                )
      Loop
        Begin
          Dbms_Output.Put_Line(p.nunota || ' | ' || p.peso || ' | ' || p.sequencia || ' | ' ||
                               p.perc || ' | ' || p.vlrfrete);
        
          -- atualiza os dados na CAB
          If validacao Then
            Null;
          Else
            Update tgfcab cab
               Set vlrfrete      = p.vlrfrete,
                   ordemcarga    = c.ordemcarga,
                   cab.seqcarga  = p.sequencia,
                   codparctransp = p.codparctransp,
                   codveiculo    = r_ord.codveiculo,
                   cif_fob       = 'F',
                   tipfrete      = 'N'
             Where codemp = c.codemp
               And nunota = p.nunota;
          End If;
        
        Exception
          When Others Then
            p_mensagem := 'Erro ao atualizar a ordem de carga dos pedidos. ' || Sqlerrm;
            Return;
        End;
      
      End Loop p;
    
      -- atualiza o status do cabeçalho
      Begin
        Update ad_tsfrocc
           Set status = 'C' --, liberado = 'S'
         Where numrocc = c.numrocc;
      Exception
        When Others Then
          p_mensagem := 'Erro ao atualizar o status da ordem de carga. ' || Sqlerrm;
          Return;
      End;
    
    End Loop c;
  
  End Loop i;

  If t1 > 0 Then
    p_mensagem := 'Não foi possível confirmar algumas roteirizações, pois as mesmas não possuiam distância total informada.';
  Else
    p_mensagem := 'Roteirização confirmada com sucesso';
  End If;

  If validacao Then
    p_mensagem := p_mensagem ||
                  '<br>Não foram realizadas as alterações nos pedidos, pois processo está marcado como <b>"Validação"</b>.';
  End If;

End;
/
