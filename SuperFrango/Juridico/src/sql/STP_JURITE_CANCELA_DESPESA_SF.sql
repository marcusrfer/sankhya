Create Or Replace Procedure "STP_JURITE_CANCELA_DESPESA_SF"(p_codusu    Number,
                                                            p_idsessao  Varchar2,
                                                            p_qtdlinhas Number,
                                                            p_mensagem  Out Nocopy Varchar2) As

  v_situacao   Varchar2(1);
  p_dhbaixa    Date;
  p_numremessa Number;
  p_count      Int;

  jur ad_jurite%Rowtype;

Begin

  /* Autor: Gustavo Lopes, M. Rangel
  * Processo: Despesas Jur�dicas
  * Objetivo: Cancelar/desfazer as movimenta��es realizadas 
  */

  If p_qtdlinhas > 1 Or p_qtdlinhas = 0 Then
    p_mensagem := 'Selecione apenas um registro por vez';
    Return;
  End If;

  jur.nupasta := act_int_field(p_idsessao, 1, 'NUPASTA');
  jur.seq     := act_int_field(p_idsessao, 1, 'SEQ');

  Select *
    Into jur
    From ad_jurite
   Where nupasta = jur.nupasta
     And seq = jur.seq;

  ---valida se for gerado financeiro

  If Nvl(jur.nufin, 0) = 0 Then
  
    p_mensagem := fc_formatahtml_sf('A��o n�o permitida!', 'Registro n�o possui despesa gerada',
                                    'S� � possivel cancelar despesa que tenha gerado financeiro');
    Return;
  End If;

  Select Count(*)
    Into p_count
    From tgffin
   Where nufin = jur.nufin;

  ---situa��o: e - elaborando

  v_situacao := 'P';

  If p_count > 0 Then
  
    -- cancelamento de adiantamentos
    If Nvl(jur.adto, 'N') = 'S' Then
      Begin
        For mbc In (Select *
                      From tgfmbc m
                     Where m.ad_nufinproc = jur.nufin)
        Loop
        
          If mbc.dhconciliacao Is Null Then
          
            Delete From tgffin
             Where nufin = jur.nufin;
          
            Delete From tgfmbc
             Where nubco = mbc.nubco;
          
          Else
            Rollback;
            p_mensagem := 'Lan�amentos conciliados n�o podem ser cancelados. <br>' ||
                          'Procure o financeiro para realizar o estorno da concilia��o antes de prosseguir';
            Return;
          End If;
        
        End Loop;
      
        Delete From tsilib
         Where nuchave = jur.nupasta
           And sequencia = jur.seq
           And tabela = 'AD_JURITE';
      
        Delete From ad_jurlib l
         Where l.nupasta = jur.nupasta
           And l.seq = jur.seq;
      
      Exception
        When Others Then
          p_mensagem := 'Erro ao desfazer adiantamento. ' || Sqlerrm;
          Return;
      End;
    
    Else
      Begin
        /* 15/06/2018 - m. rangel */
        -- pesquisa despesas 
        -- enquanto o lan�amento n�o foi liberado, pois o mesmo vai pra tsilib, o recdesp permanece 0
        -- nos casos que uma despesa foi gerada por acidente a mesma n�o ser� liberada, logo, � necess�rio desfazer a solicita��o de libera��o
        -- e excluir o lan�amento da tgffin
        Select dhbaixa, numremessa
          Into p_dhbaixa, p_numremessa
          From tgffin
         Where nufin = jur.nufin
           And recdesp != 0;
      
      Exception
        When no_data_found Then
          Select dhbaixa, numremessa
            Into p_dhbaixa, p_numremessa
            From tgffin
           Where nufin = jur.nufin
             And recdesp = 0
             And Exists (Select 1
                    From tsilib l
                   Where tabela = 'TGFFIN'
                     And l.nuchave = jur.nufin);
        
      End;
    
      ---valida se o titulo financeiro j� foi baixado
      If p_dhbaixa Is Not Null Then
        p_mensagem := fc_formatahtml_sf('A��o n�o permitida!', 'Registro est� baixado',
                                        'S� � possivel cancelar despesa caso n�o tenha sido baixado.');
        Return;
      End If;
    
      ---valida se o titulo financeiro j� foi gerado remessa
      If Nvl(p_numremessa, 0) > 0 Then
        p_mensagem := fc_formatahtml_sf('A��o n�o permitida!', 'Registro est� com a remessa gerada',
                                        'S� � possivel cancelar despesa caso n�o tenha sido gerado remessa');
        Return;
      End If;
    
      Select Count(*)
        Into p_count
        From tgfmbc mbc
       Where mbc.ad_nufinproc = jur.nufin;
    
      ---valida se o titulo financeiro est� vinculado a mov. banc�ria
    
      If Nvl(p_count, 0) > 0 Then
        p_mensagem := fc_formatahtml_sf('A��o n�o permitida!',
                                        'Registro est� vinculado a Mov. Banc�ria',
                                        'S� � possivel cancelar despesa caso n�o tenha vinculo');
        Return;
      End If;
    
      Begin
        Delete From tsilib
         Where nuchave = jur.nufin
           And evento In (1001, 1014)
           And Tabela = 'TGFFIN';
      Exception
        When Others Then
          Raise;
      End;
    
    End If;
  
  End If;

  Begin
    Delete From ad_tblcmf
     Where nometaborig = 'AD_JURITE'
       And nuchaveorig = jur.nupasta || jur.seq;
  Exception
    When Others Then
      Raise;
  End;

  Begin
    Delete From tgffin
     Where nufin = jur.nufin;
  Exception
    When Others Then
      Raise;
  End;

  Begin
    Update ad_jurite
       Set nufin = Null, situacao = v_situacao, codusucan = p_codusu, dhcanc = Sysdate,
           nufincanc = jur.nufin, codusudesp = Null, dhdesp = Null, codusujur = Null, dhjur = Null,
           codusufin = Null, dhfin = Null
     Where nupasta = jur.nupasta
       And seq = jur.seq;
  Exception
    When Others Then
      Raise;
  End;

  p_mensagem := 'Cancelado com sucesso!!!' || Chr(13) || Chr(10) || '<i> Nr. Financeiro: ' ||
                jur.nufin || '</i>.';

End;
/
