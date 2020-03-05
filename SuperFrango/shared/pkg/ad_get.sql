create or replace package ad_get is

  /*
  Autor: Marcus Rangel
  Objetivo: Aqui dever�o estar contidas todas as fun��es e m�todos
  que atendem processos e concultas em geral, a ideia � evitar a 
  repeti��o de c�digo e organizar como uma biblioteca de consultas
  e a��es corriqueiras.
  */

  /*
  Autor: Ricardo Soares em 27/07/2017
  Objetivo: Efetuar o calculo de juros, simples ou composto de um determinado valor.
  */
  function calculajuro(p_tipo char,
                       p_valor float,
                       p_taxa float,
                       p_prazo float) return float;

  /*
  Autor: Ricardo Soares em 27/07/2017
  Objetivo: Efetuar o calculo de juros pela tabela price com amortiza��o constante.
  */
  function calculajuroprice(i float, /*Taxa Juro*/
                            n int, /*Periodo em meses*/
                            pv float, /*Valor Presente*/
                            p_dtneg date,
                            -- Data da concess�o do adiantamento
                            p_dtprimvenc date,
                            -- Data vencimento primeira parcela
                            p_parcela int,
                            -- Nr da Parcela
                            p_tipojuro char,
                            -- C = Composto, S = Simples
                            p_tipocalculo char
                            ---- M Mensal, B Bimestral, S Semestral, A Anual
                            ) return float;

  function cidtransbordo(p_ordemcarga number) return number;
  /****************************************************************************
  Autor: Marcus Rangel
  Objetivo: Retorna a cidade da ordem de carga
  *****************************************************************************/

  function cnpjcpf(pcgc_cpf varchar) return varchar2;
  /****************************************************************************
  Autor: Marcus Rangel
  Objetivo: Formatar a m�scara dos campos de CPF ou CNPJ 
  *****************************************************************************/
  function get_cgccpf_parcemp(p_codparcemp number,
                              p_tipo char) return varchar2;

  function codcidparcemp(pcodigo number,
                         ptipo char) return number;

  function tira_acento(pstring in varchar2) return varchar2;
  /****************************************************************************
  Autor: Marcus Rangel
  Objetivo: retorna o c�d cidade do parceiro ou da empresa de acordo com o
  parametro
  *****************************************************************************/

  /****************************************************************************
  Autor:    Ricardo Soares de Oliveira
  Data:     06/02/2018
  Objeto:   Codempmatriz
  Objetivo: Buscar o c�digo da empresa matriz
  *****************************************************************************/
  function codempmatriz(pcodemp number) return number;
  /****************************************************************************
  Autor:    Ricardo Soares de Oliveira
  Data:     28/08/2017
  Objeto:   Codusulib
  Objetivo: Busca o usu�rio liberador onde foram cadastradas os limites por al�ada (tabela adicional SF)
  *****************************************************************************/
  function codusulib(pcodcencus number) return number;

  /****************************************************************************
  Autor:    Ricardo Soares de Oliveira
  Data:     10/01/2018
  Objeto:   Codusulibsup
  Objetivo: retornar o usu�rio suplente (quando existir
  *****************************************************************************/
  function codusulibsup(p_codusu number) return number;

  function compara_destino(p_nucapsol int) return boolean;
  /****************************************************************************
  Autor: Marcus Rangel
  Objetivo: comparar as cidades informadas na aba itiner�rio na tela de 
  solicita��o de carro de apoio
  *****************************************************************************/

  function dadoslog(ptipo number) return varchar2;
  /****************************************************************************
  Autor: Ricardo Soares
  Objetivo: retorna o nomo do programa que esta executando a a��o na sess�o atual
  *****************************************************************************/

  function dadosordcarga(p_codemp number,
                         p_ordcarga number,
                         p_tipo char) return number;
  /****************************************************************************
  Autor: Marus Rangel
  Objetivo: get simples de informa��es da ordem de carga
  *****************************************************************************/

  -- Por Ricardo - Retorna dados da Tddpco
  function dados_tddpco(p_nucampo number,
                        p_nome varchar) return varchar;

  function datavencimento(pdtnegociacao date,
                          p_usarparametro char := 'S') return date;
  /****************************************************************************
  Autor: 
  Objetivo: 
  *****************************************************************************/

  function descrproduto(p_codprod number) return varchar2;
  /****************************************************************************
  Autor: Marcus Rangel
  Objetivo: get simples da descri��o do produto
  *****************************************************************************/

  function descrnatureza(p_codnat number) return varchar2;

  function descrcencus(p_codcencus number) return varchar2;

  function codcencus_usuario(p_codusu number) return number;

  function descrprojeto(p_codproj number) return varchar2;

  /*
  Autor:    Ricardo Soares de Olivera
  Data:     15/03/2018
  Objetivo: Retorna se a data � um dia util ou n�o. Se v_Resulta = 0 dia util, sen�o � s�bado, domingo ou feriado.
            - A Dia_Util retorna 0 se for dia util e 1 se for s�bado, domingo ou feriado (TSIFER)
            - A Dia_Util_Ultimo retorna o ultimo dia �til antes da data se ptipo:  A = Anterior ou ent�o o proximo se P = Pr�ximo 
  */
  function dia_util(p_data date) return int deterministic;

  function dia_util_ultimo(dt_base in date,
                           ptipo in char) return date;

  function distanciacidade(p_cidorigem int,
                           p_ciddest int) return float;
  /****************************************************************************
  Autor: Marcus Rangel
  Objetivo: get simples da dist�ncia entre cidades informadas 
  na rotina destinada a tal, por�m, realiza algumas tratativas
  *****************************************************************************/

  function enderecocompleto(ptipo char,
                            pcodigo number,
                            pcodigo2 number) return varchar2;
  /****************************************************************************
  Autor: Marcus Rangel
  Objetivo: get simples do endere�o completo do parceiro ou da empresa
  formatados
  *****************************************************************************/

  function formatacep(pcep varchar) return varchar;
  /****************************************************************************
  Autor: Marcus Rangel
  Objetivo: formata o CEP
  *****************************************************************************/

  /****************************************************************************
  Autor: Ricardo Soares
  Objeto: Formadevolucao
  Objetivo: verificar a forma de devolu��o que � apresentada na libera��o de 
  limites SSA buscando a informa��o na AD_TGFDEV
  *****************************************************************************/
  function formadevolucao(p_nunota number) return varchar;

  function formataplaca(p_placa varchar2) return varchar2;
  /****************************************************************************
  Autor: Marcus Rangel
  Objetivo: formata placa pela placa
  *****************************************************************************/

  function formataplaca(p_codveiculo number) return varchar2;
  /****************************************************************************
  Autor: Marcus Rangel
  Objetivo: Formata a placa pelo codigo do ve�culo
  *****************************************************************************/

  function formatatelefone(ptelefone varchar) return varchar2;

  function formatatelefone(p_codparc number) return varchar2;
  /****************************************************************************
  Autor: Marcus Rangel
  Objetivo: Formata o n�mero de telefone
  *****************************************************************************/

  function formatavalor(p_valor number) return varchar deterministic;
  /****************************************************************************
  Autor: Marcus Rangel
  Objetivo: Formata em valor de moeda
  *****************************************************************************/

  function formatanumero(p_numero number) return varchar;

  function mailfila(pcodfila number) return varchar2;
  /****************************************************************************
  Autor: 
  Objetivo: 
  *****************************************************************************/
  function mailusu(pcodusu number) return varchar2;
  /****************************************************************************
  Autor: Marcus Rangel
  Objetivo: get simples do email do usu�rio
  *****************************************************************************/

  function maxdhtipoper(pcodtop number) return date;
  /****************************************************************************
  Autor: Marcus Rangel
  Objetivo: retornar a maior data da TOP informada como argumento
  *****************************************************************************/

  function maxdhtipvenda(pcodtipvenda number) return date;
  /****************************************************************************
  Autor: Marcus Rangel
  Objetivo: retorna a maior data do tipo de negocia��o
  *****************************************************************************/

  function modulo11(p_numero in number) return number;
  /****************************************************************************
  Autor: 
  Objetivo: 
  *****************************************************************************/

  function nomemaquina return varchar2;
  /****************************************************************************
  Autor: Marcus Rangel
  Objetivo: retorna a descri��o da m�quina da sess�o atual
  *****************************************************************************/

  function ordemcargapai(p_ordemcarga number) return number;
  /****************************************************************************
  Autor: Marcus Rangel
  Objetivo: retornar o n�mero da ordem de carga pai, se houver
  *****************************************************************************/

  function nometop(pcodtop number) return varchar2;
  /****************************************************************************
  Autor: Marcus Rangel
  Objetivo: retornar a descri��o da top
  *****************************************************************************/

  function nomeusu(pcodusu number,
                   ptipo varchar2) return varchar2;
  /****************************************************************************
  Autor: Marcus Rangel
  Objetivo: Retornar o nome do usu�rio, completo ou resumido
  *****************************************************************************/

  function nuchavedest(p_taborig varchar2,
                       p_nuchaveorig number) return varchar2;
  /****************************************************************************
  Autor: Marcus Rangel
  Objetivo: Retornar o n�mero de destino de tabelas de processos personalizados 
  que fazem liga��o com tabelas do sistema
  *****************************************************************************/

  function opcoescampo(p_valor varchar,
                       p_nomecampo varchar,
                       p_nometab varchar) return varchar;
  /****************************************************************************
  Autor: Marcus Rangel
  Objetivo: Retornar os valores de campos do tipo lista
  *****************************************************************************/

  function qtdlibpend(p_nuchave number,
                      p_tabela varchar,
                      p_sequencia int) return number;
  /****************************************************************************
  Autor: 
  Objetivo: 
  *****************************************************************************/

  function sequenciaformacarga(p_codparc number) return number;
  /****************************************************************************
  Autor: 
  Objetivo: 
  *****************************************************************************/

  function ufparcemp(pcodigo number,
                     ptipo char) return number;
  /****************************************************************************
  Autor:     Ricardo Soares de Oliveira
  Objetivo:  Busca a UF do parceiro ou da empresa:
             pCodigo - informar CODPARC ou CODEMP
             pTipo   - P = Parceiro 
                       I = C�digo IBGE da UF do Parceiro
                       E = Empresa
  *****************************************************************************/
  procedure get_next_cod_tgfnum(p_tabela varchar2,
                                p_codemp number,
                                p_serie char,
                                p_proxcod out number);

  function ultcod(p_tabela varchar2,
                  p_codemp number,
                  p_serie char) return number;
  /****************************************************************************
  Autor: Marcus Rangel
  Objetivo: Retornar o ultimo c�digo da TGFNUM de dada tabela
  *****************************************************************************/

  function usuarioliberador(p_area varchar2) return number;
  /****************************************************************************
  Autor: 
  Objetivo: 
  *****************************************************************************/

  function validacr(pcodcr number) return int;
  /****************************************************************************
  Autor: 
  Objetivo: 
  *****************************************************************************/

  function validanat(pcodnat number) return int;
  /****************************************************************************
  Autor: 
  Objetivo: 
  *****************************************************************************/

  function validaprj(pcodprojeto number) return int;
  /****************************************************************************
  Autor: 
  Objetivo: 
  *****************************************************************************/

  function valorextenso(valor number) return varchar2;
  /****************************************************************************
  Autor: Marcus Rangel
  Objetivo: Retornar o valor por extenso moeda de um numeral
  *****************************************************************************/

  procedure valor_tabela_despfrete(p_nudef int,
                                   p_nurecibo int,
                                   p_motivo int,
                                   p_valor out float,
                                   p_nutabela out int);
  /****************************************************************************
  Autor: 
  Objetivo: 
  *****************************************************************************/

  function valorguiarecolhimento(p_codbar varchar2) return float;
  /****************************************************************************
  Autor: 
  Objetivo: 
  *****************************************************************************/

  function temcompensacao(p_codparc int) return int;
  /****************************************************************************
  Autor:     Ricardo Soares em 12/07/2017
  Objetivo:  Uso em principio na TRG_UPT_TGFFIN_CODBARRA_SF para saber se a despesa que esta sendo conferida tem compensa��o pendente
  *****************************************************************************/

  function temlib(pnufin int) return number;
  function temlib(p_nufin number,
                  p_tabela varchar2) return number;
  function temlib(p_nufin number,
                  p_tabela varchar2,
                  p_sequencia int,
                  p_evento number) return number;
  /****************************************************************************
  Autor: Ricardo Soares em 26/10/2017
  Objetivo: Uso na TRG_CMP_TGFFIN_CONFIRMA_SF
  *****************************************************************************/

  function temwms(p_nunota int) return int;
  /****************************************************************************
  Autor: 
  Objetivo: 
  *****************************************************************************/

  /****************************************************************************
  Autor: Ricardo Soares
  Data: 23/08/2017
  Objeto: Tipdev
  Objetivo: Identificar se a devolu��o � total ou parcial
  *****************************************************************************/
  function tipdev(pnunota number) return varchar2;

  function tipmovtop(pcodtop number,
                     pdhtipoper date) return char;
  /****************************************************************************
  Autor: 
  Objetivo: 
  *****************************************************************************/

  --FUNCTION Maxdhtipoper(Pcodtop NUMBER) RETURN DATE;

  function tipovendamais(p_codparc int) return varchar2;
  /****************************************************************************
  Autor: 
  Objetivo: 
  *****************************************************************************/

  function totcontrato(p_numcontrato number,
                       p_tipo varchar2) return float;
  /****************************************************************************
  Autor: 
  Objetivo: 
  *****************************************************************************/

  function ultcodparc(p_codparc int) return number;
  /****************************************************************************
  Autor: 
  Objetivo: 
  *****************************************************************************/

  function horasuteis(p_dataini timestamp,
                      p_datafin timestamp) return float;
  /****************************************************************************
  Autor: Marcus Rangel
  Objetivo: retornar a quantidade de horas �teis, considerando 
  feriados  da TSIFER e os finais de semana entre duas datas 
  passadas como par�metros
  *****************************************************************************/

  function subtrai_hora_acidente(p_dtacid date,
                                 p_hrtrabalho varchar2) return varchar2;

  /****************************************************************************
  Autor: Gusttavo Lopes
  Objetivo: retornar o ultimo valor da moeda a partir de uma data especifica
  *****************************************************************************/
  function moeda(p_codmoeda int,
                 p_dtmoeda date) return float;

  /****************************************************************************
  Autor: Marcus Rangel
  Objetivo: retornar o cnpj do parceiro tendo o parceiro como parametro
  *****************************************************************************/
  function formatacnpjcpf(p_codparc number) return varchar2;

  /****************************************************************************
  Autor: Gusttavo Lopes
  Data: 10/10/2017
  Objeto: Tipdev
  Objetivo: Identificar se a situa��o do pedido
    - Pendente
    - Confirmado
    - Fat. Parcial
    - Fat. Completo   
  *****************************************************************************/
  function sitpedido(pnunota number) return varchar2;

  function data_w(p_data varchar2) return date;
  /*
  * Autor: Marcus Rangel
  * Objetivo: Formatar as datas recebidas do Sankhya W e trat�-las para utiliza��o 
  * em consultas de campos calculados. As datas recebidas no W vem nesse formato:
  '2017-10-18 00:00:00.0' e � muito trabalhoso trabalhar com ela dentro do campo
  */

  function custo_produto(p_codprod in number,
                         p_codemp in number,
                         p_data in date,
                         p_tipo in number) return float;

  /*
  * Autor: Marcus Rangel
  * Objetivo: Reover o c�idgo do erro nativo do Oracle para melhor exibi��o na
  * execu��o de procedimentos
  */
  function custo_produto(p_codprod in number,
                         p_codemp in number,
                         p_codlocal in number,
                         p_data in date,
                         p_tipo in number) return float;

  function formatnativeoramsg(p_errmsg varchar2) return varchar2;

  --Function formata_valor_hora(p_valor Float) Return Varchar2;
  function formata_valor_hora(p_valor float) return number;

  function removerduplicidade(p_texto varchar2,
                              p_caracter char) return varchar2;

  function valorprodcontrato(p_numcontrato number,
                             p_codprod number) return float;

  function nome_parceiro(p_codparc number,
                         p_tiponome varchar2) return varchar2;

  function aliq_piscofins(p_codprod number,
                          p_nomeimp varchar2,
                          p_top number) return float;

  function ultimo_valor_contrato(p_numcontrato number,
                                 p_codprod number,
                                 p_data date) return float;

  -- M. Rangel - Retorna o c�digo do usu�rio respons�vel do centro de resultados
  function codusuresp_cencus(p_codcencus number) return number;

  function nuinstancia(p_nometabela varchar) return number;

  function cotacao_moeda(p_codmoeda number,
                         p_dtref date) return float;

  function cr_do_usuario(p_codusu number) return number;
  function meses_entre_datas(p_dtini date,
                             p_dtfin date) return number;

