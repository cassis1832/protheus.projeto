#include "totvs.ch"
#Include "MSOLE.CH"

//-------------------------------------------------------------------
/*/{Protheus.doc} PL030
Consulta geral do planejamento
@author  Carlos Assis
@since   22/05/2024
@version 1.0
/*/
//-------------------------------------------------------------------
User Function PL030old()
	Private cCliente := "000003"
	Private cLoja := "01"

	Private aDatas := {}
	Private aPedidos := {}
	Private cSql := ""

	Private cAliasZA0
	Private cAliasSC6

	Private nPosItem:=0
	Private nPosData:=0
	Private nSaldo:= 0
	Private nQtde:= 0

	Private oDlg       := Nil
	Private oFwBrowse  := Nil
	Private aColumns   := {}

	// Carrega os itens e os saldos iniciais
	strSql := "SELECT A7_PRODUTO, B1_LOCPAD "
	strSql += "  FROM " + RetSQLName("SA7") + " SA7, " + RetSQLName("SB1") + " SB1"
	strSql += " WHERE A7_FILIAL         = '" + xFilial("SA7") + "' "
	strSql += "   AND B1_FILIAL         = '" + xFilial("SB1") + "' "
	strSql += "   AND A7_CLIENTE        = '" + cCliente + "'"
	strSql += "   AND A7_LOJA           = '" + cLoja + "'"
	strSql += "   AND A7_PRODUTO        = B1_COD"
	strSql += "   AND SA7.D_E_L_E_T_    <> '*' "
	strSql += "   AND SB1.D_E_L_E_T_    <> '*' "
	strSql += " ORDER BY A7_PRODUTO "
	cAliasSA7 := MPSysOpenQuery(strSql)

	dbSelectArea("SB2")
	SB2->(DBSetOrder(1))

	While (cAliasSA7)->(!EOF())

		If SB2->(MsSeek(xFilial("SB2") + (cAliasSA7)->A7_PRODUTO + (cAliasSA7)->B1_LOCPAD))
			nSaldo := SB2->B2_QATU
		else
			nSaldo := 0
		EndIf

		Aadd(aPedidos,{(cAliasSA7)->A7_PRODUTO, cValToChar(nSaldo), "0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0"})

		(cAliasSA7)->(DbSkip())
	EndDo

	strSql := "SELECT ZA0_DTENTR, ZA0_PRODUT, ZA0_QTDE "
	strSql += "  FROM ZA0010, SB1010 "
	strSql += " WHERE ZA0_STATUS = '0' "
	strSql += "   AND ZA0_CLIENT = '" + cCliente + "'"
	strSql += "   AND ZA0_LOJA   = '" + cLoja + "'"
	strSql += "   AND ZA0_FILIAL = B1_FILIAL "
	strSql += "   AND ZA0_PRODUT = B1_COD "
	strSql += "   AND ZA0010.D_E_L_E_T_ <> '*' "
	strSql += "   AND SB1010.D_E_L_E_T_ <> '*' "
	strSql += " ORDER BY ZA0_DTENTR, ZA0_PRODUT "
	cAliasZA0 := MPSysOpenQuery(strSql)

	strSql := "SELECT B1_COD, C6_ENTREG, C6_QTDVEN "
	strSql += "  FROM SC5010, SC6010, SB1010, SF4010 "
	strSql += " WHERE C5_NOTA      = '' "
	strSql += "   AND C5_CLIENTE     = '" + cCliente + "'"
	strSql += "   AND C5_LOJACLI     = '" + cLoja + "'"
	strSql += "   AND C5_LIBEROK    <> 'E' "
	strSql += "   AND C5_FILIAL      = C6_FILIAL "
	strSql += "   AND C5_NUM         = C6_NUM "
	strSql += "   AND C6_QTDENT     <= C6_QTDVEN "
	strSql += "   AND SC6010.C6_BLQ <> 'R' "
	strSql += "   AND C6_FILIAL      = B1_FILIAL "
	strSql += "   AND C6_PRODUTO     = B1_COD "
	strSql += "   AND C5_FILIAL      = F4_FILIAL "
	strSql += "   AND F4_CODIGO      = C6_TES "
	strSql += "   AND F4_QTDZERO    <> '1' "
	strSql += "   AND SC5010.D_E_L_E_T_   <> '*' "
	strSql += "   AND SC6010.D_E_L_E_T_   <> '*' "
	strSql += "   AND SF4010.D_E_L_E_T_   <> '*' "
	strSql += "   AND SB1010.D_E_L_E_T_   <> '*' "
	strSql += "   AND SB1010.D_E_L_E_T_   <> '*' "
	strSql += " ORDER BY C6_ENTREG, C6_PRODUTO "
	cAliasSC6 := MPSysOpenQuery(strSql)

	MontaDatas()

	While (cAliasZA0)->(!EOF())

		// Localiza o item e a data
		nPosItem := aScan(aPedidos, {|x| AllTrim(x[1]) == AllTrim((cAliasZA0)->ZA0_PRODUT)})
		nPosData := aScan(aDatas, {|x| x == sToD((cAliasZA0)->ZA0_DTENTR)})

		if nPosItem <> 0 .and. nPosData <> 0
			// Soma a quantidade do pedido
			nQtde := val(aPedidos[nPosItem][nPosData+2]) + (cAliasZA0)->ZA0_QTDE
			aPedidos[nPosItem][nPosData+2] := cValToChar(nQtde)
		endif

		(cAliasZA0)->(DbSkip())
	End While


	While (cAliasSC6)->(!EOF())

		// Localiza o item e a data
		nPosItem := aScan(aPedidos, {|x| AllTrim(x[1]) == AllTrim((cAliasSC6)->C6_PRODUTO)})
		nPosData := aScan(aDatas, {|x| x == sToD((cAliasSC6)->C6_ENTREG)})

		// Soma a quantidade do pedido
		nQtde := val(aPedidos[nPosItem][nPosData+2]) + val((cAliasSC6)->C6_QTDVEN)
		aPedidos[nPosItem][nPosData+2] := cValToChar(nQtde)

		(cAliasSC6)->(DbSkip())
	End While

	CalculaSaldos()

	fWBrowse1()
