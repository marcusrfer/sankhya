Select codemp, codune, coduf, codprod, Sum(qtdneg)
 From dre_baseindpad_201812
 Where codemp = &emp
  And codune = &une
	And coduf = &uf
	And codprod = &prod
 Group By codemp, codune, coduf, codprod
 Union
 
  Select  codemp, codune, coduf, codprod, vlrdesc
	from dre_basevlrdesc_201812
	 Where codemp = &emp
	 And codune = &une
	 And coduf = &uf
	 And codprod = &prod;
	 --1 - 5 - 25 - 18856
	 --1 - 11 - 27 - 17410
