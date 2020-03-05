create or replace Procedure Stp_i_Tsiata_Tsfahmtad_Sf(p_Nunota Int, p_Nuapont Int) As

	Header     Varchar2(4000);
	Detail     Varchar2(32000);
	Htmlhead   Varchar2(4000);
	Htmlbottom Varchar2(4000);

	r_Cab            Ad_Tsfahmc%Rowtype;
	v_Dhsolicit      Date;
	v_Dtinicio       Date;
	v_Dtfim          Date;
	v_Numcontrato    Number;
	v_Observacoes    Varchar2(1000);
	v_Projeto        Varchar2(100);
	v_Ususolicitante Varchar2(50);
	v_Usuinclusao    Varchar2(50);

	v_Conteudo Blob;
Begin

	--  Autor: Ricardo Soares de Oliveira
	--  Dt. Criação: 16/03/2018
	--  Objetivo: Inserir anexo do apontamento de maquinas no pedido

	Begin
		Select Distinct a.Nuapont,
										a.Nomeparc,
										c.Numcontrato,
										Nvl(Trunc(s.Dhsolicit), '01/01/1900'),
										Nvl(s.Dtinicio, '01/01/1900'),
										Nvl(s.Dtfim, '01/01/1900'),
										s.Codsol || ' - ' || Ad_Get.Nomeusu(s.Codsol, 'Resumido'),
										s.Codusu || ' - ' || Ad_Get.Nomeusu(s.Codusu, 'Resumido'),
										Case
											When s.Codproj = 0 Then
											 'Projeto não informado na solicitação'
											Else
											 s.Codproj || ' - ' || p.Identificacao
										End,
										Nvl(s.Obs, 'Não informado detalhes de aplicação na solicitação')
			Into r_Cab.Nuapont,
					 r_Cab.Nomeparc,
					 v_Numcontrato,
					 v_Dhsolicit,
					 v_Dtinicio,
					 v_Dtfim,
					 v_Ususolicitante,
					 v_Usuinclusao,
					 v_Projeto,
					 v_Observacoes
			From Ad_Tsfahmc a, Ad_Tsfahmmaq q, Tcscon c, Ad_Tsfsstc s, Tcsprj p
		 Where a.Nuapont = q.Nuapont
			 And q.Numcontrato = c.Numcontrato
			 And c.Ad_Codsolst = s.Codsolst
			 And s.Codproj = p.Codproj
			 And a.Nuapont = p_Nuapont;
	
	Exception
		When No_Data_Found Then
			Return;
	End;

	Header := '<b>Apontamento: </b>' || r_Cab.Nuapont || '<br/><b>Parceiro: </b>' || r_Cab.Nomeparc ||
						'<br/><b>Solicitação: </b>' || v_Dhsolicit || '<br/><b>Inicio: </b>' || v_Dtinicio || '<br/><b>Fim: </b>' ||
						v_Dtfim || '<br/><b>Solicitante: </b>' || v_Ususolicitante || '<br/><b>Incluido Por: </b>' || v_Usuinclusao ||
						'<br/><b>Contrato: </b>' || v_Numcontrato || '<br/><b>Projeto: </b>' || v_Projeto ||
						'<br/><b>Detalhes: </b>' || v_Observacoes || Chr(13) || Chr(13) || Chr(10);

	Htmlhead := '<table border = 1>' || Chr(13) || '<tr>' || Chr(13) || ' <td> Data Apontamento </td>' || Chr(13) ||
							' <td> Tipo Apontamento </td>' || Chr(13) || ' <td> Quantidade</td>' || Chr(13) ||
							' <td>Vlr Unitário </td>' || Chr(13) || ' <td> Vlr Total </td>' || Chr(13) || ' <td> Serviço </td>' ||
							Chr(13) || ' <td> Máquina </td>' || Chr(13) || '</tr>';

	For Apontamento In (Select Nvl(Dtapont, '01/01/1900') Dtapont,
														 Nvl(Descrvol, 'Não Informado') Descrvol,
														 Nvl(Descrmaq, 'Não Informado') Descrmaq,
														 Nvl(Descrprod, 'Não Informado') Descrprod,
														 Nvl(Vlrunit, 0) Vlrunit,
														 Nvl(Qtdneg, 0) Qtdneg,
														 Nvl(Vlrunit * Qtdneg, 0) As Vlrtot,
														 Nunota
												From (Select r.*,
																		 Ad_Pkg_Ahm.Valorhora(q.Codsolst, q.Nussti, q.Seqmaq) As Vlrunit,
																		 m.Descrmaq || ' - ' || m.Id Descrmaq,
																		 p.Descrprod,
																		 Par.Nomeparc,
																		 v.Descrvol
																From Ad_Tsfahmapd r
																Join Ad_Tsfahmmaq q
																	On q.Nuseqmaq = r.Nuseqmaq
																 And q.Nuapont = r.Nuapont
																Join Ad_Tsfcme m
																	On m.Codmaq = q.Codmaq
																Join Tgfpro p
																	On q.Codprod = p.Codprod
																Join Tcscon c
																	On q.Numcontrato = c.Numcontrato
																Join Tgfpar Par
																	On Par.Codparc = c.Codparc
																Join Tgfvol v
																	On q.Codvol = v.Codvol
															 Where r.Nunota = p_Nunota))
                              
                               
                              
	Loop
		Detail := Detail || Chr(13) || '<tr align="center">' || Chr(13) || '<td>' || Apontamento.Dtapont || '</td>' ||
							Chr(13) || '<td>' || Apontamento.Descrvol || '</td>' || Chr(13) || '<td>' || Apontamento.Qtdneg ||
							'</td>' || Chr(13) || '<td>' || Apontamento.Vlrunit || '</td>' || Chr(13) || '<td>' || Apontamento.Vlrtot ||
							'</td>' || Chr(13) || '<td>' || Apontamento.Descrprod || '</td>' || Chr(13) || '<td><font color=red>' ||
							Apontamento.Descrmaq || '</font></td>' || Chr(13) || '</tr>';
	End Loop;

	If Detail Is Null Then
		Return;
	End If;

	Htmlbottom := Chr(13) || '</table>';

	--Detail := Header || Htmlhead || Detail || Htmlbottom;

	v_Conteudo := Utl_Raw.Cast_To_Raw(Header || Htmlhead || Detail || Htmlbottom);

	--Dbms_Output.Put_Line(Detail);

	Insert Into Tsiata
		(Codata, Tipo, Descricao, Arquivo, Codusu, Dtalter, Tipoconteudo, Conteudo, Edita, Sequencia, Sequenciapr)
	Values
		(p_Nunota, 'N', 'Apontamento ' || r_Cab.Nuapont, 'Apontamento' || r_Cab.Nuapont || '.html', 0, Sysdate, 'N',
		 v_Conteudo, 'N', 0, 0);

	Dbms_Output.Put_Line('inseriu nunota ' || p_Nunota);

Exception
	When Dup_Val_On_Index Then
		Null;
	When Others Then
		Dbms_Output.put_line('Msg de erro: ' || Sqlerrm);
		Raise_Application_Error(-20101,
														'Não foi possivel inserir o anexo do apontamento ' || r_Cab.Nuapont || ' / ' || p_Nunota ||
														' - ' || Sqlerrm);
End;
