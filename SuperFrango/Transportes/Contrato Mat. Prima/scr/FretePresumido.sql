REM PL/SQL Developer SQL History
Select To_Char(c.Dtentsai, 'mm/yyyy') As Referencia,
			 'SC' Tipo, --c.dtentsai,
			 To_Char(c.Dtentsai, 'DD') As Dia,
			 Round((Qtdneg) / 60, 2) Qtdneg
--Round((Vlrtot), 2) Vlrunit
--Fc_Divide(Round((Vlrtot), 2), Round((Qtdneg) / 60, 2)) Vlrtot
	From Tgfcab c
	Join Tgfite i
		On c.Nunota = i.Nunota
 Where c.Dtentsai Between '01/12/2018' And '31/12/2018'
	 And i.Codprod = 10001
	 And c.Codtipoper In (28, 86, 188)
/
Select To_Char(c.Dtentsai, 'mm/yyyy') As Referencia,
			 'SC' Tipo, --c.dtentsai,
			 To_Char(c.Dtentsai, 'DD') As Dia,
			 sum(Round((Qtdneg) / 60, 2)) Qtdneg
--Round((Vlrtot), 2) Vlrunit
--Fc_Divide(Round((Vlrtot), 2), Round((Qtdneg) / 60, 2)) Vlrtot
	From Tgfcab c
	Join Tgfite i
		On c.Nunota = i.Nunota
 Where c.Dtentsai Between '01/12/2018' And '31/12/2018'
	 And i.Codprod = 10001
	 And c.Codtipoper In (28, 86, 188)
/
Select To_Char(c.Dtentsai, 'mm/yyyy') As Referencia,
			 'SC' Tipo, --c.dtentsai,
			 To_Char(c.Dtentsai, 'DD') As Dia,
			 sum(Round((Qtdneg) / 60, 2)) Qtdneg
--Round((Vlrtot), 2) Vlrunit
--Fc_Divide(Round((Vlrtot), 2), Round((Qtdneg) / 60, 2)) Vlrtot
	From Tgfcab c
	Join Tgfite i
		On c.Nunota = i.Nunota
 Where c.Dtentsai Between '01/12/2018' And '31/12/2018'
	 And i.Codprod = 10001
	 And c.Codtipoper In (28, 86, 188)
   Group By To_Char(c.Dtentsai, 'mm/yyyy') ;
Select To_Char(c.Dtentsai, 'mm/yyyy') As Referencia,
			 'SC' Tipo, --c.dtentsai,
			 --To_Char(c.Dtentsai, 'DD') As Dia,
			 sum(Round((Qtdneg) / 60, 2)) Qtdneg
--Round((Vlrtot), 2) Vlrunit
--Fc_Divide(Round((Vlrtot), 2), Round((Qtdneg) / 60, 2)) Vlrtot
	From Tgfcab c
	Join Tgfite i
		On c.Nunota = i.Nunota
 Where c.Dtentsai Between '01/12/2018' And '31/12/2018'
	 And i.Codprod = 10001
	 And c.Codtipoper In (28, 86, 188)
   Group By To_Char(c.Dtentsai, 'mm/yyyy') ;
/

Select To_Char(c.Dtentsai, 'mm/yyyy') As Referencia,
			 'SC' Tipo, --c.dtentsai,
			 --To_Char(c.Dtentsai, 'DD') As Dia,
       c.codparc,
       ad_get.Nome_Parceiro(c.codparc,'fantasia') nomeparc,
			 sum(Round((Qtdneg) / 60, 2)) Qtdneg
--Round((Vlrtot), 2) Vlrunit
--Fc_Divide(Round((Vlrtot), 2), Round((Qtdneg) / 60, 2)) Vlrtot
	From Tgfcab c
	Join Tgfite i
		On c.Nunota = i.Nunota
 Where c.Dtentsai Between '01/12/2018' And '31/12/2018'
	 And i.Codprod = 10001
	 And c.Codtipoper In (28, 86, 188)
   Group By To_Char(c.Dtentsai, 'mm/yyyy');
/
Select To_Char(c.Dtentsai, 'mm/yyyy') As Referencia,
			 'SC' Tipo, --c.dtentsai,
			 --To_Char(c.Dtentsai, 'DD') As Dia,
       c.codparc,
       ad_get.Nome_Parceiro(c.codparc,'fantasia') nomeparc,
			 sum(Round((Qtdneg) / 60, 2)) Qtdneg
