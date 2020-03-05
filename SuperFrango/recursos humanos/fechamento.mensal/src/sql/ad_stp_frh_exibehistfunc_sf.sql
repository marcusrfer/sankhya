create or replace procedure ad_stp_frh_exibehistfunc_sf(p_codusu    number,
                                                        p_idsessao  varchar2,
                                                        p_qtdlinhas number,
                                                        p_mensagem  out varchar2) as
 p_matfunc varchar2(4000);

 v_head  varchar2(4000);
 v_thead varchar(400);
 v_body  varchar2(4000);

 v_nomefunc varchar2(400);

begin

 p_matfunc := act_int_param(p_idsessao, 'MATFUNC');

 begin
  select f.funomfunc into v_nomefunc from fpwpower.funciona f where fumatfunc = p_matfunc;
 exception
  when no_data_found then
   p_mensagem := 'Funcionário ' || p_matfunc || ' não encontrado!';
   return;
 end;

 v_head := '<!DOCTYPE html>
		              <html>
									<head>
									<style>
									table{ font-family: arial, sans-serif; border-collapse: collapse; width: 100%; }
									td, th { border: 1px solid #dddddd; padding: 3px; }
									tr:nth-child(even) {background-color: #dddddd;}
									</style>
									<body>' || chr(13) || 'Matrícula: ' || p_matfunc || ' - ' || v_nomefunc || chr(13);

 v_thead := '<br><table border=1 style="width:100%">
						               <tr>
														 <th align="left">Dt. Início</th>
														 <th align="left">Dt. Fim</th>
														 <th align="center">Situação</th>
													 </tr>
													 ';

 for hist in (select *
                from (select fmt.number_to_date(fh.fuhistdataini) dataini,
                             fmt.number_to_date(fh.fuhistdatafim) datafin,
                             s.stdescsitu descrsit
                        from fpwpower.funcionahist fh
                        join fpwpower.situacao s
                          on s.stcodemp = fh.fuhistcodemp
                         and s.stcodsitu = fh.fuhistcodsitu
                       where fh.fuhistmatfunc = p_matfunc
                       order by fmt.number_to_date(fh.fuhistdataini) desc
                       fetch first 20 rows only)
               order by dataini)
 loop
  v_body := v_body || chr(13) || '<tr><td>' || hist.dataini || '</td>' || '<td>' || hist.datafin || '</td>' ||
            '<td>' || hist.descrsit || '</td></tr>';
 end loop;

 v_body := v_body || chr(13) || '</table></body></html>';

 --dbms_output.put_line(v_head || chr(13) || v_thead ||chr(13) ||v_body);
 p_mensagem := v_head || chr(13) || v_thead || chr(13) || v_body;

end;
/
