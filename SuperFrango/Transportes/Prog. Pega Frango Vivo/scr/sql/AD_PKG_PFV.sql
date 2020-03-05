Create Or Replace Package AD_PKG_PFV As

  v_QtdMacho      Constant Number := 4080;
  v_QtdFemea      Constant Number := 4590;
  v_DivMacho      Constant Number := 8;
  v_DivFemea      Constant Number := 9;
  v_CodProdMacho  Constant Number := 2896;
  v_CodProdFemea  Constant Number := 2897;
  v_CodProdSexado Constant Number := 2639;

  v_GeraPedido Boolean Default False;

  Type type_rec_pfv Is Record(
    codprod   Number,
    nupfv     Number,
    codune    Number,
    nucleo    Number,
    sexo      Varchar2(1),
    codcid    Number,
    distancia Float,
    dtmarek   Date,
    dtbouba   Date,
    dtgumboro Date,
    origpinto Varchar2(4000),
    dtagend   Date,
    qtdneg    Float,
    status    Varchar2(1),
    codparc   Number);

  --Procedure insere_agendamento(p_Nupfv  In Number,p_Errmsg Out Varchar2);

  Function get_codparc_integrado(p_Unidade Varchar,
                                 p_Nucleo  Varchar2,
                                 p_Aviario Varchar2) Return Number;

  Procedure atualiza_statusvei;

