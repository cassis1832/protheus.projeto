#Include 'Protheus.ch'
#Include 'FWMVCDef.ch'

/*/{Protheus.doc} PL280
Função: Follow-up de aquisicoes
@author Assis
@since 06/11/2024
@version 1.0
	@return Nil, Fução não tem retorno
	@example
	u_PL280()
/*/

Static cTitulo := "Follow-up de Materia Prima e Componentes"

User Function PL280()
	Local aArea 		:= FWGetArea()
	Local aCampos 		:= {}
	Local aColunas 		:= {}
	Local aPesquisa 	:= {}
	Local aIndex 		:= {}
	Local oBrowse

	Private aRotina 	:= {}
	Private cTableName 	:= ""
	Private cAliasTT 	:= GetNextAlias()
	Private nSeq		:= 0

	//Definicao do menu
	aRotina := MenuDef()

	//Campos da temporária
	aAdd(aCampos, {"TT_ID"		,"N", 12, 0})
	aAdd(aCampos, {"TT_NUMSC"	,"C", 06, 0})
	aAdd(aCampos, {"TT_NUMPC"	,"C", 06, 0})
	aAdd(aCampos, {"TT_PRODUTO"	,"C", 15, 0})
	aAdd(aCampos, {"TT_DESC"	,"C", 60, 0})
	aAdd(aCampos, {"TT_TIPO"	,"C", 03, 0})
	aAdd(aCampos, {"TT_CLIENT"	,"C", 30, 0})
	aAdd(aCampos, {"TT_ITEM"	,"C", 15, 0})
	aAdd(aCampos, {"TT_UM"		,"C", 02, 0})
	aAdd(aCampos, {"TT_COMPRA"	,"C", 06, 0})

	aAdd(aCampos, {"TT_EMISSAO"	,"D", 08, 0})
	aAdd(aCampos, {"TT_DATPRF"	,"D", 08, 0})
	aAdd(aCampos, {"TT_QUANT"	,"N", 10, 2})
	aAdd(aCampos, {"TT_QUJE"	,"N", 10, 2})
	aAdd(aCampos, {"TT_SALDO"	,"N", 10, 2})
	aAdd(aCampos, {"TT_CONS"	,"N", 10, 2})

	aAdd(aCampos, {"TT_DTENT"	,"D", 08, 0})

	aAdd(aCampos, {"TT_FORNECE"	,"C", 06, 0})
	aAdd(aCampos, {"TT_LOJA"	,"C", 02, 0})
	aAdd(aCampos, {"TT_NOME"	,"C", 30, 0})

	//Cria a temporária
	oTempTable := FWTemporaryTable():New(cAliasTT)
	oTempTable:SetFields(aCampos)
	oTempTable:AddIndex("2", {"TT_PRODUTO"} )
	oTempTable:AddIndex("3", {"TT_CLIENT" , "TT_PRODUTO"} )
	oTempTable:Create()

	cTableName  := oTempTable:GetRealName()

	SolCompra()
	PedCompra()
	Consumo()
	UltimaEntrada()

	//Definindo as colunas que serão usadas no browse
	aAdd(aColunas, {"Num. SC"		, "TT_NUMSC"	, "C", 06, 0, "@!"})
	aAdd(aColunas, {"Num. PC"		, "TT_NUMPC"	, "C", 06, 0, "@!"})
	aAdd(aColunas, {"Modo"			, "TT_COMPRA"	, "C", 06, 0, "@!"})
	aAdd(aColunas, {"Produto"		, "TT_PRODUTO"	, "C", 08, 0, "@!"})
	aAdd(aColunas, {"Descricao"		, "TT_DESC"		, "C", 30, 0, "@!"})
	aAdd(aColunas, {"Tipo"			, "TT_TIPO"		, "C", 02, 0, "@!"})
	aAdd(aColunas, {"Cliente"		, "TT_CLIENT"	, "C", 15, 0, "@!"})
	aAdd(aColunas, {"Item Cliente"	, "TT_ITEM"		, "C", 08, 0, "@!"})
	aAdd(aColunas, {"UM"			, "TT_UM"		, "C", 02, 0, "@!"})
	aAdd(aColunas, {"Emissao"		, "TT_EMISSAO"	, "D", 06, 0, "@!"})
	aAdd(aColunas, {"Entrega"		, "TT_DATPRF"	, "D", 06, 0, "@!"})
	aAdd(aColunas, {"Qt. Pedida"	, "TT_QUANT"	, "N", 08, 0, "@E 9,999,999.999"})
	aAdd(aColunas, {"Qt. Entregue"	, "TT_QUJE"		, "N", 08, 0, "@E 9,999,999.999"})
	aAdd(aColunas, {"Sld. Estoque"	, "TT_SALDO"	, "N", 08, 0, "@E 9,999,999.999"})
	aAdd(aColunas, {"Cons. Mes"		, "TT_CONS"		, "N", 08, 0, "@E 9,999,999.999"})
	aAdd(aColunas, {"Ult. Ent."		, "TT_DTENT"	, "D", 06, 0, "@!"})
	aAdd(aColunas, {"Fornec."		, "TT_FORNECE"	, "C", 05, 0, "@!"})


	aAdd(aPesquisa, {"Produto"	, {{"", "C",  15, 0, "Produto" 	, "@!", "TT_PRODUTO"}} } )
	aAdd(aPesquisa, {"Cliente"	, {{"", "C",  06, 0, "Cliente" 	, "@!", "TT_CLIENT"}} } )

	aAdd(aIndex, {"TT_PRODUTO"} )
	aAdd(aIndex, {"TT_CLIENT" , "TT_PRODUTO"} )

	//Criando o browse da temporária
	oBrowse := FWMBrowse():New()
	oBrowse:SetTemporary(.T.)
	oBrowse:SetAlias(oTempTable:getAlias())
	oBrowse:SetFields(aColunas)
	oBrowse:SetQueryIndex(aIndex)
	oBrowse:SetSeek(.T., aPesquisa)
	oBrowse:DisableDetails()
	oBrowse:SetDescription(cTitulo)
	oBrowse:SetUseFilter(.T.)

	oBrowse:Activate()

	oTempTable:Delete()
	FWRestArea(aArea)
