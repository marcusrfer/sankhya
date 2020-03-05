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
		
				/* Tratativa para quando a multa é inserida a partir da notificação */
				If :new.dtvencto Is Null And :new.Codbarra Is Null And
							(:new.Valormulta Is Null Or :new.Valormulta = 0) Then
						Return;
				End If;
		
				v_diavencto := To_Char(:new.Dtvencto, 'd');
		
				If v_diavencto In ('1', '7') Then
						errmsg := 'O dia do vencimento não pode ser um fim de semana!';
						Raise error;
				End If;
		
				If trunc(:new.Dtvencto) = trunc(Sysdate) Then
						errmsg := 'A data do vencimeto deve respeitar a data mínima de vencimneto estipulada pelo financeiro.';
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
						errmsg := 'O parceiro desta Ordem de Carga não está ativo.';
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
								errmsg := 'Código de barras com tamanho inválido (' || v_tamcodbar || ').';
								Raise error;
						Elsif v_tamcodbar <> 48 And v_Convenio = 'S' Then
								errmsg := 'Código de barras com tamanho inválido (' || v_tamcodbar || ').';
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
								errmsg := 'Se há desconto, o percentual deve ser informado.';
								Raise error;
						End If;
				
						If (:old.Vlrdesconto Is Null Or :old.Vlrdesconto = 0) Or
									(:old.Percdesc Is Null Or :old.Percdesc = 0) Then
								v_vlrdesc := Round(v_valor * (:new.Percdesc / 100), 2);
								:new.Vlrdesconto := v_vlrdesc;
								:new.Percdesc := v_percdesc;
						
								/* código comentado devido os centavos de diferença entre o valor calculado e o valor dos desconto no documento, não existe padrão, portato, vai preencher inicialmente, mas o campo
        ficará aberto permitindo alteração   - Marcus Rangel 
        Else
        v_vlrdesc        := round(v_valor * (:new.Percdesc / 100), 1);
        v_percdesc       := :new.Percdesc;
        :new.Vlrdesconto := v_vlrdesc;
        :new.Percdesc    := v_percDesc; */
						End If;
				End If;
		
				-- valida o parceiro e o código de barras
				Begin
				
						Begin
								Select 1 Into v_Count From ad_mulparcod c Where c.codparc = :new.Codparc;
						Exception
								When no_data_found Then
										v_Count := 0;
						End;
				
						If v_count <> 1 Then
								errmsg := 'Parceiro não está apto a ser usado nesta rotina.';
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
								errmsg := 'O código de barras não pertence ao parceiro. Verifique o código e tente novamente.';
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
						errmsg := 'Não existe essa Ordem de Carga para essa Empresa.';
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
		
				V_TITAVI := 'Liberação de Multa Pendente';
		
				Begin
						Select PAR.NOMEPARC
								Into V_NOMEPAR
								From TGFORD ORD, TGFPAR PAR
							Where ORD.CODEMP = :NEW.CODEMP
									And ORD.ORDEMCARGA = :NEW.ORDEMCARGA
									And ORD.CODPARCTRANSP = PAR.CODPARC;
				Exception
						When NO_DATA_FOUND Then
								V_NOMEPAR := 'TRANSPORTADORA NÃO INFORMADA';
				End;
		
		Elsif UPDATING Then
		
				If :old.Situacao = 'AL' And :new.Situacao = 'AL' Then
						errmsg := 'Lançamentos <b>"Aguardando liberação"</b> não podem ser alterados. Desfaça a liberação, altere o lançamento e refaça o envio para liberação.';
						Raise error;
				End If;
		
				If :old.Situacao = 'A' And :new.Situacao = 'A' Then
						errmsg := 'Lançamentos <b>"Autorizados"</b> não podem ser alterados.';
						Raise error;
				End If;
		
				If :old.Situacao = 'N' And :new.Situacao = 'N' Then
						errmsg := 'Lançamentos <b>"Não Autorizados"</b> não podem ser alterados.';
						Raise error;
				End If;
		
				If updating('PERCEDESC') Then
						:new.Vlrdesconto := :new.Valormulta * (1 - (:new.Percdesc / 100));
				End If;
		
				V_CODUSUREM := stp_get_codusulogado;
				V_CODUSUDEST := :OLD.CODUSUCAD;
		
				/*    If :old.Situacao = 'A' Then
          raise_application_error(-20105, ad_fnc_formataerro('Multas autorizadas não podem ser alteradas.'));
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
								errmsg := 'Não existe essa Ordem de Carga para essa Empresa.';
								Raise error;
						End If;
				
						If (:OLD.SITUACAO = 'P' Or :old.situacao = 'AL') And :NEW.SITUACAO = 'A' Then
								-- AUTORIZADO
								V_SITUACAO := '<FONT COLOR="BLUE">AUTORIZADO</FONT>';
								V_TITAVI := 'Liberação de Multa Autorizada';
						
						Elsif :OLD.SITUACAO = 'P' And :NEW.SITUACAO = 'N' Then
								-- NÃO AUTORIZADO
								V_SITUACAO := '<FONT COLOR="RED">NÃO AUTORIZADO</FONT>';
								V_TITAVI := 'Liberação de Multa Não Autorizada';
						
								/* Else
          V_SITUACAO := '<FONT COLOR="RED">OCORREU UM PROBLEMA</FONT>';
          V_TITAVI   := 'Ocorreu um problema.';
        */
						Elsif :old.Situacao = 'P' And :new.Situacao = 'AL' Then
								V_SITUACAO := 'AGUARDANDO LIBERAÇÂO';
								V_TITAVI := 'Solicitação de Liberação de Multa';
						Elsif :old.Situacao = 'AL' And :new.Situacao = 'N' Then
								V_SITUACAO := 'Autorização Reprovada';
								V_TITAVI := 'Solicitação de Liberação Negada.';
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
						P_MENSAGEM := P_MENSAGEM || '<B>SITUAÇÃO: ' || V_SITUACAO || '</BR>';
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
											Nvl(V_TITAVI, 'Não Informado'),
											'<a title="Abrir Tela" href="' || V_LINK_AVISO || '">Autuação ' || :NEW.CODAUTUACAO ||
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
										errmsg := 'Erro ao enviar avisos sobre liberação do controle de multas. ' || Sqlerrm;
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
								errmsg := 'lançamento não pode ser excluído por possuir lançamentos posteriores.';
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