--Round((Vlrtot), 2) Vlrunit
--Fc_Divide(Round((Vlrtot), 2), Round((Qtdneg) / 60, 2)) Vlrtot
	From Tgfcab c
	Join Tgfite i
		On c.Nunota = i.Nunota
 Where c.Dtentsai Between '01/12/2018' And '31/12/2018'
	 And i.Codprod = 10001
	 And c.Codtipoper In (28, 86, 188)
   Group By To_Char(c.Dtentsai, 'mm/yyyy') ,c.codparc;
/
Select To_Char(c.Dtentsai, 'mm/yyyy') As Referencia,
			 'SC' Tipo, --c.dtentsai,
			 --To_Char(c.Dtentsai, 'DD') As Dia,
       c.codparc,
       ad_get.Nome_Parceiro(c.codparc,'fantasia') nomeparc,
			 sum(Round((Qtdneg) / 60, 2)) Qtdneg
--Round((Vlrtot), 2) Vlrunit
--Fc_Divide(Round((Vlrtot), 2), Round((Qtdneg) / 60, 2)) Vlrtot
	From Tgfcab c
	Join Tgfite i
		On c.Nunota = i.Nunota
 Where c.Dtentsai Between '01/12/2018' And '31/12/2018'
	 And i.Codprod = 10001
	 And c.Codtipoper In (28, 86, 188)
   Group By To_Char(c.Dtentsai, 'mm/yyyy') ,c.codparc;
/
Select To_Char(c.Dtentsai, 'mm/yyyy') As Referencia,
			 'SC' Tipo, --c.dtentsai,
			 --To_Char(c.Dtentsai, 'DD') As Dia,
       c.codparc,
       ad_get.Nome_Parceiro(c.codparc,'fantasia') nomeparc,
			 sum(Round((Qtdneg) / 60, 2)) Qtdneg,
       (Select 1 From ad_TABFRETEMP t Where t.codprod = c.codparc)
--Round((Vlrtot), 2) Vlrunit
--Fc_Divide(Round((Vlrtot), 2), Round((Qtdneg) / 60, 2)) Vlrtot
	From Tgfcab c
	Join Tgfite i
		On c.Nunota = i.Nunota
 Where c.Dtentsai Between '01/12/2018' And '31/12/2018'
	 And i.Codprod = 10001
	 And c.Codtipoper In (28, 86, 188)
   Group By To_Char(c.Dtentsai, 'mm/yyyy') ,c.codparc;
/
Select To_Char(c.Dtentsai, 'mm/yyyy') As Referencia,
			 'SC' Tipo, --c.dtentsai,
			 --To_Char(c.Dtentsai, 'DD') As Dia,
       c.codparc,
       ad_get.Nome_Parceiro(c.codparc,'fantasia') nomeparc,
			 sum(Round((Qtdneg) / 60, 2)) Qtdneg,
       (Select 1 From ad_TABFRETEMP t Where c.codparc = t.codparc)
--Round((Vlrtot), 2) Vlrunit
--Fc_Divide(Round((Vlrtot), 2), Round((Qtdneg) / 60, 2)) Vlrtot
	From Tgfcab c
	Join Tgfite i
		On c.Nunota = i.Nunota
 Where c.Dtentsai Between '01/12/2018' And '31/12/2018'
	 And i.Codprod = 10001
	 And c.Codtipoper In (28, 86, 188)
   Group By To_Char(c.Dtentsai, 'mm/yyyy') ,c.codparc;
/
Select To_Char(c.Dtentsai, 'mm/yyyy') As Referencia,
			 'SC' Tipo, --c.dtentsai,
			 --To_Char(c.Dtentsai, 'DD') As Dia,
       c.codparc,
       ad_get.Nome_Parceiro(c.codparc,'fantasia') nomeparc,
			 sum(Round((Qtdneg) / 60, 2)) Qtdneg,
       (Select count(1) From ad_TABFRETEMP t Where c.codparc = t.codparc)
--Round((Vlrtot), 2) Vlrunit
--Fc_Divide(Round((Vlrtot), 2), Round((Qtdneg) / 60, 2)) Vlrtot
	From Tgfcab c
	Join Tgfite i
		On c.Nunota = i.Nunota
 Where c.Dtentsai Between '01/12/2018' And '31/12/2018'
	 And i.Codprod = 10001
	 And c.Codtipoper In (28, 86, 188)
   Group By To_Char(c.Dtentsai, 'mm/yyyy') ,c.codparc;
