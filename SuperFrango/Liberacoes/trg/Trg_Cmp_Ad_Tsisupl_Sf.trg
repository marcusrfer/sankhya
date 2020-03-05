Create Or Replace Trigger Trg_Cmp_Ad_Tsisupl_Sf
	For Insert Or Update On Ad_Tsisupl
	Referencing New As New Old As Old
	Compound Trigger

	--  Dt.       Criação: 29/05/2017
	--  Autor:    Ricardo Soares
	--  Objetivo: Alimentar TSISUPL, pois o usuário final não pode ter acesso a tela de usuários.
	--            Não me preocupo com o update pois o usuário não tem que ter acesso a isso nessa tela, qualquer alteração tem que ser solicitada ao TI para que isso fique registrado

	-- Declarando como variável global para que assim eu possa carregar o valor no BEFORE e utilizar no AFTER
	r_Usu     Tsisupl%Rowtype;
	v_Inserir Boolean;

	Before Each Row Is
	Begin
		If Inserting Then
		
			If :New.Codusu = 0 Or :New.Codususupl = 0 Then
				Raise_Application_Error(-20101, Fc_Formatahtml_Sf('Ação Cancelada!', 'Usuário zero não aceita suplencia', Null));
			End If;
		
			If :New.Codususupl = Stp_Get_Codusulogado Then
				Raise_Application_Error(-20101,
																Fc_Formatahtml_Sf('Ação Cancelada!', 'Não é possível atribuir suplência para você mesmo!', Null));
			End If;
		
			If :New.Dtinicio > :New.Dtfim Then
				Raise_Application_Error(-20101,
																Fc_Formatahtml_Sf('Ação Cancelada!', 'Data Final deve ser posterior a data inicial', Null));
			End If;
		
			If :New.Dtinicio > Trunc(Sysdate) + 10 Then
				Raise_Application_Error(-20101,
																Fc_Formatahtml_Sf('Ação Cancelada!',
																									'Data Inicial está limitata a ' || To_Char(Trunc(Sysdate) + 10, 'DD/MM/YYYY'),
																									Null));
			End If;
		
			If :New.Dtfim < Trunc(Sysdate) Then
				Raise_Application_Error(-20101, Fc_Formatahtml_Sf('Ação Cancelada!', 'Data Final deve ser posterior a data atual', Null));
			End If;
		
			If :New.Dtfim > Trunc(:New.Dtinicio) + 31 Then
				Raise_Application_Error(-20101,
																Fc_Formatahtml_Sf('Ação Cancelada!',
																									'Data Final está limitada a ' ||
																									To_Char(Trunc(:New.Dtinicio) + 31, 'DD/MM/YYYY'),
																									Null));
			End If;
		
			r_Usu.Codusu     := :New.Codusu;
			r_Usu.Codususupl := :New.Codususupl;
			r_Usu.Dtinicio   := :New.Dtinicio;
			r_Usu.Dtfim      := :New.Dtfim;
			v_Inserir        := True;
		
		End If;
	
		If Updating And Not Updating('REVOGADO') Then
			Raise_Application_Error(-20101, Fc_Formatahtml_Sf('Alteração não permitida', 'Entre em contato com o TI', Null));
		End If;
	
	End Before Each Row;

	--- Após as operações
	After Statement Is
		v_Count        Int;
		v_Usuario_Rede Varchar2(60);
		v_Nomemaquina  Varchar2(60);
		v_Ipmaquina    Varchar2(60);
	Begin
		--Raise_Application_Error(-20101, Fc_Formatahtml_Sf('Ação Cancelada!', 'Registro já existe no sistema', r_Usu.Dtinicio));
		Select Count(*)
			Into v_Count
			From Tsisupl s
		 Where s.Codusu = r_Usu.Codusu
			 And s.Codususupl = r_Usu.Codususupl
			 And s.Dtinicio = r_Usu.Dtinicio;
	
		If v_Count > 0 Then
			Raise_Application_Error(-20101, Fc_Formatahtml_Sf('Ação Cancelada!', 'Registro já existe no sistema', Null));
		End If;
	
		Select Count(*)
			Into v_Count
			From Tsisupl s
		 Where s.Codusu = r_Usu.Codusu
			 And s.Codususupl = r_Usu.Codususupl
			 And r_Usu.Dtinicio Between s.Dtinicio And s.Dtfim;
	
		If v_Count > 0 Then
			Raise_Application_Error(-20101, Fc_Formatahtml_Sf('Ação Cancelada!', 'Já existe uma suplencia para esse período', Null));
		End If;
	
		Select Osuser, Machine, Sys_Context('USERENV', 'IP_ADDRESS')
			Into v_Usuario_Rede, v_Nomemaquina, v_Ipmaquina
			From V$session
		 Where Audsid = (Select Userenv('SESSIONID')
											 From Dual);
	
		If v_Inserir Then
		
			Insert Into Tsisupl
				(Codusu, Codususupl, Dtinicio, Dtfim, Ad_Observacaousu)
			Values
				(r_Usu.Codusu, r_Usu.Codususupl, r_Usu.Dtinicio, r_Usu.Dtfim,
				 'Data: ' || To_Char(Sysdate, 'DD/MM/YYYY HH24:MI:SS') || Chr(13) || 'Usuário Sistema: ' || Stp_Get_Codusulogado || ' - ' ||
					Tsiusu_Log_Pkg.v_Nomeusulog || Chr(13) || 'Usuário Rede: ' || v_Usuario_Rede || Chr(13) || 'Nome Máquina: ' ||
					v_Nomemaquina || Chr(13) || 'IP Máquina: ' || v_Ipmaquina || Chr(13));
		
			-- verifica se o usuário é suplente de algum usuário guarda chuva
			-- alteração M. Rangel - 26/07/2018
			-- ocorria erro no insert quando o existe mais de uma liberação de suplência 
			-- para o usuário atribuidor
			Declare
				r_Codusu Number;
			Begin
			
				Begin
					Select Nvl(s.codusu, 0)
						Into r_codusu
						From Tsisupl s
					 Where s.Codususupl = r_Usu.Codusu
						 And r_Usu.Dtinicio Between s.Dtinicio And s.Dtfim
						 And s.Codusu In (950, 993, 1018)
						 And rownum = 1;
				Exception
					When no_data_found Then
						Null;
					When Others Then
						Raise;
				End;
			
				If r_Codusu > 0 Then
					Begin
						Insert Into Tsisupl
							(Codusu, Codususupl, Dtinicio, Dtfim, Ad_Observacaousu)
						Values
							(r_Codusu, r_Usu.Codususupl, r_Usu.Dtinicio, r_Usu.Dtfim,
							 'Data: ' || To_Char(Sysdate, 'DD/MM/YYYY HH24:MI:SS') || Chr(13) || 'Usuário Sistema: ' || Stp_Get_Codusulogado ||
								' - ' || Tsiusu_Log_Pkg.v_Nomeusulog || Chr(13) || 'Usuário Rede: ' || v_Usuario_Rede || Chr(13) ||
								'Nome Máquina: ' || v_Nomemaquina || Chr(13) || 'IP Máquina: ' || v_Ipmaquina || Chr(13));
					Exception
						When dup_val_on_index Then
							Null;
						When no_data_found Then
							Null;
						When Others Then
							Raise;
					End;
				End If;
			End;
		
			/*For r In (Select Nvl(s.Codusu, 0) Codusu
                  From Tsisupl s
                 Where s.Codususupl = r_Usu.Codusu
                   And r_Usu.Dtinicio Between s.Dtinicio And s.Dtfim
                   And s.Codusu In (950, 993, 1018)) -- quando um usuário que é suplente deste estiver inserindo uma suplencia passa a suplencia deste para o novo usuário
      Loop
        If r.Codusu > 0 Then
        
          Insert Into Tsisupl
            (Codusu, Codususupl, Dtinicio, Dtfim, Ad_Observacaousu)
          Values
            (r.Codusu, r_Usu.Codususupl, r_Usu.Dtinicio, r_Usu.Dtfim,
             'Data: ' || To_Char(Sysdate, 'DD/MM/YYYY HH24:MI:SS') || Chr(13) || 'Usuário Sistema: ' || Stp_Get_Codusulogado ||
              ' - ' || Tsiusu_Log_Pkg.v_Nomeusulog || Chr(13) || 'Usuário Rede: ' || v_Usuario_Rede || Chr(13) || 'Nome Máquina: ' ||
              v_Nomemaquina || Chr(13) || 'IP Máquina: ' || v_Ipmaquina || Chr(13));
        
        End If;
      End Loop;*/
		
		End If;
	
	End After Statement;
End;
/