Return Nil


Static Function MenuDef()
	Local aRotina := {}
	ADD OPTION aRotina TITLE "Visualizar" ACTION "VIEWDEF.PL280" OPERATION 2 ACCESS 0
Return aRotina


Static Function ModelDef()
	Local oModel := Nil
	Local oStTMP := FWFormModelStruct():New()

	//Na estrutura, define os campos e a temporária
	oStTMP:AddTable(cAliasTT, {'TT_ID'}, "Temporaria")

	//Adiciona os campos da estrutura
	oStTmp:AddField("Num. SC"		,"Num. SC"		,"TT_NUMSC"		,"C",06,00,Nil,Nil,{},.F.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_NUM,'')" ),.F.,.F.,.F.)
	oStTmp:AddField("Num. PC"		,"Num. PC"		,"TT_NUMPC"		,"C",06,00,Nil,Nil,{},.F.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_NUM,'')" ),.F.,.F.,.F.)
	oStTmp:AddField("Modo"			,"Modo"			,"TT_COMPRA"	,"C",06,00,Nil,Nil,{},.T.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_PRODUTO,'')" ), .T., .F., .F.)
	oStTmp:AddField("Produto"		,"Produto"		,"TT_PRODUTO"	,"C",06,00,Nil,Nil,{},.T.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_PRODUTO,'')" ), .T., .F., .F.)
	oStTmp:AddField("Descricao"		,"Descricao"	,"TT_DESC"		,"C",40,00,Nil,Nil,{},.T.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_DESC,'')" ),.F.,.F.,.F.)
	oStTmp:AddField("Tipo"			,"Tipo"			,"TT_TIPO"		,"C",02,00,Nil,Nil,{},.T.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_TIPO,'')" ), .T., .F., .F.)
	oStTmp:AddField("Cliente"		,"Cliente"		,"TT_CLIENT"	,"C",06,00,Nil,Nil,{},.T.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_CLIENT,'')" ), .T., .F., .F.)
	oStTmp:AddField("Item Cliente"	,"Item Cliente"	,"TT_ITEM"		,"C",15,00,Nil,Nil,{},.T.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_ITEM,'')" ), .T., .F., .F.)
	oStTmp:AddField("UM"			,"UM"			,"TT_UM"		,"C",02,00,Nil,Nil,{},.F.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_UM,'')" ),.F.,.F.,.F.)
	oStTmp:AddField("Dt. Emissao"	,"Dt. Emissao"	,"TT_EMISSAO"	,"D",08,00,Nil,Nil,{},.F.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_DATPRF,'')" ),.F.,.F.,.F.)
	oStTmp:AddField("Dt. Entrega"	,"Dt. Entrega"	,"TT_DATPRF"	,"D",08,00,Nil,Nil,{},.F.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_DATPRF,'')" ),.F.,.F.,.F.)
	oStTmp:AddField("Qt. Pedida"	,"Qt. Pedids"	,"TT_QUANT"		,"N",10,02,Nil,Nil,{},.F.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_QUANT,'')" ),.F.,.F.,.F.)
	oStTmp:AddField("Qt. Entregue"	,"Qt. Entregue"	,"TT_QUJE"		,"N",10,02,Nil,Nil,{},.F.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_QUJE,'')" ),.F.,.F.,.F.)
	oStTmp:AddField("Sld. Estoque"	,"Sld. Estoque"	,"TT_SALDO"		,"N",10,02,Nil,Nil,{},.F.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_QUJE,'')" ),.F.,.F.,.F.)
	oStTmp:AddField("Cons. Mes"		,"Cons. Mes"	,"TT_CONS"		,"N",10,02,Nil,Nil,{},.F.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_QUJE,'')" ),.F.,.F.,.F.)
	oStTmp:AddField("Ult. Ent."		,"Ult. Ent."	,"TT_DTENT"		,"D",08,00,Nil,Nil,{},.F.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_DTENT,'')" ),.F.,.F.,.F.)
	oStTmp:AddField("Cod. Forn."	,"Cod. Forn."	,"TT_FORNECE"	,"N",10,02,Nil,Nil,{},.F.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_FORNECE,'')" ),.F.,.F.,.F.)

	//Instanciando o modelo
	oModel := MPFormModel():New("PL280M",/*bPre*/, /*bPos*/,/*bCommit*/,/*bCancel*/)
	oModel:AddFields("FORMTT",/*cOwner*/,oStTMP)
	oModel:SetPrimaryKey({'TT_ID'})
	oModel:SetDescription("Modelo de Dados do Cadastro ")
	oModel:GetModel("FORMTT"):SetDescription("Formulário do Cadastro ")
