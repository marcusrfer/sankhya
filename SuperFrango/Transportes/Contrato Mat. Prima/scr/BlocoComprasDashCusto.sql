 -- bloco compras dash custo matéria prima
 Select * From (
 Select 'Compra' As origem,
        To_Char(c.dtentsai,'mm/yyyy') As referencia,
        1 As ordem,
        'SC' tipo, --c.dtentsai,
        to_char(c.dtentsai,'DD') As dia,
        Round((Qtdneg) / 60, 2) Qtdneg
        --Round((Vlrtot), 2) Vlrunit
        --Fc_Divide(Round((Vlrtot), 2), Round((Qtdneg) / 60, 2)) Vlrtot
  From Tgfcab c
  Join Tgfite i
    On c.Nunota = i.Nunota
 Where c.Dtentsai Between '01/12/2018' And '31/12/2018'
   And i.Codprod = 10001
   And c.Codtipoper In (28, 86, 188)
  )
  Pivot (
   Sum(qtdneg)
   For dia In (
     '01','02','03','04','05','06','07','08','09','10','11','12','13','14','15','16','17','18','20','21','22','23','24','25','26','27','28','29','30','31'
     )
  )
  Union
  Select *From (
 Select 'Compra' As origem,
        To_Char(c.dtentsai,'mm/yyyy') As referencia,
        2 As ordem,
        'R$' tipo, --c.dtentsai,
        to_char(c.dtentsai,'DD') As dia,
        --Round((Qtdneg) / 60, 2) Qtdneg
        Round((Vlrtot), 2) Vlrunit
        --Fc_Divide(Round((Vlrtot), 2), Round((Qtdneg) / 60, 2)) Vlrtot
  From Tgfcab c
  Join Tgfite i
    On c.Nunota = i.Nunota
 Where c.Dtentsai Between '01/12/2018' And '31/12/2018'
   And i.Codprod = 10001
   And c.Codtipoper In (28, 86, 188)
  )
  Pivot (
   Sum(vlrunit)
   For dia In ('01','02','03','04','05','06','07','08','09','10','11','12','13','14','15','16','17','18','20','21','22','23','24','25','26','27','28','29','30','31')
  )
  Union
  Select *From (
 Select 'Compra' As origem,
        To_Char(c.dtentsai,'mm/yyyy') As referencia,
        3 As ordem,
        'R$/SC' tipo, --c.dtentsai,
        to_char(c.dtentsai,'DD') As dia,
        Fc_Divide(Round((Vlrtot), 2), Round((Qtdneg) / 60, 2)) Vlrtot
  From Tgfcab c
  Join Tgfite i
    On c.Nunota = i.Nunota
 Where c.Dtentsai Between '01/12/2018' And '31/12/2018'
   And i.Codprod = 10001
   And c.Codtipoper In (28, 86, 188)
  )
  Pivot (
   Sum(vlrtot)
   For dia In ('01','02','03','04','05','06','07','08','09','10','11','12','13','14','15','16','17','18','20','21','22','23','24','25','26','27','28','29','30','31')
  );
