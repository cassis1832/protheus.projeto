#Include "PROTHEUS.CH"
#Include "RPTDEF.CH"
#Include "TBICONN.CH"
#Include 'FWMVCDef.ch'

/*/{Protheus.doc}	FT010
	Faturamento por cliente
@author Carlos Assis
@since 12/09/2024
@version 1.0   
/*/

User Function FT010()
	Local aArea 		:= FWGetArea()
	Local aCampos 		:= {}
	Local aColunas 		:= {}
	Local aPesquisa 	:= {}
	Local aIndex 		:= {}
	Local oBrowse

	Local oSay 			:= NIL
	Local aPergs		:= {}
	Local aResps		:= {}

	Private cTitulo		:= "Faturamento do Cliente"
	Private aRotina 	:= {}
	Private cTableName 	:= ""
	Private cAliasTT 	:= GetNextAlias()

	Private dDtIni  	:= ""
	Private dDtFim  	:= ""
	Private cCliente 	:= ""

	//Definicao do menu
	aRotina := MenuDef()

	AAdd(aPergs, {1, "Informe a data inicial "	, CriaVar("C2_DATPRF",.F.),"",".T.","",".T.", 70, .F.})
	AAdd(aPergs, {1, "Informe a data final "	, CriaVar("C2_DATPRF",.F.),"",".T.","",".T.", 70, .F.})
	AAdd(aPergs, {1, "Cliente"					, CriaVar("A1_COD",.F.),,,"SA1",, 70, .F.})

	If ParamBox(aPergs, "PLANO DE PRODUCAO", @aResps,,,,,,,, .T., .T.)
		dDtIni 		:= aResps[1]
		dDtFim 		:= aResps[2]
		cCliente	:= aResps[3]
	Else
		return
	endif

	//Campos da temporária
	aAdd(aCampos, {"TT_ID"		,"C", 36, 0})
	aAdd(aCampos, {"TT_PRODUTO"	,"C", 15, 0})
	aAdd(aCampos, {"TT_DESC"	,"C", 60, 0})
	aAdd(aCampos, {"TT_ITCLI"	,"C", 30, 0})
	aAdd(aCampos, {"TT_DATFAT"	,"D", 08, 0})
	aAdd(aCampos, {"TT_QTFAT"	,"N", 14, 3})
	aAdd(aCampos, {"TT_PRCVEN"	,"N", 14, 3})
	aAdd(aCampos, {"TT_VLFAT"	,"N", 14, 3})
	aAdd(aCampos, {"TT_TES"	    ,"C", 03, 3})
	aAdd(aCampos, {"TT_CF"	    ,"C", 05, 3})
	aAdd(aCampos, {"TT_PEDIDO"	,"C", 06, 3})
	aAdd(aCampos, {"TT_DOC"	    ,"C", 09, 3})
	aAdd(aCampos, {"TT_SERIE"	,"C", 03, 3})

	//Cria a temporária
	oTempTable := FWTemporaryTable():New(cAliasTT)
	oTempTable:SetFields(aCampos)

	// Sem esses indices a caixa de filtrar não funciona
	oTempTable:AddIndex("1", {"TT_ID"} )
	oTempTable:AddIndex("2", {"TT_PRODUTO"} )
	oTempTable:Create()

	cTableName  := oTempTable:GetRealName()

	FwMsgRun(NIL, {|oSay| CargaTT(oSay)}, "Processando Notas Fiscais", "Extraindo dados...")

	//Definindo as colunas que serão usadas no browse
	aAdd(aColunas, {"Produto"			, "TT_PRODUTO"	, "C", 08, 0, "@!"})
	aAdd(aColunas, {"Descricao"			, "TT_DESC"		, "C", 30, 0, "@!"})
	aAdd(aColunas, {"Item Cliente"		, "TT_ITCLI"	, "C", 15, 0, "@!"})
	aAdd(aColunas, {"Pedido"			, "TT_PEDIDO"	, "C", 10, 0, "@!"})
	aAdd(aColunas, {"Docto."			, "TT_DOC"		, "C", 09, 0, "@!"})
	aAdd(aColunas, {"Serie"			    , "TT_SERIE"	, "C", 03, 0, "@!"})
	aAdd(aColunas, {"Dt. Fatur."		, "TT_DATFAT"	, "D", 06, 0, "@D"})
	aAdd(aColunas, {"TES"			    , "TT_TES"		, "C", 03, 0, "@!"})
	aAdd(aColunas, {"CFOP"			    , "TT_CF"		, "C", 05, 0, "@!"})
	aAdd(aColunas, {"Quant."			, "TT_QTFAT"	, "N", 10, 3, "@E 9,999,999.999"})
	aAdd(aColunas, {"Vl. Unitario"		, "TT_PRCVEN"	, "N", 10, 3, "@E 9,999,999.999"})
	aAdd(aColunas, {"Valor" 			, "TT_VLFAT"	, "N", 10, 3, "@E 9,999,999.999"})

	// Para aparecer caixa de filtrar
	aAdd(aPesquisa, {"Produto"		, {{"", "C", 15, 0, "Produto" 	 , "@!", "TT_PRODUTO"}} } )

	aAdd(aIndex, {"TT_PRODUTO"} )

	//Criando o browse da temporária
	oBrowse := FWMBrowse():New()
	oBrowse:SetAlias(cAliasTT)
	oBrowse:SetQueryIndex(aIndex)
	oBrowse:SetTemporary(.T.)
	oBrowse:SetFields(aColunas)
	oBrowse:DisableDetails()
	oBrowse:SetDescription(cTitulo)
	oBrowse:SetSeek(.T., aPesquisa)
	oBrowse:Activate()

	oTempTable:Delete()
	FWRestArea(aArea)
