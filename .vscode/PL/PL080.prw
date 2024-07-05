#Include 'Protheus.ch'
#INCLUDE "TOTVS.CH"
#INCLUDE "FWMVCDEF.CH"

//-------------------------------------------------------------------
/*/{Protheus.doc} PL080A
Consulta geral do planejamento por item
@author  Carlos Assis
@since   22/05/2024
@version 1.0
/*/
//-------------------------------------------------------------------
User Function PL080()
	Private aDatas := {}
	Private aPedidos := {}

	Private cAliasZA0
	Private cAliasSC6

	Private oDlg       := Nil
	Private oFwBrowse  := Nil
	Private aColumns   := {}

	ObterDados()

	CalculaSaldos()

	fWBrowse1()
Return

Static Function ObterDados()
	Local cSql 		:= ""
	Local nPosItem	:=0
	Local nPosData	:=0
	Local nQtde		:= 0
	Local dData 	:= DaySum(Date(), 15)

	// Carregar pedidos EDI
	cSql := "SELECT ZA0_PRODUT, ZA0_DTENTR, ZA0_QTDE, B1_LOCPAD, B1_DESC "
	cSql += "  FROM " + RetSQLName("ZA0") + " ZA0 "

	cSql += " INNER JOIN " + RetSQLName("SB1") + " SB1 "
	cSql += "    ON B1_FILIAL  		= '" + xFilial("SB1") + "'"
	cSql += "   AND B1_COD     		= ZA0_PRODUT "
	cSql += "   AND B1_MRP     		= 'S' "

	cSql += " WHERE ZA0_FILIAL 		= '" + xFilial("ZA0") + "'"
	cSql += "   AND ZA0_STATUS 		= '0' "
	cSql += "   AND ZA0_DTENTR 	   <= '" + DtOs(dData) + "'"
	cSql += "   AND ZA0.D_E_L_E_T_ <> '*' "
	cSql += "   AND SB1.D_E_L_E_T_ <> '*' "
	cSql += " ORDER BY ZA0_DTENTR, ZA0_PRODUT "
	cAliasZA0 := MPSysOpenQuery(cSql)


	// Carregar pedidos de vendas
	cSql := "SELECT C6_PRODUTO, C6_ENTREG, C6_QTDVEN, C6_QTDENT, B1_LOCPAD, B1_DESC "
	cSql += "  FROM " + RetSQLName("SC6") + " SC6 "

	cSql += " INNER JOIN " + RetSQLName("SB1") + " SB1 "
	cSql += "    ON B1_FILIAL  		= '" + xFilial("SB1") + "'"
	cSql += "   AND B1_COD     		=  C6_PRODUTO "
	cSql += "   AND B1_MRP     		=  'S' "

	cSql += " INNER JOIN " + RetSQLName("SC5") + " SC5 "
	cSql += "    ON C5_FILIAL  		= '" + xFilial("SC5") + "'"
	cSql += "   AND C5_NUM      	=  C6_NUM "
	cSql += "   AND C5_NOTA        	=  '' "
	cSql += "   AND C5_LIBEROK 		<> 'E' "

	cSql += " INNER JOIN " + RetSQLName("SF4") + " SF4 "
	cSql += "    ON F4_FILIAL 		=  '" + xFilial("SF4") + "'"
	cSql += "   AND F4_CODIGO      	=  C6_TES "
	cSql += "   AND F4_QTDZERO    	<> '1' "

	cSql += " WHERE C6_FILIAL      	= '" + xFilial("SC6") + "'"
	cSql += "   AND C6_ENTREG 	    <= '" + DtOs(dData) + "'"
	cSql += "   AND C6_QTDENT      	<  C6_QTDVEN "
	cSql += "   AND C6_BLQ 		  	<> 'R' "
	cSql += "   AND SC5.D_E_L_E_T_  <> '*' "
	cSql += "   AND SC6.D_E_L_E_T_  <> '*' "
	cSql += "   AND SF4.D_E_L_E_T_  <> '*' "
	cSql += " ORDER BY C6_ENTREG, C6_PRODUTO "
	cAliasSC6 := MPSysOpenQuery(cSql)

	if (cAliasZA0)->(EOF()) .and. (cAliasSC6)->(EOF())
		return
	endif

	MontaDatas()

	While (cAliasZA0)->(!EOF())

		// Localiza o item e a data
		nPosData := aScan(aDatas, {|x| x == sToD((cAliasZA0)->ZA0_DTENTR)})
		nPosItem := aScan(aPedidos, {|x| AllTrim(x[1]) == AllTrim((cAliasZA0)->ZA0_PRODUT)})

		IF nPosItem == 0
			Aadd(aPedidos,{(cAliasZA0)->ZA0_PRODUT,(cAliasZA0)->B1_DESC,(cAliasZA0)->B1_LOCPAD, ;
				"0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0"})
			nPosItem := aScan(aPedidos, {|x| AllTrim(x[1]) == AllTrim((cAliasZA0)->ZA0_PRODUT)})
		EndIf

		if nPosItem <> 0 .and. nPosData <> 0
			// Soma a quantidade do pedido
			nQtde := val(aPedidos[nPosItem][nPosData+4]) + (cAliasZA0)->ZA0_QTDE
			aPedidos[nPosItem][nPosData+4] := cValToChar(nQtde)
		endif

		(cAliasZA0)->(DbSkip())
	End While

	While (cAliasSC6)->(!EOF())

		// Localiza o item e a data
		nPosData := aScan(aDatas, {|x| x == sToD((cAliasSC6)->C6_ENTREG)})
		nPosItem := aScan(aPedidos, {|x| AllTrim(x[1]) == AllTrim((cAliasSC6)->C6_PRODUTO)})

		IF nPosItem == 0
			Aadd(aPedidos,{(cAliasSC6)->C6_PRODUTO,(cAliasSC6)->B1_DESC,(cAliasSC6)->B1_LOCPAD, ;
				"0", "0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0"})
			nPosItem := aScan(aPedidos, {|x| AllTrim(x[1]) == AllTrim((cAliasSC6)->C6_PRODUTO)})
		EndIf

		if nPosItem <> 0 .and. nPosData <> 0
			// Soma a quantidade do pedido
			nQtde := val(aPedidos[nPosItem][nPosData+4]) + ((cAliasSC6)->C6_QTDVEN - (cAliasSC6)->C6_QTDENT)
			aPedidos[nPosItem][nPosData+4] := cValToChar(nQtde)
		EndIf

		(cAliasSC6)->(DbSkip())
	End While
