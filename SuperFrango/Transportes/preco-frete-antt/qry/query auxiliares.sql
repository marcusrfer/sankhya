select * from ad_tsfctt;

alter table tgfvei add tipotransp2 varchar2(100);

update tgfvei
   set ad_tipotransp = tipotransp2
 where codveiculo > 0
   and ativo = 'S'
   and ad_tipotransp is not null;

update tgfvei
   set ad_codtiptransp =
       (select tipotransp from ad_tsfctt)
 where codveiculo > 0
   and ativo = 'S'
   and ad_tipotransp is not null;

update tgfvei v
   set v.ad_codtiptransp =
       (select c.codtiptransp from ad_tsfctt c where c.descrtiptransp = trim(v.ad_tipotransp))
 where codveiculo > 0
   and ativo = 'S'
   and ad_tipotransp is not null;

update ad_tsfofo o
   set o.codtiptransp =
       (select c.codtiptransp from ad_tsfctt c where c.descrtiptransp = trim(o.tipooperacao))
 where o.tipooperacao is not null;

select ad_tipotransp, ad_codtiptransp, t.codtipcarga
  from tgfvei v
  join ad_tsfctt t
    on t.codtiptransp = v.ad_codtiptransp
  join ad_tsfctg g
    on g.codtipcarga = t.codtipcarga
 where codveiculo > 0
   and ativo = 'S'
   and ad_tipotransp is not null
   and ad_codtiptransp is not null
   and nvl(t.codtipcarga, 0) > 0
   and nvl(t.antt, 'N') = 'S';

select * from tddopc where nucampo =;

select nucampo, nometab from tddcam c where c.nomecampo = 'AD_TIPOTRANSP';

select nucampo, o.valor, o.opcao, o.padrao, o.controle, o.ordem
  from tddopc o
 where nucampo = 10000006198;

create table ad_tsfctt_tmp as
  select * from ad_tsfctt;

delete from ad_tsfctt;

insert into ad_tsfctg
  select t.tipocarga, t.descrtipcarga from ad_tsfctt_tmp t;

insert into ad_tsfctt
  select t.tipotransp, t.descrtipotransp, null, t.antt from ad_tsfctt_tmp t;

select distinct tipocarga from ad_tsfvfo order by 1;
select * from ad_tsfvfo where codtipcarga is null;

update ad_tsfvfo
   set codtipcarga = case
                       when tipocarga = 'C' then
                        1
                       when tipocarga = 'CG' then
                        2
                       when tipocarga = 'CGP' then
                        3
                       when tipocarga = 'F' then
                        4
                       when tipocarga = 'GL' then
                        5
                       when tipocarga = 'GS' then
                        6
                       when tipocarga = 'NG' then
                        7
                       when tipocarga = 'PC' then
                        8
                       when tipocarga = 'PCG' then
                        9
                       when tipocarga = 'PF' then
                        10
                       when tipocarga = 'PGL' then
                        11
                       when tipocarga = 'PGS' then
                        12
                     end;

select t.* from ad_tsfrfc t where 1 = 1;