return


Static Function MenuDef()
	Local aRot := {}
	ADD OPTION aRot TITLE 'Visualizar' 	  ACTION 'VIEWDEF.FT010'  OPERATION 2 ACCESS 0
Return aRot


Static Function ModelDef()
	Local oModel := Nil
	Local oStTT := FWFormModelStruct():New()

	//Na estrutura, define os campos e a temporária
	oStTT:AddTable(cAliasTT, {'TT_ID'}, "Temporaria")

	//Adiciona os campos da estrutura
	oStTT:AddField("Produto"			,"Produto"			,"TT_PRODUTO"	,"C",07,00,Nil,Nil,{},.T.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_PRODUTO,'')" ), .T., .F., .F.)
	oStTT:AddField("Descricao"			,"Descricao"		,"TT_DESC"		,"C",40,00,Nil,Nil,{},.T.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_DESC,'')" ), .T., .F., .F.)
	oStTT:AddField("Item do Cliente"	,"Item do Cliente"	,"TT_ITCLI"		,"C",15,00,Nil,Nil,{},.T.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_ITCLI,'')" ), .T., .F., .F.)
	oStTT:AddField("Dt. Fat."			,"Data Fatur."		,"TT_DATFAT"	,"D",08,00,Nil,Nil,{},.F.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_DATFAT,'')" ),.F.,.F.,.F.)
	oStTT:AddField("Quantidade"			,"Quantidade"		,"TT_QTFAT"		,"N",10,02,Nil,Nil,{},.F.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_QTFAT,'')" ),.F.,.F.,.F.)
	oStTT:AddField("Vl. Unit."			,"Vl. Unit."	    ,"TT_PRCVEN"	,"N",10,02,Nil,Nil,{},.F.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_PRCVEN,'')" ),.F.,.F.,.F.)
	oStTT:AddField("Vl. Total"			,"Vl. Total"	    ,"TT_VLFAT"		,"N",10,02,Nil,Nil,{},.F.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_VLFAT,'')" ),.F.,.F.,.F.)
	oStTT:AddField("TES"	            ,"test"	            ,"TT_TES"		,"C",03,00,Nil,Nil,{},.T.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_TES,'')" ), .T., .F., .F.)
	oStTT:AddField("CFOP"	            ,"CFOP"	            ,"TT_CF"		,"C",05,00,Nil,Nil,{},.T.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_CF,'')" ), .T., .F., .F.)
	oStTT:AddField("Pedido"	            ,"Pedido"	        ,"TT_PEDIDO"	,"C",09,00,Nil,Nil,{},.T.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_PEDIDO,'')" ), .T., .F., .F.)
	oStTT:AddField("Docto."	            ,"Docto."	        ,"TT_DOC"		,"C",09,00,Nil,Nil,{},.T.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_DOC,'')" ), .T., .F., .F.)
	oStTT:AddField("Serie"	            ,"Serie"	        ,"TT_SERIE"		,"C",03,00,Nil,Nil,{},.T.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_SERIE,'')" ), .T., .F., .F.)

	oStTT:SetProperty('TT_PRODUTO'	,MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))
	oStTT:SetProperty('TT_DESC'	    ,MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))
	oStTT:SetProperty('TT_ITCLI'	,MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))
	oStTT:SetProperty('TT_DATFAT'	,MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))
	oStTT:SetProperty('TT_QTFAT'	,MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))
	oStTT:SetProperty('TT_PRCVEN'	,MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))
	oStTT:SetProperty('TT_VLFAT'	,MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))
	oStTT:SetProperty('TT_TES'	    ,MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))
	oStTT:SetProperty('TT_CF'	    ,MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))
	oStTT:SetProperty('TT_PEDIDO'   ,MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))
	oStTT:SetProperty('TT_DOC'	    ,MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))
	oStTT:SetProperty('TT_SERIE'	,MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))

	//Instanciando o modelo
	oModel:=MPFormModel():New  ("FT010M", Nil, {|oModel| MVCMODELPOS(oModel)}, Nil, Nil)

	oModel:AddFields("FORMTT",/*cOwner*/,oStTT)
	oModel:SetPrimaryKey({'TT_ID'})
	oModel:SetDescription("Modelo de Dados do Cadastro ")
	oModel:GetModel("FORMTT"):SetDescription("Formulário do Cadastro ")