end;
/
create or replace package body ad_get is

  /*
  ** Autor: Marcus Rangel
  ** Objetivo: Conter diversas fun��es e procedimentos comuns a diversas rotinas
  */

  function calculajuro(p_tipo char,
                       p_valor float,
                       p_taxa float,
                       p_prazo float) return float is
    v_vlrjuro float;
  begin
    if p_tipo = 'S' then
      v_vlrjuro := p_valor * (p_taxa / 100) * p_prazo;
    else
      v_vlrjuro := p_valor * power(1 + p_taxa / 100, p_prazo) - p_valor;
    end if;
    return v_vlrjuro;
  end calculajuro;

  function tira_acento(pstring in varchar2) return varchar2 is
    vstringreturn varchar2(4000);
  begin
    vstringreturn := translate(pstring, '����������������������������������������',
                               'ACEIOUAEIOUAEIOUAOEUaceiouaeiouaeiouaoeu');
    return ltrim(rtrim(vstringreturn));
  
  end;

  /*
  Autor: Ricardo Soares em 27/07/2017
  Objetivo: Efetuar o calculo de juros pela tabela price com amortiza��o constante.
  */
  function calculajuroprice(i float, /*Taxa Juro*/
                            n int, /*Periodo em meses*/
                            pv float, /*Valor Presente*/
                            p_dtneg date,
                            -- Data da concess�o do adiantamento
                            p_dtprimvenc date,
                            -- Data vencimento primeira parcela
                            p_parcela int,
                            -- Nr da Parcela
                            p_tipojuro char,
                            -- C = Composto, S = Simples
                            p_tipocalculo char
                            -- M Mensal, B Bimestral, S Semestral, A Anual
                            ) return float is
  
    pmt                float; /*Presta��o*/
    p_diasprimparc     number; -- Dias entre a concess�o do adiantamento e o vencimento da primeira parcela
    p_periodo          number; -- Periodo p/ c�lculo N * p_TipoCalculo
    p_valorjuroparcela number; -- Valor juro por parcela
    p_valorparcela     float; -- Valor Parcela sem juro
    p_taxa             float := i / 100;
  
  begin
  
    if p_tipojuro = 'C' then
    
      p_periodo := n * (case
                     when p_tipocalculo = 'B' then
                      2
                     when p_tipocalculo = 'S' then
                      6
                     when p_tipocalculo = 'A' then
                      12
                     else
                      1
                   end);
    
      pmt := round(pv * (power((1 + p_taxa), p_periodo)) * p_taxa / ((power((1 + p_taxa), p_periodo)) - 1), 2);
    
      p_valorparcela := round((pv / p_periodo), 2);
    
      p_diasprimparc := p_dtprimvenc - p_dtneg;
    
      if (p_diasprimparc < 29 or p_diasprimparc > 31) and p_parcela = 1 and p_tipocalculo = 'M' then
      
        p_valorjuroparcela := (((pmt - p_valorparcela) / 30) * p_diasprimparc) * (case
                                when p_tipocalculo = 'B' then
                                 2
                                when p_tipocalculo = 'S' then
                                 6
                                when p_tipocalculo = 'A' then
                                 12
                                else
                                 1
                              end);
      
        return p_valorjuroparcela;
      
      else
      
        p_valorjuroparcela := (pmt - p_valorparcela) * (case
                                when p_tipocalculo = 'B' then
                                 2
                                when p_tipocalculo = 'S' then
                                 6
                                when p_tipocalculo = 'A' then
                                 12
                                else
                                 1
                              end);
      
        return p_valorjuroparcela;
      
      end if;
    
    else
      p_valorjuroparcela := (pv * p_taxa) / n;
      return p_valorjuroparcela;
    end if;
  
  end calculajuroprice;

  function cidtransbordo(p_ordemcarga number) return number is
    result number;
  begin
    begin
      select p.codcid
        into result
        from tgfpar p
        join tgfcab c
          on c.codparc = p.codparc
        join tgford o
          on c.ordemcarga = o.ordemcargapai
       where o.ordemcarga = p_ordemcarga
       group by p.codcid;
    exception
      when others then
        result := 0;
    end;
    return result;
  end cidtransbordo;

  function codcidparcemp(pcodigo number,
                         ptipo char) return number is
    vcodcid number;
  begin
    if ptipo = 'P' then
      select codcid into vcodcid from tgfpar where codparc = pcodigo;
    elsif ptipo = 'E' then
      select e.codcid into vcodcid from tsiemp e where codemp = pcodigo;
    end if;
    return vcodcid;
  end codcidparcemp;

  /****************************************************************************
  Autor:    Ricardo Soares de Oliveira
  Data:     06/02/2018
  Objeto:   Codempmatriz
  Objetivo: Buscar o c�digo da empresa matriz
  *****************************************************************************/
  function codempmatriz(pcodemp number) return number is
    vcodempmatriz number;
  begin
    begin
      select nvl(codempmatriz, codemp) into vcodempmatriz from tsiemp e where e.codemp = pcodemp;
    
    exception
      when no_data_found then
        vcodempmatriz := 0;
    end;
  
    return vcodempmatriz;
  
  end codempmatriz;

  /****************************************************************************
  Autor:    Ricardo Soares de Oliveira
  Data:     28/08/2017
  Objeto:   Codusulib
  Objetivo: Busca o usu�rio liberador onde foram cadastradas os limites por al�ada (tabela adicional SF)
  *****************************************************************************/
  function codusulib(pcodcencus number) return number is
    vcodusulib number;
  begin
    begin
      select lib.codusu
        into vcodusulib
        from ad_itesolcpalibcr lib, tsicus cus, tsiusu u
       where lib.ativo = 'SIM'
         and lib.codcencus = cus.codcencus
         and lib.codcencus = pcodcencus
         and lib.codusu = u.codusu
         and lib.aprova = 'S';
    
    exception
      when no_data_found then
        vcodusulib := 0;
    end;
  
    return vcodusulib;
  
  end codusulib;

  /****************************************************************************
  Autor:    Ricardo Soares de Oliveira
  Data:     10/01/2018
  Objeto:   Codusulibsup
  Objetivo: retornar o usu�rio suplente (quando existir
  *****************************************************************************/
  function codusulibsup(p_codusu number) return number is
    functionresult number;
  begin
    begin
      select min(s.codususupl)
        into functionresult
        from tsisupl s
       where s.codusu = p_codusu
         and s.dtinicio <= trunc(sysdate)
         and s.dtfim >= trunc(sysdate);
    exception
      when no_data_found then
        functionresult := 0;
    end;
    return(functionresult);
  
  end codusulibsup;

  function compara_destino(p_nucapsol int) return boolean is
    v_orig       char(1);
    v_codcidorig int;
    v_dest       char(1);
    v_codciddest int;
    v_count      int := 0;
    v_igual      boolean := false;
  begin
    --v_NuCapSol := 23;
  
    for c_itn in (select * from ad_tsfcapitn where nucapsol = p_nucapsol order by nucapsol, nuitn)
    loop
      if c_itn.tipotin = 'D' then
        v_orig       := c_itn.tipotin;
        v_codcidorig := c_itn.codcid;
      elsif c_itn.tipotin = 'O' then
        v_dest       := c_itn.tipotin;
        v_codciddest := c_itn.codcid;
      end if;
    
      v_count := v_count + 1;
    
      if v_count = 2 then
        if v_codcidorig = v_codciddest then
          v_igual := true;
        else
          v_igual := false;
        end if;
        v_count := 0;
      end if;
    end loop;
    return v_igual;
  end compara_destino;

  function dadoslog(ptipo number) return varchar2 is
  
    v_usuario_banco varchar2(60);
    v_usuario_rede  varchar2(60);
    v_nomemaquina   varchar2(60);
    v_ipmaquina     varchar2(60);
    v_programa      varchar2(60);
  begin
  
    select username, osuser, machine, sys_context('USERENV', 'IP_ADDRESS'), program
      into v_usuario_banco, v_usuario_rede, v_nomemaquina, v_ipmaquina, v_programa
      from v$session
     where audsid = (select userenv('SESSIONID') from dual);
  
    if ptipo = 1 then
      return v_usuario_banco;
    elsif ptipo = 2 then
      return v_usuario_rede;
    elsif ptipo = 3 then
      return v_nomemaquina;
    elsif ptipo = 4 then
      return v_ipmaquina;
    elsif ptipo = 5 then
      return v_programa;
    end if;
  
  end dadoslog;

  function dadosordcarga(p_codemp number,
                         p_ordcarga number,
                         p_tipo char) return number is
    v_result number;
  begin
    if p_tipo = 'V' then
      select o.codveiculo
        into v_result
        from tgford o
       where o.codemp = p_codemp
         and o.ordemcarga = p_ordcarga;
    elsif p_tipo = 'T' then
      select o.codparctransp
        into v_result
        from tgford o
       where o.codemp = p_codemp
         and o.ordemcarga = p_ordcarga;
    elsif p_tipo = 'M' then
      select o.codparcmotorista
        into v_result
        from tgford o
       where o.codemp = p_codemp
         and o.ordemcarga = p_ordcarga;
    end if;
  
    return v_result;
  exception
    when others then
      v_result := 0;
      return v_result;
  end dadosordcarga;

  -- Por Ricardo - Retorna dados da Tddpco
  function dados_tddpco(p_nucampo number,
                        p_nome varchar) return varchar as
    v_valor varchar2(20);
  
  begin
    begin
      select decode(o.valor, 'default', 'Padr�o', 'mult-list', 'Multi Sele��o', 'period', 'Per�odo', 'S', 'Sim', 'N�o')
        into v_valor
        from tddpco o
       where o.nucampo = p_nucampo
         and o.nome = p_nome;
      /* op��es para p_nome     
         combobox    = Listao de opcoes
         filterLabel = Descri��o da vari�vel no filtro
         filterType  = Tipo de Filtro
         mult-list   = Mult Sele��o
         nullable    = Permite nulo
         period      = Periodo
         requerido   = Requerido
         readOnly    = Somenteleitura
         UITabName   = Nome aba
         UIGroupName = Nome agrupamento
         visivel     = Visivel
      */
    exception
      when no_data_found then
        v_valor := '';
    end;
  
    return v_valor;
  end dados_tddpco;

  function datavencimento(pdtnegociacao date,
                          p_usarparametro char := 'S') return date is
    vqtddiasparametro int := 0;
    vvalida           int;
    pdtvencimento     date;
  
  begin
    ---Paramentro para definir a data minima para vencimento
    if p_usarparametro = 'S' then
      vqtddiasparametro := get_tsipar_inteiro('DIASUTEISADTOSF');
    end if;
  
    ---Verifica se n�o esta sendo programado para s�bado (7) ou domingo (1)
    vvalida := vqtddiasparametro + (case
                 when to_number(to_char(to_date(to_char(pdtnegociacao + vqtddiasparametro, 'DDMMYYYY'), 'DDMMYYYY'), 'D')) = 7 then
                  2
                 when to_number(to_char(to_date(to_char(pdtnegociacao + vqtddiasparametro, 'DDMMYYYY'), 'DDMMYYYY'), 'D')) = 1 then
                  1
                 else
                  0
               end);
  
    pdtvencimento := pdtnegociacao + vvalida;
  
    return pdtvencimento;
  end datavencimento;

  function descrproduto(p_codprod number) return varchar2 is
    v_descrproduto varchar2(400);
  begin
  
    select p.descrprod into v_descrproduto from tgfpro p where p.codprod = p_codprod;
  
    return v_descrproduto;
  
  exception
    when others then
      return v_descrproduto;
  end descrproduto;

  function descrnatureza(p_codnat number) return varchar2 is
    v_descrnat varchar2(400);
  begin
  
    select n.descrnat into v_descrnat from tgfnat n where codnat = p_codnat;
  
    return v_descrnat;
  
  exception
    when others then
      return v_descrnat;
  end descrnatureza;

  function descrcencus(p_codcencus number) return varchar2 is
    v_descrcencus varchar2(400);
  begin
  
    select c.descrcencus into v_descrcencus from tsicus c where c.codcencus = p_codcencus;
  
    return v_descrcencus;
  
  exception
    when others then
      return v_descrcencus;
  end descrcencus;

  function codcencus_usuario(p_codusu number) return number is
    u tsiusu%rowtype;
  begin
  
    select * into u from tsiusu u where u.codusu = p_codusu;
  
    if nvl(u.codcencuspad, 0) > 0 then
      return u.codcencuspad;
    elsif nvl(u.ad_codcencususu, 0) > 0 then
      return u.ad_codcencususu;
    elsif u.ad_fumatfunc is not null then
      select f.fucentrcus into u.codcencuspad from fpwpower.funciona f where f.fumatfunc = u.ad_fumatfunc;
      return u.codcencuspad;
    else
      return 0;
    end if;
  exception
    when others then
      return 0;
  end codcencus_usuario;

  function descrprojeto(p_codproj number) return varchar2 is
    v_descrproj varchar2(400);
  begin
  
    select p.identificacao into v_descrproj from tcsprj p where p.codproj = p_codproj;
  
    return v_descrproj;
  
  exception
    when others then
      return v_descrproj;
  end descrprojeto;

  /*
  Autor:    Ricardo Soares de Olivera
  Data:     15/03/2018
  Objetivo: Retorna se a data � um dia util ou n�o. Se v_Resulta = 0 dia util, sen�o � s�bado, domingo ou feriado.
            - A Dia_Util retorna 0 se for dia util e 1 se for s�bado, domingo ou feriado (TSIFER)
            - A Dia_Util_Ultimo retorna o ultimo dia �til antes do feriado
  */
  function dia_util(p_data date) return int deterministic is
    v_result  int;
    v_fds     int;
    v_feriado int;
  begin
    v_fds := case
               when to_char(p_data, 'D') in (1, 7) then
                1
               else
                0
             end;
  
    begin
      select count(*)
        into v_feriado
        from tsifer
       where (dtferiado = p_data)
          or (to_char(dtferiado, 'DD/MM') = to_char(p_data, 'DD/MM') and recorrente = 'S');
    exception
      when no_data_found then
        v_feriado := 0;
    end;
    v_result := nvl(v_fds, 0) + nvl(v_feriado, 0);
  
    return v_result;
  end dia_util;

  function dia_util_ultimo(dt_base in date,
                           ptipo in char) return date as
    -- ptipo: P = Pr�ximo; A = Anterior
    dt_basex date;
    bo_fimx  boolean;
  
  begin
  
    dt_basex := dt_base;
    bo_fimx  := false;
  
    while not (bo_fimx)
    loop
    
      bo_fimx := to_char(dt_basex, 'd') not in ('1', '7');
    
      if dia_util(dt_basex) = 1 then
        bo_fimx := false;
      end if;
    
      if not (bo_fimx) then
        dt_basex := case
                      when ptipo = 'P' then
                       dt_basex + 1
                      else
                       dt_basex - 1
                    end;
      end if;
    
    end loop;
  
    return dt_basex;
  
  exception
  
    when others then
      raise;
    
  end dia_util_ultimo;

  function distanciacidade(p_cidorigem int,
                           p_ciddest int) return float is
    vdistancia float;
  begin
    begin
      select distancia
        into vdistancia
        from tsidis d
       where (d.codcidorig = p_cidorigem and d.codciddest = p_ciddest)
          or (d.codciddest = p_cidorigem and d.codcidorig = p_ciddest);
    exception
      when no_data_found then
        vdistancia := 500;
      when too_many_rows then
        select distancia
          into vdistancia
          from tsidis d
         where ((d.codcidorig = p_cidorigem and d.codciddest = p_ciddest) or
               (d.codciddest = p_cidorigem and d.codcidorig = p_ciddest))
           and rownum = 1;
    end;
  
    return nvl(vdistancia, 500);
  
  end distanciacidade;

  function enderecocompleto(ptipo char,
                            pcodigo number,
                            pcodigo2 number) return varchar2 is
    vendereco varchar2(600);
  
    /*
    ***** Ptipo *****
    C - Contato do Parceiro
    E - Empresa
    P - Parceiro
    
    ***** Pcodigo ***** 
    Passar de acordo com o tipo, ou seja CODPARC, CODEMP ou CODCONTATO
    
    ***** Pcodigo2 *****
    0 - Endere�o / Cidade / UF / CEP
    1 - Endere�o / Cidade / UF
    2 - Endere�o / Cidade
    3 - Endere�o
    4 - Cidade / UF
    5 - UF
    6 - CEP
    7 - Pais
    */
  
  begin
    if ptipo = 'P' and nvl(pcodigo2, 0) = 0 then
      select end1.tipo || ' ' || ltrim(rtrim(end1.nomeend)) || case
               when par.numend is not null then
                ', ' || par.numend
               else
                ''
             end || ltrim(rtrim(par.complemento)) || ' - ' || bai.nomebai || ', ' || cid.nomecid || ' - ' || ufs.uf ||
             ' CEP: ' || par.cep
        into vendereco
        from tgfpar par
       inner join tsiend end1
          on (par.codend = end1.codend)
       inner join tsibai bai
          on (par.codbai = bai.codbai)
       inner join tsicid cid
          on (par.codcid = cid.codcid)
       inner join tsiufs ufs
          on (cid.uf = ufs.coduf)
       where par.codparc = pcodigo;
    
    elsif ptipo = 'P' and nvl(pcodigo2, 0) = 3 then
      select ltrim(rtrim(end1.nomeend)) || ' ' || ltrim(rtrim(par.complemento)) || ' - ' || bai.nomebai
        into vendereco
        from tgfpar par
       inner join tsiend end1
          on (par.codend = end1.codend)
       inner join tsibai bai
          on (par.codbai = bai.codbai)
       where par.codparc = pcodigo;
    
    elsif ptipo = 'P' and nvl(pcodigo2, 0) = 4 then
      select cid.nomecid || ' - ' || ufs.uf
        into vendereco
        from tgfpar par
       inner join tsicid cid
          on (par.codcid = cid.codcid)
       inner join tsiufs ufs
          on (cid.uf = ufs.coduf)
       where par.codparc = pcodigo;
    
    elsif ptipo = 'P' and nvl(pcodigo2, 0) = 7 then
      select pai.descricao
        into vendereco
        from tgfpar par
       inner join tsiend end1
          on (par.codend = end1.codend)
       inner join tsibai bai
          on (par.codbai = bai.codbai)
       inner join tsicid cid
          on (par.codcid = cid.codcid)
       inner join tsiufs ufs
          on (cid.uf = ufs.coduf)
       inner join tsipai pai
          on ufs.codpais = pai.codpais
       where par.codparc = pcodigo;
    
    elsif ptipo = 'C' then
    
      select ltrim(rtrim(end1.nomeend)) || ' ' || ltrim(rtrim(ctt.complemento)) || ' - ' || bai.nomebai || ', ' ||
             cid.nomecid || '/' || ufs.uf || ' CEP: ' || ctt.cep
        into vendereco
        from tgfctt ctt
       inner join tsiend end1
          on (ctt.codend = end1.codend)
       inner join tsibai bai
          on (ctt.codbai = bai.codbai)
       inner join tsicid cid
          on (ctt.codcid = cid.codcid)
       inner join tsiufs ufs
          on (cid.uf = ufs.coduf)
       where ctt.codparc = pcodigo
         and ctt.codcontato = pcodigo2;
    
    elsif ptipo = 'E' then
    
      select end1.tipo || '  ' || end1.nomeend || ', ' || emp.numend || ' - ' || emp.complemento || ' - ' ||
             bai.nomebai || ' - ' || cid.nomecid || '/' || ufs.uf || ' CEP: ' || emp.cep
        into vendereco
        from tsiemp emp, tsiend end1, tsibai bai, tsicid cid, tsiufs ufs
       where emp.codend = end1.codend
         and emp.codbai = bai.codbai
         and emp.codcid = cid.codcid
         and cid.uf = ufs.coduf
         and emp.codemp = pcodigo;
    else
      vendereco := 'Sem Endere�co ';
    
    end if;
    return vendereco;
  end enderecocompleto;

  function formatacep(pcep varchar) return varchar is
    vcep varchar2(20);
  begin
    vcep := regexp_replace(lpad(pcep, 8, '0'), '([0-9]{2})([0-9]{3})([0-9]{3})', '\1.\2-\3');
    return vcep;
  end formatacep;

  function formatacnpjcpf(pcampo varchar2) return varchar2 is
    vcnpjcpf varchar(20);
  begin
    if length(pcampo) = 11 then
      vcnpjcpf := regexp_replace(lpad(pcampo, 11, '0'), '([0-9]{3})([0-9]{3})([0-9]{3})([0-9]{2})', '\1.\2.\3-\4');
    end if;
    if length(pcampo) = 14 then
      vcnpjcpf := regexp_replace(lpad(pcampo, 14, '0'), '([0-9]{2})([0-9]{3})([0-9]{3})([0-9]{4})([0-9]{2})',
                                 '\1.\2.\3/\4-\5');
    end if;
  
    return(vcnpjcpf);
  end formatacnpjcpf;

  function formatacnpjcpf(p_codparc number) return varchar2 is
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
  
  end formatacnpjcpf;

  /****************************************************************************
  Autor: Ricardo Soares
  Objeto: Formadevolucao
  Objetivo: verificar a forma de devolu��o que � apresentada na libera��o de 
  limites SSA buscando a informa��o na AD_TGFDEV
  *****************************************************************************/
  function formadevolucao(p_nunota number) return varchar is
    v_valor char(1);
  begin
    begin
      select forma into v_valor from ad_tgfdev d where d.nunota = p_nunota;
    exception
      when no_data_found then
        v_valor := 'N';
    end;
    return v_valor;
  end formadevolucao;

  function formataplaca(p_placa varchar2) return varchar2 is
    v_placa varchar2(10);
  begin
    v_placa := regexp_replace(p_placa, '([A-Z]{3})([0-9]{4})', '\1-\2');
    return v_placa;
  end formataplaca;

  function formataplaca(p_codveiculo number) return varchar2 is
    v_placa varchar2(10);
  begin
    select v.placa into v_placa from tgfvei v where codveiculo = p_codveiculo;
    v_placa := regexp_replace(v_placa, '([A-Z]{3})([0-9]{4})', '\1-\2');
    return v_placa;
  end formataplaca;

  function formatatelefone(ptelefone varchar) return varchar2 is
    v_telefone varchar2(20);
  begin
  
    v_telefone := replace(replace(ptelefone, ' ', ''), '-', '');
  
    if length(v_telefone) = 8 then
      v_telefone := '0629' || v_telefone;
      v_telefone := '(' || substr(v_telefone, 1, 3) || ') ' || substr(v_telefone, -9, 5) || '-' ||
                    substr(v_telefone, -4);
    elsif length(ptelefone) = 12 then
      --v_Telefone := '(' || Substr(Ptelefone, 1, 2) || ') ' || Substr(Ptelefone, -8, 4) || '-' || Substr(Ptelefone, -4);
      v_telefone := '(' || substr(v_telefone, 1, 3) || ') ' || substr(v_telefone, -9, 5) || '-' ||
                    substr(v_telefone, -4);
    elsif length(ptelefone) = 13 then
      v_telefone := '(' || substr(v_telefone, 1, 2) || ') ' || substr(v_telefone, -9, 5) || '-' ||
                    substr(v_telefone, -4);
    end if;
    return v_telefone;
  end;

  function formatatelefone(p_codparc number) return varchar2 is
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
  
  end formatatelefone;

  function formatavalor(p_valor number) return varchar deterministic is
    v_valor varchar2(15);
  begin
    v_valor := replace(ltrim(rtrim('R$' || to_char(p_valor, '999G990D99'))), '   ', ' ');
    return v_valor;
  end formatavalor;

  function formatanumero(p_numero number) return varchar is
    result varchar2(100);
  begin
  
    result := to_char(p_numero, '999G999G999G999D99');
  
    return result;
  
  end formatanumero;

  function mailfila(pcodfila number) return varchar2 is
    mail varchar2(500);
  
  begin
  
    for c_usu in (select con.email, con.codusu
                    from tmdcpe cpe, tmdcon con
                   where cpe.codper = pcodfila
                     and cpe.codcon = con.codcon)
    loop
      if mail is null then
        mail := c_usu.email;
      else
        mail := mail || ', ' || c_usu.email;
      end if;
    
    end loop;
  
    return mail;
  end mailfila;

  function mailusu(pcodusu number) return varchar2 is
    vmailusu varchar2(400);
  begin
    begin
      select u.email into vmailusu from tsiusu u where codusu = pcodusu;
    exception
      when others then
        vmailusu := 'mgesankhya@ssa-br.com';
    end;
  
    return vmailusu;
  
  end mailusu;

  function maxdhtipoper(pcodtop number) return date is
    vdata date;
    pragma autonomous_transaction;
  begin
    select max(dhalter) into vdata from tgftop where codtipoper = pcodtop;
    return vdata;
  end maxdhtipoper;

  function maxdhtipvenda(pcodtipvenda number) return date is
    vdata date;
    pragma autonomous_transaction;
  begin
    select max(dhalter) into vdata from tgftpv where codtipvenda = pcodtipvenda;
    return vdata;
  end maxdhtipvenda;

  function modulo11(p_numero in number) return number is
    aux number;
    j   number;
  begin
    j   := 1;
    aux := 0;
    for i in reverse 1 .. length(p_numero)
    loop
      aux := aux + (to_number(substr(p_numero, j, 1))) * (i + 1);
      j   := j + 1;
    end loop;
    aux := mod(aux * 10, 11);
    if (aux >= 10) then
      aux := 0;
    end if;
    return nvl(aux, 0);
  
  end modulo11;

  function nomemaquina return varchar2 is
    nomemaquina v$session.terminal%type;
  begin
    select (upper(terminal))
      into nomemaquina
      from v$session
     where audsid = userenv('sessionid')
     group by (upper(terminal));
  
    return nomemaquina;
  end nomemaquina;

  function nometop(pcodtop number) return varchar2 is
    vnometop varchar2(200);
  begin
    select t.descroper
      into vnometop
      from tgftop t
     where t.codtipoper = pcodtop
       and dhalter = (select max(dhalter) from tgftop t2 where t2.codtipoper = t.codtipoper);
    return vnometop;
  end nometop;

  function nomeusu(pcodusu number,
                   ptipo varchar2) return varchar2 is
    vnomeusu varchar2(400);
  begin
    begin
      if upper(ptipo) = 'RESUMIDO' then
        select nomeusu into vnomeusu from tsiusu u where codusu = pcodusu;
      elsif upper(ptipo) = 'COMPLETO' then
        select u.nomeusucplt into vnomeusu from tsiusu u where codusu = pcodusu;
      end if;
    exception
      when others then
        vnomeusu := 'N�o Informado.';
    end;
  
    return vnomeusu;
  
  end nomeusu;

  function nuapontorig(p_numcontrato number) return number is
    v_nuapont number;
    pragma autonomous_transaction;
  begin
    select ad_nuapont into v_nuapont from tcscon c where numcontrato = p_numcontrato;
    return v_nuapont;
  exception
    when no_data_found then
      v_nuapont := 0;
      return v_nuapont;
  end nuapontorig;

  function nuchavedest(p_taborig varchar2,
                       p_nuchaveorig number) return varchar2 is
    v_result varchar2(100);
  begin
    for c in (select *
                from ad_tblcmf cmf
               where cmf.nometaborig = p_taborig
                 and nuchaveorig = p_nuchaveorig)
    loop
      if v_result is null then
        v_result := to_char(c.nuchavedest);
      else
        v_result := v_result || ', ' || to_char(c.nuchavedest);
      end if;
    end loop;
    return v_result;
  end nuchavedest;

  function opcoescampo(p_valor varchar,
                       p_nomecampo varchar,
                       p_nometab varchar) return varchar as
    v_opcao varchar2(256);
  begin
    select o.opcao
      into v_opcao
      from tddopc o
     where o.nucampo = (select nucampo
                          from tddcam c
                         where upper(c.nomecampo) = upper(p_nomecampo)
                           and upper(c.nometab) = upper(p_nometab))
       and o.valor = p_valor;
  
    return v_opcao;
  end;

  function ordemcargapai(p_ordemcarga number) return number is
    result number;
  begin
  
    begin
      select ordemcargapai into result from tgford o where o.ordemcarga = p_ordemcarga;
    exception
      when others then
        result := p_ordemcarga;
    end;
  
    if result is null then
      result := p_ordemcarga;
    end if;
  
    return result;
  end ordemcargapai;

  function qtdlibpend(p_nuchave number,
                      p_tabela varchar,
                      p_sequencia int) return number is
    v_qtdpendentes int := 0;
    pragma autonomous_transaction;
  begin
    select count(*)
      into v_qtdpendentes
      from tsilib
     where nuchave = p_nuchave
       and nvl(tabela, 0) = nvl(p_tabela, 0)
       and sequencia <> p_sequencia
       and dhlib is null;
  
    return v_qtdpendentes;
  
  end qtdlibpend;

  function sequenciaformacarga(p_codparc number) return number is
    v_numseq    number;
    v_codcid    number;
    v_codbairro number;
    pragma autonomous_transaction;
  begin
    select codcid, codbai into v_codcid, v_codbairro from tgfpar p where codparc = p_codparc;
  
    select to_number(id)
      into v_numseq
      from ad_vw_seqentperfil
     where codparc = p_codparc
       and codcid = v_codcid
       and codbai = v_codbairro;
  
    return v_numseq;
  
  exception
    when too_many_rows then
      select to_number(id)
        into v_numseq
        from ad_vw_seqentperfil
       where codparc = p_codparc
         and codcid = v_codcid
         and codbai = v_codbairro
         and rownum = 1;
      return v_numseq;
    when others then
      return 0;
  end sequenciaformacarga;

  function ufparcemp(pcodigo number,
                     ptipo char) return number as
    vvalor number;
  begin
    --uf do parceiro
    if ptipo = 'P' then
      select u.coduf
        into vvalor
        from tgfpar p, tsicid c, tsiufs u
       where p.codcid = c.codcid
         and u.coduf = c.uf
         and codparc = pcodigo;
    elsif ptipo = 'I' then
      select u.codibge
        into vvalor
        from tgfpar p, tsicid c, tsiufs u
       where p.codcid = c.codcid
         and u.coduf = c.uf
         and codparc = pcodigo;
    elsif ptipo = 'E' then
      -- Uf da empresa
      select u.coduf
        into vvalor
        from tsiemp e, tsicid c, tsiufs u
       where e.codcid = c.codcid
         and u.coduf = c.uf
         and codemp = pcodigo;
    end if;
    return vvalor;
  end ufparcemp;

  procedure get_next_cod_tgfnum(p_tabela varchar2,
                                p_codemp number,
                                p_serie char,
                                p_proxcod out number) is
    stmt        varchar2(4000);
    v_count     int := 0;
    column_name varchar2(100);
  begin
  
    <<get_number>>
    select nvl(ultcod, 0) + 1
      into p_proxcod
      from tgfnum n
     where nvl(n.arquivo, 0) = nvl(p_tabela, 0)
       and nvl(n.codemp, 0) = nvl(p_codemp, 0)
       and nvl(n.serie, 0) = nvl(p_serie, 0);
  
    /*Execute Immediate 'Select Column_Name from User_Ind_Columns i Where i.table_name = ''' ||
                    p_tabela || ''' And index_name Like ''PK%'''
    Into column_name;*/
  
    /*Execute Immediate 'Select count(*) from ' || p_tabela || ' where ' || column_name || ' = ' ||
                      p_ProxCod
      Into v_Count;
    
    If v_count > 0 Then
      Goto get_number;
    End If;*/
  
    stmt := 'Update TGFNUM set ultcod = ' || p_proxcod || ' where arquivo = ''' || p_tabela || '''and codemp = ' ||
            p_codemp || ' and serie = ''' || p_serie || '''';
  
    dbms_output.put_line(stmt);
  
    execute immediate stmt;
  
    --Commit;
  
  exception
    when others then
      --Rollback;
      raise;
  end get_next_cod_tgfnum;

  function ultcod(p_tabela varchar2,
                  p_codemp number,
                  p_serie char) return number is
    v_ultcod number;
  begin
  
    get_next_cod_tgfnum(p_tabela, p_codemp, p_serie, v_ultcod);
  
    return v_ultcod;
  exception
    when no_data_found then
      return 0;
  end ultcod;

  function usuarioliberador(p_area varchar2) return number is
    v_area      varchar2(30);
    v_codusulib number;
  begin
    v_area := upper(p_area);
    if v_area = 'TRANSPORTE' then
      select codusu
        into v_codusulib
        from tsiusu u
       where u.ad_gertransp = 'S'
         and rownum = 1;
    end if;
  
    return v_codusulib;
  
  exception
    when others then
      return 0;
  end usuarioliberador;

  function valida_ococontrato(p_numcontrato number) return char is
    vresult char(1);
  begin
  
    select oco.sitprod
      into vresult
      from tcsocc occ
     inner join tcsoco oco
        on occ.codocor = oco.codocor
     where occ.numcontrato = p_numcontrato
       and occ.dtocor = (select max(dtocor) from tcsocc o2 where o2.numcontrato = occ.numcontrato)
       and trunc(occ.dtocor) <= trunc(sysdate);
  
    return nvl(vresult, 'C');
  
  end valida_ococontrato;

  function validacr(pcodcr number) return int is
    vexiste int;
  begin
    select count(*)
      into vexiste
      from tsicus c
     where c.codcencus = pcodcr
       and c.ativo = 'S'
       and c.analitico = 'S';
    return vexiste;
  end validacr;

  function validaprj(pcodprojeto number) return int is
    vexiste int;
  begin
    select count(*)
      into vexiste
      from tcsprj p
     where p.codproj = pcodprojeto
       and p.ativo = 'S'
       and p.analitico = 'S';
    return vexiste;
  end validaprj;

  function validanat(pcodnat number) return int is
    vexiste int;
  begin
    select count(*)
      into vexiste
      from tgfnat n
     where n.codnat = pcodnat
       and n.ativa = 'S'
       and n.analitica = 'S';
    return vexiste;
  end validanat;

  function valorextenso(valor number) return varchar2 is
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
            texto_string := texto_string || 'Quatrilh�o ';
          elsif ind = 2 then
            texto_string := texto_string || 'Trilh�o ';
          elsif ind = 3 then
            texto_string := texto_string || 'Bilh�o ';
          elsif ind = 4 then
            texto_string := texto_string || 'Milh�o ';
          elsif ind = 5 then
            texto_string := texto_string || 'Mil ';
          end if;
        else
          if ind = 1 then
            texto_string := texto_string || 'Quatrilh�es ';
          elsif ind = 2 then
            texto_string := texto_string || 'Trilh�es ';
          elsif ind = 3 then
            texto_string := texto_string || 'Bilh�es ';
          elsif ind = 4 then
            texto_string := texto_string || 'Milh�es ';
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
  end valorextenso;

  procedure valor_tabela_despfrete(p_nudef int,
                                   p_nurecibo int,
                                   p_motivo int,
                                   p_valor out float,
                                   p_nutabela out int) is
    r_def ad_tsfdef%rowtype;
    error exception;
    pragma autonomous_transaction;
  begin
    select * into r_def from ad_tsfdef where nudef = p_nudef;
  
    /*    Begin
      Select *
        Into r_Rec
        From ad_tsfdefr
       Where nudef = p_nudef
         And nurecibo = p_nurecibo;
    Exception
      When Others Then
        Raise error;
    End;*/
  
    for c_regras in (select nutabela
                       from ad_tsfdeftc c
                      where nvl(c.ativo, 'N') = 'S'
                        and c.dtvigor <= trunc(sysdate))
    loop
      for c_1 in (select *
                    from ad_tsfdeftm m
                   where m.nutabela = c_regras.nutabela
                     and m.codmot = p_motivo)
      loop
        if c_1.valor <> 0 then
          p_valor    := c_1.valor;
          p_nutabela := c_1.nutabela;
        end if;
        for c_2 in (select *
                      from ad_tsfdeftr r
                     where c_regras.nutabela = r.nutabela
                       and r.codreg = r_def.codreg)
        loop
          if c_2.valor <> 0 then
            p_valor    := c_2.valor;
            p_nutabela := c_2.nutabela;
          end if;
          for c_3 in (select *
                        from ad_tsfdeftv v
                       where c_regras.nutabela = v.nutabela
                         and v.codveiculo = r_def.codveiculo)
          loop
            if c_3.valor <> 0 then
              p_valor    := c_3.valor;
              p_nutabela := c_3.nutabela;
            end if;
          end loop c_3;
        end loop c_2;
      end loop c_1;
    end loop c_regras;
  
    if p_valor is null then
      p_valor := 0;
    end if;
  exception
    when error then
      p_valor := 0;
  end valor_tabela_despfrete;

  function valorguiarecolhimento(p_codbar varchar2) return float is
    a char(1);
    b char(4);
    c char(2);
    d varchar2(20);
    v float;
  begin
  
    a := substr(p_codbar, 11, 1);
    b := substr(p_codbar, 13, 4);
    c := substr(p_codbar, 17, 2);
    d := a || b || c;
    v := to_number(d) / 10000;
  
    return v;
  
  end valorguiarecolhimento;

  -- Por Ricardo Soares em 12/07/2017 - Uso em principio na TRG_UPT_TGFFIN_CODBARRA_SF para saber se a despesa que esta sendo conferida tem compensa��o pendente
  function temcompensacao(p_codparc int) return int is
    v_tem int;
  begin
  
    select count(*)
      into v_tem
      from tgffin f
     where f.recdesp = 1
       and f.provisao = 'N'
       and f.dhbaixa is null
       and f.codparc in
           (select p.codparc from tgfpar p where p.codparcmatriz = ad_analise_credito.codparcmatriz(p_codparc));
  
    return v_tem;
  
  exception
    when no_data_found then
      return 0;
    
  end temcompensacao;

  function temlib(pnufin int) return number is
    v_temlib number;
  begin
  
    select count(*)
      into v_temlib
      from tsilib l
     where l.nuchave = pnufin
       and l.tabela = 'TGFFIN'
       and l.evento = 1017
       and l.dhlib is not null;
  
    return v_temlib;
  
  end temlib;

  function temlib(p_nufin number,
                  p_tabela varchar2) return number is
    result number;
    pragma autonomous_transaction;
  begin
    select count(*)
      into result
      from tsilib l
     where l.nuchave = p_nufin
       and tabela = p_tabela
       and dhlib is null;
  
    return result;
  
  end temlib;

  function temlib(p_nufin number,
                  p_tabela varchar2,
                  p_sequencia int,
                  p_evento number) return number is
    result number;
    --Pragma Autonomous_Transaction;
  begin
    select count(*)
      into result
      from tsilib l
     where l.nuchave = p_nufin
       and tabela = p_tabela
       and sequencia = p_sequencia
       and evento = p_evento
       and dhlib is null;
  
    return result;
  
  end temlib;

  function temwms(p_nunota int) return int is
    v_temwms int;
  begin
    select distinct c.nunota
      into v_temwms
      from tgfcab c, tgftop t, tgfite i
     where c.codtipoper = t.codtipoper
       and c.dhtipoper = t.dhalter
       and c.nunota = i.nunota
       and c.codemp = 1
       and i.codlocalorig = 3710
       and t.utilizawms = 'M'
       and t.tipatualwms = 'E'
       and c.nunota = p_nunota;
  
    return v_temwms;
  
  exception
    when no_data_found then
      return 0;
    
  end temwms;

  function ticketvenda(p_codparc int,
                       p_tipo varchar2) return float is
    v_ticketvenda float;
  
    /*
    ***** p_Tipo *****
    R - Lista o ticket m�dio em R$ dos �ltimos 365 dias
    T - Lista o ticket m�dio em Kg dos �ltimos 365 dias
    P - Lista o t�cket m�dio mensal em R$ dos �ltimos 365 dias 
    M - Lista o ticket m�dio mensal em R$ dos �ltimos 120 dias
    */
  
  begin
    if p_tipo = 'R' then
    
      select round(avg(c.vlrnota), 2)
        into v_ticketvenda
        from tgfcab c, tgfpar p, tgftop t
       where c.codparc = p.codparc
         and c.codtipoper = t.codtipoper
         and c.dhtipoper = t.dhalter
         and upper(t.grupo) like '%VENDA%'
         and t.atualfin = 1
         and t.tipatualfin = 'I'
         and c.tipmov = 'V'
         and c.statusnota = 'L'
         and c.dtneg >= trunc(sysdate) - 365
         and p.codparcmatriz = p_codparc;
    
    elsif p_tipo = 'T' then
    
      select round(avg(c.peso), 2)
        into v_ticketvenda
        from tgfcab c, tgfpar p, tgftop t
       where c.codparc = p.codparc
         and c.codtipoper = t.codtipoper
         and c.dhtipoper = t.dhalter
         and upper(t.grupo) like '%VENDA%'
         and t.atualfin = 1
         and t.tipatualfin = 'I'
         and c.tipmov = 'V'
         and c.statusnota = 'L'
         and c.dtneg >= trunc(sysdate) - 365
         and p.codparcmatriz = p_codparc;
    
    elsif p_tipo = 'P' then
    
      select round(sum(c.vlrnota) / 12, 2) media
        into v_ticketvenda
        from tgfcab c, tgfpar p, tgftop t
       where c.codparc = p.codparc
         and c.codtipoper = t.codtipoper
         and c.dhtipoper = t.dhalter
         and upper(t.grupo) like '%VENDA%'
         and t.atualfin = 1
         and t.tipatualfin = 'I'
         and c.tipmov = 'V'
         and c.statusnota = 'L'
         and c.dtneg >= trunc(sysdate) - 365
         and p.codparcmatriz = p_codparc;
    
    elsif p_tipo = 'M' then
    
      select round(sum(c.vlrnota) / 4, 2) media
        into v_ticketvenda
        from tgfcab c, tgfpar p, tgftop t
       where c.codparc = p.codparc
         and c.codtipoper = t.codtipoper
         and c.dhtipoper = t.dhalter
         and upper(t.grupo) like '%VENDA%'
         and t.atualfin = 1
         and t.tipatualfin = 'I'
         and c.tipmov = 'V'
         and c.statusnota = 'L'
         and c.dtneg >= trunc(sysdate) - 120
         and p.codparcmatriz = p_codparc;
    
    else
      v_ticketvenda := 0;
    end if;
  
    return v_ticketvenda;
  
  exception
    when no_data_found then
      return 0;
    
  end ticketvenda;

  /****************************************************************************
  Autor: Ricardo Soares
  Data: 23/08/2017
  Objetivo: Identificar se a devolu��o � total ou parcial
  *****************************************************************************/
  function tipdev(pnunota number) return varchar2 is
    vtipdev varchar2(20);
  begin
    select case
             when round((qtddev - qtdvendida), 0) = 0 then
              'Devolu��o Total. '
             else
              'Devolu��o Parcial. '
           end
      into vtipdev
      from (select sum(qtdatendida) qtddev from tgfvar v where v.nunota = pnunota),
           (select sum(qtdneg) qtdvendida
              from tgfite i
             where i.nunota in (select nunotaorig from tgfvar v where v.nunota = pnunota)) t;
  
    return vtipdev;
  end tipdev;

  function tipmovtop(pcodtop number,
                     pdhtipoper date) return char is
    vtipmov char;
  begin
    select tipmov
      into vtipmov
      from tgftop
     where codtipoper = pcodtop
       and dhalter = pdhtipoper;
    return vtipmov;
  end tipmovtop;

  function tipovendamais(p_codparc int) return varchar2 is
    v_tipvenda varchar2(50);
  
  begin
    select tipvenda
      into v_tipvenda
      from (select count(*), c.codtipvenda || ' - ' || t.descrtipvenda tipvenda
              from tgfcab c, tgfpar p, tgftpv t
             where c.codparc = p.codparc
               and c.codtipvenda = t.codtipvenda
               and c.dhtipvenda = t.dhalter
               and c.tipmov = 'V'
               and c.statusnota = 'L'
               and p.codparcmatriz = p_codparc
               and c.dtneg >= trunc(sysdate) - 365
             group by c.codtipvenda || ' - ' || t.descrtipvenda
             order by 1 desc)
     where rownum = 1;
    return v_tipvenda;
  
  exception
    when no_data_found then
      return '*** Sem Informa��o ***';
    
  end tipovendamais;

  function totcontrato(p_numcontrato number,
                       p_tipo varchar2) return float is
    v_tot float;
  begin
    -----p_Tipo = 'O' - Pedido de Compra
    -----p_Tipo = 'C' - Compra
    -----p_Tipo = 'X' - Contrato
    -----p_Tipo = 'W' - Contrato Financeiro
    v_tot := 0;
  
    if p_tipo in ('C', 'O') then
    
      select sum(i.vlrtot - i.vlrdesc)
        into v_tot
        from tgfcab c
       inner join tgfite i
          on c.nunota = i.nunota
       where c.numcontrato = p_numcontrato
         and c.tipmov = p_tipo
         and c.codtipoper not in (144)
         and exists (select 1 from tgffin f where f.nunota = c.nunota)
         and c.statusnota = 'L';
    
    elsif p_tipo = 'X' then
    
      select nvl(sum(vlr.vlrcontrato), 0) into v_tot from vgfcontratovlr_sf vlr where vlr.numcontrato = p_numcontrato;
    
    elsif p_tipo = 'W' then
    
      select nvl(sum(cof.valor), 0)
        into v_tot
        from tcscon con
        left join ad_tcsconfin cof
          on con.numcontrato = cof.numcontrato
       where con.numcontrato <> 0
         and con.numcontrato = p_numcontrato
       group by con.numcontrato;
    
    end if;
  
    return v_tot;
  
  exception
    when others then
      v_tot := 0;
      return v_tot;
    
  end totcontrato;

  function cnpjcpf(pcgc_cpf varchar) return varchar2 is
    vcgc_cpf varchar2(20);
  begin
    if length(pcgc_cpf) = 14 then
      vcgc_cpf := regexp_replace(pcgc_cpf, '([0-9]{2})([0-9]{3})([0-9]{3})([0-9]{4})([0-9]{2})', '\1.\2.\3/\4-\5');
    elsif length(pcgc_cpf) = 9 then
      vcgc_cpf := regexp_replace(pcgc_cpf, '([0-9]{3})([0-9]{3})([0-9]{3})([0-9]{2})', '\1.\2.\3-\4');
    end if;
    return vcgc_cpf;
  end cnpjcpf;

  function get_cgccpf_parcemp(p_codparcemp number,
                              p_tipo char) return varchar2 is
    v_cgccpf varchar2(20);
  begin
    if p_tipo = 'P' then
      select cgc_cpf into v_cgccpf from tgfpar where codparc = p_codparcemp;
    elsif p_tipo = 'E' then
      select e.cgc into v_cgccpf from tsiemp e where codemp = p_codparcemp;
    end if;
  
    return v_cgccpf;
  end get_cgccpf_parcemp;

  function ultcodparc(p_codparc int) return number is
    v_ultcodparc number;
  begin
    begin
      <<inicio>>
      select max(codparc) + 1 into v_ultcodparc from tgfpar par;
    exception
      when no_data_found then
        commit;
        v_ultcodparc := 1;
    end;
    return v_ultcodparc;
  exception
    when no_data_found then
      return 0;
  end ultcodparc;

  function horasuteis(p_dataini timestamp,
                      p_datafin timestamp) return float is
    d1       date;
    d2       date;
    c1       int := 0;
    c2       int := 0;
    hr       float := 0;
    f        int := 0;
    hrsuteis float;
  begin
  
    d1 := p_dataini; -- To_Date(p_dataini, 'dd/mm/yyyy hh24:mi:ss');
    d2 := p_datafin; -- To_Date(p_datafin, 'dd/mm/yyyy hh24:mi:ss');
  
    hr := 24 * (d2 - d1);
  
    while d1 <= d2
    loop
    
      begin
        select count(*)
          into c1
          from tsifer fer
         where fer.recorrente = 'S'
           and fer.nacional in ('N', 'I')
           and to_char(d1, 'DD/MM') = to_char(fer.dtferiado, 'DD/MM');
      exception
        when others then
          c1 := 0;
      end;
    
      begin
        select count(*)
          into c2
          from tsifer fer
         where fer.nacional not in ('E', 'M')
           and d1 = fer.dtferiado;
      exception
        when others then
          c2 := 0;
      end;
    
      /* Se � fim de semana ou feriado nacional ou municipal */
      if to_char(d1, 'd') in (1, 7) or (c1 <> 0 or c2 <> 0) then
        f := f + 1;
      end if;
      d1 := d1 + 1;
    end loop;
  
    f        := f * 24;
    hrsuteis := hr - f;
  
    return abs(nvl(hrsuteis, 0));
  
  end horasuteis;

  function subtrai_hora_acidente(p_dtacid date,
                                 p_hrtrabalho varchar2) return varchar2 is
    result varchar2(4);
  begin
  
    result := lpad(to_number(replace(to_char(p_dtacid, 'hh24:mi'), ':', '')) - to_number(p_hrtrabalho), 4, 0);
  
    return result;
  exception
    when others then
      raise_application_error(-20105,
                              'Verifique se a data do acidente e o hor�rio de in�cio trabalho foram informados. <br><br>');
  end;

  function moeda(p_codmoeda int,
                 p_dtmoeda date) return float is
    v_vlrmoeda float;
  begin
    select nvl(c.cotacao, 0)
      into v_vlrmoeda
      from tsicot c
     where c.codmoeda = p_codmoeda
       and c.dtmov = (select max(dtmov)
                        from tsicot cot
                       where cot.codmoeda = c.codmoeda
                         and cot.dtmov <= p_dtmoeda);
  
    return v_vlrmoeda;
  end moeda;

  /****************************************************************************
  Autor: Gusttavo Lopes
  Data: 10/10/2017
  Objeto: Tipdev
  Objetivo: Identificar se a situa��o do pedido
    - Pendente
    - Confirmado
    - Fat. Parcial
    - Fat. Completo   
  *****************************************************************************/
  function sitpedido(pnunota number) return varchar2 is
    vsitpedido    varchar2(20);
    p_qtdneg      number;
    p_qtdentregue number;
    p_statusnota  char(1);
    p_tipmov      char(1);
  begin
    vsitpedido := 'Pendente';
  
    select sum(ite.qtdneg), sum(ite.qtdentregue), nvl(cab.statusnota, 'A'), tipmov
      into p_qtdneg, p_qtdentregue, p_statusnota, p_tipmov
      from tgfcab cab
     inner join tgfite ite
        on cab.nunota = ite.nunota
     where cab.nunota = pnunota
     group by cab.nunota, nvl(cab.statusnota, 'A'), tipmov;
  
    if p_statusnota = 'L' then
      vsitpedido := 'Confirmado';
    
      if p_qtdentregue > 0 and p_qtdentregue < p_qtdneg and p_tipmov = 'O' then
        vsitpedido := 'Fat. Parcial';
      elsif p_qtdentregue > 0 and p_qtdentregue = p_qtdneg and p_tipmov = 'O' then
        vsitpedido := 'Fat. Completo';
      end if;
    
    end if;
  
    return vsitpedido;
  end sitpedido;

  function data_w(p_data varchar2) return date is
    dia        char(2);
    mes        char(2);
    ano        char(4);
    v_chardate varchar2(10);
    v_data     date;
  begin
  
    ano := substr(p_data, 1, instr(p_data, '-', 1) - 1);
    mes := substr(p_data, 6, 2);
    dia := substr(p_data, 9, 2);
  
    v_chardate := dia || '/' || mes || '/' || ano;
  
    v_data := to_date(v_chardate, 'dd/mm/yyyy');
  
    return v_data;
  
  end data_w;

  function custo_produto(p_codprod in number,
                         p_codemp in number,
                         p_data in date,
                         p_tipo in number) return float is
    r tgfcus%rowtype;
  begin
  
    select nvl(cusrep, 0),
           nvl(cusger, 0),
           nvl(cusvariavel, 0),
           nvl(cussemicm, 0),
           nvl(cusmedicm, 0),
           nvl(entradasemicms, 0),
           nvl(entradacomicms, 0),
           nvl(cusmed, 0)
      into r.cusrep, r.cusger, r.cusvariavel, r.cussemicm, r.cusmedicm, r.entradasemicms, r.entradacomicms, r.cusmed
      from tgfcus c0
     where codprod = p_codprod
       and codemp = p_codemp
       and dtatual = (select max(dtatual)
                        from tgfcus c1
                       where c1.codemp = c0.codemp
                         and c1.codprod = c0.codprod
                         and c1.codlocal = c0.codlocal
                         and c1.dtatual <= p_data
                         and c1.dtatual > add_months(p_data, -12));
  
    if p_tipo = 0 then
      return(r.cusrep);
    elsif p_tipo = 1 then
      return(r.cusger);
    elsif p_tipo = 2 then
      return(r.cusvariavel);
    elsif p_tipo = 3 then
      return(r.cussemicm);
    elsif p_tipo = 4 then
      return(r.cusmedicm);
    elsif p_tipo = 5 then
      return(r.entradasemicms);
    elsif p_tipo = 6 then
      return(r.entradacomicms);
    elsif p_tipo = 7 then
      return r.cusmed;
    else
      return(0);
    end if;
  exception
    when no_data_found then
      return(0);
  end custo_produto;

  function custo_produto(p_codprod in number,
                         p_codemp in number,
                         p_codlocal in number,
                         p_data in date,
                         p_tipo in number) return float is
    r_cus tgfcus%rowtype;
  begin
    begin
      select *
        into r_cus
        from tgfcus
       where codprod = p_codprod
         and codemp = p_codemp
         and codlocal = p_codlocal
         and dtatual = (select max(dtatual)
                          from tgfcus cn
                         where codprod = p_codprod
                           and codemp = p_codemp
                           and codlocal = p_codlocal
                           and dtatual <= p_data);
    exception
      when others then
        return 0;
    end;
  
    if p_tipo = 0 then
      return r_cus.cusrep;
    elsif p_tipo = 1 then
      return r_cus.cusger;
    elsif p_tipo = 2 then
      return r_cus.cusvariavel;
    elsif p_tipo = 3 then
      return r_cus.cussemicm;
    elsif p_tipo = 4 then
      return r_cus.cusmedicm;
    elsif p_tipo = 5 then
      return r_cus.entradasemicms;
    elsif p_tipo = 6 then
      return r_cus.entradacomicms;
    elsif p_tipo = 7 then
      return r_cus.cusmed;
    else
      return 0;
    end if;
  exception
    when no_data_found then
      return 0;
  end custo_produto;

  function formatnativeoramsg(p_errmsg varchar2) return varchar2 is
    v_errmsgout varchar2(4000);
  begin
  
    v_errmsgout := substr(p_errmsg, 1, instr(p_errmsg, 'ORA-') - 1) ||
                   substr(p_errmsg, instr(p_errmsg, ':', 1) + 1, length(p_errmsg));
  
    --Dbms_Output.put_line(v_ErrmsgOut);
    return v_errmsgout;
  
  end;

  -- Created on 30/08/2018 by M.RANGEL 
  -- retorna a hora formatada como hora
  /*Function formata_valor_hora(p_valor Float) Return Varchar2 Is
    -- Local variables here
    i Float;
    h Varchar2(5);
    m Varchar2(100);
    d Varchar2(5);
  Begin
  
    i := p_valor;
  
    If Instr(i, ',') > 0 Then
      h := Nvl(Substr(i, 1, Instr(i, ',') - 1), '0');
      m := Substr(To_Char(i), Instr(To_Char(i), ',') + 1, Length(To_Char(i))) / 100;
      m := To_Char(Round(To_Number(m) * 60));
    Else
      h := To_Char(p_valor);
      m := '00';
    End If;
  
    h := Lpad(h, 2, '0');
    m := Lpad(m, 2, '0');
  
    d := h || ':' || m;
  
    Return d;
  
  End formata_valor_hora;*/

  function formata_valor_hora(p_valor float) return number is
    i float;
    h float;
    m float;
    d float;
  begin
  
    i := round(p_valor, 2);
  
    if instr(i, ',') > 0 then
    
      --h := Substr(i, 1, Instr(i, ','));
      h := trunc(i);
      --Dbms_Output.Put_Line(h);
    
      m := substr(i, instr(i, ',') + 1, 2);
    
      /* 
      If m < 10 Then 
        m := m * 10;
      End If;
      */
    
      m := (m / 100) * 60;
    
      if m < 1 then
        m := round(m * 10, 0);
      else
        m := round(m, 0);
      end if;
    
    else
      h := i;
      m := 0;
    end if;
  
    --d := h || '.' || Lpad(m, 2, 0);
    d := h + (m / 100);
    --Dbms_Output.put_Line( d );
  
    return d;
  
  end formata_valor_hora;

  function removerduplicidade(p_texto varchar2,
                              p_caracter char) return varchar2 is
    v_texto varchar2(4000);
  begin
  
    for r in (select distinct t.column_value as texto from table(fc_split_sf(p_texto, p_caracter)) t)
    loop
      if r.texto is not null then
        if v_texto is null then
          v_texto := r.texto;
        else
          v_texto := v_texto || p_caracter || r.texto;
        end if;
      end if;
    end loop;
  
    return v_texto;
  
  end removerduplicidade;

  function valorprodcontrato(p_numcontrato number,
                             p_codprod number) return float is
    v_vlrunit float;
    -- busca �ltimo valor do produto
  begin
    begin
      select valor
        into v_vlrunit
        from tcspre p
       where numcontrato = p_numcontrato
         and codprod = p_codprod
         and referencia = (select max(referencia)
                             from tcspre p2
                            where p.numcontrato = p2.numcontrato
                              and p.codprod = p2.codprod
                              and p2.referencia <= trunc(sysdate));
    exception
      when others then
        v_vlrunit := 0;
    end;
  
    return v_vlrunit;
  
  end valorprodcontrato;

  function nome_parceiro(p_codparc number,
                         p_tiponome varchar2) return varchar2 is
    v_nomeparceiro varchar2(4000);
  begin
    if p_tiponome = 'fantasia' then
      select nomeparc into v_nomeparceiro from tgfpar where codparc = p_codparc;
    else
      select razaosocial into v_nomeparceiro from tgfpar where codparc = p_codparc;
    end if;
  
    return v_nomeparceiro;
  
  exception
    when others then
      return 'Parceiro n�o encontrado.';
  end nome_parceiro;

  function aliq_piscofins(p_codprod number,
                          p_nomeimp varchar2,
                          p_top number) return float is
    v_grupo varchar2(100);
    v_aliq  float;
  
    type type_rec_prod is record(
      grupopis varchar2(100),
      grupocof varchar2(100),
      credmp   number);
  
    r type_rec_prod;
  
  begin
  
    select grupopis, grupocofins, credmp2
      into r.grupopis, r.grupocof, r.credmp
      from tgfpro p
     where p.codprod = p_codprod;
  
    if p_nomeimp = 'PIS' then
      v_grupo := r.grupopis;
    else
      v_grupo := r.grupocof;
    end if;
  
    begin
      select i.aliq
        into v_aliq
        from tgfife i
       where i.nomeimp = p_nomeimp
         and i.grupoimp = v_grupo
         and codtipoper = p_top;
    exception
      when no_data_found then
        select i.aliq
          into v_aliq
          from tgfife i
         where i.nomeimp = p_nomeimp
           and i.grupoimp = v_grupo
           and codtipoper = 0
           and entsai = 'S';
    end;
  
    return v_aliq;
  
  end aliq_piscofins;

  function ultimo_valor_contrato(p_numcontrato number,
                                 p_codprod number,
                                 p_data date) return float is
  
    v_vlrunit float;
  begin
  
    for preco in (
                  
                  select pre.numcontrato, pre.codprod, pre.codserv, pre.valor
                    from tcspre pre
                   where pre.numcontrato = p_numcontrato
                     and pre.codprod = p_codprod
                     and pre.referencia = (select max(referencia)
                                             from tcspre p2
                                            where pre.numcontrato = p2.numcontrato
                                              and pre.codprod = p2.codprod
                                              and referencia <= p_data)
                  
                  )
    loop
      v_vlrunit := nvl(v_vlrunit, 0) + preco.valor;
    end loop;
  
    return nvl(v_vlrunit, 0);
  
  end ultimo_valor_contrato;

  function codusuresp_cencus(p_codcencus number) return number is
    v_codusuresp number;
  begin
    select codusuresp into v_codusuresp from tsicus c where codcencus = p_codcencus;
  
    return v_codusuresp;
  
  exception
    when others then
      return 0;
  end codusuresp_cencus;

  function nuinstancia(p_nometabela varchar) return number is
    v_result number;
  begin
    select nuinstancia
      into v_result
      from tddins
     where nometab = p_nometabela
       and rownum = 1;
    return v_result;
  
  end nuinstancia;

  function cotacao_moeda(p_codmoeda number,
                         p_dtref date) return float is
    v_result float;
  begin
  
    select c.cotacao
      into v_result
      from tsicot c
     where c.codmoeda = p_codmoeda
       and c.dtmov = (select max(dtmov)
                        from tsicot t
                       where t.codmoeda = c.codmoeda
                         and c.dtmov <= p_dtref);
  
    select case
             when tipmoeda != 'V' then
              round(v_result / 100, 6)
             else
              v_result * 1
           end
      into v_result
      from tsimoe m
     where codmoeda = p_codmoeda;
  
    return v_result;
  
  exception
    when others then
      return 0;
  end;

  function cr_do_usuario(p_codusu number) return number is
    v_result number;
  begin
    select u.codcencuspad into v_result from tsiusu u where u.codusu = p_codusu;
  
    return v_result;
  
  exception
    when no_data_found then
      raise;
  end;

  function meses_entre_datas(p_dtini date,
                             p_dtfin date) return number is
    v_meses number;
  begin
    v_meses := round((p_dtfin - p_dtini) / 30);
    return v_meses;
  exception
    when others then
      return 0;
  end meses_entre_datas;

end ad_get;
/
