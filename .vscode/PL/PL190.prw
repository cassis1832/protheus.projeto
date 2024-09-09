#Include "PROTHEUS.CH"
#Include "RPTDEF.CH"
#Include "TBICONN.CH"
#Include 'FWMVCDef.ch'

/*/{Protheus.doc}	PL190
	Extrair dados de ordens de produção para controle de empenho
@author Carlos Assis
@since 02/09/2024
@version 1.0   
/*/

User Function PL190()
	Local aArea 		:= FWGetArea()
	Local aCampos 		:= {}
	Local aColunas 		:= {}
	Local aPesquisa 	:= {}
	Local aIndex 		:= {}

	Local oSay 			:= NIL
	Local aPergs		:= {}
	Local aResps		:= {}
	Local aComboLin		:= {"Estamparia","Solda"}
	Local aComboSit		:= {"Nao empenhadas","Empenhadas", "Todas"}

	Private oBrowse		:= Nil
	Private cMarca 		:= GetMark()
	Private cTitulo		:= "Ordens de Producao para Empenho"
	Private aRotina 	:= {}
	Private cTableName 	:= ""
	Private cAliasTT 	:= GetNextAlias()

	Private dDtIni  	:= ""
	Private dDtFim  	:= ""
	Private nLinha 		:= ""
	Private nStatus 	:= ""

	//Definicao do menu
	aRotina := MenuDef()

	AAdd(aPergs, {1, "Informe a data inicial "	, CriaVar("C2_DATPRF",.F.),"",".T.","",".T.", 70, .F.})
	AAdd(aPergs, {1, "Informe a data final "	, CriaVar("C2_DATPRF",.F.),"",".T.","",".T.", 70, .F.})
	AAdd(aPergs ,{2, "Linha de producao:"	,01, aComboLin, 70, "", .T.})
	AAdd(aPergs ,{2, "Situacao do empenho:"	,01, aComboSit, 70, "", .T.})

	If ParamBox(aPergs, "Selecao de Ordens", @aResps,,,,,,,, .T., .T.)
		dDtIni 	:= aResps[1]
		dDtFim 	:= aResps[2]
		nLinha	:= aResps[3]
		nStatus	:= aResps[4]
	Else
		return
	endif

	//Campos da temporária
	aAdd(aCampos, {"TT_ID"		,"C", 36, 0})
	aAdd(aCampos, {"TT_PRODUTO"	,"C", 15, 0})
	aAdd(aCampos, {"TT_DESC"	,"C", 60, 0})
	aAdd(aCampos, {"TT_CLIENT"	,"C", 20, 0})
	aAdd(aCampos, {"TT_ITCLI"	,"C", 20, 0})
	aAdd(aCampos, {"TT_OP"		,"C", 11, 0})
	aAdd(aCampos, {"TT_RECURSO"	,"C", 06, 0})
	aAdd(aCampos, {"TT_QUANT"	,"N", 14, 3})
	aAdd(aCampos, {"TT_DTINIP"	,"D", 08, 0})
	aAdd(aCampos, {"TT_HRINIP"	,"C", 05, 0})
	aAdd(aCampos, {"TT_PRTOP"	,"C", 01, 0})
	aAdd(aCampos, {"TT_PRTPL"	,"C", 01, 0})
	aAdd(aCampos, {"TT_SITEMP"	,"C", 01, 0})
	aAdd(aCampos, {"TT_OBSEMP"	,"C", 60, 0})
	aAdd(aCampos, {"TT_OK"		,"C", 02, 0})

	//Cria a temporária
	oTempTable := FWTemporaryTable():New(cAliasTT)
	oTempTable:SetFields(aCampos)

	// Sem esses indices a caixa de filtrar não funciona
	oTempTable:AddIndex("1", {"TT_ID"} )
	oTempTable:AddIndex("2", {"TT_PRODUTO"} )
	oTempTable:AddIndex("3", {"TT_RECURSO"} )
	oTempTable:Create()

	cTableName  := oTempTable:GetRealName()

	FwMsgRun(NIL, {|oSay| CargaTT(oSay)}, "Processando ordens de producao", "Extraindo dados...")

	//Definindo as colunas que serão usadas no browse
	aAdd(aColunas, {"Recurso"			, "TT_RECURSO"	, "C", 06, 0, "@!"})
	aAdd(aColunas, {"Produto"			, "TT_PRODUTO"	, "C", 08, 0, "@!"})
	aAdd(aColunas, {"Descricao"			, "TT_DESC"		, "C", 20, 0, "@!"})
	aAdd(aColunas, {"Cliente"			, "TT_CLIENT"	, "C", 08, 0, "@!"})
	aAdd(aColunas, {"Item Cliente"		, "TT_ITCLI"	, "C", 08, 0, "@!"})
	aAdd(aColunas, {"Ordem"				, "TT_OP"		, "C", 08, 0, "@!"})
	aAdd(aColunas, {"Quant."			, "TT_QUANT"	, "N", 05, 3, "@E 9,999,999.999"})
	aAdd(aColunas, {"Dt. Ini. Prev."	, "TT_DTINIP"	, "D", 06, 0, "@D"})
	aAdd(aColunas, {"Hr. Ini. Prev."	, "TT_HRINIP"	, "C", 05, 0, "99:99"})
	aAdd(aColunas, {"Prt. OP"			, "TT_PRTOP"	, "C", 01, 0, "@!"})
	aAdd(aColunas, {"Prt. PL"			, "TT_PRTPL"	, "C", 01, 0, "@!"})
	aAdd(aColunas, {"Sit. Empenho"		, "TT_SITEMP"	, "C", 01, 0, "@!"})
	aAdd(aColunas, {"Obs. Empenho"		, "TT_OBSEMP"	, "C", 10, 0, "@!"})

	// Para aparecer caixa de filtrar
	aAdd(aPesquisa, {"Recurso"		, {{"", "C",  6, 0, "Recurso" 	 , "@!", "TT_RECURSO"}} } )
	aAdd(aPesquisa, {"Produto"		, {{"", "C", 15, 0, "Produto" 	 , "@!", "TT_PRODUTO"}} } )
	aAdd(aPesquisa, {"Dt. Inicio"	, {{"", "D", 10, 0, "Dt. Inicio" , "@!", "TT_DTINIP"}} } )

	aAdd(aIndex, {"TT_RECURSO", "TT_DTINIP"} )

	//Criando o browse da temporária
	oBrowse := FWMarkBrowse():New()
	oBrowse:SetAlias(cAliasTT)
	oBrowse:SetTemporary(.T.)
	oBrowse:SetFields(aColunas)
	oBrowse:DisableDetails()
	oBrowse:SetDescription(cTitulo)
	oBrowse:SetSeek(.T., aPesquisa)

	oBrowse:SetFieldMark( 'TT_OK' )
	oBrowse:SetMark(cMarca, cAliasTT, "TT_OK")
	oBrowse:SetAllMark( { || oBrowse:AllMark() } )

	// oBrowse:AddLegend("TT_TPOP == 'P'", "YELLOW", "Prevista")
	// oBrowse:AddLegend("TT_TPOP == 'F'", "GREEN",  "Em aberto")

	oBrowse:Activate()

	oTempTable:Delete()
	FWRestArea(aArea)
