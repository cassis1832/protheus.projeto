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

User Function PL060old()

	Private cAliasTT
	Private cTableName
	Private oTempTable

	Private cItem := "10614010"

	Private nSaldoIni := 0
	Private nSaldoAtu := 0

	Private oDlg       := Nil
	Private oFwBrowse  := Nil
	Private aColumns   := {}

	oTempTable := FWTemporaryTable():New("TT")

	aFields := {}
	aAdd(aFields, {"ID",      "C", 36, 0})
	aAdd(aFields, {"TT_TPMOV","N",  1, 0})
	aAdd(aFields, {"TT_TIPO", "C", 15, 0})
	aAdd(aFields, {"TT_DOC",  "C", 10, 0})
	aAdd(aFields, {"TT_DATA", "C", 10, 0})
	aAdd(aFields, {"TT_QUANT","N",  8, 2})
	aAdd(aFields, {"TT_QTFIM","N",  8, 2})

	oTempTable:SetFields( aFields )
	oTempTable:AddIndex("1", {"ID"} )
	oTempTable:AddIndex("2", {"TT_DATA", "TT_TPMOV"} )
	oTempTable:Create()

	cAliasTT    := oTempTable:GetAlias()
	cTableName  := oTempTable:GetRealName()

	LerItem()
	ObterPedidos()
	//ObterProducao()
	//ObterCompras()

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
		(cAliasTT)->(DBAppend())
		(cAliasTT)->ID          := FWUUIDv4()
		(cAliasTT)->TT_TPMOV    := 2
		(cAliasTT)->TT_TIPO     := "EDI"
		(cAliasTT)->TT_DOC      := (cAliasZA0)->ZA0_NUMPED
		(cAliasTT)->TT_DATA     := (cAliasZA0)->ZA0_DTENTR
		(cAliasTT)->TT_QUANT    := (cAliasZA0)->ZA0_QTDE
		(cAliasTT)->(DBCommit())
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
		(cAliasTT)->(DBAppend())
		(cAliasTT)->ID          := FWUUIDv4()
		(cAliasTT)->TT_TPMOV    := 2
		(cAliasTT)->TT_TIPO     := "PV"
		(cAliasTT)->TT_DOC      := (cAliasSC6)->C6_NUM
		(cAliasTT)->TT_DATA     := (cAliasSC6)->C6_ENTREG
		(cAliasTT)->TT_QUANT    := (cAliasSC6)->C6_QTDVEN
		(cAliasTT)->(DBCommit())
		(cAliasSC6)->(DbSkip())
	End While
return

Static Function	CalculaSaldos()
	Local nSaldo := nSaldoIni

	(cAliasTT)->(DBSetOrder(2))
	(cAliasTT)->(DBGoTop())

	while !(cAliasTT)->(Eof())

		if (cAliasTT)->TT_TPMOV == 1
			nSaldo = nSaldo + (cAliasTT)->TT_QUANT
		else
			nSaldo = nSaldo - (cAliasTT)->TT_QUANT
		endif

		RecLock("TT", .F.)
		(cAliasTT)->TT_QTFIM := nSaldo
		(cAliasTT)->(MsUnlock())

		(cAliasTT)->(DBSkip())
	end while

return


Static Function fWBrowse1()
	oDlg:= FwDialogModal():New()
	oDlg:SetEscClose(.T.)
	oDlg:SetTitle('FwDialogModal')

	//Seta a largura e altura da janela em pixel
	oDlg:SetPos(000, 000)
	oDlg:SetSize(400, 700)

	oDlg:CreateDialog()
	oDlg:AddCloseButton(Nil, 'Fechar')
	oPnl:=oDlg:GetPanelMain()

	oFwBrowse := FWBrowse():New()
	oFwBrowse :SetDataTable(.T.)
	oFwBrowse :SetAlias( "TT" )

	oFwBrowse:SetOwner(oPnl)
	oFwBrowse:SetDescription( "Planejamento por Item" )

// Adiciona as colunas do Browse
	oColumn := FWBrwColumn():New()
	oColumn:SetData({||TT_TIPO})
	oColumn:SetTitle("Tipo")
	oColumn:SetSize(10)
	oFwBrowse:SetColumns({oColumn})

	oColumn := FWBrwColumn():New()
	oColumn:SetData({||TT_DATA})
	oColumn:SetTitle("Data")
	oColumn:SetSize(10)
	oFwBrowse:SetColumns({oColumn})

	oColumn := FWBrwColumn():New()
	oColumn:SetData({||TT_DOC})
	oColumn:SetTitle(DecodeUTF8("Número"))
	oColumn:SetSize(15)
	oFwBrowse:SetColumns({oColumn})

	oColumn := FWBrwColumn():New()
	oColumn:SetData({||TT_QUANT})
	oColumn:SetTitle("Qtde.")
	oColumn:SetSize(10)
	oFwBrowse:SetColumns({oColumn})

	oColumn := FWBrwColumn():New()
	oColumn:SetData({||TT_QTFIM})
	oColumn:SetTitle("Saldo")
	oColumn:SetSize(10)
	oFwBrowse:SetColumns({oColumn})

	oFwBrowse:Activate()
	oDlg:Activate()
Return

