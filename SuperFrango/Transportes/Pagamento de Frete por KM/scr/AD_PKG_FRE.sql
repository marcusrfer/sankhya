Create Or Replace Package AD_PKG_FRE Is

  soma_pedagio Constant Varchar2(1) := get_tsipar_logico('SOMAPEDAGIOFRET');

  Type num_requests Is Table Of Number;

  /*
  * Autor: Marcus Rangel
  * Objetivo: Retorna a distância entre duas cidades
  * utilizando o cadastro de distância.
  */
  Function Distancia_Entre_Cidades_Oc(p_Codemp     Number,
                                      p_Ordemcarga Int) Return Float;
  Function Distancia_entre_parceiros(p_codparcOrig Number,
                                     p_codparcDest Number) Return Float;

  /*
  * Autor: Marcus Rangel
  * Objetivo: Calcula a distância geodesica entre dois pontos
  */
  Function distancia_cartesiana(p_Lat_ini Varchar2,
                                p_Lon_ini Varchar2,
                                p_Lat_fin Varchar2,
                                p_Lon_fin Varchar2) Return Number;

  -- verifica se ordem de carga informada é carona, retorna true ou false
  Function check_carona(p_codemp     Number,
                        p_ordemcarga Number) Return Boolean;

  /*
  * Autor: Marcus Rangel
  * Objetivo: Função que retornar a distância total entre todos os
  * pontos em uma ordem de carga.
  */
  Function get_Distancia_Total_OC(p_Codemp     Number,
                                  p_OrdemCarga Number) Return Float;

  /*
  * Autor: Marcus Rangel
  * Objetivo: Função que retorna o valor da ordem de carga, baseando-se
  * nos parametros definidos da tela de regiões de frete e praças de 
  * pedágio
  */
  Function get_valor_oc_regfrete(p_codemp     Number,
                                 p_ordemcarga Number) Return Float;

  /*
  * Autor: Marcus Rangel
  * Objetivo: Método que busca a latitude e a longitude do parceiro
  * no google maps, similar ao botão mapas no cadastro de parceiro, 
  * porém, pode ser usado para operações em lote.
  */
  Procedure atualiza_coord_parc(p_Codparc Number,
                                p_coord   Out Varchar2,
                                p_Link    Out Varchar2,
                                p_Errmsg  Out Varchar2);

  /* 
  * Autor: Marcus Rangel
  * Objetivo: Procedure chamada pela procedure do botão de ação,
  * a mesma executa a busca da distância e grava na tabela AD_TSFRFV
  */
  Procedure set_distancia_rota(p_codemp     Number,
                               p_OrdemCarga Number);

  /* 
  * Autor: Marcus Rangel
  * Objetivo: Procedure chamada pela procedure do botão de ação,
  * a mesma executa a busca do valor e grava na tabela  AD_TSFRFV
  */
  Procedure set_valor_rota(p_codemp     Number,
                           p_OrdemCarga Number);

  /* Autor: M.Rangel
  * Objetivo: Procedure que atualiza a distância e o valor do frete da ordem de carga considerando as regras para carona, definidas no cadastro de regiões de 
              frete, aba "caronas"
  */
  Procedure set_dist_vlr_carona(p_codemp     Number,
                                p_ordemcarga Number,
                                p_distRota   Float);

  --Autor: Marcus Rangel
  --Objetivo: Buscar a distância no google maps a distância de dois pontos.

  Function get_Distancia_Xml(v_Coord_Orig Varchar2,
                             v_Coord_Dest Varchar2) Return Float;

  --Autor: Marcus Rangel
  --Objetivo: Determinar a sequencia de entrega da ordem de carga pela distância entre os parceiros.

  Procedure set_Sequencia_Rota(p_Codemp     Number,
                               p_OrdemCarga Number,
                               p_ErrMsg     Out Varchar2);

  /* M. Rangel - Busca o valor do km pela região e categoria */
  Function get_vlr_regfrete(p_codregfre Number,
                            p_codcat    Number,
                            p_distancia Float) Return Float;

  /* M.Rangel - Calcula o valor do pedágio pela ordem de carga, compõe o valor do frete */
  Function get_vlr_pedagio(p_codemp     Number,
                           p_ordemcarga Number,
                           p_CodCat     Number) Return Float;

  -- Autor: M. Rangel
  -- Objetivo: Buscar o cód. região de frete do parceiro percorrendo a hierarquia do cadastro de regiões 
  Function get_codregfrete(p_codparc Number) Return Number;

  Function ocevento(p_codveiculo Number,
                    p_codevento  Number) Return Float;

  Function get_vlrfrete_formula(p_Nunota     Number,
                                p_codemp     Number,
                                p_codparc    Number,
                                p_OrdemCarga Number,
                                p_CodVeiculo Number) Return Float;

  Procedure set_vlrfrete_formula(p_Nunota     Number,
                                 p_codemp     Number,
                                 p_codparc    Number,
                                 p_OrdemCarga Number,
                                 p_codveiculo Number,
                                 p_errmsg     Out Varchar2);

