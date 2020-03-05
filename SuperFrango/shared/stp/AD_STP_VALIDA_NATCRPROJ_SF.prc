CREATE OR REPLACE Procedure AD_STP_VALIDA_NATCRPROJ_SF(p_codemp     Number,
																											 p_Codtipoper Number,
																											 p_codnat     Number,
																											 p_codcencus  Number,
																											 p_codproj    Number,
																											 p_tipoSaida  Int,
																											 p_errmsg     Out Nocopy Varchar2) Is
	i            Int;
	count_CR     Int := 0;
	count_Nat    Int := 0;
	count_Prj    Int := 0;
	retorna_erro Boolean Default False;
	eleva_erro   Boolean Default False;
Begin

	/* 
  Autor: M. Rangel
  Processo: Todos
  Objetivo: Permitir realizar a mesma validação do rateio, ainda no início da operação,
            para que o problema seja corrigido pelo usuário responsável pelo lançamento.
  */

	If p_tipoSaida = 0 Then
		retorna_erro := True;
	Else
		eleva_erro := True;
	End If;

	If p_Codtipoper Not In (919, 784) And Nvl(p_Codnat, 0) = 0 Then
		p_errmsg := 'Natureza deve ser informada! ';
	End If;

	If Nvl(p_Codcencus, 0) = 0 Then
		p_errmsg := 'Centro de resultado deve ser informado! ';
	End If;

	If (p_Codnat In (8040000, 8120000)) And (p_Codtipoper > 0) Then
		p_errmsg := 'A Natureza informada não pode ser usada no rateio!';
	End If;

	If (p_Codcencus = 804000000) And
		 (P_Codtipoper Not In (721, 266, 267, 268, 269, 320, 464, 277, 468)) Then
		p_errmsg := 'O Centro de Resultado ' || To_Char(p_Codcencus) ||
								', informado nao pode ser usado no rateio! ' || Chr(13) || ' - TOP:' ||
								P_Codtipoper;
	End If;

	If (p_Codcencus In
		 (10100000, 10100100, 10100200, 10100300, 10100400, 10100500, 10100600, 10100700, 10100800,
			 10100900, 10101000, 10101100, 10101200, 10101300, 10101400, 10101500, 10101600, 10101700,
			 10101800, 10101900, 10102000, 10102100, 10102200, 10102300, 10200100, 10200200, 10200300,
			 10200400, 10200500, 10200600, 10200700, 10200800, 10200900, 10201000, 10201100, 10201200,
			 10201300, 10201400, 10201500, 10201600, 10201700, 10201800, 10201900, 10202000, 10202100,
			 10202200, 10202300, 10202400, 10202500, 10202600, 10202700, 10202800, 10202900, 10203000,
			 10203200, 10203300, 10204100, 10204200, 10204300, 10204400, 10204500, 10204600, 10204700,
			 10204800, 10204900, 10205000, 10205001, 10205002, 10205003, 10205004, 10205005, 10205006,
			 10205007, 10205008, 10205009, 10205010, 10205100, 10205200, 10205300, 10205400, 10205500,
			 10205600, 11000100, 11000200, 11000300, 11000400, 11000500, 11000600, 11001100, 11100100,
			 11100200, 70200100, 70200200, 70200400, 70200500, 70200600, 70200700, 100200100, 100200300,
			 100200900, 11001000)) Then
	
		p_errmsg := 'Centro de resultados desativados, utilize a nova estrutura. ';
	
	End If;

	Begin
	
		Select Count(*)
			Into i
			From Tsicus_Desativados
		 Where Codcencus = p_codcencus;
	
		If i > 0 Then
			p_errmsg := 'Este CR foi desativado pela INDG ! ';
		End If;
	
	End;

	If p_Codcencus In (10500437, 10500410, 70200300, 70201200) Then
		p_errmsg := 'Este CR do gerador de vapor foi desativado a partir de 31/07/2015, utilizar CR novo! ';
	End If;

	If p_Codcencus = 100102400 And p_Codproj Not Like '501%' Then
		If P_Codtipoper Not In (721, 3, 266, 267) Then
			p_errmsg := 'Para o Centro de Resultado ' || To_Char(p_Codcencus) || ' TOP ' ||
									To_Char(P_Codtipoper) || ' deve se informar um Projeto Social!';
		End If;
	End If;

	If P_Codtipoper = 3 And p_Codcencus = 10600201 And p_Codnat <> 4053700 Then
		p_errmsg := 'O lançamento de frete da batata dever ser feito com a natureza 4053700- Fretes - Importacao Revenda ';
	End If;

	If P_Codtipoper In (34, 708, 720) And p_Codcencus = 10600201 And p_Codnat <> 4081600 Then
		p_errmsg := ' O lançamento nesse c.r Importações p/Revenda - Batata deve ser  feito com a natureza 4081600 - Taxas Importacao - Revenda ';
	End If;

	If (P_Codtipoper Not In (34, 708, 720)) And (p_Codcencus = 10600201) And (p_Codnat = 4081600) Then
		p_errmsg := 'O lançamento nesse c.r Importações p/Revenda - Batata deve ser com a top 708 n=' ||
								p_codnat || ' cr=' || p_codcencus || ' T=' || P_Codtipoper;
	End If;

	If (p_Codcencus Like '108%' Or p_Codcencus Like '203%' Or p_Codcencus Like '1103%' Or
		 p_Codcencus Like '404%' Or p_Codcencus Like '902%' Or p_Codcencus = 110300200 Or
		 p_Codcencus = 110300100 Or p_Codcencus = 991300000) Then
		count_CR := 1;
	End If;

	If (p_Codnat Not Like '90534%' And p_Codnat Not Like '6%' Or p_Codnat Not Like '504%' Or
		 p_Codnat Like '401%' Or
		 p_Codnat Not Like '455%' And p_Codnat Not Like '506%' And p_CODNAT Not Like '508%') Then
		count_Nat := 1;
	End If;

	Select Count(*)
		Into count_Prj
		From Tcsprj P
	 Where Upper(P.Identificacao) Like '%EXP%'
		 And P.Ativo = 'S'
		 And P.Codproj = p_Codproj;

	If (count_CR = 1 And p_Codproj = 0 /*Or p_Codproj Not Like '3217%')*/
		 ) Or (count_cr = 1 And count_Nat = 0) Then
		p_errmsg := 'Lançamentos expansão devem conter um projeto - Qualquer dúvida entre em contato com o Marcel!!! ';
	End If;

	If count_Prj > 0 And count_cr = 0 Then
		p_errmsg := 'Projetos devem ter um c.r de expansão!! - Qualquer dúvida entre em contato com o Marcel!!!';
	End If;

	If count_Prj > 0 And count_Nat = 0 Then
		p_errmsg := 'Projetos devem ter uma natureza de expansão!! - Qualquer dúvida entre em contato com o Marcel!!!';
	End If;

	If p_Codnat In
		 (6010000, 6020000, 6030000, 6040000, 6060000, 6070000, 6080000, 6090000, 6100000, 6110000,
			6120000, 6150000, 6160000, 6170000, 6190000, 6200000, 6210000) Then
		p_errmsg := 'Essa natureza não pode mais receber lançamentos - Qualquer dúvida entre em contato com o Marcel!!! ';
	
	End If;

	If p_Codnat In (6050000, 6130000, 6140000, 6170000, 6220000) And (count_CR = 0 Or p_Codproj = 0) Then
		p_errmsg := 'Lançamentos de natureza de expansão devem conter um projeto e c.r de expansão - Qualquer dúvida entre em contato com o Marcel!!! ';
	End If;

	Begin
		Select Count(*)
			Into i
			From Tsicus
		 Where (Codcencus Like '21%' Or Codcencus Like '22' Or Codcencus Like '23%' Or
					 Codcencus Like '24%' Or Codcencus Like '25%' Or Codcencus Like '26%' Or
					 Codcencus Like '27%' Or Codcencus Like '28%' Or Codcencus Like '29%' Or
					 Codcencus Like '30%' Or Codcencus Like '31%' Or Codcencus Like '32%' Or
					 Codcencus Like '33%')
			 And Descrcencus Not Like 'Av%'
			 And Analitico = 'S'
			 And Codcencus = p_Codcencus;
	
		If i > 0 And P_Codemp In (1, 2, 3, 9, 11, 15) Then
			p_errmsg := 'Esse c.r (' || p_Codcencus || ') não pode ser usado nessa empresa (' || P_Codemp ||
									')!! - Qualquer dúvida entre em contato com o Gustavo contabilidade!!!';
		End If;
	End;

	Begin
		Select Count(*)
			Into i
			From Tsicus
		 Where (Codcencus Not Like '33%' And Codcencus Not Like '21%' And Codcencus Not Like '22%' And
					 Codcencus Not Like '24%' And Codcencus Not Like '41%' And
					 Codcencus Not Like '100101300%' And Codcencus Not Like '34%' And
					 Upper(Descrcencus) Not Like '%FAZENDA ARREN%')
			 And Codcencus = p_Codcencus;
	
		If i > 0 And P_Codemp = 543 Then
			p_errmsg := 'Esse c.r não pode ser usado nessa empresa!! - Qualquer dúvida entre em contato com o Marcel!!!';
		End If;
	
	End;

	Begin
		If Tsiusu_Log_Pkg.V_Codusulog In
			 (714, 221, 680, 421, 154, 157, 565, 166, 555, 465, 250, 756, 288, 425) And
			 p_Codnat = 6140000 Then
			p_errmsg := 'A natureza 6140000 não pode ser utilizada pelo DEPTO DE TRANSPORTES !!!';
		End If;
	End;

	If p_errmsg Is Not Null Then
		If retorna_erro Then
			Return;
		Elsif eleva_erro Then
			Raise_Application_Error(-20105, ad_fnc_formataerro(p_errmsg));
		End If;
	End If;

End;
/
