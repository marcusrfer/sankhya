Create Or Replace Trigger AD_TRG_AI_TSFLFVT_SF
  After Insert On AD_TSFLFVT
  For Each Row
Declare
  t ad_tsflfvt%Rowtype;
  l ad_tsflfv%Rowtype;
	i Int := 0;
Begin
  /* 
  * Autor: M. Rangel
  * Processo: Programação Frango Vivo
  * Objetivo: Tratar os dados recebidos do Avecom para inserir na tabela de laudos
  */
  t.cod_granja        := Rtrim(Ltrim(:new.Cod_Granja));
  t.galpao            := Rtrim(Ltrim(:new.Galpao));
  t.qtd_aves_alojadas := To_Number(:new.Qtd_Aves_Alojadas);
  t.des_sexo          := Rtrim(Ltrim(:new.Des_Sexo));
  t.peso_final        := Replace(:new.Peso_Final, '.', ',');
  t.dermatose         := Replace(:new.Dermatose, '.', ',');
  t.risco             := Replace(:new.Risco, '.', ',');
  t.aerosaculite      := Replace(:new.Aerosaculite, '.', ',');
  t.calo              := Replace(:new.Calo, '.', ',');
  t.irritacao         := Replace(:new.Irritacao, '.', ',');
  t.aves_final        := Rtrim(Ltrim(:new.Aves_Final));
  t.cgc_cpf_criador   := Rtrim(Ltrim(:New.Cgc_Cpf_Criador));

  t.data_pega := To_Date(Substr(:New.Data_Pega, 9, 2) || '/' || Substr(:New.Data_Pega, 6, 2) || '/' ||
                         Substr(:New.Data_Pega, 1, 4), 'dd/mm/yyyy');

  t.hora_pega := Substr(:new.Hora_Pega, 12, 8);

  t.data_abate := To_Date(Substr(:New.Data_Abate, 9, 2) || '/' || Substr(:New.Data_Abate, 6, 2) || '/' ||
                          Substr(:New.Data_Abate, 1, 4), 'dd/mm/yyyy');

  t.data_racao := To_Date(Substr(:New.Data_Racao, 9, 2) || '/' || Substr(:New.Data_Racao, 6, 2) || '/' ||
                          Substr(:New.Data_Racao, 1, 4), 'dd/mm/yyyy');

  t.hora_racao := Substr(t.hora_racao, 12, 8);

  If :new.Suspensao_Medicamento Is Not Null Then
    t.suspensao_medicamento := To_Date(Substr(:New.Suspensao_Medicamento, 9, 2) || '/' ||
                                       Substr(:New.Suspensao_Medicamento, 6, 2) || '/' ||
                                       Substr(:New.Suspensao_Medicamento, 1, 4), 'dd/mm/yyyy');
    t.suspensao_medicamento := To_Date(t.suspensao_medicamento, 'dd/mm/yyyy');
  End If;

  t.gta := Rtrim(Ltrim(:New.gta));

  stp_keygen_tgfnum('AD_TSFLFV', 1, 'AD_TSFLFV', 'NUMLFV', 0, l.numlfv);

  Select ad_pkg_pfv.get_codparc_integrado(t.cod_granja, t.galpao, t.galpao)
    Into l.codparc
    From dual;

  If l.codparc Is Null Then
  
    Begin
      Select codparc
        Into l.codparc
        From tgfpar
       Where codtipparc = 11110200
         And (Upper(nomeparc) Like '%UNIDADE%' || t.cod_granja || '%AVIARIO%' || t.galpao || '%' Or
             Upper(nomeparc) Like '%UNIDADE%' || t.cod_granja || '%NUCLEO%' || t.galpao || '%')
         And rownum = 1;
    Exception
      When no_data_found Then
        Select codparc
          Into l.codparc
          From tgfpar
         Where (Upper(nomeparc) Like '%UNIDADE%' || t.cod_granja || '%AVIARIO%' || t.galpao || '%' Or
               Upper(nomeparc) Like '%UNIDADE%' || t.cod_granja || '%NUCLEO%' || t.galpao || '%')
           And rownum = 1;
    End;
  
  End If;

  l.codprod := Case
                 When t.des_sexo = 'MACHO' Then
                  ad_pkg_pfv.v_CodProdMacho
                 When t.des_sexo = 'FEMEA' Then
                  ad_pkg_pfv.v_CodProdFemea
                 When t.des_sexo = 'SEXADO' Then
                  ad_pkg_pfv.v_CodProdSexado
               End;

  l.qtdaves := t.qtd_aves_alojadas;

  l.descrabrevave := :new.Des_Abrev;

  Begin
    l.dtalojamento := To_Date(Substr(:New.Dat_Inicial_Alojamento, 9, 2) || '/' ||
                              Substr(:New.Dat_Inicial_Alojamento, 6, 2) || '/' ||
                              Substr(:New.Dat_Inicial_Alojamento, 1, 4), 'dd/mm/yyyy');
  Exception
    When Others Then
      Raise_Application_Error(-20105, 'Erro na conversão da data de alojamento. ' || Sqlerrm);
  End;

  Begin
    l.qtdmortes := t.aves_final;
  Exception
    When Others Then
      Raise_Application_Error(-20105, 'Erro na conversão da quantidade de mortes. ' || Sqlerrm);
  End;

  Begin
    l.pesofinal    := t.peso_final;
    l.risco        := t.risco;
    l.dermatose    := t.dermatose;
    l.aerosaculite := t.aerosaculite;
    l.calo         := t.calo;
    l.irritacao    := t.irritacao;
    l.dtabate      := t.data_abate;
    Null;
  Exception
    When Others Then
      Raise_Application_Error(-20105, 'bloco 1 - ' || :new.Peso_Final || ' - ' || Sqlerrm);
  End;

  Begin
    l.dhpega := To_Date(Substr(:new.Data_Pega, 9, 2) || '/' || Substr(:new.Data_Pega, 6, 2) || '/' ||
                        Substr(:new.Data_Pega, 1, 4) || ' ' || Substr(:new.Hora_Pega, 12, 8),
                        'dd/mm/yyyy hh24:mi:ss');
  Exception
    When Others Then
      --l.dhpega := To_Date('01/01/1900', 'dd/mm/yyyy hh24:mi:ss');
      Raise_Application_Error(-20105, 'Erro na conversão da data da pega. ' || Sqlerrm);
  End;

  Begin
    l.dhracao := To_Date(Substr(:new.Data_Racao, 9, 2) || '/' || Substr(:new.Data_Racao, 6, 2) || '/' ||
                         Substr(:new.Data_Racao, 1, 4) || ' ' || Substr(:new.Hora_Racao, 12, 8),
                         'dd/mm/yyyy hh24:mi:ss');
  Exception
    When Others Then
      Raise_Application_Error(-20105, 'erro na conersão da data da ração. ' || Sqlerrm);
  End;

  l.obs            := :new.Obs_1 || ' ' || :new.Obs_2 || ' ' || :new.Obs_3;
  l.obsmedicamento := :new.Obs_Medicamento;
  l.obscarencia    := :new.Obs_Carencia;
  l.dtsuspmed      := t.suspensao_medicamento;

  Begin
    l.gta := t.gta;
  Exception
    When Others Then
      Raise_Application_Error(-20105, 'Erro na conversão gta. ' || Sqlerrm);
  End;
	
	Select Count(*) from 

  Begin
    Insert Into ad_tsflfv
    Values l;
  Exception
    When dup_val_on_index Then
      Null;
    When Others Then
      Raise_Application_Error(-20105,
                              'Erro ao inserir registro. ' || :new.Numlinha || Chr(13) || Sqlerrm);
  End;

End;
/
