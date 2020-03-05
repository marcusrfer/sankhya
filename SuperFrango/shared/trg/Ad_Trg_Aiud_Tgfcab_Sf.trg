Create Or Replace Trigger Ad_Trg_Aiud_Tgfcab_Sf
	After Insert Or Update Or Delete On Tgfcab
	For Each Row
Declare
	i          Int := 0;
	v_Ambiente Char(1);
	p_IdSessao Varchar2(20);
	ErrMsg     Varchar2(4000);
Begin

	Select (Case
					 When Substr(program, 1, 3) = 'MGE' Then
						'G'
					 When substr(program, 1, 4) = 'JDBC' Then
						'W'
				 End)
		Into v_Ambiente
		From v$session
	 Where audsid = userenv('sessionid')
		 And username = 'SANKHYA';
	/*
  Dt. Cria��o: 22/11/2016
  Autor: Marcus Rangel
  Objetivo: Atualizar a tabela de liga��o entre a cab e as tabelas personalizadas quando o lan�amento � excluido da cab.
  (a tabela de liga��o n�o possui chave extrangeira, pois a mesma � usada para a liga��o indiscriminada, 
  funcionando mais como um de/para
  
  04/01/2017 - Ao alterar pedidos de compras para fob, sem parceiro transportador informado, disparar solicita��o de contrata��o
  de servi�os de transportes, frete dedicado.
  */

	If updating Then
		-- gerar cota��o de frete para cargas acima do Peso "X", para os fretes fob coleta, existe uma outra rotina para sele��o automa�tica do fornecedor
		-- Existe uma outra rotina que faz algo semelhante, na trigger TRG_UPD_TGFCAB_SF, linha 161
		-- � criada uma cota��o indiscriminadamente no momento da confirma��o do pedido
		-- Existe um bot�o de a��o que realiza a gera��o da solicita��o de cota��o, mas a rotina precisa atender a linha G tamb�m
		-- o futuro dessa opera��o ser� integrar a cota��o do frete � cota��o do produto, de forma que o frete componha o valor
		-- da aquisi��o considerando suas vari�veis e a escolha do fornecedor seja mais acertiva
		If :new.Statusnota = 'L' And :new.tipmov = 'O' And nvl(:new.Cif_Fob, 'N') = 'F' And nvl(:new.Tipfrete, 'N') = 'S' And
			 coalesce(:new.Peso, :new.pesobruto, 0) <> 0 Then
		
			Begin
				Select dbms_random.string('A', 20) Into p_Idsessao From dual;
			
				Insert Into execparams
					(idsessao, sequencia, nome, tipo, numint, numdec, texto, dta)
				Values
					(p_idsessao, 1, 'NUNOTA', 'I', :NEW.Nunota, Null, Null, Null);
			
				Delete From execparams
				 Where idsessao = P_IDSESSAO
					 And sequencia = 1
					 And nome = 'NUNOTA'
					 And NUMINT = :new.Nunota;
			
				ad_stp_solcotfrete(stp_get_codusulogado, p_idSessao, 1, errmsg);
			
			Exception
				When Others Then
					ErrMsg := 'Ocorreu um erro - ' || Sqlerrm;
					raise_application_error(-20105, errmsg);
			End;
		
		End If;
	End If;

	If Deleting Then
	
		Select Count(*)
			Into i
			From Ad_Tblcmf l
		 Where l.Nometabdest = 'TGFCAB'
			 And l.Nuchavedest = :old.Nunota;
	
		If i <> 0 Then
			Delete From Ad_Tblcmf l
			 Where l.Nometabdest = 'TGFCAB'
				 And l.Nuchavedest = :old.Nunota;
		Else
			Return;
		End If;
	
	End If;

End;
/
