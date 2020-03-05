create or replace function ad_fnc_formataerro(p_erro varchar2) return varchar as
 v_msg varchar2(4000);
begin

 /*v_msg := FC_FORMATAHTML_SF(P_MENSAGEM => p_Erro, P_MOTIVO => Null, P_SOLUCAO => Null,
 P_ERROR => Null);*/

 v_msg := '<p><a href="http://www.sankhya.com.br" target="_blank"><img ' ||
          'src="http://www.sankhya.com.br/imagens/logo-sankhya.png"></img></a></p> ' ||
          '<p align="center"><font color="#FF0000"><b> ATENÇÃO: </b></font></p>
           <p align="center">' || p_erro ||
          '</p><br>
  <br><p style="text-align:center;"> <span style="color:green"><b>Informações para o Suporte:</b></span><br>';

 --v_msg := fc_formatahtml(p_erro, Null, Null);

 return v_msg;

end;
/
