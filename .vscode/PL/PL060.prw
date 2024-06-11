#Include 'Protheus.ch'
#Include 'FWMVCDef.ch'

/*/{Protheus.doc} PL060
Função: (RPAD))
@author Assis
@since 10/06/2024
@version 1.0
	@return Nil, Fução não tem retorno
	@example
	u_PL050()
/*/

User Function PL060()

	Private cItem := "10614010"

	Private aLinhas   := {}
	Private nSaldoIni := 0
	Private nSaldoAtu := 0

	Private oDlg       := Nil
	Private oFwBrowse  := Nil
	Private aColumns   := {}

	LerItem()
	ObterPedidos()
	ObterProducao()
	ObterCompras()

	CalculaSaldos()

	fWBrowse1()
Return

Static Function LerItem()
	dbSelectArea("SB1")
	SB1->(DBSetOrder(1))

	If ! SB1->(MsSeek(xFilial("SB1") + cItem))
		return
	EndIf

	dbSelectArea("SB2")
	SB2->(DBSetOrder(1))

	If SB2->(MsSeek(xFilial("SB2") + SB1->B1_COD + SB1->B1_LOCPAD))
		nSaldoIni := SB2->B2_QATU
	else
		nSaldoIni := 0
	EndIf
return

Static Function ObterCompras()
	Local cSql
	Local cAlias

	cSql := "SELECT C1_NUM, C1_ITEM, C1_PRODUTO, "
	cSql += "	C1_QUANT, C1_DATPRF "
	cSql += " FROM " +	RetSQLName("SC1") + " SC1 "
	cSql += "WHERE C1_FILIAL  = '" + xFilial("SC1") + "' "
	cSql += "  AND C1_PRODUTO = '" + cItem + "'"
	cSql += "  AND SC1.D_E_L_E_T_ = ' ' "
	cSql += "	ORDER BY C1_DATPRF "

	cAlias := MPSysOpenQuery(cSql)

	While (cAlias)->(!EOF())

		Aadd(aLinhas,{(cAlias)->C1_DATPRF + "1", 1, "SC", ;
			(cAlias)->C1_NUM + (cAlias)->C1_ITEM, ;
			DtoC(sToD((cAlias)->C2_DATPRF)),(cAlias)->C2_QUANT, 0})

		(cAlias)->(DbSkip())
	enddo
return


Static Function ObterProducao()
	Local cSql
	Local cAliasOrd

	cSql := "SELECT C2_NUM, C2_ITEM, C2_SEQUEN, C2_PRODUTO, "
	cSql += "	C2_QUANT, C2_DATPRI, C2_DATPRF "
	cSql += " FROM " +	RetSQLName("SC2") + " SC2 "
	cSql += "WHERE C2_FILIAL  = '" + xFilial("SC2") + "' "
	cSql += "  AND C2_PRODUTO = '" + cItem + "'"
	cSql += "  AND SC2.D_E_L_E_T_ = ' ' "
	cSql += "	ORDER BY C2_DATPRF "

	cAliasOrd := MPSysOpenQuery(cSql)

	While (cAliasOrd)->(!EOF())

		Aadd(aLinhas,{(cAliasOrd)->C2_DATPRF + "1", 1, "OP", ;
			(cAliasOrd)->C2_NUM + (cAliasOrd)->C2_ITEM + (cAliasOrd)->C2_SEQUEN, ;
			DtoC(sToD((cAliasOrd)->C2_DATPRF)),(cAliasOrd)->C2_QUANT, 0})

		(cAliasOrd)->(DbSkip())
	enddo

return

