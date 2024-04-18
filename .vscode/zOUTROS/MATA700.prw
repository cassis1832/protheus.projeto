#INCLUDE "PROTHEUS.CH"
#INCLUDE "TBICONN.CH"

//===============================================================//
//	EXECAUTO de previsão de vendas								 //
//===============================================================//
User Function MATA700()

	Local lOk := .T.
	Local aDados := {}
	Local nOpcao := 4 // Inclusão = 3 // Alteração = 4 // Exclusão = 5

	PRIVATE lMsErroAuto := .F.
	PRIVATE lAutoErrNoFile := .T.


	//===============================================================//
	//                     Abertura do ambiente                      //
	//===============================================================//

	ConOut(Repl("-",80))

	PREPARE ENVIRONMENT EMPRESA "99" FILIAL "01" MODULO "FAT" TABLES "SB1","SC4"

	//===============================================================//
	//              Verificação do ambiente para teste               //
	//===============================================================//

	dbSelectArea("SB1")
	dbSetOrder(1)

	If !SB1->(MsSeek(xFilial("SB1")+"Cod_Produto"))   //Campo B1_COD - Verifica se o produto existe.
		lOk := .F.
		ConOut("Necessario cadastrar Produto: Cod_Produto")
	EndIf

	ConOut("Inicio: "+Time())

	//===============================================================//
	//                          INCLUSÃO                             //
	//===============================================================//

	If lOk .and. nOpcao == 3
		ConOut(PadC("Teste de Inclusao da Previsao de Vendas",80))

		aadd(aDados,{"C4_PRODUTO"  ,"Cod_Produto"       ,Nil})  //Campo B1_COD
		aadd(aDados,{"C4_LOCAL"    ,"01"                ,Nil})
		aadd(aDados,{"C4_DOC"      ,"Desc_Produto"      ,Nil})  //Campo B1_DESC
		aadd(aDados,{"C4_QUANT"    ,1                   ,Nil})
		aadd(aDados,{"C4_VALOR"    ,1                   ,Nil})
		aadd(aDados,{"C4_DATA"     ,Date()              ,Nil})  //Pode ser utilizado da seguinte forma [ Date() +10 ] para somar a data atual até chegar a desejada.
		aadd(aDados,{"C4_OBS"      ,"TESTE"             ,Nil})

		MATA700(aDados,3)

		If !lMsErroAuto
			ConOut("Inclusão realizada com sucesso!")
		Else
			aErro := GetAutoGRLog()
			cErro := "Nao foi possivel realizar inclusao"
			Conout( cErro )
		EndIf

		//===============================================================//
		//                          ALTERAÇÃO                            //
		//===============================================================//

	ElseIf lOk .and. nOpcao == 4
		aDados := {}
		ConOut(PadC("Teste de Alteracao da Previsao de Vendas",80))

		//NÃO é possível fazer alteração de data, é necessário que a data esteja igual a de inclusão.

		aadd(aDados,{"C4_PRODUTO"   ,"Cod_Produto"     ,Nil})  //Campo B1_COD - Necessário que o campo esteja exatamente igual ao banco.
		aadd(aDados,{"C4_LOCAL"     ,"01"              ,Nil})
		aadd(aDados,{"C4_DOC"       ,"Desc_Produto"    ,Nil})  //Campo B1_DESC - Necessário que o campo esteja exatamente igual ao banco.
		aadd(aDados,{"C4_QUANT"     ,20                ,Nil})
		aadd(aDados,{"C4_VALOR"     ,20                ,Nil})
		aadd(aDados,{"C4_DATA"      ,Date()            ,Nil})  //É necessário que a data esteja igual a de inclusão.
		aadd(aDados,{"C4_OBS"       ,"TESTE"           ,Nil})

		MATA700(aDados,4)

		If !lMsErroAuto
			ConOut("Alteracao realizada com sucesso! ")
		Else
			aErro := GetAutoGRLog()
			cErro := "Nao foi possivel realizar alteracao!"
			Conout( cErro )
		EndIf

		//===============================================================//
		//                           EXCLUSÃO                            //
		//===============================================================//

	ElseIf lOk .and. nOpcao == 5
		aDados := {}
		ConOut(PadC("Teste de Exclusao da Previsão de Vendas",80))

		aadd(aDados,{"C4_PRODUTO"   ,"Cod_Produto"     ,Nil})   //Campo B1_COD - Necessário que o campo esteja exatamente igual ao banco.
		aadd(aDados,{"C4_DATA"      ,Date()            ,Nil})   //Necessário colocar data, pois podem existir varias previsões de
		//venda do mesmo produto com datas diferentes.
		MATA700(aDados,5)

		If !lMsErroAuto
			ConOut("Exclusao realizada com sucesso! ")
		Else
			aErro := GetAutoGRLog()
			cErro := "Nao foi possivel realizar exclusao!"
			Conout( cErro )
		EndIf
	EndIf

	ConOut("Fim : "+Time())

	RESET ENVIRONMENT

Return(.T.)