return

Static Function	CalculaSaldos()
	Local nRow := 0
	Local nCol := 0
	Local nSaldo :=0

	aSort(aPedidos, , , {|x, y| x[1] < y[1]})

	dbSelectArea("SB2")
	SB2->(DBSetOrder(1))

	For nRow := 1 to Len(aPedidos) Step 1
		If SB2->(MsSeek(xFilial("SB2") + avKey(aPedidos[nRow][1], "B1_COD") + avKey(aPedidos[nRow][3], "B1_LOCPAD")))
			nSaldo := SB2->B2_QATU
		else
			nSaldo := 0
		EndIf

		aPedidos[nRow][4] = cValToChar(nSaldo)

		For nCol := 5 to Len(aPedidos[nRow])
			nSaldo := nSaldo - val(aPedidos[nRow][nCol])

			if nSaldo < 0 .and. val(aPedidos[nRow][nCol]) > 0
				aPedidos[nRow][nCol] := aPedidos[nRow][nCol] + " ( " + cValToChar(nSaldo) + " )"
			endif
		Next
	Next
return


/*
	Todas as datas do periodo
*/
Static Function MontaDatas()
	Local nInd  :=0
	Local dData := Date()

	if (cAliasZA0)->(!EOF())
		dData := sToD((cAliasZA0)->ZA0_DTENTR)
	Endif

	if (cAliasSC6)->(!EOF())
		if (cAliasZA0)->ZA0_DTENTR > (cAliasSC6)->C6_ENTREG
			dData := sToD((cAliasSC6)->C6_ENTREG)
		endif
	Endif

	aDatas := {}

	For nInd := 1 to 15 Step 1
		Aadd(aDatas,dData)
		dData := DaySum(dData, 1)
	Next
Return


Static Function fWBrowse1()
	Local nX:=0

	oDlg:= FwDialogModal():New()
	oDlg:SetEscClose(.T.)
	oDlg:SetTitle('Plano por item')

	//Seta a largura e altura da janela em pixel
	oDlg:SetPos(000, 000)
	oDlg:SetSize(400, 700)

	oDlg:CreateDialog()
	oDlg:AddCloseButton(Nil, 'Fechar')

	//oDlg:AddButton('Sair'    , { || oModal:DeActivate() }, 'Sair',,.T.,.F.,.T.,)

	oPnl:=oDlg:GetPanelMain()

	oFwBrowse := FWBrowse():New()
	oFwBrowse:SetDataArrayoBrowse()  //Define utilização de array
	oFwBrowse:AddStatusColumns( { || BrwStatus() }, { || BrwLegend() } )
	oFwBrowse:SetArray(aPedidos)


	aColumns := RetColumns()

	//Cria as colunas do array
	For nX := 1 To Len(aColumns )
		oFwBrowse:AddColumn( aColumns[nX] )
	Next

	oFwBrowse:SetOwner(oPnl)
	oFwBrowse:SetDoubleClick( {|| fDupClique() } )
	oFwBrowse:SetDescription( "Plano Geral Por Item" )

	oFwBrowse:Activate()
	oDlg:Activate()
Return


