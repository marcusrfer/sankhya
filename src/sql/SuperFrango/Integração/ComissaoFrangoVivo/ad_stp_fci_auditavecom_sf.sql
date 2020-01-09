create or replace procedure ad_stp_fci_auditavecom_sf(p_codusu    number,
                                                      p_idsessao  varchar2,
                                                      p_qtdlinhas number,
                                                      p_mensagem  out varchar2) as

  /*
    Autor: MARCUS.RANGEL 07/11/2019 10:38:12
    Processo: fechamento de Comissão Integrado - FV
    Objetivo: Comparar os dados digitados pelo usuário com os valores inseridos na tela
  */
  p_qtdaves   number;
  p_qtdabat   number;
  p_qtdracao  float;
  p_peso      float;
  p_sexo      varchar2(1);
  p_pesolote  float;
  /*p_calote    float;
  p_ganholote float;
  p_fpmedio   float;
  p_ipsumedio float;
  p_percom    float;
  p_pesocom   float;
  p_vlrcom    float;*/
  v_sexo      varchar2(1);
  v_html      clob := null;

  lote ad_tsffci%rowtype;

  type rec_diff is record(
    nome   varchar2(100),
    vlrold float,
    vlrnew float,
    vlrdif float);

  type tab_diff is table of rec_diff;
  t tab_diff := tab_diff();
  i int;

