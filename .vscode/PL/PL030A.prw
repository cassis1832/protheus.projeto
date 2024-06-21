#Include 'Protheus.ch'
#INCLUDE "TOTVS.CH"
#INCLUDE "FWMVCDEF.CH"

//-------------------------------------------------------------------
/*/{Protheus.doc} PL030A
Consulta geral do planejamento
@author  Carlos Assis
@since   22/05/2024
@version 1.0
/*/
//-------------------------------------------------------------------
User Function PL030A(cCliente1, cLoja1)

	Private cCliente := cCliente1
	Private cLoja := cLoja1

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
	Local cSql := ""
	Local nQtde:= 0
	Local nSaldo:= 0
	Local nPosItem:=0
	Local nPosData:=0

	// Carrega os itens e os saldos iniciais
	cSql := "SELECT A7_PRODUTO, B1_LOCPAD, A7_CODCLI "
	cSql += "  FROM " + RetSQLName("SA7") + " SA7, " + RetSQLName("SB1") + " SB1"
	cSql += " WHERE A7_FILIAL         = '" + xFilial("SA7") + "' "
	cSql += "   AND B1_FILIAL         = '" + xFilial("SB1") + "' "
	cSql += "   AND A7_CLIENTE        = '" + cCliente + "'"
	cSql += "   AND A7_LOJA           = '" + cLoja + "'"
	cSql += "   AND A7_PRODUTO        = B1_COD"
	cSql += "   AND SA7.D_E_L_E_T_    <> '*' "
	cSql += "   AND SB1.D_E_L_E_T_    <> '*' "
	cSql += " ORDER BY A7_PRODUTO "
	cAliasSA7 := MPSysOpenQuery(cSql)

	dbSelectArea("SB2")
	SB2->(DBSetOrder(1))

	While (cAliasSA7)->(!EOF())

		if SubString((cAliasSA7)->A7_PRODUTO, 1, 1) != "7"

			If SB2->(MsSeek(xFilial("SB2") + (cAliasSA7)->A7_PRODUTO + (cAliasSA7)->B1_LOCPAD))
				nSaldo := SB2->B2_QATU
			else
				nSaldo := 0
			EndIf

			Aadd(aPedidos,{(cAliasSA7)->A7_PRODUTO, (cAliasSA7)->A7_CODCLI, cValToChar(nSaldo), "0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0"})

		EndIf

		(cAliasSA7)->(DbSkip())
	EndDo

	// Carregar pedidos EDI
	cSql := "SELECT ZA0_DTENTR, ZA0_PRODUT, ZA0_QTDE - ZA0_QTCONF AS ZA0_SALDO "
	cSql += "  FROM ZA0010, SB1010 "
	cSql += " WHERE ZA0_STATUS 		= '0' "
	cSql += "   AND ZA0_CLIENT 		= '" + cCliente + "'"
	cSql += "   AND ZA0_LOJA   		= '" + cLoja + "'"
	cSql += "   AND ZA0_FILIAL 		= B1_FILIAL "
	cSql += "   AND ZA0_PRODUT 		= B1_COD "
	cSql += "   AND ZA0_QTDE   		> ZA0_QTCONF "
	cSql += "   AND ZA0010.D_E_L_E_T_ <> '*' "
	cSql += "   AND SB1010.D_E_L_E_T_ <> '*' "
	cSql += " ORDER BY ZA0_DTENTR, ZA0_PRODUT "
	cAliasZA0 := MPSysOpenQuery(cSql)

	// Carregar pedidos de vendas
	cSql := "SELECT B1_COD, C6_ENTREG, C6_QTDVEN, C6_QTDENT, C6_QTDVEN - C6_QTDENT AS C6_SALDO "
	cSql += "  FROM SC5010, SC6010, SB1010, SF4010 "
	cSql += " WHERE C5_NOTA        = '' "
	cSql += "   AND C5_CLIENTE     = '" + cCliente + "'"
	cSql += "   AND C5_LOJACLI     = '" + cLoja + "'"
	cSql += "   AND C5_LIBEROK    <> 'E' "
	cSql += "   AND C5_FILIAL      = C6_FILIAL "
	cSql += "   AND C5_NUM         = C6_NUM "
	cSql += "   AND C6_QTDENT      < C6_QTDVEN "
	cSql += "   AND SC6010.C6_BLQ <> 'R' "
	cSql += "   AND C6_FILIAL      = B1_FILIAL "
	cSql += "   AND C6_PRODUTO     = B1_COD "
	cSql += "   AND C5_FILIAL      = F4_FILIAL "
	cSql += "   AND F4_CODIGO      = C6_TES "
	cSql += "   AND F4_QTDZERO    <> '1' "
	cSql += "   AND SC5010.D_E_L_E_T_   <> '*' "
	cSql += "   AND SC6010.D_E_L_E_T_   <> '*' "
	cSql += "   AND SF4010.D_E_L_E_T_   <> '*' "
	cSql += "   AND SB1010.D_E_L_E_T_   <> '*' "
	cSql += "   AND SB1010.D_E_L_E_T_   <> '*' "
	cSql += " ORDER BY C6_ENTREG, C6_PRODUTO "
	cAliasSC6 := MPSysOpenQuery(cSql)

	if (cAliasZA0)->(EOF()) .and. (cAliasSC6)->(EOF())
		return
	endif

	MontaDatas()

	While (cAliasZA0)->(!EOF())

		// Localiza o item e a data
		nPosItem := aScan(aPedidos, {|x| AllTrim(x[1]) == AllTrim((cAliasZA0)->ZA0_PRODUT)})
		nPosData := aScan(aDatas, {|x| x == sToD((cAliasZA0)->ZA0_DTENTR)})

		if nPosItem <> 0 .and. nPosData <> 0
			// Soma a quantidade do pedido
			nQtde := val(aPedidos[nPosItem][nPosData+3]) + (cAliasZA0)->ZA0_SALDO
			aPedidos[nPosItem][nPosData+3] := cValToChar(nQtde)
		endif

		(cAliasZA0)->(DbSkip())
	End While

	While (cAliasSC6)->(!EOF())

		// Localiza o item e a data
		nPosItem := aScan(aPedidos, {|x| AllTrim(x[1]) == AllTrim((cAliasSC6)->C6_PRODUTO)})
		nPosData := aScan(aDatas, {|x| x == sToD((cAliasSC6)->C6_ENTREG)})

		// Soma a quantidade do pedido
		nQtde := val(aPedidos[nPosItem][nPosData+3]) + val((cAliasSC6)->C6_SALDO)
		aPedidos[nPosItem][nPosData+3] := cValToChar(nQtde)

		(cAliasSC6)->(DbSkip())
	End While