End ad_pkg_pfv;
/
Create Or Replace Package Body AD_PKG_PFV As

  /*Procedure insere_agendamento(p_Nupfv  In Number,
                               p_Errmsg Out Varchar2) Is
  
    \*
    * Autor: Marcus Rangel
    * Dt. Criação: 25/10/2017
    * Objetivo: Realizar o agendamento da coleta do frango vivo, quebrando pela quantidade de acordo com o produto
    *\
  
    r_Pfv         ad_tsfpfv2%Rowtype;
    v_Divisor     Number;
    v_Qtdneg      Number;
    v_QtdResidual Float := 0;
    v_Nuafv       Int := 0;
    Error Exception;
    Errmsg Varchar2(4000);
  Begin
  
    \*Preenche a record com os dados do registro*\
    Select *
      Into r_Pfv
      From ad_tsfpfv2
     Where nupfv = p_Nupfv;
  
    If r_pfv.codparc Is Null Then
      Begin
        Select codparc
          Into r_Pfv.Codparc
          From tgfpar
         Where (Upper(nomeparc) Like
               '%UNIDADE%' || r_pfv.codune || '%NUCLEO%' || r_pfv.nucleo || '%' Or
               Upper(nomeparc) Like
               '%UNIDADE%' || r_pfv.codune || '%AVIARIO%' || r_pfv.nucleo || '%');
      Exception
        When Others Then
          Null;
      End;
    
    End If;
  
    v_QtdResidual := r_pfv.qtdneg;
  
    If r_pfv.Sexo = 'F' Then
      v_Qtdneg  := v_QtdFemea;
      v_Divisor := v_DivFemea;
    Elsif r_pfv.sexo In ('M', 'X') Then
      v_Qtdneg  := v_QtdMacho;
      v_Divisor := v_DivMacho;
    End If;
  
    \*Begin
      Select Nvl(Max(a.nuafv), 0)
        Into v_nuafv
        From ad_tsfafv a
       Where a.nupfv = p_Nupfv;
    Exception
      When Others Then
        errmsg := Sqlerrm;
        Raise error;
    End;*\
  
    \*Begin
      Delete From ad_tsfafv a
       Where a.nupfv = r_pfv.nupfv;
    Exception
      When Others Then
        Raise;
    End;*\
  
    <<insere_agend>>
    Loop
      Exit When v_QtdResidual = 0;
    
      v_QtdResidual := v_QtdResidual - v_Qtdneg;
    
      v_Nuafv := v_nuafv + 1;
    
      Begin
        Insert Into ad_tsfafv
          (nupfv, nuafv, unidade, nucleo, codparc, codprod, dtagend, codparctransp, codveiculo,
           codmotorista, codcid, qtdneg, qtdnegalt, qtdvolalt, statusvei)
        Values
          (p_Nupfv, v_Nuafv, r_pfv.codune, r_pfv.nucleo, r_pfv.codparc, r_pfv.codprod,
           r_pfv.dtdescarte, Null, Null, Null, r_pfv.codcid, v_qtdneg, v_qtdneg / v_Divisor,
           v_Divisor, Null);
      Exception
        When Others Then
          Errmsg := 'Erro na inserção do agendamento. <br>' || Sqlerrm;
          Raise error;
      End;
    
      If v_QtdResidual < v_Qtdneg Then
        v_qtdneg := v_QtdResidual;
      End If;
    
    End Loop;
  
    \*Begin
      Update ad_tsfpfv
         Set status = 'A'
       Where nupfv = p_NuPfv;
    Exception
      When Others Then
        errmsg := 'Erro na atualização do status. <br>' || Sqlerrm;
        Raise error;
    End;*\
  
  Exception
    When error Then
      Rollback;
      p_Errmsg := errmsg;
    When Others Then
      Rollback;
      p_Errmsg := Sqlerrm;
  End insere_agendamento;*/

  Function get_codparc_integrado(p_Unidade Varchar,
                                 p_Nucleo  Varchar2,
                                 p_Aviario Varchar2) Return Number Is
    v_Codparc Number;
  Begin
  
    Begin
    
      Begin
        Select codparc
          Into v_Codparc
          From tgfpar
         Where codtipparc = 11110200
           And (Upper(nomeparc) Like
               '%UNIDADE%' || To_Char(p_Unidade) || '%AVIARIO%' || To_Char(p_Aviario) || '%' Or
               Upper(nomeparc) Like
               '%UNIDADE%' || To_Char(p_Unidade) || '%NUCLEO%' || To_Char(p_nucleo) || '%')
           And rownum = 1;
      Exception
        When no_data_found Then
          Select codparc
            Into v_codparc
            From tgfpar
           Where (Upper(nomeparc) Like '%UNIDADE%' || p_Unidade || '%AVIARIO%' || p_Aviario || '%' Or
                 Upper(nomeparc) Like '%UNIDADE%' || p_Unidade || '%NUCLEO%' || p_nucleo || '%')
             And rownum = 1;
      End;
    
    Exception
      When Others Then
        Raise;
    End;
  
    Return v_codparc;
  
  End get_codparc_integrado;

  Procedure atualiza_statusvei Is
    i Integer;
  Begin
    For f In (Select p.*
                From ad_tsfpfv2 p
               Where p.statusvei In ('P', 'I')
                 And p.nunota Is Not Null
              --And a.nupfv = 81
               Order By p.nunota)
    Loop
      -- verifica se nota gerada foi confirmada, nesse momento o motorista já pode ir buscar o frango
      Select Count(*)
        Into i
        From tgfcab cab
       Where cab.nunota = f.nunota
         And cab.statusnota = 'L';
    
      -- altera o status para "Estrada Ida"
      If i > 0 And f.statusvei = 'P' Then
        Begin
          Update ad_tsfpfv2 v
             Set statusvei = 'I'
           Where nupfv = f.nupfv;
        Exception
          When Others Then
            Raise;
        End;
      
      End If;
    
      -- verificam os que estão em descanso, já foram pesados mas ainda estão no pátio
      Select Count(*)
        Into i
        From tgfpeg peg
        Join tgfcab cab
          On peg.numnota = cab.numnota
         And cab.codtipoper = 27
       Where peg.dhiniciopega = f.dtagend
         And cab.nunota = f.nunota
         And peg.produto = 'FRANGO VIVO'
         And peg.dh1 Is Not Null
         And peg.dh2 Is Null;
    
      Begin
        If i > 0 And f.statusvei In ('C', 'I', 'V') Then
          Update ad_tsfpfv2 a
             Set a.statusvei = 'D'
           Where a.nupfv = f.nupfv;
          i := 0;
        End If;
      Exception
        When Others Then
          Raise;
      End;
    
      -- identifica os abatidos
      -- já foram pesados
      Select Count(*)
        Into i
        From tgfpeg peg
        Join tgfcab cab
          On peg.numnota = cab.numnota
         And cab.codtipoper = 27
       Where peg.dhiniciopega = f.dtagend
         And cab.nunota = f.nunota
         And peg.produto = 'FRANGO VIVO'
         And peg.dh1 Is Not Null
         And peg.dh2 Is Not Null
         And peg.dhabate Is Not Null;
    
      Begin
        If i > 0 And f.statusvei In ('D', 'I') Then
          Update ad_tsfpfv2 a
             Set a.statusvei = 'A'
           Where a.nupfv = f.nupfv;
        End If;
      Exception
        When Others Then
          Raise;
      End;
    
    End Loop;
  
  End atualiza_statusvei;

End AD_PKG_PFV;
/