Return

Static Function	CalculaSaldos()
	Local nRow := 0
	Local nCol := 0
	Local nSaldo :=0

	For nRow := 1 to Len(aPedidos) Step 1
		nSaldo := val(aPedidos[nRow][2])

		For nCol := 3 to Len(aPedidos[nRow])

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
	Local nInd :=0
	Local dData

	if (cAliasZA0)->(!EOF())
		dData := (cAliasZA0)->ZA0_DTENTR
	Endif

	if (cAliasSC6)->(!EOF())
		if (cAliasZA0)->ZA0_DTENTR > (cAliasSC6)->C6_ENTREG
			dData := (cAliasSC6)->C6_ENTREG
		endif
	Endif

	aDatas := {}
	dData := sToD(dData)

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

	oDlg = TDialog():New(0, 0, 800, 1500, "Visão Geral do Planejamento por Cliente",,,,,,,,,.T.)

	oFwBrowse := FWBrowse():New(oDlg)
	oFwBrowse:SetDataArrayoBrowse()  //Define utilização de array
	oFwBrowse:AddStatusColumns( { || BrwStatus() }, { || BrwLegend() } )

	//Indica o array utilizado para apresentação dos dados no Browse.
	oFwBrowse:SetArray(aPedidos)

	aColumns := RetColumns()

	//Cria as colunas do array
	For nX := 1 To Len(aColumns )
		oFwBrowse:AddColumn( aColumns[nX] )
	Next

	oFwBrowse:SetOwner(oDlg)
	oFwBrowse:SetDescription( "Planejamento por Cliente" )
	oFwBrowse:Activate()

	oDlg:Activate()
Return


Static Function RetColumns()
	Local aColumns := {}

	aAdd(aColumns, {"Item",  {|oBrw| aPedidos[oBrw:At(), 1] }, "C", "@!"     , 1, 10, 0, .F.})
	aAdd(aColumns, {"Saldo Atual", {|oBrw| aPedidos[oBrw:At(), 2] }, "C", "@!", 0,  6, 2, .F.})

	aAdd(aColumns, {DtoC(aDatas[1]), {|oBrw| aPedidos[oBrw:At(),  3] }, "C", "@!",	0, 6, 2, .F.})
	aAdd(aColumns, {DtoC(aDatas[2]), {|oBrw| aPedidos[oBrw:At(),  4] }, "C", "@!",	0, 6, 2, .F.})
	aAdd(aColumns, {DtoC(aDatas[3]), {|oBrw| aPedidos[oBrw:At(),  5] }, "C", "@!",	0, 6, 2, .F.})
	aAdd(aColumns, {DtoC(aDatas[4]), {|oBrw| aPedidos[oBrw:At(),  6] }, "C", "@!",	0, 6, 2, .F.})
	aAdd(aColumns, {DtoC(aDatas[5]), {|oBrw| aPedidos[oBrw:At(),  7] }, "C", "@!",	0, 6, 2, .F.})
	aAdd(aColumns, {DtoC(aDatas[6]), {|oBrw| aPedidos[oBrw:At(),  8] }, "C", "@!",	0, 6, 2, .F.})
	aAdd(aColumns, {DtoC(aDatas[7]), {|oBrw| aPedidos[oBrw:At(),  9] }, "C", "@!",	0, 6, 2, .F.})
	aAdd(aColumns, {DtoC(aDatas[8]), {|oBrw| aPedidos[oBrw:At(), 10] }, "C", "@!",	0, 6, 2, .F.})
	aAdd(aColumns, {DtoC(aDatas[9]), {|oBrw| aPedidos[oBrw:At(), 11] }, "C", "@!",	0, 6, 2, .F.})
	aAdd(aColumns, {DtoC(aDatas[10]),{|oBrw| aPedidos[oBrw:At(), 12] }, "C", "@!",	0, 6, 2, .F.})
	aAdd(aColumns, {DtoC(aDatas[11]),{|oBrw| aPedidos[oBrw:At(), 13] }, "C", "@!",	0, 6, 2, .F.})
	aAdd(aColumns, {DtoC(aDatas[12]),{|oBrw| aPedidos[oBrw:At(), 14] }, "C", "@!",	0, 6, 2, .F.})
	aAdd(aColumns, {DtoC(aDatas[13]),{|oBrw| aPedidos[oBrw:At(), 15] }, "C", "@!",	0, 6, 2, .F.})
	aAdd(aColumns, {DtoC(aDatas[14]),{|oBrw| aPedidos[oBrw:At(), 16] }, "C", "@!",	0, 6, 2, .F.})
	aAdd(aColumns, {DtoC(aDatas[15]),{|oBrw| aPedidos[oBrw:At(), 17] }, "C", "@!",	0, 6, 2, .F.})

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
