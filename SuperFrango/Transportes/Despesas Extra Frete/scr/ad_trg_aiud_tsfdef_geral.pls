create or replace trigger ad_trg_aiud_tsfdef_geral
  after insert or update or delete on ad_tsfdef
  for each row
declare
  vnudefp number;
  def     ad_tsfdef %rowtype;
begin
  /*
  Autor: Marcus Rangel
  Processo: Despesas Extras de Frete
  Objetivo: Inserir os parceiros da ordem de carga selecionda na tela de despesas extras de frete
  */
  if inserting then
  
    def.nudef      := :new.nudef;
    def.ordemcarga := :new.ordemcarga;
  
    begin
      select nvl(max(nudefp), 0) + 1
        into vnudefp
        from ad_tsfdefp p
       where p.nudef = def.nudef;
    exception
      when others then
        raise;
    end;
  
    for p in (select distinct c.codparc, p.codcid, p.codvend
                from tgfcab c, tgfpar p
               where c.ordemcarga = def.ordemcarga
                 and c.codparc = p.codparc)
    loop
      begin
        insert into ad_tsfdefp
          (nudef, nudefp, codparc, codcid, codvend)
        values
          (def.nudef, vnudefp, p.codparc, p.codcid, p.codvend);
      
        vnudefp := vnudefp + 1;
      exception
        when others then
          raise;
      end;
    end loop;
  end if;
end;
/
