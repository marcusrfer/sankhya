Create Or Replace Trigger TRG_I_U_AFTER_TGFMBC_SF
	After Update On Tgfmbc
	Referencing New As New Old As Old
	For Each Row
	Disable
	When (New.Conciliado = 'S' And New.Origmov = 'T')
/*
  Trigger desabilitada por Marcus Rangel - Snk
  Apos a cria��o da tela de bloqueio judiciais em lote
  o sistema gera as transfer�ncia sem amarra��o com o processo, pois at� o momento o financeiro desconhe essa informa��o.
  De posse dessa info, o financeiro informa o c�digo do processo manualmente e o sistema busca o processo para fazer a amarra��o
  neste cen�rio, essa trigger impede que isso ocorra, pois exige que a amarra��o seja feita de imediato, permitindo que a transf.
  seja realizada somente depois de se obter o c�digo do processo, na contra m�o do processo desenhado
  */
Declare
	P_Count Int := 0;
	--P_Valor                  Number;
	P_Nufinproc Int := 0;

	Pragma Autonomous_Transaction;
Begin

	If :New.Origmov = 'T' Then
	
		Select Count(*)
			Into P_Count
			From Tsicta Cta
		 Inner Join Tgfmbc Mbc
				On Mbc.Codctabcoint = Cta.Codctabcoint
		 Where Mbc.Numtransf = :New.Numtransf
			 And Cta.Ad_Judicial = 'S'
			 And :NEW.DTLANC > '01/12/2016'; -- Trecho informado por Ricardo Soares em 22/03/2017, motivo: lan�amentos antigos n�o tem processo registrado no Sankhyaw 
	
		If P_Count > 0 Then
			Select Nvl(Max(Ad_Nufinproc), 0)
				Into P_Nufinproc
				From Tgfmbc
			 Where Numtransf = :New.Numtransf;
		
			If P_Nufinproc = 0 Then
				Raise_Application_Error(-20101,
																Fc_Formatahtml_Sf('A��o n�o permitida!',
																									'Dep�sito Judicial - N�o possui processo informado',
																									'Informar o Nr. Financeiro do Processo'));
			End If;
		
			---        Foi desativada essa parte pois os valores podem sofrer altera��es
			--            Select Nvl(Max(Valor),0) Into P_Valor 
			--              From Ad_Jurite
			--             Where Nufin = P_Nufinproc;
		
			--            If P_Valor <> :New.Vlrlanc Then 
			--                Raise_Application_Error(-20101, Fc_Formatahtml_Sf('A��o n�o permitida!', 
			--                                                                  'Dep�sito Judicial - Valor do Processo n�o � v�lido', 
			--                                                                  'Informar o valor ('||P_Valor||') do processo igual ao valor ('||:New.Vlrlanc||') do lan�amento'));        
			--            End If;
		End If;
	End If;

End;
/