Return oModel


Static Function ViewDef()
	Local oView := Nil
	Local oModel := FWLoadModel("FT010")
	Local oStTT := FWFormViewStruct():New()

	//Adicionando campos da estrutura
	oStTT:AddField("TT_PRODUTO"	,"01","Produto"			,"Produto"			,Nil,"C","@!",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTT:AddField("TT_DESC"	,"02","Descricao"		,"Descricao"		,Nil,"C","@!",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTT:AddField("TT_ITCLI"	,"03","Item do Cliente"	,"Item do Cliente"	,Nil,"C","@!",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTT:AddField("TT_DATFAT"	,"04","Dt. Fatur."		,"Dt. Fatur."		,Nil,"D","@D",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTT:AddField("TT_QTFAT"	,"05","Quantidade"		,"Quantidade"		,Nil,"N","@E 9,999,999.99",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTT:AddField("TT_PRCVEN"	,"06","Vl. Unit."       ,"Vl. Unit."  		,Nil,"N","@E 9,999,999.99",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTT:AddField("TT_VLFAT"	,"07","Vl. Total"       ,"Vl. Total"  		,Nil,"N","@E 9,999,999.99",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTT:AddField("TT_TES"	    ,"08","TES "		    ,"TES"		        ,Nil,"C","@!",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTT:AddField("TT_CF"	    ,"09","CFOP"		    ,"CFOP"		        ,Nil,"C","@!",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTT:AddField("TT_PEDIDO"  ,"10","Pedido"		    ,"Pedido"		    ,Nil,"C","@!",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTT:AddField("TT_DOC"	    ,"11","Docto."		    ,"Docto."		    ,Nil,"C","@!",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTT:AddField("TT_SERIE"	,"12","Serie"		    ,"Serie"		    ,Nil,"C","@!",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)

	//Criando a view que será o retorno da função e setando o modelo da rotina
	oView := FWFormView():New()
	oView:SetModel(oModel)
	oView:AddField("VIEW_TT", oStTT, "FORMTT")
	oView:CreateHorizontalBox("TELA",100)
	oView:EnableTitleView('VIEW_TT', 'Dados DA ORDEM DE PRODUCAO')
	oView:SetCloseOnOk({||.T.})
	oView:SetOwnerView("VIEW_TT","TELA")
Return oView


Static Function CargaTT(oSay)
	Local cSql 			:= ""
	Local cAlias 		:= ""

	cSql := "SELECT D2_COD, D2_QUANT, D2_TOTAL, D2_TES, D2_CF, D2_PEDIDO, "
	cSql += "	    D2_CLIENTE, D2_LOJA, D2_DOC, D2_SERIE, D2_EMISSAO, D2_PRCVEN, "
	cSql += "	  	B1_DESC, B1_UM, B1_XITEM "
	cSql += "  FROM " + RetSQLName("SD2") + " D2 "

	cSql += " INNER JOIN " + RetSQLName("SB1") + " SB1 "
	cSql += "	 ON B1_COD 		 	 = D2_COD"
	cSql += "   AND B1_FILIAL 	 	 = '" + xFilial("SB1") + "' "
	cSql += "	AND SB1.D_E_L_E_T_ 	 = ' ' "

	cSql += " INNER JOIN " + RetSQLName("SF4") + " SF4 "
	cSql += "	 ON F4_CODIGO 	 	 = D2_TES"
	cSql += "   AND F4_DUPLIC	 	 = 'S'"
	cSql += "   AND F4_FILIAL 	 	 = '" + xFilial("SF4") + "' "
	cSql += "	AND SF4.D_E_L_E_T_ 	 = ' ' "

	cSql += " WHERE D2_EMISSAO 	   	>= '" + dtos(dDtIni) + "'"
	cSql += "   AND D2_EMISSAO	   	<= '" + dtos(dDtFim) + "'"
	cSql += "   AND D2_CLIENTE 		 = '" + cCliente     + "'"
	cSql += "   AND D2_FILIAL 	 	 = '" + xFilial("SD2") + "' "
	cSql += "	AND D2.D_E_L_E_T_ 	 = ' ' "
	cSql += "	ORDER BY D2_COD, D2_EMISSAO, D2_DOC "
	cAlias := MPSysOpenQuery(cSql)

	While (cAlias)->(! EOF())
		cSql := "INSERT INTO " + cTableName + " ("
		cSql += " TT_ID, TT_PRODUTO, TT_DESC, TT_ITCLI, TT_DATFAT, TT_QTFAT, TT_PRCVEN, TT_VLFAT, "
		cSql += " TT_PEDIDO, TT_TES, TT_CF, TT_DOC, TT_SERIE) "
		cSql += " VALUES ('"
		cSql += FWUUIDv4() 			 				+ "','"
		cSql += (cAlias)->D2_COD 				    + "','"
		cSql += (cAlias)->B1_DESC 					+ "','"
		cSql += (cAlias)->B1_XITEM 					+ "','"
		cSql += (cAlias)->D2_EMISSAO 				+ "','"
		cSql += cValToChar((cAlias)->D2_QUANT) 		+ "','"
		cSql += cValToChar((cAlias)->D2_PRCVEN)		+ "','"
		cSql += cValToChar((cAlias)->D2_TOTAL) 		+ "','"
		cSql += (cAlias)->D2_PEDIDO 				+ "','"
		cSql += (cAlias)->D2_TES 					+ "','"
		cSql += (cAlias)->D2_CF 					+ "','"
		cSql += (cAlias)->D2_DOC 					+ "','"
		cSql += (cAlias)->D2_SERIE 					+ "')"

		if TCSqlExec(cSql) < 0
			MsgInfo("Erro na execução da query:", "Atenção")
			MsgInfo(TcSqlError(), "Atenção3")
		endif

		(cAlias)->(DbSkip())
	enddo

	(cAlias)->(DBCLOSEAREA())
return
