Create Or Replace Procedure "AD_STP_VERNOMAPA"(P_CODUSU    Number,
																							 P_IDSESSAO  Varchar2,
																							 P_QTDLINHAS Number,
																							 P_MENSAGEM  Out Varchar2) As
	r_Maq AD_TSFAHMAPD%Rowtype;
	error Exception;
Begin

	For I In 1 .. P_QTDLINHAS -- Este loop permite obter o valor de campos dos registros envolvidos na execução.
	Loop
		-- A variável "I" representa o registro corrente.
	
		r_Maq.Nuapont     := ACT_INT_FIELD(P_IDSESSAO, I, 'NUAPONT');
		r_Maq.Numcontrato := ACT_INT_FIELD(P_IDSESSAO, I, 'NUMCONTRATO');
		r_Maq.Codmaq      := ACT_INT_FIELD(P_IDSESSAO, I, 'CODMAQ');
		r_Maq.Codprod     := ACT_INT_FIELD(P_IDSESSAO, I, 'CODPROD');
		r_Maq.Codvol      := ACT_INT_FIELD(P_IDSESSAO, I, 'CODVOL');
	
		Begin
			Select coordenadas
				Into r_Maq.Coordenadas
				From ad_tsfahmapd a
			 Where a.nuapont = r_maq.nuapont
				 And a.numcontrato = r_Maq.Numcontrato
				 And a.codprod = r_maq.codprod
				 And a.codmaq = r_Maq.Codmaq
				 And a.codvol = r_maq.codvol;
		Exception
			When Others Then
				Raise error;
		End;
	
	End Loop;
	p_mensagem := '<p align=''center''><a target="_blank" href="https://www.google.com/maps/preview?q=
								' || r_Maq.Coordenadas ||
								'&z=18&t=k">Clique <b><font color="#FF0000">AQUI</font></b> para ver no mapa</a>';
Exception
	When error Then
		p_mensagem := 'Não foi possível analisar as coordenadas desse apontamento, por favor verifique se a informação está correta.';
End;
/
