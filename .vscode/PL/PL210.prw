#Include 'Protheus.ch'
#Include 'FWMVCDef.ch'

/*/{Protheus.doc} PL210
Função: Geração de pedido de venda com base no saldo de estoque
@author Assis
@since 08/09/2024
@version 1.0
	@return Nil, Fução não tem retorno
/*/

Static cTitulo := "Geracao de Pedidos de Vendas"

User Function PL210(cCli, cLoj, dLim)
	Local aArea 		:= FWGetArea()

	Local aCampos 		:= {}
	Local aColunas 		:= {}
	Local aPesquisa 	:= {}
	Local aIndex 		:= {}

	Private oBrowse
	Private cCliente	:= cCli
	Private cLoja		:= cLoj
	Private dLimite		:= dLim
	Private cTableName 	:= ""
	Private aRotina 	:= {}
	Private cMarca 		:= GetMark()
	Private cAliasTT 	:= GetNextAlias()

	//Definicao do menu
	aRotina := MenuDef()

	//Campos da temporária
	aAdd(aCampos, {"TT_ID"		,"C", 36, 0})
	aAdd(aCampos, {"TT_OK"		,"C", 01, 0})
	aAdd(aCampos, {"TT_PRODUTO"	,"C", 15, 0})
	aAdd(aCampos, {"TT_DESC"	,"C", 60, 0})
	aAdd(aCampos, {"TT_UM"		,"C", 02, 0})
	aAdd(aCampos, {"TT_SALDO"	,"N", 10, 0})
	aAdd(aCampos, {"TT_QUANT"	,"N", 10, 0})
	aAdd(aCampos, {"TT_GRUPV"	,"C", 20, 0})
	aAdd(aCampos, {"TT_NATUR"	,"C", 15, 0})

	//Cria a temporária
	oTempTable := FWTemporaryTable():New(cAliasTT)
	oTempTable:SetFields(aCampos)
	oTempTable:AddIndex("1", {"TT_PRODUTO"} )
	oTempTable:AddIndex("2", {"TT_ID"} )
	oTempTable:Create()

	cTableName  := oTempTable:GetRealName()

	CargaTT()

	//Definindo as colunas que serão usadas no browse
	aAdd(aColunas, {"Produto"		, "TT_PRODUTO"	, "C", 08, 0, "@!"})
	aAdd(aColunas, {"Descricao"		, "TT_DESC"		, "C", 30, 0, "@!"})
	aAdd(aColunas, {"Saldo"			, "TT_SALDO"	, "N", 10, 0, "@E 9,999,999.999"})
	aAdd(aColunas, {"UM"			, "TT_UM"		, "C", 02, 0, "@!"})
	aAdd(aColunas, {"Quantidade"	, "TT_QUANT"	, "N", 10, 0, "@E 9,999,999.999"})

	aAdd(aPesquisa, {"Produto"	, {{"", "C",  15, 0, "Produto" 	, "@!", "TT_PRODUTO"}} } )
	aAdd(aIndex, {"TT_PRODUTO"} )

	oBrowse := FWMarkBrowse():New()
	oBrowse:SetAlias(cAliasTT)
	oBrowse:SetQueryIndex(aIndex)
	oBrowse:SetTemporary(.T.)
	oBrowse:SetFields(aColunas)
	oBrowse:DisableDetails()
	oBrowse:SetDescription(cTitulo)
	oBrowse:SetSeek(.T., aPesquisa)

	oBrowse:SetFieldMark( 'TT_OK' )
	oBrowse:SetMark(cMarca, cAliasTT, "TT_OK")
	oBrowse:SetAllMark( { || oBrowse:AllMark() } )
	oBrowse:Activate()

	oTempTable:Delete()
	FWRestArea(aArea)
Return Nil


/*---------------------------------------------------------------------*
	Criação do menu MVC
 *---------------------------------------------------------------------*/
