create or replace trigger ad_trg_aiud_tblcmf_sf
 after insert or update or delete on sankhya.ad_tblcmf
 for each row
declare
 v ad_tblcmf%rowtype;
begin

 if deleting then
 
  v.nometaborig := :old.nometaborig;
  v.nometabdest := :old.nometabdest;
  v.nuchaveorig := :old.nuchaveorig;
  v.nuchavedest := :old.nuchavedest;
 
  /* Ao excluir o pedido de compras referente ao apontamento, marca os apontamentos como pendentes*/
  if v.nometaborig = 'AD_TSFAHMC' then
   begin
    update ad_tsfahmapd a
       set a.dtfecha  = null,
           a.faturado = 'N',
           a.nunota   = null --, a.origem = 0
     where a.nuapont = v.nuchaveorig
       and a.nunota = v.nuchavedest;
   exception
    when others then
     raise;
   end;
  end if;
 
  if v.nometaborig = 'TCSCON' then
   declare
    v_parcela number;
   begin
   
    select c.parcelaatual into v_parcela from tcscon c where numcontrato = v.nuchaveorig;
   
    if v_parcela <> 0 or v_parcela is not null then
     begin
      update tcscon
         set parcelaatual = parcelaatual - 1
       where numcontrato = v.nuchaveorig;
     exception
      when others then
       raise;
     end;
    end if;
   end;
  end if;
 
  if v.nometaborig = 'TCSCON' then
   begin
    update ad_tsfdfc d
       set d.compensado = 'N',
           nunota       = null
     where compensado = 'S'
       and numcontrato = v.nuchaveorig;
   exception
    when others then
     insert into tsilog
      (codusu, dhevento, descricao, computador, sequencia)
     values
      (stp_get_codusulogado(), sysdate,
       'Erro ao desfazer a compensação do desconto no contrato.', ad_get.nomemaquina(),
       null);
   end;
  end if;
 
 -- despesas extras de frete
  if v.nometaborig = 'AD_TSFDEF' then
   begin
    update ad_tsfdef d set d.status = 'L' where d.nudef = v.nuchaveorig;
   exception
    when others then
     raise;
   end;
  end if;
 
 -- fechamento de comissão do integrado frango vivo
  if v.nometaborig = 'AD_TSFFCI' and v.nometabdest = 'TGFCAB' then
   begin
    delete from ad_tsffcinf nf where nf.nunota = v.nuchaveorig;
   exception
    when others then
     raise;
   end;
  end if;
 
 end if;

end ad_trg_aiud_tblcmf_sf;
/