Static Function RetColumns()
	Local aColumns := {}

	aAdd(aColumns, {"Item",  	   {|oBrw| aPedidos[oBrw:At(), 1] }, "C", "@!", 1,  7, 0, .F.})
	aAdd(aColumns, {"Descricao",   {|oBrw| aPedidos[oBrw:At(), 2] }, "C", "@!", 1, 20, 0, .F.})
	aAdd(aColumns, {"Saldo Atual", {|oBrw| aPedidos[oBrw:At(), 4] }, "C", "@!", 0,  5, 2, .F.})

	if len(aDatas) == 0
		FWAlertWarning("NAO EXISTEM DADOS PARA MOSTRAR! ", "PLANO GERAL")
	else
		iif (len(aDatas) >  0, aAdd(aColumns, {DtoC(aDatas[1]), {|oBrw| aPedidos[oBrw:At(),  5] }, "C", "@!",	0, 5, 2, .F.}),0)
		iif (len(aDatas) >  1, aAdd(aColumns, {DtoC(aDatas[2]), {|oBrw| aPedidos[oBrw:At(),  6] }, "C", "@!",	0, 5, 2, .F.}),0)
		iif (len(aDatas) >  2, aAdd(aColumns, {DtoC(aDatas[3]), {|oBrw| aPedidos[oBrw:At(),  7] }, "C", "@!",	0, 5, 2, .F.}),0)
		iif (len(aDatas) >  3, aAdd(aColumns, {DtoC(aDatas[4]), {|oBrw| aPedidos[oBrw:At(),  8] }, "C", "@!",	0, 5, 2, .F.}),0)
		iif (len(aDatas) >  4, aAdd(aColumns, {DtoC(aDatas[5]), {|oBrw| aPedidos[oBrw:At(),  9] }, "C", "@!",	0, 5, 2, .F.}),0)
		iif (len(aDatas) >  5, aAdd(aColumns, {DtoC(aDatas[6]), {|oBrw| aPedidos[oBrw:At(), 10] }, "C", "@!",	0, 5, 2, .F.}),0)
		iif (len(aDatas) >  6, aAdd(aColumns, {DtoC(aDatas[7]), {|oBrw| aPedidos[oBrw:At(), 11] }, "C", "@!",	0, 5, 2, .F.}),0)
		iif (len(aDatas) >  7, aAdd(aColumns, {DtoC(aDatas[8]), {|oBrw| aPedidos[oBrw:At(), 12] }, "C", "@!",	0, 5, 2, .F.}),0)
		iif (len(aDatas) >  8, aAdd(aColumns, {DtoC(aDatas[9]), {|oBrw| aPedidos[oBrw:At(), 13] }, "C", "@!",	0, 5, 2, .F.}),0)
		iif (len(aDatas) >  9, aAdd(aColumns, {DtoC(aDatas[10]),{|oBrw| aPedidos[oBrw:At(), 14] }, "C", "@!",	0, 5, 2, .F.}),0)
		iif (len(aDatas) > 10, aAdd(aColumns, {DtoC(aDatas[11]),{|oBrw| aPedidos[oBrw:At(), 15] }, "C", "@!",	0, 5, 2, .F.}),0)
		iif (len(aDatas) > 11, aAdd(aColumns, {DtoC(aDatas[12]),{|oBrw| aPedidos[oBrw:At(), 16] }, "C", "@!",	0, 5, 2, .F.}),0)
		iif (len(aDatas) > 12, aAdd(aColumns, {DtoC(aDatas[13]),{|oBrw| aPedidos[oBrw:At(), 17] }, "C", "@!",	0, 5, 2, .F.}),0)
		iif (len(aDatas) > 13, aAdd(aColumns, {DtoC(aDatas[14]),{|oBrw| aPedidos[oBrw:At(), 18] }, "C", "@!",	0, 5, 2, .F.}),0)
		iif (len(aDatas) > 14, aAdd(aColumns, {DtoC(aDatas[15]),{|oBrw| aPedidos[oBrw:At(), 19] }, "C", "@!",	0, 5, 2, .F.}),0)
	EndIf

Return aColumns


Static Function BrwStatus()
Return Iif(ValidMark(),"BR_VERDE","BR_VERMELHO")


Static Function ValidMark()
	Local lRet := .T.
Return lRet


Static Function BrwLegend()
	Local oLegend := FWLegend():New()

	oLegend:Add("","BR_VERDE" , "VERDE" )
	oLegend:Add("","BR_VERMELHO", "VERMELHO" )
	oLegend:Activate()
	oLegend:View()
	oLegend:DeActivate()
Return



Static Function fDupClique()
	Local aArea   := FWGetArea()

	nLinha := oFwBrowse:At()
	nColuna := oFwBrowse:ColPos()
	cItem := aPedidos[nLinha][1]

	u_PL060A(cItem)

	FWRestArea(aArea)
Return
