create or replace procedure ad_stp_icm_credoutprot_sf(p_codemp number, p_dtref date) is
begin

 begin
 
  delete ad_adcredoutprot9vi vi
   where vi.empresa = p_codemp
     and vi.referencia = p_dtref;
 
  insert /*+ APPEND NOLOGGING */
  into ad_adcredoutprot9vi
   select /*+ PARALLEL(AUTO) */
    codemp, p_dtref, nunota, sequencia, option_label('TGFLIV', 'ORIGEM', origem) as origem, dhmov, dtdoc,
    codprod, descrprod, ncm, codcfo, codgrupoprod, descrgrupoprod, (vlrctb) as vlrctb, (baseicms) as baseicms,
    aliqicms, (vlricms) as vlricms, aliqefetiva, 9 as aliq_outor, credito_outor as credito_outor, aliq_protege,
    credito_outor * aliq_protege / 100 as protege, numnota
     from (select l.codemp, l.nunota, l.sequencia, l.origem, l.numnota, l.dhmov, l.dtdoc, p.codprod,
                   p.descrprod, p.ncm, l.codcfo, g.codgrupoprod, g.descrgrupoprod,
                   (l.vlrctb * (case
                    when l.codcfo < 5000 then
                     -1
                    else
                     1
                   end)) as vlrctb,
                   (l.baseicms * (case
                    when l.codcfo < 5000 then
                     -1
                    else
                     1
                   end)) as baseicms, l.aliqicms,
                   (l.vlricms * (case
                    when l.codcfo < 5000 then
                     -1
                    else
                     1
                   end)) as vlricms,
                   round(func_divide_sf(l.vlricms,
                                         l.vlrctb - decode(top.somasubst, 'S', l.icmsretencao, 0) - l.vlripi) * 100,
                          1) as aliqefetiva,
                   (l.baseicms * 0.09 * (case
                    when l.codcfo < 5000 then
                     -1
                    else
                     1
                   end)) as credito_outor, func_aliq_protege_sf(1, trunc(l.dhmov, 'MON')) as aliq_protege
              from tgfliv l
             inner join tgfcab c
                on (c.nunota = l.nunota and l.origem in ('E', 'A'))
             inner join tgfite i
                on (i.nunota = l.nunota and i.sequencia = l.sequencia)
             inner join tgfpro p
                on (p.codprod = i.codprod)
             inner join tgfgru g
                on (g.codgrupoprod = p.codgrupoprod)
             inner join tgfpar par
                on (par.codparc = c.codparc)
             inner join tgftop top
                on (top.codtipoper = c.codtipoper and top.dhalter = c.dhtipoper)
             where to_char(l.dhmov, 'YYYYMM') = to_char(p_dtref, 'YYYYMM')
               and l.codemp = p_codemp
               and exists (select 1
                      from ad_relparmcfop cf
                     where cf.nurelparm = 1
                       and cf.codcfo = l.codcfo)
               and exists (select 1
                      from ad_relparmgrup gr
                     where gr.nurelparm = 1
                       and gr.codgrupoprod = p.codgrupoprod));
 
 exception
  when others then
   null;
 end;

 begin
  delete ad_credoutprot9lxvi lxvi
   where lxvi.empresa = p_codemp
     and lxvi.referencia = p_dtref;
 
  insert /*+ APPEND NOLOGGING */
  into ad_credoutprot9lxvi
   select /*+ PARALLEL(AUTO) */
    codemp, p_dtref, nunota, sequencia, option_label('TGFLIV', 'ORIGEM', origem) as origem, dhmov, dtdoc,
    codprod, descrprod, ncm, codgrupoprod, descrgrupoprod, (vlrctb) as vlrctb, (baseicms) as baseicms,
    aliqicms, (vlricms) as vlricms, aliqefetiva, 9 as aliq_outor, credito_outor as credito_outor, aliq_protege,
    credito_outor * aliq_protege / 100 as protege, codcfo, numnota
     from (select l.codemp, l.nunota, l.sequencia, l.origem, l.numnota, l.dhmov, l.dtdoc, p.codprod,
                   p.descrprod, p.ncm, l.codcfo, g.codgrupoprod, g.descrgrupoprod,
                   (l.vlrctb * (case
                    when l.codcfo < 5000 then
                     -1
                    else
                     1
                   end)) as vlrctb,
                   (l.baseicms * (case
                    when l.codcfo < 5000 then
                     -1
                    else
                     1
                   end)) as baseicms, l.aliqicms,
                   (l.vlricms * (case
                    when l.codcfo < 5000 then
                     -1
                    else
                     1
                   end)) as vlricms,
                   round(func_divide_sf(l.vlricms,
                                         l.vlrctb - decode(top.somasubst, 'S', l.icmsretencao, 0) - l.vlripi) * 100,
                          1) as aliqefetiva,
                   (l.baseicms * 0.09 * (case
                    when l.codcfo < 5000 then
                     -1
                    else
                     1
                   end)) as credito_outor, func_aliq_protege_sf(1, trunc(l.dhmov, 'MON')) as aliq_protege
              from tgfliv l
             inner join tgfcab c
                on (c.nunota = l.nunota and l.origem in ('E', 'A'))
             inner join tgfite i
                on (i.nunota = l.nunota and i.sequencia = l.sequencia)
             inner join tgfpro p
                on (p.codprod = i.codprod)
             inner join tgfgru g
                on (g.codgrupoprod = p.codgrupoprod)
             inner join tgfpar par
                on (par.codparc = c.codparc)
             inner join tgftop top
                on (top.codtipoper = c.codtipoper and top.dhalter = c.dhtipoper)
             where to_char(l.dhmov, 'YYYYMM') = to_char(p_dtref, 'YYYYMM')
               and l.codemp = p_codemp
               and exists (select 1
                      from ad_relparmcfop cf
                     where cf.nurelparm = 2
                       and cf.codcfo = l.codcfo)
               and exists (select 1
                      from ad_relparmgrup gr
                     where gr.nurelparm = 2
                       and gr.codgrupoprod = p.codgrupoprod));
 exception
  when others then
   null;
 end;

 begin
  delete ad_credoutprotpres3 pres
   where pres.empresa = p_codemp
     and pres.referencia = p_dtref;
 
  insert /*+ APPEND NOLOGGING */
  into ad_credoutprotpres3
   select /*+ PARALLEL(AUTO) */
    codemp, p_dtref, nunota, sequencia, option_label('TGFLIV', 'ORIGEM', origem) as origem, numnota, dhmov,
    dtdoc, codprod, descrprod, ncm, codcfo, codgrupoprod, descrgrupoprod, vlrctb, baseicms, aliqicms, vlricms,
    aliqefetiva,
    case
     when codprod in (50593, 50587, 50588) then
      0
     else
      case
       when codgrupoprod in (01040500, 01040200) then
        1
       else
        3
      end
    end as aliq_outor, credito_outor,
    
    case
     when codprod in (50593, 50587, 50588) then
      0
     else
      aliq_protege
    end aliq_protege, credito_outor * aliq_protege / 100 as protege
     from (select l.codemp, l.nunota, l.sequencia, l.origem, l.numnota, l.dhmov, l.dtdoc, p.codprod,
                   p.descrprod, p.ncm, l.codcfo, g.codgrupoprod, g.descrgrupoprod,
                   (l.vlrctb * (case
                    when l.codcfo < 5000 then
                     -1
                    else
                     1
                   end)) as vlrctb,
                   (l.baseicms * (case
                    when l.codcfo < 5000 then
                     -1
                    else
                     1
                   end)) as baseicms, l.aliqicms,
                   (l.vlricms * (case
                    when l.codcfo < 5000 then
                     -1
                    else
                     1
                   end)) as vlricms,
                   round(func_divide_sf(l.vlricms,
                                         l.vlrctb - decode(top.somasubst, 'S', l.icmsretencao, 0) - l.vlripi) * 100,
                          1) as aliqefetiva,
                   (l.baseicms * case
                    when p.codprod in (50593, 50587, 50588) then
                     0
                    else
                     case
                      when p.codgrupoprod in (01040500, 01040200) then
                       0.01
                      else
                       0.03
                     end
                   end * (case
                    when l.codcfo < 5000 then
                     -1
                    else
                     1
                   end)) as credito_outor, func_aliq_protege_sf(3, trunc(l.dhmov, 'mon')) as aliq_protege
              from tgfliv l
             inner join tgfcab c
                on (c.nunota = l.nunota and l.origem in ('E', 'A'))
             inner join tgfite i
                on (i.nunota = l.nunota and i.sequencia = l.sequencia)
             inner join tgfpro p
                on (p.codprod = i.codprod)
             inner join tgfgru g
                on (g.codgrupoprod = p.codgrupoprod)
             inner join tgfpar par
                on (par.codparc = c.codparc)
             inner join tgftop top
                on (top.codtipoper = c.codtipoper and top.dhalter = c.dhtipoper)
             where to_char(l.dhmov, 'YYYYMM') = to_char(p_dtref, 'YYYYMM')
               and l.codemp = p_codemp
               and exists (select 1
                      from ad_relparmcfop cf
                     where cf.nurelparm = 3
                       and cf.codcfo = l.codcfo)
               and exists (select 1
                      from ad_relparmgrup gr
                     where gr.nurelparm = 3
                       and gr.codgrupoprod = p.codgrupoprod));
 exception
  when others then
   null;
 end;

 begin
  delete ad_credoutprotrb10 rb
   where rb.empresa = p_codemp
     and rb.referencia = p_dtref;
 
  insert /*+ APPEND NOLOGGING */
  into ad_credoutprotrb10
   select /*+ PARALLEL(AUTO) */
    codemp, p_dtref, nunota, sequencia, option_label('TGFLIV', 'ORIGEM', origem) as origem, numnota, dhmov,
    dtdoc, codprod, descrprod, ncm, codcfo, codgrupoprod, descrgrupoprod, vlrctb, baseicms, aliqicms, vlricms,
    aliqefetiva, base_semst, round(base_semst * aliqicms / 100, 2) as vlricms_sembenef,
    round(base_semst * aliqicms / 100, 2) - vlricms as credito_presumido, aliq_protege,
    round((round(base_semst * aliqicms / 100, 2) - vlricms) * aliq_protege / 100, 2) as protege
     from (select l.codemp, l.nunota, l.sequencia, l.origem, l.numnota, l.dhmov, l.dtdoc, p.codprod,
                   p.descrprod, p.ncm, l.codcfo, g.codgrupoprod, g.descrgrupoprod,
                   (l.vlrctb * (case
                    when l.codcfo < 5000 then
                     -1
                    else
                     1
                   end)) as vlrctb,
                   (l.baseicms * (case
                    when l.codcfo < 5000 then
                     -1
                    else
                     1
                   end)) as baseicms, l.aliqicms,
                   (l.vlricms * (case
                    when l.codcfo < 5000 then
                     -1
                    else
                     1
                   end)) as vlricms,
                   round(func_divide_sf(l.vlricms,
                                         l.vlrctb - decode(top.somasubst, 'S', l.icmsretencao, 0) - l.vlripi) * 100,
                          1) as aliqefetiva,
                   (l.vlrctb - decode(top.somasubst, 'S', l.icmsretencao, 0) - l.vlripi * (case
                    when l.codcfo < 5000 then
                     -1
                    else
                     1
                   end)) as base_semst, func_aliq_protege_sf(4, trunc(l.dhmov, 'MON')) as aliq_protege
              from tgfliv l
             inner join tgfcab c
                on (c.nunota = l.nunota and l.origem in ('E', 'A'))
             inner join tgfite i
                on (i.nunota = l.nunota and i.sequencia = l.sequencia)
             inner join tgfpro p
                on (p.codprod = i.codprod)
             inner join tgfgru g
                on (g.codgrupoprod = p.codgrupoprod)
             inner join tgfpar par
                on (par.codparc = c.codparc)
             inner join tgftop top
                on (top.codtipoper = c.codtipoper and top.dhalter = c.dhtipoper)
             where to_char(l.dhmov, 'YYYYMM') = to_char(p_dtref, 'YYYYMM')
               and l.codemp = p_codemp
               and exists
             (select 1
                      from ad_relparmcfop cf
                     where cf.nurelparm = 4
                       and cf.codcfo = l.codcfo)
               and round(func_divide_sf(l.vlricms,
                                        l.vlrctb - decode(top.somasubst, 'S', l.icmsretencao, 0) - l.vlripi) * 100,
                         1) >= 10
               and round(func_divide_sf(l.vlricms,
                                        l.vlrctb - decode(top.somasubst, 'S', l.icmsretencao, 0) - l.vlripi) * 100,
                         1) <= 11);
 exception
  when others then
   null;
 end;

end;
/
