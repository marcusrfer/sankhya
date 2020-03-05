Create Or Replace Trigger AD_TRG_AIUD_TSFDEF_GERAL
	After Insert Or Update Or Delete On ad_tsfdef
	For Each Row
Declare
	vNudef  Number;
	vNudefp Number;
	vNumOC  Number;
Begin
	/*
  Autor: Marcus Rangel
  Processo: Despesas Extras de Frete
  Objetivo: Inserir os parceiros da ordem de carga selecionda na tela de despesas extras de frete
  */
	If inserting Then
	
		vNudef := :new.Nudef;
		vNumOC := :New.Ordemcarga;
	
		Begin
			Select Nvl(Max(nudefp), 0) + 1
				Into vNudefp
				From ad_tsfdefp p
			 Where p.nudef = vnudef;
		Exception
			When Others Then
				Raise;
		End;
	
		For P In (Select Distinct c.codparc, p.codcid, p.codvend
								From tgfcab c, tgfpar p
							 Where c.ordemcarga = vnumOC
								 And c.codparc = p.codparc)
		Loop
			Begin
				Insert Into ad_tsfdefp
					(nudef, nudefp, codparc, codcid, codvend)
				Values
					(vNudef, vNudefp, p.Codparc, p.Codcid, p.Codvend);
			
				vnudefp := vNudefp + 1;
			Exception
				When Others Then
					Raise;
			End;
		End Loop;
	End If;
End;
/
