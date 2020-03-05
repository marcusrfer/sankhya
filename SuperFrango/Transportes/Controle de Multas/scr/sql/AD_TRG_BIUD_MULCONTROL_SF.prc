Create Or Replace Trigger AD_TRG_BIUD_MULCONTROL_SF
		Before Insert Or Update Or Delete On SANKHYA.AD_MULCONTROL
		For Each Row
Declare

		V_SEQAVI TGFNUM.ULTCOD%Type;
		V_TITAVI Varchar2(100);
		V_NOMEPAR TGFPAR.RAZAOSOCIAL%Type;
		P_MENSAGEM Varchar2(4000);
		V_LINK_AVISO Varchar2(2000);
		V_SITUACAO Varchar2(100);
		V_CODUSUREM TSIUSU.CODUSU%Type;
		V_CODUSUDEST TSIUSU.CODUSU%Type;
		V_CODUSURESP TSIUSU.CODUSU%Type;
		ERRMSG Varchar2(4000);

		v_codBar Varchar2(100);
		v_tamCodBar Int;
		v_Instr Int;
		v_Count Int;
		r_Par ad_mulparcod%Rowtype;
		v_String1 Varchar2(100);
		v_VlrTemp Varchar2(100);
		v_Valor Number(10, 2);
		v_percDesc Number(10, 2);
		v_VlrDesc Number(10, 2);
		v_DiaVencto Char(1);
		v_Convenio Char(1);
		Error Exception;

