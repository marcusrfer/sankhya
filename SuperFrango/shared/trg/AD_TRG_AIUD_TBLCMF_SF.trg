Create Or Replace Trigger AD_TRG_AIUD_TBLCMF_SF
	After Insert Or Update Or Delete On SANKHYA.AD_TBLCMF
	For Each Row
Declare
	v ad_tblcmf%Rowtype;
Begin

	If deleting Then
	
		v.nometaborig := :old.Nometaborig;
		v.nometabdest := :old.Nometabdest;
		v.nuchaveorig := :old.Nuchaveorig;
		v.nuchavedest := :old.Nuchavedest;
	
		/* Ao excluir o pedido de compras referente ao apontamento, marca os apontamentos como pendnetes*/
		If v.nometaborig = 'AD_TSFAHMC' Then
			Begin
				Update ad_tsfahmapd a
					 Set a.dtfecha = Null, a.faturado = 'N', a.nunota = Null --, a.origem = 0
				 Where a.nuapont = v.nuchaveorig
					 And a.nunota = v.nuchavedest;
			Exception
				When Others Then
					Raise;
			End;
		End If;
	
		If v.nometaborig = 'TCSCON' Then
			Declare
				v_Parcela Number;
			Begin
			
				Select c.parcelaatual
					Into v_parcela
					From tcscon c
				 Where numcontrato = v.nuchaveorig;
			
				If v_parcela <> 0 Or v_parcela Is Not Null Then
					Begin
						Update tcscon
							 Set parcelaatual = parcelaatual - 1
						 Where numcontrato = v.nuchaveorig;
					Exception
						When Others Then
							Raise;
					End;
				End If;
			End;
		End If;
	
		If v.nometaborig = 'TCSCON' Then
			Begin
				Update Ad_tsfdfc d
					 Set d.Compensado = 'N', nunota = Null
				 Where Compensado = 'S'
					 And Numcontrato = V.Nuchaveorig;
			Exception
				When Others Then
					Insert Into Tsilog
						(Codusu, Dhevento, Descricao, Computador, Sequencia)
					Values
						(Stp_get_codusulogado(),
						 Sysdate,
						 'Erro ao desfazer a compensação do desconto no contrato.',
						 Ad_get.Nomemaquina(),
						 Null);
			End;
		End If;
	
		If v.nometaborig = 'AD_TSFDEF' Then
			Begin
				Update ad_tsfdef d
					 Set d.status = 'L'
				 Where d.nudef = v.nuchaveorig;
			Exception
				When Others Then
					Raise;
			End;
		End If;
	
	End If;

End AD_TRG_AIUD_TBLCMF_SF;
/
