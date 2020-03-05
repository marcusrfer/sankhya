Create Or Replace View AD_FPWLOT As
Select Locodlot As codlot, l.Lodesclot As descrlot From fpwpower.Lotacoes l Where l.Locodlot In (1)  Group By l.Locodlot, l.Lodesclot
