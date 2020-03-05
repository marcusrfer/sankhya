create or replace trigger ad_trg_cmp_tsftfv2_sf
 for insert or update or delete on ad_tsftfv
 compound trigger

 t ad_tsftfv%rowtype;
 p ad_tsfpfv2%rowtype;
 i int;

 /* 
 * autor: m. rangel
 * processo: programação frango vivo
 * objetivo: insert na tsfpfv, tratar os dados recebidos da rotina java, oriundos do avecom, 
             para inserir na tela de programação os dados gravados nessa tabela são oriundos 
             da aplicação java, e aqui são tratados antes de serem enviados para a tabela 
             da programação ad_tsfpfv2
 */

 before each row is
 begin
 
  t.numtfv     := :new.numtfv;
  t.dtdescarte := :new.dtdescarte;
  t.dhpega     := :new.dhpega;
  t.horapega   := :new.horapega;
  t.unidade    := to_char(ltrim(rtrim(:new.unidade)));
  t.nucleo     := to_char(ltrim(rtrim(:new.nucleo)));
  t.aviario    := to_char(ltrim(rtrim(:new.aviario)));
  t.idade      := :new.idade;
  t.sexo       := :new.sexo;
  t.peso       := :new.peso;
  t.localidade := ltrim(rtrim(:new.localidade));
  t.km         := :new.km;
  t.pega       := :new.pega;
  t.tecnico    := :new.tecnico;
  t.qtdpega    := :new.qtdpega;
  t.numlote    := :new.numlote;
  t.codlote    := :new.codlote;
 end before each row;

 after statement is
  v_qtdneg      float;
  v_divisor     number;
  v_qtdresidual float := 0;
  v_errmsg      varchar2(4000);
 begin
 
  if nvl(t.numtfv, 0) > 0 then
  
   /*dbms_output.put_line('dtdescarte = ' || t.dtdescarte);
   dbms_output.put_line('unidade = ' || t.unidade);
   dbms_output.put_line('nucleo = ' || t.nucleo);
   dbms_output.put_line('aviario = ' || t.aviario);
   dbms_output.put_line('IDADE = ' || t.idade);
   Dbms_Output.put_line('sexo = ' || t.sexo);
   --and v.localidade = t.localidade
   --and v.pega = t.pega
   --and v.tecnico = t.tecnico
   Dbms_Output.put_line('horapega = ' || t.horapega);
   Dbms_Output.put_line('qtdpega = ' || t.qtdpega);
   Dbms_Output.put_line('dhpega = ' || t.dhpega);
   --and v.km = t.km
   Dbms_Output.put_line('peso = ' || t.peso);*/
  
   /*Begin
     Select Count(*)
       Into i
       From ad_tsftfv v
      Where Trim(v.dtdescarte) = Trim(t.dtdescarte)
        And Trim(v.unidade) = Trim(t.unidade)
        And Trim(v.nucleo) = Trim(t.nucleo)
        And Trim(v.aviario) = Trim(t.aviario)
        And Trim(v.idade) = Trim(t.idade)
        And Trim(v.sexo) = Trim(t.sexo)
        And Trim(v.horapega) = Trim(t.horapega)
        And v.qtdpega = t.qtdpega
        And Trim(v.dhpega) = Trim(t.dhpega)
        And Trim(v.localidade) = Trim(t.localidade)
        And Trim(v.pega) = Trim(t.pega)
        And Trim(v.tecnico) = Trim(t.tecnico)
        And v.km = t.km
        And v.peso = t.peso;
   
     If i > 0 Then
       --Raise_Application_Error(-20105, 'Já existe! ' || t.unidade || ' - ' || t.aviario);
       Goto finalmetodo;
     End If;
     
   End;*/
  
   p.codusu     := stp_get_codusulogado;
   p.dhalter    := sysdate;
   p.numtfv     := t.numtfv;
   p.codune     := to_number(t.unidade);
   p.nucleo     := to_number(t.nucleo);
   p.codparc    := ad_pkg_pfv.get_codparc_integrado(to_char(t.unidade),
                                                    to_char(t.nucleo),
                                                    to_char(t.aviario));
   p.sexo       := t.sexo;
   p.distancia  := t.km;
   p.origpinto  := null;
   p.dtagend    := sysdate;
   p.status     := 'P';
   p.tecnico    := ltrim(rtrim(t.tecnico));
   p.pegador    := ltrim(rtrim(t.pega));
   p.dtdescarte := to_date(substr(t.dtdescarte, 9, 2) || '/' || substr(t.dtdescarte, 6, 2) || '/' ||
                           substr(t.dtdescarte, 1, 4),
                           'dd/mm/yyyy');
   p.horapega := case
                  when to_number(replace(substr(t.horapega, 12, 5), ':', '')) = 0 then
                   0001
                  else
                   to_number(replace(substr(t.horapega, 12, 5), ':', ''))
                 end;
  
   p.dhpega := to_date(substr(t.dhpega, 9, 2) || '/' || substr(t.dhpega, 6, 2) || '/' ||
                       substr(t.dhpega, 1, 4) || ' ' || substr(t.horapega, 12, 8),
                       'dd/mm/yyyy hh24:mi:ss');
  
   -- seleciona o produto de acordo com o sexo
   if t.sexo = 'M' then
    p.codprod := ad_pkg_pfv.v_codprodmacho;
    v_qtdneg  := ad_pkg_pfv.v_qtdmacho;
    v_divisor := ad_pkg_pfv.v_divmacho;
   elsif t.sexo = 'F' then
    p.codprod := ad_pkg_pfv.v_codprodfemea;
    v_qtdneg  := ad_pkg_pfv.v_qtdfemea;
    v_divisor := ad_pkg_pfv.v_divfemea;
   elsif t.sexo = 'X' then
    p.codprod := ad_pkg_pfv.v_codprodsexado;
    v_qtdneg  := ad_pkg_pfv.v_qtdmacho;
    v_divisor := ad_pkg_pfv.v_divmacho;
   end if;
  
   -- busca a cidade
   begin
    select codcid
      into p.codcid
      from tsicid
     where nomecid = t.localidade
       and rownum = 1;
   exception
    when others then
     p.codcid := 0;
   end;
  
   -- busca o laudo     
   begin
    select l.numlfv, l.dtalojamento - 1, l.dtalojamento - 1, l.dtalojamento + 14,
           l.gta || ' - ' || ad_get.get_cgccpf_parcemp(p.codparc, 'P'), l.dhpega, l.qtdaves,
           l.qtdmortes, (l.qtdaves - l.qtdmortes)
      into p.numlfv, p.dtmarek, p.dtbouba, p.dtgumboro, p.origpinto, p.dhpega, p.qtdpega,
           p.qtdmortes, p.qtdneg
      from ad_tsflfv l
     where l.codparc = p.codparc
       and l.codprod = p.codprod
       and to_date(l.dhpega, 'DD/MM/YYYY HH24:MI:SS') = to_date(p.dhpega, 'DD/MM/YYYY HH24:MI:SS');
   exception
    when others then
     null;
   end;
  
   -- insert das quantidades      
   begin
    if p.qtdpega is null then
     p.qtdpega := t.qtdpega;
    end if;
   
    if nvl(p.qtdpega, 0) > 0 then
     v_qtdresidual := p.qtdpega; -- se achou o lote, usa a qtd result do laudo
    else
     --p.qtdneg      := t.qtdpega; -- qtde que vai ser inserida
     v_qtdresidual := t.qtdpega; -- se não, usa a qtd da tabela base msm
    end if;
   
    p.nunota    := null;
    p.statusvei := null;
    p.qtdnegalt := v_qtdneg / v_divisor;
    p.qtdvolalt := v_divisor;
    p.qtdneg    := v_qtdneg;
    p.numlote   := to_number(t.numlote);
   
    -- verificação mais completa se o lançamento existe
    i := 0;
    select count(*)
      into i
      from ad_tsfpfv2 x
     where x.codune = p.codune
       and x.nucleo = to_number(p.nucleo)
       and x.codparc = p.codparc
       and x.codprod = p.codprod
       and trunc(x.dhpega) = trunc(p.dhpega)
       and x.horapega = p.horapega
          --And Nvl(x.numlfv, 0) = Nvl(p.numlfv, 0)
          --And x.qtdpega = p.qtdneg
       and x.status != 'C';
   
    if i > 0 then
     goto finalmetodo;
     --Raise_Application_Error(-20105, 'Lançamento duplicado');
    end if;
   
    -- loop que distribui as quantidades por linhas
    <<insere_agend>>
    loop
     exit when v_qtdresidual <= 0;
     v_qtdresidual := v_qtdresidual - p.qtdneg;
    
     begin
     
      stp_keygen_tgfnum('AD_TSFPFV2', 1, 'AD_TSFPFV2', 'NUPFV', 0, p.nupfv);
     
      insert into ad_tsfpfv2 values p;
     exception
      when dup_val_on_index then
       null;
       dbms_output.put_line('possível lançamento duplicado ' || p.nupfv);
      when others then
       v_errmsg := 'Erro ao inserir o lançamento na programação. Unidade ' || t.unidade ||
                   ' núcleo ' || t.nucleo || ' - ' || t.numtfv || '<br>' || sqlerrm;
       raise_application_error(-20105, ad_fnc_formataerro(v_errmsg));
     end;
    
     if v_qtdresidual < p.qtdneg then
      p.qtdneg := v_qtdresidual;
     end if;
    
    end loop insere_agend;
   end;
  
   <<finalmetodo>>
   null;
  
  end if;
 
 end after statement;

end;
/
