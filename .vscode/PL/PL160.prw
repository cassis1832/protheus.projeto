#Include "PROTHEUS.CH"
#Include "RPTDEF.CH"
#Include "TBICONN.CH"
#Include 'FWMVCDef.ch'

/*/{Protheus.doc}	PL160
	Extrair dados de ordens de produção para controle de empenho
@author Carlos Assis
@since 22/07/2024
@version 1.0   
/*/

User Function PL160()
	Local aArea 	:= FWGetArea()
	Local aCampos 	:= {}
	Local aColunas 	:= {}
	Local aPesquisa := {}
	Local aIndex 	:= {}
	Local oBrowse

	Local oSay 		:= NIL
	Local aPergs	:= {}
	Local aResps	:= {}

	Private cTitulo		:= "Plano de Producao"
	Private aRotina 	:= {}
	Private cTableName 	:= ""
	Private cAliasTT 	:= GetNextAlias()

	Private dDtIni  := ""
	Private dDtFim  := ""
	Private lEstamp := .F.
	Private lSolda  := .F.

	//Definicao do menu
	aRotina := MenuDef()

	AAdd(aPergs, {1, "Informe a data inicial "	, CriaVar("C2_DATPRF",.F.),"",".T.","",".T.", 70, .F.})
	AAdd(aPergs, {1, "Informe a data final "	, CriaVar("C2_DATPRF",.F.),"",".T.","",".T.", 70, .F.})
	AAdd(aPergs, {4, "Estamparia"				,.T.,"Estamparia" ,90,"",.F.})
	AAdd(aPergs, {4, "Solda"					,.T.,"Solda" ,90,"",.F.})

	If ParamBox(aPergs, "Extracao de Uso Planejado de Maquina", @aResps,,,,,,,, .T., .T.)
		dDtIni 	:= aResps[1]
		dDtFim 	:= aResps[2]
		lEstamp	:= aResps[3]
		lSolda	:= aResps[4]
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
	aAdd(aCampos, {"TT_STATUS"	,"C", 01, 0})
	aAdd(aCampos, {"TT_RECURSO"	,"C", 06, 0})
	aAdd(aCampos, {"TT_DATPRI"	,"D", 08, 0})
	aAdd(aCampos, {"TT_DATPRF"	,"D", 08, 0})
	aAdd(aCampos, {"TT_QUANT"	,"N", 14, 3})
	aAdd(aCampos, {"TT_QUJE"	,"N", 14, 3})
	aAdd(aCampos, {"TT_QTHSTOT"	,"N", 14, 3})
	aAdd(aCampos, {"TT_DTINIP"	,"D", 08, 0})
	aAdd(aCampos, {"TT_DTFIMP"	,"D", 08, 0})
	aAdd(aCampos, {"TT_DTINIR"	,"D", 08, 0})
	aAdd(aCampos, {"TT_DTFIMR"	,"D", 08, 0})
	aAdd(aCampos, {"TT_DTSACR"	,"D", 08, 0})
	aAdd(aCampos, {"TT_HRINIP"	,"C", 05, 0})
	aAdd(aCampos, {"TT_HRFIMP"	,"C", 05, 0})
	aAdd(aCampos, {"TT_HRINIR"	,"C", 05, 0})
	aAdd(aCampos, {"TT_HRFIMR"	,"C", 05, 0})
	aAdd(aCampos, {"TT_HRSACR"	,"C", 05, 0})
	aAdd(aCampos, {"TT_OBSEMP"	,"C", 60, 0})
	aAdd(aCampos, {"TT_OBSPRD"	,"C", 60, 0})
	aAdd(aCampos, {"TT_PRTOP"	,"C", 01, 0})
	aAdd(aCampos, {"TT_PRTPL"	,"C", 01, 0})

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
	aAdd(aColunas, {"Cliente"			, "TT_CLIENT"	, "C", 10, 0, "@!"})
	aAdd(aColunas, {"Item do Cliente"	, "TT_ITCLI"	, "C", 10, 0, "@!"})
	aAdd(aColunas, {"Ordem"				, "TT_OP"		, "C", 10, 0, "@!"})
	aAdd(aColunas, {"Dt. Inicio Prev."	, "TT_DTINIP"	, "D", 06, 0, "@D"})
	aAdd(aColunas, {"Hr. Inicio Prev."	, "TT_HRINIP"	, "C", 05, 0, "99:99"})
	aAdd(aColunas, {"Num. Horas"		, "TT_QTHSTOT"	, "N", 05, 3, "@E 9,999,999.999"})
	aAdd(aColunas, {"Dt. Fim Prev."		, "TT_DTFIMP"	, "D", 06, 0, "@D"})
	aAdd(aColunas, {"Hr. Fim Prev."		, "TT_HRFIMP"	, "C", 05, 0, "99:99"})
	aAdd(aColunas, {"Quant."			, "TT_QUANT"	, "N", 05, 3, "@E 9,999,999.999"})
	aAdd(aColunas, {"Quant. Prod."		, "TT_QUJE"		, "N", 05, 3, "@E 9,999,999.999"})
	aAdd(aColunas, {"Dt. Inicio Real"	, "TT_DTINIR"	, "D", 06, 0, "@D"})
	aAdd(aColunas, {"Hr. Inicio Real"	, "TT_HRINIR"	, "C", 05, 0, "99:99"})
	aAdd(aColunas, {"Dt. Fim Real"		, "TT_DTFIMR"	, "D", 06, 0, "@D"})
	aAdd(aColunas, {"Hr. Fim Real"		, "TT_HRFIMR"	, "C", 05, 0, "99:99"})
	aAdd(aColunas, {"Dt. Inicio"		, "TT_DATPRI"	, "D", 06, 0, "@D"})
	aAdd(aColunas, {"Dt. Fim"			, "TT_DATPRF"	, "D", 06, 0, "@D"})
	aAdd(aColunas, {"Obs. Empenho"		, "TT_OBSEMP"	, "C", 30, 0, "@!"})
	aAdd(aColunas, {"Obs. Producao"		, "TT_OBSPRD"	, "C", 30, 0, "@!"})

	// Para aparecer caixa de filtrar
	aAdd(aPesquisa, {"Recurso"		, {{"", "C",  6, 0, "Recurso" 	 , "@!", "TT_RECURSO"}} } )
	aAdd(aPesquisa, {"Produto"		, {{"", "C", 15, 0, "Produto" 	 , "@!", "TT_PRODUTO"}} } )
	aAdd(aPesquisa, {"Dt. Inicio"	, {{"", "D", 10, 0, "Dt. Inicio" , "@!", "TT_DATPRI"}} } )

	aAdd(aIndex, {"TT_RECURSO", "TT_DTINIP"} )

	//Criando o browse da temporária
	oBrowse := FWMBrowse():New()
	oBrowse:SetAlias(cAliasTT)
	oBrowse:SetQueryIndex(aIndex)
	oBrowse:SetTemporary(.T.)
	oBrowse:SetFields(aColunas)
	oBrowse:DisableDetails()
	oBrowse:SetDescription(cTitulo)
	oBrowse:SetSeek(.T., aPesquisa)

	oBrowse:AddLegend("TT_STATUS == 'N'", "YELLOW", "Normal")
	oBrowse:AddLegend("TT_STATUS == 'U'", "RED", "Suspensa")
	oBrowse:AddLegend("TT_STATUS == 'S'", "GREEN", "Sacramentada")

	oBrowse:Activate()

	oTempTable:Delete()
	FWRestArea(aArea)
