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

User Function PL060A(pItem)
	Private cItem 		:= pItem
	Private nSaldoIni 	:= 0
	Private nSaldoAtu 	:= 0

	Private oDlg       := Nil
	Private oFwBrowse  := Nil

	Private aLinhas    := {}
	Private aColumns   := {}

	dbSelectArea("SB1")
	SB1->(DBSetOrder(1))

	If ! SB1->(MsSeek(xFilial("SB1") + cItem))
		FWAlertWarning("ITEM NAO ENCONTRADO NO CADASTRO! ", "CADASTRO DE PRODUTOS")
		return
	EndIf

	dbSelectArea("SB2")
	SB2->(DBSetOrder(1))

	If SB2->(MsSeek(xFilial("SB2") + SB1->B1_COD + SB1->B1_LOCPAD))
		nSaldoIni := SB2->B2_QATU
	else
		nSaldoIni := 0
	EndIf

	ObterPedidos()
	ObterProducao()
	ObterCompras()

	if len(aLinhas) == 0
		FWAlertWarning("NAO EXISTEM DADOS PARA MOSTRAR! ", "PLANO DO ITEM")
		return .F.
	endif

	CalculaSaldos()

	fMontaTela()
Return .T.


Static Function ObterCompras()
	Local cSql
	Local cAlias

	cSql := "SELECT C1_NUM, C1_ITEM, C1_PRODUTO, C1_QUANT, C1_DATPRF "
	cSql += " FROM " +	RetSQLName("SC1") + " SC1 "
	cSql += "WHERE C1_FILIAL  = '" + xFilial("SC1") + "' "
	cSql += "  AND C1_PRODUTO = '" + cItem + "'"
	cSql += "  AND SC1.D_E_L_E_T_ = ' ' "
	cSql += "ORDER BY C1_DATPRF "

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
	Local bTrata

	cSql := "SELECT C2_NUM, C2_ITEM, C2_SEQUEN, C2_PRODUTO, C2_DATRF, "
	cSql += "	C2_QUANT, C2_DATPRI, C2_DATPRF, C2_QUJE, C2_TPOP"
	cSql += " FROM " +	RetSQLName("SC2") + " SC2 "
	cSql += "WHERE C2_FILIAL    = '" + xFilial("SC2") + "' "
	cSql += "  AND C2_PRODUTO   = '" + cItem + "'"
	cSql += "  AND C2_QUANT     > C2_QUJE "
	cSql += "  AND SC2.D_E_L_E_T_ = ' ' "
	cSql += "ORDER BY C2_DATPRF "
	cAliasOrd := MPSysOpenQuery(cSql)

	While (cAliasOrd)->(!EOF())
		bTrata := .T.

		if (cAliasOrd)->C2_TPOP == "F" .And. !Empty((cAliasOrd)->C2_DATRF) .And. (cAliasOrd)->(C2_QUJE >= C2_QUANT) //Enc.Totalmente
			bTrata := .F.
		endif

		if (cAliasOrd)->C2_TPOP == "F" .And. !Empty((cAliasOrd)->C2_DATRF) .And. (cAliasOrd)->(C2_QUJE < C2_QUANT) //Enc.Parcialmente
			bTrata := .F.
		endif

		if bTrata == .T.
			Aadd(aLinhas,{(cAliasOrd)->C2_DATPRF + "1", 1, "OP", ;
				(cAliasOrd)->C2_NUM + (cAliasOrd)->C2_ITEM + (cAliasOrd)->C2_SEQUEN, ;
				DtoC(sToD((cAliasOrd)->C2_DATPRF)),(cAliasOrd)->C2_QUANT - (cAliasOrd)->C2_QUJE, 0})
		endif

		(cAliasOrd)->(DbSkip())
	enddo

return