Static Function MenuDef()
	Local aRot := {}

	ADD OPTION aRot TITLE 'Visualizar' 	  ACTION 'VIEWDEF.PL210' 	OPERATION 2 ACCESS 0 
	ADD OPTION aRot TITLE 'Alterar'    	  ACTION 'VIEWDEF.PL210' 	OPERATION 4 ACCESS 0 
	ADD OPTION aRot TITLE 'Gerar Pedidos' ACTION 'u_PL210Mark()'	OPERATION 6 ACCESS 0 
Return aRot


/*---------------------------------------------------------------------*
	Criação do modelo de dados MVC
 *---------------------------------------------------------------------*/
Static Function ModelDef()
    Local oModel   := Nil
   	Local oStTMP := FWFormModelStruct():New()

	//Adiciona os campos da estrutura
	oStTmp:AddField("Produto"		,"Produto"		,"TT_PRODUTO"	,"C",06,00,Nil,Nil,{},.T.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_PRODUTO,'')" ), .T., .F., .F.)
	oStTmp:AddField("Descricao"		,"Descricao"	,"TT_DESC"		,"C",40,00,Nil,Nil,{},.T.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_DESC,'')" ),.F.,.F.,.F.)
	oStTmp:AddField("Saldo"			,"Saldo"		,"TT_SALDO"		,"N",10,00,Nil,Nil,{},.F.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_SALDO,'')" ),.F.,.F.,.F.)
	oStTmp:AddField("UM"			,"UM"			,"TT_UM"		,"C",02,00,Nil,Nil,{},.F.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_UM,'')" ),.F.,.F.,.F.)
	oStTmp:AddField("Quantidade"	,"Quantidade"	,"TT_QUANT"		,"N",10,00,Nil,Nil,{},.T.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_LOTE,'')" ), .T., .F., .F.)

	// Proteger de alteracoes
	oStZA0:SetProperty('TT_PRODUTO'	,MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))
	oStZA0:SetProperty('TT_DESC'	,MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))
	oStZA0:SetProperty('TT_SALDO'	,MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))
	oStZA0:SetProperty('TT_UM'		,MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))

	oModel:=MPFormModel():New("PL210M", Nil, {|oModel| MVCMODELPOS(oModel)}, Nil, Nil)
	oModel:AddFields("FORMTT",/*cOwner*/,oStTMP)
	oModel:SetPrimaryKey({'TT_ID'})
	oModel:SetDescription(cTitulo)
	oModel:GetModel("FORMTT"):SetDescription("Formulário do Cadastro ")
Return oModel


/*---------------------------------------------------------------------*
	Criação da visão MVC
 *---------------------------------------------------------------------*/