return



/*/{Protheus.doc} MenuDef
Menu de opcoes na funcao pl160
@author Assis
@since 19/06/2024
@version 1.0
/*/
Static Function MenuDef()
	Local aRot := {}
	ADD OPTION aRot TITLE 'Visualizar' 	  ACTION 'VIEWDEF.PL160' OPERATION 2 ACCESS 0
	ADD OPTION aRot TITLE 'Alterar'    	  ACTION 'VIEWDEF.PL160' OPERATION 4 ACCESS 0
	ADD OPTION aRot TITLE 'Legenda'    	  ACTION 'u_ProLeg' 	 OPERATION 8 ACCESS 0
Return aRot


/*/{Protheus.doc} ModelDef
Modelo de dados na funcao pl160
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
	oStTT:AddField("Dt. Inicio"			,"Data Inicio"		,"TT_DATPRI"	,"D",08,00,Nil,Nil,{},.F.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_DATPRI,'')" ),.F.,.F.,.F.)
	oStTT:AddField("Dt. Fim"			,"Data Fim"			,"TT_DATPRF"	,"D",08,00,Nil,Nil,{},.F.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_DATPRF,'')" ),.F.,.F.,.F.)
	oStTT:AddField("Quantidade"			,"Quantidade"		,"TT_QUANT"		,"N",10,02,Nil,Nil,{},.F.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_QUANT,'')" ),.F.,.F.,.F.)
	oStTT:AddField("Quant. Prod."		,"Quant. Prod."		,"TT_QUJE"		,"N",10,02,Nil,Nil,{},.F.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_QUJE,'')" ),.F.,.F.,.F.)
	oStTT:AddField("Recurso"			,"Recurso"			,"TT_RECURSO"	,"N",10,02,Nil,Nil,{},.F.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_RECURSO,'')" ),.F.,.F.,.F.)
	oStTT:AddField("Num. Horas"			,"Num. Horas"		,"TT_QTHSTOT"	,"N",10,02,Nil,Nil,{},.F.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_QTHSTOT,'')" ),.F.,.F.,.F.)

	oStTT:AddField("Dt. Inicio Prev."	,"Dt. Inicio Prev."	,"TT_DTINIP"	,"D",08,00,Nil,Nil,{},.F.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_DTINIP,'')" ),.F.,.F.,.F.)
	oStTT:AddField("Hr. Inicio Prev."	,"Hr. Inicio Prev."	,"TT_HRINIP"	,"C",05,00,Nil,Nil,{},.F.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_HRINIP,'')" ),.F.,.F.,.F.)
	oStTT:AddField("Dt. Fim Prev."		,"Dt. Fim Prev."	,"TT_DTFIMP"	,"D",08,00,Nil,Nil,{},.F.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_DTFIMP,'')" ),.F.,.F.,.F.)
	oStTT:AddField("Hr. Fim Prev."		,"Hr. Fim Prev."	,"TT_HRFIMP"	,"C",05,00,Nil,Nil,{},.F.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_HRFIMP,'')" ),.F.,.F.,.F.)
	oStTT:AddField("Dt. Inicio Real"	,"Dt. Inicio Real"	,"TT_DTINIR"	,"D",08,00,Nil,Nil,{},.F.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_DTINIR,'')" ),.F.,.F.,.F.)
	oStTT:AddField("Hr. Inicio Real"	,"Hr. Inicio Real"	,"TT_HRINIR"	,"C",05,00,Nil,Nil,{},.F.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_HRINIR,'')" ),.F.,.F.,.F.)
	oStTT:AddField("Dt. Fim Real"		,"Dt. Fim Real"		,"TT_DTFIMR"	,"D",08,00,Nil,Nil,{},.F.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_DTFIMR,'')" ),.F.,.F.,.F.)
	oStTT:AddField("Hr. Fim Real"		,"Hr. Fim Real"		,"TT_HRFIMR"	,"C",05,00,Nil,Nil,{},.F.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_HRFIMR,'')" ),.F.,.F.,.F.)

	oStTT:AddField("Obs. Empenho"		,"Obs. Empenho"		,"TT_OBSEMP"	,"C",40,00,Nil,Nil,{},.F.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_OBSEMP,'')" ), .F., .F., .F.)
	oStTT:AddField("Obs. Producao"		,"Obs. Producao"	,"TT_OBSPRD"	,"C",40,00,Nil,Nil,{},.F.,FwBuildFeature(STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTT+"->TT_OBSPRD,'')" ), .F., .F., .F.)

	oStTT:SetProperty('TT_OP'		,MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))
	oStTT:SetProperty('TT_PRODUTO'	,MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))
	oStTT:SetProperty('TT_CLIENT'	,MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))
	oStTT:SetProperty('TT_ITCLI'	,MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))
	oStTT:SetProperty('TT_DESC'		,MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))
	oStTT:SetProperty('TT_DATPRI'	,MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))
	oStTT:SetProperty('TT_DATPRF'	,MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))
	oStTT:SetProperty('TT_QUANT'	,MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))
	oStTT:SetProperty('TT_QUJE'		,MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))
	oStTT:SetProperty('TT_QTHSTOT'	,MODEL_FIELD_WHEN,FwBuildFeature(STRUCT_FEATURE_WHEN,'.F.'))

	//Instanciando o modelo
	oModel:=MPFormModel():New  ("PL160M", Nil, {|oModel| MVCMODELPOS(oModel)}, Nil, Nil)

	oModel:AddFields("FORMTT",/*cOwner*/,oStTT)
	oModel:SetPrimaryKey({'TT_ID'})
	oModel:SetDescription("Modelo de Dados do Cadastro ")
	oModel:GetModel("FORMTT"):SetDescription("Formulário do Cadastro ")
