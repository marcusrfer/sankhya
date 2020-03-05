Create Or Replace Procedure "AD_STP_GETLIBSTATUS"(p_Codusu    Number,
																									p_Idsessao  Varchar2,
																									p_Qtdlinhas Number,
																									p_Mensagem  Out Varchar2) As
	r_Fin         Tgffin%Rowtype;
	v_Nometab     Varchar2(30);
	v_Nuchave     Number;
	v_NufinOrig   Number;
	v_Nomellib    Varchar2(100);
	v_Statuslib   Varchar2(100);
	v_Mensagem    Varchar2(4000);
	v_Descrevento Varchar(60);
	v_Tipacerto   Char(1);
	v_Tipmov      Char(1);
	Errmsg        Varchar2(4000);
	Error Exception;
Begin

	If p_Qtdlinhas > 1 Or p_Qtdlinhas = 0 Then
		Errmsg := 'Selecione os lançamentos individualmente.' || Sqlerrm;
		Raise Error;
	End If;

	r_Fin.Nufin := Act_Int_Field(p_Idsessao, 1, 'NUFIN');

	Select * Into r_Fin From Tgffin Where Nufin = r_Fin.Nufin;

	If Nvl(r_Fin.Numdupl, 0) > 0 Or Nvl(r_fin.nucompens, 0) > 0 Then
		Begin
			Select f.Tipacerto, f.nufinorig Into v_Tipacerto, v_NufinOrig From Tgffre f Where f.Nufin = r_Fin.Nufin;
		Exception
			When No_Data_Found Then
				v_Tipacerto := 'Z';
		End;
	End If;

	If (r_Fin.Nureneg Is Not Null Or r_Fin.Numdupl Is Not Null) And v_Tipacerto = 'F' And r_Fin.Recdesp <> 0 Then
		v_Mensagem := 'Verifique <i>Outras Opções >>Visualizar Origem do Lançamento</i>.';
	
	Else
	
		For c_Nuchave In (Select l.Nometaborig, l.Nuchaveorig
												From Ad_Tblcmf l
											 Where l.Nometabdest = 'TGFFIN'
												 And l.Nuchavedest = r_Fin.Nufin
											Union All
											Select 'TGFFIN', Nufin
												From Tgffin f
											 Where f.Nufin = r_Fin.Nufin)
		
		Loop
			v_Nometab := c_Nuchave.Nometaborig;
			v_Nuchave := c_Nuchave.Nuchaveorig;
		
			Select t.Tipmov
				Into v_Tipmov
				From Tgftop t
			 Where t.Codtipoper = r_Fin.Codtipoper
				 And t.Dhalter = r_Fin.Dhtipoper;
		
			If r_Fin.Origem = 'F' And (v_Nometab Is Null Or v_Nometab In ('AD_JURITE', 'AD_REQCART', 'TGFFIN')) And
				 r_Fin.Nunota Is Null Then
				v_Nometab := 'TGFFIN';
				/*v_Nuchave := r_Fin.Nufin;*/
				v_Nuchave := Case
											 When v_NufinOrig Is Null Then
												r_Fin.Nufin
											 Else
												v_NufinOrig
										 End;
			Elsif r_Fin.Origem = 'F' And v_Nometab Is Not Null And r_Fin.Nunota Is Null Then
				If v_Nometab = 'AD_MULCONTROL' Then
					v_Nometab := 'AD_MULCONT';
				
				End If;
			Elsif r_Fin.Origem = 'E' And v_Tipmov = 'I' Then
				v_Nometab := 'TGFFIN';
				v_Nuchave := r_Fin.Nufin;
			Elsif r_Fin.Origem = 'E' Then
				v_Nometab := 'TGFCAB';
				v_Nuchave := r_Fin.Nunota;
			End If;
		
			For c_Lib In (Select *
											From (Select l.Tabela, l.Nuchave, l.Dhlib, l.Codusulib, l.Evento,
																		Case
																			When Nvl(l.Ad_Codusulib, l.Codusulib) <> l.Codusulib Then
																			 ' - (S) '
																			Else
																			 ' - '
																		End Suplente
															 From Tsilib l
															Where Nvl(l.Tabela, 0) = Nvl(v_Nometab, 0)
																And Nuchave = v_Nuchave
														 
														 Union All
														 
														 -- Verifica quem é o usuário que incluiu a nota *
														 Select 'TGFCAB' Tabela, c.Nunota Nuchave,
																		--c.Dtalter Dhlib,
																		Nvl(c.Ad_Dtconfnota, c.Dtalter) Dhlib,
																		Case
																			 When Ad_Get.Temwms(v_Nuchave) = 0 Then
																				c.Codusu
																			 Else
																				c.Codusuinc
																		 End Codusulib, 1019 Evento, ' - ' Suplente
															 From Tgfcab c
															Where c.Nunota = v_Nuchave
																And v_Nometab = 'TGFCAB'
														 
														 Union All
														 --Verifica quem conferiu a mercadoria
														 Select 'TGFCAB' Tabela, r.Nunota Nuchave, Con.Dhfinalconf Dhlib, Con.Codusu As Codusulib,
																		1037 Evento, ' - ' Suplente
															 From Tgwcon Con, Tgwrec r
															Where Con.Nuconferencia = r.Nuconferencia
																And r.Nunota = v_Nuchave
														 
														 /*UNION ALL -- Comentado por Ricardo Soares em 24/04/2017 - No momento não é importante para o financeiro ter todas essas informações
                             
                             --* Verifica quem é o usuário que incluiu o pedido *
                             SELECT DISTINCT 'TGFCAB' Tabela,
                                             c.Nunota Nuchave,
                                             p.Dtalter Dhlib,
                                             p.Codusuinc Codusulib,
                                             1020 Evento
                               FROM Tgfcab c,
                                    Tgfvar v,
                                    Tgfcab p
                              WHERE c.Nunota = v_Nuchave
                                AND c.Nunota = v.Nunota
                                AND v.Nunotaorig = p.Nunota
                                AND v_Nometab = 'TGFCAB'
                             
                             UNION ALL
                             
                             --* Verifica quem é o usuário responsável pela cotação *
                             SELECT DISTINCT 'TGFCAB' Tabela,
                                             c.Nunota Nuchave,
                                             p.Dtalter Dhlib,
                                             Cot.Codusuresp Codusulib,
                                             1021 Evento
                               FROM Tgfcab c,
                                    Tgfvar v,
                                    Tgfcab p,
                                    Tgfcot Cot
                              WHERE c.Nunota = v_Nuchave
                                AND c.Nunota = v.Nunota
                                AND v.Nunotaorig = p.Nunota
                                AND p.Numcotacao = Cot.Numcotacao
                                AND v_Nometab = 'TGFCAB'
                             
                             UNION ALL
                             
                             --* Verifica quem é o usuário que requisitou a cotação *
                             SELECT DISTINCT 'TGFCAB' Tabela,
                                             c.Nunota Nuchave,
                                             Cot.Dtalter Dhlib,
                                             Cot.Codusureq Codusulib,
                                             1022 Evento
                               FROM Tgfcab c,
                                    Tgfvar v,
                                    Tgfcab p,
                                    Tgfcot Cot
                              WHERE c.Nunota = v_Nuchave
                                AND c.Nunota = v.Nunota
                                AND v.Nunotaorig = p.Nunota
                                AND v_Nometab = 'TGFCAB'
                                AND p.Numcotacao = Cot.Numcotacao
                             
                             UNION ALL
                             
                             --* Verifica quem é o usuário que executou a cotação *
                             SELECT DISTINCT 'TGFCAB' Tabela,
                                             c.Nunota Nuchave,
                                             p.Dtalter Dhlib,
                                             Cot.Codusu Codusulib,
                                             1023 Evento --Executou a cotação
                               FROM Tgfcab c,
                                    Tgfvar v,
                                    Tgfcab p,
                                    Tgfcot Cot
                              WHERE c.Nunota = v_Nuchave
                                AND c.Nunota = v.Nunota
                                AND v.Nunotaorig = p.Nunota
                                AND p.Numcotacao = Cot.Numcotacao
                                AND v_Nometab = 'TGFCAB'*/
														 ) t
										 Order By t.Dhlib)
			
			Loop
				/*IF 
         c_Lib.Evento < 1000 THEN
              CONTINUE;
        -- Por Ricardo Soares em 29/08/2017 comentei o trecho acima e coloquei o IF  c_Lib.Evento IN (44) OR c_Lib.Evento >= 1000 dessa forma 
        -- tenho por objetivo visualizar quem liberou o evento 44 que substitui o 1035
        END IF;*/
			
				If c_Lib.Evento In (44) Or c_Lib.Evento >= 1000 Then
					Select Substr(e.Descricao, 1, 23) Into v_Descrevento From Tgflibeve e Where e.Nuevento = c_Lib.Evento;
				
					If c_Lib.Dhlib Is Null Then
						v_Statuslib := '<font color="#FF0000">' || v_Descrevento || '</font>';
					Else
						v_Statuslib := '<font color="#0000FF">' || v_Descrevento || '</font>';
					End If;
				
					v_Nomellib := Ad_Get.Nomeusu(c_Lib.Codusulib, 'resumido');
				
					If v_Mensagem Is Null Then
						v_Mensagem := v_Statuslib || c_Lib.Suplente || v_Nomellib;
					Else
						v_Mensagem := v_Mensagem || Chr(13) || v_Statuslib || c_Lib.Suplente || v_Nomellib;
					End If;
				End If;
			End Loop c_Lib;
		
		End Loop c_Nuchave;
	
		If v_Statuslib Is Null Then
			v_Mensagem := 'Lançamento não necessita de liberação.' || v_Nometab || '.';
		End If;
	End If;

	<<stat_End>>
	p_Mensagem := v_Mensagem;
	Dbms_Output.Put_Line(p_Mensagem);

Exception
	When Error Then
		p_Mensagem := Errmsg;
	When Others Then
		p_Mensagem := Sqlerrm;
End;
/
