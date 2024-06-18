#Include 'Protheus.ch'
#Include 'FWMVCDef.ch'

/*/{Protheus.doc} PL070
Função: Ordens de Produção Abertas
@author Assis
@since 07/06/2024
@version 1.0
	@return Nil, Fução não tem retorno
	@example
	u_PL070()
/*/

Static cTitulo := "Ordens de Producao Abertas"

User Function PL070()
	Local aArea   := FWGetArea()
	Local aCampos := {}
	Local aColunas := {}
	Local aPesquisa := {}
	Local aIndex := {}
	Local oBrowse

	Private aRotina := {}
	Private cTableName := ""
	Private cAliasTT := GetNextAlias()

	//Definicao do menu
	aRotina := MenuDef()

	//Campos da temporária
	aAdd(aCampos, {"TT_XCLIENT"	,"C", 15, 0})
	aAdd(aCampos, {"TT_XLINPRD"	,"C", 01, 0})
	aAdd(aCampos, {"TT_XPROX"	,"C", 01, 0})
	aAdd(aCampos, {"TT_PROD"	,"C", 15, 0})
	aAdd(aCampos, {"TT_DESC"	,"C", 60, 0})
	aAdd(aCampos, {"TT_OP"		,"C", 11, 0})
	aAdd(aCampos, {"TT_INI"		,"C", 10, 0})
	aAdd(aCampos, {"TT_FIM"		,"C", 10, 0})
	aAdd(aCampos, {"TT_QUANT"	,"N", 14, 3})
	aAdd(aCampos, {"TT_QUJE"	,"N", 14, 3})
	aAdd(aCampos, {"TT_SALDO"	,"N", 14, 3})

	//Cria a temporária
	oTempTable := FWTemporaryTable():New(cAliasTT)
	oTempTable:SetFields(aCampos)
	oTempTable:AddIndex("1", {"TT_FIM"	, "TT_PROD"} )
	oTempTable:AddIndex("2", {"TT_PROD"	, "TT_OP"} )
	oTempTable:AddIndex("3", {"TT_OP"	, "TT_FIM"} )
	oTempTable:Create()

	cTableName  := oTempTable:GetRealName()

	CargaTT()

	//Definindo as colunas que serão usadas no browse
	aAdd(aColunas, {"Linha"		, "TT_XLINPRD"	, "C", 01, 0, "@!"})
	aAdd(aColunas, {"Codigo"	, "TT_PROD"		, "C", 06, 0, "@!"})
	aAdd(aColunas, {"Descricao"	, "TT_DESC"		, "C", 50, 0, "@!"})
	aAdd(aColunas, {"OP"		, "TT_OP"		, "C", 11, 0, "@!"})
	aAdd(aColunas, {"Data Ini."	, "TT_INI"		, "D", 08, 0, "@D"})
	aAdd(aColunas, {"Data Fim."	, "TT_FIM"		, "D", 08, 0, "@D"})
	aAdd(aColunas, {"Quant."	, "TT_QUANT"	, "N", 10, 0, "@E 9,999,999.999"})
	aAdd(aColunas, {"Prod."		, "TT_QUJE"		, "N", 10, 0, "@E 9,999,999.999"})
	aAdd(aColunas, {"Saldo"		, "TT_SALDO"	, "N", 10, 0, "@E 9,999,999.999"})

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
        [n,3] Ordem da pesquisa
        [n,4] Exibe na pesquisa
    */
	aAdd(aPesquisa, {"Codigo"	, {{"", "C",  6, 0, "Codigo", "@!", "TT_PROD"}} } )
	aAdd(aPesquisa, {"OP"		, {{"", "C", 11, 0, "OP"	, "@!", "TT_OP"}} } )
	aAdd(aPesquisa, {"Linha"	, {{"", "C",  1, 0, "Linha" , "@!", "TT_XLINPRD"}} } )

	aAdd(aIndex, "TT_FIM" )

	//Criando o browse da temporária
	oBrowse := FWMBrowse():New()
	oBrowse:SetAlias(cAliasTT)
	oBrowse:SetQueryIndex(aIndex)
	oBrowse:SetTemporary(.T.)
	oBrowse:SetFields(aColunas)
	oBrowse:DisableDetails()
	oBrowse:SetDescription(cTitulo)
	oBrowse:SetSeek(.T., aPesquisa)
	//oBrowse:SetItemHeaderClick({"TT_XLINPRD", "TT_PROD"}) não funciona no FWMBROWSE
	oBrowse:Activate()

	oTempTable:Delete()
	FWRestArea(aArea)
