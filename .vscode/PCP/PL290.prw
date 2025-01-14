#Include 'Protheus.ch'
#Include 'FWMVCDef.ch'

//-------------------------------------------------------------------
/*/{Protheus.doc} PL290
	Consulta geral do planejamento
@author  Carlos Assis
@since   09/12/2024
@version 1.0
/*/
//-------------------------------------------------------------------
User Function PL290()
	Local aArea   		:= GetArea()
	Local cFunBkp 		:= FunName()

	Private aDatas 		:= {}
	Private aPedidos 	:= {}
	Private aColumns   	:= {}

	Private oDlg       	:= Nil
	Private oFwBrowse  	:= Nil
	Private oBrw  		:= Nil

	Private cAliasZA0	:= ''
	Private cAliasSC6	:= ''

	ObterDados()

	CalculaSaldos()

	fWBrowse1()

	SetFunName(cFunBkp)
	RestArea(aArea)
Return

Static Function ObterDados()
	Local cSql := ""
	Local nQtde:= 0
	Local nSaldo:= 0
	Local nPosItem:=0
	Local nPosData:=0

	// Carrega os itens e os saldos iniciais
	cSql := "SELECT DISTINCT A7_PRODUTO, B1_LOCPAD, A7_CODCLI, B1_XCLIENT "
	cSql += "  FROM " + RetSQLName("SA7") + " SA7 "

	cSql += " INNER JOIN " + RetSQLName("SB1") + " SB1 "
	cSql += "    ON B1_COD						=  A7_PRODUTO"
	cSql += "   AND B1_FILIAL       			=  '" + xFilial("SB1") 	+ "'"
	cSql += "   AND SB1.D_E_L_E_T_    			<> '*' "

	cSql += " WHERE A7_FILIAL         			=  '" + xFilial("SA7") 	+ "'"
	cSql += "   AND SUBSTRING(A7_XNATUR,1,1) 	=  'F' "
	cSql += "   AND SUBSTRING(A7_PRODUTO,1,1) 	<> '7' "
	cSql += "   AND SA7.D_E_L_E_T_    			<> '*' "
	cSql += " ORDER BY A7_PRODUTO "
	cAliasSA7 := MPSysOpenQuery(cSql)

	dbSelectArea("SB2")
	SB2->(DBSetOrder(1))

	While (cAliasSA7)->(!EOF())

		If SB2->(MsSeek(xFilial("SB2") + (cAliasSA7)->A7_PRODUTO + (cAliasSA7)->B1_LOCPAD))
			nSaldo := SB2->B2_QATU
		else
			nSaldo := 0
		EndIf

		Aadd(aPedidos,{(cAliasSA7)->B1_XCLIENT, (cAliasSA7)->A7_PRODUTO, (cAliasSA7)->A7_CODCLI, cValToChar(nSaldo), "0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0"})

		(cAliasSA7)->(DbSkip())
	EndDo

	(cAliasSA7)->(DBCLOSEAREA())

	// Carregar pedidos EDI
	cSql := "SELECT ZA0_DTENTR, ZA0_PRODUT, ZA0_QTDE, ZA0_QTCONF, (ZA0_QTDE - ZA0_QTCONF) AS ZA0_SALDO "
	cSql += "  FROM ZA0010, SB1010 "
	cSql += " WHERE ZA0_STATUS 		= '0' "
	cSql += "   AND ZA0_FILIAL 		= '" + xFilial("ZA0") + "'"
	cSql += "   AND B1_FILIAL 		= '" + xFilial("SB1") + "'"
	cSql += "   AND ZA0_PRODUT 		= B1_COD "
	cSql += "   AND ZA0_QTDE   		> ZA0_QTCONF "
	cSql += "   AND ZA0010.D_E_L_E_T_ <> '*' "
	cSql += "   AND SB1010.D_E_L_E_T_ <> '*' "
	cSql += " ORDER BY ZA0_DTENTR, ZA0_PRODUT "
	cAliasZA0 := MPSysOpenQuery(cSql)

	// Carregar pedidos de vendas
	cSql := "SELECT B1_COD, C6_ENTREG, C6_QTDVEN, C6_QTDENT, (C6_QTDVEN - C6_QTDENT) AS C6_SALDO "
	cSql += "  FROM SC5010, SC6010, SB1010, SF4010 "
	cSql += " WHERE C5_NOTA        = '' "
	cSql += "   AND C5_LIBEROK    <> 'E' "
	cSql += "   AND C5_NUM         = C6_NUM "
	cSql += "   AND C6_QTDENT      < C6_QTDVEN "
	cSql += "   AND SC6010.C6_BLQ <> 'R' "
	cSql += "   AND C6_PRODUTO     = B1_COD "
	cSql += "   AND F4_CODIGO      = C6_TES "
	cSql += "   AND F4_QTDZERO    <> '1' "
	cSql += "   AND B1_FILIAL      = '" + xFilial("SB1") + "'"
	cSql += "   AND C5_FILIAL      = '" + xFilial("SC5") + "'"
	cSql += "   AND C6_FILIAL      = '" + xFilial("SC6") + "'"
	cSql += "   AND F4_FILIAL      = '" + xFilial("SF4") + "'"
	cSql += "   AND SC5010.D_E_L_E_T_   <> '*' "
	cSql += "   AND SC6010.D_E_L_E_T_   <> '*' "
	cSql += "   AND SF4010.D_E_L_E_T_   <> '*' "
	cSql += "   AND SB1010.D_E_L_E_T_   <> '*' "
	cSql += "   AND SB1010.D_E_L_E_T_   <> '*' "
	cSql += " ORDER BY C6_ENTREG, B1_COD "
	cAliasSC6 := MPSysOpenQuery(cSql)

	if (cAliasZA0)->(EOF()) .and. (cAliasSC6)->(EOF())
		return
	endif

	MontaDatas()

	// Carrega pedidos EDI
	While (cAliasZA0)->(!EOF())

		// Localiza o item e a data
		nPosItem := aScan(aPedidos, {|x| AllTrim(x[2]) == AllTrim((cAliasZA0)->ZA0_PRODUT)})

		if (cAliasZA0)->ZA0_DTENTR < dToS(ddatabase)
			nPosData := 1
		else
			nPosData := aScan(aDatas, {|x| x == sToD((cAliasZA0)->ZA0_DTENTR)})
		endif

		// Soma a quantidade do pedido
		if nPosItem <> 0 .and. nPosData <> 0
			nQtde := val(aPedidos[nPosItem][nPosData+4]) + (cAliasZA0)->ZA0_SALDO
			aPedidos[nPosItem][nPosData+4] := cValToChar(nQtde)
		endif

		(cAliasZA0)->(DbSkip())
	End While

	(cAliasZA0)->(DBCLOSEAREA())

	While (cAliasSC6)->(!EOF())

		// Localiza o item e a data
		nPosItem := aScan(aPedidos, {|x| AllTrim(x[2]) == AllTrim((cAliasSC6)->B1_COD)})

		if (cAliasSC6)->C6_ENTREG < dToS(ddatabase)
			nPosData := 1
		else
			nPosData := aScan(aDatas, {|x| x == sToD((cAliasSC6)->C6_ENTREG)})
		endif

		// Soma a quantidade do pedido
		if nPosItem <> 0 .And. nPosData <> 0
			nQtde := val(aPedidos[nPosItem][nPosData+4]) + (cAliasSC6)->C6_SALDO
			aPedidos[nPosItem][nPosData+4] := cValToChar(nQtde)
		endif

		(cAliasSC6)->(DbSkip())
	End While

	(cAliasSC6)->(DBCLOSEAREA())
