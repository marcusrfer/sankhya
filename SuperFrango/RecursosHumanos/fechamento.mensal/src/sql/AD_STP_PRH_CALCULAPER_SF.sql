Create Or Replace Procedure "AD_STP_PRH_CALCULAPER_SF"(p_codusu    Number,
                                                       p_idsessao  Varchar2,
                                                       p_qtdlinhas Number,
                                                       p_mensagem  Out Varchar2) As
  param_dtref Date;

Begin

  /*
    Autor: MARCUS.RANGEL 18/06/2019 12:43:17
    Objetivo: Permitir o recalculo do período direto da tela de parâmetros do RH e do dash.
    Processo: Fechamento mensal
  */

  param_dtref := act_dta_param(p_idsessao, 'DTREF');

  ad_pkg_var.Init_Time := dbms_utility.get_time;

  ad_pkg_rh.calcula_saldo_func(param_dtref, True);

  ad_pkg_rh.calcula_totais_acumulado(param_dtref);

  ad_pkg_var.End_Time := dbms_utility.get_time;

  p_mensagem := 'Operação realizada com sucesso em ' || To_Char((ad_pkg_var.End_Time - ad_pkg_var.Init_Time) / 100) || ' s';

End;
/
