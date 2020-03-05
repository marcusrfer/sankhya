PL/SQL Developer Test script 3.0
42
Begin

Insert Into execparams(idsessao, sequencia, nome, tipo, numint, numdec, texto, dta) 
Values('C844FEB9A4C7CFDD3CABAEA9681665B8',0,'MASTER_NUMCONTRATO','I',9538,Null,Null,Null);
-------------------------------------------------------------------------------------------------------
Insert Into execparams(idsessao, sequencia, nome, tipo, numint, numdec, texto, dta) 
Values('C844FEB9A4C7CFDD3CABAEA9681665B8',1,'NUMCONTRATO','I',9538,Null,Null,Null);
-------------------------------------------------------------------------------------------------------
Insert Into execparams(idsessao, sequencia, nome, tipo, numint, numdec, texto, dta) 
Values('C844FEB9A4C7CFDD3CABAEA9681665B8',1,'NUAGEND','I',5,Null,Null,Null);
-------------------------------------------------------------------------------------------------------
Insert Into execparams(idsessao, sequencia, nome, tipo, numint, numdec, texto, dta) 
Values('C844FEB9A4C7CFDD3CABAEA9681665B8',1,'__ESCOLHA_SIMNAO__','S',Null,Null,'N',Null);
-------------------------------------------------------------------------------------------------------
Insert Into execparams(idsessao, sequencia, nome, tipo, numint, numdec, texto, dta) 
Values('C844FEB9A4C7CFDD3CABAEA9681665B8',2,'NUMCONTRATO','I',9538,Null,Null,Null);
-------------------------------------------------------------------------------------------------------
Insert Into execparams(idsessao, sequencia, nome, tipo, numint, numdec, texto, dta) 
Values('C844FEB9A4C7CFDD3CABAEA9681665B8',2,'NUAGEND','I',4,Null,Null,Null);
-------------------------------------------------------------------------------------------------------
Insert Into execparams(idsessao, sequencia, nome, tipo, numint, numdec, texto, dta) 
Values('C844FEB9A4C7CFDD3CABAEA9681665B8',3,'NUMCONTRATO','I',9538,Null,Null,Null);
-------------------------------------------------------------------------------------------------------
Insert Into execparams(idsessao, sequencia, nome, tipo, numint, numdec, texto, dta) 
Values('C844FEB9A4C7CFDD3CABAEA9681665B8',3,'NUAGEND','I',3,Null,Null,Null);
-------------------------------------------------------------------------------------------------------
Insert Into execparams(idsessao, sequencia, nome, tipo, numint, numdec, texto, dta) 
Values('C844FEB9A4C7CFDD3CABAEA9681665B8',4,'NUMCONTRATO','I',9538,Null,Null,Null);
-------------------------------------------------------------------------------------------------------
Insert Into execparams(idsessao, sequencia, nome, tipo, numint, numdec, texto, dta) 
Values('C844FEB9A4C7CFDD3CABAEA9681665B8',4,'NUAGEND','I',2,Null,Null,Null);
-------------------------------------------------------------------------------------------------------
Insert Into execparams(idsessao, sequencia, nome, tipo, numint, numdec, texto, dta) 
Values('C844FEB9A4C7CFDD3CABAEA9681665B8',5,'NUMCONTRATO','I',9538,Null,Null,Null);
-------------------------------------------------------------------------------------------------------
Insert Into execparams(idsessao, sequencia, nome, tipo, numint, numdec, texto, dta) 
Values('C844FEB9A4C7CFDD3CABAEA9681665B8',5,'NUAGEND','I',1,Null,Null,Null);
-------------------------------------------------------------------------------------------------------

ad_stp_fmp_agendmp_sf(1098,'C844FEB9A4C7CFDD3CABAEA9681665B8',5, ad_pkg_var.errmsg);
  
End;
1
output
2
Não foi possível gerar o agendamento. 
Quantidade agendada (1000000) é maior que a quantidade do contrato!
5
0