Static Function ViewDef()
    Local oView  := Nil
    Local oModel := FWLoadModel("PL210")      
	Local oStTMP := FWFormViewStruct():New()

	//Adicionando campos da estrutura
	oStTmp:AddField("TT_PRODUTO"	,"01","Codigo"		,"Codigo"		,Nil,"C","@!",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTmp:AddField("TT_DESC"		,"02","Descricao"	,"Descricao"	,Nil,"C","@!",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTmp:AddField("TT_SALDO"		,"06","Saldo"		,"Saldo"		,Nil,"N","@E 9,999,999",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTmp:AddField("TT_UM"			,"07","UM"			,"UM"			,Nil,"C","@!",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTmp:AddField("TT_QUANT"		,"09","Quantidade"	,"Quantidade"	,Nil,"N","@E 9,999,999",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)

    oView:= FWFormView():New()               
    oView:SetModel(oModel)
  	oView:AddField("VIEW_TT", oStTMP, "FORMTT")
	oView:CreateHorizontalBox("TELA",100)
	oView:EnableTitleView('VIEW_TT', 'Dados - ')
	oView:SetCloseOnOk({||.T.})
	oView:SetOwnerView("VIEW_TT","TELA")
Return oView


Static Function MVCMODELPOS(oModel)
	Local aArea   		:= GetArea()
	Local lOk	:= .T.

	RestArea(aArea)
Return lOk


/*---------------------------------------------------------------------*
  Prepara os registros marcados no checkbox
 *---------------------------------------------------------------------*/
User Function PL210Mark()
	Local aArea    := GetArea()
	Local cMarca   := oBrowse:Mark()
	
	cAliasTT->(DbGoTop())

	While !cAliasTT->(EoF())
		If oBrowse:IsMark(cMarca) .AND. (cAliasTT)->TT_QUANT > 0
			aadd(aPedidos,{"", cCliente, cLoja, (cAliasTT)->TT_PRODUTO, dtos(Date()), "00:00", (cAliasTT)->TT_QUANT, (cAliasTT)->TT_NATUR, (cAliasTT)->TT_GRUPV})
		EndIf

		(cAliasTT)->(DbSkip())
	EndDo

	if len(aPedidos) > 0
		u_PL210A(aPedidos)
	endif

	RestArea(aArea)
Return NIL



Static Function CargaTT()
	Local cAliasSA7, cAliasSB8, cSql
	Local nQtde	:= 0

	cSql := "SELECT A7_PRODUTO, A7_XNATUR, A7_XGRUPV, B1_DESC, B1_UM "
	cSql += "  FROM " + RetSQLName("SA7") + " SA7 "

	cSql += " INNER JOIN " + RetSQLName("SB1") + " SB1 "
	cSql += "    ON B1_COD          =  B8_PRODUTO "
	cSql += "   AND B1_FILIAL      	=  '" + xFilial("SB1") 	+ "'"
	cSql += "   AND SB1.D_E_L_E_T_  <> '*' "

	cSql += " WHERE A7_CLIENTE 		 = '" + cCliente 		+ "'"
	cSql += "   AND A7_LOJA 		 = '" + cLoja 			+ "'"
	cSql += "   AND A7_FILIAL 		=  '" + xFILIAL("SA7") 	+ "'"
	cSql += "   AND SA7.D_E_L_E_T_  <> '*' "
	cSql += " ORDER BY A7_PRODUTO "
	cAliasSA7 := MPSysOpenQuery(cSql)

	While (cAliasSA7)->(!EOF())

		// Calcula o saldo do item no estoque
		cSql := "SELECT SUM(B8_SALDO) B8_SALDO "
		cSql += "  FROM " + RetSQLName("SB8") + " B8 "
		cSql += " WHERE B8_PRODUTO     	= '" + (cAliasSA7)->A7_PRODUTO + "'"
		cSql += "   AND B8_SALDO      	>  0 "
		cSql += "   AND B8_FILIAL      	=  '" + xFilial("SB8") 	+ "'"
		cSql += "   AND B8.D_E_L_E_T_  <> '*' "
		cAliasSB8 := MPSysOpenQuery(cSql)

		if ! (cAliasSB8)->(EOF())
			nQtde := (cAliasSB8)->B8_SALDO
		else 
			nQtde := 0
		endif

		cSql := "INSERT INTO " + cTableName + " ("
		cSql += " TT_ID, TT_PRODUTO, TT_DESC, TT_UM, TT_NATUR, TT_GRUPV, TT_SALDO, TT_QUANT) VALUES ('"
		cSql += FWUUIDv4() 			 				+ "','"
		cSql += (cAliasSA7)->A7_PRODUTO 			+ "','"
		cSql += (cAliasSA7)->B1_DESC    			+ "','"
		cSql += (cAliasSA7)->B1_UM   				+ "','"
		cSql += (cAliasSA7)->A7_XGRUPV  			+ "','"
		cSql += (cAliasSA7)->A7_XNATUR  			+ "','"
		cSql += cValToChar(nQtde) 					+ "','"
		cSql += cValToChar(nQtde) 					+ "')"

		if TCSqlExec(cSql) < 0
			MsgInfo("Erro no insert da TT:", "Atenção")
			MsgInfo(TcSqlError(), "Atenção")
		endif

		(cAliasSA7)->(DbSkip())
	End While
return
