-- faltosos
select empresa, matricula, dtadm, codlot, descrlot, dtinisit, codsit, descrsit, count(*)
  from (select fucodemp empresa, fumatfunc matricula, to_char(epdata, 'DD/MM/YYYY') data,
                sankhya.fmt.number_to_date(f.fudtadmis) dtadm, f.fucodlot codlot, l.lodesclot descrlot,
                sankhya.fmt.number_to_date(f.fudtinisit) dtinisit, f.fucodsitu codsit, s.stdescsitu descrsit
           from fpwpower.funciona f, fpwpower.entrpont, fpwpower.lotacoes l, fpwpower.situacao s
          where epempsis = fucodemp
            and epmatricula = fumatfunc
            and epirreent = 5
            and epjustent = 0
            and f.fucodemp = 1
            and f.fucodemp = l.locodemp
            and f.fucodlot = l.locodlot
            and f.fucodsitu = s.stcodsitu
            and f.fucodemp = s.stcodemp
            and epdata between '10/08/2019' and '26/08/2019'
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
          order by fumatfunc, epdata)
 where codsit not in (select ss.codsit
                        from ad_prhsit ss
                       where ss.nuprh = 1
                         and ss.gruporel = 'R')
 group by empresa, matricula, dtadm, codlot, descrlot, dtinisit, codsit, descrsit
having count(*) > 5;
