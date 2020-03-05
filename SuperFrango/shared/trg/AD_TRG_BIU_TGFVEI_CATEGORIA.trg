Create Or Replace Trigger AD_TRG_BIU_TGFVEI_CATEGORIA
	Before Insert Or Update On tgfvei
	For Each Row
Declare
	-- local variables here
Begin

	/***************************************************************************
  * Autor: Marcus Rangel
  * Obejtivo: Trigger criada para preencher a categoria quando somente o 
  * campo texto for utilizado.
  **************************************************************************/
	If :old.Ad_Codcat Is Null Or :old.Ad_Codcat = 0 Then
	
		If Upper(:new.categoria) Like '%3/4%' And Upper(:new.categoria) Not Like '%ESPECIAL%' And
			 Upper(:new.categoria) Not Like '%EXTRA%' And Upper(:new.categoria) Not Like '%FS%' And
			 Upper(:new.categoria) Not Like '%SUPER%' And :new.ad_codcat Is Null Then
			:new.Ad_Codcat := 5;
		Elsif Upper(:new.Categoria) Like '%3/4%ESPECIAL%' Then
			:new.Ad_Codcat := 7;
		Elsif Upper(:new.Categoria) Like '%3/4%EXTRA%' Then
			:new.Ad_Codcat := 8;
		Elsif Upper(:new.Categoria) Like '%3/4%FS%' Then
			:new.Ad_Codcat := 10;
		Elsif Upper(:new.Categoria) Like '%3/4%SUPER%' Then
			:new.Ad_Codcat := 6;
		Elsif Upper(:new.categoria) Like '%FURGAO%' And
					Upper(:new.categoria) Not Like '%FURGAO%ESPECIAL%' Then
			:new.Ad_Codcat := 11;
		Elsif Upper(:new.categoria) Like '%FURGAO%ESPECIAL%' Then
			:new.Ad_Codcat := 12;
		Elsif Upper(:new.categoria) Like '%BITREM%' Then
			:new.Ad_Codcat := 20;
		Elsif rtrim(ltrim(Upper(:new.categoria))) = 'CARRETA' Then
			:new.Ad_Codcat := 1;
		Elsif Upper(:new.categoria) Like '%CARRETA%LS%' Then
			:new.Ad_Codcat := 9;
		Elsif Upper(:new.categoria) Like '%CARRETA%VAND%' Then
			:new.Ad_Codcat := 4;
		Elsif Upper(:new.Categoria) Like '%TRUCK%' And Upper(:new.Categoria) Not Like '%TRUCK%SILO%' And
					Upper(:new.Categoria) Not Like '%TRUCK%GAOILA%' Then
			:new.Ad_Codcat := 3;
		Elsif Upper(:new.Categoria) Like '%TRUCK%SILO%' Then
			:new.Ad_Codcat := 16;
		Elsif Upper(:new.Categoria) Like '%TRUCK%GAOILA%' Then
			:new.Ad_Codcat := 15;
		Elsif Upper(:new.Categoria) Like '%TRUCÃO%' And Upper(:new.Categoria) Not Like '%TRUCÃO%SILO%' And
					Upper(:new.Categoria) Not Like '%TRUCÃO%GAOILA%' Then
			:new.Ad_Codcat := 17;
		Elsif Upper(:new.Categoria) Like '%TRUCÃO%SILO%' Then
			:new.Ad_Codcat := 18;
		Elsif Upper(:new.Categoria) Like '%TRUCÃO%GAOILA%' Then
			:new.Ad_Codcat := 19;
		Elsif Upper(:new.Categoria) Like '%TOCO%' Then
			:new.Ad_Codcat := 2;
		Elsif Upper(:new.Categoria) Like '%RODOTREM%' Then
			:new.Ad_Codcat := 13;
		Elsif Upper(:new.Categoria) Like '%ROLL%ON%' Then
			:new.Ad_Codcat := 14;
		Elsif Upper(:new.Categoria) Like '%PARTIC%' Then
			:new.Ad_Codcat := 23;
		Elsif Upper(:new.Categoria) Like '%CONTAINER%' Then
			:new.Ad_Codcat := 26;
		End If;
	
	End If;

End AD_TRG_BIU_TGFVEI_CATEGORIA;
/