Static Function ObterPedidos()
	Local cSql := ""

	// Carregar pedidos EDI
	cSql := "SELECT ZA0_DTENTR, ZA0_PRODUT, ZA0_QTDE, ZA0_NUMPED, ZA0_QTDE - ZA0_QTCONF AS ZA0_SALDO "
	cSql += "  FROM ZA0010 "
	cSql += " WHERE ZA0_STATUS          = '0' "
	cSql += "   AND ZA0_FILIAL          = '" + xFilial("ZA0") + "'"
	cSql += "   AND ZA0_PRODUT          = '" + cItem +  "'"
	cSql += "   AND ZA0_QTCONF          < ZA0_QTDE "
	cSql += "   AND ZA0010.D_E_L_E_T_  <> '*' "
	cSql += " ORDER BY ZA0_DTENTR "
	cAliasZA0 := MPSysOpenQuery(cSql)

	While (cAliasZA0)->(!EOF())
		Aadd(aLinhas,{(cAliasZA0)->ZA0_DTENTR + "2", 2, "EDI", ;
			(cAliasZA0)->ZA0_NUMPED, ;
			DtoC(sToD((cAliasZA0)->ZA0_DTENTR)),(cAliasZA0)->ZA0_SALDO, 0})
		(cAliasZA0)->(DbSkip())
	End While

	// Carregar pedidos de vendas
	cSql := "SELECT C6_PRODUTO, C6_ENTREG, C6_QTDVEN, C6_QTDENT, C6_QTDVEN - C6_QTDENT AS C6_SALDO, C6_NUM "
	cSql += "  FROM SC5010, SC6010, SF4010 "
	cSql += " WHERE C6_FILIAL           = '" + xFilial("SC6") + "'"
	cSql += "   AND C5_FILIAL           = '" + xFilial("SC5") + "'"
	cSql += "   AND F4_FILIAL           = '" + xFilial("SF4") + "'"
	cSql += "   AND C6_PRODUTO          = '" + cItem + "'"
	cSql += "   AND C5_NOTA             = '' "
	cSql += "   AND C5_LIBEROK          <> 'E' "
	cSql += "   AND C5_NUM              =  C6_NUM "
	cSql += "   AND C6_QTDENT           <  C6_QTDVEN "
	cSql += "   AND C6_BLQ       		<> 'R' "
	cSql += "   AND F4_CODIGO           =  C6_TES "
	cSql += "   AND F4_QTDZERO          <> '1' "
	cSql += "   AND SC5010.D_E_L_E_T_   <> '*' "
	cSql += "   AND SC6010.D_E_L_E_T_   <> '*' "
	cSql += "   AND SF4010.D_E_L_E_T_   <> '*' "
	cSql += " ORDER BY C6_ENTREG "
	cAliasSC6 := MPSysOpenQuery(cSql)

	While (cAliasSC6)->(!EOF())
		Aadd(aLinhas,{(cAliasSC6)->C6_ENTREG + "2", 2,"PV",	(cAliasSC6)->C6_NUM, ;
			DtoC(sToD((cAliasSC6)->C6_ENTREG)),     ;
			(cAliasSC6)->C6_SALDO, 0})
		(cAliasSC6)->(DbSkip())
	End While
return

Static Function	CalculaSaldos()
	Local nRow   := 0
	Local nSaldo := nSaldoIni

	aSort(aLinhas, , , {|x, y| x[1] < y[1]})

	For nRow := 1 to Len(aLinhas) Step 1

		if aLinhas[nRow][2] == 1
			nSaldo = nSaldo + aLinhas[nRow][6]
		else
			nSaldo = nSaldo - aLinhas[nRow][6]
		endif

		aLinhas[nRow][7] := nSaldo
	Next

return


