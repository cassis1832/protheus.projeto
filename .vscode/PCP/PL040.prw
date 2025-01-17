#Include 'Protheus.ch'
#Include 'FWMVCDef.ch'

/*/{Protheus.doc} PL040
Função: Exceções do MRP
@author Assis
@since 05/08/2024
@version 1.0
	@return Nil, Fução não tem retorno
	@example
	u_PL040()
/*/

Static cTitulo := "Excecoes do MRP"

User Function PL040()
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
	aAdd(aCampos, {"ID"			,"C",  36, 0})
	aAdd(aCampos, {"TT_PRODUTO"	,"C",  15, 0})
	aAdd(aCampos, {"TT_DESC"	,"C",  60, 0})
	aAdd(aCampos, {"TT_CLIENT"	,"C",  30, 0})
	aAdd(aCampos, {"TT_TIPO"	,"C",   3, 0})
	aAdd(aCampos, {"TT_DOCTO"	,"C",  20, 0})
	aAdd(aCampos, {"TT_NUMEVE"	,"C",   5, 0})
	aAdd(aCampos, {"TT_DESEVE"	,"C", 150, 0})

	//Cria a temporária
	oTempTable := FWTemporaryTable():New(cAliasTT)
	oTempTable:SetFields(aCampos)
	oTempTable:AddIndex("1", {"ID"} )
	oTempTable:AddIndex("2", {"TT_PRODUTO"	, "TT_NUMEVE"} )
	oTempTable:AddIndex("3", {"TT_TIPO"		, "TT_PRODUTO"} )
	oTempTable:AddIndex("4", {"TT_NUMEVE"	, "TT_PRODUTO"} )
	oTempTable:AddIndex("5", {"TT_CLIENT"	, "TT_PRODUTO"} )
	oTempTable:Create()

	cTableName  := oTempTable:GetRealName()

	CargaTT()

	//Definindo as colunas que serão usadas no browse
	aAdd(aColunas, {"Produto"		, "TT_PRODUTO"	, "C", 08, 0, "@!"})
	aAdd(aColunas, {"Descricao"		, "TT_DESC"		, "C", 30, 0, "@!"})
	aAdd(aColunas, {"Tipo"			, "TT_TIPO"		, "C", 03, 0, "@!"})
	aAdd(aColunas, {"Cliente"		, "TT_CLIENT"	, "C", 15, 0, "@!"})
	aAdd(aColunas, {"Num. Evento"	, "TT_NUMEVE"	, "C", 15, 0, "@!"})
	aAdd(aColunas, {"Descr.Evento"	, "TT_DESEVE"	, "C", 50, 0, "@!"})
	aAdd(aColunas, {"Documento"		, "TT_DOCTO"	, "C", 15, 0, "@!"})

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
	aAdd(aPesquisa, {"Produto"	, {{"", "C",  6, 0, "Produto" , "@!", "TT_PRODUTO"}} } )
	aAdd(aPesquisa, {"Cliente"	, {{"", "C",  1, 0, "Cliente" , "@!", "TT_CLIENT"}} } )
	aAdd(aPesquisa, {"Tipo"		, {{"", "C",  1, 0, "Tipo" 	  , "@!", "TT_TIPO"}} } )
	aAdd(aPesquisa, {"Evento"	, {{"", "C",  1, 0, "Evento"  , "@!", "TT_NUMEVE"}} } )

	aAdd(aIndex, {"TT_PRODUTO"} )
	aAdd(aIndex, {"TT_CLIENT"} )
	aAdd(aIndex, {"TT_TIPO"} )
	aAdd(aIndex, {"TT_NUMEVE"} )

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
Menu de opcoes na funcao PL040
@author Assis
@since 19/06/2024
@version 1.0
/*/
Static Function MenuDef()
	Local aRotina := {}
	ADD OPTION aRotina TITLE "Visualizar" ACTION "VIEWDEF.PL040" OPERATION 1 ACCESS 0
Return aRotina


/*/{Protheus.doc} ModelDef
Modelo de dados na funcao PL040
@author Assis
@since 19/06/2024
@version 1.0
/*/
Static Function ModelDef()
	Local oModel := Nil
	Local oStTMP := FWFormModelStruct():New()

	//Na estrutura, define os campos e a temporária
	oStTMP:AddTable(cAliasTT, {'TT_PRODUTO', 'TT_DESC', 'TT_CLIENT', 'TT_TIPO', 'TT_DOCTO', 'TT_NUMEVE', 'TT_DESEVE'}, "Temporaria")

	//Adiciona os campos da estrutura
	oStTmp:AddField("Produto"		,"Produto"		,"TT_PRODUTO"	,"C",06,00,Nil,Nil,{},.T.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_PRODUTO,'')" ), .T., .F., .F.)
	oStTmp:AddField("Descricao"		,"Descricao"	,"TT_DESC"		,"C",40,00,Nil,Nil,{},.T.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_DESC,'')" ),.F.,.F.,.F.)
	oStTmp:AddField("Cliente"		,"Cliente"		,"TT_CLIENT"	,"C",06,00,Nil,Nil,{},.T.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_CLIENT,'')" ), .T., .F., .F.)
	oStTmp:AddField("Tipo"			,"Tipo"			,"TT_TIPO"		,"C",02,00,Nil,Nil,{},.T.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_TIPO,'')" ), .T., .F., .F.)
	oStTmp:AddField("Documento"		,"Documento"	,"TT_DOCTO"		,"C",02,00,Nil,Nil,{},.T.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_DOCTO,'')" ), .T., .F., .F.)
	oStTmp:AddField("Evento"		,"Evento"		,"TT_NUMEVE"	,"C",02,00,Nil,Nil,{},.T.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_NUMEVE,'')" ), .T., .F., .F.)
	oStTmp:AddField("Descr. Evento"	,"Descr. Evento","TT_DESEVE"	,"C",02,00,Nil,Nil,{},.T.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_DESEVE,'')" ), .T., .F., .F.)

	//Instanciando o modelo
	oModel := MPFormModel():New("PL040M",/*bPre*/, /*bPos*/,/*bCommit*/,/*bCancel*/)
	oModel:AddFields("FORMTT",/*cOwner*/,oStTMP)
	oModel:SetPrimaryKey({'ID'})
	oModel:SetDescription("Modelo de Dados do Cadastro ")
	oModel:GetModel("FORMTT"):SetDescription("Formulário do Cadastro ")
