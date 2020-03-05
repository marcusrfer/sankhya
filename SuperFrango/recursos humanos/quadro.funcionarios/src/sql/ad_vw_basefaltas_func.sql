-- faltosos
Create Or Replace View ad_vw_basefaltas_func
As
select empresa, matricula, nomefunc, dtadm, codlot, descrlot, posicao, descrpos, dtinisit, codsit, descrsit,
       count(*) qtdfaltas
  from (
         
         select fucodemp empresa, fumatfunc matricula, f.funomfunc nomefunc,
                 to_char(epdata, 'dd/mm/yyyy') dtfalta, sankhya.fmt.number_to_date(f.fudtadmis) dtadm,
                 f.fucodlot codlot, l.lodesclot descrlot, f.fucodgrphie posicao, gh.ghdesc descrpos,
                 sankhya.fmt.number_to_date(f.fudtinisit) dtinisit, f.fucodsitu codsit, s.stdescsitu descrsit
           from fpwpower.funciona f, fpwpower.entrpont, fpwpower.lotacoes l, fpwpower.situacao s,
                 fpwpower.grphierarquico gh
          where epempsis = fucodemp
            and epmatricula = fumatfunc
            and epirreent = 5
            and epjustent = 0
            and f.fucodemp = 1
            and f.fucodemp = l.locodemp
            and f.fucodlot = l.locodlot
            and f.fucodsitu = s.stcodsitu
            and f.fucodemp = s.stcodemp
            and f.fucodgrphie = gh.ghcodgrphie
            and f.fucodemp = gh.ghcodemp
            and epdata between Trunc(sysdate) - 15 and Trunc(sysdate) 
            and exists (select 1
                   from ad_prhsit ss
                  where ss.codsit = f.fucodsitu
                    and ss.nuprh = 1
                    and ss.gruporel = 'A'
                    and ss.subgruporel is null)
            and not exists
          (select 1
                   from fpwpower.ocorfunc, fpwpower.situacao
                  where ofcodemp = f.fucodemp
                    and ofmatfunc = f.fumatfunc
                    and ofcodocorr in (1001, 1002, 1007)
                    and ofdtinioco <= to_number(to_char(epdata, 'YYYYMMDD'))
                    and ofdtfinoco >= to_number(to_char(epdata, 'YYYYMMDD') + decode(sttipositu, 'A', 1, 0))
                    and stcodemp = 1
                    and stcodsitu = ofcodproxs
                    and sttipositu in ('A', 'F'))
         
          order by fumatfunc, epdata
         
         )
 group by empresa, matricula, nomefunc, dtadm, codlot, descrlot, posicao, descrpos, dtinisit, codsit, descrsit
having count(*) > 5;
