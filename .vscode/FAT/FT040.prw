#Include 'Protheus.ch'
#Include 'FWMVCDef.ch'

/*/{Protheus.doc} FT040
Função: Geração de pedido de venda com base no saldo de estoque
@author Assis
@since 08/09/2024
@version 1.0
	@return Nil, Fução não tem retorno
/*/

Static cTitulo := "Geracao de Pedidos de Vendas"

User Function FT040(cCli, cLoj)
	Local aArea 		:= FWGetArea()

	Local aCampos 		:= {}
	Local aColunas 		:= {}
	Local aPesquisa 	:= {}
	Local aIndex 		:= {}

	Private oMark		:= Nil
	Private cCliente	:= cCli
	Private cLoja		:= cLoj
	Private cTableName 	:= ""
	Private aRotina 	:= {}
	Private cMarca 		:= GetMark()
	Private cAliasTT 	:= GetNextAlias()

	//Definicao do menu
	aRotina := MenuDef()

	//Campos da temporária
	aAdd(aCampos, {"TT_ID"		,"C", 36, 0})
	aAdd(aCampos, {"TT_PRODUTO"	,"C", 15, 0})
	aAdd(aCampos, {"TT_DESC"	,"C", 60, 0})
	aAdd(aCampos, {"TT_QUANT"	,"N", 10, 0})
	aAdd(aCampos, {"TT_UM"		,"C", 02, 0})
	aAdd(aCampos, {"TT_ALOC"	,"N", 10, 0})
	aAdd(aCampos, {"TT_SALDO"	,"N", 10, 0})
	aAdd(aCampos, {"TT_GRUPV"	,"C", 20, 0})
	aAdd(aCampos, {"TT_NATUR"	,"C", 15, 0})
	aAdd(aCampos, {"TT_OK"		,"C", 02, 0})

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
	aAdd(aColunas, {"Alocado"		, "TT_ALOC"		, "N", 10, 0, "@E 9,999,999.999"})
	aAdd(aColunas, {"Quantidade"	, "TT_QUANT"	, "N", 10, 0, "@E 9,999,999.999"})

	aAdd(aPesquisa, {"Produto"	, {{"", "C",  15, 0, "Produto" 	, "@!", "TT_PRODUTO"}} } )
	aAdd(aIndex, {"TT_PRODUTO"} )

	oMark := FWMarkBrowse():New()
	oMark:SetAlias(cAliasTT)
	//oMark:SetQueryIndex(aIndex)
	oMark:SetTemporary(.T.)
	oMark:SetFields(aColunas)
	oMark:DisableDetails()
	oMark:SetDescription(cTitulo)
	oMark:SetSeek(.T., aPesquisa)

	oMark:SetFieldMark( 'TT_OK' )
	oMark:SetMark(cMarca, cAliasTT, "TT_OK")
	oMark:SetAllMark( { || oMark:AllMark() } )
	oMark:Activate()

	oTempTable:Delete()
	FWRestArea(aArea)
Return Nil


/*---------------------------------------------------------------------*
	Criação do menu MVC
 *---------------------------------------------------------------------*/
Static Function MenuDef()
	Local aRot := {}

	ADD OPTION aRot TITLE 'Visualizar' 	  ACTION 'VIEWDEF.FT040' 	OPERATION 2 ACCESS 0 
	ADD OPTION aRot TITLE 'Alterar'    	  ACTION 'VIEWDEF.FT040' 	OPERATION 4 ACCESS 0 
	ADD OPTION aRot TITLE 'Gerar Pedidos' ACTION 'u_FT040Mark()'	OPERATION 6 ACCESS 0 
Return aRot


/*---------------------------------------------------------------------*
	Criação do modelo de dados MVC
 *---------------------------------------------------------------------*/