Return oModel


Static Function ViewDef()
	Local oView := Nil
	Local oModel := FWLoadModel("PL280")
	Local oStTMP := FWFormViewStruct():New()

	//Adicionando campos da estrutura
	oStTmp:AddField("TT_NUMSC"		,"01","Num. SC"		,"Num. SC"		,Nil,"N","@E 9,999,999.99",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTmp:AddField("TT_NUMPC"		,"02","Num. PC"		,"Num. PC"		,Nil,"N","@E 9,999,999.99",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTmp:AddField("TT_COMPRA"		,"03","Modo"		,"Modo"			,Nil,"C","@!",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTmp:AddField("TT_PRODUTO"	,"04","Codigo"		,"Codigo"		,Nil,"C","@!",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTmp:AddField("TT_DESC"		,"05","Descricao"	,"Descricao"	,Nil,"C","@!",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTmp:AddField("TT_TIPO"		,"06","Tipo"		,"Tipo"			,Nil,"C","@!",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTmp:AddField("TT_CLIENT"		,"07","Cliente"		,"Cliente"		,Nil,"C","@!",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTmp:AddField("TT_ITEM"		,"08","Item Cliente","Item Cliente"	,Nil,"C","@!",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTmp:AddField("TT_UM"			,"10","UM"			,"UM"			,Nil,"C","@!",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTmp:AddField("TT_EMISSAO"	,"11","Dt. Emissao"	,"Dt. Emissao"	,Nil,"D","@!",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTmp:AddField("TT_DATPRF"		,"16","Dt. Entrega"	,"Dt. Entrega"	,Nil,"D","@!",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTmp:AddField("TT_QUANT"		,"17","Qt. Pedida"	,"Qt. Pedida"	,Nil,"N","@E 9,999,999.99",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTmp:AddField("TT_QUJE"		,"18","Qt. Entregue","Qt. Entregue"	,Nil,"N","@E 9,999,999.99",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTmp:AddField("TT_SALDO"		,"19","Sld. Estoque","Sld. Estoque"	,Nil,"N","@E 9,999,999.99",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTmp:AddField("TT_CONS"		,"20","Cons. Mes"	,"Cons. Mes"	,Nil,"N","@E 9,999,999.99",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTmp:AddField("TT_DTENT"		,"21","Ult. Ent."	,"Ult. Ent."	,Nil,"D","@!",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTmp:AddField("TT_FORNECE"	,"22","Cod. Forn."	,"Cod. Forn."	,Nil,"C","@!",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)

	//Criando a view que será o retorno da função e setando o modelo da rotina
	oView := FWFormView():New()
	oView:SetModel(oModel)
	oView:AddField("VIEW_TT", oStTMP, "FORMTT")
	oView:CreateHorizontalBox("TELA",100)
	oView:EnableTitleView('VIEW_TT', 'Dados - ')
	oView:SetCloseOnOk({||.T.})
	oView:SetOwnerView("VIEW_TT","TELA")
Return oView


Static Function SolCompra()
	Local cAlias, cSql, cModo

	cSql := "SELECT C1_NUM, C1_PRODUTO, C1_QUANT, C1_DATPRF, C1_EMISSAO, C1_PEDIDO, C1_QUJE, "
	cSql += "		B1_COD, B1_DESC, B1_XCLIENT, B1_TIPO, B1_XITEM, B1_LE, B1_PE, B1_MRP, B1_UM, B1_ESTSEG, B1_TIPO, B1_AGREGCU "
	cSql += "  FROM " + RetSQLName("SC1") + " SC1 "

	cSql += " INNER JOIN " + RetSQLName("SB1") + " SB1 "
	cSql += "    ON B1_COD           = C1_PRODUTO "
	cSql += "   AND B1_TIPO         IN ('PA','PI','PP','BN', 'MP') "
	cSql += "   AND B1_FILIAL      	 = '" + xFilial("SB1") + "'"
	cSql += "   AND SB1.D_E_L_E_T_  <> '*' "

	cSql += " WHERE C1_FILIAL      	 = '" + xFilial("SC1") + "'"
	cSql += "   AND C1_PEDIDO  		 = '' "
	cSql += "   AND C1_RESIDUO 		 = '' "
	cSql += "   AND SC1.D_E_L_E_T_  <> '*' "
	cSql += " ORDER BY C1_PRODUTO, C1_DATPRF "
	cAlias := MPSysOpenQuery(cSql)

	While (cAlias)->(!EOF())
		nSeq++

		if (cAlias)->B1_AGREGCU == '1'
			cModo := 'Terc.'
		else
			cModo := 'Compra'
		endif

		cSql := "INSERT INTO " + cTableName + " ("
		cSql += "	TT_ID, TT_PRODUTO, TT_DESC, TT_TIPO, TT_UM, TT_CLIENT, TT_ITEM, TT_COMPRA, TT_DATPRF, TT_QUANT, TT_QUJE, TT_EMISSAO, TT_NUMPC, TT_NUMSC) VALUES ('"
		cSql += cValToChar(nSeq)					+ "','"
		cSql += (cAlias)->B1_COD 					+ "','"
		cSql += (cAlias)->B1_DESC    				+ "','"
		cSql += (cAlias)->B1_TIPO    				+ "','"
		cSql += (cAlias)->B1_UM    					+ "','"
		cSql += (cAlias)->B1_XCLIENT 				+ "','"
		cSql += (cAlias)->B1_XITEM 					+ "','"
		cSql += cModo 								+ "','"

		cSql += (cAlias)->C1_DATPRF   				+ "','"
		cSql += cValToChar((cAlias)->C1_QUANT) 		+ "','"
		cSql += cValToChar((cAlias)->C1_QUJE) 		+ "','"
		cSql += (cAlias)->C1_EMISSAO   				+ "','"
		cSql += (cAlias)->C1_PEDIDO   				+ "','"
		cSql += (cAlias)->C1_NUM   					+ "')"

		if TCSqlExec(cSql) < 0
			MsgInfo("Erro na execução da query:", "Atenção 1")
			MsgInfo(TcSqlError(), "Atenção1")
		endif

		(cAlias)->(DbSkip())
	End While

	(cAlias)->(DBCLOSEAREA())
return


Static Function PedCompra()
	// PC
	cSql := "SELECT C7_NUM, C7_TIPO, C7_PRODUTO, C7_QUANT, C7_QUJE, C7_RESIDUO, C7_ENCER, C7_PRECO, C7_TOTAL, C7_NUMSC, C7_DATPRF, C7_FORNECE, C7_EMISSAO,  "
	cSql += "		B1_COD, B1_DESC, B1_XCLIENT, B1_TIPO, B1_XITEM, B1_UM, B1_AGREGCU  "
	cSql += "  FROM " + RetSQLName("SC7") + " SC7 "

	cSql += " INNER JOIN " + RetSQLName("SB1") + " SB1 "
	cSql += "    ON B1_COD           = C7_PRODUTO "
	cSql += "   AND B1_TIPO         IN ('PA','PI','PP','BN', 'MP') "
	cSql += "   AND B1_FILIAL      	 = '" + xFilial("SB1") + "'"
	cSql += "   AND SB1.D_E_L_E_T_  <> '*' "

	cSql += " WHERE C7_FILIAL      	 = '" + xFilial("SC7") + "'"
	cSql += "   AND C7_ENCER   		 = '' "
	cSql += "   AND C7_RESIDUO   	 = '' "
	cSql += "   AND C7_QUANT   		 > C7_QUJE "
	cSql += "   AND SC7.D_E_L_E_T_  <> '*' "
	cSql += " ORDER BY C7_PRODUTO, C7_DATPRF "
	cAlias := MPSysOpenQuery(cSql)

	While (cAlias)->(!EOF())
		nSeq++

		if (cAlias)->B1_AGREGCU == '1'
			cModo := 'Terc.'
		else
			cModo := 'Compra'
		endif

		cSql := "INSERT INTO " + cTableName + " ("
		cSql += "	TT_ID, TT_PRODUTO, TT_DESC, TT_TIPO, TT_UM, TT_CLIENT, TT_ITEM, TT_COMPRA, TT_DATPRF, TT_QUANT, TT_QUJE, TT_EMISSAO, TT_FORNECE, TT_NUMPC, TT_NUMSC) VALUES ('"
		cSql += cValToChar(nSeq)					+ "','"
		cSql += (cAlias)->B1_COD 					+ "','"
		cSql += (cAlias)->B1_DESC    				+ "','"
		cSql += (cAlias)->B1_TIPO    				+ "','"
		cSql += (cAlias)->B1_UM    					+ "','"
		cSql += (cAlias)->B1_XCLIENT 				+ "','"
		cSql += (cAlias)->B1_XITEM 					+ "','"
		cSql += cModo 								+ "','"

		cSql += (cAlias)->C7_DATPRF   				+ "','"
		cSql += cValToChar((cAlias)->C7_QUANT) 		+ "','"
		cSql += cValToChar((cAlias)->C7_QUJE) 		+ "','"
		cSql += (cAlias)->C7_EMISSAO   				+ "','"
		cSql += (cAlias)->C7_FORNECE   				+ "','"
		cSql += (cAlias)->C7_NUM 	  				+ "','"
		cSql += (cAlias)->C7_NUMSC 					+ "')"

		if TCSqlExec(cSql) < 0
			MsgInfo("Erro na execução da query:", "Atenção 2")
			MsgInfo(TcSqlError(), "Atenção 2")
		endif

		(cAlias)->(DbSkip())
	End While

	(cAlias)->(DBCLOSEAREA())
return


Static Function Consumo()
	Local cSql	:= ''

	// Consumo medio mensal
	cSql := "UPDATE " + cTableName
	cSql += "   SET TT_CONS = B3_MEDIA "
	cSql += "  FROM " + cTableName

	cSql += " INNER JOIN " + RetSQLName("SB3") + " SB3 "
	cSql += "    ON B3_COD           = TT_PRODUTO "
	cSql += "   AND B3_FILIAL      	 = '" + xFilial("SB3") + "'"
	cSql += "   AND SB3.D_E_L_E_T_  <> '*' "

	if TCSqlExec(cSql) < 0
		MsgInfo("Erro na execução da query update 3:", "Atenção 3")
		MsgInfo(TcSqlError(), "Atenção 3")
	endif

	// Saldo atual de estoque
	cSql := "UPDATE " + cTableName
	cSql += "   SET TT_SALDO = B2_QATU "
	cSql += "  FROM " + cTableName

	cSql += " INNER JOIN " + RetSQLName("SB2") + " SB2 "
	cSql += "    ON B2_COD           = TT_PRODUTO "
	cSql += "   AND B2_FILIAL      	 = '" + xFilial("SB2") + "'"
	cSql += "   AND SB2.D_E_L_E_T_  <> '*' "

	if TCSqlExec(cSql) < 0
		MsgInfo("Erro na execução da query update 4:", "Atenção 4")
		MsgInfo(TcSqlError(), "Atenção 4")
	endif

return


Static Function UltimaEntrada()
	Local cSql	:= ''

	cSql := "UPDATE " + cTableName
	cSql += "   SET TT_DTENT = "
	cSql += " (SELECT TOP 1 DS_EMISSA "
	cSql += "	 FROM " + RetSQLName("SDS") + " SDS, " + RetSQLName("SDT") + " SDT
	cSql += "   WHERE DS_DOC 		 = DT_DOC "
	cSql += "     AND DT_COD         = TT_PRODUTO "
	cSql += "     AND DS_FILIAL    	 = '" + xFilial("SDS") + "'"
	cSql += "     AND DT_FILIAL    	 = '" + xFilial("SDT") + "'"
	cSql += "     AND SDS.D_E_L_E_T_  <> '*' "
	cSql += "     AND SDT.D_E_L_E_T_  <> '*' "
	cSql += "   ORDER BY DS_EMISSA DESC) "

	if TCSqlExec(cSql) < 0
		MsgInfo("Erro na execução da query update xml", "Atenção XML")
		MsgInfo(TcSqlError(), "Atenção XML")
	endif

return
