Create Or Replace Procedure "AD_STP_UPD_REGFRETE"(P_CODUSU Number, P_IDSESSAO Varchar2, P_QTDLINHAS Number,
																									P_MENSAGEM Out Varchar2) As
	v_CodReg      Number;
	v_CodRegFrete Number;
	r             tsireg%Rowtype;
	l             Int := 0;
	continua      Varchar2(1) := 'S';
	Errmsg        Varchar2(1000);
	stmt          Varchar2(1000);
	Error Exception;
Begin

	/* Autor: Marcus Rangel
     Processo: Cálculo de Frete por OC
     Objetivo: Procedure utilizada na tela de Regiões de frete, ação "Atulizar código da região". 
               Atualizar o cadastro do parceiro com o código da região de frete.
  */

	Execute Immediate 'alter trigger trg_inc_upd_tgfpar_sf disable';

	Execute Immediate 'alter trigger trg_upd_tgfpar_sf disable';

	For I In 1 .. P_QTDLINHAS
	Loop
	
		v_CodReg      := ACT_INT_FIELD(P_IDSESSAO, I, 'CODREG');
		v_CodRegFrete := act_int_param(p_chave => P_IDSESSAO, p_nome => 'CODREGFRETE');
	
		Select *
			Into r
			From tsireg
		 Where codreg = v_CodReg;
	
		If Nvl(r.ativa, 'S') = 'N' Then
			Errmsg := 'Região não está ativa.';
		Elsif Nvl(r.analitica, 'N') = 'N' Then
			errmsg := 'Região não é analítica.';
		End If;
	
		If Errmsg Is Not Null Then
			Raise error;
		End If;
	
		For c_Par In (Select Rowid, codparc
										From tgfpar
									 Where codreg = v_CodReg
										 And Nvl(ad_codregfre, 0) <> v_CodRegFrete)
		Loop
		
			Begin
			
				Update tgfpar
					 Set ad_codregfre = v_CodRegFrete
				 Where Rowid = c_par.rowid;
			
				l := l + 1;
			
				If Mod(l, 100) = 0 Then
					Commit;
				End If;
			
			Exception
				When Others Then
				
					Continue;
				
				/*          If act_escolher_simnao(p_titulo => 'Erro na Atualização do parceiro ' || c_par.codparc,
                               p_texto => 'Foi encontrado o seguinte erro no processo: ' || Sqlerrm, p_chave => P_IDSESSAO,
                               p_sequencia => i) = 'S' Then
          Continue;
        Else
          Errmsg := 'Erro ao atualizar o cadastro de parceiros. ' || Sqlerrm;
          Raise error;
        End If;*/
			End;
		
		End Loop;
	
	End Loop;

	P_MENSAGEM := l || ' Parceiros atualizados!!!';

	Execute Immediate 'alter trigger trg_inc_upd_tgfpar_sf enable';

	Execute Immediate 'alter trigger trg_upd_tgfpar_sf enable';

Exception
	When error Then
		P_MENSAGEM := Errmsg;
End;
/
