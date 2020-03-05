Create Or Replace Trigger Ad_Trg_CMP_Tgfcab_Sf
	For Insert Or Update Or Delete On Tgfcab
	Compound Trigger

	/*
  Autor: Marcus Rangel
  Objetivo: Gerar uma solicitação de serviço de transporte para pedidos de compras que são frete FOB extra nota automaticamente na confirmação  
  objeto não publicado em produção ainda, pois o processo mudou.
  */

	Type t_Nota Is Table Of Number;
	r_Nota     t_Nota := t_Nota();
	v_Count    Int := 0;
	i          Int := 0;
	v_Nunota   Int;
	v_Ambiente Char(1);
	p_IdSessao Varchar2(20);
	ErrMsg     Varchar2(4000);

	Before Statement Is
	Begin
		i := r_Nota.count;
		If Nvl(i, 0) <> 0 Then
			r_Nota.delete;
		End If;
	End Before Statement;

	Before Each Row Is
	Begin
	
		If Nvl(:new.tipmov, :old.tipmov) <> 'O' Then
			Goto saida;
		End If;
	
		v_Nunota := Nvl(:new.Nunota, :old.Nunota);
	
		Select (Case
						 When Substr(program, 1, 3) = 'MGE' Then
							'G'
						 When Substr(program, 1, 4) = 'JDBC' Then
							'W'
					 End)
			Into v_Ambiente
			From v$session
		 Where audsid = userenv('sessionid');
	
		If updating Then
		
			Begin
				Select 1 Into v_Count From ad_tsfsstc c Where c.nunotaorig = :new.Nunota;
			Exception
				When no_data_found Then
					v_Count := 0;
			End;
		
			If v_Count = 0 Then
			
				If /*v_Ambiente = 'G' And */
				-- Confirmando pedido de compra com frete fob extra nota sem parceiro transportador
				 (:old.Statusnota <> 'L' And :new.Statusnota = 'L') And :new.tipmov = 'O' And Nvl(:new.Cif_Fob, 'N') = 'F' And
				 Nvl(:new.Tipfrete, 'S') = 'N' And :new.pesobruto > 0 And Nvl(:new.Codparctransp, 0) = 0 Then
				
					i := r_Nota.count;
					i := i + 1;
					r_Nota.extend;
					r_Nota(i) := v_Nunota;
				
				End If;
			End If;
		End If;
	
		If Deleting Then
			Select Count(*)
				Into v_Count
				From Ad_Tblcmf l
			 Where l.Nometabdest = 'TGFCAB'
				 And l.Nuchavedest = :old.Nunota;
		
			If v_Count <> 0 Then
				Delete From Ad_Tblcmf l
				 Where l.Nometabdest = 'TGFCAB'
					 And l.Nuchavedest = :old.Nunota;
			End If;
		
			v_Count := 0;
		
			Begin
				Select 1 Into v_Count From ad_tsfsstc Where nunotaorig = :old.Nunota;
			Exception
				When no_data_found Then
					Goto saida;
			End;
		
			If v_Count <> 0 Then
				Delete From ad_tsfsstc Where nunotaorig = :old.Nunota;
			End If;
		
		End If;
	
		<<saida>>
		Null;
	End Before Each Row;

	After Statement Is
		p_IdSessao Varchar2(4000);
		errmsg     Varchar2(4000);
	Begin
		If r_Nota.count > 0 Then
			For i In r_Nota.first .. r_Nota.last
			Loop
				Begin
					ad_Set.Inseresessao('NUNOTA', 'I', r_Nota(i), p_IdSessao);
					ad_stp_solcotfrete(stp_get_codusulogado, p_idSessao, 1, errmsg);
				
					Delete From execparams
					 Where idsessao = P_IDSESSAO
						 And sequencia = 1
						 And nome = 'NUNOTA'
						 And NUMINT = r_Nota(i);
				
				Exception
					When Others Then
						ErrMsg := 'Ocorreu um erro - ' || Sqlerrm;
						raise_application_error(-20105, errmsg);
				End;
			End Loop;
		End If;
	
	End After Statement;

End;
/
