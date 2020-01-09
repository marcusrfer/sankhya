Create Or Replace Trigger AD_TRG_BIUD_JURMBCTR_SF
	Before Insert Or Update Or Delete On ad_jurmbctr
	For Each Row
Declare
	proc            ad_jurproc%Rowtype;
	jur             ad_jurite % Rowtype;
	fin             tgffin % Rowtype;
	p               ad_pkg_jur.type_rec_desp_jur;
	permite_excluir Boolean Default False;
	errmsg          Varchar2(4000);
	error Exception;
Begin
	/*
  * autor: m. rangel
  * processo: bloqueio jurídicos em lotes
  * objetivo: realizar operações ao informar o número do processo na tela 
  */

	If deleting Then
		If permite_excluir Then
			Null;
		Else
		
			If :old.Numtransf Is Not Null Then
				errmsg := 'Não é possível excluir lançamentos com transferência realizada.';
				Raise Error;
			Elsif :old.Codproc Is Not Null Then
				errmsg := 'Não é possível excluir lançamentos com processo informado.';
				Raise Error;
			End If;
		
		End If;
	End If;

	--se informando o processo
	If :new.codproc Is Not Null And :old.codproc Is Null Then
	
		Select *
			Into proc
			From ad_jurproc
		 Where codproc = Nvl(:new.codproc, :old.codproc);
	
		--busca dados do processo
		Select *
			Into jur
			From ad_jurite
		 Where nupasta = proc.nupasta
			 And seq = proc.sequencia;
	
		If jur.nufin Is Not Null Then
			errmsg := 'Esse processo já possui uma despesa/adiantamento vinculado a ele.';
			Raise Error;
		End If;
	
		-- busca parâmetros jurídico
		Ad_pkg_jur.Get_param_jur(jur.Nupasta,
														 jur.Seq,
														 p.Codtopdesp,
														 p.Codtoprec,
														 p.Codtopbxrec,
														 p.Codtopbxdesp,
														 p.Codtoptransf,
														 p.Codtiptit,
														 p.Nueventojur,
														 p.Nueventofin,
														 p.Nueventoreemb,
														 p.Usulibjur,
														 p.Usulibfin,
														 p.codnatdesp,
														 p.codnatrec);
	
		-- insere financeiro
		Begin
			-- get nufin
			Stp_keygen_nufin(Fin.Nufin);
		
			ad_pkg_jur.v_Reclamante := Ad_pkg_jur.Get_nome_reclamante(jur.Nupasta);
		
			-- tratativa para numero do documento nÃ£o informado
			If Nvl(jur.Numdoc, '0') = '0' Then
				fin.numnota := ad_pkg_jur.gera_numdoc(jur.nupasta, jur.seq);
			Else
				fin.Numnota := jur.Numdoc;
			End If;
		
			fin.Historico := Substr('Despesa no valor de ' || Ad_get.Formatavalor(jur.Valor) || ' do processo ' || jur.Numprocesso ||
															' - ' || ad_pkg_jur.v_Reclamante,
															1,
															255);
		
			fin.Recdesp := 0;
		
			Stp_keygen_nufin(fin.Nufin);
		
			-- insere lançamento no financeiro
			Insert Into Tgffin
				(Nufin, Codemp, Numnota, Dtneg, Desdobramento, Dhmov, Dtvencinic, Dtvenc, Codparc, Codtipoper, Dhtipoper, Codbco, Codnat,
				 Codcencus, Codproj, Codvend, Codmoeda, Vlrdesdob, Recdesp, Provisao, Origem, Nunota, Rateado, Dtentsai, Dtalter, Codusu,
				 Codtiptit, Codctabcoint, Sequencia, Historico)
			Values
				(Fin.Nufin, jur.Codemp, fin.Numnota, Trunc(Sysdate), 1, Sysdate, jur.Dtvenc, jur.Dtvenc, jur.Codparc, p.Codtopdesp,
				 Ad_get.Maxdhtipoper(p.Codtopdesp), Nvl(jur.Codbco, 0), jur.Codnat, jur.Codcencus, 0, 0, 0, :new.Vlrtransf, fin.Recdesp,
				 'S', 'F', Null, 'N', Trunc(Sysdate), Sysdate, Stp_get_codusulogado, p.Codtiptit, :new.Codcta, 1, fin.Historico);
		
			Insert Into ad_tblcmf
				('AD_JURITE', jur.nupasta || jur.seq, 'TGFFIN', fin.nufin);
		
		Exception
			When Others Then
				errmsg := 'Financeiro não pode ser incluído. <br>' || Sqlerrm;
				Raise Error;
		End;
	
		-- atualiza JURITE
		Begin
			Update Ad_jurite
				 Set Situacao   = 'F',
						 Status     = 'A',
						 Codusudesp = Stp_get_codusulogado,
						 Dhdesp     = Sysdate,
						 Codcta     = :new.Codcta,
						 Codusujur  = p.Usulibjur,
						 Codusufin  = p.Usulibfin,
						 Nufin      = fin.Nufin
			 Where Nupasta = jur.Nupasta
				 And Seq = jur.Seq;
		Exception
			When Others Then
				Raise_Application_Error(-20105, 'Não foi possível atualizar as informações no lançamento selecionado');
		End;
	
		-- atualiza Mov. Bancária e log jur.
		Begin
			-- verifica se possui transferencia
			If Nvl(:New.numtransf, :old.Numtransf) Is Null Then
				errmsg := 'Não foi possível vincular as trasferências ao processo pois o número da transferência não foi encontrado<br>.' ||
									'Verfique se o número está registrado no lançamento ou se a transferência realmente existe';
				Raise Error;
			End If;
		
			-- percorre lançamentos da transferência
			For Log In (Select *
										From Tgfmbc
									 Where Numtransf = :new.Numtransf)
			Loop
				Begin
					ad_pkg_jur.grava_log_transf_bancaria(p_nupasta => jur.nupasta, p_seq => jur.seq, p_numtransf => :new.Numtransf);
				Exception
					When Others Then
						errmsg := 'Erro ao atualizar a aba "Lançamentos" do processo para o registro selecionado. <br>' || Sqlerrm;
						Raise Error;
				End;
			
				Begin
					Update Tgfmbc
						 Set Ad_nufinproc = fin.Nufin
					 Where nubco = log.nubco;
				Exception
					When Others Then
						errmsg := 'Erro ao vincular processo à transferência bancária.<br>' || Sqlerrm;
						Raise Error;
				End;
			
			End Loop;
		End;
	
		-- se limpando campo processo ou excluindo
	Elsif (:new.Codproc Is Null And :old.codproc Is Not Null) Or deleting Then
	
		-- verifica se foi realizado o retorno, se sim, exit
		If Nvl(:new.Dtret, :old.dtret) Is Not Null Then
		
			errmsg := 'Desbloqueio já realizado, não é possível alterar o código do processo';
			Raise Error;
		
		Else
			-- delete da jurlog
			Begin
				Delete From ad_jurlog
				 Where nupasta = jur.nupasta
					 And seq = jur.seq
					 And nubco In (Select nubco
													 From tgfmbc
													Where numtransf = Nvl(:new.Numtransf, :old.Numtransf));
			Exception
				When Others Then
					errmsg := 'Não foi possível desfazer a vinculação com a despesa jurídica.';
					Raise Error;
			End;
		
			-- limpa ad_nufinproc da tgfmbc
			Begin
				Update tgfmbc
					 Set ad_nufinproc = Null
				 Where ad_nufinproc = jur.nufin
					 And numtransf = Nvl(:new.Numtransf, :old.Numtransf);
			Exception
				When Others Then
					errmsg := 'Não foi possível atualizar a mov. bancária da transferência';
					Raise Error;
			End;
		
			-- delete da tgffin
		
			/* esse mov na fin é herança do processo original, por conta das variações do processo
      que não foram tratadas, resolvi não alterar */
		
			Begin
				Delete From tgffin
				 Where nufin = jur.nufin;
			Exception
				When Others Then
					errmsg := 'Não foi possível remover a ligação criada no financeiro.<br>' || Sqlerrm;
					Raise Error;
			End;
		
			-- verifica se cascade da fin limpou o campo da jurite
		
			/* Não foi possível usar o "set null on delete" da Fk devido erros gerados em outros processos */
			Begin
				Update ad_jurite
					 Set nufin = Null, nufincanc = jur.nufin, dhcanc = Sysdate
				 Where nupasta = jur.nupasta
					 And seq = jur.seq
					 And nufin = jur.nufin;
			Exception
				When Others Then
					errmsg := 'Não foi possível atualizar a ligação da despesa jurídica com o financeiro';
					Raise Error;
			End;
		
		End If;
	
	End If;
	-- fim informa codproc
Exception
	When error Then
		Raise_Application_Error(-20105, ad_fnc_formataerro(errmsg));
	When Others Then
		Raise_Application_Error(-20105, ad_fnc_formataerro('Erro - ' || Sqlerrm));
End;
/
