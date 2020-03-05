create or replace view ad_vw_qrcodemaq as
(Select
p.Nuapont,
 p.nuapont||'*'||
 p.Numcontrato || '*' ||
 p.maquina||'*'||
 p.codvol||'*'||
 p.Parceiro || '*' ||
 p.servico||'*'||
 p.codproj||'*'||
 p.Cr||'*^' As imglink,
 p.maquina As DESCRMAQ
From (
 Select cab.nuapont As nuapont,
     Maq.Numcontrato,
		 Par.Codparc || '-' || Par.Nomeparc As Parceiro,
		 Con.Codcencus Cr,
		 Con.Codproj,
		 Psc.Codprod||'-'||Pro.Descrprod servico,
		 Maq.Codmaq||'-'||Cme.Descrmaq||'-'||maq.id maquina,
		 maq.codvol
			From Ad_Tsfahmmaq Maq
			Inner Join Tcscon Con On (con.numcontrato = maq.numcontrato)
			Inner Join Tgfpar Par On (Con.Codparc = Par.Codparc)
			Inner Join Tcspsc Psc On (Con.Numcontrato = Psc.Numcontrato)
			Inner Join Tgfpro Pro On (Psc.Codprod = Pro.Codprod)
			Inner Join Ad_Tsfcme Cme On (Maq.Codmaq = Cme.Codmaq)
			inner join ad_tsfahmc cab on (maq.nuapont = cab.nuapont)
			Where  Maq.Codprod = Psc.Codprod And maq.numcontrato = con.numcontrato) p
			);