return

Static Function	CalculaSaldos()
	Local nRow := 0
	Local nCol := 0
	Local nSaldo :=0

	For nRow := 1 to Len(aPedidos) Step 1
		nSaldo := val(aPedidos[nRow][3])

		For nCol := 4 to Len(aPedidos[nRow])

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


/*
	Somente as datas com conteúdo
*/
Static Function MontaDt2()
	Local nX := 0
	Local dData
	Local dZA
	Local dSC

	aDatas := {}

	While ZA0->(!Eof()) .and. SC6->(!Eof())
		if (cAliasZA0)->(EOF())
			dZA := 31/12/9999
		else
			dZA := (cAliasZA0)->ZA0_DTENTR
		Endif

		if (cAliasSC6)->(EOF())
			dSC := 31/12/9999
		else
			dSC := (cAliasSC6)->C6_ENTREG
		Endif

		if dZA < dSC
			dData := dZA
			(cAliasZA0)->(DbSkip())
		else
			dData := dSC
			(cAliasSC6)->(DbSkip())
		endif

		if nX == 0
			nX := nX + 1
			Aadd(aDatas,dData)
		else
			if dData != aDatas[nX]
				nX := nX + 1
				Aadd(aDatas,dData)
			endif
		endif

	Enddo
Return


Static Function fWBrowse1()
	Local nX:=0

	oDlg:= FwDialogModal():New()
	oDlg:SetEscClose(.T.)
	oDlg:SetTitle('Plano por cliente')

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
	oFwBrowse:SetDescription( "Planejamento por Cliente" )

	oFwBrowse:Activate()
	oDlg:Activate()