Static Function ModelDef()
    Local oModel   := Nil
   	Local oStTT := FWFormModelStruct():New()

	oStTT:AddTable(cAliasTT, {'TT_ID'}, "Temporaria")

	//Adiciona os campos da estrutura
	oStTT:AddField("Produto"	,"Produto"		,"TT_PRODUTO"	,"C",06,00,Nil,Nil,{},.F.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_PRODUTO,'')" ), .T., .F., .F.)
	oStTT:AddField("Descricao"	,"Descricao"	,"TT_DESC"		,"C",40,00,Nil,Nil,{},.F.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_DESC,'')" ),.T.,.F.,.F.)
	oStTT:AddField("Saldo"		,"Saldo"		,"TT_SALDO"		,"N",10,00,Nil,Nil,{},.F.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_SALDO,'')" ),.T.,.F.,.F.)
	oStTT:AddField("UM"			,"UM"			,"TT_UM"		,"C",02,00,Nil,Nil,{},.F.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_UM,'')" ),.T.,.F.,.F.)
	oStTT:AddField("Alocado"	,"Alocado"		,"TT_ALOC"		,"N",10,00,Nil,Nil,{},.F.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_ALOC,'')" ), .T., .F., .F.)
	oStTT:AddField("Quantidade"	,"Quantidade"	,"TT_QUANT"		,"N",10,00,Nil,Nil,{},.T.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_QUANT,'')" ), .F., .F., .F.)

	oModel:=MPFormModel():New("FT040M", Nil, Nil, Nil, Nil)

	oModel:AddFields("FORMTT",/*cOwner*/,oStTT)
	oModel:SetPrimaryKey({'TT_ID'})
	oModel:SetDescription(cTitulo)
	oModel:GetModel("FORMTT"):SetDescription("Formulário do Cadastro ")
Return oModel


/*---------------------------------------------------------------------*
	Criação da visão MVC
 *---------------------------------------------------------------------*/
