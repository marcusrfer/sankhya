PL/SQL Developer Test script 3.0
44
declare 
  Type type_regioes_rec Is Record(
	 codparc Number,
	 codreg Number,
	 codregfre Number);
	 
	Type type_regioes_tab Is Table Of type_regioes_rec;
	
	t type_regioes_tab := type_regioes_tab();
Begin
	
  t.extend;
  Select p.codparc, p.codreg, ad_pkg_fre.get_codregfrete(p.codparc) codregfrete
	Bulk Collect Into t
	From tgfpar p
	Join tsireg r On p.codreg = r.codreg
 Where p.ativo = 'S'
	 And p.cliente = 'S'
	 And p.codvend > 0
	 And Nvl(p.codreg, 0) > 0
	 And Nvl(p.ad_codregfre, 0) = 0
	 And p.codreg != 6000000
	 And r.analitica = 'S';
  
	
 Execute Immediate 'alter trigger	TRG_INC_UPD_TGFPAR_SF disable';
	
 Begin
 Forall x In t.first .. t.last Save Exceptions
   Update tgfpar 
	  Set ad_codregfre = t(x).codregfre
	 Where codparc = t(x).codparc
	  And codreg = t(x).codreg;
	Exception
		When Others Then
			For z In 1 .. Sql%Bulk_Exceptions.count
				Loop
					Dbms_Output.put_Line( 'Erro nos índices: '||Sql%Bulk_Exceptions(z).error_index||' - '||Sqlerrm(-Sql%Bulk_Exceptions(z).error_code) );
				End Loop;
		End;

 Execute Immediate 'alter trigger	TRG_INC_UPD_TGFPAR_SF enable';
	
end;
0
0
