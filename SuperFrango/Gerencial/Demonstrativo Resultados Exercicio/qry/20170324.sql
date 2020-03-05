/*queFRTRX*/

Select Cab.Codemp,
       Round(Sum(Case
                    When Codempnegoc = 5 Then
                     Vlrfrete
                    Else
                     0
                  End) / Sum(Case
                               When Codempnegoc = 5 Then
                                Peso
                               Else
                                0
                             End), 4) As Fr5,
       Round(Sum(Case
                    When Codempnegoc = 7 Then
                     Vlrfrete
                    Else
                     0
                  End) / Sum(Case
                               When Codempnegoc = 7 Then
                                Peso
                               Else
                                0
                             End), 4) As Fr7,
       Round(Sum(Case
                    When Codempnegoc = 14 Then
                     Vlrfrete
                    Else
                     0
                  End) / Sum(Case
                               When Codempnegoc = 14 Then
                                Peso
                               Else
                                0
                             End), 4) As Fr14
/*  Round(Sum(Case When Codempnegoc = 5 Then Peso Else 0 End), 4) As QT5,
  Round(Sum(Case When Codempnegoc = 7 Then Peso Else 0 End), 4) As QT7,
  Round(Sum(Case When Codempnegoc = 14 Then Peso Else 0 End), 4) As QT14
*/
  From Tgfcab Cab
 Where Bom(Cab.Dtfatur) = Bom(&Dat1)
   And Codtipoper = 46
   And Codempnegoc In (5, 7, 14)
 Group By Cab.Codemp;

Select d.codemp,
       d.Codempneg,
       Nvl(d.codune, 0) codune,
       Round(Fc_Divide(Sum(Vlrfrete), Sum(Peso)), 4) frete
  From Ad_Basedre d
  Join ad_tsfune u
    On d.codune = u.codune
   And d.codemp = u.codemp
   And d.codempneg = u.codempneg
 Where d.Codempneg In (5, 7, 14)
   And d.Codtipoper = 46
   And Trunc(Dtfatur, 'mm') = &Dataini
 Group By d.codemp, d.Codempneg, d.codune;

-- 0,068815

Select
/*  Round(Sum(Case When Codempnegoc = 5 Then Vlrfrete Else 0 End) / Sum(Case When Codempnegoc = 5 Then Peso Else 0 End), 4) As FR5,
Round(Sum(Case When Codempnegoc = 7 Then Vlrfrete Else 0 End) / Sum(Case When Codempnegoc = 7 Then Peso Else 0 End), 4) As FR7,
Round(Sum(Case When Codempnegoc = 14 Then Vlrfrete Else 0 End) / Sum(Case When Codempnegoc = 14 Then Peso Else 0 End), 4) As FR14,
  Round(Sum(Case When Codempnegoc = 5 Then Peso Else 0 End), 4) As Qt5,
  Round(Sum(Case When Codempnegoc = 7 Then Peso Else 0 End), 4) As Qt7,
  Round(Sum(Case When Codempnegoc = 14 Then Peso Else 0 End), 4) As Qt14 */
--Count(nunota), Sum(peso)
 nunota, peso
  From Tgfcab Cab
 Where Bom(Cab.Dtfatur) = Bom(&Dat1)
   And Codtipoper = 46
      --And Codempnegoc In (5, 7, 14)
   And codempnegoc = 5
 Order By nunota;

Select Sum(PESO)
  From Select Distinct NUNOTA,
                       PESO(From Ad_Basedre d Join Ad_Tsfune u On
                            d.Codune = u.Codune And d.Codemp = u.Codemp And
                            d.Codempneg = u.Codempneg Where
                            d.Codempneg In (5, 7, 14) And d.Codtipoper = 46 And
                            Trunc(Dtfatur, 'mm') = '01/02/2017');


Select codempneg, Sum(PESO) PESO
  From (Select Distinct codempneg, nunota, peso
          From Ad_Basedre d
         Where d.Codempneg In (5, 7, 14)
           And d.Codtipoper = 46
           And Trunc(Dtfatur, 'mm') = '01/02/2017')
 Group By codempneg;
