#Include 'Protheus.ch'
#Include 'FWMVCDef.ch'

/*/{Protheus.doc} PL300
Função: Consulta de ordens de producaoi
@author Assis
@since 08/12/2024
@version 1.0
	@return Nil, Fução não tem retorno
	@example
	u_PL300()
/*/

Static cTitulo := "Ordens de Producao"

User Function PL300()
	Local aArea 		:= FWGetArea()
	Local aCampos 		:= {}
	Local aColunas 		:= {}
	Local aPesquisa 	:= {}
	Local aIndex 		:= {}

	Private oBrowse		:= ''
	Private cFiltro		:= ''
	Private cTppr 		:= ''
	Private cTpop 		:= ''
	Private cLinprd 	:= ''
	Private aRotina 	:= {}
	Private cTableName 	:= ''
	Private cAliasTT 	:= GetNextAlias()

	//Definicao do menu
	aRotina := MenuDef()

	SetKey( VK_F12,  {|| u_PL300F12()} )

	//Campos da temporária
	aAdd(aCampos, {"TT_ID"		,"C", 36, 0})

	// dados do item
	aAdd(aCampos, {"TT_PRODUTO"	,"C", 15, 0})
	aAdd(aCampos, {"TT_DESC"	,"C", 60, 0})
	aAdd(aCampos, {"TT_TIPO"	,"C",  3, 0})
	aAdd(aCampos, {"TT_CLIENT"	,"C", 30, 0})
	aAdd(aCampos, {"TT_LINPRD"	,"C", 01, 0})
	aAdd(aCampos, {"TT_XITEM"	,"C", 20, 0})
	aAdd(aCampos, {"TT_UM"		,"C", 02, 0})
	aAdd(aCampos, {"TT_ESTSEG"	,"N", 14, 3})
	aAdd(aCampos, {"TT_LE"		,"N", 12, 2})
	aAdd(aCampos, {"TT_SIT"		,"C", 10, 0})

	// dados da op
	aAdd(aCampos, {"TT_NUM"		,"C", 06, 0})
	aAdd(aCampos, {"TT_ITEM"	,"C", 02, 0})
	aAdd(aCampos, {"TT_SEQUEN"	,"C", 03, 0})
	aAdd(aCampos, {"TT_PRTOP"	,"C", 01, 0})
	aAdd(aCampos, {"TT_TPOP"	,"C", 01, 0})
	aAdd(aCampos, {"TT_TPPR"	,"C", 01, 0})
	aAdd(aCampos, {"TT_DATPRI"	,"D", 08, 0})
	aAdd(aCampos, {"TT_DATPRF"	,"D", 08, 0})
	aAdd(aCampos, {"TT_QUANT"	,"N", 14, 3})
	aAdd(aCampos, {"TT_QUJE"	,"N", 14, 3})

	// dados de saldo
	aAdd(aCampos, {"TT_SALDO"	,"N", 14, 3})
	aAdd(aCampos, {"TT_CONS"	,"N", 14, 3})
	aAdd(aCampos, {"TT_DMOV"	,"D", 08, 0})
	aAdd(aCampos, {"TT_DIAS"	,"N", 10, 2})
	aAdd(aCampos, {"TT_FALTA"	,"C", 01, 0})

	//Cria a temporária
	oTempTable := FWTemporaryTable():New(cAliasTT)
	oTempTable:SetFields(aCampos)

	oTempTable:AddIndex("1", {"TT_ID"} )
	oTempTable:AddIndex("2", {"TT_PRODUTO"} )
	oTempTable:AddIndex("3", {"TT_CLIENT" , "TT_PRODUTO"} )
	oTempTable:AddIndex("4", {"TT_DATPRF" , "TT_PRODUTO"} )
	oTempTable:AddIndex("5", {"TT_LINPRD" , "TT_DATPRF", "TT_PRODUTO"} )
	oTempTable:Create()

	cTableName  := oTempTable:GetRealName()

	aAdd(aCampos, {"TT_ID"			,"C", 10, 0})

	//Definindo as colunas que serão usadas no browse
	aAdd(aColunas, {"Ordem"			, "TT_NUM"		, "C", 06, 0, "@!"})
	aAdd(aColunas, {"Item"			, "TT_ITEM"		, "C", 02, 0, "@!"})
	aAdd(aColunas, {"Seq."			, "TT_SEQUEN"	, "C", 03, 0, "@!"})
	aAdd(aColunas, {"Prt."			, "TT_PRTOP"	, "C", 01, 0, "@!"})
	aAdd(aColunas, {"Produto"		, "TT_PRODUTO"	, "C", 08, 0, "@!"})
	aAdd(aColunas, {"Tipo"			, "TT_TIPO"		, "C", 02, 0, "@!"})
	aAdd(aColunas, {"Lin."			, "TT_LINPRD"	, "C", 01, 0, "@!"})
	aAdd(aColunas, {"Cliente"		, "TT_CLIENT"	, "C", 10, 0, "@!"})
	aAdd(aColunas, {"Item Cli."		, "TT_XITEM"	, "C", 10, 0, "@!"})
	aAdd(aColunas, {"Inicio"		, "TT_DATPRI"	, "D", 06, 0, "@!"})
	aAdd(aColunas, {"Fim"			, "TT_DATPRF"	, "D", 06, 0, "@!"})
	aAdd(aColunas, {"Quant."		, "TT_QUANT"	, "N", 08, 0, "@E 9,999,999.999"})
	aAdd(aColunas, {"UM"			, "TT_UM"		, "C", 01, 0, "@!"})
	aAdd(aColunas, {"Produzida"		, "TT_QUJE"		, "N", 08, 0, "@E 9,999,999.999"})
	aAdd(aColunas, {"Saldo"			, "TT_SALDO"	, "N", 08, 0, "@E 9,999,999.999"})
	aAdd(aColunas, {"Lote"			, "TT_LE"		, "N", 08, 0, "@E 9,999,999.999"})
	aAdd(aColunas, {"Consumo"		, "TT_CONS"		, "N", 08, 0, "@E 9,999,999.999"})
	aAdd(aColunas, {"Ult.Mov."		, "TT_DMOV"		, "D", 06, 0, "@!"})
	aAdd(aColunas, {"Dias"			, "TT_DIAS"		, "N", 06, 2, "@E 999,999.99"})
	aAdd(aColunas, {"Segur."		, "TT_ESTSEG"	, "N", 08, 0, "@E 9,999,999.999"})
	aAdd(aColunas, {"Sit."			, "TT_SIT"		, "C", 01, 0, "@!"})
	aAdd(aColunas, {"Descricao"		, "TT_DESC"		, "C", 30, 0, "@!"})

	aAdd(aPesquisa, {"Entrega"	, {{"", "D",  08, 0, "Entrega" 	, "@!", "TT_DATPRF"}} } )
	aAdd(aPesquisa, {"Produto"	, {{"", "C",  15, 0, "Produto" 	, "@!", "TT_PRODUTO"}} } )
	aAdd(aPesquisa, {"Cliente"	, {{"", "C",  06, 0, "Cliente" 	, "@!", "TT_CLIENT"}} } )

	aAdd(aIndex, {"TT_DATPRF" , "TT_PRODUTO"} )
	aAdd(aIndex, {"TT_LINPRD" , "TT_DATPRF" , "TT_PRODUTO"} )
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

	oBrowse:AddLegend("TT_TPOP == 'F' .and. TT_FALTA != 'F'", "GREEN" , "Ordem Firme", "1")
	oBrowse:AddLegend("TT_TPOP == 'P' .and. TT_FALTA != 'F'", "YELLOW", "Ordem Prevista", "1")
	oBrowse:AddLegend("TT_TPOP == 'F' .and. TT_FALTA == 'F'", "RED"   , "Ordem Firme - Sem saldo de materia prima", "1")
	oBrowse:AddLegend("TT_TPOP == 'P' .and. TT_FALTA == 'F'", "PINK"  , "Ordem Prevista - Sem saldo de materia prima", "1")

	CargaTT()

	u_PL300F12()

	oBrowse:Activate()

	oTempTable:Delete()
	FWRestArea(aArea)
