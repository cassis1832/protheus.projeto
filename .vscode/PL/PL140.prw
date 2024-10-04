#Include 'Protheus.ch'
#Include 'FWMVCDef.ch'

/*/{Protheus.doc} PL140
Função: Consulta de estoque por tipo de item
@author Assis
@since 02/08/2024
@version 1.0
	@return Nil, Fução não tem retorno
	@example
	u_PL140()
/*/

Static cTitulo := "Posicao do Estoque"

User Function PL140()
	Local aArea 	:= FWGetArea()
	Local aCampos 	:= {}
	Local aColunas 	:= {}
	Local aPesquisa := {}
	Local aIndex 	:= {}
	Local oBrowse

	Private aRotina 	:= {}
	Private cTableName 	:= ""
	Private cAliasTT 	:= GetNextAlias()

	//Definicao do menu
	aRotina := MenuDef()

	//Campos da temporária
	aAdd(aCampos, {"TT_ID"		,"C", 36, 0})
	aAdd(aCampos, {"TT_PRODUTO"	,"C", 15, 0})
	aAdd(aCampos, {"TT_DESC"	,"C", 60, 0})
	aAdd(aCampos, {"TT_CLIENT"	,"C", 30, 0})
	aAdd(aCampos, {"TT_SALDO"	,"N", 14, 3})
	aAdd(aCampos, {"TT_UM"		,"C", 02, 3})
	aAdd(aCampos, {"TT_LOTE"	,"C", 10, 0})
	aAdd(aCampos, {"TT_EMPENHO"	,"N", 14, 3})
	aAdd(aCampos, {"TT_TIPO"	,"C",  3, 0})
	aAdd(aCampos, {"TT_ITEM"	,"C", 20, 0})
	aAdd(aCampos, {"TT_LE"		,"N", 12, 2})
	aAdd(aCampos, {"TT_PE"		,"N",  5, 0})
	aAdd(aCampos, {"TT_MRP"		,"C", 10, 0})

	//Cria a temporária
	oTempTable := FWTemporaryTable():New(cAliasTT)
	oTempTable:SetFields(aCampos)
	oTempTable:AddIndex("1", {"TT_ID"} )
	oTempTable:AddIndex("2", {"TT_PRODUTO", "TT_LOTE"} )
	oTempTable:AddIndex("3", {"TT_CLIENT" , "TT_PRODUTO", "TT_LOTE"} )
	oTempTable:Create()

	cTableName  := oTempTable:GetRealName()

	CargaTT()

	//Definindo as colunas que serão usadas no browse
	aAdd(aColunas, {"Produto"		, "TT_PRODUTO"	, "C", 08, 0, "@!"})
	aAdd(aColunas, {"Descricao"		, "TT_DESC"		, "C", 30, 0, "@!"})
	aAdd(aColunas, {"Tipo"			, "TT_TIPO"		, "C", 02, 0, "@!"})
	aAdd(aColunas, {"Cliente"		, "TT_CLIENT"	, "C", 15, 0, "@!"})
	aAdd(aColunas, {"Item Cliente"	, "TT_ITEM"		, "C", 20, 0, "@!"})
	aAdd(aColunas, {"Saldo"			, "TT_SALDO"	, "N", 10, 0, "@E 9,999,999.999"})
	aAdd(aColunas, {"UM"			, "TT_UM"		, "C", 02, 0, "@!"})
	aAdd(aColunas, {"Lote"			, "TT_LOTE"		, "C", 10, 0, "@!"})
	aAdd(aColunas, {"Empenho"		, "TT_EMPENHO"	, "N", 10, 0, "@E 9,999,999.999"})

	//Adiciona os indices para pesquisar
    /*
        [n,1] Título da pesquisa
        [n,2,n,1] LookUp
        [n,2,n,2] Tipo de dados
        [n,2,n,3] Tamanho
        [n,2,n,4] Decimal
        [n,2,n,5] Título do campo
        [n,2,n,6] Máscara
        [n,2,n,7] Nome Físico do campo - Opcional - é ajustado no programa
        [n,3] Pedido a pesquisa
        [n,4] Exibe na pesquisa
    */
	aAdd(aPesquisa, {"Produto"	, {{"", "C",  15, 0, "Produto" 	, "@!", "TT_PRODUTO"}} } )
	aAdd(aPesquisa, {"Cliente"	, {{"", "C",  06, 0, "Cliente" 	, "@!", "TT_CLIENT"}} } )

	aAdd(aIndex, {"TT_PRODUTO", "TT_LOTE"} )
	aAdd(aIndex, {"TT_CLIENT" , "TT_PRODUTO", "TT_LOTE"} )

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


