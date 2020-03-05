create or replace view ad_vw_comb as
Select
          i.codemp,
          c.nunota,
					c.codveiculo,
					c.codparc,
					c.tipmov,
					i.atualestoque,
          i.codprod,
          p.descrprod,
          c.dtentsai,
          c.dtneg,
          i.qtdneg,
          i.vlrunit,
					i.vlrdesc,
          i.vlrtot
          From Tgfite I
          Join Tgfcab C On I.Nunota = C.Nunota
          Join Ad_tsfppcp pcp On I.Codprod = pcp.Codprod
          Join Ad_tsfppct T On C.Codtipoper = T.Codtipoper
          Join tgfpro p On i.codprod = p.codprod
         Where I.Codemp = 2
           And I.Atualestoque <> 0
           And C.Statusnota = 'L'
           And pcp.Nuppc = 1
           And Nvl(T.Perdaent, 'N') = 'N'
           And Tipmov In ('C', 'Q');