Return oModel


/*/{Protheus.doc} ViewDef
Visualizacao de dados na funcao pl160
@author Assis
@since 19/06/2024
@version 1.0
/*/

Static Function ViewDef()
	Local oView := Nil
	Local oModel := FWLoadModel("PL160")
	Local oStTT := FWFormViewStruct():New()

	//Adicionando campos da estrutura
	oStTT:AddField("TT_PRODUTO"	,"01","Produto"			,"Produto"			,Nil,"C","@!",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTT:AddField("TT_DESC"	,"02","Descricao"		,"Descricao"		,Nil,"C","@!",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTT:AddField("TT_CLIENT"	,"03","Cliente"			,"Cliente"			,Nil,"C","@!",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTT:AddField("TT_ITCLI"	,"04","Item do Cliente"	,"Item do Cliente"	,Nil,"C","@!",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTT:AddField("TT_OP"		,"05","Ordem"			,"Ordem"			,Nil,"C","@!",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTT:AddField("TT_DATPRI"	,"06","Dt. Inicio"		,"Dt. Inicio"		,Nil,"D","@D",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTT:AddField("TT_DATPRF"	,"07","Dt. Fim"			,"Dt. Fim"			,Nil,"D","@D",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTT:AddField("TT_QUANT"	,"08","Quantidade"		,"Quantidade"		,Nil,"N","@E 9,999,999.99",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTT:AddField("TT_QUJE"	,"09","Quant. Prod."	,"Quant. Prod."		,Nil,"N","@E 9,999,999.99",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTT:AddField("TT_RECURSO"	,"10","Recurso"			,"Recurso"			,Nil,"C","@!",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTT:AddField("TT_QTHSTOT"	,"11","Hs. Totais"		,"Hs. Totais"		,Nil,"N","@E 9,999,999.99",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)

	oStTT:AddField("TT_DTINIP"	,"12","Dt. Inicio Prev.","Dt. Inicio Prev."	,Nil,"D","@D",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTT:AddField("TT_HRINIP"	,"13","Hr. Inicio Prev.","Hr. Inicio Prev."	,Nil,"C","@!",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTT:AddField("TT_DTFIMP"	,"14","Dt. Fim Prev."	,"Dt. Fim Prev."	,Nil,"D","@D",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTT:AddField("TT_HRFIMP"	,"15","Hr. Fim Prev."	,"Hr. Fim Prev."	,Nil,"C","@!",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTT:AddField("TT_DTINIR"	,"16","Dt. Inicio Real"	,"Dt. Inicio Real"	,Nil,"D","@D",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTT:AddField("TT_HRINIR"	,"17","Hr. Inicio Real"	,"Hr. Inicio Real"	,Nil,"C","@!",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTT:AddField("TT_DTFIMR"	,"18","Dt. Fim Real"	,"Dt. Fim Real"		,Nil,"D","@D",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTT:AddField("TT_HRFIMR"	,"19","Hr. Fim Real"	,"Hr. Fim Real"		,Nil,"C","@!",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)

	oStTT:AddField("TT_OBSEMP"	,"20","Obs. Empenho"	,"Obs. Empenho"		,Nil,"C","@!",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)
	oStTT:AddField("TT_OBSPRD"	,"21","Obs. Producao"	,"Obs. Producao"	,Nil,"C","@!",Nil,Nil,.T.,Nil,Nil,Nil,Nil,Nil,Nil,Nil,Nil)

	//Criando a view que será o retorno da função e setando o modelo da rotina
	oView := FWFormView():New()
	oView:SetModel(oModel)
	oView:AddField("VIEW_TT", oStTT, "FORMTT")
	oView:CreateHorizontalBox("TELA",100)
	oView:EnableTitleView('VIEW_TT', 'Dados - ')
	oView:SetCloseOnOk({||.T.})
	oView:SetOwnerView("VIEW_TT","TELA")
Return oView


Static Function CargaTT(oSay)
	Local cSql 			:= ""
	Local cAlias 		:= ""
	Local nQuant		:= 0
	Local nTotal		:= 0
	Local nSetup		:= 0
	Local dDtPrev		:= Date()

	if lEstamp == .T.
		cLinPrd := "Estamparia"
	Else
		cLinPrd := "Solda"
	Endif

	cSql := "SELECT C2_NUM, C2_ITEM, C2_SEQUEN, C2_PRODUTO, C2_STATUS, "
	cSql += "	    C2_QUANT, C2_QUJE, C2_DATPRI, C2_DATPRF, C2_TPOP, "
	cSql += "	    C2_XDTINIP, C2_XDTFIMP, C2_XHRINIP, C2_XHRFIMP, "
	cSql += "	    C2_XDTINIR, C2_XDTFIMR, C2_XHRINIR, C2_XHRFIMR, "
	cSql += "	    C2_XSITEMP, C2_XDTSACR, C2_XHRSACR, "
	cSql += "	    C2_XOBSEMP, C2_XOBSPRD, "
	cSql += "	  	B1_COD, B1_DESC, B1_UM, B1_XCLIENT, B1_XITEM, "
	cSql += "	    G2_OPERAC, G2_RECURSO, G2_MAOOBRA, G2_SETUP, "
	cSql += "	  	G2_TEMPAD, G2_LOTEPAD, "
	cSql += "	  	H1_XLIN, H1_XLOCLIN, H1_XTIPO, H1_XSETUP, H1_XNOME "
	cSql += "  FROM " + RetSQLName("SC2") + " SC2 "

	cSql += " INNER JOIN " + RetSQLName("SB1") + " SB1 "
	cSql += "	 ON B1_COD 		 	 = C2_PRODUTO"
	cSql += "   AND B1_FILIAL 	 	 = '" + xFilial("SB1") + "' "
	cSql += "   AND B1_XLINPRD 	 	 = '" + cLinPrd + "' "
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
	cSql += "   AND C2_FILIAL 	 	 = '" + xFilial("SC2") + "' "
	cSql += "	AND SC2.D_E_L_E_T_ 	 = ' ' "
	cSql += "	ORDER BY G2_RECURSO, C2_DATPRI, C2_NUM, C2_ITEM, C2_SEQUEN "
	cAlias := MPSysOpenQuery(cSql)

	While (cAlias)->(! EOF())
		nQuant := (cAlias)->C2_QUANT / (cAlias)->G2_LOTEPAD

		if (cAlias)->G2_SETUP > 0
			nSetup	:= (cAlias)->G2_SETUP
		else
			if (cAlias)->H1_XSETUP > 0
				nSetup	:= (cAlias)->H1_XSETUP
			else
				nSetup	:= 0.5
			endif
		endif

		nTotal := nSetup + nQuant

		if empty((cAlias)->C2_XDTINIP) .Or. (cAlias)->C2_XDTINIP == ""
			dDtPrev := (cAlias)->C2_DATPRI
		else
			dDtPrev := (cAlias)->C2_XDTINIP
		endif

		cSql := "INSERT INTO " + cTableName + " ("
		cSql += " TT_ID, TT_PRODUTO, TT_DESC, TT_CLIENT, TT_ITCLI, TT_OP, TT_STATUS, TT_RECURSO, "
		cSql += " TT_DATPRI, TT_DATPRF, TT_QUANT, TT_QUJE, TT_QTHSTOT, "
		cSql += " TT_DTINIP, TT_DTFIMP, TT_HRINIP, TT_HRFIMP, "
		cSql += " TT_DTINIR, TT_DTFIMR, TT_HRINIR, TT_HRFIMR, "
		cSql += " TT_DTSACR, TT_HRSACR, TT_OBSEMP, TT_OBSPRD) VALUES ('"

		cSql += FWUUIDv4() 			 				+ "','"
		cSql += (cAlias)->C2_PRODUTO 				+ "','"
		cSql += (cAlias)->B1_DESC 					+ "','"
		cSql += (cAlias)->B1_XCLIENT				+ "','"
		cSql += (cAlias)->B1_XITEM 					+ "','"
		cSql += Transform((cAlias)->C2_NUM, "999999") + AllTrim((cAlias)->C2_ITEM) + AllTrim((cAlias)->C2_SEQUEN) +  "','"
		cSql += AllTrim((cAlias)->C2_STATUS)  +  "','"
		cSql += AllTrim((cAlias)->G2_RECURSO) +  "','"
		cSql += (cAlias)->C2_DATPRI +  "','"
		cSql += (cAlias)->C2_DATPRF +  "','"
		cSql += cValToChar((cAlias)->C2_QUANT) +  "','"
		cSql += cValToChar((cAlias)->C2_QUJE) +  "','"
		cSql += cValToChar(nTotal) + "','"
		cSql += dDtPrev + "','" + (cAlias)->C2_XDTFIMP + "','"
		cSql += (cAlias)->C2_XHRINIP + "','" + (cAlias)->C2_XHRFIMP + "','"
		cSql += (cAlias)->C2_XDTINIR + "','" + (cAlias)->C2_XDTFIMR + "','"
		cSql += (cAlias)->C2_XHRINIR + "','" + (cAlias)->C2_XHRFIMR + "','"
		cSql += (cAlias)->C2_XDTSACR + "','" + (cAlias)->C2_XHRSACR + "','"
		cSql += (cAlias)->C2_XOBSEMP + "','" + (cAlias)->C2_XOBSPRD + "')"

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

			SC2->C2_XDTINIP := M->TT_DTINIP
			SC2->C2_XDTFIMP := M->TT_DTFIMP
			SC2->C2_XHRINIP := M->TT_HRINIP
			SC2->C2_XHRFIMP := M->TT_HRFIMP
			SC2->C2_XDTINIR := M->TT_DTINIR
			SC2->C2_XDTFIMR := M->TT_DTFIMR
			SC2->C2_XHRINIR := M->TT_HRINIR
			SC2->C2_XHRFIMR := M->TT_HRFIMR
			SC2->C2_XDTSACR := M->TT_DTSACR
			SC2->C2_XHRSACR := M->TT_HRSACR
			SC2->C2_XOBSEMP := M->TT_OBSEMP
			SC2->C2_XOBSPRD := M->TT_OBSPRD

			MsUnLock()
		endif
	EndIf

	RestArea(aArea)
Return lOk
