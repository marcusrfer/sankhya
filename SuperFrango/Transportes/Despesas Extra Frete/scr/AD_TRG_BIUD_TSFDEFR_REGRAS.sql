Create Or Replace Trigger AD_TRG_BIUD_TSFDEFR_REGRAS
	Before Insert Or Update Or Delete On AD_TSFDEFR
	For Each Row
Declare
	v_Count     Int := 0;
	v_Status    Char(2);
	v_codcencus Number;
	v_Valor     Float;
	v_NuTabela  Int;
	Errmsg      Varchar2(4000);
	Error Exception;
Begin
	/*
   Autor: Marcus Rangel
   Processo: Despesas Extras de Frete
   Objetivo: Realiizar validações no preenchimento do recibo do processo de despesas extras de frete
  */

	Begin
		Select status
			Into v_Status
			From ad_tsfdef f
		 Where f.nudef = Nvl(:new.Nudef, :old.Nudef);
	Exception
		When Others Then
			Raise;
	End;

	If inserting Then
		-- valida status do cabeçalho na inclusão de recibos
	
		If (v_status = 'AL' Or v_status = 'L' Or v_status = 'P') Then
			errmsg := 'Lançamentos que estão aguardando liberação, já foram liberados ou já possuem pedido de compras gerados não podem ser alterados (valor).';
		
			Raise error;
		End If;
	
		-- valida o anexo
		Begin
			Select Count(*)
				Into v_Count
				From tsianx a
			 Where a.nomeinstancia = 'TSFDEF'
				 And (Upper(a.nomearquivo) Like '%RECIBO%' Or Upper(a.descricao) Like '%RECIBO%')
				 And To_Number(Substr(pkregistro, 1, Instr(pkregistro, '_') - 1)) = :new.Nudef;
		
			If :new.Nutabela Is Not Null And v_Count = 0 Then
				errmsg := 'Não encontramos nenhum anexo referente recibos. Por favor, anexe uma cópia
			 do recibo antes de inserir o mesmo no sistema.';
				Raise error;
			End If;
		End;
	
		If (Nvl(:new.Rateio_Oc, 'N') = 'N' And Nvl(:new.Usacrmot, 'N') = 'N') And :new.codcencus Is Null Then
			errmsg := 'Para lançamentos que não utilizam rateio de CR pela Ordem de Carga, é obrigatório informar o CR manualmente.';
			Raise error;
		End If;
	
		-- se usa a CR do cadastro do motivo.
		If Nvl(:new.Usacrmot, 'N') = 'S' Then
			If :new.Codmotpai Is Null Or :new.Codmot Is Null Then
				Errmsg := 'Quando a opção "Usa CR do Motivo" estiver marcada, é obrigatório infomar o tipo e o motivo da despesa.';
				Raise error;
			End If;
			:new.Rateio_Oc := 'N';
		
			Begin
				Select Nvl(codcencus, 0)
					Into v_codcencus
					From ad_tsfdefm m
				 Where :New.Codmot = m.codmot;
			Exception
				When no_data_found Then
					errmsg := 'Centro de resultados não informado no motivo da despesa.';
					Raise Error;
			End;
		
			:new.Codcencus := v_codcencus;
		End If;
	
		-- busca preço de acordo com as tabelas
		Begin
		
			ad_get.valor_tabela_despfrete(:new.Nudef, :new.Nurecibo, :new.Codmot, v_valor, v_nutabela);
		
			If v_valor <> 0 Then
				If :new.Vlrdesdob > v_valor Then
					:new.Vlrdesdob := v_valor;
					:new.Nutabela  := v_nutabela;
				Elsif :new.Vlrdesdob Is Null Then
					:new.Vlrdesdob := v_valor;
				End If;
			End If;
		
		End;
	
	End If;

	If updating Then
	
		/* If :new.Codcencus Is Null Then
      :new.codcencus := 0;
    End If;*/
	
		-- valida alteraçao de valor e status do cabeçalho na inclusão de recibos
		If updating('VLRDESDOB') And (v_status = 'AL' Or v_status = 'L' Or v_status = 'P') Then
			errmsg := 'Lançamentos que estão aguardando liberação, já foram liberados ou já possuem pedido de compras gerados não podem ser alterados (valor).';
			Raise error;
		End If;
	
		If (Nvl(:new.Rateio_Oc, 'N') = 'N' And Nvl(:new.Usacrmot, 'N') = 'N') And :new.codcencus Is Null Then
			errmsg := 'Para lançamentos que não utilizam rateio de CR pela Ordem de Carga, é obrigatório informar o <font color="#FF0000">CR manualmente</font>.';
			Raise error;
		End If;
	
		-- se usa a CR do cadastro do motivo.
		If Nvl(:new.Usacrmot, 'N') = 'S' Then
			If :new.Codmotpai Is Null Or :new.Codmot Is Null Then
				Errmsg := 'Quando a opção "Usa CR do Motivo" estiver marcada, é obrigatório infomar o tipo e o motivo da despesa.';
				Raise error;
			End If;
		
			:new.Rateio_Oc := 'N';
		
			Select Nvl(codcencus, 0)
				Into v_codcencus
				From ad_tsfdefm m
			 Where :New.Codmot = m.codmot;
		
			:new.Codcencus := v_codcencus;
		
		End If;
	
		-- busca preço de acordo com as tabelas
		Begin
			ad_get.valor_tabela_despfrete(:new.Nudef, :new.Nurecibo, :new.Codmot, v_valor, v_nutabela);
		
			If v_valor <> 0 Then
				If :new.Vlrdesdob > v_valor Then
					:new.Vlrdesdob := v_valor;
					:new.Nutabela  := v_nutabela;
				Elsif :new.Vlrdesdob Is Null Then
					:new.Vlrdesdob := v_valor;
				End If;
			End If;
		
		End;
	
	End If;

	If deleting Then
		-- valida status do cabeçalho na inclusão de recibos
		If (v_status = 'AL' Or v_status = 'L' Or v_status = 'P') Then
			errmsg := 'Lançamentos que já foram liberados ou já possuem pedido de compras gerados não podem ser alterados (valor).';
			Raise error;
		End If;
	End If;

	Return;

Exception
	When error Then
		errmsg := errmsg || Chr(13) || Sqlerrm;
		Raise_Application_Error(-20105, ad_fnc_formataerro(errmsg));
	When Others Then
		errmsg := Sqlerrm;
		Raise_Application_Error(-20105, ad_fnc_formataerro(errmsg));
End;
/
