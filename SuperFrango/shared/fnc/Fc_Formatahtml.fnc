Create Or Replace Function Fc_Formatahtml(p_Mensagem Varchar2, p_Motivo Varchar2, p_Solucao Varchar2)
	Return Varchar2 Is
	p_Texto Varchar2(4000);
	p_Owner Varchar2(100);

Begin
	If Programa Like 'JDBC%' Then
		p_Texto := '<p align="center"><a href="http://www.sankhya.com.br" target="_blank">' ||
							 '<img src="http://www.sankhya.com.br/imagens/logo-sankhya.png"></img></a></p>' ||
							 '<p align="left"><font size="12" face="arial" color="#8B1A1A"><br><b>Atenção:  </b>' ||
							 p_Mensagem || '  <br>' || Case
								 When p_Motivo Is Null Then
									''
								 Else
									'<b>Motivo: </b> ' || p_Motivo || '<br>'
							 End || Case
								 When p_Solucao Is Null Then
									''
								 Else
									'<b>Solução: </b> ' || p_Solucao || '<br>'
							 End ||
							 '<p align="center"><font size="10" color="#008B45"><b>Informações para o Implantador e/ou equipe Sankhya</b></font><br>';
	Else
		p_Texto := p_Mensagem || Chr(13) || Chr(10) || 'MOTIVO: ' || Nvl(p_Motivo, '') || Chr(13) || Chr(10) ||
							 'SOLUCAO:' || Nvl(p_Solucao, '') || Chr(13) || Chr(10) ||
							 'Informações para o Implantador e/ou equipe Sankhya' || Chr(13) || Chr(10);
	End If;
	Return p_Texto;
End;
/
