create or replace view ad_vw_fretefrango_anlt as
With vendas_subprodutos
as
(Select c.codemp , c.ordemcarga
 from tgfcab c
 Join tgfite i On c.nunota = i.nunota
 Join tgfpro p On i.codprod = p.codprod
where p.codgrupoprod in (62010000, 81040000)
 And c.statusnota = 'L'
 And c.tipmov = 'V'
 And c.ordemcarga > 0
 And c.vlrfrete > 0),
sum_oc_total As
(Select Trunc(o.dtinic,'mm') dtref,
       ger.codvend As codger,
       ger.apelido nomeger,
			 c.codemp,
       c.ordemcarga,
       t.categoria,
       v.ad_codcat codcat,
       round(Sum(c.vlrfrete),2) vlrfrete,
       Count(Distinct c.ordemcarga)       qtdordenscarga,
       round(Avg(v.pesomax),2) pesomediocat,
       round(Count(Distinct c.ordemcarga) * Avg(v.pesomax),2) capacidade,
       Round(Avg(c.ad_km),2) mediakm,
       round(Sum(nvl(c.ad_km,0)),2) kmtotal,
       round(Sum(c.peso),2) pesototal,
       round( fc_divide(Sum(c.vlrfrete) , Sum(Round(nvl(c.ad_km,1), 2))),2) vlrkm,
       round( fc_divide(Sum(c.peso) , (Count(Distinct c.ordemcarga) * Avg(v.pesomax) ) * 100),2) perc_ocupacao,
       count( Distinct c.codparc) qtdentregas
  From tgfcab c
  Join tgford o On c.codemp = o.codemp
               And c.ordemcarga = o.ordemcarga
  Join tgfvei v On c.codveiculo = v.codveiculo
  Join tgfven ven On ven.codvend = c.codvend
  Join tgfven ger On ven.codger = ger.codvend
  Left Join ad_tsfcat t On v.ad_codcat = t.codcat
 Where c.statusnota = 'L'
   And (c.tipmov = 'V' Or ((c.codtipoper = 519 And c.tipmov = 'C') Or (c.codtipoper = 532 And c.tipmov = 'T')))
   And c.ordemcarga > 0
   And c.vlrfrete > 0
   and not exists (select 1
                    from ad_centparamtop ctop
                  where ctop.codtipoper = c.codtipoper
                    and nvl(ctop.utilizacao,'X') = 'PROIBIDO'
                    and ctop.nupar = 21)
     And Not Exists (
     Select 1
         From vendas_subprodutos vsp
     Where To_Char(c.codemp)||To_Char(c.ordemcarga) = To_Char(vsp.codemp)||To_Char(vsp.ordemcarga)
     )
 Group By Trunc(o.dtinic,'mm'),c.codemp, c.ordemcarga, ger.codvend, ger.apelido, t.categoria, v.ad_codcat
 ),
 total_oc As
 (Select  codemp,
          ordemcarga,
					Sum(vlrfrete) As totalfrete,
					Sum(kmtotal) As totalkm,
					sum(pesototal) As totalpeso,
					Sum(vlrkm) As totalvlrkm,
					Sum(perc_ocupacao) As totalpercocup
  From sum_oc_total
	Group By codemp, ordemcarga)

Select t1.dtref,
       t1.codger,
       t1.nomeger,
       t1.codemp,
       t1.ordemcarga,
			 t1.qtdordenscarga,
			 t1.qtdentregas,
			 t1.codcat,
			 t1.categoria,
			 t1.pesomediocat,
			 t1.capacidade,
       sum(t2.totalfrete) totalfrete,
       sum(t2.totalkm) totalkm,
       sum(t2.totalpeso) totalpeso,
       sum(t2.totalvlrkm) totalvlrkm,
       sum(t2.totalpercocup) totalpercocup
 From Sum_oc_total t1, total_oc t2
 Where t1.codemp = t2.codemp
  And t1.ordemcarga = t2.ordemcarga
	Group By
t1.dtref,
       t1.codger,
       t1.nomeger,
       t1.codemp,
       t1.ordemcarga,
			 t1.qtdordenscarga,
			 t1.qtdentregas,
			 t1.codcat,
			 t1.categoria,
			 t1.pesomediocat,
			 t1.capacidade;
