create or replace view AD_TSFAHMRAD as
Select 0 As SEQRAD, DTAPONT, NUAPONT, NUSEQMAQ, QTDNEG, CODVOL, TOTHORAS, VLRUNIT, (TOTHORAS*VLRUNIT) VLRTOTAL
From (
     Select
     td.DTAPONT,
     td.NUAPONT,
		 td.nuseqmaq,
		 m.codvol,
		 Case When td.codvol = 'HR' Then
			 ad_get.formata_valor_hora(td.tothoras) -- retorna number
			 Else
				 td.tothoras
			 End As QTDNEG,
     to_number(td.TOTHORAS) TOTHORAS,
     to_number(ad_pkg_ahm.get_vlr_atualapont(p_numcontrato => td.numcontrato,
                                             p_codsolst    => m.codsolst,
                                             p_nussti      => m.nussti,
																						 p_seqmaq      => m.seqmaq,
                                             p_dtapont     => td.dtapont)) As VLRUNIT
     From ad_tsfahmtad td
     Join ad_tsfahmmaq m On td.nuapont = m.nuapont
		                     And td.nuseqmaq = m.nuseqmaq
					Where nvl(td.pendente,'N') = 'S'

)
;
