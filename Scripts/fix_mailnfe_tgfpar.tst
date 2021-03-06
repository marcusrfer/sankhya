PL/SQL Developer Test script 3.0
43
declare
  type rec_parceiro is record(
    codparc int,
    mail    tgfpar.emailnfe%type);

  cursor cur_parceiros is(
    select codparc, emailnfe
      from tgfpar p
     where 1 = 1
       and regexp_like(emailnfe, '[[:upper:]]')
       and ativo = 'S'
       and cliente = 'S'
    --and exists (select 1
    --from tgfcab c
    --where c.codparc = p.codparc
    --and c.codemp = 1
    --and dtneg >= '01/01/2019')
     );

  type tab_parceiro is table of rec_parceiro;
  t tab_parceiro := tab_parceiro();

  total int := 0;

begin
  stp_set_atualizando('S');
  open cur_parceiros;
  loop
    fetch cur_parceiros bulk collect
      into t limit 1000;
  
    forall x in t.first .. t.last
      update tgfpar set emailnfe = lower(t(x).mail) where codparc = t(x).codparc;
    total := total + sql%rowcount;
    dbms_output.put_line(sql%rowcount);
    exit when t.count = 0;
  end loop;
  close cur_parceiros;
  stp_set_atualizando('N');

  dbms_output.put_line('Total: ' || total);

end;
0
0
