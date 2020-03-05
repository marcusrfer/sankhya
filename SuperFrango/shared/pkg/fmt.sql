create or replace package fmt is

  -- Author  : MARCUS RANGEL
  -- Created : 17/05/2019 10:00:03
  -- Purpose : conter funÁıes que realizam formataÁıes de diversas informaÁıes
  /*   Function horas(p_hora Number) Return Varchar2;
  Function cep(p_cep Varchar2) Return Varchar2;
  Function cep(p_codparc Number) Return Varchar2;
  Function cnpj_cpf(p_codparc Number) Return Varchar2;*/

  function dia_semana(p_data date,
                      p_format varchar2) return varchar2;

  function dia_semana(p_dia number,
                      p_format varchar2) return varchar2;

  function hora(p_hora number) return varchar2;

  function cep(p_cep varchar) return varchar;

  function cnpj_cpf(p_cnpj varchar2) return varchar2;

  function cnpj_cpf(p_codparc number) return varchar2;

  function placa(p_placa varchar2) return varchar2;

  function placa(p_codveiculo number) return varchar2;

  function telefone(p_telefone varchar) return varchar2;

  function telefone(p_codparc number) return varchar2;

  function valor_moeda(p_valor number) return varchar deterministic;

  function numero(p_numero number) return varchar;

  function moeda_extenso(valor number) return varchar2;

  function number_to_date(p_data number) return date deterministic;

  function remove_acento(p_string in varchar2) return varchar2;

