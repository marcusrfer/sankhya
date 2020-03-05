CREATE OR REPLACE Procedure Stp_Adtssacab_Gerafin_Sf(p_Nunico      Number,
                                                     p_Aprfin      Number,
                                                     p_Mensagemusu Varchar2) As
   r_Cab  Ad_Adtssacab%Rowtype;
   r_Conf Ad_Adtssaconf%Rowtype;
   Mail   Tmdfmg%Rowtype;

   Errmsg        Varchar2(4000);
   v_Codusu      Number := Stp_Get_Codusulogado;
   v_Codusulibib Number;
   v_Count       Number := 1;
   v_Nufin       Number;
   v_Nufindesp   Number;
   v_Ultcod      Number;

Begin

   /**************************
   Autor:     Ricardo Soares de Oliveira
   Criado em: 09/02/2018
   Objetivo:  Gerar o adiantamento com provisão = S, vai gerar receita e despesa, e após aprovado (TSILIB) a provisão para para N
   **************************/
   Select c.* Into r_Cab From Ad_Adtssacab c Where c.Nunico = p_Nunico;

   Select c.* Into r_Conf From Ad_Adtssaconf c Where c.Codigo = r_Cab.Tipo;

   For r In (Select * From Ad_Adtssapar c Where c.Nunico = p_Nunico)
   
   Loop
   
      Stp_Keygen_Nufin(v_Nufin);
   
      -- Gerando a Receita / Despesa Despesa
      Insert Into Tgffin
         (Nufin,
          Codemp,
          Numnota,
          Dtneg,
          Desdobramento,
          Dhmov,
          Dtvenc,
          Dtvencinic,
          Codparc,
          Codtipoper,
          Dhtipoper,
          Codctabcoint,
          Codnat,
          Codcencus,
          Codproj,
          Codtiptit,
          Vlrdesdob,
          Vlrjuroembut,
          Recdesp,
          Provisao,
          Origem,
          Codusu,
          Dtalter,
          Desdobdupl,
          Historico,
          Codbco,
          Ad_Variacao,
          Ad_Modcred)
      Values
         (v_Nufin,
          r_Cab.Codemp,
          Nvl(r_Cab.Numnota, r_Cab.Nunico),
          r_Cab.Dtneg, --Trunc(Sysdate), alterado por Ricardo Soares em 25/07/2018 conforme solicitação do João Paulo
          r.Nrparcela,
          Sysdate,
          r.Dtvenc,
          r.Dtvenc,
          Case When r.Recdesp = -1 Then r_Cab.Codparc Else Nvl(r_Cab.Codparcrec, r_Cab.Codparc) End,
          Case When r.Recdesp = -1 Then r_Conf.Codtipoperdesp Else r_Conf.Codtipoperrec End,
          Ad_Get.Maxdhtipoper(Case When r.Recdesp = -1 Then r_Conf.Codtipoperdesp Else r_Conf.Codtipoperrec End),
          Nvl(r_Cab.Codctabcoint, r_Conf.Codctabcoint),
          r_Cab.Codnat,
          r_Cab.Codcencus,
          r_Cab.Codproj,
          Case When r.Sequencia = 1 Then Case When r_Cab.Forma = '1' /*Crédito em conta*/ Then 56 When
          r_Cab.Forma = '2' /*Cheque*/ Then 4 When r_Cab.Forma = '3' /*Espécie*/ Then 6 When r_Cab.Forma = '4' /*Compensação*/ Then 61 When
          r_Cab.Forma = '36' /*Boleto*/ Then 5 Else 3 End Else 61 End,
          Round(r.Vlrtotal, 2),
          Round(r.Vlrjuros, 2),
          r.Recdesp,
          Case When r_Conf.Exigaprdesp = 'N' Then 'N' Else r.Provisao End,
          'F',
          v_Codusu,
          Sysdate,
          'ZZ',
          r_Cab.Historico,
          1,
          'adtSsa',
          r_Cab.Modcred);
   
      If v_Ultcod Is Null Then
         Stp_Keygen_Tgfnum(p_Arquivo => 'TGFFRE', p_Codemp => 1, p_Tabela => 'TGFFRE', p_Campo => 'NUACERTO',
                           p_Dsync => 0,
                           
                           p_Ultcod => v_Ultcod);
      
      End If;
   
      Update Ad_Adtssapar p
         Set p.Nufin    = v_Nufin,
             p.Provisao = Case
                             When r_Conf.Exigaprdesp = 'N' Then
                              'N'
                             Else
                              p.Provisao
                          End
       Where p.Nunico = r.Nunico
         And p.Sequencia = r.Sequencia;
   
      Insert Into Tgffre
         (Codusu,
          Dhalter,
          Nuacerto,
          Nufin,
          Nufinorig,
          Nunota,
          Sequencia,
          Tipacerto)
      Values
         (v_Codusu,
          Sysdate,
          v_Ultcod,
          v_Nufin,
          Null,
          Null,
          r.Sequencia,
          'A');
   
      Update Tgffin
         Set Dtalter   = Sysdate,
             Nucompens = v_Ultcod,
             Numdupl   = v_Ultcod,
             Numnota   = Nvl(r_Cab.Numnota, v_Ultcod)
       Where Tgffin.Nufin = v_Nufin;
   
      If v_Count = 1 Then
      
         v_Count     := 2;
         v_Nufindesp := v_Nufin;
      
      End If;
   
   End Loop;

   If r_Conf.Exigaprdesp = 'S' Then
   
      If p_Aprfin = 1 Then
         Ad_Set.Ins_Liberacao(p_Tabela => 'AD_ADTSSACAB', p_Nuchave => p_Nunico, p_Evento => 1042, p_Valor => 1,
                              p_Codusulib => Nvl(r_Conf.Codusuapr, 946),
                              p_Obslib => 'Adiantamento ' || v_Ultcod || ', com Divergência de ' || p_Mensagemusu,
                              p_Errmsg => Errmsg);
      
         Mail.Email := Ad_Get.Mailfila(13); -- Busca usuários que estão vinculados ao perfil 13 (>>Bi Móvel >>Cadastro >>Perfil)
      
         Ad_Stp_Gravafilabi(p_Assunto => 'Liberação Adiantamento Financeiro',
                            p_Mensagem => 'Acaba de ser incluido o adiantamento ' || p_Nunico ||
                                           '. Favor verificar as liberações pendentes!' || Chr(13) || Chr(10) ||
                                           'Obrigado.' || Chr(13) || Chr(10) || 'Stp_Adtssacab_Gerafin_Sf' || Chr(13) ||
                                           Chr(10) || 'e-mail enviado para: ' || Mail.Email, p_Email => Mail.Email);
      
         If Errmsg Is Not Null Then
            Raise_Application_Error(-20105, Errmsg);
         End If;
      
      End If;
   
      v_Codusulibib := Ad_Confirma_Fin.Usulibfin(p_Codtipoper => r_Conf.Codtipoperdesp, p_Exige => 'F',
                                                 p_Codnat => r_Cab.Codnat, p_Codcencus => r_Cab.Codcencusresp,
                                                 p_Codcencusr => r_Cab.Codcencusresp);
   
      Ad_Set.Ins_Liberacao(p_Tabela => 'AD_ADTSSACAB', p_Nuchave => p_Nunico, p_Evento => 1035,
                           p_Valor => r_Cab.Vlrdesdob, p_Codusulib => v_Codusulibib,
                           p_Obslib => 'Adiantamento ' || v_Ultcod, p_Errmsg => Errmsg);
   
      Insert Into Ad_Tblcmf
         (Nometaborig,
          Nuchaveorig,
          Nometabdest,
          Nuchavedest)
      Values
         ('AD_ADTSSACAB',
          p_Nunico,
          'TGFFIN',
          v_Nufindesp);
   
   End If;

   Update Ad_Adtssacab c
      Set c.Nufin         = v_Nufindesp,
          c.Situacao = Case
                          When r_Conf.Exigaprdesp = 'N' Then
                           'A'
                          Else
                           'P'
                       End,
          c.Nuacerto      = v_Ultcod,
          c.Codusufin = Case
                           When p_Aprfin = 1 Then
                            Nvl(r_Conf.Codusuapr, 946)
                           Else
                            Null
                        End,
          c.Dhsolicitacao = Sysdate,
          c.Codusuapr = Case
                           When r_Conf.Exigaprdesp = 'N' Then
                            v_Codusu
                           Else
                            v_Codusulibib
                        End,
          c.Dhaprovadt = Case
                            When r_Conf.Exigaprdesp = 'N' Then
                             Sysdate
                            Else
                             Null
                         End
    Where c.Nunico = p_Nunico;

   If r_Conf.Exigaprdesp = 'S' Then
      Update Tsilib l
         Set l.Ad_Nuadto = v_Ultcod,
             l.Vlrlimite = 1
       Where l.Nuchave = p_Nunico
         And l.Tabela = 'AD_ADTSSACAB';
   
   End If;

   If Errmsg Is Not Null Then
      Raise_Application_Error(-20105, Errmsg);
   End If;

End;
/