Static Function ViewDef()
    Local oView  := Nil
    Local oModel := FWLoadModel("FT040")      
	Local oStTT := FWFormViewStruct():New()

	//Adicionando campos da estrutura
	oStTT:AddField("TT_PRODUTO"	,"01","Produto"		,"Produto"		,Nil,"C","@!",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTT:AddField("TT_DESC"	,"02","Descricao"	,"Descricao"	,Nil,"C","@!",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTT:AddField("TT_SALDO"	,"03","Saldo"		,"Saldo"		,Nil,"N","@E 9,999,999",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTT:AddField("TT_UM"		,"04","UM"			,"UM"			,Nil,"C","@!",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTT:AddField("TT_ALOC"	,"05","Alocado"		,"Alocado"		,Nil,"N","@E 9,999,999",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTT:AddField("TT_QUANT"	,"06","Quantidade"	,"Quantidade"	,Nil,"N","@E 9,999,999",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)

    oView:= FWFormView():New()               
    oView:SetModel(oModel)
  	oView:AddField("VIEW_TT", oStTT, "FORMTT")
	oView:CreateHorizontalBox("TELA",100)
	oView:EnableTitleView('VIEW_TT', 'Dados' )
	oView:SetCloseOnOk({||.T.})
	oView:SetOwnerView("VIEW_TT","TELA")
Return oView


/*---------------------------------------------------------------------*
  Prepara os registros marcados no checkbox
 *---------------------------------------------------------------------*/
User Function FT040Mark()
	Local aArea    := GetArea()
	Local cMarca   := oMark:Mark()
	Local aPedidos := {}

	(cAliasTT)->(DbGoTop())

	While !(cAliasTT)->(EoF())
		If oMark:IsMark(cMarca) .AND. (cAliasTT)->TT_QUANT > 0
			aadd(aPedidos,{"", cCliente, cLoja, (cAliasTT)->TT_PRODUTO, dtos(Date()), "00:00", (cAliasTT)->TT_QUANT, (cAliasTT)->TT_NATUR, (cAliasTT)->TT_GRUPV})

			RecLock(cAliasTT, .F.)
			(cAliasTT)->TT_OK := ''
			(cAliasTT)->(MsUnlock())
		EndIf

		(cAliasTT)->(DbSkip())
	EndDo

	if len(aPedidos) > 0
		u_FT040A(aPedidos)
		CargaTT()		
	endif

	RestArea(aArea)
Return NIL


Static Function CargaTT()
	Local cAliasSA7, cAliasSB8, cSql
	Local nSaldo	:= 0
	Local nAloc		:= 0

	cSql := "DELETE FROM " + cTableName 

	if TCSqlExec(cSql) < 0
		MsgInfo("Erro na Delete", "Atenção")
		MsgInfo(TcSqlError(), "Atenção3")
	endif
	
	cSql := "SELECT A7_PRODUTO, A7_XNATUR, A7_XGRUPV, B1_DESC, B1_UM "
	cSql += "  FROM " + RetSQLName("SA7") + " SA7 "

	cSql += " INNER JOIN " + RetSQLName("SB1") + " SB1 "
	cSql += "    ON B1_COD          =  A7_PRODUTO "
	cSql += "   AND B1_FILIAL      	=  '" + xFilial("SB1") 	+ "'"
	cSql += "   AND SB1.D_E_L_E_T_  <> '*' "

	cSql += " WHERE A7_CLIENTE 		 			=  '" + cCliente 		+ "'"
	cSql += "   AND A7_LOJA 		 			=  '" + cLoja 			+ "'"
	cSql += "   AND SUBSTRING(A7_XNATUR,1,1) 	=  'F" 					+ "'"
	cSql += "   AND A7_FILIAL 					=  '" + xFILIAL("SA7") 	+ "'"
	cSql += "   AND SA7.D_E_L_E_T_  			<> '*' "
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
			nSaldo := (cAliasSB8)->B8_SALDO
			nAloc := LerAlocados((cAliasSA7)->A7_PRODUTO)
		else 
			nQtde := 0
		endif

		cSql := "INSERT INTO " + cTableName + " ("
		cSql += " TT_ID, TT_PRODUTO, TT_DESC, TT_UM, TT_NATUR, TT_GRUPV, TT_SALDO, TT_ALOC, TT_QUANT) VALUES ('"
		cSql += FWUUIDv4() 			 				+ "','"
		cSql += (cAliasSA7)->A7_PRODUTO 			+ "','"
		cSql += (cAliasSA7)->B1_DESC    			+ "','"
		cSql += (cAliasSA7)->B1_UM   				+ "','"
		cSql += (cAliasSA7)->A7_XNATUR  			+ "','"
		cSql += (cAliasSA7)->A7_XGRUPV  			+ "','"
		cSql += cValToChar(nSaldo) 					+ "','"
		cSql += cValToChar(nAloc) 					+ "','"
		cSql += cValToChar(nSaldo - nAloc) 			+ "')"

		if TCSqlExec(cSql) < 0
			MsgInfo("Erro no insert da TT:", "Atenção")
			MsgInfo(TcSqlError(), "Atenção")
		endif

		(cAliasSB8)->(DBCLOSEAREA())

		(cAliasSA7)->(DbSkip())
	End While

	(cAliasSA7)->(DBCLOSEAREA())
return


Static Function LerAlocados(cProduto)
	Local cAlias	:= ""
	Local cSql		:= ""
	Local nAlocado 	:= 0

	// Carregar pedidos de vendas
	cSql := "SELECT C5_NUM, C6_QTDVEN "
	cSql += "  FROM  " + RetSQLName("SC5") + " SC5 "
	cSql += " INNER JOIN " + RetSQLName("SC6") + " SC6 "
	cSql += "    ON C5_NUM         =  C6_NUM "
	cSql += " WHERE C5_NOTA        =  '' "
	cSql += "   AND C5_LIBEROK     <> 'E' "
	cSql += "   AND C6_QTDENT      <  C6_QTDVEN "
	cSql += "   AND C6_BLQ 		   <> 'R' "
	cSql += "   AND C6_PRODUTO     =  '" + cProduto + "' "
	cSql += "   AND C5_FILIAL      =  '" + xFilial("SC5") + "'"
	cSql += "   AND C6_FILIAL      =  '" + xFilial("SC6") + "'"
	cSql += "   AND SC5.D_E_L_E_T_ <> '*' "
	cSql += "   AND SC6.D_E_L_E_T_ <> '*' "
	cAlias := MPSysOpenQuery(cSql)

	While (cAlias)->(!EOF())
		nAlocado := nAlocado + (cAlias)->C6_QTDVEN
		(cAlias)->(DbSkip())
	End

	(cAlias)->(DBCLOSEAREA())
return nAlocado
