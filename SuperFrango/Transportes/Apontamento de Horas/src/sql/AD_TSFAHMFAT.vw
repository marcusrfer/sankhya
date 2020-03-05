Create Or Replace View AD_TSFAHMFAT As
/*Select 
 0 As codempped,0 As codtipoper,
 0 As codtopped,0 As codusuincped,
 '' As descroper,
 '' As descroperped, 
 To_Date('01/01/1970')  As dtfaturped, 
 To_Date('01/01/1970')  As dtneg, 
 To_Date('01/01/1970')  As dtnegped,
 '' As nomeusuincped,
 0 As nuapont,
 0 As numnota,
 0 As numnotaped,
 0 As nunota,
 0 As nunotaped,
 0 As nuseqmaq,
 0 As seqfat,
 1.0 As vlrped 
 From dual;
*/

With notas As
 (Select v.nunota, v.nunotaorig, c.numnota, c.dtneg, c.vlrnota, c.codtipoper
    From tgfcab c
    Join tgfvar v
      On c.nunota = v.nunota)

Select Distinct a.nuapont, a.nuseqmaq, c.nunota nunotaped,
                c.numnota numnotaped,
                c.codemp codempped,
                c.dtneg dtnegped,
                c.dtfatur dtfaturped,
  							c.codtipoper CODTOPPED,
								ad_get.Nometop(c.codtipoper) descroperped,
								c.vlrnota vlrped,
								c.codusuinc codusuincped,
								ad_get.Nomeusu(c.codusuinc,'resumido') nomeusuincped,
								n.nunota,
								n.numnota,
								n.dtneg,
								n.codtipoper,
								ad_get.Nometop(n.codtipoper) DESCROPER,
								1 As seqfat
	From ad_tsfahmapd a
	Join tgfcab c
		On a.nunota = c.nunota
	Left Join notas n
		On c.nunota = n.nunotaorig
	 ;
