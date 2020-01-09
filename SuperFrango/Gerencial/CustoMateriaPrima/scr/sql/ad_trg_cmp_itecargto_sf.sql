create or replace trigger ad_trg_cmp_itecargto_sf
 for insert or update or delete on ad_itecargto
 compound trigger

 r_ite ad_itecargto%rowtype;

 /*
 * Dt. Criação: 01/04/2019
 * Autor: M. Rangel 
 * Processo: Custo Materia Prima    
 * Objetivo: Buscar as informa¿¿es de n¿mero Único da remessa e n¿mero do contrato de compras. 
 */
 before each row is
 begin
 
  if stp_get_atualizando then
   goto end_of_line;
  end if;
 
  if updating then
  
   if nvl(:new.codprod, :old.codprod) = 10001 and :new.numnota is not null and
      nvl(:new.numcontrato, 0) = 0 then
    r_ite.sequencia := :new.sequencia;
    r_ite.ordem     := :new.ordem;
    r_ite.codparc   := :new.codparc;
    r_ite.codprod   := :new.codprod;
    r_ite.numnota   := :new.numnota;
   end if;
  
  end if;
 
  <<end_of_line>>
  null;
 end before each row;

 after statement is
 begin
 
  if r_ite.sequencia is not null then
  
   begin
    variaveis_pkg.v_atualizando := true;
    update ad_itecargto
       set nunota      = ad_pkg_cmp.get_nunota(r_ite.numnota, r_ite.codparc, r_ite.codprod),
           numcontrato = ad_pkg_cmp.get_nrocontratocpa(r_ite.sequencia,
                                                       r_ite.ordem,
                                                       r_ite.numnota,
                                                       r_ite.codparc,
                                                       r_ite.codprod)
     where sequencia = r_ite.sequencia
       and ordem = r_ite.ordem;
    variaveis_pkg.v_atualizando := false;
   exception
    when others then
     dbms_output.put_line('Erro ao preencher o nunota o numcontrato do carregamento. ' || sqlerrm);
   end;
  
  end if;
 end after statement;
end;
/