Static Function ObterPedidos()
	Local cSql := ""

	// Carregar pedidos EDI
	cSql := "SELECT ZA0_DTENTR, ZA0_PRODUT, ZA0_QTDE, ZA0_NUMPED "
	cSql += "  FROM ZA0010 "
	cSql += " WHERE ZA0_STATUS          = '0' "
	cSql += "   AND ZA0_FILIAL          = '" + xFilial("ZA0") + "'"
	cSql += "   AND ZA0_PRODUT          = '" + cItem +  "'"
	cSql += "   AND ZA0010.D_E_L_E_T_  <> '*' "
	cSql += " ORDER BY ZA0_DTENTR "
	cAliasZA0 := MPSysOpenQuery(cSql)

	While (cAliasZA0)->(!EOF())
		Aadd(aLinhas,{(cAliasZA0)->ZA0_DTENTR + "2", 2, "EDI", ;
			(cAliasZA0)->ZA0_NUMPED, ;
			DtoC(sToD((cAliasZA0)->ZA0_DTENTR)),(cAliasZA0)->ZA0_QTDE, 0})
		(cAliasZA0)->(DbSkip())
	End While

	// Carregar pedidos de vendas
	cSql := "SELECT C6_PRODUTO, C6_ENTREG, C6_QTDVEN, C6_NUM "
	cSql += "  FROM SC5010, SC6010, SF4010 "
	cSql += " WHERE C6_FILIAL           = '" + xFilial("SC6") + "'"
	cSql += "   AND C5_FILIAL           = '" + xFilial("SC5") + "'"
	cSql += "   AND F4_FILIAL           = '" + xFilial("SF4") + "'"
	cSql += "   AND C6_PRODUTO          = '" + cItem + "'"
	cSql += "   AND C5_NOTA             = '' "
	cSql += "   AND C5_LIBEROK          <> 'E' "
	cSql += "   AND C5_NUM              = C6_NUM "
	cSql += "   AND C6_QTDENT           <= C6_QTDVEN "
	cSql += "   AND SC6010.C6_BLQ       <> 'R' "
	cSql += "   AND F4_CODIGO           = C6_TES "
	cSql += "   AND F4_QTDZERO          <> '1' "
	cSql += "   AND SC5010.D_E_L_E_T_   <> '*' "
	cSql += "   AND SC6010.D_E_L_E_T_   <> '*' "
	cSql += "   AND SF4010.D_E_L_E_T_   <> '*' "
	cSql += " ORDER BY C6_ENTREG "
	cAliasSC6 := MPSysOpenQuery(cSql)


	While (cAliasSC6)->(!EOF())
		Aadd(aLinhas,{(cAliasSC6)->C6_ENTREG + "2", 2,"PV",	(cAliasSC6)->C6_NUM, ;
			DtoC(sToD((cAliasSC6)->C6_ENTREG)),     ;
			(cAliasSC6)->C6_QTDVEN, 0})
		(cAliasSC6)->(DbSkip())
	End While
return

Static Function	CalculaSaldos()
	Local nRow   := 0
	Local nSaldo := nSaldoIni

	For nRow := 1 to Len(aLinhas) Step 1

		if aLinhas[nRow][2] == 1
			nSaldo = nSaldo + aLinhas[nRow][6]
		else
			nSaldo = nSaldo - aLinhas[nRow][6]
		endif

		aLinhas[nRow][7] := nSaldo
	Next

return


Static Function fWBrowse1()
	Local nX := 0

	aSort(aLinhas, , , {|x, y| x[1] < y[1]})

	oDlg:= FwDialogModal():New()
	oDlg:SetEscClose(.T.)
	oDlg:SetTitle('FwDialogModal')

	oDlg:CreateDialog()
	oDlg:AddCloseButton(Nil, 'Fechar')

	@ 030, 075 SAY oSay1 PROMPT "DADOS ADICIONAIS PARA IMPORTAÇÃO " SIZE 108, 011 OF oDlg COLORS 0, 16777215 PIXEL

	oPnl:=oDlg:GetPanelMain()

	oFwBrowse := FWBrowse():New()
	oFwBrowse:SetDataArrayoBrowse()
	oFwBrowse:SetArray(aLinhas)
	aColumns := RetColumns()

	//Cria as colunas do array
	For nX := 1 To Len(aColumns )
		oFwBrowse:AddColumn( aColumns[nX] )
	Next

	oFwBrowse:SetOwner(oPnl)
	oFwBrowse:SetDescription( "Planejamento por Item" )
	oFwBrowse:Activate()

	// oSayModulo := TSay():New(004, 003, {|| cSayModulo}, , "", ,  , , , .T., RGB(149, 179, 215), , 200, 30, , , , , , .F., , )
	// oSayTitulo := TSay():New(004, 045, {|| cSayTitulo}, , "", ,  , , , .T., RGB(031, 073, 125), , 200, 30, , , , , , .F., , )
	// oSaySubTit := TSay():New(020, 020, {|| cSaySubTit}, , "", , , , , .T., RGB(031, 073, 125), , 300, 30, , , , , , .F., , )

	oDlg:Activate()
Return



Static Function RetColumns()
	Local aColumns := {}

	aAdd(aColumns, {"Data",   {|oBrw| aLinhas[oBrw:At(), 5] }, "D", "@!", 1, 10, 0, .F.})
	aAdd(aColumns, {"Tipo",   {|oBrw| aLinhas[oBrw:At(), 3] }, "C", "@!", 1,  5, 0, .F.})
	aAdd(aColumns, {"Numero", {|oBrw| aLinhas[oBrw:At(), 4] }, "C", "@!", 0,  6, 2, .F.})
	aAdd(aColumns, {"Qtde.",  {|oBrw| aLinhas[oBrw:At(), 6] }, "N", "@!", 0,  6, 2, .F.})
	aAdd(aColumns, {"Saldo",  {|oBrw| aLinhas[oBrw:At(), 7] }, "N", "@!", 0,  6, 2, .F.})
Return aColumns
