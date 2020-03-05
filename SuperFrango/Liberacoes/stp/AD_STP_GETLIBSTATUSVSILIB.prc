Create Or Replace Procedure "AD_STP_GETLIBSTATUSVSILIB"(p_codusu    Number,
																												p_idsessao  Varchar2,
																												p_qtdlinhas Number,
																												p_mensagem  Out Varchar2) As
	r_fin         tgffin%Rowtype;
	v_nometab     Varchar2(30);
	v_nuchave     Number;
	v_Sequencia   Int;
	v_SeqCascata  Int;
	v_nomellib    Varchar2(100);
	v_statuslib   Varchar2(100);
	v_mensagem    Varchar2(4000);
	v_count       Int := 0;
	v_descrevento Varchar(60);
	v_rodapemsg   Varchar(256);
	v_tipmov      Char(1);
	errmsg        Varchar2(4000);
	error Exception;
Begin

	If p_qtdlinhas > 1 Or p_qtdlinhas = 0 Then
		errmsg := 'Selecione os lançamentos individualmente.' || Sqlerrm;
		Raise error;
	End If;

	r_fin.nufin := act_int_field(p_idsessao, 1, 'NUCHAVE');

	v_nometab    := act_txt_field(p_idsessao, 1, 'TABELA');
	v_nuchave    := act_int_field(p_idsessao, 1, 'NUCHAVE');
	v_Sequencia  := act_int_field(p_idsessao, 1, 'SEQUENCIA');
	v_SeqCascata := act_int_field(p_idsessao, 1, 'SEQCASCATA');

	If v_nometab = 'AD_JURITE' Then
	
		Select l.obscompl
			Into p_mensagem
			From tsilib l
		 Where l.tabela = v_nometab
			 And l.nuchave = v_nuchave
			 And l.sequencia = v_Sequencia
			 And l.seqcascata = v_SeqCascata;
	
		Return;
	
	End If;

	Select *
		Into r_fin
		From tgffin f
	 Where ((f.nunota = r_fin.nufin And f.numdupl Is Null) Or
				 (f.nufin = r_fin.nufin And f.numdupl Is Not Null))
		 And rownum = 1;

	For c_nuchave In (
										--begin
										Select Distinct l.nometaborig, l.nuchaveorig
											From ad_tblcmf l
										 Where l.nometabdest = 'TGFFIN'
											 And l.nuchavedest = r_fin.nufin
										Union All
										Select Distinct 'TGFFIN', nunota -- rso nufin
											From tgffin f
										 Where f.nufin = r_fin.nufin)
	
	Loop
		v_nometab := c_nuchave.nometaborig;
		v_nuchave := c_nuchave.nuchaveorig;
	
		Select t.tipmov
			Into v_tipmov
			From tgftop t
		 Where t.codtipoper = r_fin.codtipoper
			 And t.dhalter = r_fin.dhtipoper;
	
		If r_fin.origem = 'F' And
			 (v_nometab Is Null Or v_nometab In ('AD_JURITE', 'AD_REQCART', 'TGFFIN')) And
			 r_fin.nunota Is Null Then
			v_nometab := 'TGFFIN';
			v_nuchave := r_fin.nufin;
		Elsif r_fin.origem = 'F' And v_nometab Is Not Null And r_fin.nunota Is Null Then
			If v_nometab = 'AD_MULCONTROL' Then
				v_nometab := 'AD_MULCONT';
			
			End If;
		Elsif r_fin.origem = 'E' And v_tipmov = 'I' Then
			v_nometab := 'TGFFIN';
			v_nuchave := r_fin.nufin;
		
		Elsif r_fin.origem = 'E' Then
			v_nometab := 'TGFCAB';
			v_nuchave := r_fin.nunota;
		End If;
	
		For c_lib In (Select *
										From (Select Distinct l.tabela, l.nuchave, l.dhlib, l.codusulib, l.evento,
																					 Case
																							When Nvl(l.ad_codusulib, l.codusulib) <> l.codusulib Then
																							 ' - (S) '
																							Else
																							 ' - '
																						End suplente
														 From tsilib l
														Where Nvl(l.tabela, 0) = Nvl(v_nometab, 0)
															And nuchave = v_nuchave
													 
													 Union All
													 
													 -- verifica quem é o usuário que incluiu a nota *
													 Select Distinct 'TGFCAB' tabela, c.nunota nuchave,
																					 --c.dtalter dhlib,
																					 Case
																							When c.statusnota = 'L' Then
																							 Nvl(c.ad_dtconfnota, c.dtalter)
																							Else
																							 Null
																						End dhlib,
																					 Case
																							When c.statusnota <> 'L' Then
																							 Null
																							When ad_get.temwms(v_nuchave) = 0 Then
																							 c.codusu
																							Else
																							 c.codusuinc
																						End codusulib, 1019 evento, ' - ' suplente
														 From tgfcab c
														Where c.nunota = v_nuchave
															And v_nometab = 'TGFCAB'
													 
													 Union All
													 --verifica quem conferiu a mercadoria
													 Select Distinct 'TGFCAB' tabela, r.nunota nuchave, con.dhfinalconf dhlib,
																					 con.codusu As codusulib, 1037 evento, ' - ' suplente
														 From tgwcon con, tgwrec r
														Where con.nuconferencia = r.nuconferencia
															And r.nunota = v_nuchave
													 
													 ) t
									 Order By t.dhlib)
		
		Loop
		
			Select Substr(e.descricao, 1, 23)
				Into v_descrevento
				From tgflibeve e
			 Where e.nuevento = c_lib.evento;
		
			If c_lib.dhlib Is Null Then
				v_statuslib := '<font color="#FF0000">' || v_descrevento || '</font>';
			Else
				v_statuslib := '<font color="#0000FF">' || v_descrevento || '</font>';
			End If;
		
			v_nomellib := ad_get.nomeusu(c_lib.codusulib, 'resumido');
		
			If v_mensagem Is Null Then
				v_mensagem := v_statuslib || c_lib.suplente || v_nomellib;
			Else
				v_mensagem := v_mensagem || Chr(13) || v_statuslib || c_lib.suplente || v_nomellib;
			End If;
		
		End Loop c_lib;
	
	End Loop c_nuchave;

	If v_statuslib Is Null Then
		v_mensagem := 'Lançamento não necessita de liberação.' || v_nometab || '.';
	End If;

	<<stat_end>>
	p_mensagem := v_mensagem;
	dbms_output.put_line(p_mensagem);

Exception
	When error Then
		p_mensagem := errmsg;
	When Others Then
		p_mensagem := Sqlerrm;
End;
/