begin

  if p_qtdlinhas > 1 then
    p_mensagem := 'Selecione apenas 1 registro!';
    return;
  end if;

  lote.numlote := act_int_field(p_idsessao, 1, 'NUMLOTE');
  p_qtdaves    := act_int_param(p_idsessao, 'QTDAVES');
  p_qtdabat    := act_int_param(p_idsessao, 'QTDABAT');
  p_qtdracao   := act_dec_param(p_idsessao, 'QTDRACAO');
  p_peso       := act_dec_param(p_idsessao, 'PESO');
  p_sexo       := act_txt_param(p_idsessao, 'SEXO');
  p_pesolote   := act_dec_param(p_idsessao, 'PESOLOTE');
  --p_calote     := act_dec_param(p_idsessao, 'CALOTE');
  --p_ganholote  := act_dec_param(p_idsessao, 'GANHOLOTE');
  --p_fpmedio    := act_dec_param(p_idsessao, 'FPMEDIO');
  --p_ipsumedio  := act_dec_param(p_idsessao, 'IPSUMEDIO');
  --p_percom     := act_dec_param(p_idsessao, 'PERCOM');
  --p_pesocom    := act_dec_param(p_idsessao, 'PESOCOM');
  --p_vlrcom     := act_dec_param(p_idsessao, 'VLRCOM');

  if variaveis_pkg.v_atualizando then
    lote.numlote := 57199;
    p_qtdaves    := 21000;
    p_qtdabat    := 20351;
    p_qtdracao   := 101273;
    p_peso       := 53700;
    p_sexo       := 'F';
    p_pesolote   := 2.6387;
    /*p_calote     := 1.8859;
    p_ganholote  := 56.1;
    p_fpmedio    := 320.15;
    p_ipsumedio  := 203.73;
    p_percom     := 7.1;
    p_pesocom    := 3812.70;
    p_vlrcom     := 11438.10;*/
  end if;

  select * into lote from ad_tsffci where numlote = lote.numlote;

  if lote.qtdfem > 0 and lote.qtdmachos = 0 then
    v_sexo := 'F';
  elsif lote.qtdmachos > 0 and lote.qtdfem = 0 then
    v_sexo := 'M';
  elsif lote.qtdfem > 0 and lote.qtdmachos > 0 then
    v_sexo := 'X';
  end if;

  if p_qtdaves != lote.qtdaves then
    t.extend;
    i := t.last;
    t(i).nome := 'Aves Alojadas';
    t(i).vlrold := lote.qtdaves;
    t(i).vlrnew := p_qtdaves;
    t(i).vlrdif := t(i).vlrold - t(i).vlrnew;
  end if;

  if p_qtdabat != lote.qtdabat then
    t.extend;
    i := t.last;
    t(i).nome := 'Aves Abatidas';
    t(i).vlrold := lote.qtdabat;
    t(i).vlrnew := p_qtdabat;
    t(i).vlrdif := t(i).vlrold - t(i).vlrnew;
  end if;

  if p_qtdracao != lote.qtdracao then
    t.extend;
    i := t.last;
    t(i).nome := 'Ração Consumida';
    t(i).vlrold := lote.qtdracao;
    t(i).vlrnew := p_qtdracao;
    t(i).vlrdif := t(i).vlrold - t(i).vlrnew;
  end if;

  if p_peso != lote.peso then
    t.extend;
    i := t.last;
    t(i).nome := 'Peso Total Aves';
    t(i).vlrold := lote.peso;
    t(i).vlrnew := p_peso;
    t(i).vlrdif := t(i).vlrold - t(i).vlrnew;
  end if;

  if p_sexo != v_sexo then
    t.extend;
    i := t.last;
    t(i).nome := 'Sexo';
    t(i).vlrold := 0;
    t(i).vlrnew := 0;
    t(i).vlrdif := 0;
  end if;
 /*
  if p_pesolote != lote.pesolote then
    t.extend;
    i := t.last;
    t(i).nome := 'Peso Médio';
    t(i).vlrold := lote.pesolote;
    t(i).vlrnew := p_pesolote;
    t(i).vlrdif := t(i).vlrold - t(i).vlrnew;
  end if;

  if p_calote != lote.calote then
    t.extend;
    i := t.last;
    t(i).nome := 'CA';
    t(i).vlrold := lote.calote;
    t(i).vlrnew := p_calote;
    t(i).vlrdif := t(i).vlrold - t(i).vlrnew;
  end if;

  if p_ganholote != lote.ganholote then
    t.extend;
    i := t.last;
    t(i).nome := 'GMD';
    t(i).vlrold := lote.ganholote;
    t(i).vlrnew := p_ganholote;
    t(i).vlrdif := t(i).vlrold - t(i).vlrnew;
  end if;

  if p_fpmedio != lote.fpmedio then
    t.extend;
    i := t.last;
    t(i).nome := 'FP Médio';
    t(i).vlrold := lote.fpmedio;
    t(i).vlrnew := p_fpmedio;
    t(i).vlrdif := t(i).vlrold - t(i).vlrnew;
  end if;

  if p_ipsumedio != lote.ipsumedio then
    t.extend;
    i := t.last;
    t(i).nome := 'IPSU Médio';
    t(i).vlrold := lote.ipsumedio;
    t(i).vlrnew := p_ipsumedio;
    t(i).vlrdif := t(i).vlrold - t(i).vlrnew;
  end if;

  if p_percom != lote.percom then
    t.extend;
    i := t.last;
    t(i).nome := '% Comissão';
    t(i).vlrold := lote.percom;
    t(i).vlrnew := p_percom;
    t(i).vlrdif := t(i).vlrold - t(i).vlrnew;
  end if;

  if p_pesocom != lote.pesocom then
    t.extend;
    i := t.last;
    t(i).nome := 'Comissão KG';
    t(i).vlrold := lote.pesocom;
    t(i).vlrnew := p_pesocom;
    t(i).vlrdif := t(i).vlrold - t(i).vlrnew;
  end if;

  if p_vlrcom != lote.vlrcom then
    t.extend;
    i := t.last;
    t(i).nome := 'Resultado do Lote';
    t(i).vlrold := lote.vlrcom;
    t(i).vlrnew := p_vlrcom;
    t(i).vlrdif := t(i).vlrold - t(i).vlrnew;
  end if;

 */
 
  v_html := '<!DOCTYPE html>
 <html>
 <head>
 <style>
  table {
   font-family: arial, sans-serif;
   border-collapse: collapse;
   width: 100%;
   }

  td, th {
   border: 1px solid #dddddd;
   text-align: left;
   padding: 8px;
   }

  tr:nth-child(even) {
   background-color: #dddddd;
  } 
 </style>
 </head>
 <body>
 <table>
  <tr>
    <th>Onde</th>
    <th>Valor Snk-W</th>
    <th>Valor Digitado</th>
    <th>Diferença</th>
  </tr>';

  if t.count > 0 then
    for x in t.first .. t.last
    loop
      dbms_lob.append(v_html, chr(13) || '<tr>' || chr(13));
      dbms_lob.append(v_html, ' <td>' || t(x).nome || '</td>');
      dbms_lob.append(v_html, ' <td>' || t(x).vlrold || '</td>');
      dbms_lob.append(v_html, ' <td>' || t(x).vlrnew || '</td>');
      dbms_lob.append(v_html, ' <td>' || t(x).vlrdif || '</td>');
      dbms_lob.append(v_html, chr(13) || '</tr>');
    end loop;
  
    v_html     := v_html || chr(13) || '</table>
 </body>
 </html>';
    p_mensagem := v_html;
  else
  
    begin
      update ad_tsffci f
         set f.statuslote  = 'A',
             f.dhalter     = sysdate,
             f.codusualter = p_codusu
       where f.numlote = lote.numlote;
    exception
      when others then
        p_mensagem := 'Erro ao atualizar o status do fechamento. ' || '  - ' || sqlerrm;
        return;
    end;
  
    p_mensagem := 'O lote ' || lote.numlote || ' foi auditado com sucesso!';
  
  end if;

end;
/