Return oModel

/*/{Protheus.doc} ViewDef
Visualizacao de dados na funcao PL040
@author Assis
@since 19/06/2024
@version 1.0
/*/

Static Function ViewDef()
	Local oView := Nil
	Local oModel := FWLoadModel("PL040")
	Local oStTMP := FWFormViewStruct():New()

	//Adicionando campos da estrutura
	oStTmp:AddField("TT_PRODUTO"	,"01","Produto"		,"Produto"		,Nil,"C","@!",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTmp:AddField("TT_DESC"		,"02","Descricao"	,"Descricao"	,Nil,"C","@!",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTmp:AddField("TT_CLIENT"		,"04","Cliente"		,"Cliente"		,Nil,"C","@!",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTmp:AddField("TT_TIPO"		,"03","Tipo"		,"Tipo"			,Nil,"C","@!",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTmp:AddField("TT_DOCTO"		,"04","Documento"	,"Documento"	,Nil,"C","@!",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTmp:AddField("TT_NUMEVE"		,"04","Evento"		,"Evento"		,Nil,"C","@!",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTmp:AddField("TT_DESEVE"		,"04","Descr. Evento","Descr. Evento",Nil,"C","@!",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)

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
	Local cTicket := ""

	// Carregar pedidos de vendas
	cSql := "SELECT HWM_TICKET, HWM_PRODUT, HWM_EVENTO, HWM_LOGMRP, HWM_DOC, "
	cSql += "		B1_DESC, B1_XCLIENT, B1_TIPO, B1_XITEM "
	cSql += "  FROM " + RetSQLName("HWM") + " HWM "

	cSql += " INNER JOIN " + RetSQLName("SB1") + " SB1 "
	cSql += "    ON B1_COD          =  HWM_PRODUT "

	cSql += " WHERE HWM_FILIAL     	=  '" + xFilial("HWM") + "'"
	cSql += "   AND B1_FILIAL      	=  '" + xFilial("SB1") + "'"

	cSql += "   AND HWM.D_E_L_E_T_  <> '*' "
	cSql += "   AND SB1.D_E_L_E_T_  <> '*' "
	cSql += " ORDER BY HWM_TICKET DESC, HWM_PRODUT "
	cAlias := MPSysOpenQuery(cSql)

	While (cAlias)->(!EOF())

		if cTicket == ""
			cTicket = (cAlias)->HWM_TICKET
		endif

		if cTicket <> (cAlias)->HWM_TICKET
			return
		endif

		cSql := "INSERT INTO " + cTableName + " ("
		cSql += "	ID, TT_PRODUTO, TT_DESC, TT_CLIENT, TT_DOCTO, TT_NUMEVE, TT_DESEVE) VALUES ('"
		cSql += FWUUIDv4() 			 				+ "','"
		cSql += (cAlias)->HWM_PRODUT 				+ "','"
		cSql += (cAlias)->B1_DESC    				+ "','"
		cSql += (cAlias)->B1_XCLIENT 				+ "','"
		cSql += substring((cAlias)->HWM_DOC,1,20)	+ "','"
		cSql += (cAlias)->HWM_EVENTO   				+ "','"
		cSql += (cAlias)->HWM_LOGMRP   				+ "')"

		if TCSqlExec(cSql) < 0
			MsgInfo("Erro na execução da query:", "Atenção")
			MsgInfo(TcSqlError(), "Atenção2")
		endif

		(cAlias)->(DbSkip())
	End While
return
