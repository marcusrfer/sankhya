create or replace procedure stp_adtssacab_can_sf(p_codusu    number,
                                                 p_idsessao  varchar2,
                                                 p_qtdlinhas number,
                                                 p_mensagem  out varchar2) as
  field_nunico number;

  r_cab   ad_adtssacab%rowtype;
  v_count int;

  v_incluir  boolean;
  v_titulo   varchar(40);
  v_mensagem varchar(200);
  v_msgerro  varchar2(4000);

begin

  stp_set_atualizando('S');
  ad_pkg_var.permite_update := true;

  /**************************
  Autor:     Ricardo Soares de Oliveira
  Criado em: 31/07/2017
  Objetivo:  Cancelar um adiantamento, desde que a despesa não tenha sido baixada ou enviada para o banco na rotina "Adiantamento / Empréstimo SSA"
  
  Autor:     Ricardo Soares de Oliveira
  Criado em: 18/06/2018
  Objetivo:  Ajustei a procedure para efetuar as alterações a partir da Ad_Set.Del_Adiantamento e com isso centralizar os processos das telas Rateio de Valores por Parceiro, Adiantamento / Empréstimo SSA e Despesas integrado
  **************************/
  if p_qtdlinhas > 1 then
    raise_application_error(-20101,
                            fc_formatahtml_sf('Selecione apenas um registro por vez', null, null));
  end if;

  -- A variável "I" representa o registro corrente.
  field_nunico := act_int_field(p_idsessao, 1, 'NUNICO');

  select c.* into r_cab from ad_adtssacab c where c.nunico = field_nunico;

  /* If r_Cab.Situacao In ('E') Then
     Raise_Application_Error(-20101,
                             Fc_Formatahtml_Sf('Registro já se encontra com situação <i>Elaborando</i>', Null, Null));
  End If;*/

  v_titulo   := 'Atenção';
  v_mensagem := 'Deseja cancelar a solicitação?\nA situação voltará para <i>Elaborando</i>';
  v_incluir  := act_confirmar(v_titulo, v_mensagem, p_idsessao, 1);

  ad_set.del_adiantamento(p_nuacerto => r_cab.nuacerto, p_tabela => 'AD_ADTSSACAB',
                          p_chavetabela => field_nunico, p_mensagem => v_msgerro);

  /*** 
  Por Ricardo em 18/06/2018, as ações abaixo foram substituidas pela execução do pacote Ad_Set.Del_Adiantamento afim de centralizar as ações e facilitar ajustes futuros
  
  Delete From Ad_Tblcmf t Where t.Nometaborig = 'AD_ADTSSACAB' And t.Nuchaveorig = Field_Nunico;
  Delete From Tsilib l Where l.Nuchave = Field_Nunico And l.Tabela = 'AD_ADTSSACAB';
  Delete From Tgffre Where Nuacerto = r_Cab.Nuacerto;
  For r In (Select Nufin From Ad_Adtssapar l Where l.Nunico = Field_Nunico)
  Loop
     Select Count(*) Into v_Count From Tgffin f Where f.Nufin = r.Nufin And (f.Dhbaixa Is Not Null Or f.Numremessa Is Not Null);
     If v_Count > 0 Then Raise_Application_Error(-20101, Fc_Formatahtml_Sf('Registro baixado ou enviado para banco, entre em contato com departamento financeiro', Null, Null));
     Else Delete From Tgffin f Where f.Nufin = r.Nufin;
     End If;
  End Loop;
  
  ***/

  if v_msgerro is not null then
    raise_application_error(-20191, fc_formatahtml('Ação Cancelada', v_msgerro || '. ', null));
  end if;

  --m.rangel - 6/3/20 - desfazer o financeiro dos juros
  begin
    delete from tgffin where numdupl = r_cab.nuacerto;
  exception
    when others then
      p_mensagem := 'Erro ao excluir os juros do Renovar. ' || sqlerrm;
      return;
  end;

  delete from ad_adtssapar t where t.nunico = r_cab.nunico;
  --- by rodrigo dia 4/07/2019 novo processo renovar
  delete from ad_adtssaparrenovar t where t.nunico = r_cab.nunico;

  update ad_adtssacab c
     set c.codusuapr     = null,
         c.codusufin     = null,
         c.dhaprovadt    = null,
         c.dhaprovfin    = null,
         c.dhsolicitacao = null,
         c.nuacerto      = null,
         c.nufin         = null,
         c.situacao      = 'E'
   where c.nunico = field_nunico;

  insert into ad_adtssalgtt
    (nunico, dhalter, acao, codusu)
  values
    (r_cab.nunico, sysdate, 'Cancelada solicitações!', p_codusu);

  p_mensagem := 'Solicitação cancelada com sucesso!';

  stp_set_atualizando('N');
  ad_pkg_var.permite_update := false;

end;
/
