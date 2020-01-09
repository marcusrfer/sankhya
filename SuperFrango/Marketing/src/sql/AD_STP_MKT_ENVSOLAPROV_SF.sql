Create Or Replace Procedure "AD_STP_MKT_ENVSOLAPROV_SF"(p_codusu Number,
                                                        p_idsessao Varchar2,
                                                        p_qtdlinhas Number,
                                                        p_mensagem Out Varchar2) As

   /* 
   * Dt. Criação: 26/03/2019
   * Autor: M. Rangel
   * Processo: Solicitações Endo Marketing
   * Objetivo: Enviar a solicitação para a tela de central de solicitações para análise e posterior aprovação.
   */
   s ad_tsfsmkt%Rowtype;
   c ad_tsfcmkt%Rowtype;
   m tmdfmg%Rowtype;
   i Int;

Begin

   For l In 1 .. p_qtdlinhas
   Loop
      s.nusmkt := act_int_field(p_idsessao, l, 'NUSMKT');
   
      Select * Into s From ad_tsfsmkt Where nusmkt = s.nusmkt;
   
      -- verifica se existem anexos
      Select Count(*)
        Into i
        From tsianx a
       Where a.nomeinstancia = 'TSFSMKT'
         And a.nuattach = s.nusmkt;
   
      -- valida anexos
      If Nvl(s.anexo, 'N') = 'S' And i = 0 Then
         p_mensagem := 'O formulário possui a informação de que existem arquivos relevantes, ' ||
                       'mas nenhum foi anexado ao formulário. <br>Por favor, anexe os arquivos ou desmarque a opção.';
         Return;
      End If;
   
      Select Count(*) Into i From ad_tsfcmkt c Where c.nusmkt = s.nusmkt;
   
      -- busca os emails dos resp da central de paramentros, regra 19
      For usu In (Select u.codusu, u.email
                    From ad_centparamusu pu
                    Join tsiusu u
                      On pu.codusu = u.codusu
                   Where pu.nupar = 19
                     And Nvl(pu.validacao, 'N') = 'S')
      Loop
         If m.email Is Null Then
            m.email := usu.email;
         Else
            m.email := m.email || ', ' || usu.email;
         End If;
         m.codusu := usu.codusu;
      End Loop;
   
      --se já existe
      If i > 0 Then
         Select * Into c From ad_tsfcmkt Where nusmkt = s.nusmkt;
         -- verifica se finalizado
         If c.status = 'F' Then
            p_mensagem := 'Essa solicitação já foi finalizada!';
            Return;
         Else
            Begin
               Update ad_tsfcmkt
                  Set status = 'P'
                Where nucmkt = c.nucmkt
                  And nusmkt = s.nusmkt;
            Exception
               When Others Then
                  p_mensagem := 'Erro ao atualizar o status da Solicitação na Central. Erro: ' || Sqlerrm;
                  Return;
            End;
         
            --insere interação
            Declare
               v_nuimkt Number;
            Begin
            
               Select Nvl(Max(nuimkt), 0) + 1 Into v_nuimkt From ad_tsfimkt Where nucmkt = c.nucmkt;
            
               Insert Into ad_tsfimkt
                  (nucmkt, nuimkt, dhcontato, codusuint, contato, ocorrencia, status)
               Values
                  (c.nucmkt, v_nuimkt, Sysdate, p_codusu, 'S', 'Reenvio para Análise', 'C');
            Exception
               When Others Then
                  p_mensagem := 'Erro ao atualizar o status da Solicitação na Central. Erro: ' || Sqlerrm;
                  Return;
            End;
         
            -- atualiza histórico da solicitação
            Begin
               Update ad_tsfsmkt
                  Set detagencia = detagencia || Chr(13) || To_Char(Sysdate, 'dd/mm/yyyy hh24:mi:ss') ||
                                   ' - Reenviada para análise do marketing após correção.'
                Where nusmkt = s.nusmkt;
            Exception
               When Others Then
                  p_mensagem := 'Erro ao atualizar a solicitação. - ' || Sqlerrm;
                  Return;
            End;
         
            ad_stp_gravafilabi(p_Assunto => 'Solicitação de Endo Marketing reenviada!',
                               p_Mensagem => m.mensagem,
                               p_Email => m.email);
         End If;
      
         -- se ainda não existe
      Else
      
         stp_keygen_tgfnum('ad_tsfcmkt', 1, 'ad_tsfcmkt', 'nucmkt', 0, c.nucmkt);
      
         Insert Into ad_tsfcmkt
            (nucmkt, nusmkt, codususol, dhsolicit, dhenvio, codcencus, status, tipojob, objetivo, veiculacao, tipomaterial)
         Values
            (c.nucmkt,
             s.nusmkt,
             s.codususol,
             s.dhsolicita,
             Sysdate,
             s.codcencus,
             'P',
             s.tipojob,
             s.objetivo,
             s.veiculacao,
             s.tipomaterial);
      
         m.mensagem := Null;
         dbms_lob.createtemporary(m.mensagem, True);
      
         dbms_lob.append(m.mensagem, '<!DOCTYPE html><html><head>');
         dbms_lob.append(m.mensagem, '<meta http-equiv="content-language" content="pt-br">');
         dbms_lob.append(m.mensagem, '<meta http-equiv="content-type" content="text/html; charset=iso-8859-1">');
         dbms_lob.append(m.mensagem, '</head><body>');
         dbms_lob.append(m.mensagem, '<table border="1" style="border-collapse: collapse; width: 100%;">  ');
         dbms_lob.append(m.mensagem, ' <tbody><tr>');
         dbms_lob.append(m.mensagem, '<td style="width: 16.6667%;">Nro Solicitação</td>');
         dbms_lob.append(m.mensagem, '<td style="width: 16.6667%;">' || s.nusmkt || '</td>');
         dbms_lob.append(m.mensagem, '<td style="width: 16.6667%;">Solicitante</td>');
         dbms_lob.append(m.mensagem, '<td style="width: 16.6667%;">' || ad_get.Nomeusu(s.codususol, 'resumido') || '</td>');
         dbms_lob.append(m.mensagem, '<td style="width: 16.6667%;">Dh. Solicitação</td>');
         dbms_lob.append(m.mensagem, '<td style="width: 16.6667%;">' || To_Char(s.dhsolicita, 'dd/mm/yyyy') || '</td>');
         dbms_lob.append(m.mensagem, '</tr> </tbody></table>');
         dbms_lob.append(m.mensagem, '<table border="1" style="border-collapse: collapse; width: 100%;">');
         dbms_lob.append(m.mensagem, '<tbody>');
         dbms_lob.append(m.mensagem, '<tr style="height: 21px;">');
         dbms_lob.append(m.mensagem, '<td style="width: 100%; height: 21px; text-align: left;">C.R: ');
         dbms_lob.append(m.mensagem, ' - ' || ad_get.DescrCenCus(s.codcencus) || '</td></tr>');
         --dbms_lob.append(m.mensagem, ad_get.Opcoescampo(s.tipojob, 'TIPOJOB', 'AD_TSFSMKT') || '</td></tr>');
         dbms_lob.append(m.mensagem, '<tr style="height: 21px;">');
         dbms_lob.append(m.mensagem, '<td style="width: 100%; height: 21px; text-align: center;background-color: #999999;">');
         dbms_lob.append(m.mensagem, 'Descritivo da demanda</td></tr>');
         dbms_lob.append(m.mensagem, '<tr style="height: 21px;">');
         dbms_lob.append(m.mensagem, '<td style="width: 100%; height: 21px; text-align: left;">');
         dbms_lob.append(m.mensagem, s.especificajob || '</td></tr><tr>');
         dbms_lob.append(m.mensagem,
                         '<td style="width: 100%; text-align: center;background-color: #999999;">Publico Alvo</td></tr><tr>');
         dbms_lob.append(m.mensagem, '<td style="width: 100%; text-align: left;">');
         dbms_lob.append(m.mensagem, ad_get.opcoescampo(s.publicoalvo, 'PUBLICOALVO', 'AD_TSFSMKT'));
         dbms_lob.append(m.mensagem, ' - ' || s.pubalvocompl || '</td></tr><tr>');
         dbms_lob.append(m.mensagem,
                         '<td style="width: 100%; text-align: center;background-color: #999999;">Objetivo da Comunicação</td>');
         dbms_lob.append(m.mensagem, '</tr><tr><td style="width: 100%; text-align: left;">');
         dbms_lob.append(m.mensagem, ad_get.opcoescampo(s.objetivo, 'OBJETIVO', 'AD_TSFSMKT'));
         dbms_lob.append(m.mensagem, s.objetivocompl || '</td>');
         dbms_lob.append(m.mensagem,
                         '</tr><tr><td style="width: 100%; text-align: center;background-color: #999999;">Essencial para o Job</td>');
         dbms_lob.append(m.mensagem, '</tr><tr><td style="width: 100%; text-align: left;">');
         dbms_lob.append(m.mensagem, s.necessidadejob || '</td>');
         dbms_lob.append(m.mensagem,
                         '</tr><tr><td style="width: 100%; text-align: center;background-color: #999999;">Veiculação</td>');
         dbms_lob.append(m.mensagem, '</tr><tr><td style="width: 100%; text-align: left;">');
         dbms_lob.append(m.mensagem, ad_get.opcoescampo(s.veiculacao, 'VEICULACAO', 'AD_TSFSMKT'));
         dbms_lob.append(m.mensagem, ' - ' || s.veiculacompl || '</td></tr><tr>');
         dbms_lob.append(m.mensagem,
                         '<td style="width: 100%; text-align: center;background-color: #999999;">Tipo do Material</td>');
         dbms_lob.append(m.mensagem, '</tr><tr><td style="width: 100%; text-align: left;">');
         dbms_lob.append(m.mensagem, ad_get.opcoescampo(s.tipomaterial, 'TIPOMATERIAL', 'AD_TSFSMKT'));
         dbms_lob.append(m.mensagem, ' - ' || s.tipmatcompl || '</td></tr><tr>');
         dbms_lob.append(m.mensagem, '<td style="width: 100%; text-align: center;background-color: #999999;">Dimensões</td>');
         dbms_lob.append(m.mensagem, '</tr><tr>');
         dbms_lob.append(m.mensagem, '<td style="width: 100%; text-align: left;">');
         dbms_lob.append(m.mensagem, s.altura || ' x ' || s.largura || ' x ' || s.profundidade);
         dbms_lob.append(m.mensagem, ' - ' || ad_get.opcoescampo(s.unidmedida, 'UNIDMEDIDA', 'AD_TSFSMKT'));
         dbms_lob.append(m.mensagem, ' - ' || s.dimensaocompl || '</td></tr><tr>');
         dbms_lob.append(m.mensagem, '<td style="width: 100%; text-align: center;background-color: #999999;">Modelo/Padrão</td>');
         dbms_lob.append(m.mensagem, '</tr><tr><td style="width: 100%; text-align: left;">');
         dbms_lob.append(m.mensagem, s.modelocompl || '</td>');
         dbms_lob.append(m.mensagem, '</tr><tr>');
         dbms_lob.append(m.mensagem,
                         '<td style="width: 100%; text-align: center;background-color: #999999;">Restrições/Obrigações</td>');
         dbms_lob.append(m.mensagem, '</tr><tr>');
         dbms_lob.append(m.mensagem, '<td style="width: 100%; text-align: left;">' || s.restricoes || '</td>');
         dbms_lob.append(m.mensagem, '</tr><tr>');
         dbms_lob.append(m.mensagem,
                         '<td style="width: 100%; text-align: center;background-color: #999999;">Mais informações</td>');
         dbms_lob.append(m.mensagem, '</tr><tr>');
         dbms_lob.append(m.mensagem, '<td style="width: 100%; text-align: center;">');
         dbms_lob.append(m.mensagem, 'Cor: ' || s.cor);
         dbms_lob.append(m.mensagem, '<br>Possui Anexo: ' || ad_get.Opcoescampo(s.anexo, 'ANEXO', 'AD_TSFSMKT') || '</td>');
         dbms_lob.append(m.mensagem, '</tr><tr>');
         dbms_lob.append(m.mensagem, '<td style="width: 100%; text-align: center;"></td>');
         dbms_lob.append(m.mensagem, '</tr></tbody></table></body></html>	');
      
         -- envia o e-mail para usuário/lista do parametro
         ad_stp_gravafilabi(p_Assunto => 'Nova Solicitação de Endo Marketing recebida.',
                            p_Mensagem => m.mensagem,
                            p_Email => m.email);
      
         -- envia o aviso do sistema
         Begin
            ad_set.Ins_Avisosistema(p_Titulo => 'Nova Solicitação!',
                                    p_Descricao => 'Foi inserida uma nova solitação de material de marketing.',
                                    p_Solucao => 'Vá à Central de Solicitações para maiores informações!',
                                    p_Usurem => p_codusu,
                                    p_Usudest => m.codusu,
                                    p_Prioridade => 0,
                                    p_Tabela => 'AD_TSFCKMT',
                                    p_Nrounico => c.nucmkt,
                                    p_Erro => p_mensagem);
         
            If p_mensagem Is Not Null Then
               Return;
            End If;
         End;
      
         --Atualiza solicitação
         Begin
            Update ad_tsfsmkt
               Set dhenviomkt = Sysdate,
                   --dtlimiteaprov = Sysdate + 7,
                   detagencia = Case
                                   When detagencia Is Null Then
                                    To_Char(Sysdate, 'dd/mm/yyyy hh24:mi:ss') || ' - Enviada para análise do marketing.'
                                   Else
                                    detagencia || Chr(13) || To_Char(Sysdate, 'dd/mm/yyyy hh24:mi:ss') ||
                                    ' - Enviada para análise do marketing.'
                                End,
                   mailtext = m.mensagem
             Where nusmkt = s.nusmkt;
         Exception
            When Others Then
               p_mensagem := 'Erro ao atualizar a solicitação. - ' || Sqlerrm;
               Return;
         End;
      
         --insere interação
         Declare
            v_nuimkt Number;
         Begin
         
            Select Nvl(Max(nuimkt), 0) + 1 Into v_nuimkt From ad_tsfimkt Where nucmkt = c.nucmkt;
         
            Insert Into ad_tsfimkt
               (nucmkt, nuimkt, dhcontato, codusuint, contato, ocorrencia, status)
            Values
               (c.nucmkt, v_nuimkt, Sysdate, p_codusu, 'S', 'Envio para Análise', 'C');
         Exception
            When Others Then
               p_mensagem := 'Erro ao atualizar o status da Solicitação na Central. Erro: ' || Sqlerrm;
               Return;
         End;
      
      End If;
   
   End Loop;

   p_mensagem := 'Solicitação enviada com sucesso!!!';

End;
/
