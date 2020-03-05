Create Or Replace Procedure ad_Stp_Gravafilabi(p_Assunto  In Tmdfmg.Assunto%Type,
																							 p_Mensagem In Tmdfmg.Mensagem%Type,
																							 p_Email    In Tmdfmg.Email%Type) As
	p_Codfila Number;
	v_Count   Int := 0;
	P_Codcon  Int;

Begin

	/* alteração para não ficar utilizando várias procedures e não ter que mudar todos os objetos que usam essa procedure */

	Stp_Gravafilabi_Sf(p_Assunto => p_Assunto, p_Codmsg => Null, p_Dtentrada => Sysdate, p_Status => 'Pendente',
										 p_Codcon => P_Codcon, p_Tentenvio => 3, p_Mensagem => p_Mensagem, p_Tipoenvio => 'E',
										 p_Maxtentenvio => 3, p_Email => p_Email);

	/*<<inicio>>
    Select Nvl(Max(Codfila), 0) + 1 Into p_Codfila From Tmdfmg;
    Select Count(*) Into v_Count From Tmdfmg Where codfila = p_Codfila;
    
    P_Codcon := 0; ----Rodrigo Evangelista Pereira - TI
  
    If v_Count != 0 Then
      p_codfila := p_codfila + 1;
    End If;
  
    Insert Into Tmdfmg
      (Codfila, Assunto, Dtentrada, Status, Codcon, Tentenvio, Mensagem, Tipoenvio, Maxtentenvio, Email, Mimetype, Codusu)
    Values
      (p_Codfila, p_Assunto, Sysdate, 'Pendente', P_Codcon, 3, p_Mensagem, 'E', 3, p_Email, 'text/html', 0);
  
    Dbms_Output.put_line('p_codfila: ' || p_Codfila);
    
  Exception
    When dup_val_on_index Then
      Select Nvl(Max(Codfila), 0) + 1 Into p_Codfila From Tmdfmg;
    
      Insert Into Tmdfmg
        (Codfila, Assunto, Dtentrada, Status, Codcon, Tentenvio, Mensagem, Tipoenvio, Maxtentenvio, Email, Mimetype,
         Codusu)
      Values
        (p_Codfila, p_Assunto, Sysdate, 'Pendente', P_Codcon, 3, p_Mensagem, 'E', 3, p_Email, 'text/html', 0);*/
Exception
	When Others Then
		Raise_Application_Error(-20105, 'Erro ao inserir o e-mail. ' || Sqlerrm);
End;
/
