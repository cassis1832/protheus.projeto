#Include 'Protheus.ch'
#Include 'FWMVCDef.ch'

/*/{Protheus.doc} PL090
Função: Pedidos de Vendas Abertos
@author Assis
@since 21/06/2024
@version 1.0
	@return Nil, Fução não tem retorno
	@example
	u_PL090()
/*/

Static cTitulo := "Pedidos de Vendas Abertos"

User Function PL090()
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
	aAdd(aCampos, {"ID"			,"C", 36, 0})
	aAdd(aCampos, {"TT_CLIENT"	,"C", 10, 0})
	aAdd(aCampos, {"TT_NOME"	,"C", 30, 0})
	aAdd(aCampos, {"TT_NUM"		,"C", 11, 0})
	aAdd(aCampos, {"TT_ITEM"	,"C", 02, 0})
	aAdd(aCampos, {"TT_PRODUTO"	,"C", 15, 0})
	aAdd(aCampos, {"TT_DESC"	,"C", 60, 0})
	aAdd(aCampos, {"TT_EMISSAO"	,"D", 10, 0})
	aAdd(aCampos, {"TT_ENTREG"	,"D", 10, 0})
	aAdd(aCampos, {"TT_QTDVEN"	,"N", 14, 3})
	aAdd(aCampos, {"TT_QTDENT"	,"N", 14, 3})
	aAdd(aCampos, {"TT_SALDO"	,"N", 14, 3})

	//Cria a temporária
	oTempTable := FWTemporaryTable():New(cAliasTT)
	oTempTable:SetFields(aCampos)
	oTempTable:AddIndex("1", {"ID"} )
	oTempTable:AddIndex("2", {"TT_ENTREG"	, "TT_PRODUTO"} )
	oTempTable:AddIndex("3", {"TT_PRODUTO"	, "TT_ENTREG"} )
	oTempTable:AddIndex("4", {"TT_CLIENT"	, "TT_ENTREG"} )
	oTempTable:AddIndex("6", {"TT_NUM"} )
	oTempTable:Create()

	cTableName  := oTempTable:GetRealName()

	CargaTT()

	//Definindo as colunas que serão usadas no browse
	aAdd(aColunas, {"Cliente"		, "TT_CLIENT"	, "C", 07, 0, "@!"})
	aAdd(aColunas, {"Nome"			, "TT_NOME"		, "C", 20, 0, "@!"})
	aAdd(aColunas, {"Produto"		, "TT_PRODUTO"	, "C", 08, 0, "@!"})
	aAdd(aColunas, {"Descricao"		, "TT_DESC"		, "C", 25, 0, "@!"})
	aAdd(aColunas, {"Pedido"		, "TT_NUM"		, "C", 06, 0, "@!"})
	aAdd(aColunas, {"Item"			, "TT_ITEM"		, "C", 02, 0, "@!"})
	aAdd(aColunas, {"Emissao"		, "TT_EMISSAO"	, "D", 06, 0, "@D"})
	aAdd(aColunas, {"Entrega"		, "TT_ENTREG"	, "D", 06, 0, "@D"})
	aAdd(aColunas, {"Quant."		, "TT_QTDVEN"	, "N", 08, 0, "@E 9,999,999.999"})
	aAdd(aColunas, {"Qt. Entregue"	, "TT_QTDENT"	, "N", 08, 0, "@E 9,999,999.999"})
	aAdd(aColunas, {"Saldo"			, "TT_SALDO"	, "N", 08, 0, "@E 9,999,999.999"})

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
	aAdd(aPesquisa, {"Cliente"	, {{"", "C",  1, 0, "Cliente" , "@!", "TT_CLIENT"}} } )
	aAdd(aPesquisa, {"Produto"	, {{"", "C",  6, 0, "Produto" , "@!", "TT_PRODUTO"}} } )

	aAdd(aIndex, {"TT_ENTREG", "TT_NUM"} )

	//Criando o browse da temporária
	oBrowse := FWMBrowse():New()
	oBrowse:SetAlias(cAliasTT)
	oBrowse:SetQueryIndex(aIndex)
	oBrowse:SetTemporary(.T.)
	oBrowse:SetFields(aColunas)
	oBrowse:DisableDetails()
	oBrowse:SetDescription(cTitulo)
	oBrowse:SetSeek(.T., aPesquisa)
	//oBrowse:SetItemHeaderClick({"TT_PROD"}) não funciona no FWMBROWSE
	oBrowse:Activate()

	oTempTable:Delete()
	FWRestArea(aArea)
Return Nil


