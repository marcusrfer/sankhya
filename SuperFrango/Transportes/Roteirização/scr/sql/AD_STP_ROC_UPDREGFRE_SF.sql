create or replace Procedure "AD_STP_ROC_UPDREGFRE_SF" (
  p_codusu      Number,
  p_idsessao    Varchar2,
  p_qtdlinhas   number,
  p_mensagem    Out nocopy Varchar2
) As
  p_codregfre   Varchar2(4000);
  v_numrocc     Number;
  v_numrocp     Number;
Begin
  p_codregfre   := act_txt_param(p_idsessao,'CODREGFRE');
  
    v_numrocc   := act_int_field(p_idsessao,1,'NUMROCC');
    --v_numrocp   := act_int_field(p_idsessao,i,'NUMROCP');
  
  begin
   update ad_tsfrocp 
     set codregfre = to_number(p_codregfre)
    where numrocc = v_numrocc;
  exception
   when others then
     p_mensagem := 'Erro ao atualizar as regiões de Frete. '||chr(13)||sqlerrm;
     return;
  end;
  
  p_mensagem := 'Regiões atualizadas com sucesso!!!';

End;