Static Function fMontaTela()
	Local nLargBtn := 50
	Local nX := 0

	//Objetos e componentes
	Private oDlg
	Private oFwLayer
	Private oPanTitulo
	Private oPanGrid

	//Tamanho da janela
	Private aSize := MsAdvSize(.T.)
	Private nJanLarg := aSize[5] * 0.3
	Private nJanAltu := aSize[6] * 0.8

	//Fontes
	Private cFontUti    := "Tahoma"
	Private oFontSub    := TFont():New(cFontUti, , -16)
	Private oFontBtn    := TFont():New(cFontUti, , -14)

	//Cria a janela
	DEFINE MSDIALOG oDlg TITLE "Planejamento por Item"  FROM 0, 0 TO  nJanAltu, nJanLarg PIXEL

	oFwLayer := FwLayer():New()
	oFwLayer:init(oDlg,.F.)

	//Cabeçalho da tela
	oFWLayer:addLine("TIT",  8, .F.)
	oFWLayer:addLine("DAD", 10, .F.)
	oFWLayer:addLine("GRD", 77, .F.)

	oFWLayer:addCollumn("HEADERTEXT", 075, .T., "TIT")
	oFWLayer:addCollumn("BTNSAIR"   , 025, .T., "TIT")
	oFWLayer:addCollumn("DADOS"     , 90,  .T., "DAD")

	oPanHeader := oFWLayer:GetColPanel("HEADERTEXT" , "TIT")
	oPanSair   := oFWLayer:GetColPanel("BTNSAIR"    , "TIT")
	oPanDados  := oFWLayer:GetColPanel("DADOS"      , "DAD")

	oFWLayer:addCollumn("COLGRID1",  5, .T., "GRD")     // margem esquerda
	oFWLayer:addCollumn("COLGRID2", 90, .T., "GRD")     // browse

	oPanGrid   := oFWLayer:GetColPanel("COLGRID1", "GRD")
	oPanGrid   := oFWLayer:GetColPanel("COLGRID2", "GRD")

	oSayTitulo := TSay():New(004, 005, {|| "Planejamento por item"}, ;
		oPanHeader, "", oFontSub,  , , , .T., RGB(031, 073, 125), , 200, 30, , , , , , .F., , )

	oSayDados  := TSay():New(004, 010, {|| "Codigo do Item: " + cItem}, ;
		oPanDados, "", oFontSub,  , , , .T., RGB(031, 073, 125), , 200, 30, , , , , , .F., , )

	oSayDados2 := TSay():New(020, 010, {|| "Saldo inicial:  " + cValToChar(nSaldoIni)}, ;
		oPanDados, "", oFontSub,  , , , .T., RGB(031, 073, 125), , 200, 30, , , , , , .F., , )

	//Criando os botões
	oBtnSair := TButton():New(006, 001, "Fechar", oPanSair, {|| oDlg:End()}, nLargBtn, 018, , oFontBtn, , .T., , , , , , )

	// GRID
	oFwBrowse := FWBrowse():New()
	oFwBrowse:SetDataArrayoBrowse()
	oFwBrowse:SetArray(aLinhas)
	aColumns := RetColumns()

	//Cria as colunas do array
	For nX := 1 To Len(aColumns )
		oFwBrowse:AddColumn( aColumns[nX] )
	Next

	oFwBrowse:SetOwner(oPanGrid)
	oFwBrowse:Activate()

	Activate MsDialog oDlg Centered
Return


Static Function RetColumns()
	Local aColumns := {}
	aAdd(aColumns, {"Data",   {|oBrw| aLinhas[oBrw:At(), 5] }, "D", "@!", 1,  8, 0, .F.})
	aAdd(aColumns, {"Tipo",   {|oBrw| aLinhas[oBrw:At(), 3] }, "C", "@!", 1,  4, 0, .F.})
	aAdd(aColumns, {"Numero", {|oBrw| aLinhas[oBrw:At(), 4] }, "C", "@!", 0,  5, 2, .F.})
	aAdd(aColumns, {"Qtde.",  {|oBrw| aLinhas[oBrw:At(), 6] }, "N", "@!", 0,  4, 2, .F.})
	aAdd(aColumns, {"Saldo",  {|oBrw| aLinhas[oBrw:At(), 7] }, "N", "@!", 0,  4, 2, .F.})
Return aColumns

