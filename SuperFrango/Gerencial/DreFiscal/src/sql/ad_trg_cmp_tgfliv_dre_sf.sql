create or replace trigger ad_trg_cmp_tgfliv_dre_sf
  for insert or update on tgfliv
  compound trigger

  /*
    Author: MARCUS.RANGEL 23/09/2019 09:50:10
    Processo: Fiscal / DRE
    Objetivo: Trigger utilizada para popular a tabela de antecipação de icms. 
              Para movimentações de saída, será verificada se a empresa
              da movimentação, qual a sua regra de parametrização e qual 
              calculo será realizado.
    
  */

  pro       tgfpro%rowtype;
  v_nuparam pls_integer;

  type dados_antecipacao is table of ad_antecpicm%rowtype;
  icm dados_antecipacao := dados_antecipacao();
  i   int;

  before each row is
    ufs         tsiufs%rowtype;
    v_cntcfo    pls_integer;
    v_cntgruicm pls_integer;
  begin
  
    --> se mov. saída
    if :new.entsai = 'S'
       and ad_pkg_var.isdebugging then
    
      --> busca o produto
      select ite.codprod
        into pro.codprod
        from tgfite ite
       where ite.nunota = :new.nunota
         and ite.sequencia = :new.sequencia;
    
      select * into pro from tgfpro where codprod = pro.codprod;
    
      --> busca a uf da empresa
      select * into ufs from tsiufs u where u.coduf = ad_get.ufparcemp(:new.codemp, 'E');
    
      --> determina qual regra de parâmetros será usada  
    
      --- uf da empresa
      if (ufs.uf = 'PA') then
        v_nuparam := 8;
      else
        v_nuparam := 0;
      end if;
    
      select count(*)
        into v_cntgruicm
        from ad_adrelparmgruicms rg
       where rg.grupoicms = pro.grupoicms
         and rg.nurelparm = v_nuparam;
    
      --> se o lançamento atende a regra da cfop e do grupo de icms da tela de parametrização
      if v_cntgruicm > 0 then
        icm.extend;
        i := icm.last;
        stp_keygen_tgfnum('AD_ANTECPICM', 1, 'AD_ANTECPICM', 'NUANTECIP', 0, icm(i).nuantecip);
        icm(i).dtref := trunc(:new.dhmov, 'fmmm');
        icm(i).codemp := :new.codemp;
        icm(i).nunota := :new.nunota;
        icm(i).sequencia := :new.sequencia;
        icm(i).dhmov := :new.dhmov;
        icm(i).dtdoc := :new.dtdoc;
        icm(i).vlrctb := :new.vlrctb;
        icm(i).baseicms := :new.baseicms;
        icm(i).aliqicms := :new.aliqicms;
        icm(i).vlricms := :new.vlricms;
        icm(i).vlrantecip := 0;
        icm(i).vlrantecipcb := 0;
        icm(i).coduf := ufs.coduf;
      
      end if;
    
    end if;
  end before each row;

  after statement is
  begin
    if icm.count > 0 then
      for l in icm.first .. icm.last
      loop
      
        -- calculo da antecipação do icms
        select liv.baseicms * ad_fnc_get_param_fiscal_sf(v_nuparam, icm(l).dhmov, 'PERCANT')
          into icm(l).vlrantecip
          from tgfliv liv
          join tgfite ite
            on ite.codemp = liv.codemp
           and ite.nunota = liv.nunota
           and ite.sequencia = liv.sequencia
          join tgfpro p
            on p.codprod = ite.codprod
         where ite.codprod = pro.codprod
           and exists (select cf.codcfo
                  from ad_relparmcfop cf
                 where cf.codcfo = liv.codcfo
                   and cf.nurelparm = v_nuparam)
           and exists (select 1
                  from ad_adrelparmgruicms rg
                 where rg.grupoicms = pro.grupoicms
                   and rg.nurelparm = v_nuparam)
           and liv.dhmov = (select max(lv.dhmov) from tgfliv lv where lv.dhmov <= icm(l).dhmov)
           and rownum = 1;
      
      end loop;
    
      forall x in icm.first .. icm.last
        merge into ad_antecpicm a
        using (select icm(x).codemp codemp,icm(x).nunota nunota,icm(x).sequencia sequencia from dual) i
        on (a.nunota = i.nunota and a.sequencia = i.sequencia and a.codemp = i.codemp)
        when not matched then
          insert values icm (x)
        when matched then
          update
             set vlrantecip   = icm(x).vlrantecip,
                 vlrantecipcb = icm(x).vlrantecipcb;
    
    end if;
  end after statement;

end;
/
