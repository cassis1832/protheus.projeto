Static Function fMontaTela()
	Local nLargBtn      := 50
	//Objetos e componentes
	Private oDlgPulo
	Private oFwLayer
	Private oPanTitulo
	Private oPanGrid
	//Cabeçalho
	Private oSayModulo, cSayModulo := 'TST'
	Private oSayTitulo, cSayTitulo := 'Pulo do Gato na Montagem de Dialogs'
	Private oSaySubTit, cSaySubTit := 'Exemplo usando FWLayer'
	//Tamanho da janela
	Private aSize := MsAdvSize(.F.)
	Private nJanLarg := aSize[5]
	Private nJanAltu := aSize[6]
	//Fontes
	Private cFontUti    := "Tahoma"
	Private oFontMod    := TFont():New(cFontUti, , -38)
	Private oFontSub    := TFont():New(cFontUti, , -20)
	Private oFontSubN   := TFont():New(cFontUti, , -20, , .T.)
	Private oFontBtn    := TFont():New(cFontUti, , -14)
	Private oFontSay    := TFont():New(cFontUti, , -12)
	//Grid
	Private aCampos := {}
	Private cAliasTmp := "TST_" + RetCodUsr()
	Private aColunas := {}

	//Campos da Temporária
	aAdd(aCampos, { "CODIGO" , "C", TamSX3("BM_GRUPO")[1], 0 })
	aAdd(aCampos, { "DESCRI" , "C", TamSX3("BM_DESC")[1],  0 })

	//Cria a tabela temporária
	oTempTable:= FWTemporaryTable():New(cAliasTmp)
	oTempTable:SetFields( aCampos )
	oTempTable:Create()

	//Busca as colunas do browse
	aColunas := fCriaCols()

	//Popula a tabela temporária
	Processa({|| fPopula()}, "Processando...")

	//Cria a janela
	DEFINE MSDIALOG oDlgPulo TITLE "Exemplo de Pulo do Gato"  FROM 0, 0 TO nJanAltu, nJanLarg PIXEL

	//Criando a camada
	oFwLayer := FwLayer():New()
	oFwLayer:init(oDlgPulo,.F.)

	//Adicionando 3 linhas, a de título, a superior e a do calendário
	oFWLayer:addLine("TIT", 10, .F.)
	oFWLayer:addLine("COR", 90, .F.)

	//Adicionando as colunas das linhas
	oFWLayer:addCollumn("HEADERTEXT",   050, .T., "TIT")
	oFWLayer:addCollumn("BLANKBTN",     040, .T., "TIT")
	oFWLayer:addCollumn("BTNSAIR",      010, .T., "TIT")
	oFWLayer:addCollumn("COLGRID",      100, .T., "COR")

	//Criando os paineis
	oPanHeader := oFWLayer:GetColPanel("HEADERTEXT", "TIT")
	oPanSair   := oFWLayer:GetColPanel("BTNSAIR",    "TIT")
	oPanGrid   := oFWLayer:GetColPanel("COLGRID",    "COR")

	//Títulos e SubTítulos
	oSayModulo := TSay():New(004, 003, {|| cSayModulo}, oPanHeader, "", oFontMod,  , , , .T., RGB(149, 179, 215), , 200, 30, , , , , , .F., , )
	oSayTitulo := TSay():New(004, 045, {|| cSayTitulo}, oPanHeader, "", oFontSub,  , , , .T., RGB(031, 073, 125), , 200, 30, , , , , , .F., , )
	oSaySubTit := TSay():New(014, 045, {|| cSaySubTit}, oPanHeader, "", oFontSubN, , , , .T., RGB(031, 073, 125), , 300, 30, , , , , , .F., , )

	//Criando os botões
	oBtnSair := TButton():New(006, 001, "Fechar",             oPanSair, {|| oDlgPulo:End()}, nLargBtn, 018, , oFontBtn, , .T., , , , , , )

	//Cria a grid
	oGetGrid := FWBrowse():New()
	oGetGrid:SetDataTable()
	oGetGrid:SetInsert(.F.)
	oGetGrid:SetDelete(.F., { || .F. })
	oGetGrid:SetAlias(cAliasTmp)
	oGetGrid:DisableReport()
	oGetGrid:DisableFilter()
	oGetGrid:DisableConfig()
	oGetGrid:DisableReport()
	oGetGrid:DisableSeek()
	oGetGrid:DisableSaveConfig()
	oGetGrid:SetFontBrowse(oFontSay)
	oGetGrid:SetColumns(aColunas)
	oGetGrid:SetOwner(oPanGrid)
	oGetGrid:Activate()
	Activate MsDialog oDlgPulo Centered
	oTempTable:Delete()
Return

Static Function fCriaCols()
	Local nAtual   := 0
	Local aColunas := {}
	Local aEstrut  := {}
	Local oColumn

	//Adicionando campos que serão mostrados na tela
	//[1] - Campo da Temporaria
	//[2] - Titulo
	//[3] - Tipo
	//[4] - Tamanho
	//[5] - Decimais
	//[6] - Máscara
	aAdd(aEstrut, {"CODIGO", "Código",                "C", TamSX3('BM_GRUPO')[01],   0, ""})
	aAdd(aEstrut, {"DESCRI", "Descrição",             "C", TamSX3('BM_DESC')[01],    0, ""})

	//Percorrendo todos os campos da estrutura
	For nAtual := 1 To Len(aEstrut)
		//Cria a coluna
		oColumn := FWBrwColumn():New()
		oColumn:SetData(&("{|| (cAliasTmp)->" + aEstrut[nAtual][1] +"}"))
		oColumn:SetTitle(aEstrut[nAtual][2])
		oColumn:SetType(aEstrut[nAtual][3])
		oColumn:SetSize(aEstrut[nAtual][4])
		oColumn:SetDecimal(aEstrut[nAtual][5])
		oColumn:SetPicture(aEstrut[nAtual][6])
		oColumn:bHeaderClick := &("{|| fOrdena('" + aEstrut[nAtual][1] + "') }")

		//Adiciona a coluna
		aAdd(aColunas, oColumn)
	Next
Return aColunas

Static Function fPopula()
	Local nAtual := 0
	Local nTotal := 0

	DbSelectArea("SBM")
	SBM->(DbSetOrder(1))
	SBM->(DbGoTop())

	//Define o tamanho da régua
	Count To nTotal
	ProcRegua(nTotal)
	SBM->(DbGoTop())

	//Enquanto houver itens
	While ! SBM->(EoF())
		//Incrementa a régua
		nAtual++
		IncProc("Adicionando registro " + cValToChar(nAtual) + " de " + cValToChar(nTotal) + "...")

		//Grava na temporária
		RecLock(cAliasTmp, .T.)
		(cAliasTmp)->CODIGO := SBM->BM_GRUPO
		(cAliasTmp)->DESCRI := SBM->BM_DESC
		(cAliasTmp)->(MsUnlock())

		SBM->(DbSkip())
	EndDo
Return