Begin

		If STP_GET_ATUALIZANDO Then
				Return;
		End If;

		If Not deleting Then
		
				/* Tratativa para quando a multa � inserida a partir da notifica��o */
				If :new.dtvencto Is Null And :new.Codbarra Is Null And
							(:new.Valormulta Is Null Or :new.Valormulta = 0) Then
						Return;
				End If;
		
				v_diavencto := To_Char(:new.Dtvencto, 'd');
		
				If v_diavencto In ('1', '7') Then
						errmsg := 'O dia do vencimento n�o pode ser um fim de semana!';
						Raise error;
				End If;
		
				If trunc(:new.Dtvencto) = trunc(Sysdate) Then
						errmsg := 'A data do vencimeto deve respeitar a data m�nima de vencimneto estipulada pelo financeiro.';
						Raise error;
				End If;
		
				:new.Codautuacao := upper(ltrim(rtrim(:new.Codautuacao)));
		
				Begin
						Select 1
								Into v_count
								From tgford o
							Inner Join tgfpar p On (o.codparctransp = p.codparc And p.ativo = 'S')
							Where o.ordemcarga = :new.Ordemcarga
									And o.codemp = :new.Codemp;
				Exception
						When Others Then
								v_Count := 0;
				End;
		
				If v_count = 0 Then
						errmsg := 'O parceiro desta Ordem de Carga n�o est� ativo.';
						Raise error;
				End If;
		
				Begin
						v_tamCodBar := length(Nvl(:new.Codbarra, :old.Codbarra));
				
						Begin
								Select Nvl(convenio, 'N') Into v_Convenio From ad_mulparcod Where codparc = :new.Codparc;
						Exception
								When Others Then
										v_Convenio := 'N';
						End;
				
						If v_tamCodBar <> 47 And v_Convenio = 'N' Then
								errmsg := 'C�digo de barras com tamanho inv�lido (' || v_tamcodbar || ').';
								Raise error;
						Elsif v_tamcodbar <> 48 And v_Convenio = 'S' Then
								errmsg := 'C�digo de barras com tamanho inv�lido (' || v_tamcodbar || ').';
						End If;
				
				End;
		
				If v_Convenio = 'N' Then
						v_vlrtemp := Substr(:new.codbarra, length(:new.Codbarra) - 9, length(:new.Codbarra));
						v_valor := Cast(To_Char(v_vlrtemp, 99999999.99) As Float);
				Else
						v_Valor := Substr(Codbar(:new.codbarra, length(:new.codbarra)), 5, 11) / 100; --  ad_get.valorGuiaRecolhimento(:new.Codbarra);
				End If;
		
				:new.Valormulta := v_valor;
		
				v_count := 0;
		
				Begin
						Select 1, percdesc
								Into v_Count, v_percDesc
								From ad_mulparcod m
							Where m.codparc = :new.Codparc
									And m.descobrig = 'S';
				Exception
						When Others Then
								v_count := 0;
								v_percdesc := :new.Percdesc;
				End;
		
				If v_count = 1 Then
						:new.Temdesconto := 'S';
				End If;
		
				If Nvl(:new.Temdesconto, 'N') = 'S' Then
				
						If :new.Percdesc Is Null Or :new.Percdesc = 0 And v_count = 0 Then
								errmsg := 'Se h� desconto, o percentual deve ser informado.';
								Raise error;
						End If;
				
						If (:old.Vlrdesconto Is Null Or :old.Vlrdesconto = 0) Or
									(:old.Percdesc Is Null Or :old.Percdesc = 0) Then
								v_vlrdesc := Round(v_valor * (:new.Percdesc / 100), 2);
								:new.Vlrdesconto := v_vlrdesc;
								:new.Percdesc := v_percdesc;
						
								/* c�digo comentado devido os centavos de diferen�a entre o valor calculado e o valor dos desconto no documento, n�o existe padr�o, portato, vai preencher inicialmente, mas o campo
        ficar� aberto permitindo altera��o   - Marcus Rangel 
        Else
        v_vlrdesc        := round(v_valor * (:new.Percdesc / 100), 1);
        v_percdesc       := :new.Percdesc;
        :new.Vlrdesconto := v_vlrdesc;
        :new.Percdesc    := v_percDesc; */
						End If;
				End If;
		
				-- valida o parceiro e o c�digo de barras
				Begin
				
						Begin
								Select 1 Into v_Count From ad_mulparcod c Where c.codparc = :new.Codparc;
						Exception
								When no_data_found Then
										v_Count := 0;
						End;
				
						If v_count <> 1 Then
								errmsg := 'Parceiro n�o est� apto a ser usado nesta rotina.';
								Raise error;
						End If;
				
						Select * Into r_Par From ad_mulparcod Where codparc = :new.codparc;
				
						If Instr(r_par.codbar, '$', 1, 1) > 0 Then
						
								v_String1 := Substr(r_par.codbar, Instr(r_par.codbar, '_', 1, 1) + 1, length(r_par.codbar));
						
								If v_string1 = 'CODATUACAO' Then
										v_codBar := ltrim(Substr(:new.codautuacao, 3, length(:new.Codautuacao)));
										v_Instr := Instr(:new.codbarra, v_codbar, 1, 1);
								End If;
						
						Else
								v_Instr := Instr(Substr(:new.codbarra, 1, length(:new.Codbarra) - 10), r_par.codbar, 1, 1);
						End If;
				
						If v_Instr = 0 Then
								errmsg := 'O c�digo de barras n�o pertence ao parceiro. Verifique o c�digo e tente novamente.';
								Raise error;
						End If;
				
				End;
		
		End If;

		If INSERTING Then
		
				/*    Select NVL(CUS.CODUSURESP, 0)
     Into V_CODUSURESP
     From AD_MULPAR PAR, TSICUS CUS
    Where PAR.CODEMP = 1
      And PAR.CODCENCUSPAG = CUS.CODCENCUS;*/
				Begin
						Select Count(*)
								Into v_Count
								From tgford o
							Where o.ordemcarga = :new.Ordemcarga
									And o.codemp = :new.Codemp;
				Exception
						When Others Then
								v_Count := 0;
				End;
		
				If v_Count = 0 Then
						errmsg := 'N�o existe essa Ordem de Carga para essa Empresa.';
						Raise error;
				End If;
		
				Begin
						Select codusu
								Into v_codusuresp
								From tsiusu u
							Where Nvl(u.ad_gertransp, 'N') = 'S'
									And rownum = 1;
				Exception
						When Others Then
								v_codusuresp := 0;
				End;
		
				:NEW.SITUACAO := 'P'; -- Pendente
				V_SITUACAO := 'PENDENTE';
				V_CODUSUREM := :NEW.CODUSUCAD;
		
				:NEW.CODUSULIB := V_CODUSURESP;
				V_CODUSUDEST := :NEW.CODUSULIB;
		
				V_TITAVI := 'Libera��o de Multa Pendente';
		
				Begin
						Select PAR.NOMEPARC
								Into V_NOMEPAR
								From TGFORD ORD, TGFPAR PAR
							Where ORD.CODEMP = :NEW.CODEMP
									And ORD.ORDEMCARGA = :NEW.ORDEMCARGA
									And ORD.CODPARCTRANSP = PAR.CODPARC;
				Exception
						When NO_DATA_FOUND Then
								V_NOMEPAR := 'TRANSPORTADORA N�O INFORMADA';
				End;
		
		Elsif UPDATING Then
		
				If :old.Situacao = 'AL' And :new.Situacao = 'AL' Then
						errmsg := 'Lan�amentos <b>"Aguardando libera��o"</b> n�o podem ser alterados. Desfa�a a libera��o, altere o lan�amento e refa�a o envio para libera��o.';
						Raise error;
				End If;
		
				If :old.Situacao = 'A' And :new.Situacao = 'A' Then
						errmsg := 'Lan�amentos <b>"Autorizados"</b> n�o podem ser alterados.';
						Raise error;
				End If;
		
				If :old.Situacao = 'N' And :new.Situacao = 'N' Then
						errmsg := 'Lan�amentos <b>"N�o Autorizados"</b> n�o podem ser alterados.';
						Raise error;
				End If;
		
				If updating('PERCEDESC') Then
						:new.Vlrdesconto := :new.Valormulta * (1 - (:new.Percdesc / 100));
				End If;
		
				V_CODUSUREM := stp_get_codusulogado;
				V_CODUSUDEST := :OLD.CODUSUCAD;
		
				/*    If :old.Situacao = 'A' Then
          raise_application_error(-20105, ad_fnc_formataerro('Multas autorizadas n�o podem ser alteradas.'));
        End If;
    */
				If updating('SITUACAO') Then
				
						v_count := 0;
						Begin
								Select Count(*)
										Into v_Count
										From tgford o
									Where o.ordemcarga = :new.Ordemcarga
											And o.codemp = :new.Codemp;
						Exception
								When Others Then
										v_Count := 0;
						End;
				
						If v_Count = 0 Then
								errmsg := 'N�o existe essa Ordem de Carga para essa Empresa.';
								Raise error;
						End If;
				
						If (:OLD.SITUACAO = 'P' Or :old.situacao = 'AL') And :NEW.SITUACAO = 'A' Then
								-- AUTORIZADO
								V_SITUACAO := '<FONT COLOR="BLUE">AUTORIZADO</FONT>';
								V_TITAVI := 'Libera��o de Multa Autorizada';
						
						Elsif :OLD.SITUACAO = 'P' And :NEW.SITUACAO = 'N' Then
								-- N�O AUTORIZADO
								V_SITUACAO := '<FONT COLOR="RED">N�O AUTORIZADO</FONT>';
								V_TITAVI := 'Libera��o de Multa N�o Autorizada';
						
								/* Else
          V_SITUACAO := '<FONT COLOR="RED">OCORREU UM PROBLEMA</FONT>';
          V_TITAVI   := 'Ocorreu um problema.';
        */
						Elsif :old.Situacao = 'P' And :new.Situacao = 'AL' Then
								V_SITUACAO := 'AGUARDANDO LIBERA��O';
								V_TITAVI := 'Solicita��o de Libera��o de Multa';
						Elsif :old.Situacao = 'AL' And :new.Situacao = 'N' Then
								V_SITUACAO := 'Autoriza��o Reprovada';
								V_TITAVI := 'Solicita��o de Libera��o Negada.';
						End If;
				
						V_LINK_AVISO := ad_fnc_urlskw('AD_MULCONTROL', :new.Codmulcont);
				
						-- Montagem do texto do aviso
						P_MENSAGEM := '<HTML><HEAD><meta http-equiv="Content-Type" content="text/html;charset=ISO-8859-1"><title>CONTROLE DE MULTAS</title></head><font size=3>';
						P_MENSAGEM := P_MENSAGEM || '<B>' || V_TITAVI || '</B></BR>';
						P_MENSAGEM := P_MENSAGEM || '<B>TRANSPORTADORA</B>: ' || V_NOMEPAR || '</BR>';
						P_MENSAGEM := P_MENSAGEM || '<B>VALOR: </B>' || To_Char(:NEW.VALORMULTA, 'FM999G999G990D00') ||
																				'</BR>';
						P_MENSAGEM := P_MENSAGEM || '<B>VENCIMENTO: </B>' || To_Char(:NEW.DTVENCTO, 'DD/MM/YYYY') ||
																				'</BR>';
						P_MENSAGEM := P_MENSAGEM || '<B>SITUA��O: ' || V_SITUACAO || '</BR>';
						P_MENSAGEM := P_MENSAGEM || '</font></BODY></HTML>';
				
						/*      
      Select NVL(NUM.ULTCOD, 0) + 1
        Into V_SEQAVI
        From TGFNUM NUM
       Where NUM.ARQUIVO = 'TSIAVI'
         And NUM.CODEMP = 1;
            
      Update TGFNUM NUM
         Set NUM.ULTCOD = V_SEQAVI
       Where NUM.ARQUIVO = 'TSIAVI'
         And NUM.CODEMP = 1;
       */
				
						Select Max(nuaviso) + 1 Into v_seqavi From tsiavi;
				
						-- Envia aviso de sistema
						Begin
								Insert Into tsiavi
										(NUAVISO,
											TITULO,
											DESCRICAO,
											SOLUCAO,
											IDENTIFICADOR,
											IMPORTANCIA,
											CODUSU,
											CODGRUPO,
											TIPO,
											DHCRIACAO,
											CODUSUREMETENTE,
											NUAVISOPAI,
											DTEXPIRACAO,
											DTNOTIFICACAO,
											ORDEM)
								Values
										(V_SEQAVI,
											Nvl(V_TITAVI, 'N�o Informado'),
											'<a title="Abrir Tela" href="' || V_LINK_AVISO || '">Autua��o ' || :NEW.CODAUTUACAO ||
											'</a></br></br>' || P_MENSAGEM,
											Null,
											'LIBERACAO_MULTA',
											3,
											V_CODUSUDEST,
											Null,
											'P',
											Sysdate,
											V_CODUSUREM,
											Null,
											Null,
											Sysdate,
											Null);
						Exception
								When Others Then
										errmsg := 'Erro ao enviar avisos sobre libera��o do controle de multas. ' || Sqlerrm;
										raise_application_error(-20105, ad_fnc_formataerro(errmsg));
						End;
				End If;
		
		Elsif deleting Then
				For M In (Select *
																From tsilib
															Where tabela = 'AD_MULCONT'
																	And nuchave = :Old.Codmulcont)
				Loop
						If m.dhlib Is Null And :old.nufin Is Null Then
								Delete From tsilib
									Where tabela = m.tabela
											And nuchave = m.nuchave;
						Else
								errmsg := 'lan�amento n�o pode ser exclu�do por possuir lan�amentos posteriores.';
								Raise error;
						End If;
				End Loop;
		End If;

Exception
		When error Then
				raise_application_error(-20105, ad_fnc_formataerro(errmsg));
		When Others Then
				errmsg := Sqlerrm;
				raise_application_error(-20105, ad_fnc_formataerro(errmsg));
End;
/