return



/*/{Protheus.doc} MenuDef
Menu de opcoes na funcao pl190
@author Assis
@since 19/06/2024
@version 1.0
/*/
Static Function MenuDef()
	Local aRot := {}
	ADD OPTION aRot TITLE 'Visualizar' 	  	ACTION 'VIEWDEF.PL190'  OPERATION 2 ACCESS 0
	ADD OPTION aRot TITLE 'Alterar'    	  	ACTION 'VIEWDEF.PL190'  OPERATION 4 ACCESS 0
	ADD OPTION aRot TITLE 'Legenda'    	  	ACTION 'u_PL190ProLeg'  OPERATION 8 ACCESS 0
	ADD OPTION aRot TITLE 'Picking-list'  	ACTION 'u_PL190Picking' OPERATION 9 ACCESS 0
	ADD OPTION aRot TITLE 'Liberar Empenho'	ACTION 'u_PL190Lib' 	OPERATION 9 ACCESS 0
Return aRot


/*/{Protheus.doc} ModelDef
Modelo de dados na funcao pl190
@author Assis
@since 19/06/2024
@version 1.0
/*/
Static Function ModelDef()
	Local oModel := Nil
	Local oStTT := FWFormModelStruct():New()

	//Na estrutura, define os campos e a temporária
	oStTT:AddTable(cAliasTT, {'TT_ID'}, "Temporaria")

	//Adiciona os campos da estrutura
	oStTT:AddField("Ordem"				,"Ordem"			,"TT_OP"		,"C",11,00,Nil,Nil,{},.F.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_OP,'')" ),.F.,.F.,.F.)
	oStTT:AddField("Produto"			,"Produto"			,"TT_PRODUTO"	,"C",07,00,Nil,Nil,{},.T.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_PRODUTO,'')" ), .T., .F., .F.)
	oStTT:AddField("Descricao"			,"Descricao"		,"TT_DESC"		,"C",40,00,Nil,Nil,{},.T.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_DESC,'')" ), .T., .F., .F.)
	oStTT:AddField("Cliente"			,"Cliente"			,"TT_CLIENT"	,"C",15,00,Nil,Nil,{},.T.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_CLIENT,'')" ), .T., .F., .F.)
	oStTT:AddField("Item do Cliente"	,"Item do Cliente"	,"TT_ITCLI"		,"C",15,00,Nil,Nil,{},.T.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_ITCLI,'')" ), .T., .F., .F.)
	oStTT:AddField("Recurso"			,"Recurso"			,"TT_RECURSO"	,"C",10,00,Nil,Nil,{},.F.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_RECURSO,'')" ),.F.,.F.,.F.)
	oStTT:AddField("Dt. Inicio Prev."	,"Dt. Inicio Prev."	,"TT_DTINIP"	,"D",08,00,Nil,Nil,{},.F.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_DTINIP,'')" ),.F.,.F.,.F.)
	oStTT:AddField("Hr. Inicio Prev."	,"Hr. Inicio Prev."	,"TT_HRINIP"	,"C",05,00,Nil,Nil,{},.F.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_HRINIP,'')" ),.F.,.F.,.F.)
	oStTT:AddField("Quantidade"			,"Quantidade"		,"TT_QUANT"		,"N",10,02,Nil,Nil,{},.F.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_QUANT,'')" ),.F.,.F.,.F.)
	oStTT:AddField("Sit. Emp."			,"Sit. Emp."		,"TT_SITEMP"	,"C",01,00,Nil,Nil,{},.F.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_SITEMP,'')" ),.F.,.F.,.F.)
	oStTT:AddField("Obs. Empenho"		,"Obs. Empenho"		,"TT_OBSEMP"	,"C",40,00,Nil,Nil,{},.F.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_OBSEMP,'')" ), .F., .F., .F.)

	oStTT:SetProperty('TT_OP'		,MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))
	oStTT:SetProperty('TT_PRODUTO'	,MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))
	oStTT:SetProperty('TT_CLIENT'	,MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))
	oStTT:SetProperty('TT_ITCLI'	,MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))
	oStTT:SetProperty('TT_DESC'		,MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))
	oStTT:SetProperty('TT_QUANT'	,MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))
	oStTT:SetProperty('TT_RECURSO'	,MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))
	oStTT:SetProperty('TT_DTINIP'	,MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))
	oStTT:SetProperty('TT_HRINIP'	,MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))
	oStTT:SetProperty('TT_SITEMP'	,MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))

	//Instanciando o modelo
	oModel:=MPFormModel():New  ("PL190M", Nil, {|oModel| MVCMODELPOS(oModel)}, Nil, Nil)

	oModel:AddFields("FORMTT",/*cOwner*/,oStTT)
	oModel:SetPrimaryKey({'TT_ID'})
	oModel:SetDescription("Modelo de Dados do Cadastro ")
	oModel:GetModel("FORMTT"):SetDescription("Formulário do Cadastro ")
