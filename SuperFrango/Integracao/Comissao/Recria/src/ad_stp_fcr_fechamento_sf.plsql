create or replace procedure ad_stp_fcr_fechamento_sf(p_codusu    number,
                                                     p_idsessao  varchar2,
                                                     p_qtdlinhas number,
                                                     p_mensagem  out varchar2) as
 p_dtvenc date;
 --p_pontuacao number;
 --p_qtdmortransp  number;
 --p_qtdenvlab     number;
 --p_qtdmortgranja number;
 --p_qtdavesvda    number;
 --p_qtdaveselim   number;

 fcr ad_tsffcr%rowtype;
 adt ad_tsffcradt%rowtype;

 cd int := 5;

begin

 /*
 * Autor: M. Rangel
 * Processo: Fechamento de comissão do integrado recria
 * Objetivo: Realizar o fechamento do lote, botão de ação homônima na tela.
             O mesmo só pode ser realizado quando apenas a última parcela estiver
             pendente de geração.
 */

 if p_qtdlinhas > 1 then
  p_mensagem := 'Selecione apenas um registro!';
  return;
 end if;

 fcr.codcencus := act_int_field(p_idsessao, 1, 'CODCENCUS');
 fcr.codparc   := act_int_field(p_idsessao, 1, 'CODPARC');
 fcr.numlote   := act_int_field(p_idsessao, 1, 'NUMLOTE');
 fcr.sexo      := act_txt_field(p_idsessao, 1, 'SEXO');

 select *
   into fcr
   from ad_tsffcr f
  where 1 = 1
    and codcencus = fcr.codcencus
    and codparc = fcr.codparc
    and numlote = fcr.numlote
    and f.sexo = fcr.sexo;

 p_dtvenc          := act_dta_param(p_idsessao, 'DTVENC');
 fcr.pontuacao     := act_dec_param(p_idsessao, 'PONTUACAO');
 fcr.qtdmortransp  := act_int_param(p_idsessao, 'QTDMORTRANSP');
 fcr.qtdenvlab     := act_int_param(p_idsessao, 'QTDENVLAB');
 fcr.qtdmortgranja := act_int_param(p_idsessao, 'QTDMORTGRANJA');
 fcr.qtdavesvda    := act_int_param(p_idsessao, 'QTDAVESVDA');
 fcr.qtdaveselim   := act_int_param(p_idsessao, 'QTDAVESELIM');

 begin
  select *
    into adt
    from ad_tsffcradt a
   where 1 = 1
     and a.codcencus = fcr.codcencus
     and a.codparc = fcr.codparc
     and a.numlote = fcr.numlote
     and a.sexo = fcr.sexo
        --and a.desdobramento != fcr.qtdmeses
     and a.nuacerto is null;
 exception
  when no_data_found then
   p_mensagem := 'A última parcela tem que estar pendente de adiantamento.<br>' ||
                 'Cancelando operação!';
   return;
  when too_many_rows then
   p_mensagem := 'É necessário que somente a última parcela esteja pendente.<br>' ||
                 'Cancelando a operação!';
   return;
  when others then
   raise;
 end;

 --get valores da tabela
 ad_stp_fcp_getreftabela_sf(fcr.codcencus, adt.dtref, fcr.sexo, fcr.codtabreal, fcr.dreftabreal,
                            fcr.vlrcomfixa, fcr.vlrcomatrat, fcr.vlrcomclist, fcr.vlrunitprev,
                            fcr.vlrcomave);

 -- Created on 02/03/2021 by MARCUS.RANGEL 
 --- tratativa para quando a tabela de preço for atualizada no período da recria
 --- calcula a média dos valores individualmente para aplicar a proporção entre os períodos
 if fcr.dreftabprev < fcr.dreftabreal then
 
  declare
   old ad_tsffcr%rowtype;
  
   m1 int;
   m2 int;
   v1 float;
   v2 float;
  begin
   m1 := round((fcr.dreftabreal - fcr.dtaloj) / 30);
   m2 := fcr.qtdmeses - m1;
  
   ad_stp_fcp_getreftabela_sf(fcr.codcencus, fcr.dtaloj, fcr.sexo, old.codtabreal, old.dreftabreal,
                              old.vlrcomfixa, old.vlrcomatrat, old.vlrcomclist, old.vlrunitprev,
                              old.vlrcomave);
  
   v1             := old.vlrcomfixa * m1;
   v2             := fcr.vlrcomfixa * m2;
   fcr.vlrcomfixa := round((v1 + v2) / fcr.qtdmeses, cd);
  
   v1              := old.vlrcomatrat * m1;
   v2              := fcr.vlrcomatrat * m2;
   fcr.vlrcomatrat := round((v1 + v2) / fcr.qtdmeses, cd);
  
   v1              := old.vlrcomclist * m1;
   v2              := fcr.vlrcomclist * m2;
   fcr.vlrcomclist := round((v1 + v2) / fcr.qtdmeses, cd);
  
   fcr.vlrunitprev := fcr.vlrcomfixa + fcr.vlrcomatrat + fcr.vlrcomclist;
  end;
 
 end if;

 -- NoFormat Start
 dbms_output.put_line(
  'Valores da Tabela: ' || chr(13) || 
  'Com. fixa: ' || fcr.vlrcomfixa ||chr(13) || 
  'Com. Bônus: ' || fcr.vlrcomatrat || chr(13) || 
  'Com. C-List: ' ||fcr.vlrcomclist || chr(13) || 
  'Vlr Unit: ' || fcr.vlrunitprev
 );
 -- NoFormat End

 -- atualiza dados no formulario principal
 begin
  fcr.totremave     := round(fcr.vlrcomfixa + fcr.vlrcomatrat +
                             (fcr.vlrcomclist * (fcr.pontuacao / 100)), cd);
  fcr.qtdavesliq    := (fcr.qtdaves - fcr.qtdmortransp - fcr.qtdenvlab);
  fcr.qtdmortperm   := round(fcr.qtdavesliq * (fcr.percmortprev / 100));
  fcr.totavestransf := fcr.qtdavesliq - (fcr.qtdmortgranja + fcr.qtdavesvda + fcr.qtdaveselim);
 
  -- se a qtd de mortes ultrapassar o estimado, realiza demais deduções
  if fcr.qtdmortgranja > fcr.qtdmortperm then
   fcr.qtdavesliq := fcr.qtdavesliq + (fcr.qtdmortperm - fcr.qtdmortgranja);
  end if;
 
  fcr.vlrtotreal := round(fcr.totremave * fcr.qtdavesliq, 2);
  --fcr.vlrtotreal := round(fcr.totremmes * fcr.qtdavesliq * fcr.qtdmeses, 2);
  fcr.totremmes := round(fcr.totremave / fcr.qtdmeses, cd);
  fcr. vlrcomclist := round(fcr.vlrcomclist * (fcr.pontuacao / 100), cd);
 
  -- NoFormat Start
  	dbms_output.put_line(
  	'Valores >>>>>'||chr(13)|| 
  	'Pontuação: '||  fcr.pontuacao ||chr(13)|| 
    'Total Remuneração por Ave: '||fcr.totremave ||chr(13)|| 
    'Vlr. Remuneração: '||   fcr.totremmes ||chr(13)|| 
    'Qtd. Aves p/ Remuneração: '|| fcr.qtdavesliq ||chr(13)|| 
    'Mortes permitidas: '|| fcr.qtdmortperm ||chr(13)|| 
    'Mortes granja: '||fcr.qtdmortgranja ||chr(13)|| 
    'Vendidas: '||fcr.qtdavesvda ||chr(13)|| 
    'Eliminadas: '||fcr.qtdaveselim ||chr(13)|| 
    'Env. Lab.: '||fcr.qtdenvlab ||chr(13)|| 
    'Mortes Transp.:'|| fcr.qtdmortransp ||chr(13)|| 
    'Transferidas: '||fcr.totavestransf ||chr(13)|| 
    'Vlr. Total Realizado: '||fcr.vlrtotreal ||chr(13)|| 
    'Vlr. Médio Mensal Real: '||round(fcr.vlrtotreal / fcr.qtdmeses, 2) ||chr(13)|| 
    'Vlr. Adiant.: '||round(fcr.vlrtotreal - fcr.vlrtotadiant, 2) ||chr(13)|| 
    'Saldo: '||fcr.vlrtotreal - fcr.vlrtotadiant
  	);
  	-- NoFormat End
 
  stp_set_atualizando('S');
  begin
   update ad_tsffcr r
      set r.codtabreal    = fcr.codtabreal,
          r.dreftabreal   = fcr.dreftabreal,
          r.vlrcomfixa    = fcr.vlrcomfixa,
          r.vlrcomatrat   = fcr.vlrcomatrat,
          r.vlrcomave     = fcr.vlrcomave,
          r.pontuacao     = fcr.pontuacao,
          r.vlrcomclist   = fcr.vlrcomclist,
          r.totremave     = fcr.totremave,
          r.totremmes     = fcr.totremmes,
          r.qtdavesliq    = fcr.qtdavesliq,
          r.qtdmortperm   = fcr.qtdmortperm,
          r.qtdmortgranja = fcr.qtdmortgranja,
          r.qtdavesvda    = fcr.qtdavesvda,
          r.qtdaveselim   = fcr.qtdaveselim,
          r.qtdenvlab     = fcr.qtdenvlab,
          r.qtdmortransp  = fcr.qtdmortransp,
          r.totavestransf = fcr.totavestransf,
          r.vlrtotreal    = fcr.vlrtotreal,
          r.vlrmedreal    = round(fcr.vlrtotreal / fcr.qtdmeses, 2),
          r.saldo         = fcr.vlrtotreal - fcr.vlrtotadiant,
          r.statuslote    = 'F',
          r.codusualt     = p_codusu,
          r.dhalter       = sysdate
    where r.codcencus = fcr.codcencus
      and r.codparc = fcr.codparc
      and r.numlote = fcr.numlote
      and r.sexo = fcr.sexo;
  exception
   when others then
    stp_set_atualizando('N');
    p_mensagem := 'Erro ao atualizar o formulário principal. ' || sqlerrm;
    return;
  end;
  stp_set_atualizando('N');
 
 end;

 <<valida_venc>>
 begin
  if p_dtvenc is not null and to_char(p_dtvenc, 'd') in (1, 7) then
   p_dtvenc := p_dtvenc + 1;
   goto valida_venc;
  end if;
 end;

 begin
  update ad_tsffcradt a
     set a.vlradiant = round(fcr.vlrtotreal - fcr.vlrtotadiant, 2),
         a.dtvenc    = nvl(p_dtvenc, a.dtvenc)
   where a.codcencus = fcr.codcencus
     and a.codparc = fcr.codparc
     and a.numlote = fcr.numlote
     and a.sexo = fcr.sexo
     and a.desdobramento = fcr.qtdmeses;
 exception
  when others then
   p_mensagem := 'Erro ao atualizar os dados do adiantamento. ' || sqlerrm;
   return;
 end;

 p_mensagem := 'Lote de Comissão fechado com sucesso!!!';
 --|| fcr.totremmes || ' * ' || fcr.qtdavesliq || ' * ' ||fcr.qtdmeses;

end;
/