end fmt;
/
create or replace package body fmt is

  function dia_semana(p_data date,
                      p_format varchar2) return varchar2 is
  
    v_nomedia varchar2(10);
  begin
    if upper(p_format) = 'DDD' then
      v_nomedia := case
                     when to_char(p_data, 'd') = 1 then
                      'DOM'
                     when to_char(p_data, 'd') = 2 then
                      'SEG'
                     when to_char(p_data, 'd') = 3 then
                      'TER'
                     when to_char(p_data, 'd') = 4 then
                      'QUA'
                     when to_char(p_data, 'd') = 5 then
                      'QUI'
                     when to_char(p_data, 'd') = 6 then
                      'SEX'
                     when to_char(p_data, 'd') = 7 then
                      'SAB'
                   end;
    end if;
  
    return v_nomedia;
  
  end dia_semana;

  function dia_semana(p_dia number,
                      p_format varchar2) return varchar2 is
    v_nomedia varchar2(10);
  begin
    if upper(p_format) = 'DDD' then
      v_nomedia := case
                     when p_dia = 1 then
                      'DOM'
                     when p_dia = 2 then
                      'SEG'
                     when p_dia = 3 then
                      'TER'
                     when p_dia = 4 then
                      'QUA'
                     when p_dia = 5 then
                      'QUI'
                     when p_dia = 6 then
                      'SEX'
                     when p_dia = 7 then
                      'SAB'
                   end;
    end if;
    return v_nomedia;
  end dia_semana;

  function hora(p_hora number) return varchar2 is
    v_hora varchar2(5);
  begin
    v_hora := regexp_replace(lpad(p_hora, 4, '0'), '([0-9]{2})([0-9]{2})', '\1:\2');
    return v_hora;
  end hora;

  function cep(p_cep varchar) return varchar is
    cep varchar2(20);
  begin
    cep := regexp_replace(lpad(p_cep, 8, '0'), '([0-9]{2})([0-9]{3})([0-9]{3})', '\1.\2-\3');
    return cep;
  end cep;

  function cnpj_cpf(p_cnpj varchar2) return varchar2 is
    cnpjcpf varchar(20);
  begin
    if length(p_cnpj) = 11 then
      cnpjcpf := regexp_replace(lpad(p_cnpj, 11, '0'), '([0-9]{3})([0-9]{3})([0-9]{3})([0-9]{2})', '\1.\2.\3-\4');
    end if;
    if length(p_cnpj) = 14 then
      cnpjcpf := regexp_replace(lpad(p_cnpj, 14, '0'), '([0-9]{2})([0-9]{3})([0-9]{3})([0-9]{4})([0-9]{2})',
                                '\1.\2.\3/\4-\5');
    end if;
  
    return(cnpjcpf);
  
  end cnpj_cpf;

  function cnpj_cpf(p_codparc number) return varchar2 is
    v_cnpjcpf varchar(20);
  begin
    select cgc_cpf into v_cnpjcpf from tgfpar where codparc = p_codparc;
  
    if length(v_cnpjcpf) = 11 then
      v_cnpjcpf := regexp_replace(lpad(v_cnpjcpf, 11, '0'), '([0-9]{3})([0-9]{3})([0-9]{3})([0-9]{2})', '\1.\2.\3-\4');
    end if;
    if length(v_cnpjcpf) = 14 then
      v_cnpjcpf := regexp_replace(lpad(v_cnpjcpf, 14, '0'), '([0-9]{2})([0-9]{3})([0-9]{3})([0-9]{4})([0-9]{2})',
                                  '\1.\2.\3/\4-\5');
    end if;
  
    return(v_cnpjcpf);
  
  end cnpj_cpf;

  function placa(p_placa varchar2) return varchar2 is
    v_placa varchar2(10);
  begin
    v_placa := regexp_replace(p_placa, '([A-Z]{3})([0-9]{4})', '\1-\2');
    return v_placa;
  end placa;

  function placa(p_codveiculo number) return varchar2 is
    v_placa varchar2(10);
  begin
    select v.placa into v_placa from tgfvei v where codveiculo = p_codveiculo;
    v_placa := regexp_replace(v_placa, '([A-Z]{3})([0-9]{4})', '\1-\2');
    return v_placa;
  end placa;

  function telefone(p_telefone varchar) return varchar2 is
    v_telefone varchar2(20);
  begin
  
    v_telefone := replace(replace(p_telefone, ' ', ''), '-', '');
  
    if length(v_telefone) = 8 then
      v_telefone := '0629' || v_telefone;
      v_telefone := '(' || substr(v_telefone, 1, 3) || ') ' || substr(v_telefone, -9, 5) || '-' ||
                    substr(v_telefone, -4);
    elsif length(p_telefone) = 12 then
      --v_Telefone := '(' || Substr(Ptelefone, 1, 2) || ') ' || Substr(Ptelefone, -8, 4) || '-' || Substr(Ptelefone, -4);
      v_telefone := '(' || substr(v_telefone, 1, 3) || ') ' || substr(v_telefone, -9, 5) || '-' ||
                    substr(v_telefone, -4);
    elsif length(p_telefone) = 13 then
      v_telefone := '(' || substr(v_telefone, 1, 2) || ') ' || substr(v_telefone, -9, 5) || '-' ||
                    substr(v_telefone, -4);
    end if;
    return v_telefone;
  end;

  function telefone(p_codparc number) return varchar2 is
    v_telefone varchar2(20);
  begin
  
    select replace(replace(nvl(telefone, fax), ' ', ''), '-', '')
      into v_telefone
      from tgfpar
     where codparc = p_codparc;
  
    if length(v_telefone) = 8 then
      v_telefone := '0629' || v_telefone;
      v_telefone := '(' || substr(v_telefone, 1, 3) || ') ' || substr(v_telefone, -9, 5) || '-' ||
                    substr(v_telefone, -4);
    elsif length(v_telefone) = 12 then
      --v_Telefone := '(' || Substr(Ptelefone, 1, 2) || ') ' || Substr(Ptelefone, -8, 4) || '-' || Substr(Ptelefone, -4);
      v_telefone := '(' || substr(v_telefone, 1, 3) || ') ' || substr(v_telefone, -9, 5) || '-' ||
                    substr(v_telefone, -4);
    elsif length(v_telefone) = 13 then
      v_telefone := '(' || substr(v_telefone, 1, 2) || ') ' || substr(v_telefone, -9, 5) || '-' ||
                    substr(v_telefone, -4);
    end if;
    return v_telefone;
  
  end telefone;

  function valor_moeda(p_valor number) return varchar deterministic is
    v_valor varchar2(15);
  begin
    v_valor := replace(ltrim(rtrim('R$' || to_char(p_valor, '999G990D99'))), '   ', ' ');
    return v_valor;
  end valor_moeda;

  function numero(p_numero number) return varchar is
    result varchar2(100);
  begin
  
    result := ltrim(rtrim(to_char(p_numero, '999G999G999G999D99')));
  
    return result;
  
  end numero;

  function number_to_date(p_data number) return date deterministic is
    v_data date;
  begin
    if length(p_data) != 10 then
      v_data := '01/01/1900';
    end if;
  
    v_data := to_date(regexp_replace(p_data, '([0-9]{4})([0-9]{2})([0-9]{2})', '\3/\2/\1'), 'dd/mm/yyyy');
  
    return v_data;
  
  exception
    when others then
      return '01/01/1900';
  end;

  function moeda_extenso(valor number) return varchar2 is
    valor_string varchar2(256);
    valor_conv   varchar2(25);
    ind          number;
    tres_digitos varchar2(3);
    texto_string varchar2(256);
  begin
    valor_conv := to_char(trunc((abs(valor) * 100), 0), '0999999999999999999');
    valor_conv := substr(valor_conv, 1, 18) || '0' || substr(valor_conv, 19, 2);
    if to_number(valor_conv) = 0 then
      return('Zero ');
    end if;
    for ind in 1 .. 7
    loop
      tres_digitos := substr(valor_conv, (((ind - 1) * 3) + 1), 3);
      texto_string := '';
      -- Extenso para Centena
      if substr(tres_digitos, 1, 1) = '2' then
        texto_string := texto_string || 'Duzentos ';
      elsif substr(tres_digitos, 1, 1) = '3' then
        texto_string := texto_string || 'Trezentos ';
      elsif substr(tres_digitos, 1, 1) = '4' then
        texto_string := texto_string || 'Quatrocentos ';
      elsif substr(tres_digitos, 1, 1) = '5' then
        texto_string := texto_string || 'Quinhentos ';
      elsif substr(tres_digitos, 1, 1) = '6' then
        texto_string := texto_string || 'Seiscentos ';
      elsif substr(tres_digitos, 1, 1) = '7' then
        texto_string := texto_string || 'Setecentos ';
      elsif substr(tres_digitos, 1, 1) = '8' then
        texto_string := texto_string || 'Oitocentos ';
      elsif substr(tres_digitos, 1, 1) = '9' then
        texto_string := texto_string || 'Novecentos ';
      end if;
      if substr(tres_digitos, 1, 1) = '1' then
        if substr(tres_digitos, 2, 2) = '00' then
          texto_string := texto_string || 'Cem ';
        else
          texto_string := texto_string || 'Cento ';
        end if;
      end if;
      -- Extenso para Dezena
      if substr(tres_digitos, 2, 1) <> '0' and texto_string is not null then
        texto_string := texto_string || 'e ';
      end if;
      if substr(tres_digitos, 2, 1) = '2' then
        texto_string := texto_string || 'Vinte ';
      elsif substr(tres_digitos, 2, 1) = '3' then
        texto_string := texto_string || 'Trinta ';
      elsif substr(tres_digitos, 2, 1) = '4' then
        texto_string := texto_string || 'Quarenta ';
      elsif substr(tres_digitos, 2, 1) = '5' then
        texto_string := texto_string || 'Cinquenta ';
      elsif substr(tres_digitos, 2, 1) = '6' then
        texto_string := texto_string || 'Sessenta ';
      elsif substr(tres_digitos, 2, 1) = '7' then
        texto_string := texto_string || 'Setenta ';
      elsif substr(tres_digitos, 2, 1) = '8' then
        texto_string := texto_string || 'Oitenta ';
      elsif substr(tres_digitos, 2, 1) = '9' then
        texto_string := texto_string || 'Noventa ';
      end if;
      if substr(tres_digitos, 2, 1) = '1' then
        if substr(tres_digitos, 3, 1) <> '0' then
          if substr(tres_digitos, 3, 1) = '1' then
            texto_string := texto_string || 'Onze ';
          elsif substr(tres_digitos, 3, 1) = '2' then
            texto_string := texto_string || 'Doze ';
          elsif substr(tres_digitos, 3, 1) = '3' then
            texto_string := texto_string || 'Treze ';
          elsif substr(tres_digitos, 3, 1) = '4' then
            texto_string := texto_string || 'Catorze ';
          elsif substr(tres_digitos, 3, 1) = '5' then
            texto_string := texto_string || 'Quinze ';
          elsif substr(tres_digitos, 3, 1) = '6' then
            texto_string := texto_string || 'Dezesseis ';
          elsif substr(tres_digitos, 3, 1) = '7' then
            texto_string := texto_string || 'Dezessete ';
          elsif substr(tres_digitos, 3, 1) = '8' then
            texto_string := texto_string || 'Dezoito ';
          elsif substr(tres_digitos, 3, 1) = '9' then
            texto_string := texto_string || 'Dezenove ';
          end if;
        else
          texto_string := texto_string || 'Dez ';
        end if;
      else
        -- Extenso para Unidade
        if substr(tres_digitos, 3, 1) <> '0' and texto_string is not null then
          texto_string := texto_string || 'e ';
        end if;
        if substr(tres_digitos, 3, 1) = '1' then
          texto_string := texto_string || 'Um ';
        elsif substr(tres_digitos, 3, 1) = '2' then
          texto_string := texto_string || 'Dois ';
        elsif substr(tres_digitos, 3, 1) = '3' then
          texto_string := texto_string || 'Tres ';
        elsif substr(tres_digitos, 3, 1) = '4' then
          texto_string := texto_string || 'Quatro ';
        elsif substr(tres_digitos, 3, 1) = '5' then
          texto_string := texto_string || 'Cinco ';
        elsif substr(tres_digitos, 3, 1) = '6' then
          texto_string := texto_string || 'Seis ';
        elsif substr(tres_digitos, 3, 1) = '7' then
          texto_string := texto_string || 'Sete ';
        elsif substr(tres_digitos, 3, 1) = '8' then
          texto_string := texto_string || 'Oito ';
        elsif substr(tres_digitos, 3, 1) = '9' then
          texto_string := texto_string || 'Nove ';
        end if;
      end if;
      if to_number(tres_digitos) > 0 then
        if to_number(tres_digitos) = 1 then
          if ind = 1 then
            texto_string := texto_string || 'Quatrilh„o ';
          elsif ind = 2 then
            texto_string := texto_string || 'Trilh„o ';
          elsif ind = 3 then
            texto_string := texto_string || 'Bilh„o ';
          elsif ind = 4 then
            texto_string := texto_string || 'Milh„o ';
          elsif ind = 5 then
            texto_string := texto_string || 'Mil ';
          end if;
        else
          if ind = 1 then
            texto_string := texto_string || 'Quatrilhıes ';
          elsif ind = 2 then
            texto_string := texto_string || 'Trilhıes ';
          elsif ind = 3 then
            texto_string := texto_string || 'Bilhıes ';
          elsif ind = 4 then
            texto_string := texto_string || 'Milhıes ';
          elsif ind = 5 then
            texto_string := texto_string || 'Mil ';
          end if;
        end if;
      end if;
      valor_string := valor_string || texto_string;
      -- Escrita da Moeda Corrente
      if ind = 5 then
        if to_number(substr(valor_conv, 16, 3)) > 0 and valor_string is not null then
          valor_string := rtrim(valor_string) || ' e ';
        end if;
      else
        if ind < 5 and valor_string is not null then
          valor_string := rtrim(valor_string) || ' e ';
        end if;
      end if;
      if ind = 6 then
        if to_number(substr(valor_conv, 1, 18)) > 1 then
          valor_string := valor_string || 'Reais ';
        elsif to_number(substr(valor_conv, 1, 18)) = 1 then
          valor_string := valor_string || 'Real ';
        end if;
      
        if to_number(substr(valor_conv, 20, 2)) > 0 and length(valor_string) > 0 then
          valor_string := valor_string || 'e ';
        end if;
      end if;
      -- Escrita para Centavos
      if ind = 7 then
        if to_number(substr(valor_conv, 20, 2)) > 1 then
          valor_string := valor_string || 'Centavos ';
        elsif to_number(substr(valor_conv, 20, 2)) = 1 then
          valor_string := valor_string || 'Centavo ';
        end if;
      end if;
    end loop;
    return(rtrim(valor_string));
  exception
    when others then
      return('*** VALOR INVALIDO ***');
  end moeda_extenso;

  function remove_acento(p_string in varchar2) return varchar2 is
    v_stringreturn varchar2(2000);
  begin
    v_stringreturn := translate(p_string, '¡«…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’À‹·ÁÈÌÛ˙‡ËÏÚ˘‚ÍÓÙ˚„ıÎ¸',
                                'ACEIOUAEIOUAEIOUAOEUaceiouaeiouaeiouaoeu');
    return v_stringreturn;
  end remove_acento;

end fmt;
/