Return


Static Function RetColumns()
	Local aColumns := {}

	aAdd(aColumns, {"Item",  {|oBrw| aPedidos[oBrw:At(), 1] }, "C", "@!"     , 1, 10, 0, .F.})
	aAdd(aColumns, {"Item do cliente", {|oBrw| aPedidos[oBrw:At(), 2] }, "C", "@!"     , 1, 10, 0, .F.})
	aAdd(aColumns, {"Saldo Atual", {|oBrw| aPedidos[oBrw:At(), 3] }, "C", "@!", 0,  6, 2, .F.})

	if len(aDatas) == 0
		FWAlertWarning("NAO EXISTEM DADOS PARA MOSTRAR! ", "PLANO GERAL")
	else
		iif (len(aDatas) >  0, aAdd(aColumns, {DtoC(aDatas[1]), {|oBrw| aPedidos[oBrw:At(),  4] }, "C", "@!",	0, 6, 2, .F.}),0)
		iif (len(aDatas) >  1, aAdd(aColumns, {DtoC(aDatas[2]), {|oBrw| aPedidos[oBrw:At(),  5] }, "C", "@!",	0, 6, 2, .F.}),0)
		iif (len(aDatas) >  2, aAdd(aColumns, {DtoC(aDatas[3]), {|oBrw| aPedidos[oBrw:At(),  6] }, "C", "@!",	0, 6, 2, .F.}),0)
		iif (len(aDatas) >  3, aAdd(aColumns, {DtoC(aDatas[4]), {|oBrw| aPedidos[oBrw:At(),  7] }, "C", "@!",	0, 6, 2, .F.}),0)
		iif (len(aDatas) >  4, aAdd(aColumns, {DtoC(aDatas[5]), {|oBrw| aPedidos[oBrw:At(),  8] }, "C", "@!",	0, 6, 2, .F.}),0)
		iif (len(aDatas) >  5, aAdd(aColumns, {DtoC(aDatas[6]), {|oBrw| aPedidos[oBrw:At(),  9] }, "C", "@!",	0, 6, 2, .F.}),0)
		iif (len(aDatas) >  6, aAdd(aColumns, {DtoC(aDatas[7]), {|oBrw| aPedidos[oBrw:At(), 10] }, "C", "@!",	0, 6, 2, .F.}),0)
		iif (len(aDatas) >  7, aAdd(aColumns, {DtoC(aDatas[8]), {|oBrw| aPedidos[oBrw:At(), 11] }, "C", "@!",	0, 6, 2, .F.}),0)
		iif (len(aDatas) >  8, aAdd(aColumns, {DtoC(aDatas[9]), {|oBrw| aPedidos[oBrw:At(), 12] }, "C", "@!",	0, 6, 2, .F.}),0)
		iif (len(aDatas) >  9, aAdd(aColumns, {DtoC(aDatas[10]),{|oBrw| aPedidos[oBrw:At(), 13] }, "C", "@!",	0, 6, 2, .F.}),0)
		iif (len(aDatas) > 10, aAdd(aColumns, {DtoC(aDatas[11]),{|oBrw| aPedidos[oBrw:At(), 14] }, "C", "@!",	0, 6, 2, .F.}),0)
		iif (len(aDatas) > 11, aAdd(aColumns, {DtoC(aDatas[12]),{|oBrw| aPedidos[oBrw:At(), 15] }, "C", "@!",	0, 6, 2, .F.}),0)
		iif (len(aDatas) > 12, aAdd(aColumns, {DtoC(aDatas[13]),{|oBrw| aPedidos[oBrw:At(), 16] }, "C", "@!",	0, 6, 2, .F.}),0)
		iif (len(aDatas) > 13, aAdd(aColumns, {DtoC(aDatas[14]),{|oBrw| aPedidos[oBrw:At(), 17] }, "C", "@!",	0, 6, 2, .F.}),0)
		iif (len(aDatas) > 14, aAdd(aColumns, {DtoC(aDatas[15]),{|oBrw| aPedidos[oBrw:At(), 18] }, "C", "@!",	0, 6, 2, .F.}),0)
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
