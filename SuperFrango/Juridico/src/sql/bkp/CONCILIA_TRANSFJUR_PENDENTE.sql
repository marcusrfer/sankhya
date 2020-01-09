begin
  sys.dbms_scheduler.create_job(job_name            => 'SANKHYA.CONCILIA_TRANSFJUR_PENDENTE',
                                job_type            => 'PLSQL_BLOCK',
                                job_action          => 'Begin
    For mbc In (With conciliados As
                   (Select *
                      From tgfmbc
                     Where conciliado = ''S''),
                  pendentes As
                   (Select *
                      From tgfmbc
                     Where conciliado = ''N'')
                  Select c.numtransf, c.nubco nubcoconc, c.codctabcoint codctaconc, p.nubco nubcopend, p.codctabcoint codctapend,
                         c.dhconciliacao, c.codusu
                    From ad_jurlog l
                    Join conciliados c
                      On l.nubco = c.nubco
                    Join pendentes p
                      On c.nubcocp = p.nubco
                   Where c.numtransf = p.numtransf
                     And l.conciliado = ''S''
                     And Trunc(p.dtlanc, ''mm'') = Trunc(Sysdate, ''mm'')-1)
    Loop
      Begin
        Update tgfmbc
           Set dhconciliacao = mbc.dhconciliacao, codusu = mbc.codusu, conciliado = ''S''
         Where nubco = mbc.nubcopend
           And numtransf = mbc.numtransf
           And dhconciliacao Is Null
           And Nvl(conciliado, ''N'') = ''N'';
      Exception
        When Others Then
          Rollback;
      End;
    End Loop;
  End;',
                                start_date          => to_date('30-05-2018 00:00:00', 'dd-mm-yyyy hh24:mi:ss'),
                                repeat_interval     => 'Freq=Daily;ByHour=4',
                                end_date            => to_date(null),
                                job_class           => 'DEFAULT_JOB_CLASS',
                                enabled             => true,
                                auto_drop           => true,
                                comments            => 'Ação que concilia os lançamentos pendentes de conciliação oriundos de transferências bancárias do jurídico');
end;
/
