create or replace package ad_pkg_cmp as

 -- retorna o n�mero �nico da nota de romaneio para preenchimento do campo
 -- na tela de controle de carregamento de mp
 function get_nunota(p_numnota number, p_codparc number, p_codprod number) return number;

 -- fun��o que retorna o n�mero do contrato de compra atravez do n�mero do romaneio 
 -- informado na tela de controle de carregametno de materia prima
 function get_nrocontratocpa(p_numnota number, p_codparc number, p_codprod number) return number;

 function get_nrocontratocpa(p_seq     number,
                             p_ord     int,
                             p_numnota number,
                             p_codparc number,
                             p_codprod number) return number;

 function get_ult_vlrfreteton(p_codparc number, p_codprod number, p_codemp number, p_data date)
  return float deterministic;

 function get_cred_piscofins(p_nunota number, p_sequencia int) return float;

 function get_vlrcontrato(p_numcontrato number, p_codprod number) return float;

 function get_qtdcontrato(p_numcontrato number, p_codprod number) return float;

 function get_totalcarregamento(p_numcontrato number, p_codprod number) return float;

 function get_totalfrete(p_numcontrato number, p_codprod number) return float;

 function get_mediaumidade(p_numcontrato number, p_codprod number) return float;

 function get_tabdescumidade(p_numcontrato number, p_codprod number) return float;

 function get_vlrdescumidade(p_numcontrato number, p_codprod number) return float;

 function get_vlrsecagem(p_nrocontratoarmz number, p_umidade float) return float;