/*/{Protheus.doc} MenuDef
Menu de opcoes na funcao PL140
@author Assis
@since 19/06/2024
@version 1.0
/*/
Static Function MenuDef()
	Local aRotina := {}
	ADD OPTION aRotina TITLE "Visualizar" ACTION "VIEWDEF.PL140" OPERATION 2 ACCESS 0
Return aRotina


/*/{Protheus.doc} ModelDef
Modelo de dados na funcao PL140
@author Assis
@since 19/06/2024
@version 1.0
/*/
Static Function ModelDef()
	Local oModel := Nil
	Local oStTMP := FWFormModelStruct():New()

	//Na estrutura, define os campos e a temporária
	oStTMP:AddTable(cAliasTT, {'TT_ID'}, "Temporaria")


	//Adiciona os campos da estrutura
	oStTmp:AddField("Produto"		,"Produto"		,"TT_PRODUTO"	,"C",06,00,Nil,Nil,{},.T.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_PRODUTO,'')" ), .T., .F., .F.)
	oStTmp:AddField("Descricao"		,"Descricao"	,"TT_DESC"		,"C",40,00,Nil,Nil,{},.T.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_DESC,'')" ),.F.,.F.,.F.)
	oStTmp:AddField("Tipo"			,"Tipo"			,"TT_TIPO"		,"C",02,00,Nil,Nil,{},.T.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_TIPO,'')" ), .T., .F., .F.)
	oStTmp:AddField("Cliente"		,"Cliente"		,"TT_CLIENT"	,"C",06,00,Nil,Nil,{},.T.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_CLIENT,'')" ), .T., .F., .F.)
	oStTmp:AddField("Item Cliente"	,"Item Cliente"	,"TT_ITEM"		,"C",20,00,Nil,Nil,{},.T.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_ITEM,'')" ), .T., .F., .F.)
	oStTmp:AddField("Saldo"			,"Saldo da OP"	,"TT_SALDO"		,"N",10,02,Nil,Nil,{},.F.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_SALDO,'')" ),.F.,.F.,.F.)
	oStTmp:AddField("UM"			,"UM"			,"TT_UM"		,"C",02,00,Nil,Nil,{},.F.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_UM,'')" ),.F.,.F.,.F.)
	oStTmp:AddField("Lote"			,"Lote"			,"TT_LOTE"		,"C",30,00,Nil,Nil,{},.T.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_LOTE,'')" ), .T., .F., .F.)
	oStTmp:AddField("Empenho"		,"Empenho"		,"TT_EMPENHO"	,"N",10,02,Nil,Nil,{},.F.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_EMPENHO,'')" ),.F.,.F.,.F.)

	//Instanciando o modelo
	oModel := MPFormModel():New("PL140M",/*bPre*/, /*bPos*/,/*bCommit*/,/*bCancel*/)
	oModel:AddFields("FORMTT",/*cOwner*/,oStTMP)
	oModel:SetPrimaryKey({'TT_ID'})
	oModel:SetDescription("Modelo de Dados do Cadastro ")
	oModel:GetModel("FORMTT"):SetDescription("Formulário do Cadastro ")
Return oModel

/*/{Protheus.doc} ViewDef
Visualizacao de dados na funcao PL140
@author Assis
@since 19/06/2024
@version 1.0
/*/

