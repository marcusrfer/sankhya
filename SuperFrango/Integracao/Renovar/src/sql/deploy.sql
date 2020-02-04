ALTER TABLE AD_ADTSSALGTT disable CONSTRAINT PK_AD_ADTSSALGTT;
/

delete from ad_adtssaconfcr c
 where codcencus = 991900000
   and not exists (select f.codigo
          from ad_adtssaconf f
         where nvl(f.renovar, 'N') = 'S'
           and f.codigo = c.codigo);

/


begin

 merge into ad_cabsolcpalibcr c
 using (select 991900000 as cr from dual) d
 on (d.cr = c.codcencus)
 when not matched then
  insert values (991900000, 'NÃO', 0);

 if sql%rowcount > 0 then
  insert into ad_itesolcpalibcr
   (codcencus, codusu, vlrfinal, diretor, ativo, aprova)
  values
   (991900000, 114, null, null, 'SIM', 'S');
 end if;
end;
/



declare 
  v_nubtn number;
begin
 stp_keygen_tgfnum(p_arquivo => 'TSIBTA',
                   p_codemp  => 1,
                   p_tabela  => 'TSIBTA',
                   p_campo   => 'IDBTNACAO',
                   p_dsync   => 0,
                   p_ultcod  => v_nubtn);

 insert into tsibta (IDBTNACAO, NOMEINSTANCIA, RESOURCEID, DESCRICAO, TIPO, CONFIG, CODMODULO, ORDEM, CONTROLAACESSO)
values (v_nubtn, 'ADTSSACAB', '!br.com.sankhya.menu.adicional.ADTSSACAB__1545395619194.1', 'Reabre Solicitação', 'SP', '<actionConfig>
            <dbCall name="STP_ADTSSACAB_CAN_SF" refreshType="SEL" txManual="false" rootEntity="ADTSSACAB" />
          </actionConfig>', null, 3, 'N');

--delete from tsibta where IDBTNACAO = 815;

end;
/

declare 
  v_nubtn number;
begin
 stp_keygen_tgfnum(p_arquivo => 'TSIBTA',
                   p_codemp  => 1,
                   p_tabela  => 'TSIBTA',
                   p_campo   => 'IDBTNACAO',
                   p_dsync   => 0,
                   p_ultcod  => v_nubtn);

insert into tsibta (IDBTNACAO, NOMEINSTANCIA, RESOURCEID, DESCRICAO, TIPO, CONFIG, CODMODULO, ORDEM, CONTROLAACESSO)
values (v_nubtn, 'ADTSSACAB', '!br.com.sankhya.menu.adicional.ADTSSACAB__1545395619194.1', 'Confirma / Sol. Aprovação', 'SP', '<actionConfig>
  <dbCall name="AD_STP_ADTSSA_SOLAPROV_SF" refreshType="SEL" txManual="false" rootEntity="ADTSSACAB"/>
</actionConfig>', null, 2, 'N');


--delete from tsibta where IDBTNACAO = 1223;'

end;

/

declare 
  v_nubtn number;
begin
 stp_keygen_tgfnum(p_arquivo => 'TSIBTA',
                   p_codemp  => 1,
                   p_tabela  => 'TSIBTA',
                   p_campo   => 'IDBTNACAO',
                   p_dsync   => 0,
                   p_ultcod  => v_nubtn);

insert into tsibta (IDBTNACAO, NOMEINSTANCIA, RESOURCEID, DESCRICAO, TIPO, CONFIG, CODMODULO, ORDEM, CONTROLAACESSO)
values (v_nubtn, 'ADTSSACAB', null, 'Gerar Parcelas', 'SP', '<actionConfig>
  <dbCall name="AD_STP_ADTSSA_GERAPARCELA_SF" refreshType="NONE" txManual="false" rootEntity="ADTSSACAB"/>
</actionConfig>', null, 1, 'N');

--delete from tsibta where IDBTNACAO = 1220;

end;
/

 Update tsievp e
  Set e.ativo = 'N' 
 Where e.nomeinstancia Like ('%ADTSSA%') ;

 /


 
