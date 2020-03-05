Create Or Replace Trigger AD_TRG_AIUD_TCSCON_SF
	After Insert Or Update Or Delete On TCSCON
	For Each Row
Declare
	Errmsg Varchar2(4000);
Begin
	/* 
  Autor: M. Rangel
  Processo: Contratação de serviços de transportes
  Objetivo: Validações de dados e regras de negócio
  */

	-- saída para quando o contrato não é oriundo de solicitação de serviços de transportes.
	If inserting Or updating Or deleting Then
		If Nvl(:old.Ad_Codsolst, :new.Ad_Codsolst) Is Null Then
			Return;
		End If;
	End If;

	If deleting Then
	
		If :old.Ad_Situacao = 'L' And stp_get_codusulogado <> 0 Then
			errmsg := 'Contratos confirmados não podem ser alterados.';
			Raise_Application_Error(-20105, ad_fnc_formataerro(errmsg));
		End If;
	
		--* Tratativa para exclusão do contrato
	
		--* Alterado para tratativa da Fk da tabela, altera para "Set Null on Cascade"
		--tanto na AD_TSFSSTI quanto na AD_TSFSSTM.
	
		--* lembrando que essa alteração se deu 
		--para atender a demanda de geração de vários contratos para o mesmo serviço
	
		/*
    TODO: owner="MarcusR" category="Otimização" priority="1 - Alta" created="07/04/2017"
    text="Verificar a atualização do Status da solicitação de acordo com as esclusões dos contratos gerados. Se não existem contratos gerados, voltar o status para ""Pendente"""
    */
	
		Begin
			Update ad_tsfsstm stm
				 Set stm.numcontrato = Null
			 Where stm.codsolst = :old.Ad_Codsolst
				 And stm.numcontrato = :old.Numcontrato;
		
			Update ad_tsfssti sti
				 Set sti.numcontrato = Null
			 Where sti.codsolst = :old.Ad_Codsolst
				 And sti.numcontrato = :old.Numcontrato;
		Exception
			When Others Then
				errmsg := 'Erro ao atualizar as Solicitações de origem. ' || Sqlerrm;
				Raise_Application_Error(-20105, ad_fnc_formataerro(errmsg));
		End;
	
	End If; -- end of deleting
End;
/