End ad_Pkg_Fre;
/
Create Or Replace Package Body AD_PKG_FRE Is

  Function Distancia_entre_cidades_oc(p_Codemp     Number,
                                      p_Ordemcarga Int) Return Float Is
    Cidade_Emp  Int;
    Cidade_Orig Int;
    Cidade_Dest Int;
    Distancia   Float := 0;
  Begin
  
    Select E.Codcid
      Into Cidade_Emp
      From Tsiemp E
     Where E.Codemp = p_Codemp;
  
    Cidade_Orig := Cidade_Emp;
  
    For C_dist In (Select C.Seqcarga, P.Codcid
                     From Tgfcab C
                     Join Tgfpar P
                       On C.Codparc = P.Codparc
                    Where C.Codemp = p_Codemp
                      And C.Ordemcarga = p_Ordemcarga
                    Order By C.Seqcarga)
    Loop
      Cidade_Dest := C_dist.Codcid;
    
      If Cidade_Orig = Cidade_Dest Then
        Distancia := Distancia + 0;
      Else
        Distancia := Distancia + Ad_get.Distanciacidade(Cidade_Orig, Cidade_Dest);
      End If;
    
      Cidade_Orig := C_dist.Codcid;
      --Dbms_Output.put_line(distancia);
    End Loop;
  
    Distancia := Distancia + Ad_get.Distanciacidade(Cidade_Emp, Cidade_Dest);
  
    Return Distancia;
  
  Exception
    When Others Then
      Return 0;
  End Distancia_entre_cidades_oc;

  Function Distancia_entre_parceiros(p_codparcOrig Number,
                                     p_codparcDest Number) Return Float Is
    v_Distancia Float;
  Begin
    Begin
      Select d.distancia
        Into v_distancia
        From TSIDIS d
       Where d.codparcorig = p_codparcorig
         And d.codparcdest = p_codparcDest;
    Exception
      When Others Then
        v_Distancia := 0;
    End;
    Return v_distancia;
  End;

  Function Distancia_cartesiana(p_Lat_ini Varchar2,
                                p_Lon_ini Varchar2,
                                p_Lat_fin Varchar2,
                                p_Lon_fin Varchar2) Return Number Is
    v_rad       Number := 8200; -- := 8200; --6387.7; raio equatorial 6378.13, raio polar 6357
    v_GrausRad  Number := 57.30; --57.29577951; -- 1 radiano possui 57,30 mts
    Lat1        Number;
    Lon1        Number;
    Lat2        Number;
    Lon2        Number;
    v_distancia Number;
  Begin
  
    Lat1 := To_Number(Replace(p_Lat_ini, '.', ','));
    Lon1 := To_Number(Replace(p_Lon_ini, '.', ','));
    Lat2 := To_Number(Replace(p_Lat_fin, '.', ','));
    Lon2 := To_Number(Replace(p_Lon_fin, '.', ','));
  
    v_distancia := Round((Nvl(v_rad, 0) *
                         Acos((Sin(Nvl(Lat1, 0) / v_GrausRad) * Sin(Nvl(Lat2, 0) / v_GrausRad)) +
                               (Cos(Nvl(Lat1, 0) / v_GrausRad) * Cos(Nvl(Lat2, 0) / v_GrausRad) *
                               Cos(Nvl(Lon2, 0) / v_GrausRad - Nvl(Lon1, 0) / v_GrausRad)))));
  
    Return v_distancia;
  
  End Distancia_cartesiana;

  /* Verifica se a ordem de carga é carona de acordo com regra definida, 2 OC no mesmo caminhão */
  Function check_carona(p_codemp     Number,
                        p_ordemcarga Number) Return Boolean Is
    veiculo Number;
    data    Date;
    carona  Varchar2(1);
    i       Int;
  Begin
  
    Begin
      Select o.codveiculo, o.dtinic, Nvl(o.ad_carona, 'N')
        Into veiculo, data, carona
        From tgford o
       Where o.codemp = p_codemp
         And o.ordemcarga = p_ordemcarga
         And o.temtransbordo = 'N';
    Exception
      When Others Then
        Return False;
    End;
  
    If carona = 'S' Then
      Return True;
    Else
    
      Select Count(*)
        Into i
        From (Select o.ordemcarga
                From tgford o
               Where codveiculo = veiculo
                 And dtinic = data
                 And codemp != p_codemp
                 And ordemcarga != p_ordemcarga
                 And o.temtransbordo = 'S'
              Union
              Select o.ordemcarga
                From tgford o
               Where codveiculo = veiculo
                 And dtinic = data
                 And codemp != p_codemp
                 And ordemcarga != p_ordemcarga
                 And o.ordemcargapai > 0
                 And o.ordemcargapai <> o.ordemcarga
                 And o.ordemcargapai <> p_ordemcarga);
    End If;
  
    If i > 0 Then
      Return True;
    Else
      Return False;
    End If;
  
  End check_carona;

  /* verifica se a modalidade de pagamento é "frete por peso", modalidade que considera
  o peso da carona sobre peso total da carga para definir o valor a ser pago */
  Function check_fretepeso(p_codemp     Number,
                           p_ordemcarga Number) Return Varchar2 Is
    ord tgford%Rowtype;
    i   Int;
    x   Int;
  Begin
  
    Begin
      Select *
        Into ord
        From tgford o
       Where o.codemp = p_codemp
         And o.ordemcarga = p_ordemcarga;
    Exception
      When no_data_found Then
        Return 'N';
    End;
  
    Select Count(*)
      Into i
      From tgford o
     Where o.codveiculo = ord.codveiculo
       And o.dtinic = ord.dtinic
       And o.codemp != ord.codemp
       And o.ordemcarga != ord.ordemcarga
       And o.temtransbordo = 'N';
  
    If i > 0 Then
      Select Count(*)
        Into x
        From tgford o
       Where o.ordemcarga = ord.ordemcargapai
         And o.temtransbordo = 'S';
    End If;
  
    If x > 0 Then
      Dbms_Output.Put_Line('frete por peso ');
      Return 'S';
    Else
      Return 'N';
    End If;
  
  End check_fretepeso;

  -- Autor: M. Rangel
  -- Objetivo: Buscar o cód. região de frete do parceiro percorrendo a hierarquia do cadastro de regiões 
  Function get_codregfrete(p_codparc Number) Return Number Is
    v_codreg    Number;
    v_codregfre Number;
    sql_stmt    Varchar2(4000);
    pivot_stmt  Varchar2(4000);
  
    c_cur Sys_Refcursor;
    c     Number;
  
  Begin
  
    Begin
      Select codreg
        Into v_codreg
        From tgfpar p
       Where p.codparc = p_codparc;
    Exception
      When no_data_found Then
        Return 0;
    End;
  
    Begin
      Select Substr(Sys_Connect_By_Path('' || codreg || '', ','), 2,
                    Length(Sys_Connect_By_Path('' || codreg || '', ',')))
        Into pivot_stmt
        From tsireg
       Where codreg = v_codreg
         And Rownum = 1
      Connect By Prior codreg = codregpai
       Start With codreg > 0;
    Exception
      When Others Then
        Return 0;
    End;
  
    --Dbms_Output.Put_Line(pivot_stmt);
  
    sql_stmt := 'Select codreg from tsireg where codreg in (' || pivot_stmt || ') order by 1 desc';
  
    --Dbms_Output.Put_Line(sql_stmt);
  
    Open c_cur For sql_stmt;
    Loop
      Exit When c_cur%Notfound;
      Fetch c_cur
        Into c;
      If v_codregfre Is Null Then
        Select ad_codregfre
          Into v_codregfre
          From tsireg
         Where codreg = c;
      Else
        Exit;
      End If;
    End Loop;
    Close c_cur;
    --Dbms_Output.Put_Line('Região de Frete: ' || v_codregfre);
  
    Return v_codregfre;
  
  Exception
    When Others Then
      Return 0;
  End get_codregfrete;

  /* Busca a distância total da ordem de carga */
  Function Get_distancia_total_oc(p_Codemp     Number,
                                  p_OrdemCarga Number) Return Float Is
    ponto_inicial Varchar2(50);
    ponto_final   Varchar2(50);
    v_Coord_Orig  Varchar2(50);
    v_Coord_Dest  Varchar2(50);
    v_CodParc     Number;
    v_km          Float;
    km_total      Float := 0;
    qtd_req       Number := 0;
  Begin
  
    /* Busca a localização do parceiro de origem da ordem de carga */
    Begin
      Select Replace(P.Latitude, ',', '.') || '%2C' || Replace(P.Longitude, ',', '.')
        Into ponto_inicial
        From Tgfpar P
        Join Tgford O
          On P.Codparc = O.Codparcorig
         And O.Codemp = p_Codemp
         And O.Ordemcarga = p_OrdemCarga
       Where P.Latitude Is Not Null
         And P.Longitude Is Not Null;
    Exception
      When No_data_found Then
        Raise;
    End;
  
    --percorre os parceiros da ordem de carga
    For Parc In (Select Codparc, Min(Sequencia) Sequencia, Coordenada
                   From (Select P.Codparc,
                                1 Sequencia,
                                Substr(Replace(P.Latitude, ',', '.'), 1, 9) || '%2C' ||
                                Substr(Replace(P.Longitude, ',', '.'), 1, 9) Coordenada
                           From Tgfpar P
                           Join Tgford O
                             On P.Codparc = O.Codparcorig
                            And O.Codemp = p_Codemp
                            And O.Ordemcarga = p_OrdemCarga
                          Where P.Latitude Is Not Null
                            And P.Longitude Is Not Null
                         Union
                         Select P.Codparc,
                                C.Seqcarga Sequencia,
                                Substr(Replace(P.Latitude, ',', '.'), 1, 9) || '%2C' ||
                                Substr(Replace(P.Longitude, ',', '.'), 1, 9)
                           From Tgfpar P, Tgfcab C
                          Where C.Codparc = P.Codparc
                            And C.Codemp = p_Codemp
                            And C.Ordemcarga = p_OrdemCarga
                            And P.Latitude Is Not Null
                            And P.Longitude Is Not Null)
                  Group By Codparc, Coordenada
                  Order By Sequencia)
    Loop
    
      v_CodParc := Parc.Codparc;
    
      If v_Coord_Orig Is Null Then
        v_Coord_Orig := Parc.Coordenada;
      Else
      
        If v_Coord_Dest Is Not Null Then
          v_Coord_Orig := v_Coord_Dest;
        End If;
      
      End If;
    
      If Parc.Sequencia > 1 Then
      
        If Parc.Coordenada Is Null Then
          Continue;
        End If;
      
        v_Coord_Dest := Parc.Coordenada;
      
        v_km := Get_distancia_xml(v_Coord_Orig, v_Coord_Dest);
      
        /*Dbms_Output.put_line(v_Coord_Orig || ' / ' || v_Coord_Dest || ' - ' || v_km);*/
      
        km_total := km_total + v_km;
      
        ponto_final := v_Coord_Dest;
      
      End If;
    
      qtd_req := qtd_req + 1;
    
    End Loop Parc;
  
    -- calcula a volta
    If ponto_final Is Not Null Then
    
      -- Para utilizar a mesma distância simulando ida direta,
      -- Para obter o mesmo valor do gmaps, inverter o ponto inicial/final
      v_km := Get_distancia_xml(ponto_inicial, ponto_final);
    
      /*Dbms_Output.put_line(ponto_inicial || ' / ' || ponto_final || ' - ' || v_km);*/
    
      km_total := km_total + v_km;
    End If;
  
    /*
    Dbms_Output.put_line('KM Total: ' || km_total);
    qtd_req := qtd_req + 1;
    Dbms_Output.put_line(qtd_req);
    */
  
    Return km_total;
  
  Exception
    When Others Then
      Raise;
  End Get_distancia_total_oc;

  /* 
  * Autor: Marcus Rangel
  * Objetivo: Procedure chamada pela procedure AD_STP_FRE_CALCVLROC_SF do botão de ação "Calcular Valores de Frete da OC",
  * a mesma executa a busca da distância e grava na tabela  AD_TSFRFV
  */
  Procedure Set_distancia_rota(p_codemp     Number,
                               p_OrdemCarga Number) Is
    v_Distancia Float;
    i           Int := 0;
  Begin
  
    Select Count(*)
      Into i
      From Ad_tsfrfv V
     Where V.Codemp = p_codemp
       And V.Ordemcarga = p_OrdemCarga;
  
    -- busca a distância total da rota
    v_Distancia := Get_distancia_total_oc(p_codemp, p_OrdemCarga);
  
    -- merge
    If i = 0 Then
      Insert Into Ad_tsfrfv
      Values
        (p_codemp, p_OrdemCarga, v_Distancia, 0);
    Else
      Update Ad_tsfrfv
         Set Distrota = v_Distancia
       Where Codemp = p_codemp
         And Ordemcarga = p_OrdemCarga;
    End If;
  
  End Set_distancia_rota;

  Function get_vlr_regfrete(p_codregfre Number,
                            p_codcat    Number,
                            p_distancia Float) Return Float Is
    v_vlrkm Float;
  Begin
    For r In (Select c.codregfre, c.descrregfre, r.codcat, r.dtvigor, r.vlrsaida, i.vlrkm, i.vlrfixo
                From ad_tsfrfc c
                Left Join ad_tsfrfr r
                  On c.codregfre = r.codregfre
                Left Join ad_tsfrfi i
                  On i.nurfr = r.nurfr
                 And i.codregfre = r.codregfre
               Where c.codregfre = p_codregfre
                 And p_distancia Between i.inicioint And i.finalint
                 And r.codcat = p_codcat
                 And r.dtvigor = (Select Max(dtvigor)
                                    From ad_tsfrfr R2
                                   Where r2.Codregfre = r.codregfre
                                     And R2.CODCAT = r.codcat
                                     And r2.Dtvigor <= Sysdate))
    Loop
    
      If r.vlrfixo = 'S' Then
        v_vlrkm := Nvl(r.vlrsaida, 0) + r.vlrkm;
      Else
        v_vlrkm := Nvl(r.vlrsaida, 0) + (r.vlrkm * p_distancia);
      End If;
    
    End Loop;
  
    Return Nvl(v_vlrkm, 0);
  
  End get_vlr_regfrete;

  Function get_vlr_pedagio(p_codemp     Number,
                           p_ordemcarga Number,
                           p_CodCat     Number) Return Float Is
    v_vlrPedagio Float;
  Begin
    Select Nvl(Cat.Vlrpedagio, 0) * c.qtdeixos
      Into v_vlrPedagio
      From Ad_tsfrfpcat Cat
      Join ad_tsfcat c
        On c.codcat = cat.codcat
      Join Ad_tsfrfpcid Cid
        On cid.codpraca = cat.codpraca
      Join Ad_tsfrfp P
        On P.Codpraca = Cat.Codpraca
     Where Nvl(P.Ativo, 'N') = 'S'
       And Cat.Codcat = p_CodCat
       And Cat.Dtvigor = (Select Max(C2.Dtvigor)
                            From Ad_tsfrfpcat C2
                           Where C2.Codpraca = Cat.Codpraca
                             And C2.Codcat = Cat.Codcat
                             And C2.Dtvigor <= Sysdate)
       And Exists (Select 1
              From Tgfpar Par, Tgfcab Cab
             Where Par.Codparc = Cab.Codparc
               And Cab.Codemp = p_codemp
               And Cab.Ordemcarga = p_ordemcarga
               And Par.Codcid = Cid.Codcid);
  
    Return v_vlrPedagio;
  
  Exception
    When Others Then
      Return 0;
  End get_vlr_pedagio;

  --M. Rangel
  /* Função que retorna o valor do frete de uma ordem de carga  */
  Function Get_valor_oc_regfrete(p_codemp     Number,
                                 p_ordemcarga Number) Return Float Is
    v_CodVeiculo Number;
    v_DistRota   Float;
    v_CodCat     Number;
    valor_atual  Float := 0;
    valor_final  Float := 0;
    qtd_eixos    Number;
    vlr_pedagio  Float := 0;
    ErrMsg       Varchar2(4000);
    Error Exception;
  
  Begin
    /*
    * Autor: Marcus Rangel
    * Objetivo: Função que retorna o valor da ordem de carga, baseando-se
    * nos parametros definidos da tela de regiões de frete e praças de 
    * pedágio
    */
  
    --Busca os dados do veículo da ordem de carga
    Begin
      Select O.Codveiculo, V.Ad_codcat, Nvl(V.Ad_qtdeixos, 0)
        Into v_CodVeiculo, v_CodCat, qtd_eixos
        From Tgford O
        Join Tgfvei V
          On O.Codveiculo = V.Codveiculo
       Where O.Codemp = p_codemp
         And O.Ordemcarga = p_ordemcarga;
    
      If v_CodCat Is Null Or qtd_eixos Is Null Then
        ErrMsg := 'Não encontramos a categoria ou a quantidade de eixos do veículo ' ||
                  v_CodVeiculo;
        Raise Error;
      End If;
    
      Dbms_Output.Put_Line('Veículo: ' || v_CodVeiculo || ', Cat: ' || v_CodCat || ', Eixos: ' ||
                           qtd_eixos);
    
    End;
  
    -- percorre as regiões da ordem de carga
    /*For C_reg In (Select Distinct P.Ad_codregfre Codregfre
     From Tgfpar P
     Join Tgfcab C
       On C.Codparc = P.Codparc
    Where C.Codemp = p_codemp
      And C.Ordemcarga = p_ordemcarga)*/
  
    For c_reg In (Select p.codregfre
                    From ad_tsfrocc c
                    Join ad_tsfrocp p
                      On c.numrocc = p.numrocp
                   Where c.codemp = p_codemp
                     And c.ordemcarga = p_ordemcarga
                   Group By p.codregfre)
    Loop
      Dbms_Output.Put_Line('Regiao de Frete: ' || c_reg.codregfre);
    
      /*Busca a distância da rota pela localização dos parceiros*/
    
      Begin
        Select V.Distrota
          Into v_DistRota
          From Ad_tsfrfv V
         Where V.Codemp = p_codemp
           And V.Ordemcarga = p_ordemcarga;
      Exception
        When No_data_found Then
          v_DistRota := Get_distancia_total_oc(p_codemp, p_ordemcarga);
      End;
    
      -- preço da região
      Begin
        valor_atual := get_vlr_regfrete(c_reg.codregfre, v_CodCat, v_DistRota);
      End;
    
    End Loop C_reg;
  
    If soma_pedagio = 'S' Then
      /*Busca o valor do pedágio por cidade / categoria*/
      vlr_pedagio := get_vlr_pedagio(p_codemp, p_ordemcarga, v_CodCat);
      valor_final := valor_atual + vlr_pedagio;
    Else
      valor_final := valor_atual;
    End If;
  
    Return valor_final;
  
  Exception
    When Error Then
      Raise_Application_Error(-20105, ErrMsg);
    When Others Then
      Raise;
  End Get_valor_oc_regfrete;

  Procedure Set_valor_rota(p_codemp     Number,
                           p_OrdemCarga Number) Is
    v_Valor Float;
    i       Int := 0;
  Begin
  
    Select Count(*)
      Into i
      From Ad_tsfrfv V
     Where V.Codemp = p_codemp
       And V.Ordemcarga = p_OrdemCarga;
  
    -- busca o valor da rota de acordo com a região de frete
    If check_carona(p_codemp, p_ordemcarga) Then
      Null;
    Else
      v_Valor := Get_valor_oc_regfrete(p_codemp, p_OrdemCarga);
    End If;
  
    -- merge
    If i = 0 Then
      Insert Into Ad_tsfrfv
      Values
        (p_codemp, p_OrdemCarga, 0, v_Valor);
    Else
      Update Ad_tsfrfv
         Set Vlrrota = v_Valor
       Where Codemp = p_codemp
         And Ordemcarga = p_OrdemCarga;
    End If;
  
  End Set_valor_rota;

  -- M. Rangel - Calcula o preço do frete para ordens de cargas caronas
  Procedure set_dist_vlr_carona(p_codemp     Number,
                                p_ordemcarga Number,
                                p_distRota   Float) Is
    r1         tgford%Rowtype;
    v_distRota Float := p_distrota;
    v_vlrKm    Float;
    v_Peso     Float;
  
    Type type_rec_oc Is Record(
      codemp   Number,
      ordcarga Number,
      peso     Float);
  
    Type type_tab_oc Is Table Of type_rec_oc;
    t type_tab_oc := type_tab_oc();
    i Pls_Integer;
  
    soma_pedagio Varchar2(1);
  Begin
  
    -- verifica se OC é carona
    If Not check_carona(p_codemp, p_ordemcarga) Then
      Return;
    End If;
  
    Begin
      Select *
        Into r1
        From tgford
       Where codemp = p_codemp
         And ordemcarga = p_ordemcarga;
    Exception
      When Others Then
        Raise;
    End;
  
    -- percorre as OC com mesmo veículo e data 
    For c_ord In (Select o.codemp,
                         o.ordemcarga,
                         o.codveiculo,
                         o.codparcorig,
                         o.codparctransp,
                         v.ad_codcat As codcat,
                         o.dtinic,
                         Case
                            When o.ordemcargapai > 0 Then
                             'S'
                            Else
                             'N'
                          End As Carona,
                         Nvl(o.ad_vlrfreteproppeso, 'N') As fretepeso
                    From tgford o
                    Join tgfvei v
                      On o.codveiculo = v.codveiculo
                   Where o.codveiculo = r1.codveiculo
                     And o.codparctransp = r1.codparctransp
                     And o.dtinic = r1.dtinic
                   Order By o.codemp)
    -- vai começar pela empresa 1 devido o order by
    Loop
      t.extend;
      i := t.last;
    
      t(i).codemp := c_ord.codemp;
      t(i).ordcarga := c_ord.ordemcarga;
    
      -- percorre as regiões que estão dentro da ordem de carga
      For c_reg In (Select p.codregfre,
                           Count(Distinct p.codparc) qtdclientes,
                           Count(Distinct p.codcid) qtdcidades,
                           Case
                              When Count(Distinct p.codcid) = 1 Then
                               'S'
                              Else
                               'N'
                            End As mesmodestino,
                           Sum(p.peso) peso
                      From ad_tsfrocp p
                    --tgfcab c Join tgfpar p On c.codparc = p.codparc
                     Where p.codemp = c_ord.codemp
                       And p.ordemcarga = c_ord.ordemcarga
                    --And p.tipmov = 'P'
                     Group By p.codregfre)
      Loop
      
        t(i).peso := c_reg.peso;
      
        --pela ordem, quando entrar na regra da carona a variável já vai conter o peso total
        v_peso := Nvl(v_peso, 0) + c_reg.peso;
      
        -- percorre as categorias dentro das regiões
        For c_cat In (Select *
                        From ad_tsfrfr r
                       Where r.codregfre = c_reg.codregfre
                         And r.codcat = c_ord.CodCat)
        Loop
          -- Lê as regras das caronas nas categorias
          For c_car In (Select *
                          From ad_tsfrfa a
                          Join ad_tsfrfr r
                            On r.nurfr = a.nurfr
                           And r.codregfre = a.codregfre
                         Where a.codregfre = c_cat.codregfre
                           And a.nurfr = c_cat.nurfr
                           And r.codcat = c_cat.codcat
                           And a.codemp = c_ord.codemp
                           And a.codparcorig = c_ord.codparcorig
                           And c_reg.qtdclientes Between a.qtdminclientes And a.qtdmaxclientes
                           And Nvl(a.mesmodestino, 'N') = c_reg.mesmodestino)
          
          Loop
          
            -- verifica se a ordem de carga se enquadra no pagamento por peso proporcional
            If c_ord.fretepeso Is Null Then
              c_ord.fretepeso := check_fretepeso(p_codemp, p_ordemcarga);
            End If;
          
            /*km fixo*/
            If c_ord.carona = 'S' And c_ord.fretepeso = 'N' And c_car.aplicacao = 'F' Then
              v_distRota := c_car.valor;
              v_vlrKm    := (v_distrota *
                            get_vlr_regfrete(c_car.codregfrevlr, c_cat.Codcat, c_car.valor));
            
              /*peso*/
            Elsif c_ord.carona = 'S' And c_ord.fretepeso = 'N' And c_car.aplicacao = 'P' Then
              v_vlrKm := (c_reg.peso / 1000) * c_car.valor;
            
              /*km*/
            Elsif c_ord.carona = 'S' And c_ord.fretepeso = 'N' And c_car.aplicacao = 'K' Then
              v_vlrKm := (v_distrota *
                         get_vlr_regfrete(c_car.codregfrevlr, c_cat.Codcat, c_car.valor));
            
              /*valor fixo*/
            Elsif c_ord.carona = 'S' And c_ord.fretepeso = 'N' And c_car.aplicacao = 'VF' Then
              v_vlrKm := c_car.valor;
            
              /*Peso proporcional Rota*/
            Elsif c_ord.carona = 'S' And c_ord.fretepeso = 'S' And c_car.aplicacao = 'PP' Then
            
              Declare
                peso_total Float := 0;
                valor_rota Float;
                dist_rota  Float;
              Begin
                For z In t.first .. t.last
                Loop
                  If t(z).codemp = 1 Then
                  
                    Select v.distrota
                      Into dist_rota
                      From ad_tsfrocc v
                     Where v.codemp = t(z).codemp
                       And v.ordemcarga = t(z).ordcarga;
                  
                    valor_rota := get_vlr_regfrete(c_car.codregfrevlr, c_cat.codcat, dist_rota);
                  
                    If Nvl(soma_pedagio, 'N') = 'S' Then
                      valor_rota := valor_rota +
                                    get_vlr_pedagio(t(z).codemp, t(z).ordcarga, c_cat.codcat);
                    End If;
                  
                    Begin
                      Merge Into ad_tsfrfv r
                      Using (Select t(z).codemp As codemp,
                                    t(z).ordcarga As ordemcarga,
                                    dist_rota As distrota,
                                    ((valor_rota / v_peso) * t(z).peso) vlrrota
                               From dual) s
                      On (r.codemp = s.codemp And r.ordemcarga = s.ordemcarga)
                      When Matched Then
                        Update
                           Set r.distrota = s.distrota, r.vlrrota = s.vlrrota
                      When Not Matched Then
                        Insert
                        Values
                          (s.codemp, s.ordemcarga, s.distrota, s.vlrrota);
                    Exception
                      When Others Then
                        Raise;
                    End;
                  
                    Begin
                      Update ad_tsfrocc
                         Set vlrrota =
                              ((valor_rota / v_peso) * t(z).peso)
                       Where codemp = t(z).codemp
                         And ordemcarga = t(z).ordcarga;
                    Exception
                      When Others Then
                        Raise;
                    End;
                  
                  End If;
                  peso_total := peso_total + t(z).peso;
                  v_vlrKm    := ((valor_rota / v_peso) * t(z).peso);
                End Loop;
              
                --valor_kilo := valor_rota / peso_total;
              
                /*Begin
                  Select distrota
                    Into v_distRota
                    From ad_tsfrocc c
                   Where c.codemp = c_ord.codemp
                     And c.ordemcarga = c_ord.ordemcarga;
                Exception
                  When Others Then
                    Raise;
                End;*/
              
                --v_vlrKm := v_distRota * valor_kilo;
              
              End;
            
              /*Peso proporcional Transbordo*/
            Elsif c_ord.carona = 'S' And c_ord.fretepeso = 'S' And c_car.aplicacao = 'PT' Then
            
              Declare
                peso_carga  Float := 0;
                peso_carona Float := 0;
              Begin
                For z In t.first .. t.last
                Loop
                  If t(z).codemp = 1 Then
                    peso_carga := peso_carga + t(z).peso;
                  Elsif t(z).codemp != 1 Then
                    peso_carona := peso_carona + t(z).peso;
                  End If;
                End Loop;
              
                v_vlrKm := Round(peso_carona / peso_carga, 2) * c_car.valor;
              
              End;
            
            End If;
          
            If Nvl(v_distRota, 0) > 0 And Nvl(v_vlrKm, 0) > 0 Then
            
              Begin
              
                If Nvl(soma_pedagio, 'N') = 'S' Then
                  v_vlrKm := v_vlrKm +
                             get_vlr_pedagio(c_ord.codemp, c_ord.ordemcarga, c_cat.codcat);
                End If;
              
                Merge Into ad_tsfrfv r
                Using (Select c_ord.codemp     As codemp,
                              c_ord.ordemcarga As ordemcarga,
                              v_distRota       As distrota,
                              v_vlrKm          As vlrrota
                         From dual) d
                On (r.codemp = d.codemp And r.ordemcarga = d.ordemcarga)
                When Matched Then
                  Update
                     Set r.distrota = d.distrota, r.vlrrota = d.vlrrota
                When Not Matched Then
                  Insert
                    (codemp, ordemcarga, distrota, vlrrota)
                  Values
                    (d.codemp, d.ordemcarga, d.distrota, d.vlrrota);
              
                Begin
                  Update ad_tsfrocc
                     Set vlrrota = v_vlrKm
                   Where codemp = p_codemp
                     And ordemcarga = p_ordemcarga;
                Exception
                  When Others Then
                    Raise;
                End;
              
                Dbms_Output.Put_Line('Distância: ' || ' | ' || v_distRota);
                Dbms_Output.Put_Line('Valor Km: ' || ' | ' || v_vlrKm);
              
              Exception
                When Others Then
                  Raise;
              End;
            
            End If;
          
          End Loop c_car;
        
        End Loop c_cat;
      
      End Loop c_reg;
    
    End Loop c_ord;
  
  End set_dist_vlr_carona;

  Procedure Atualiza_coord_parc(p_Codparc Number,
                                p_coord   Out Varchar2,
                                p_Link    Out Varchar2,
                                p_Errmsg  Out Varchar2) Is
    v_Endereco Varchar2(1000);
    req        Utl_http.req;
    resp       Utl_http.resp;
    xml        Varchar2(32767);
    i          Int := 1;
    x          Xmltype;
    status     Varchar2(100);
    url        Varchar2(1000);
    lat        Varchar2(200);
    lng        Varchar2(200);
  Begin
    /*
    * Autor: Marcus Rangel
    * Objetivo: Método que busca a latitude e a longitude do parceiro
    * no google maps, similar ao botão mapas no cadastro de parceiro, 
    * porém, pode ser usado para operações em lote.
    */
    <<Monta_pesquisa>>
  
    If i = 1 Then
    
      /*pesquisa sem o nome e sem o cep*/
      Select E.Tipo || '+' || Replace(E.Nomeend, ' ', '+') || ',' ||
             Decode(P.Numend, 'SN', '', P.Numend || ',') || /* Replace(p.complemento, ' ', '+') || ',' ||*/
             Replace(Ltrim(Rtrim(B.Nomebai)), ' ', '+') || ',' ||
             Replace(Ltrim(Rtrim(C.Nomecid)), ' ', '+') || '-' || U.Uf
        Into v_Endereco
        From Tgfpar P
        Join Tsiend E
          On P.Codend = E.Codend
        Join Tsibai B
          On P.Codbai = B.Codbai
        Join Tsicid C
          On P.Codcid = C.Codcid
        Join Tsiufs U
          On C.Uf = U.Coduf
       Where P.Codparc = p_Codparc;
    
    Elsif i = 2 Then
    
      /*pesquisa sem o nome do parceiro com cep*/
      Select E.Tipo || '+' || Replace(E.Nomeend, ' ', '+') || ',' || P.Numend || ',' || /*Replace(p.complemento, ' ', '+') || ',' ||*/
             Replace(Ltrim(Rtrim(B.Nomebai)), ' ', '+') || ',' ||
             Replace(Ltrim(Rtrim(C.Nomecid)), ' ', '+') || '-' || U.Uf || ', CEP+' || P.Cep
        Into v_Endereco
        From Tgfpar P
        Join Tsiend E
          On P.Codend = E.Codend
        Join Tsibai B
          On P.Codbai = B.Codbai
        Join Tsicid C
          On P.Codcid = C.Codcid
        Join Tsiufs U
          On C.Uf = U.Coduf
       Where P.Codparc = p_Codparc;
    
    Elsif i = 3 Then
    
      /*pesquisa pelo nome do parceiro e endereço completo */
      Select Replace(Replace(Ltrim(Rtrim(Substr(P.Nomeparc, 1,
                                                 Case
                                                    When Instr(P.Nomeparc, '-', -1, 1) - 1 = -1 Then
                                                     Length(P.Nomeparc)
                                                    Else
                                                     Instr(P.Nomeparc, '-', -1, 1) - 1
                                                  End))), ' ', '+') || ',' || E.Tipo || '+' ||
                      Replace(E.Nomeend, ' ', '+') || ',' || P.Numend || ',' || /*Replace(p.complemento, ' ', '+') || ',' || */
                      Replace(Ltrim(Rtrim(B.Nomebai)), ' ', '+') || ',' ||
                      Replace(Ltrim(Rtrim(C.Nomecid)), ' ', '+') || '-' || U.Uf, ',,', ',')
        Into v_Endereco
        From Tgfpar P
        Join Tsiend E
          On P.Codend = E.Codend
        Join Tsibai B
          On P.Codbai = B.Codbai
        Join Tsicid C
          On P.Codcid = C.Codcid
        Join Tsiufs U
          On C.Uf = U.Coduf
       Where P.Codparc = p_Codparc;
    
    Elsif i = 4 Then
    
      /*pesquisa pelo nome do parceiro com bairro, cidade e uf */
      Select Replace(Replace(Ltrim(Rtrim(Substr(P.Nomeparc, 1,
                                                 Case
                                                    When Instr(P.Nomeparc, '-', -1, 1) - 1 = -1 Then
                                                     Length(P.Nomeparc)
                                                    Else
                                                     Instr(P.Nomeparc, '-', -1, 1) - 1
                                                  End))), ' ', '+') || ',' ||
                      Replace(Ltrim(Rtrim(B.Nomebai)), ' ', '+') || ',' ||
                      Replace(Ltrim(Rtrim(C.Nomecid)), ' ', '+') || '-' || U.Uf, ',,', ',')
        Into v_Endereco
        From Tgfpar P
        Join Tsiend E
          On P.Codend = E.Codend
        Join Tsibai B
          On P.Codbai = B.Codbai
        Join Tsicid C
          On P.Codcid = C.Codcid
        Join Tsiufs U
          On C.Uf = U.Coduf
       Where P.Codparc = p_Codparc;
    Else
      p_Errmsg := 'Nenhum Resultado encontrado';
      Return;
    End If;
  
    url := 'https://maps.googleapis.com/maps/api/geocode/xml?address=' || v_Endereco || '&key=' ||
           Get_tsipar_texto('CHAVEGOOGLEMAP');
  
    Utl_http.Set_wallet('file:/u01/app/oracle/admin/orcl/geo_wallet', 'Sf29zx47');
  
    req := Utl_http.Begin_request(url);
    Utl_http.Set_header(req, 'User-Agent', 'Mozilla/4.0');
    resp := Utl_http.Get_response(req);
    Utl_http.Read_text(resp, xml, 32767);
    x := Xmltype(xml);
  
    status := x.Extract('/GeocodeResponse/status/text()').Getstringval;
  
    If Nvl(status, 'N') = 'OK' Then
    
      lat := Substr(x.Extract('/GeocodeResponse/result/geometry/location/lat/text()').Getstringval,
                    1, 11);
      lng := Substr(x.Extract('/GeocodeResponse/result/geometry/location/lng/text()').Getstringval,
                    1, 11);
    
      If lat Is Not Null And lng Is Not Null Then
      
        Begin
          Update Tgfpar
             Set Latitude = lat, Longitude = lng
           Where Codparc = p_Codparc;
        
        Exception
          When Others Then
            Raise;
        End;
      
      End If;
    
    Elsif Nvl(status, 'N') = 'ZERO_RESULTS' Then
      i   := i + 1;
      xml := Null;
      url := Null;
      Utl_http.End_request(req);
      Utl_http.End_response(resp);
      Goto Monta_pesquisa;
    End If;
  
    Utl_http.End_request(req);
    Utl_http.End_response(resp);
    xml := Null;
  
    p_coord := lat || ',' || lng;
    p_Link  := 'https://www.google.com.br/maps/place/' || lat || ',' || lng;
  
  Exception
    When Utl_http.End_of_body Then
      Utl_http.End_response(resp);
      Utl_http.End_request(req);
      p_Errmsg := 'Serviço inalcançável, tente novamente.';
    When Others Then
      p_Errmsg := Sqlerrm;
      Utl_http.End_response(resp);
      Utl_http.End_request(req);
  End Atualiza_coord_parc;

  Procedure Grava_coordenadas(p_Coord_Orig Varchar2,
                              p_Coord_Dest Varchar2,
                              p_Distancia  Float,
                              p_ErrMsg     Out Varchar2) Is
  Begin
    Insert Into Ad_tsfrfdg
      (Dtalter, Coordorig, Coorddest, distancia)
    Values
      (Sysdate, p_Coord_Orig, p_Coord_Dest, p_Distancia);
  
    Commit;
  
  Exception
    When Dup_val_on_index Then
      Return;
    When Others Then
      p_ErrMsg := Sqlerrm;
      Return;
  End Grava_coordenadas;

  Function Get_distancia_xml(v_Coord_Orig Varchar2,
                             v_Coord_Dest Varchar2) Return Float Is
    v_url        Varchar2(1000);
    header       Varchar2(100);
    key          Varchar2(100);
    req          Utl_http.req;
    resp         Utl_http.resp;
    conteudo_xml Varchar2(32767);
    status       Varchar2(100);
    status_row   Varchar2(100);
    v_xml        Xmltype;
    v_KmChar     Varchar2(10);
    v_km         Float;
    un           Char(2);
    ErrMsg       Varchar2(4000);
    Error Exception;
  Begin
  
    -- pesquisa na tabela de distâncias por coordenadas
    Begin
      Select distancia
        Into v_km
        From Ad_tsfrfdg D
       Where D.Coordorig = v_Coord_Orig
         And D.Coorddest = v_Coord_Dest
         And D.Dtalter = (Select Max(D2.Dtalter)
                            From Ad_tsfrfdg D2
                           Where D2.Dtalter <= Sysdate
                             And D2.Coordorig = v_Coord_Orig
                             And D2.Coorddest = v_Coord_Dest);
    
    Exception
      When No_data_found Then
        v_km := 0;
      When Others Then
        v_km := 0;
    End;
  
    If v_km Is Not Null And v_km > 0 Then
      Return v_km;
    Else
    
      If resp.Private_hndl Is Not Null Then
        Utl_http.End_response(resp);
      End If;
    
      If req.Private_hndl Is Not Null Then
        Utl_http.End_request(req);
      End If;
    
      Utl_http.Set_response_error_check(True);
      Utl_http.Set_detailed_excp_support(True);
    
      --utl_http.set_wallet(Path => 'file:/u01/app/oracle/admin/orcl/wallet', password => '@Sf29zx47#'); --dev
      --Utl_http.Set_wallet('file:/u01/app/oracle/admin/orcl/geo_wallet', 'Sf29zx47');
      Utl_http.Set_wallet('file:/u01/app/oracle/admin/orcl/geo_wallet', 'sf29zx47');
      header := 'https://maps.googleapis.com/maps/api/distancematrix/xml?';
      key    := '&key=' || Get_tsipar_texto('CHAVEGOOGLEMAP');
      v_url  := header || 'origins=' || v_Coord_Orig || '&destinations=' || v_Coord_Dest ||
                '&mode=driving&language=pt-BR&sensor=false' || key;
      v_url  := Replace(v_url, ' ', '');
      req    := Utl_http.Begin_request(v_url);
      Utl_http.Set_header(req, 'User-Agent', 'Mozilla/4.0');
      resp := Utl_http.Get_response(req);
      Utl_http.Read_text(resp, conteudo_xml, 32767);
      v_xml := Xmltype(conteudo_xml);
    
      status := v_xml.Extract('/DistanceMatrixResponse/status/text()').Getstringval;
    
      If status != 'OK' Then
        ErrMsg := 'Erro ao pesquisar coordenadas - ' || status;
        Raise Error;
      End If;
    
      status_row := v_xml.Extract('/DistanceMatrixResponse/row/element/status/text()').Getstringval;
    
      If status_row = 'ZERO_RESULTS' Or status_row = 'NOT_FOUND' Then
        v_km := 0;
      Else
        v_km     := To_Number(v_xml.Extract('/DistanceMatrixResponse/row/element/distance/value/text()')
                              .Getstringval);
        v_KmChar := Upper(v_xml.Extract('/DistanceMatrixResponse/row/element/distance/text/text()')
                          .Getstringval);
        un       := Rtrim(Ltrim(Upper(Substr(v_KmChar, Instr(v_KmChar, ' ', 1, 1), Length(v_KmChar)))));
      
        v_km := Case
                  When v_km > 0 And un = 'KM' Then
                   v_km / 1000
                  When v_km > 0 And un = 'M' Then
                   v_km / 100
                  Else
                   0
                End;
      End If;
    
      Utl_http.End_request(req);
      Utl_http.End_response(resp);
    
      --grava as coordenadas na tabela de coordenadas TSFRFDG
      Grava_coordenadas(v_Coord_Orig, v_Coord_Dest, v_km, ErrMsg);
    
      If ErrMsg Is Not Null Then
        --ad_set.insere_msglog('Erro ao gravar distância entre coordanadas. ' || ErrMsg);
        Raise Error;
      End If;
    
    End If;
    --Dbms_Output.put_line('request google');
  
    Return v_km;
  
  Exception
    When Error Then
    
      If resp.Private_hndl Is Not Null Then
        Utl_http.End_response(resp);
      End If;
    
      If req.Private_hndl Is Not Null Then
        Utl_http.End_request(req);
      End If;
    
      ErrMsg := ErrMsg || ' - ' || Sqlerrm;
    
      Raise_Application_Error(-20105, ErrMsg);
    
    When Others Then
      Utl_http.End_response(resp);
      Utl_http.End_request(req);
      Raise;
  End Get_distancia_xml;

  /*Calcula a sequencia da ordem de carga pela distância entre parceiros*/
  Procedure Set_sequencia_rota(p_Codemp     Number,
                               p_OrdemCarga Number,
                               p_ErrMsg     Out Varchar2) Is
    v_Count        Int;
    v_CodPacrOrig  Number;
    v_CoordOrig    Varchar2(25);
    v_Distancia    Float;
    v_DisTotal     Float := 0;
    ponto_final    Varchar2(25);
    l_dist_tab     Ad_type_fre_disttable := Ad_type_fre_disttable();
    l_dist_tab_ord Ad_type_fre_disttable := Ad_type_fre_disttable();
    x              Int;
    v_UltSeq       Int;
    l_rec_seq      Ad_type_of_number := Ad_type_of_number();
    l_Idx          Int;
  
    Erro_valor Exception;
    Pragma Exception_Init(Erro_valor, -06502);
  
  Begin
  
    -- Verifica a qtde de registros na OC, usado no loop
    Select Count(Distinct Codparc)
      Into v_Count
      From Tgfcab
     Where Codemp = p_Codemp
       And Ordemcarga = p_OrdemCarga
       And Tipmov = 'V'
       And Statusnota = 'L'
       And Seqcarga = 0;
  
    -- verifica se existe origem definida pelo usuário 
    Select Nvl(Max(Seqcarga), 0)
      Into v_UltSeq
      From Tgfcab
     Where Codemp = p_Codemp
       And Ordemcarga = p_OrdemCarga
       And Tipmov = 'V'
       And Statusnota = 'L'
       And Nvl(Seqcarga, 0) > 0;
  
    --- define quem é o parceiro inicio da OC
    If Nvl(v_UltSeq, 0) > 0 Then
      Select P.Codparc, P.Latitude || '%2C' || P.Longitude Coordparc
        Into v_CodPacrOrig, v_CoordOrig
        From Tgfcab C, Tgfpar P
       Where P.Codparc = C.Codparc
         And C.Codemp = p_Codemp
         And C.Ordemcarga = p_OrdemCarga
         And c.tipmov = 'V'
         And c.statusnota = 'L'
         And Nvl(C.Seqcarga, 0) = v_UltSeq;
    Else
      Select P.Codparc, P.Latitude || '%2C' || P.Longitude Coordparc
        Into v_CodPacrOrig, v_CoordOrig
        From Tgfpar P, Tgford O
       Where P.Codparc = O.Codparcorig
         And O.Codemp = p_Codemp
         And O.Ordemcarga = p_OrdemCarga;
    End If;
  
    -- percorre as notas buscando os parceiros
    For i In 1 .. v_Count
    Loop
      -- limpa a coleção
      l_dist_tab.Delete;
    
      -- inner loop para preencher os demais valores da coleção
      -- não rodou com bulk, devido a proc dentro do object type, ordem de exceução
      For C In (Select Distinct P.Codparc,
                                To_Char(Substr(P.Latitude, 1, 9) || '%2C' ||
                                        Substr(P.Longitude, 1, 9)) Coord
                  From Tgfpar P, Tgfcab C
                 Where C.Codparc = P.Codparc
                   And C.Codemp = p_Codemp
                   And C.Ordemcarga = p_OrdemCarga
                   And C.Tipmov = 'V'
                   And C.Statusnota = 'L'
                   And Nvl(C.Seqcarga, 0) = 0
                   And P.Codparc Not In (Select *
                                           From Table(l_rec_seq))
                 Order By 1)
      Loop
        v_Distancia := Ad_pkg_fre.Get_distancia_xml(v_CoordOrig, C.Coord);
        l_dist_tab.Extend;
        x := l_dist_tab.Last;
        l_dist_tab(x) := Ad_type_fre_distobject(C.Codparc, C.Coord, v_Distancia);
      End Loop;
    
      -- ordena a coleção pela menor distância  
      Select Cast(Multiset (Select Codparc, Coord, distancia
                     From Table(l_dist_tab)
                    Order By distancia) As Ad_type_fre_disttable)
        Into l_dist_tab_ord
        From Dual;
    
      l_rec_seq.Extend;
    
      l_Idx := l_rec_seq.Last;
    
      l_rec_seq(l_Idx) := l_dist_tab_ord(1).Codparc;
    
      v_CodPacrOrig := l_dist_tab_ord(1).Codparc;
    
      v_CoordOrig := l_dist_tab_ord(1).Coord;
    
      ponto_final := l_dist_tab_ord(1).Coord;
    
      v_DisTotal := v_DisTotal + l_dist_tab_ord(1).distancia;
    
    End Loop;
  
    -- atualiza as notas da OC
    For Z In l_rec_seq.First .. l_rec_seq.Last
    Loop
      Dbms_Output.Put_Line(Z || ' - ' || l_rec_seq(Z));
    
      Begin
        Update Tgfcab
           Set Seqcarga = Z + v_UltSeq
         Where Ordemcarga = p_OrdemCarga
           And Codemp = p_Codemp
           And Tipmov = 'V'
           And Statusnota = 'L'
           And Codparc = l_rec_seq(Z);
      
      Exception
        When Others Then
          p_ErrMsg := '(' || l_rec_seq(Z) || ') ' || Sqlerrm;
          --Raise;
          Return;
      End;
    
    End Loop;
  
  Exception
    When Others Then
      Raise;
      /*When Erro_valor Then
      p_ErrMsg := 'Problema na informação contida na sequência de Entrega';*/
  
  End Set_sequencia_rota;

  --M. Rangel
  /*busca o valor do evento de transporte, o nome coincide com o nome usado no construtor 
  de fórmula para ser utilizado dinamicamente*/
  Function ocevento(p_codveiculo Number,
                    p_codevento  Number) Return Float Is
    VlrEvento Float;
  Begin
    Begin
      Select valor
        Into VlrEvento
        From TGFEVEVEI eve
       Where eve.codveiculo = p_codveiculo
         And eve.codevento = p_codevento
         And eve.dtref = (Select Max(dtref)
                            From tgfevevei i
                           Where i.codveiculo = eve.codveiculo
                             And i.codevento = eve.codevento
                             And i.dtref < Sysdate);
    Exception
      When Others Then
        VlrEvento := 0;
    End;
  
    Return VlrEvento;
  End ocevento;

  --M. Rangel
  /* Calcula o valor do frete utilzando as fórmulas de frete, simulando o processo nativo do sistema*/
  Function get_vlrfrete_formula(p_Nunota     Number,
                                p_codemp     Number,
                                p_codparc    Number,
                                p_OrdemCarga Number,
                                p_CodVeiculo Number) Return Float Is
    o tgford%Rowtype;
    v tgfvei%Rowtype;
  
    Type type_totais Is Record(
      distancia Float,
      valor     Float);
  
    totais type_totais;
  
    v_formula Varchar2(4000);
  
  Begin
  
    Select *
      Into v
      From tgfvei
     Where codveiculo = p_codveiculo;
  
    Select *
      Into o
      From tgford
     Where codemp = p_codemp
       And ordemcarga = p_ordemcarga;
  
    -- distancia
    totais.distancia := ad_pkg_fre.Distancia_entre_parceiros(o.codparcorig, p_codparc) * 2;
  
    If o.tipcalcfrete = 1 Then
    
      Begin
        Select Lower(f.formula)
          Into v_formula
          From tsifor f
         Where tipform = 'F'
           And codform = v.codformfrete;
      Exception
        When no_data_found Then
          Raise;
      End;
    
      v_formula := Replace(v_formula, 'totais.distancia',
                           Replace(To_Char(totais.distancia), ',', '.'));
      v_formula := Replace(v_formula, 'ocevento(', 'ad_pkg_fre.ocevento(' || v.codveiculo || ',');
    
      Dbms_Output.Put_Line('Select ' || v_formula || ' from dual');
    
      Execute Immediate 'Select ' || v_formula || ' from dual'
        Into totais.valor;
    
      Dbms_Output.Put_Line(v_formula);
    
    End If;
  
    Dbms_Output.Put_Line(totais.valor);
    Return totais.valor;
  
  End get_vlrfrete_formula;

  --M. Rangel
  /* Método para realizar a atualização do valor do frete no pedido/nota */
  Procedure set_vlrfrete_formula(p_Nunota     Number,
                                 p_codemp     Number,
                                 p_codparc    Number,
                                 p_OrdemCarga Number,
                                 p_codveiculo Number,
                                 p_errmsg     Out Varchar2) Is
    valorFrete Float;
  Begin
    valorFrete := get_vlrfrete_formula(p_Nunota, p_codemp, p_codparc, p_OrdemCarga, p_CodVeiculo);
  
    Begin
      Update tgfcab
         Set vlrfrete = valorFrete
       Where nunota = p_nunota;
    Exception
      When Others Then
        p_Errmsg := 'Erro ao atualizar o valor do frete na TGFCAB. ' || Sqlerrm;
        Return;
    End;
  
  End set_vlrfrete_formula;

End Ad_pkg_fre;
/
