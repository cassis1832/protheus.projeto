#Include "PROTHEUS.CH"
#Include "RPTDEF.CH"
#Include "TBICONN.CH"
#Include "FWPrintSetup.ch"
#Include "Colors.ch"

/*/{Protheus.doc}	PL130A
	Impressao do Picking List de Produção
	@author Carlos Assis
	@since 23/07/2024
	@version 1.0   
/*/

Static oFont09 	:= TFont():New( "Arial",, -09, .T.)
Static oFont10 	:= TFont():New( "Arial",, -10, .T.)
Static oFont11 	:= TFont():New( "Arial",, -11, .T.)
Static oFont11b := TFont():New( "Arial",, -11, .T.,.T.)
Static oFont12 	:= TFont():New( "Arial",, -12, .T.)
Static oFont12b := TFont():New( "Arial",, -12, .T.,.T.)
Static oFont16b := TFont():New( "Arial",, -16, .T.,.T.)

User Function PL130A(aDados)
	Local nRow			:= 0

	Private oPrinter    := nil
	Private nLin 	    := 0
	Private cDir        := "c:\temp\"
	Private cFilePrint  := "PL130A_" + DToS(Date()) + StrTran(Time(),":","") + ".pdf"

	Private cOpAnt	    := ""

	oPrinter := FWMSPrinter():New(cFilePrint,	IMP_PDF,.F.,cDir,.T.,,,,.T.,.F.,,.T.)
	oFont1 := TFont():New('Courier new',,-18,.T.)
	oPrinter:SetParm( "-RFS")
	oPrinter:cPathPDF := cDir
	oPrinter:SetPortrait()
	oPrinter:SetPaperSize(DMPAPER_A4)
	oPrinter:SetMargin(40,40,40,40)

	For nRow := 1 to Len(aDados) Step 1
		if aDados[nRow][1] == .T.
			TrataOP(aDados[nRow])
		endif
	Next

	oPrinter:EndPage()
	oPrinter:Preview()
	FreeObj(oPrinter)
	oPrinter := nil
	Sleep(1000)
return


Static Function TrataOP(aLin)
	Local cSql			:= ""
	Local cTexto		:= ""

	Private cAliasOrd	:= ""
	Private cAliasCmp	:= ""
	Private cAliasOper  := ""

	// Ler a OP e item
	cSql := "SELECT C2_NUM, C2_ITEM, C2_SEQUEN, C2_PRODUTO, C2_QUANT, C2_ROTEIRO, "
	cSql += "	 	CAST(C2_DATPRI AS DATE) C2_DATPRI, C2_PRIOR, C2_XPRTPL, "
	cSql += "	  	B1_COD, B1_DESC, B1_UM, B1_XCLIENT, B1_XPROJ "
	cSql += "  FROM " + RetSQLName("SC2") + " SC2 "

	cSql += " INNER JOIN " + RetSQLName("SB1") + " SB1 "
	cSql += "	 ON B1_COD 		 	=  C2_PRODUTO"

	cSql += " WHERE C2_NUM 			= '" + aLin[2] + "'"
	cSql += "   AND C2_ITEM			= '" + aLin[3] + "'"
	cSql += "   AND C2_SEQUEN 		= '" + aLin[4] + "'"
	cSql += "   AND C2_TPOP 	 	<> 'P'"

	cSql += "   AND C2_FILIAL 	 	=  '" + xFilial("SC2") + "' "
	cSql += "   AND B1_FILIAL 	 	=  '" + xFilial("SB1") + "' "
	cSql += "	AND SC2.D_E_L_E_T_ 	=  ' ' "
	cSql += "	AND SB1.D_E_L_E_T_ 	=  ' ' "
	cSql += "	ORDER BY C2_NUM, C2_ITEM, C2_SEQUEN "
	cAliasOrd := MPSysOpenQuery(cSql)

	if (cAliasOrd)->(EOF())
		FWAlertError("ORDEM DE PRODUCAO " + aLin[2] + aLin[3] + aLin[4] + " NAO ENCONTRADA!", "ERRO")
		return
	endif

	// Ler as operacões do item - mas só pega a primeira
	cSql := "SELECT G2_OPERAC, G2_RECURSO, G2_FERRAM, G2_DESCRI "
	cSql += "  FROM " + RetSQLName("SG2") + " SG2 "

	cSql += " WHERE G2_CODIGO  	 	= '" + (cAliasOrd)->C2_ROTEIRO + "' "
	cSql += "   AND G2_PRODUTO 	 	= '" + (cAliasOrd)->B1_COD + "' "
	cSql += "   AND G2_FILIAL  	 	= '" + xFilial("SG2") + "' "
	cSql += "   AND SG2.D_E_L_E_T_ 	= ' ' "
	cSql += " ORDER BY G2_OPERAC"
	cAliasOper := MPSysOpenQuery(cSql)

	// Ler os empenhos da OP
	cSql := "SELECT D4_OP, D4_QUANT, D4_LOTECTL, B1_COD, B1_DESC, B1_UM "
	cSql += "  FROM " + RetSQLName("SD4") + " SD4 "

	cSql += " INNER JOIN " + RetSQLName("SB1") + " SB1 "
	cSql += "	 ON B1_COD 			= D4_COD "
	cSql += "   AND B1_TIPO 	   <> 'SV'"
	cSql += "   AND B1_FILIAL 	 	= '" + xFilial("SB1") + "' "
	cSql += "   AND SB1.D_E_L_E_T_ 	= ' ' "

	cSql += " WHERE D4_OP 		 	= '" + aLin[2] + aLin[3] + aLin[4] + "' "
	cSql += "   AND D4_FILIAL 	 	= '" + xFilial("SD4") + "' "
	cSql += "   AND SD4.D_E_L_E_T_ 	= ' ' "
	cSql += " ORDER BY D4_COD, D4_LOTECTL"
	cAliasCmp := MPSysOpenQuery(cSql)

	While (cAliasCmp)->(!EOF())

		if (cAliasCmp)->D4_OP <> cOpAnt
			cOpAnt := (cAliasCmp)->D4_OP
			printCabec(aLin)
			printOP()
		endif

		if nLin > 800
			printCabec(aLin)
		endif

		nLin +=16
		oPrinter:Say(nLin, 15, (cAliasCmp)->B1_COD, oFont12b)
		oPrinter:Say(nLin, 80, (cAliasCmp)->B1_DESC, oFont12b)
		nLin +=20
		cTexto := "Quantidade " + TRANSFORM((cAliasCmp)->D4_QUANT, "@E 999,999.999") + " " + (cAliasCmp)->B1_UM
		cTexto += "    Lote " + (cAliasCmp)->D4_LOTECTL
		oPrinter:Say(nLin, 260, cTexto, oFont12)

		(cAliasCmp)->(DbSkip())
	EndDo

	// Atualiza print pick da ordem
	SC2->(dbSetOrder(1))

	If SC2->(MsSeek(xFilial("SC2") + (cAliasOrd)->C2_NUM + (cAliasOrd)->C2_ITEM + (cAliasOrd)->C2_SEQUEN))
		RecLock("SC2", .F.)
		SC2->C2_XPRTPL := "S"
		MsUnLock()
	endif

