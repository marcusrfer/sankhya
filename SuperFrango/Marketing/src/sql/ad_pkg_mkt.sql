Create Or Replace Package ad_pkg_mkt Is

			Procedure inserir_ocorrencia(p_nucmkt Number, texto Varchar2, msg Out Varchar2);
End ad_pkg_mkt;
/
Create Or Replace Package Body "AD_PKG_MKT" Is

			Procedure inserir_ocorrencia(p_nucmkt Number, texto Varchar2, msg Out Varchar2) As
						v_nuimkt Number;
						c        ad_tsfcmkt%Rowtype;
			Begin
			
						Select * Into c From ad_tsfcmkt Where nucmkt = p_nucmkt;
			
						Begin
									Select Nvl(Max(nuimkt), 0) + 1 Into v_nuimkt From Ad_tsfimkt Where nucmkt = p_Nucmkt;
									Insert Into Ad_tsfimkt
												(Nucmkt, Nuimkt, Codusuint, Contato, Dhcontato, Ocorrencia, Status)
									Values
												(p_Nucmkt, v_nuimkt, stp_get_codusulogado, 'S', Sysdate, texto, 'C');
						Exception
									When Others Then
												msg := 'Erro ao inserir interação. - ' || Sqlerrm;
												Return;
						End;
			
						--Atualiza histórico briefing
						Begin
									Update Ad_tsfsmkt
												Set Detagencia = Detagencia || Chr(13) || To_Char(Sysdate, 'dd/mm/yyyy hh24:mi:ss') || ' - ' || texto
										Where nusmkt = c.nusmkt;
						Exception
									When Others Then
												msg := 'Erro ao atualizar historico. - ' || Sqlerrm;
												Return;
						End;
			End inserir_ocorrencia;
End ad_pkg_mkt;
/