Return oModel


/*/{Protheus.doc} ViewDef
Visualizacao de dados na funcao pl190
@author Assis
@since 19/06/2024
@version 1.0
/*/

Static Function ViewDef()
	Local oView := Nil
	Local oModel := FWLoadModel("PL190")
	Local oStTT := FWFormViewStruct():New()

	//Adicionando campos da estrutura
	oStTT:AddField("TT_OP"		,"01","Ordem"			,"Ordem"			,Nil,"C","@!",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTT:AddField("TT_PRODUTO"	,"03","Produto"			,"Produto"			,Nil,"C","@!",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTT:AddField("TT_DESC"	,"04","Descricao"		,"Descricao"		,Nil,"C","@!",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTT:AddField("TT_CLIENT"	,"05","Cliente"			,"Cliente"			,Nil,"C","@!",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTT:AddField("TT_ITCLI"	,"06","Item do Cliente"	,"Item do Cliente"	,Nil,"C","@!",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTT:AddField("TT_RECURSO"	,"15","Recurso"			,"Recurso"			,Nil,"C","@!",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTT:AddField("TT_DTINIP"	,"17","Dt. Inicio Prev.","Dt. Inicio Prev."	,Nil,"D","@D",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTT:AddField("TT_HRINIP"	,"18","Hr. Inicio Prev.","Hr. Inicio Prev."	,Nil,"C","@!",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTT:AddField("TT_QUANT"	,"19","Quantidade"		,"Quantidade"		,Nil,"N","@E 9,999,999.99",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTT:AddField("TT_SITEMP"	,"25","Sit. Empenho"	,"Sit. Empenho"		,Nil,"C","@!",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTT:AddField("TT_OBSEMP"	,"27","Obs. Empenho"	,"Obs. Empenho"		,Nil,"C","@!",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)

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
	Local cOP 			:= ''
	Local cLinha		:= ""

	if nLinha == 1
		cLinha := "Estamparia"
	else
		cLinha := "Solda"
	endif

	cSql := "SELECT C2_NUM, C2_ITEM, C2_SEQUEN, C2_PRODUTO, "
	cSql += "	    C2_QUANT, C2_DATPRI, C2_DATPRF, C2_XPRTPL,"
	cSql += "	    C2_XDTINIP, C2_XHRINIP, C2_XSITEMP, C2_XOBSEMP, "
	cSql += "	  	B1_COD, B1_DESC, B1_UM, B1_XCLIENT, B1_XITEM, "
	cSql += "	    G2_OPERAC, G2_RECURSO, "
	cSql += "	  	H1_XLIN, H1_XLOCLIN, H1_XTIPO, H1_XNOME "
	cSql += "  FROM " + RetSQLName("SC2") + " SC2 "

	cSql += " INNER JOIN " + RetSQLName("SB1") + " SB1 "
	cSql += "	 ON B1_COD 		 	 = C2_PRODUTO"
	cSql += "   AND B1_FILIAL 	 	 = '" + xFilial("SB1") + "' "
	cSql += "   AND B1_XLINPRD 	 	 = '" + cLinha + "' "
	cSql += "	AND SB1.D_E_L_E_T_ 	 = ' ' "

	cSql += " INNER JOIN " + RetSQLName("SG2") + " SG2 "
	cSql += "    ON G2_PRODUTO 		 = C2_PRODUTO"
	cSql += "   AND G2_FILIAL		 = '" + xFilial("SG2") + "' "
	cSql += "   AND SG2.D_E_L_E_T_ 	 = ''

	cSql += " INNER JOIN " + RetSQLName("SH1") + " SH1 "
	cSql += "    ON H1_CODIGO 		 = G2_RECURSO"
	cSql += "   AND H1_FILIAL 	 	 = '" + xFilial("SH1") + "' "
	cSql += "   AND SH1.D_E_L_E_T_ 	 = ''

	cSql += " WHERE C2_DATPRF 	   	>= '" + dtos(dDtIni) + "'"
	cSql += "   AND C2_DATPRF	   	<= '" + dtos(dDtFim) + "'"
	cSql += "   AND C2_DATRF   		 = ''"
	cSql += "   AND C2_TPOP 	 	<> 'P'"
	cSql += "   AND C2_FILIAL 	 	 = '" + xFilial("SC2") + "' "

	if nStatus == 1
		cSql += " AND C2_XSITEMP <> 'S' "
	elseif nStatus == 2
		cSql += " AND C2_XSITEMP = 'S' "
	endif

	cSql += "	AND SC2.D_E_L_E_T_ 	 = ' ' "
	cSql += "	ORDER BY G2_RECURSO, C2_DATPRI, C2_NUM, C2_ITEM, C2_SEQUEN "
	cAlias := MPSysOpenQuery(cSql)

	While (cAlias)->(! EOF())
		cOP	 := Transform((cAlias)->C2_NUM, "999999") + AllTrim((cAlias)->C2_ITEM) + AllTrim((cAlias)->C2_SEQUEN)

		cSql := "INSERT INTO " + cTableName + " ("
		cSql += " TT_ID, TT_PRODUTO, TT_DESC, TT_CLIENT, TT_ITCLI, TT_OP, TT_RECURSO, "
		cSql += " TT_QUANT, TT_SITEMP, TT_PRTPL,"
		cSql += " TT_DTINIP, TT_HRINIP, "
		cSql += " TT_OBSEMP) VALUES ('"

		cSql += FWUUIDv4() 			 				+ "','"
		cSql += (cAlias)->C2_PRODUTO 				+ "','"
		cSql += (cAlias)->B1_DESC 					+ "','"
		cSql += (cAlias)->B1_XCLIENT				+ "','"
		cSql += (cAlias)->B1_XITEM 					+ "','"
		cSql += cOP 								+ "','"
		cSql += AllTrim((cAlias)->G2_RECURSO) 		+ "','"
		cSql += cValToChar((cAlias)->C2_QUANT) 		+ "','"
		cSql += AllTrim((cAlias)->C2_XSITEMP) 		+ "','"
		cSql += (cAlias)->C2_XPRTPL 				+ "','"
		cSql += (cAlias)->C2_XDTINIP 				+ "','"
		cSql += (cAlias)->C2_XHRINIP 				+ "','"
		cSql += (cAlias)->C2_XOBSEMP 				+ "')"

		if TCSqlExec(cSql) < 0
			MsgInfo("Erro na execução da query:", "Atenção")
			MsgInfo(TcSqlError(), "Atenção3")
		endif

		(cAlias)->(DbSkip())
	enddo

	(cAlias)->(DBCLOSEAREA())
return


Static Function MVCMODELPOS(oModel)
	Local aArea   		:= GetArea()
	Local lOk			:= .T.
	Local nOperation 	:=	oModel:GetOperation()

	If nOperation == MODEL_OPERATION_UPDATE

		SC2->(dbSetOrder(1))

		If SC2->(MsSeek(xFilial("SC2") + M->TT_OP))
			RecLock("SC2", .F.)
			SC2->C2_XSITEMP := M->TT_SITEMP
			SC2->C2_XOBSEMP := M->TT_OBSEMP
			MsUnLock()
		endif
	EndIf

	RestArea(aArea)
Return lOk


/*---------------------------------------------------------------------*
  Legendas
 *---------------------------------------------------------------------*/
User Function PL190ProLeg()
    Local aLegenda := {}
    AAdd(aLegenda,{"BR_AMARELO","Prevista"})
    AAdd(aLegenda,{"BR_VERDE","Em aberto"})
    BrwLegenda("Registros", "Tipo", aLegenda)
return



/*---------------------------------------------------------------------*
  Prepara os registros marcados no checkbox
 *---------------------------------------------------------------------*/
User Function PL190Mark()
	Local aArea    := GetArea()
	Local cMarca   := oBrowse:Mark()
	Local nCt      := 0
	
	SC2->(dbSetOrder(1))  

	cAliasTT->(DbGoTop())

	While !cAliasTT->(EoF())
		If oBrowse:IsMark(cMarca)
			nCt++

			If SC2->(MsSeek(xFilial("SC2") + (cAliasTT)->TT_OP))
				RecLock("SC2", .F.)
				SC2->C2_XSITEMP := M->TT_SITEMP
				MsUnLock()
			EndIf

			//Limpando a marca
			// RecLock('ZA0', .F.)
			// ZA0_OK := ''
			// ZA0->(MsUnlock())
		EndIf

		(cAliasTT)->(DbSkip())
	EndDo

	RestArea(aArea)
Return NIL



User Function PL190Lib()
	Local aArea   		:= GetArea()
	Local cMarca   		:= oBrowse:Mark()
	Local nCt      		:= 0
	
	SC2->(dbSetOrder(1))  
	(cAliasTT)->(DbGoTop())

	While !(cAliasTT)->(EoF())
		If oBrowse:IsMark(cMarca)
			nCt++

			If SC2->(MsSeek(xFilial("SC2") + (cAliasTT)->TT_OP))
				RecLock("SC2", .F.)
				if SC2->C2_XSITEMP == 'S'
					SC2->C2_XSITEMP := "N"
				else
					SC2->C2_XSITEMP := "S"
				endif
				MsUnLock()

				RecLock(cAliasTT, .F.)
				TT_SITEMP := SC2->C2_XSITEMP
				(cAliasTT)->(MsUnlock())
			EndIf

		EndIf

		(cAliasTT)->(DbSkip())
	EndDo

	RestArea(aArea)
Return Nil


User Function PL190Picking()
	Local aArea   		:= GetArea()
	Local cMarca   		:= oBrowse:Mark()
	Local nCt      		:= 0
	Local aDados		:= {}	

	SC2->(dbSetOrder(1))  
	(cAliasTT)->(DbGoTop())

	While !(cAliasTT)->(EoF())
		If oBrowse:IsMark(cMarca)
			nCt++

			If SC2->(MsSeek(xFilial("SC2") + (cAliasTT)->TT_OP))
				aAdd(aDados,{.T., SC2->C2_NUM, SC2->C2_ITEM, SC2->C2_SEQUEN})

				RecLock(cAliasTT, .F.)
				TT_PRTPL := 'S'
				(cAliasTT)->(MsUnlock())
			EndIf
		EndIf

		(cAliasTT)->(DbSkip())
	EndDo

	if len(aDados) > 0
		u_PL130A(aDados)
	endif

	RestArea(aArea)
Return Nil