Return Nil


/*/{Protheus.doc} MenuDef
Menu de opcoes na funcao PL300
@author Assis
@since 19/06/2024
@version 1.0
/*/
Static Function MenuDef()
	Local aRotina := {}
	ADD OPTION aRotina TITLE "Visualizar" 		ACTION "VIEWDEF.PL300" 		OPERATION 2 ACCESS 0
	ADD OPTION aRotina TITLE 'Imprimir Ordem'	ACTION 'u_PL300Imprimir'	OPERATION 7 ACCESS 0
	ADD OPTION aRotina TITLE 'Legenda'    		ACTION 'u_PL300Legenda' 	OPERATION 8 ACCESS 0
Return aRotina

/*/{Protheus.doc} ModelDef
Modelo de dados na funcao PL300
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
	oStTmp:AddField("Est. Segur."	,"Est. Segur."	,"TT_ESTSEG"	,"N",10,02,Nil,Nil,{},.F.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_ESTSEG,'')" ),.F.,.F.,.F.)
	oStTmp:AddField("Saldo Estoq."	,"Saldo Estoq."	,"TT_SALDO"		,"N",10,02,Nil,Nil,{},.F.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_SALDO,'')" ),.F.,.F.,.F.)
	oStTmp:AddField("UM"			,"UM"			,"TT_UM"		,"C",02,00,Nil,Nil,{},.F.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_UM,'')" ),.F.,.F.,.F.)
	oStTmp:AddField("Dt Movimento"	,"Dt Movimento"	,"TT_DMOV"		,"D",08,00,Nil,Nil,{},.F.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_DMOV,'')" ),.F.,.F.,.F.)
	oStTmp:AddField("Dias Estoque"	,"Dias Estoque"	,"TT_DIAS"		,"N",10,02,Nil,Nil,{},.F.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_DIAS,'')" ),.F.,.F.,.F.)
	oStTmp:AddField("Situacao"		,"Situacao"		,"TT_SIT"		,"C",10,00,Nil,Nil,{},.F.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_SIT,'')" ),.F.,.F.,.F.)

	//Instanciando o modelo
	oModel := MPFormModel():New("PL300M",/*bPre*/, /*bPos*/,/*bCommit*/,/*bCancel*/)
	oModel:AddFields("FORMTT",/*cOwner*/,oStTMP)
	oModel:SetPrimaryKey({'TT_ID'})
	oModel:SetDescription("Modelo de Dados do Cadastro ")
	oModel:GetModel("FORMTT"):SetDescription("Formulário do Cadastro ")