Return Nil


/*/{Protheus.doc} MenuDef
Menu de opcoes na funcao pl070
@author Atilio
@since 10/03/2022
@version 1.0
/*/
Static Function MenuDef()
	Local aRotina := {}
	ADD OPTION aRotina TITLE "Visualizar" ACTION "VIEWDEF.PL070" OPERATION 1 ACCESS 0
Return aRotina


/*/{Protheus.doc} ModelDef
Modelo de dados na funcao pl070
@author Atilio
@since 10/03/2022
@version 1.0
/*/
Static Function ModelDef()
	Local oModel := Nil
	Local oStTMP := FWFormModelStruct():New()

	//Na estrutura, define os campos e a temporária
	oStTMP:AddTable(cAliasTT, {'TT_PROD', 'TT_DESC', 'TT_OP', 'TT_INI', 'TT_FIM', 'TT_QUANT', 'TT_QUJE', 'TT_SALDO'}, "Temporaria")

	//Adiciona os campos da estrutura
	oStTmp:AddField("Linha"		,"Linha"		,"TT_XLINPRD"	,"C",06,00,Nil,Nil,{},.T.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_PROD,'')" ), .T., .F., .F.)
	oStTmp:AddField("Codigo"	,"Codigo"		,"TT_PROD"		,"C",06,00,Nil,Nil,{},.T.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_PROD,'')" ), .T., .F., .F.)
	oStTmp:AddField("Descricao"	,"Descricao"	,"TT_DESC"		,"C",50,00,Nil,Nil,{},.T.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_DESC,'')" ),.F.,.F.,.F.)
	oStTmp:AddField("Ordem"		,"Ordem"		,"TT_OP"		,"C",11,00,Nil,Nil,{},.F.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_OP,'')" ),.F.,.F.,.F.)
	oStTmp:AddField("Data Ini."	,"Data Inicial"	,"TT_INI"		,"D",08,00,Nil,Nil,{},.F.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_INI,'')" ),.F.,.F.,.F.)
	oStTmp:AddField("Data Fim"	,"Data Final"	,"TT_FIM"		,"D",08,00,Nil,Nil,{},.F.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_FIM,'')" ),.F.,.F.,.F.)
	oStTmp:AddField("Quant."	,"Quantidade"	,"TT_QUANT"		,"N",10,02,Nil,Nil,{},.F.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_QUANT,'')" ),.F.,.F.,.F.)
	oStTmp:AddField("Prod."		,"Produzida"	,"TT_QUJE"		,"N",10,02,Nil,Nil,{},.F.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_QUJE,'')" ),.F.,.F.,.F.)
	oStTmp:AddField("Saldo"		,"Saldo da OP"	,"TT_SALDO"		,"N",10,02,Nil,Nil,{},.F.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_SALDO,'')" ),.F.,.F.,.F.)

	//Instanciando o modelo
	oModel := MPFormModel():New("PL070M",/*bPre*/, /*bPos*/,/*bCommit*/,/*bCancel*/)
	oModel:AddFields("FORMTT",/*cOwner*/,oStTMP)
	//oModel:SetPrimaryKey({'TT_PROD'})
	oModel:SetDescription("Modelo de Dados do Cadastro ")
	oModel:GetModel("FORMTT"):SetDescription("Formulário do Cadastro ")
Return oModel

