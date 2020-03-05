Create Or Replace Procedure "AD_STP_ROC_SETCODVEIOC_SF"(p_codusu Number,
                                                        p_idsessao Varchar2,
                                                        p_qtdlinhas Number,
                                                        p_mensagem Out Varchar2) As
   p_codvei    Varchar2(4000);
   v_numrocc   Number;
   v_pesocarga Float;
   c           ad_tsfrocc%Rowtype;
   v           tgfvei%Rowtype;
   o           tgford%Rowtype;

Begin

   /* 
   Autor: M. Rangel
   Processo: Roteirização
   Objetivo: Preencher o veículo da ordem de carga pela tela de formação de carga;
   */

   -- obsoleto, substituído por trigger

   p_codvei := act_txt_param(p_idsessao, 'CODVEI');

   For i In 1 .. p_qtdlinhas
   Loop
      v_numrocc := act_int_field(p_idsessao, i, 'NUMROCC');
   
      Begin
         Select * Into c From ad_tsfrocc Where numrocc = v_numrocc;
      Exception
         When Others Then
            Raise;
      End;
   
      Begin
         Select * Into v From tgfvei Where codveiculo = p_codvei;
      Exception
         When Others Then
            Raise;
      End;
   
      Begin
         Select *
           Into o
           From tgford
          Where codemp = c.codemp
            And ordemcarga = c.ordemcarga;
      Exception
         When Others Then
            Raise;
      End;
   
      Begin
         Select Sum(p.peso) Into v_pesocarga From ad_tsfrocp p Where p.numrocc = c.numrocc;
      Exception
         When Others Then
            Raise;
      End;
   
      If Nvl(v.pesomax, 0) = 0 Then
         Begin
            Select cat.pesomax Into v.pesomax From ad_tsfcat cat Where cat.codcat = v.ad_codcat;
         Exception
            When Others Then
               v.pesomax := 0;
         End;
      End If;
   
      -- verifica se já existe veículo informada na OC
      If Nvl(o.codveiculo, 0) > 0 Then
         If act_escolher_simnao('Veículo já informado',
                                'A OC já possui o veículo ' || ad_get.Formataplaca(o.codveiculo) ||
                                ' informado.\n Deseja infomar o novo veículo mesmo assim?',
                                p_idsessao,
                                1) = 'N' Then
            Return;
         End If;
      End If;
   
      -- compara peso da OC com o do veículo
      If v_pesocarga > v.pesomax Then
         If act_escolher_simnao('Peso do veículo ultrapassado',
                                'O peso da carga informada é superior ao peso máximo informado do veículo.<br>' || Chr(13) ||
                                'Deseja continuar?',
                                p_idsessao,
                                2) = 'S' Then
         
            Begin
               Update tgford ord
                  Set ord.codveiculo = p_codvei, ord.codparctransp = v.codparc, ord.codparcmotorista = v.codmotorista
                Where ord.codemp = c.codemp
                  And ord.ordemcarga = c.ordemcarga;
               Null;
            Exception
               When Others Then
                  Raise;
            End;
         Else
            Return;
         End If;
      End If;
   
   End Loop;

   p_mensagem := 'Veículo ' || v.marcamodelo || ' / ' || ad_get.formataplaca(v.placa) || ' vinculado com sucesso na OC ' ||
                 c.ordemcarga;

End;
/
