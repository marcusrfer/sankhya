Create Or Replace Procedure "AD_STP_ROC_GETPEDIDOS_SF"(p_codusu Number,
                                                       p_idsessao Varchar2,
                                                       p_qtdlinhas Number,
                                                       p_mensagem Out Nocopy Varchar2) As
   p_codemp     Varchar2(4000);
   p_dtnegini   Date;
   p_dtnegfim   Date;
   p_tipmov     Varchar2(1);
   p_codvend    Varchar2(4000);
   p_codger     Varchar2(4000);
   p_codregfre  Varchar2(4000);
   p_codcid     Varchar2(4000);
   p_CodTipParc Varchar2(4000);
   p_ordemcarga Int;
   v_seqped     Number;

   r_roc ad_tsfrocc%Rowtype;
   r_ord tgford%Rowtype;

   Type type_tab_pedido Is Table Of ad_tsfrocp%Rowtype;
   t type_tab_pedido := type_tab_pedido();
Begin

   /* 
   * Autor: M. Rangel
   * Processo: Roteirizador/sequenciador de ordens de carga (subprocesso frete OC)
   * Objetivo: Ação "Buscar Pedidos" da tela de Formação de Carga pela Distancia
   */

   p_codemp     := act_txt_param(p_idsessao, 'CODEMP');
   p_dtnegini   := act_dta_param(p_idsessao, 'DTNEGINI');
   p_dtnegfim   := act_dta_param(p_idsessao, 'DTNEGFIM');
   p_tipmov     := act_txt_param(p_idsessao, 'TIPMOV');
   p_codvend    := act_txt_param(p_idsessao, 'CODVEND');
   p_codger     := act_txt_param(p_idsessao, 'CODGER');
   P_Codregfre  := Act_txt_Param(P_Idsessao, 'CODREGFRE');
   p_CodTipParc := Act_txt_Param(P_Idsessao, 'CODTIPPARC');
   p_codcid     := act_txt_param(p_idsessao, 'CODCID');
   p_ordemcarga := act_int_param(p_idsessao, 'ORDEMCARGA');

   If Lower(p_idsessao) = 'debug' Then
      p_codemp      := 1;
      p_dtnegini    := Trunc(Sysdate) - 1;
      p_dtnegfim    := Trunc(Sysdate) - 1;
      p_tipmov      := 'V';
      p_codvend     := Null;
      p_codger      := Null;
      P_Codregfre   := Null;
      p_CodTipParc  := 99040100;
      p_codcid      := Null;
      p_ordemcarga  := Null;
      r_roc.numrocc := 25;
   End If;

   r_roc.numrocc := act_int_field(p_idsessao, 1, 'NUMROCC');

   If p_qtdlinhas > 1 Then
      p_mensagem := 'Selecione uma Ordem de Carga por vez.';
      Return;
   End If;

   Select * Into r_roc From ad_tsfrocc Where numrocc = r_roc.numrocc;

   Begin
      Select *
        Into r_ord
        From tgford o
       Where o.codemp = r_roc.codemp
         And o.ordemcarga = r_roc.ordemcarga;
   Exception
      When Others Then
         p_mensagem := 'Erro ao buscar os dados da Ordem de Carga. <br>' || Sqlerrm;
         Return;
   End;

   /* 
     TODO: owner="M.Rangel" category="Test" priority="1 - High" created="06/09/2018"
     text="Não esquecer de descomentar quando entrar em produção"
     
   
   If r_ord.situacao = 'F' Then
     p_mensagem := 'Ordem de carga Fechada, não é possível realizar alterações';
     Return;
   End If;
   */

   If r_roc.status = 'C' Then
      p_mensagem := 'Sequência de entrega desta Ordem de carga já foi confirmada';
   End If;

   -- verifica se já tem algum registro
   Select Nvl(Max(p.numrocp), 0) Into v_seqped From ad_tsfrocp p Where numrocc = r_roc.numrocc;

   -- se já existem
   If v_seqped > 0 Then
      -- avisa e pergunta se continua
      If act_escolher_simnao(P_TITULO => 'Formação de Ordem de Carga',
                             P_TEXTO => 'Já existem pedidos/notas vinculadas a esta ordem de carga, deseja inserir mais lançamentos assim mesmo?',
                             P_CHAVE => p_idsessao,
                             P_SEQUENCIA => 1) = 'N' Then
         Return;
      Else
         -- se já existir, pergunta se exclui pra incluir de novo
         If act_escolher_simnao(P_TITULO => 'Exclusão de lançamentos',
                                P_TEXTO => 'Deseja excluir os lançamentos existentes?',
                                P_CHAVE => p_idsessao,
                                P_SEQUENCIA => 2) = 'S' Then
         
            -- se sim, excluir os lançamentos existentes
            Begin
               Delete From ad_tsfrocp p Where p.numrocc = r_roc.numrocc;
            Exception
               When Others Then
                  Raise;
            End;
         
            v_seqped := 0;
         
         End If;
      
      End If;
   
   End If;

   -- busca os pedidos/notas
   -- sempre vai inserir com a ordem d carga do cabeçalho
   Begin
      Select r_roc.numrocc As numrocc,
             rownum + v_seqped As numrocp,
             cab.codemp,
             r_roc.ordemcarga,
             cab.nunota,
             cab.numnota,
             cab.serienota,
             cab.dtneg,
             cab.dtfatur,
             cab.dtentsai,
             cab.codtipoper,
             cab.tipmov,
             cab.codvend,
             ven.codger,
             cab.codparc,
             par.codcid,
             par.codbai,
             cid.uf As coduf,
             par.ad_codregfre As codregfre,
             cab.qtdvol,
             cab.peso,
             Null As sequencia,
             par.latitude,
             par.longitude,
             cab.vlrnota
        Bulk Collect
        Into t
        From tgfcab cab
        Join tgfpar par
          On cab.codparc = par.codparc
        Join tsicid cid
          On par.codcid = cid.codcid
        Join tsibai bai
          On par.codbai = bai.codbai
        Join tgfven ven
          On cab.codvend = ven.codvend
        Join tgfven ger
          On ven.codger = ger.codvend
        Left Join ad_tsfrfc reg
          On par.ad_codregfre = reg.codregfre
        Left Join tgfppa ppa
          On ppa.codparc = cab.codparc
       Where cab.statusnota = 'L'
         And par.codtipparc Not In (11110200, 21075000)
         And cab.dtfatur Between p_dtnegini And p_dtnegfim
         And cab.tipmov = p_tipmov
         And cab.codemp = p_codemp
         And (cab.codvend = p_codvend Or Nvl(p_codvend, 0) = 0)
         And (ven.codger = p_codger Or Nvl(p_codger, 0) = 0)
         And (Par.Ad_Codregfre = P_Codregfre Or Nvl(P_Codregfre, 0) = 0)
         And (par.codcid = p_codcid Or Nvl(p_codcid, 0) = 0)
         And (ppa.codtipparc = p_CodTipParc Or Nvl(p_CodTipParc, 0) = 0)
         And (cab.ordemcarga = Nvl(p_ordemcarga, 0)); --Or Nvl(p_ordemcarga, 0) = 0);
   End;

   Dbms_Output.Put_Line(t.last);

   -- insere os pedidos/notas
   Begin
      Forall i In t.first .. t.last Save Exceptions
         Insert Into ad_tsfrocp Values t (i);
   Exception
      When Others Then
         Dbms_Output.Put_Line('Qtd. Erros: ' || Sql%Bulk_Exceptions.count);
         p_mensagem := 'Qtd. Erros: ' || Sql%Bulk_Exceptions.count;
         For z In 1 .. Sql%Bulk_Exceptions.count
         Loop
            Dbms_Output.Put_Line('Posição do erro: ' || Sql%Bulk_Exceptions(z).error_index);
            Dbms_Output.Put_Line('Msg Erro: ' || Sqlerrm || ' ' || Sqlerrm(-Sql%Bulk_Exceptions(z).error_code));
         End Loop;
   End;

   -- zera distância e valor da OC
   Begin
      ad_pkg_var.permite_update := True;
      Update ad_tsfrocc Set distrota = 0, vlrrota = 0 Where numrocc = r_roc.numrocc;
   Exception
      When Others Then
         p_mensagem := Sqlerrm;
         Return;
   End;

   p_mensagem := t.count || ' registros inseridos';

End;
/