Return oModel

/*/{Protheus.doc} ViewDef
Visualizacao de dados na funcao PL300
@author Assis
@since 19/06/2024
@version 1.0
/*/

Static Function ViewDef()
	Local oView := Nil
	Local oModel := FWLoadModel("PL300")
	Local oStTMP := FWFormViewStruct():New()

	//Adicionando campos da estrutura
	oStTmp:AddField("TT_PRODUTO"	,"01","Codigo"		,"Codigo"		,Nil,"C","@!",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTmp:AddField("TT_DESC"		,"02","Descricao"	,"Descricao"	,Nil,"C","@!",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTmp:AddField("TT_TIPO"		,"03","Tipo"		,"Tipo"			,Nil,"C","@!",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTmp:AddField("TT_CLIENT"		,"04","Cliente"		,"Cliente"		,Nil,"C","@!",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTmp:AddField("TT_ITEM"		,"05","Item Cliente","Item Cliente"	,Nil,"C","@!",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTmp:AddField("TT_ESTSEG"		,"07","Est. Segur."	,"Est. Segur."	,Nil,"N","@E 9,999,999.99",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTmp:AddField("TT_SALDO"		,"08","Saldo"		,"Saldo"		,Nil,"N","@E 9,999,999.99",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTmp:AddField("TT_UM"			,"10","UM"			,"UM"			,Nil,"C","@!",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTmp:AddField("TT_DIAS"		,"12","Dias Estoque","Dias Estoque"	,Nil,"N","@E 9,999,999.99",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTmp:AddField("TT_DMOV"		,"13","Dt Movimento","Dt Movimento"	,Nil,"D","@!",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTmp:AddField("TT_SIT"		,"14","Situacao"	,"Situacao"		,Nil,"C","@!",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)

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
	Local nQtNec 	:= 0
	Local nDias		:= 0
	Local cSit		:= ''
	Local lRet		:= .T.

	cSql := "SELECT B1_COD, B1_DESC, B1_XCLIENT, B1_TIPO, B1_XITEM, B1_LE, B1_PE, B1_UM, B1_ESTSEG, B1_XSIT, B1_XLINPRD, "
	cSql += "		 C2_NUM, C2_ITEM, C2_SEQUEN, C2_DATPRI, C2_DATPRF, C2_QUANT, C2_QUJE, C2_TPOP, C2_TPPR, C2_XPRTOP, "
	cSql += "		 B2_QATU, B2_QEMP, B2_DMOV, B2_VATU1 "
	cSql += "  FROM " + RetSQLName("SC2") + " SC2 "

	cSql += " INNER JOIN " + RetSQLName("SB1") + " SB1 "
	cSql += "    ON B1_COD           = C2_PRODUTO "
	cSql += "   AND B1_FILIAL      	 = '" + xFilial("SB1") + "'"
	cSql += "   AND SB1.D_E_L_E_T_  <> '*' "

	cSql += " LEFT OUTER JOIN " + RetSQLName("SB2") + " SB2 "
	cSql += "    ON B1_COD      	 = B2_COD "
	cSql += "   AND B2_FILIAL      	 = '" + xFilial("SB2") + "'"
	cSql += "   AND B2_LOCAL      	<> '99'"
	cSql += "   AND B2_QATU      	<> 0 "
	cSql += "   AND SB2.D_E_L_E_T_  <> '*' "

	cSql += " WHERE C2_FILIAL      	 = '" + xFilial("SC2") + "'"
	cSql += "   AND C2_DATRF       	 = ''"
	cSql += "   AND C2_QUANT		 > C2_QUJE "
	cSql += "   AND SC2.D_E_L_E_T_  <> '*' "
	cSql += " ORDER BY C2_DATPRF, B1_XLINPRD, B1_COD "
	cAlias := MPSysOpenQuery(cSql)

	SB3->(dbSetOrder(1))

	While (cAlias)->(!EOF())

		nQtNec := (cAlias)->C2_QUANT - (cAlias)->C2_QUJE

		lRet := Estrutura((cAlias)->B1_COD, nQtNec)

		cSql := "INSERT INTO " + cTableName + " ("
		cSql += "	TT_ID, TT_PRODUTO, TT_DESC, TT_CLIENT, TT_ESTSEG, TT_LE, TT_SALDO, TT_TIPO, TT_XITEM, TT_DMOV, TT_SIT, TT_CONS, TT_DIAS, TT_UM, TT_TPOP, TT_TPPR, TT_LINPRD, "
		cSql += "	TT_NUM, TT_ITEM, TT_SEQUEN, TT_DATPRI, TT_DATPRF, TT_QUANT, TT_QUJE, TT_PRTOP, TT_FALTA ) VALUES ('"
		cSql += FWUUIDv4() 			 				+ "','"
		cSql += (cAlias)->B1_COD 					+ "','"
		cSql += (cAlias)->B1_DESC    				+ "','"
		cSql += (cAlias)->B1_XCLIENT 				+ "','"
		cSql += cValToChar((cAlias)->B1_ESTSEG)		+ "','"
		cSql += cValToChar((cAlias)->B1_LE)			+ "','"
		cSql += cValToChar((cAlias)->B2_QATU) 		+ "','"
		cSql += (cAlias)->B1_TIPO   				+ "','"
		cSql += (cAlias)->B1_XITEM   				+ "','"
		cSql += (cAlias)->B2_DMOV   				+ "','"

		cSit := ''
		if (cAlias)->B1_XSIT == 'A'
			cSit := "PA"
		elseif (cAlias)->B1_XSIT == 'I'
			cSit := "Inativo"
		elseif (cAlias)->B1_XSIT == 'D'
			cSit := "Desenv."
		endif
		cSql += cSit   								+ "','"

		nDias	:= 0

		If SB3->(MsSeek(xFilial("SB3") + (cAlias)->B1_COD))
			nDias := SB3->B3_MEDIA
			cSql += cValToChar(SB3->B3_MEDIA)		+ "','"
		else
			cSql += "0','"
		endif

		if nDias <> 0
			nDias := (cAlias)->B2_QATU / nDias * 30
		else
			ndias := 9999
		endif

		cSql += cValToChar(ndias)   				+ "','"
		cSql += (cAlias)->B1_UM   					+ "','"

		cSql += (cAlias)->C2_TPOP   				+ "','"
		cSql += (cAlias)->C2_TPPR   				+ "','"
		cSql += (cAlias)->B1_XLINPRD   				+ "','"
		cSql += (cAlias)->C2_NUM   					+ "','"
		cSql += (cAlias)->C2_ITEM   				+ "','"
		cSql += (cAlias)->C2_SEQUEN   				+ "','"
		cSql += (cAlias)->C2_DATPRI   				+ "','"
		cSql += (cAlias)->C2_DATPRF   				+ "','"
		cSql += cValToChar((cAlias)->C2_QUANT)   	+ "','"
		cSql += cValToChar((cAlias)->C2_QUJE)   	+ "','"
		cSql += (cAlias)->C2_XPRTOP   				+ "','"

		if lRet == .F.
			cSql += "F')"
		else
			cSql += "')"
		endif

		if TCSqlExec(cSql) < 0
			MsgInfo("Erro na execução da query:", "Atenção")
			MsgInfo(TcSqlError(), "Atenção2")
		endif

		(cAlias)->(DbSkip())
	End While
return


/*---------------------------------------------------------------------*
  Ler os parametros do usuario
 *---------------------------------------------------------------------*/
User Function PL300F12()
	Local aPergs	:= {}
	Local aResps	:= {}

	Local aTppr		:= {'Interna', 'Externa'}
	Local aLinprd	:= {'Estamparia', 'Solda'}
	Local aTpop		:= {'Todas', 'Firmes', 'Previstas'}
	
	AAdd(aPergs, {2, "Tipo de Producao"		, cTpop,   aTppr,   70, ".T.", .F.})
	AAdd(aPergs, {2, "Linha de producao"	, cLinprd, aLinprd, 70, ".T.", .F.})
	AAdd(aPergs, {2, "Tipo de OP"			, cTpop,   aTpop,   70, ".T.", .F.})

	cFiltro := ""

	If ParamBox(aPergs, "PL300 - ORDENS DE PRODUCAO", @aResps,,,,,,,, .T., .T.)
		cTppr 		:= aResps[1]
		cLinprd 	:= aResps[2]
		cTpop 		:= aResps[3]

		// TPPR
		IF cTppr == 'Interna'
			cTppr := 'I'
		else
			cTppr := 'E'
		endif

		if cFiltro	<> ''
			cFiltro += " .and. "
		endif

		cFiltro += "TT_TPPR == '" + cTppr + "'"

		// LINPRD
		IF cLinprd == 'Estamparia'
			cLinprd := 'E'
		else
			cLinprd := 'S'
		endif

		if cFiltro	<> ''
			cFiltro += " .and. "
		endif

		cFiltro += "TT_LINPRD == '" + cLinprd + "'"

		// TPOP
		if cTpop == 'Todas'
			cTpop := ''
		elseif cTpop == 'Firmes'
			cTpop := 'F'
		elseif cTpop == 'Previstas'
			cTpop := 'P'
		endif

		if cTpop <> ''
			if cFiltro	<> ''
				cFiltro += " .and. "
			endif

			cFiltro += "TT_TPOP == '" + cTpop + "'"
		endif

		oBrowse:CleanFilter()
		oBrowse:SetFilterDefault(cFiltro)
		oBrowse:Refresh()
	endif
return


/*---------------------------------------------------------------------*
  Explode a estrutura para calcular o saldo de materia prima
 *---------------------------------------------------------------------*/
Static Function	Estrutura(cProduto, nQtPai)
	Local lRet		:= .T.
	Local cSql 		:= ""
	Local nQtNec 	:= 0
	Local cAliasSG1
	Local cAliasSB2

	cSql := "SELECT G1_COD, G1_COMP, G1_QUANT, G1_INI, G1_FIM, G1_FANTASM "
	cSql += "  FROM " + RetSQLName("SG1") + " SG1 "

	cSql += " INNER JOIN " + RetSQLName("SB1") + " SB1 "
	csQL += "	 ON B1_COD			=  G1_COMP "
	cSql += "   AND B1_MSBLQL 		=  '2' "
	cSql += "   AND B1_FILIAL 		= '" + xFilial("SB1") + "' "
	cSql += "   AND SB1.D_E_L_E_T_ 	= ' ' "

	cSql += " WHERE G1_COD 			= '" + cProduto + "' "
	cSql += "   AND G1_INI 		   <= '" + DTOS(Date()) + "' "
	cSql += "   AND G1_FIM 		   >= '" + DTOS(Date()) + "' "
	cSql += "   AND G1_FILIAL 		= '" + xFilial("SG1") + "' "
	cSql += "   AND SG1.D_E_L_E_T_ 	= ' ' "
	cAliasSG1 := MPSysOpenQuery(cSql)

	While (cAliasSG1)->(!EOF())
		nQtNec := nQtPai * (cAliasSG1)->G1_QUANT

		// Ler o saldo do componente
		cSql := "SELECT B2_QATU FROM " + RetSQLName("SB2") + " SB2 "
		cSql += " WHERE B2_COD    		=  '" + (cAliasSG1)->G1_COMP + "'"
		cSql += "   AND B2_FILIAL 		=  '" + xFilial("SB2") + "'"
		cSql += "   AND SB2.D_E_L_E_T_  <> '*' "
		cAliasSB2 := MPSysOpenQuery(cSql)

		if nQtNec > (cAliasSB2)->B2_QATU
			lRet := .F.
		endif

		(cAliasSB2)->(DBCLOSEAREA())
		(cAliasSG1)->(DbSkip())
	EndDo

	(cAliasSG1)->(DBCLOSEAREA())
return lRet


/*---------------------------------------------------------------------*
  Legendas
 *---------------------------------------------------------------------*/
User Function PL300Legenda()
    Local aLegenda := {}
    AAdd(aLegenda,{"BR_VERDE"   	,"Ordem firme"})
    AAdd(aLegenda,{"BR_VERMELHO"	,"Ordem firme - Sem saldo de componente ou MP"})
    AAdd(aLegenda,{"BR_AMARELO"   	,"Ordem prevista"})
    AAdd(aLegenda,{"BR_PINK"		,"Ordem prevista - Sem saldo de componente ou MP"})
    BrwLegenda("Legenda", "Tipo", aLegenda)
return



/*---------------------------------------------------------------------*
  Imprimir OP
 *---------------------------------------------------------------------*/
User Function PL300Imprimir()
	Local aArea    	:= GetArea()

	if TT_PRTOP == 'S'	// Ja foi impressa
		u_PL010A(TT_NUM + TT_ITEM + TT_SEQUEN, .F., .T.)
	else
		u_PL010A(TT_NUM + TT_ITEM + TT_SEQUEN, .F., .F.)
	endif
		
	Sleep(1000)

	RestArea(aArea)
Return NIL