end ad_pkg_cmp;
/
create or replace package body ad_pkg_cmp as

 -- retorna o n�mero �nico da nota de romaneio para preenchimento do campo
 -- na tela de controle de carregamento de mp
 function get_nunota(p_numnota number, p_codparc number, p_codprod number) return number is
  v_nunota number;
 begin
  select c.nunota
    into v_nunota
    from tgfcab c
    join tgfite i
      on i.nunota = c.nunota
   where c.numnota = p_numnota
     and c.codparc = p_codparc
     and i.codprod = p_codprod
     and c.codtipoper in (622, 604)
   group by c.nunota;
 
  return v_nunota;
 
 exception
  when others then
   dbms_output.put_line('Erro ao buscar o nro �nico da remessa do carregamento. ' || sqlerrm);
   return null;
 end get_nunota;

 -- fun��o que retorna o n�mero do contrato de compra atravez do n�mero do romaneio 
 -- informado na tela de controle de carregametno de materia prima

 function get_nrocontratocpa(p_numnota number, p_codparc number, p_codprod number) return number is
  v_nrocontrato number;
 begin
  v_nrocontrato := get_nrocontratocpa(null, null, p_numnota, p_codparc, p_codprod);
  return v_nrocontrato;
 end;

 function get_nrocontratocpa(p_seq     number,
                             p_ord     int,
                             p_numnota number,
                             p_codparc number,
                             p_codprod number) return number is
  v_nunota      number;
  v_nrocontrato number;
  v_dtcarrgto   date;
  v_codparc     number;
  pragma autonomous_transaction;
 begin
 
  begin
   select c.numcontrato
     into v_nrocontrato
     from tgfcab c
     join tgfite i
       on i.nunota = c.nunota
    where c.numnota = p_numnota
      and c.codparc = p_codparc
      and i.codprod = p_codprod
      and c.codtipoper in (622);
  
   select nunota into v_nunota from tcscon where numcontrato = v_nrocontrato;
  
   select numcontrato into v_nrocontrato from tgfcab where nunota = v_nunota;
  
  exception
   when no_data_found then
   
    select ct.datasaidatrans into v_dtcarrgto from ad_contcargto ct where ct.sequencia = p_seq;
   
    begin
     select c.numcontrato
       into v_nrocontrato
       from tcscon c
       join tcspsc p
         on p.numcontrato = c.numcontrato
      where c.codparc = p_codparc
        and c.dtcontrato = (select max(dtcontrato)
                              from tcscon con
                             where con.codparc = c.codparc
                               and con.dtcontrato <= v_dtcarrgto);
    exception
     when no_data_found then
     
      begin
       select ic.coddest
         into v_codparc
         from ad_itecargto ic
        where ic.sequencia = p_seq
          and ic.ordem = p_ord;
      
       select c.numcontrato
         into v_nrocontrato
         from tcscon c
         join tcspsc p
           on p.numcontrato = c.numcontrato
        where c.codparc = v_codparc
          and c.dtcontrato = (select max(dtcontrato)
                                from tcscon con
                               where con.codparc = c.codparc
                                 and con.dtcontrato <= v_dtcarrgto);
      exception
       when others then
        dbms_output.put_line('N�o encontrou o contrato - ' || sqlerrm);
        return null;
      end;
     
    end;
   
  end;
 
  return v_nrocontrato;
 
 exception
  when others then
   dbms_output.put_line('Erro ao buscar o contrato. ' || sqlerrm);
   return null;
 end get_nrocontratocpa;

 function get_dadoscontrato(p_numcontrato number, p_codprod number, p_tipo char) return float is
  functionresult float;
 begin
  /**
  * Fun��o que retorna o valor ou a quantidade do contrato informado
  * no parametro
  **/
 
  -- tipo q = quantidade e v = 
  for contrato in (select c.numcontrato, psc.codprod, psc.qtdeprevista, pre.valor
                     from tcscon c
                     join tcspsc psc
                       on c.numcontrato = psc.numcontrato
                     join tcspre pre
                       on c.numcontrato = pre.numcontrato
                      and psc.codprod = pre.codprod
                    where c.numcontrato = p_numcontrato
                      and psc.codprod = p_codprod
                      and pre.referencia = (select max(p.referencia)
                                              from tcspre p
                                             where p.numcontrato = pre.numcontrato
                                               and p.codprod = pre.codprod))
  loop
   if p_tipo = 'Q' then
    functionresult := contrato.qtdeprevista;
   elsif p_tipo = 'V' then
    functionresult := contrato.valor;
   end if;
  end loop;
 
  return(functionresult);
 end get_dadoscontrato;

 function get_qtdcontrato(p_numcontrato number, p_codprod number) return float is
  functionresult float;
 begin
  functionresult := get_dadoscontrato(p_numcontrato, p_codprod, 'Q');
  return(functionresult);
 end;

 function get_vlrcontrato(p_numcontrato number, p_codprod number) return float is
  functionresult float;
 begin
  functionresult := get_dadoscontrato(p_numcontrato, p_codprod, 'V');
  return(functionresult);
 end get_vlrcontrato;

 function get_dadoscarregamentos(p_numcontrato number, p_codprod number, p_tipo varchar2)
  return float is
  functionresult float := 0;
  totalcarregado float := 0;
  totalfrete     float := 0;
  mediaumidade   float := 0;
  codtabdesconto int := 0;
 begin
  /**
  * Fun��o que retorna dados resumidos relacionados a determinado contrato
  * o mesmo � private e existem outras fun��es p�blicas que chamam essa fun��o
  * j� passando o par�mentro do tipo de informa��o retornada.
  **/
  select sum(i.qtde), sum(i.vlrfrete), avg(i.umidade), avg(amz.codtdc)
    into totalcarregado, totalfrete, mediaumidade, codtabdesconto
    from ad_itecargto i
    join ad_contcargto c
      on i.sequencia = c.sequencia
    left join tgfcab cab
      on cab.nunota = i.nunota
    left join tcscon amz
      on cab.numcontrato = amz.numcontrato
    join tcscon con
      on i.numcontrato = con.numcontrato
   where i.codprod = p_codprod
     and i.codparc = con.codparc
     and i.numcontrato = p_numcontrato
     and i.cancelado = 'N�O';
 
  if p_tipo = 'TC' then
   functionresult := totalcarregado;
  elsif p_tipo = 'TF' then
   functionresult := totalfrete;
  elsif p_tipo = 'MU' then
   functionresult := trunc(mediaumidade, 2);
  elsif p_tipo = 'TD' then
   functionresult := codtabdesconto;
  end if;
 
  return(functionresult);
 
 end get_dadoscarregamentos;

 /* fun�oes auxiliares poliformicas */

 -- retorna a quantidade total carregada
 function get_totalcarregamento(p_numcontrato number, p_codprod number) return float is
  fresult float;
 begin
  fresult := get_dadoscarregamentos(p_numcontrato, p_codprod, 'TC');
  return(fresult);
 end get_totalcarregamento;

 -- retorna o valor total do frete
 function get_totalfrete(p_numcontrato number, p_codprod number) return float is
  fresult float;
 begin
  fresult := get_dadoscarregamentos(p_numcontrato, p_codprod, 'TF');
  return(fresult);
 end get_totalfrete;

 -- retorna a media da umidade
 function get_mediaumidade(p_numcontrato number, p_codprod number) return float is
  fresult float;
 begin
  fresult := get_dadoscarregamentos(p_numcontrato, p_codprod, 'MU');
  return(fresult);
 end get_mediaumidade;

 -- retorna a tabela da umidade
 function get_tabdescumidade(p_numcontrato number, p_codprod number) return float is
  fresult float;
 begin
  fresult := get_dadoscarregamentos(p_numcontrato, p_codprod, 'TD');
  return(fresult);
 end get_tabdescumidade;

 -- retorna o desconto pela umidade do gr�o
 function get_vlrdescumidade(p_numcontrato number, p_codprod number) return float is
  v_desconto float;
  totcarreg  float;
  vlrsaca    float;
  fresult    float;
 begin
  select r.descontar
    into v_desconto
    from tgardc r
   where r.codtdc = get_tabdescumidade(p_numcontrato, p_codprod)
     and r.vlrobtido = get_mediaumidade(p_numcontrato, p_codprod);
 
  totcarreg := get_totalcarregamento(p_numcontrato, p_codprod) / 60;
  vlrsaca   := get_vlrcontrato(p_numcontrato, p_codprod) * 60;
 
  fresult := ((totcarreg * vlrsaca) * (case
              when v_desconto > 0 then
               1
              else
               0
             end + (v_desconto / 100)) / totcarreg / 60);
 
  return(nvl(fresult, 0));
 end get_vlrdescumidade;

 -- retorna o valor da secagem praticado pelo armaz�m
 function get_vlrsecagem(p_nrocontratoarmz number, p_umidade float) return float is
  v_codtab int;
  v_preco  float;
 begin
  begin
   select codtdc into v_codtab from tcscon c where c.numcontrato = p_nrocontratoarmz;
  
   select preco
     into v_preco
     from tgardc r
    where r.codtdc = v_codtab
      and r.vlrobtido = p_umidade
      and nvl(r.descontar, 0) > 0;
  exception
   when no_data_found then
    v_preco := 0;
  end;
  return v_preco;
 
 end get_vlrsecagem;

 -- retorna o valor do ultimo vlr de frete por tonelada
 function get_ult_vlrfreteton(p_codparc number, p_codprod number, p_codemp number, p_data date)
  return float deterministic as
  v_vlrfreteton float;
 begin
  select vlrfreteton
    into v_vlrfreteton
    from ad_tabfretemp t
   where t.codparc = p_codparc
     and t.codprod = p_codprod
     and t.codemp = p_codemp
     and t.dtpauta = (select max(f.dtpauta)
                        from ad_tabfretemp f
                       where t.codemp = f.codemp
                         and t.codparc = f.codparc
                         and t.codprod = f.codprod
                         and f.dtpauta <= p_data);
 
  return nvl(v_vlrfreteton, 0);
 
 exception
  when no_data_found then
   select max(vlrfreteton)
     into v_vlrfreteton
     from ad_tabfretemp t
    where t.codparc = p_codparc
      and t.codprod = p_codprod
      and t.dtpauta = (select max(f.dtpauta)
                         from ad_tabfretemp f
                        where t.codparc = f.codparc
                          and t.codprod = f.codprod
                          and f.dtpauta <= p_data
                          and rownum = 1);
  
   return nvl(v_vlrfreteton, 0);
  
  when others then
   return 0;
 end get_ult_vlrfreteton;

 -- retorna os valores de credito do pis cofins aplicado indice para exporta��o
 function get_cred_piscofins(p_nunota number, p_sequencia int) return float as
  v_vlrpiscofins float;
  v_vlrnota      float;
  v_dtref        date;
  v_codempmtz    int;
 
 begin
 
  begin
   select c.vlrnota, trunc(c.dtneg, 'mm'), e.codempmatriz
     into v_vlrnota, v_dtref, v_codempmtz
     from tgfcab c
     join tgfite i
       on c.nunota = i.nunota
     join tsiemp e
       on c.codemp = e.codemp
     join tgfpar p
       on c.codparc = p.codparc
    where c.nunota = p_nunota
      and i.sequencia = p_sequencia
      and p.tippessoa = 'J';
  exception
   when no_data_found then
    return 0;
  end;
 
  select round(v_vlrnota * round(percexport / 100, 4) * (30 / 100) * (9.25 / 100), 4)
    into v_vlrpiscofins
    from ad_apurapc pc
   where pc.referencia = v_dtref
     and pc.codempmatriz = v_codempmtz;
 
  return v_vlrpiscofins;
 
 end get_cred_piscofins;

end ad_pkg_cmp;
/