return


Static Function	CalculaSaldos()
	Local nRow 		:= 1
	Local nCol 		:= 0
	Local nSaldo 	:= 0
	Local lTem		:= .F.

	While nRow <= Len(aPedidos)

		if aPedidos[nRow] == Nil
			aSize(aPedidos, nRow - 1)
			exit
		endif

		lTem	:= .F.

		nSaldo := val(aPedidos[nRow][4])

		if nSaldo <> 0
			lTem	:= .T.
		endif

		For nCol := 5 to Len(aPedidos[nRow])
			if val(aPedidos[nRow][nCol]) <> 0
				lTem	:= .T.
			endif

			nSaldo := nSaldo - val(aPedidos[nRow][nCol])

			if nSaldo < 0 .and. val(aPedidos[nRow][nCol]) > 0
				aPedidos[nRow][nCol] := aPedidos[nRow][nCol] + " ( " + cValToChar(nSaldo) + " )"
			endif
		Next

		if lTem == .F.
			aDel(aPedidos, nRow)
		else
			nRow++
		endif
	EndDo
return


//--------------------------------------------------------------
//	Todas as datas do periodo
//--------------------------------------------------------------
Static Function MontaDatas()
	Local nInd  :=0
	Local dData := daySub(ddatabase,1)

	aDatas := {}

	For nInd := 1 to 15 Step 1
		Aadd(aDatas,dData)
		dData := DaySum(dData, 1)
	Next