/
Select To_Char(c.Dtentsai, 'mm/yyyy') As Referencia,
			 'SC' Tipo, --c.dtentsai,
			 --To_Char(c.Dtentsai, 'DD') As Dia,
       c.codparc,
       ad_get.Nome_Parceiro(c.codparc,'fantasia') nomeparc,
			 sum(Round((Qtdneg) / 60, 2)) Qtdneg,
       (Select count(1) From ad_TABFRETEMP t Where c.codparc = t.codparc) tf
--Round((Vlrtot), 2) Vlrunit
--Fc_Divide(Round((Vlrtot), 2), Round((Qtdneg) / 60, 2)) Vlrtot
	From Tgfcab c
	Join Tgfite i
		On c.Nunota = i.Nunota
 Where c.Dtentsai Between '01/12/2018' And '31/12/2018'
	 And i.Codprod = 10001
	 And c.Codtipoper In (28, 86, 188)
   Group By To_Char(c.Dtentsai, 'mm/yyyy') ,c.codparc;
/
Select To_Char(c.Dtentsai, 'mm/yyyy') As Referencia,
			 'SC' Tipo, --c.dtentsai,
			 --To_Char(c.Dtentsai, 'DD') As Dia,
       c.codparc,
       ad_get.Nome_Parceiro(c.codparc,'fantasia') nomeparc,
       c.codparctransp,
			 sum(Round((Qtdneg) / 60, 2)) Qtdneg,
       (Select count(1) From ad_TABFRETEMP t Where c.codparc = t.codparc) tf
--Round((Vlrtot), 2) Vlrunit
--Fc_Divide(Round((Vlrtot), 2), Round((Qtdneg) / 60, 2)) Vlrtot
	From Tgfcab c
	Join Tgfite i
		On c.Nunota = i.Nunota
 Where c.Dtentsai Between '01/12/2018' And '31/12/2018'
	 And i.Codprod = 10001
	 And c.Codtipoper In (28, 86, 188)
   Group By To_Char(c.Dtentsai, 'mm/yyyy') ,c.codparc, c.codparctransp;
/
-- frete presumido
Select To_Char(c.Dtentsai, 'mm/yyyy') As Referencia,
			 'SC' Tipo, --c.dtentsai,
			 --To_Char(c.Dtentsai, 'DD') As Dia,
       c.codparc,
       ad_get.Nome_Parceiro(c.codparc,'fantasia') nomeparc,
       c.codparctransp,
			 sum(Round((Qtdneg) / 60, 2)) Qtdneg,
       (Select count(1) From ad_TABFRETEMP t Where c.codparc = t.codparc) tf
--Round((Vlrtot), 2) Vlrunit
--Fc_Divide(Round((Vlrtot), 2), Round((Qtdneg) / 60, 2)) Vlrtot
	From Tgfcab c
	Join Tgfite i
		On c.Nunota = i.Nunota
 Where c.Dtentsai Between '01/12/2018' And '31/12/2018'
	 And i.Codprod = 10001
	 And c.Codtipoper In (28, 86, 188)
   Group By To_Char(c.Dtentsai, 'mm/yyyy') ,c.codparc, c.codparctransp;
/
-- frete presumido
Select To_Char(c.Dtentsai, 'mm/yyyy') As Referencia,
			 'SC' Tipo, --c.dtentsai,
			 --To_Char(c.Dtentsai, 'DD') As Dia,
       c.codparc,
       ad_get.Nome_Parceiro(c.codparc,'fantasia') nomeparc,
       c.codparctransp,
			 sum(Round((Qtdneg) / 60, 2)) Qtdneg,
       (Select count(1) From ad_TABFRETEMP t Where c.codparc = t.codparc) tf
--Round((Vlrtot), 2) Vlrunit
--Fc_Divide(Round((Vlrtot), 2), Round((Qtdneg) / 60, 2)) Vlrtot
	From Tgfcab c
	Join Tgfite i
		On c.Nunota = i.Nunota
 Where c.Dtentsai Between '01/12/2018' And '31/12/2018'
	 And i.Codprod = 10001
	 And c.Codtipoper In (28, 86, 188)
   Group By To_Char(c.Dtentsai, 'mm/yyyy') ,c.codparc, c.codparctransp;
