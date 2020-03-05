create or replace view ad_vw_basefunc as
Select
       Trunc(fmt.number_to_date(f.fudtinisit),'mm') referencia,
       f.Fucodemp codemp,
       f.Fumatfunc matfunc,
       f.Funomfunc nomefunc,
       f.Fusexfunc sexo,
       fmt.number_to_date(Fudtnasc) dtnasc,
       --Fudtnasc,
       f.Fuestcivil estcivil,
       Case
         When f.fuestcivil = '1' Then
          'Solteiro'
         When f.fuestcivil = '2' Then
          'Casado'
         When f.fuestcivil = '3' Then
          'Sep. Judicialmente'
         When f.fuestcivil = '4' Then
          'Divorciado'
         When f.fuestcivil = '5' Then
          'Viuvo'
         When f.fuestcivil = '6' Then
          'Outros'
         When f.fuestcivil = '7' Then
          'Ignorado'
       End As descrestciv,
       f.Fugrauinst grauinst,
       Case
         When f.fugrauinst = 1 Then
          'Analfabeto'
         When f.fugrauinst = 2 Then
          'Primeiro Grau Incompleto'
         When f.fugrauinst = 3 Then
          'Primeiro grau completo'
         When f.fugrauinst = 4 Then
          'Ens. Fundamental Incompleto'
         When f.fugrauinst = 5 Then
          'Ens. Fundamental Completo'
         When f.fugrauinst = 6 Then
          'Ensino Médio Incompleto'
         When f.fugrauinst = 7 Then
          'Ensino Médio Completo'
         When f.fugrauinst = 8 Then
          'Superior Incompleto'
         When f.fugrauinst = 9 Then
          'Superior Completo'
         When f.fugrauinst = 10 Then
          'Pós-Graduação/Especialização'
         when f.fugrauinst = 11 then
          'Doutorado Completo'
          when f.fugrauinst = 12 then
          'Segundo grau técnico incompleto'
          when f.fugrauinst = 13 then
          'Segundo grau técnico completo'
          when f.fugrauinst = 14 then
           'Mestrado'
          when f.fugrauinst = 15 then
          'Pós-Doutorado'
           End As descrgrauinstr,
       f.Fuendereco endereco,
       f.Fubairro bairro,
       f.Fucodmunic codmun,
       m.Mudesmunic cidade,
       Case
         When Length(Substr(Replace(a.afvalor, '-', ''), Rtrim(Instr(Replace(a.afvalor, '-', ''), ' ', -1)) + 1,
                            Length(a.afvalor) - Rtrim(Instr(a.afvalor, ' ', -1)))) = 2 Then
          Substr(Replace(a.afvalor, '-', ''), Rtrim(Instr(Replace(a.afvalor, '-', ''), ' ', -1)) + 1,
                 Length(a.afvalor) - Rtrim(Instr(a.afvalor, ' ', -1)))
         Else
          m.Muuf
       End UF,
       --m.Muuf UF,
       a.afcodatrib codatrib,
       a.afvalor valoratrib,
       f.Fucep cep,
       fmt.number_to_date(f.fudtinisit) dtinisit,
       --f.fudtinisit,
       f.Fucodsitu codsituacao,
       st.Stdescsitu descrsituacao,
       f.Futipoadms tipoadms,
       fmt.number_to_date(f.fudtadmis) dtadmiss,
       --f.fudtadmis,
       Case
         When Exists
          (Select 1
          From ad_prhsit p
         Where p.Nuprh = 1
           And f.fucodsitu = p.Codsit
           And p.Gruporel = 'R')
          Then
          fmt.number_to_date(f.fudtinisit)
       End As dtrescisao,
       Case
         When f.fucodsitu In ( Select 1
          From ad_prhsit p
         Where p.Nuprh = 1
           And fucodsitu = p.Codsit
           And p.Gruporel = 'R') Then
          fmt.number_to_date(f.fudtinisit)
       End As dtafast,
       Case
         When f.fucodsitu In (19, 26) Then
          fmt.number_to_date(f.fudtinisit)
       End As dtferias,
       f.Fucodlot codlot,
       l.Lodesclot descrlot,
       --To_Number(f.Fucentrcus) centrcus,
       f.Fucentrcus,
       cw.codcencus,
       cw.descrcencus,
       cw.ad_clacus clacus,
       f.Fucodcargo codcargo,
       --ca.Cadescargo descrcargo,
       ad_pkg_rh.get_descrcargo_func(f.fucodemp,f.fumatfunc) descrcargo,
       f.Fucbo cbo,
       f.Fucpf cpf,
       f.Fuidade idade,
       f.Fuemail email
             --ca.Castatus statuscargo,
             --fmt.number_to_date(ca.Cadatainativacao) dtinatcargo
  From fpwpower.Funciona f
  left Join tsicus cw
    On To_Char(cw.codcencus) = To_Char(f.fucentrcus)
  Join fpwpower.Municip m
    On f.Fucodmunic = m.Mucodmunic
  Join fpwpower.Situacao st
    On f.Fucodsitu = st.Stcodsitu
   And f.Fucodemp = st.Stcodemp
  Join fpwpower.Lotacoes l
    On l.Locodemp = f.Fucodemp
   And l.Locodlot = f.Fucodlot
 /*Join fpwpower.Cargos ca
    On ca.Cacodemp = f.Fucodemp
    And ca.Cacodcargo = f.Fucodcargo*/
   --And (ca.Castatus = 'A' Or ca.Cadatainativacao = 0)
  Join fpwpower.atribfun a
    On f.fumatfunc = a.afmatfunc
   And f.fucodemp = a.Afcodemp
 Where a.Afcodatrib = '1002'
  And f.Fucodemp = 1

 Union all

 Select Trunc(fmt.number_to_date(f.fudtinisit), 'mm') referencia,
        f.Fucodemp codemp,
        f.Fumatfunc matfunc,
        f.Funomfunc nomefunc,
        f.Fusexfunc sexo,
        fmt.number_to_date(Fudtnasc) dtnasc,
        --Fudtnasc,
        f.Fuestcivil estcivil,
        Case
          When f.fuestcivil = '1' Then
           'Solteiro'
          When f.fuestcivil = '2' Then
           'Casado'
          When f.fuestcivil = '3' Then
           'Sep. Judicialmente'
          When f.fuestcivil = '4' Then
           'Divorciado'
          When f.fuestcivil = '5' Then
           'Viuvo'
          When f.fuestcivil = '6' Then
           'Outros'
          When f.fuestcivil = '7' Then
           'Ignorado'
        End As descrestciv,
        f.Fugrauinst grauinst,
        Case
          When f.fugrauinst = 1 Then
           'Analfabeto'
          When f.fugrauinst = 2 Then
           'Primeiro Grau Incompleto'
          When f.fugrauinst = 3 Then
           'Primeiro grau completo'
          When f.fugrauinst = 4 Then
           'Ens. Fundamental Incompleto'
          When f.fugrauinst = 5 Then
           'Ens. Fundamental Completo'
          When f.fugrauinst = 6 Then
           'Ensino Médio Incompleto'
          When f.fugrauinst = 7 Then
           'Ensino Médio Completo'
          When f.fugrauinst = 8 Then
           'Superior Incompleto'
          When f.fugrauinst = 9 Then
           'Superior Completo'
          When f.fugrauinst = 10 Then
           'Pós-Graduação/Especialização'
          When f.fugrauinst = 11 Then
           'Doutorado Completo'
          When f.fugrauinst = 12 Then
           'Segundo grau técnico incompleto'
          When f.fugrauinst = 13 Then
           'Segundo grau técnico completo'
          When f.fugrauinst = 14 Then
           'Mestrado'
          When f.fugrauinst = 15 Then
           'Pós-Doutorado'
        End As descrgrauinstr,
        f.Fuendereco endereco,
        f.Fubairro bairro,
        f.Fucodmunic codmun,
        m.Mudesmunic cidade,
        /*Case
         When Length(Substr(Replace(a.afvalor, '-', ''), Rtrim(Instr(Replace(a.afvalor, '-', ''), ' ', -1)) + 1,
                            Length(a.afvalor) - Rtrim(Instr(a.afvalor, ' ', -1)))) = 2 Then
          Substr(Replace(a.afvalor, '-', ''), Rtrim(Instr(Replace(a.afvalor, '-', ''), ' ', -1)) + 1,
                 Length(a.afvalor) - Rtrim(Instr(a.afvalor, ' ', -1)))
         Else
          m.Muuf
       End UF,*/
        m.Muuf  UF,
        /*a.afcodatrib */ 0 codatrib,
        /*a.afvalor */ '' valoratrib,
        f.Fucep cep,
        fmt.number_to_date(f.fudtinisit) dtinisit,
        --f.fudtinisit,
        f.Fucodsitu codsituacao,
        st.Stdescsitu descrsituacao,
        f.Futipoadms tipoadms,
        fmt.number_to_date(f.fudtadmis) dtadmiss,
        --f.fudtadmis,
        Case
          When Exists (Select 1
                  From ad_prhsit p
                 Where p.Nuprh = 1
                   And f.fucodsitu = p.Codsit
                   And p.Gruporel = 'R') Then
           fmt.number_to_date(f.fudtinisit)
        End As dtrescisao,
        Case
          When f.fucodsitu In (Select 1
                                 From ad_prhsit p
                                Where p.Nuprh = 1
                                  And fucodsitu = p.Codsit
                                  And p.Gruporel = 'R') Then
           fmt.number_to_date(f.fudtinisit)
        End As dtafast,
        Case
          When f.fucodsitu In (19, 26) Then
           fmt.number_to_date(f.fudtinisit)
        End As dtferias,
        f.Fucodlot codlot,
        l.Lodesclot descrlot,
        --To_Number(f.Fucentrcus) centrcus,
        f.Fucentrcus,
        cw.codcencus,
        cw.descrcencus,
        cw.ad_clacus clacus,
        f.Fucodcargo codcargo,
        --ca.Cadescargo descrcargo,
        ad_pkg_rh.get_descrcargo_func(f.fucodemp, f.fumatfunc) descrcargo,
        f.Fucbo cbo,
        f.Fucpf cpf,
        f.Fuidade idade,
        f.Fuemail email
                --ca.Castatus statuscargo,
             --fmt.number_to_date(ca.Cadatainativacao) dtinatcargo
   From folha.Funciona f
   Left Join tsicus cw
     On To_Char(cw.codcencus) = To_Char(f.fucentrcus)
   Join folha.Municip m
     On f.Fucodmunic = m.Mucodmunic
   Join folha.Situacao st
     On f.Fucodsitu = st.Stcodsitu
    And f.Fucodemp = st.Stcodemp
   Join folha.Lotacoes l
     On l.Locodemp = f.Fucodemp
    And l.Locodlot = f.Fucodlot
   /*Join folha.Cargos ca
     On ca.Cacodemp = f.Fucodemp
    And ca.Cacodcargo = f.Fucodcargo*/
   -- And (ca.Castatus = 'A' Or ca.Cadatainativacao = 0)
   /*Left Join folha.atribfun a
     On f.fumatfunc = a.afmatfunc
    And f.fucodemp = a.Afcodemp
    And a.Afcodatrib = '1002'*/
  Where f.Fucodemp = 10
And (f.Fucodsitu In (4, 5, 100) Or f.Fucodstant In (4,5,100))
;