Return


Static Function fWBrowse1()
	Local nX:=0
	Local geraXml  := {|| GeraExcel()}

	oDlg:= FwDialogModal():New()
	oDlg:enableAllClient()
	oDlg:SetEscClose(.T.)
	oDlg:SetTitle('Plano Geral de Entrega')

	oDlg:CreateDialog()
	oDlg:AddCloseButton(Nil, 'Fechar')
	oDlg:AddButton("Excel", geraXml, "Excel", , .T., .F., .T., )

	oPnl:=oDlg:GetPanelMain()

	oFwBrowse := FWBrowse():New()
	oFWBrowse:DisableReport()
	oFwBrowse:SetDataArrayoBrowse()  //Define utilização de array
	oFwBrowse:SetArray(aPedidos)

	aColumns := RetColumns()

	//Cria as colunas do array
	For nX := 1 To Len(aColumns )
		oFwBrowse:AddColumn( aColumns[nX] )
	Next

	oFwBrowse:SetOwner(oPnl)
	oFwBrowse:SetDoubleClick( {|| fDupClique() } )
	oFwBrowse:SetDescription( "Planejamento Geral" )

	oFwBrowse:Activate()
	oDlg:Activate()
Return


Static Function RetColumns()
	Local aCols := {}

	if len(aColumns) != 0
		return aColumns
	endif

	aAdd(aCols, {"Cliente",			{|oBrw| aPedidos[oBrw:At(), 1] }, "C", "@!", 1, 10, 0, .F.})
	aAdd(aCols, {"Item",  			{|oBrw| aPedidos[oBrw:At(), 2] }, "C", "@!", 1, 08, 0, .F.})
	aAdd(aCols, {"Item Cliente", 	{|oBrw| aPedidos[oBrw:At(), 3] }, "C", "@!", 1, 08, 0, .F.})
	aAdd(aCols, {"Saldo", 			{|oBrw| aPedidos[oBrw:At(), 4] }, "C", "@!", 0, 04, 2, .F.})

	if len(aDatas) == 0
		FWAlertWarning("NAO EXISTEM DADOS PARA MOSTRAR! ", "PLANO GERAL")
	else
		iif (len(aDatas) >  0, aAdd(aCols, {"Em Atraso", 	 {|oBrw| aPedidos[oBrw:At(),  5] }, "C", "@!",	0, 6, 2, .F.}),0)
		iif (len(aDatas) >  1, aAdd(aCols, {DtoC(aDatas[2]), {|oBrw| aPedidos[oBrw:At(),  6] }, "C", "@!",	0, 6, 2, .F.}),0)
		iif (len(aDatas) >  2, aAdd(aCols, {DtoC(aDatas[3]), {|oBrw| aPedidos[oBrw:At(),  7] }, "C", "@!",	0, 6, 2, .F.}),0)
		iif (len(aDatas) >  3, aAdd(aCols, {DtoC(aDatas[4]), {|oBrw| aPedidos[oBrw:At(),  8] }, "C", "@!",	0, 6, 2, .F.}),0)
		iif (len(aDatas) >  4, aAdd(aCols, {DtoC(aDatas[5]), {|oBrw| aPedidos[oBrw:At(),  9] }, "C", "@!",	0, 6, 2, .F.}),0)
		iif (len(aDatas) >  5, aAdd(aCols, {DtoC(aDatas[6]), {|oBrw| aPedidos[oBrw:At(), 10] }, "C", "@!",	0, 6, 2, .F.}),0)
		iif (len(aDatas) >  6, aAdd(aCols, {DtoC(aDatas[7]), {|oBrw| aPedidos[oBrw:At(), 11] }, "C", "@!",	0, 6, 2, .F.}),0)
		iif (len(aDatas) >  7, aAdd(aCols, {DtoC(aDatas[8]), {|oBrw| aPedidos[oBrw:At(), 12] }, "C", "@!",	0, 6, 2, .F.}),0)
		iif (len(aDatas) >  8, aAdd(aCols, {DtoC(aDatas[9]), {|oBrw| aPedidos[oBrw:At(), 13] }, "C", "@!",	0, 6, 2, .F.}),0)
		iif (len(aDatas) >  9, aAdd(aCols, {DtoC(aDatas[10]),{|oBrw| aPedidos[oBrw:At(), 14] }, "C", "@!",	0, 6, 2, .F.}),0)
		iif (len(aDatas) > 10, aAdd(aCols, {DtoC(aDatas[11]),{|oBrw| aPedidos[oBrw:At(), 15] }, "C", "@!",	0, 6, 2, .F.}),0)
		iif (len(aDatas) > 11, aAdd(aCols, {DtoC(aDatas[12]),{|oBrw| aPedidos[oBrw:At(), 16] }, "C", "@!",	0, 6, 2, .F.}),0)
		iif (len(aDatas) > 12, aAdd(aCols, {DtoC(aDatas[13]),{|oBrw| aPedidos[oBrw:At(), 17] }, "C", "@!",	0, 6, 2, .F.}),0)
		iif (len(aDatas) > 13, aAdd(aCols, {DtoC(aDatas[14]),{|oBrw| aPedidos[oBrw:At(), 18] }, "C", "@!",	0, 6, 2, .F.}),0)
		iif (len(aDatas) > 14, aAdd(aCols, {DtoC(aDatas[15]),{|oBrw| aPedidos[oBrw:At(), 19] }, "C", "@!",	0, 6, 2, .F.}),0)
	EndIf