Return


Static Function printOP()
	nLin +=10
	oPrinter:Line(nLin+10, 15, nLin+10, 550)
	oPrinter:Say(nLin+25, 225, "Material Necessario",oFont12b)
	oPrinter:Line(nLin+30, 15, nLin+30, 550)

	nLin +=45
	oPrinter:Say(nLin, 15, "Cod. Item",oFont09)
	oPrinter:Say(nLin, 80, "Descricao",oFont09)
return


//-----------------------------------------------------------------------------
//	Imprime o cabecalho 
//-----------------------------------------------------------------------------
Static Function printCabec(aLin)

	oPrinter:StartPage()
	oPrinter:Box(20,15,60,550)

	nLin := 40
	oPrinter:SayBitmap(nLin-15, 20, "\images\logo.png", 130, 30)
	oPrinter:Say(nLin+3, 170,"RELATORIO DE SEPARACAO",oFont16b)

	oPrinter:Line(nLin-20, 440, 60, 440)
	oPrinter:Say(nLin-10, 500,"Data",oFont10)
	oPrinter:Say(nLin-5 + 17, 460, DTOC(Date()), oFont12b)

	nLin +=45
	oPrinter:Say(nLin, 15, "Maquina:" ,oFont10)
	oPrinter:Say(nLin, 75, (cAliasOper)->G2_RECURSO, oFont12b)

	nLin +=25
	oPrinter:Say(nLin, 15, "Ordem:",oFont10)
	oPrinter:Say(nLin, 75, aLin[2] + aLin[3] + aLin[4], oFont12b)

	nLin +=25
	oPrinter:Say(nLin, 15, "Data Inicio:",oFont10)
	oPrinter:Say(nLin, 75, DTOC((cAliasOrd)->C2_DATPRI), oFont11b)
	oPrinter:Say(nLin, 400, "Quantidade:",oFont10)

	if (cAliasOrd)->C2_QUANT - int((cAliasOrd)->C2_QUANT) == 0
		oPrinter:Say(nLin, 450, TRANSFORM((cAliasOrd)->C2_QUANT, "@E 999,999") + " " + (cAliasOrd)->B1_UM, oFont12b)
	else
		oPrinter:Say(nLin, 450, TRANSFORM((cAliasOrd)->C2_QUANT, "@E 999,999.999") + " " + (cAliasOrd)->B1_UM, oFont12b)
	endif

	nLin +=30
	oPrinter:Say(nLin, 15, "Cliente:",oFont10)
	oPrinter:Say(nLin, 75, (cAliasOrd)->B1_XCLIENT, oFont10)
	oPrinter:Say(nLin, 220, "Projeto:",oFont10)
	oPrinter:Say(nLin, 270,(cAliasOrd)->B1_XPROJ, oFont10)
Return