/*/{Protheus.doc} MenuDef
Menu de opcoes na funcao pl090
@author Assis
@since 19/06/2024
@version 1.0
/*/
Static Function MenuDef()
	Local aRotina := {}
	ADD OPTION aRotina TITLE "Visualizar" ACTION "VIEWDEF.PL090" OPERATION 1 ACCESS 0
Return aRotina


/*/{Protheus.doc} ModelDef
Modelo de dados na funcao pl090
@author Assis
@since 19/06/2024
@version 1.0
/*/
Static Function ModelDef()
	Local oModel := Nil
	Local oStTMP := FWFormModelStruct():New()

	//Na estrutura, define os campos e a temporária
	oStTMP:AddTable(cAliasTT, {'TT_CLIENT', 'TT_PROD', 'TT_DESC', 'TT_NUM', 'TT_ENTREG', 'TT_FIM', 'TT_QTDVEN', 'TT_QTENT', 'TT_SALDO', 'TT_TPOP', 'TT_EMISSAO'}, "Temporaria")

	//Adiciona os campos da estrutura
	oStTmp:AddField("Cliente"		,"Cliente"		,"TT_CLIENT"	,"C",06,00,Nil,Nil,{},.T.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_CLIENT,'')" ), .T., .F., .F.)
	oStTmp:AddField("Nome"			,"Nome"			,"TT_Nome"		,"C",30,00,Nil,Nil,{},.T.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_NOME,'')" ), .T., .F., .F.)
	oStTmp:AddField("Codigo"		,"Codigo"		,"TT_PRODUTO"	,"C",06,00,Nil,Nil,{},.T.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_PRODUTO,'')" ), .T., .F., .F.)
	oStTmp:AddField("Descricao"		,"Descricao"	,"TT_DESC"		,"C",40,00,Nil,Nil,{},.T.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_DESC,'')" ),.F.,.F.,.F.)
	oStTmp:AddField("Pedido"		,"Pedido"		,"TT_NUM"		,"C",11,00,Nil,Nil,{},.F.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_NUM,'')" ),.F.,.F.,.F.)
	oStTmp:AddField("Emissao"		,"Emissao"		,"TT_EMISSAO"	,"D",08,00,Nil,Nil,{},.F.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_EMISSAO,'')" ),.F.,.F.,.F.)
	oStTmp:AddField("Entrega"		,"Data Entrega"	,"TT_ENTREG"	,"D",08,00,Nil,Nil,{},.F.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_ENTREG,'')" ),.F.,.F.,.F.)
	oStTmp:AddField("Quant."		,"Quantidade"	,"TT_QTDVEN"	,"N",10,02,Nil,Nil,{},.F.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_QTDVEN,'')" ),.F.,.F.,.F.)
	oStTmp:AddField("Qt. Entregue"	,"Entregue"		,"TT_QTDENT"	,"N",10,02,Nil,Nil,{},.F.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_QTDENT,'')" ),.F.,.F.,.F.)
	oStTmp:AddField("Saldo"			,"Saldo da OP"	,"TT_SALDO"		,"N",10,02,Nil,Nil,{},.F.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_SALDO,'')" ),.F.,.F.,.F.)

	//Instanciando o modelo
	oModel := MPFormModel():New("PL090M",/*bPre*/, /*bPos*/,/*bCommit*/,/*bCancel*/)
	oModel:AddFields("FORMTT",/*cOwner*/,oStTMP)
	oModel:SetPrimaryKey({'ID'})
	oModel:SetDescription("Modelo de Dados do Cadastro ")
	oModel:GetModel("FORMTT"):SetDescription("Formulário do Cadastro ")
Return oModel

/*/{Protheus.doc} ViewDef
Visualizacao de dados na funcao pl090
@author Assis
@since 19/06/2024
@version 1.0
/*/