Return aCols


Static Function fDupClique()
	Local aArea   := FWGetArea()

	nLinha := oFwBrowse:At()
	nColuna := oFwBrowse:ColPos()
	cItem := aPedidos[nLinha][2]

	u_PL060A(cItem)

	FWRestArea(aArea)
Return


Static Function GeraExcel()
	Local oExcel
	Local oFWMsExcel
	Local cArquivo    	:= 'c:\temp\PL290.xml'
	Local cAba			:= ""
	Local nX			:= 0
	Local nY			:= 0
	Local nCols			:= 0
	Local aVal			:= {}

	//Criando o objeto que irá gerar o conteúdo do Excel
	oFWMsExcel := FWMSExcel():New()

	//Aba
	cAba := "Plano Geral"

	oFWMsExcel:AddworkSheet(cAba)

	//Criando a Tabela
	oFWMsExcel:AddTable(cAba,"Dados")
	oFWMsExcel:AddColumn(cAba,"Dados","Produto",1)
	oFWMsExcel:AddColumn(cAba,"Dados","Item do Cliente",1)
	oFWMsExcel:AddColumn(cAba,"Dados","Saldo Atual",1)
	oFWMsExcel:AddColumn(cAba,"Dados","Em Atraso",1)

	if Len(aPedidos[1]) > 20
		nCols := 20
	else
		nCols := Len(aPedidos[1])
	endif

	For nX := 2 to nCols - 4
		oFWMsExcel:AddColumn(cAba,"Dados",DtoC(aDatas[nX]),1)
	Next nX

	For nX := 1 to Len(aPedidos)
		aVal := {}
		For nY := 1 to nCols - 1
			if AllTrim(aPedidos[nX][nY]) == '0'
				Aadd(aVal, '')
			else
				Aadd(aVal, aPedidos[nX][nY])
			endif
		Next nY

		oFWMsExcel:AddRow(cAba,"Dados",aVal)
	Next nX

	//Ativando o arquivo e gerando o xml
	oFWMsExcel:Activate()
	oFWMsExcel:GetXMLFile(cArquivo)

	//Abrindo o excel e abrindo o arquivo xml
	oExcel := MsExcel():New()            	//Abre uma nova conexão com Excel
	oExcel:WorkBooks:Open(cArquivo)     	//Abre uma planilha
	oExcel:SetVisible(.T.)                 	//Visualiza a planilha
	oExcel:Destroy()                        //Encerra o processo do gerenciador de tarefas
return
