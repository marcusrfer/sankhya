Create Or Replace Trigger AD_TRG_BIUD_TCSAMZ_SF
  Before Insert Or Update Or Delete On Ad_Tcsamz
  For Each Row
Declare
  i Int := 0;
Begin

  /*
  ** Autor: M. Rangel
  ** Processo: Contratos do armazém
  ** Objetivo: Controle de alterações
  */

  If Ad_Pkg_Var.Permite_Update Then
    Return;
  End If;

  -- count pedidos/notas confirmadas  
  Select Count(*)
    Into i
    From Tgfcab c
   Where c.Numcontrato = Nvl(:New.Numcontrato, :old.Numcontrato)
     And c.Statusnota = 'L';

  If inserting Or updating Then
  
    If Nvl(:new.Kitservicos, 'N') = 'S' And Nvl(:new.Nunota, 0) > 0 Then
      Ad_Pkg_Var.Errmsg := 'Não é possível informar pedidos de captação para contratos apenas de serviços!';
      Raise_Application_Error(-20105, Ad_Fnc_Formataerro(Ad_Pkg_Var.Errmsg));
    End If;
  
    If (:new.RESPKITSERV = 'E' Or :new.RESPARMAZ = 'E') And :new.Codempresp Is Null Then
      Ad_Pkg_Var.Errmsg := 'Empresa responsável não informada!';
      Raise_Application_Error(-20105, Ad_Fnc_Formataerro(Ad_Pkg_Var.Errmsg));
    End If;
  
  End If;

  If Updating Or deleting Then
  
    If (:New.Dtcontrato != :Old.Dtcontrato) Or (:New.Codemp != :Old.Codemp) Or (:New.Codparc != :Old.Codparc) Or
       (:New.Codnat != :Old.Codnat) Or (:New.Codmoeda != :Old.Codmoeda) Or (:New.Codcencus != :Old.Codcencus) Or
       (:New.Ativo != :Old.Ativo) Or (:New.Codtdc != :Old.Codtdc) Or (:New.Tipoarm != :Old.Tipoarm) Or
       (:New.Codsaf != :Old.Codsaf) Or (:New.Codusu != :Old.Codusu) Or (:New.Codgpc != :Old.Codgpc) Or
       (:New.Codproj != :Old.Codproj) Or (:New.Codprod != :Old.Codprod) Or (:New.Codserv != :Old.Codserv) Or
      --(:new.nunota  !=  :old.nunota ) Or
       (:New.Tipcobkit != :Old.Tipcobkit) Or (:New.Respquebratec != :Old.Respquebratec) Or
       (:New.Respkitserv != :Old.Respkitserv) Or (:New.Codempresp != :Old.Codempresp) Or
       (:New.Resparmaz != :Old.Resparmaz) Or (:New.Unidconversao != :Old.Unidconversao) Or
       (:New.Qtdisencao != :Old.Qtdisencao) Or (:New.Tipoarea != :Old.Tipoarea) Or
       (:New.Areatotal != :Old.Areatotal) Or (:New.Areaplant != :Old.Areaplant) Or
       (:New.Qtdprevista != :Old.Qtdprevista) Or (:New.Dtinicioisencao != :Old.Dtinicioisencao) Or
       (:New.Dtfimisencao != :Old.Dtfimisencao) Or (:New.Valor != :Old.Valor) Or (:New.Origem != :Old.Origem) Or
       (:New.Kitservicos != :Old.Kitservicos)
    --(:new.numcontratocpa !=  :old.numcontratocpa) Or
     Then
    
      -- impede alteração
      If i > 0 Then
        Ad_Pkg_Var.Errmsg := 'Não é possível editar contratos que já possuem pedidos/notas geradas!';
        Raise_Application_Error(-20105, Ad_Fnc_Formataerro(Ad_Pkg_Var.Errmsg));
      End If;
    
    End If;
  
  End If;
End;
/