Static Function ViewDef()
	Local oView := Nil
	Local oModel := FWLoadModel("PL090")
	Local oStTMP := FWFormViewStruct():New()

	//Adicionando campos da estrutura
	oStTmp:AddField("TT_CLIENT"		,"01","Cliente"		,"Cliente"		,Nil,"C","@!",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTmp:AddField("TT_NOME"		,"02","Nome"		,"Nome"			,Nil,"C","@!",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTmp:AddField("TT_PRODUTO"	,"03","Codigo"		,"Codigo"		,Nil,"C","@!",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTmp:AddField("TT_DESC"		,"04","Descricao"	,"Descricao"	,Nil,"C","@!",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTmp:AddField("TT_NUM"		,"05","Pedido"		,"Pedido"		,Nil,"C","@!",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTmp:AddField("TT_EMISSAO"	,"06","Emissao"		,"Emissao"		,Nil,"D","@D",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTmp:AddField("TT_ENTREG"		,"07","Data Entrega","Data Entrega"	,Nil,"D","@D",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTmp:AddField("TT_QTDVEN"		,"08","Quant."		,"Quantidade"	,Nil,"N","@E 9,999,999.99",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTmp:AddField("TT_QTDENT"		,"09","Prod."		,"Produzida"	,Nil,"N","@E 9,999,999.99",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTmp:AddField("TT_SALDO"		,"10","Saldo"		,"Saldo"		,Nil,"N","@E 9,999,999.99",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)

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

	// Carregar pedidos de vendas
	cSql := "SELECT C5_CLIENTE, C5_LOJACLI, C5_EMISSAO, C6_NUM, "
	cSql += " 	C6_ITEM, C6_PRODUTO, C6_ENTREG, C6_QTDVEN, C6_QTDENT, "
	cSql += "	(C6_QTDVEN - C6_QTDENT) AS C6_SALDO, B1_DESC, A1_NREDUZ "
	cSql += "  FROM " + RetSQLName("SC6") + " SC6 "

	cSql += " INNER JOIN " + RetSQLName("SC5") + " SC5 "
	cSql += "    ON C5_NUM          =  C6_NUM "
	cSql += " 	AND C5_NOTA         =  '' "
	cSql += "   AND C5_LIBEROK    	<> 'E' "

	cSql += " INNER JOIN " + RetSQLName("SA1") + " SA1 "
	cSql += "    ON A1_COD       	=  C5_CLIENTE "
	cSql += " 	AND A1_LOJA         =  C5_LOJACLI "

	cSql += " INNER JOIN " + RetSQLName("SB1") + " SB1 "
	cSql += "    ON B1_COD          =  C6_PRODUTO "

	cSql += " INNER JOIN " + RetSQLName("SF4") + " SF4 "
	cSql += "    ON F4_CODIGO      	=  C6_TES "
	cSql += "   AND B1_COD          =  C6_PRODUTO "
	cSql += "   AND F4_QTDZERO    	<> '1' "

	cSql += " WHERE C6_QTDENT      	<  C6_QTDVEN "
	cSql += "   AND C6_BLQ 			<> 'R' "

	cSql += "   AND A1_FILIAL      	=  '" + xFilial("SA1") + "'"
	cSql += "   AND B1_FILIAL      	=  '" + xFilial("SB1") + "'"
	cSql += "   AND C5_FILIAL      	=  '" + xFilial("SC5") + "'"
	cSql += "   AND C6_FILIAL      	=  '" + xFilial("SC6") + "'"
	cSql += "   AND F4_FILIAL      	=  '" + xFilial("SF4") + "'"

	cSql += "   AND SA1.D_E_L_E_T_  <> '*' "
	cSql += "   AND SC5.D_E_L_E_T_  <> '*' "
	cSql += "   AND SC6.D_E_L_E_T_  <> '*' "
	cSql += "   AND SF4.D_E_L_E_T_  <> '*' "
	cSql += "   AND SB1.D_E_L_E_T_  <> '*' "
	cSql += " ORDER BY C6_ENTREG, B1_COD "
	cAlias := MPSysOpenQuery(cSql)

	While (cAlias)->(!EOF())
		cSql := "INSERT INTO " + cTableName + " ("
		cSql += "	ID, TT_PRODUTO, TT_DESC, TT_NUM, TT_ITEM, TT_QTDVEN, TT_QTDENT, "
		cSql += "	TT_SALDO, TT_ENTREG, TT_CLIENT, TT_EMISSAO, TT_NOME) VALUES ('"
		cSql += FWUUIDv4() 			 			+ "','"
		cSql += (cAlias)->C6_PRODUTO 			+ "','"
		cSql += (cAlias)->B1_DESC    			+ "','"
		cSql += (cAlias)->C6_NUM     			+ "','"
		cSql += (cAlias)->C6_ITEM    			+ "','"
		cSql += cValToChar((cAlias)->C6_QTDVEN) + "','"
		cSql += cValToChar((cAlias)->C6_QTDENT) + "','"
		cSql += cValToChar((cAlias)->C6_SALDO)  + "','"
		cSql += (cAlias)->C6_ENTREG  			+ "','"
		cSql += (cAlias)->C5_CLIENTE 			+ "','"
		cSql += (cAlias)->C5_EMISSAO 			+ "','"
		cSql += (cAlias)->A1_NREDUZ  			+ "')"

		if TCSqlExec(cSql) < 0
			MsgInfo("Erro na execução da query:", "Atenção")
			MsgInfo(TcSqlError(), "Atenção2")
		endif

		(cAlias)->(DbSkip())
	End While
return