/*/{Protheus.doc} ViewDef
Visualizacao de dados na funcao pl070
@author Atilio
@since 10/03/2022
@version 1.0
/*/

Static Function ViewDef()
	Local oView := Nil
	Local oModel := FWLoadModel("PL070")
	Local oStTMP := FWFormViewStruct():New()

	//Adicionando campos da estrutura
	oStTmp:AddField("TT_XLINPRD","01","Linha"		,"Linha"		,Nil,"C","@!",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTmp:AddField("TT_PROD"	,"02","Codigo"		,"Codigo"		,Nil,"C","@!",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTmp:AddField("TT_DESC"	,"03","Descricao"	,"Descricao"	,Nil,"C","@!",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTmp:AddField("TT_OP"		,"04","Ordem"		,"Ordem"		,Nil,"C","@!",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTmp:AddField("TT_INI"	,"05","Data Ini."	,"Data Ini."	,Nil,"D","@D",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTmp:AddField("TT_FIM"	,"06","Data Fim"	,"Data Fim"		,Nil,"D","@D",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTmp:AddField("TT_QUANT"	,"07","Quant."		,"Quantidade"	,Nil,"N","@E 9,999,999.99",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTmp:AddField("TT_QUJE"	,"08","Prod."		,"Produzida"	,Nil,"N","@E 9,999,999.99",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTmp:AddField("TT_SALDO"	,"09","Saldo"		,"Saldo"		,Nil,"N","@E 9,999,999.99",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)

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

	// LER OP E ITEM
	cSql := "SELECT C2_NUM, C2_ITEM, C2_SEQUEN, C2_PRODUTO, "
	cSql += "	 C2_QUANT, C2_QUJE, CAST(C2_DATPRI AS DATE) C2_DATPRI, "
	cSql += "	 CAST(C2_DATPRF AS DATE) C2_DATPRF, "
	cSql += "	 B1_COD, B1_DESC, B1_UM, B1_XCLIENT, B1_XLINPRD, B1_XPROX "
	cSql += " FROM " + RetSQLName("SC2") + " SC2 "
	cSql += "INNER JOIN " + RetSQLName("SB1") + " SB1 "
	cSql += "   ON C2_PRODUTO     = B1_COD "
	cSql += "WHERE C2_FILIAL      = '" + xFilial("SC2") + "' "
	cSql += "  AND C2_QUANT       > C2_QUJE "
	cSql += "  AND C2_DATRF       = '' "
	cSql += "  AND SC2.D_E_L_E_T_ = ' ' "
	cSql += "  AND SB1.D_E_L_E_T_ = ' ' "
	cSql += "ORDER BY C2_DATPRF, C2_NUM, C2_ITEM, C2_SEQUEN "
	cAlias := MPSysOpenQuery(cSql)

	While (cAlias)->(!EOF())
		cSql := "INSERT INTO " + cTableName + " (TT_PROD, TT_DESC, TT_OP, TT_QUANT, TT_QUJE, TT_SALDO, TT_INI, TT_FIM) VALUES "
		cSql += "('" + (cAlias)->C2_PRODUTO + "','" + (cAlias)->B1_DESC + "',"
		cSql += "'" + (cAlias)->C2_NUM + (cAlias)->C2_ITEM + (cAlias)->C2_SEQUEN + "',"
		cSql += "'" + cValToChar((cAlias)->C2_QUANT) + "',"
		cSql += "'" + cValToChar((cAlias)->C2_QUJE) + "',"
		cSql += "'" + cValToChar((cAlias)->C2_QUANT - (cAlias)->C2_QUJE) + "',"
		cSql += "'" + DtOc((cAlias)->C2_DATPRI) + "','" + DtOc((cAlias)->C2_DATPRF) + "')"

		if TCSqlExec(cSql) < 0
			MsgInfo("Erro na execução da query:", "Atenção")
			MsgInfo(TcSqlError(), "Atenção2")
		endif

		(cAlias)->(DbSkip())
	End While
return