Static Function ViewDef()
	Local oView := Nil
	Local oModel := FWLoadModel("PL140")
	Local oStTMP := FWFormViewStruct():New()

	//Adicionando campos da estrutura
	oStTmp:AddField("TT_PRODUTO"	,"01","Codigo"		,"Codigo"		,Nil,"C","@!",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTmp:AddField("TT_DESC"		,"02","Descricao"	,"Descricao"	,Nil,"C","@!",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTmp:AddField("TT_TIPO"		,"03","Tipo"		,"Tipo"			,Nil,"C","@!",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTmp:AddField("TT_CLIENT"		,"04","Cliente"		,"Cliente"		,Nil,"C","@!",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTmp:AddField("TT_ITEM"		,"05","Item Cliente","Item Cliente"	,Nil,"C","@!",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTmp:AddField("TT_SALDO"		,"06","Saldo"		,"Saldo"		,Nil,"N","@E 9,999,999.99",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTmp:AddField("TT_UM"			,"07","UM"			,"UM"			,Nil,"C","@!",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTmp:AddField("TT_LOTE"		,"08","Lote"		,"Lote"			,Nil,"C","@!",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTmp:AddField("TT_EMPENHO"	,"09","Empenho"		,"Empenho"		,Nil,"N","@E 9,999,999.99",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)

	//Criando a view que será o retorno da função e setando o modelo da rotina
	oView := FWFormView():New()
	oView:SetModel(oModel)
	oView:AddField("VIEW_TT", oStTMP, "FORMTT")
	oView:CreateHorizontalBox("TELA",100)
	oView:EnableTitleView('VIEW_TT', 'Dados - ')
	oView:SetCloseOnOk({||.T.})
	oView:SetOwnerView("VIEW_TT","TELA")
Return oView


Static Function CargaTT()
	Local cAlias, cSql

	cSql := "SELECT B8_PRODUTO, B8_SALDO, B8_EMPENHO, B8_LOTECTL, "
	cSql += "		B1_DESC, B1_XCLIENT, B1_TIPO, B1_XITEM, B1_LE, B1_PE, B1_MRP, B1_UM "
	cSql += "  FROM " + RetSQLName("SB8") + " SB8 "

	cSql += " INNER JOIN " + RetSQLName("SB1") + " SB1 "
	cSql += "    ON B1_COD           = B8_PRODUTO "
	cSql += "   AND B1_FILIAL      	 = '" + xFilial("SB1") + "'"
	cSql += "   AND SB1.D_E_L_E_T_  <> '*' "

	cSql += " WHERE B8_SALDO      	<> 0 "
	cSql += "   AND B8_LOCAL      	<> '99'"
	cSql += "   AND B8_FILIAL      	 = '" + xFilial("SB8") + "'"
	cSql += "   AND SB8.D_E_L_E_T_  <> '*' "
	cSql += " ORDER BY B8_PRODUTO, B8_LOTECTL "
	cAlias := MPSysOpenQuery(cSql)

	While (cAlias)->(!EOF())
		cSql := "INSERT INTO " + cTableName + " ("
		cSql += "	TT_ID, TT_PRODUTO, TT_DESC, TT_CLIENT, TT_SALDO, TT_LOTE, TT_EMPENHO, TT_TIPO, TT_ITEM, TT_UM) VALUES ('"
		cSql += FWUUIDv4() 			 				+ "','"
		cSql += (cAlias)->B8_PRODUTO 				+ "','"
		cSql += (cAlias)->B1_DESC    				+ "','"
		cSql += (cAlias)->B1_XCLIENT 				+ "','"
		cSql += cValToChar((cAlias)->B8_SALDO) 		+ "','"
		cSql += (cAlias)->B8_LOTECTL   				+ "','"
		cSql += cValToChar((cAlias)->B8_EMPENHO) 	+ "','"
		cSql += (cAlias)->B1_TIPO   				+ "','"
		cSql += (cAlias)->B1_XITEM   				+ "','"
		cSql += (cAlias)->B1_UM   					+ "')"

		if TCSqlExec(cSql) < 0
			MsgInfo("Erro na execução da query:", "Atenção")
			MsgInfo(TcSqlError(), "Atenção2")
		endif

		(cAlias)->(DbSkip())
	End While
return
