#Include "PROTHEUS.CH"
#Include "RPTDEF.CH"
#Include "TBICONN.CH"
#Include "FWPrintSetup.ch"
#Include "Colors.ch"

/*/{Protheus.doc}	PL010
	
	Ordem de Produção Modelo MR V01
	-------------------------------
@author Carlos ASsis
@since 04/11/2023
@version 1.0   
/*/

Static oFont09 		:= TFont():New( "Arial",, -09, .T.)
Static oFont10 		:= TFont():New( "Arial",, -10, .T.)
Static oFont11 		:= TFont():New( "Arial",, -11, .T.)
Static oFont11b 	:= TFont():New( "Arial",, -11, .T.,.T.)
Static oFont12 		:= TFont():New( "Arial",, -12, .T.)
Static oFont12b 	:= TFont():New( "Arial",, -12, .T.,.T.)
Static oFont16b 	:= TFont():New( "Arial",, -16, .T.,.T.)

Static cQuery 		:= ""
Static lOper 		:= .T.
Static lComp		:= .F.
Static cAliasOrd 	:= ""
Static cAliasCmp	:= ""
Static cAliasOper   := ""

Static nLin 		:= 0
Static oPrinter		:= nil

User Function PL010()
	Local aPergs	:= {}
	Local aResps	:= {}
	Local cOrdemDe	:= 0
	Local cOrdemAte	:= 0
	Local lContinua	:= .T.

	//
	Local lPar01 		:= ""
	Local cPar02 		:= ""
	Local dPar03 		:= CTOD(' / / ')

	Prepare Environment Empresa '01' Filial '01'
	lPar01 := SuperGetMV("MV_PARAM",.F.)
	cPar02 := cFilAnt
	dPar03 := dDataBase
	//

	AAdd(aPergs, {1, "Ordem Inicial"	, CriaVar("C2_NUM",.F.),,,"SC2",, 50, .F.})
	AAdd(aPergs, {1, "Ordem Final"    	, CriaVar("C2_NUM",.F.),,,"SC2",, 50, .F.})
	AAdd(aPergs ,{4,"Operações"    		,.T.,"Todas as operações juntas" ,90,"",.F.})

	If ParamBox(aPergs, "Parâmetros do relatório", @aResps,,,,,,,, .T., .T.)
		cOrdemDe	:= aResps[1]
		cOrdemAte	:= aResps[2]
		lOper		:= aResps[3]
	Else
		lContinua := .F.
	EndIf

	If lContinua = .F.
		return
	endif

	// LER OP E ITEM
	cQuery := "SELECT C2_NUM, C2_ITEM, C2_SEQUEN, C2_PRODUTO, " + CRLF
	cQuery += "	 C2_QUANT, CAST(C2_DATPRI AS DATE) C2_DATPRI, "	+ CRLF
	cQuery += "	 CAST(C2_DATPRF AS DATE) C2_DATPRF, " 			+ CRLF
	cQuery += "	 B1_COD, B1_DESC, B1_UM, B1_XCLIENT, B1_XPROJ " + CRLF
	cQuery += "FROM " +	RetSQLName("SC2") + " SC2 " 			+ CRLF
	cQuery += "INNER JOIN " + RetSQLName("SB1") + " SB1 " 		+ CRLF
	cQuery += "		ON C2_PRODUTO = B1_COD " 					+ CRLF
	cQuery += "WHERE C2_FILIAL = '" + xFilial("SC5") + "' " 	+ CRLF
	cQuery += "	 AND SC2.D_E_L_E_T_ = ' ' " 					+ CRLF
	cQuery += "	 AND SB1.D_E_L_E_T_ = ' ' " 					+ CRLF

	If !Empty(cOrdemDe) .And. Empty(cOrdemAte)
		cQuery += "  AND C2_NUM >= '" + cOrdemDe + "' " 		+ CRLF
		cQuery += "  AND C2_NUM <= '" + cOrdemDe + "' " 		+ CRLF
	endif

	If Empty(cOrdemDe) .And. !Empty(cOrdemAte)
		cQuery += "  AND C2_NUM >= '" + cOrdemAte + "' " 		+ CRLF
		cQuery += "  AND C2_NUM <= '" + cOrdemAte + "' " 		+ CRLF
	endif

	If !Empty(cOrdemDe) .And. !Empty(cOrdemAte)
		cQuery += "  AND C2_NUM >= '" + cOrdemDe  + "' " 		+ CRLF
		cQuery += "  AND C2_NUM <= '" + cOrdemAte + "' " 		+ CRLF
	EndIf

	If Empty(cOrdemDe) .And. Empty(cOrdemAte)
		cQuery += "  AND C2_NUM >= '0' " 						+ CRLF
		cQuery += "  AND C2_NUM <= '0' " 						+ CRLF
	EndIf

	cAliasOrd := MPSysOpenQuery(cQuery)

	obterDados()

	lComp = .F.

	While (cAliasOrd)->(!EOF())

		// Imprime todas as operações da ordem na mesma página
		if lOper
			printCabec	()
			printCompon	()
			printOper	()
			printApont	()
			printParada ()
		else
			While (cAliasOper)->(!EOF())
				printCabec	()
				printCompon	()
				printOper	()
				printApont	()
				printParada ()
				(cAliasOper)->(DbSkip())
			enddo
		endif

		(cAliasOrd)->(DbSkip())
	EndDo

return

//-----------------------------------------------------------------------------
//	Ler a estrutura e as operações do item
//-----------------------------------------------------------------------------
Static Function obterDados()
	Local cOp := (cAliasOrd)->C2_NUM + (cAliasOrd)->C2_ITEM + (cAliasOrd)->C2_SEQUEN

	// LER COMPONENTES DA OP
	cQuery := "SELECT D4_COD, D4_OP, D4_DATA, D4_QTDEORI, " 		+ CRLF
	cQuery += "	 D4_QUANT, D4_LOTECTL, "							+ CRLF
	cQuery += "	 B1_COD, B1_DESC, B1_UM " 							+ CRLF
	cQuery += "FROM " + RetSQLName("SD4") + " SD4 " 				+ CRLF
	cQuery += "INNER JOIN " + RetSQLName("SB1") + " SB1 " 			+ CRLF
	cQuery += "		ON D4_COD = B1_COD " 							+ CRLF
	cQuery += "WHERE SD4.D_E_L_E_T_ = ' ' " 						+ CRLF
	cQuery += "	 AND SB1.D_E_L_E_T_ = ' ' " 						+ CRLF
	cQuery += "  AND D4_FILIAL = '" + xFilial("SC5") + "' " 		+ CRLF
	cQuery += "  AND D4_OP = '" + cOp + "' " 						+ CRLF
	cAliasCmp := MPSysOpenQuery(cQuery)

	// LER OPERACOES DA OP
	cQuery := "SELECT G2_OPERAC, G2_RECURSO, G2_FERRAM, " 			+ CRLF
	cQuery += "	G2_DESCRI, G2_MAOOBRA, G2_SETUP, "					+ CRLF
	cQuery += "	G2_LOTEPAD, G2_TEMPAD, G2_CTRAB, "					+ CRLF
	cQuery += "	G2_TEMPEND "										+ CRLF
	cQuery += "FROM " + RetSQLName("SG2") + " SG2 " 				+ CRLF
	cQuery += "WHERE SG2.D_E_L_E_T_ = ' ' " 						+ CRLF
	cQuery += "  AND G2_FILIAL = '" + xFilial("SC5") + "' " 		+ CRLF
	cQuery += "  AND G2_PRODUTO = '" + (cAliasOrd)->B1_COD + "' " 	+ CRLF
	cAliasOper := MPSysOpenQuery(cQuery)
return


//-----------------------------------------------------------------------------
//	Imprime o cabeçalho da OP
//-----------------------------------------------------------------------------
Static Function printCabec()
	Local cFilePrintert		:= "OP" + cValToChar((cAliasOrd)->C2_NUM) + cValToChar((cAliasOrd)->C2_ITEM) + cValToChar((cAliasOrd)->C2_SEQUEN) + DToS(Date()) + StrTran(Time(),":","") + ".pdf"
	Local cDir				:= "c:\temp\"	// Local do relatório

	oPrinter := FWMSPrinter():New(cFilePrintert,IMP_PDF,.F.,cDir,.T.,,,,.T.,.F.,,.T.)
	oFont1 := TFont():New('Courier new',,-18,.T.)
	oPrinter:SetParm( "-RFS")
	oPrinter:cPathPDF := cDir 			// Se for usado PDF e fora de rotina agendada

	oPrinter:SetPortrait()
	oPrinter:SetPaperSize(DMPAPER_A4)
	oPrinter:SetMargin(40,40,40,40) // nEsquerda, nSuperior, nDireita, nInferior

	oPrinter:StartPage()

	oPrinter:Box(20,15,60,550)		    // Box(row, col, bottom, right)

	nLin := 40
	oPrinter:SayBitmap(nLin-15, 20, "\images\logo.png", 130, 30)
	oPrinter:Say(nLin+3, 190,"ORDEM DE PRODUÇÃO",oFont16b)

	oPrinter:Line(nLin-20, 400, 60, 400)
	oPrinter:Say(nLin-10, 430,"Num. Ordem",oFont10)
	oPrinter:Say(nLin-5 + 17, 410, cValToChar((cAliasOrd)->C2_NUM) + "/" + cValToChar((cAliasOrd)->C2_ITEM) + "/" + cValToChar((cAliasOrd)->C2_SEQUEN), oFont16b)

	nLin +=35
	oPrinter:Say(nLin, 15, "Cod. Item:" ,oFont10)
	oPrinter:Say(nLin, 80, (cAliasOrd)->B1_COD, oFont12b)
	oPrinter:Say(nLin, 160, "Descricao:",oFont10)
	oPrinter:Say(nLin, 220, (cAliasOrd)->B1_DESC, oFont12)

	nLin +=20
	oPrinter:Say(nLin, 15, "Data Inicio:",oFont10)
	oPrinter:Say(nLin, 80, DTOC((cAliasOrd)->C2_DATPRI), oFont11)
	oPrinter:Say(nLin, 160, "Data Termino:",oFont10)
	oPrinter:Say(nLin, 240, DTOC((cAliasOrd)->C2_DATPRF), oFont11)
	oPrinter:Say(nLin, 400, "Quantidade:",oFont10)
	oPrinter:Say(nLin, 450, TRANSFORM((cAliasOrd)->C2_QUANT, "@E 999,999.999") + " " + (cAliasOrd)->B1_UM, oFont11b)

	nLin +=20
	oPrinter:Say(nLin, 15, "Cliente:",oFont10)
	oPrinter:Say(nLin, 80, (cAliasOrd)->B1_XCLIENT, oFont11)
	oPrinter:Say(nLin, 160, "Projeto:",oFont10)
	oPrinter:Say(nLin, 240,(cAliasOrd)->B1_XPROJ, oFont11)

Return

//-----------------------------------------------------------------------------
//	Imprime os componentes da OP (estrutura)
//-----------------------------------------------------------------------------
Static Function printCompon()

	if lOper = .F. 						// Uma operação por pagina
		if lComp = .T.					// Já imprimiu a primeira operação, não imprime os componentes de novo
			return
		else
			lComp = .T.
		endif
	endif

	oPrinter:Line(nLin+10, 15, nLin+10, 550)
	oPrinter:Say(nLin+25, 225, "Material Necessário",oFont12b)
	oPrinter:Line(nLin+30, 15, nLin+30, 550)

	nLin +=45
	oPrinter:Say(nLin, 15, "Cod. Item",oFont09)
	oPrinter:Say(nLin, 70, "Descricao",oFont09)
	oPrinter:Say(nLin, 320, "Quantidade",oFont09)
	oPrinter:Say(nLin, 420, "Lote",oFont09)
	oPrinter:Say(nLin, 500, "Lote Real",oFont09)

	While (cAliasCmp)->(!EOF())
		nLin +=16
		oPrinter:Say(nLin, 15, (cAliasCmp)->B1_COD, oFont10)
		oPrinter:Say(nLin, 70, SUBSTR((cAliasCmp)->B1_DESC, 1, 45), oFont10)

		oPrinter:Say(nLin, 310, TRANSFORM((cAliasCmp)->D4_QTDEORI, "@E 999,999.999") + " " + (cAliasCmp)->B1_UM,oFont10)
		oPrinter:Say(nLin, 420, (cAliasCmp)->D4_LOTECTL,oFont10)
		(cAliasCmp)->(DbSkip())
	EndDo

Return

//-----------------------------------------------------------------------------
//	Imprime as operações da OP
//-----------------------------------------------------------------------------
Static Function printOper()

	oPrinter:Line(nLin+10, 15, nLin+10, 550)
	oPrinter:Say(nLin+25, 250, "Operacoes",oFont12b)
	oPrinter:Line(nLin+30, 15, nLin+30, 550)

	nLin +=45
	oPrinter:Say(nLin, 15, "Oper.",oFont09)
	oPrinter:Say(nLin, 60, "Descricao",oFont09)
	oPrinter:Say(nLin, 180, "Maquina",oFont09)
	oPrinter:Say(nLin, 260, "Qtde/Hr",oFont09)
	oPrinter:Say(nLin, 360, "Qtde Real.",oFont09)
	oPrinter:Say(nLin, 460, "Observações",oFont09)

	if lOper
		While (cAliasOper)->(!EOF())
			nLin +=16
			oPrinter:Say(nLin, 15, (cAliasOper)->G2_OPERAC, oFont10)
			oPrinter:Say(nLin, 60, (cAliasOper)->G2_DESCRI,oFont10)
			oPrinter:Say(nLin, 180, (cAliasOper)->G2_RECURSO, oFont10)
			(cAliasOper)->(DbSkip())
		EndDo
	else
		nLin +=16
		oPrinter:Say(nLin, 15, (cAliasOper)->G2_OPERAC, oFont10)
		oPrinter:Say(nLin, 60, (cAliasOper)->G2_DESCRI,oFont10)
		oPrinter:Say(nLin, 180, (cAliasOper)->G2_RECURSO, oFont10)
	endif
Return

//-----------------------------------------------------------------------------
//	Imprime o espaço para registro dos apontamentos e o rodapé da ordem
//-----------------------------------------------------------------------------
Static Function printApont()
	Local nLinIni	:= 0

	nLin += 10
	nLinIni = nLin

	oPrinter:Line(nLin, 15, nLin, 550)
	oPrinter:Say(nLin+15, 235, "Apontamentos",oFont12b)
	oPrinter:Line(nLin+20, 15, nLin+20, 550)

	nLin +=32
	oPrinter:Say(nLin, 30, "Data",oFont10)
	oPrinter:Say(nLin, 73, "Turno",oFont10)
	oPrinter:Say(nLin, 110, "Operador",oFont10)
	oPrinter:Say(nLin, 173, "Inicio",oFont10)
	oPrinter:Say(nLin, 228, "Fim",oFont10)
	oPrinter:Say(nLin, 282, "Qtde.",oFont10)
	oPrinter:Say(nLin, 335, "Refugo",oFont10)
	oPrinter:Say(nLin, 390, "Motivo",oFont10)
	oPrinter:Say(nLin, 450, "Observacao",oFont10)

	// Looping de linhas em branco para apontamentos
	nLin += 2

	While nLin <= 710
		oPrinter:Line(nLin, 15, nLin, 550)
		nLin += 23
	EndDo

	// Colunas
	oPrinter:Line(nLinIni, 15, nLin, 15)
	oPrinter:Line(nLinIni+20, 70, nLin, 70)
	oPrinter:Line(nLinIni+20, 105, nLin, 105)
	oPrinter:Line(nLinIni+20, 160, nLin, 160)
	oPrinter:Line(nLinIni+20, 215, nLin, 215)
	oPrinter:Line(nLinIni+20, 270, nLin, 270)
	oPrinter:Line(nLinIni+20, 325, nLin, 325)
	oPrinter:Line(nLinIni+20, 380, nLin, 380)
	oPrinter:Line(nLinIni+20, 435, nLin, 435)
	oPrinter:Line(nLinIni, 550, nLin, 550)

	// Última linha
	oPrinter:Line(nLin, 15, nLin, 550)

	nLin += 10
	oPrinter:Box(nLin, 15, nLin+85, 550)		    // Box(row, col, bottom, right)

	nlin += 12
	oPrinter:Say(nLin, 240, "Sim     Não",oFont10)

	nlin += 18
	oPrinter:Say(nLin, 30, "Peças Separadas Para Liberação:",oFont10)
	oPrinter:Box(nLin-10, 240, nLin+5, 260)		    // Box(row, col, bottom, right)
	oPrinter:Box(nLin-10, 270, nLin+5, 290)		    // Box(row, col, bottom, right)
	oPrinter:Say(nLin, 330, "Visto Qualidade:",oFont10)
	oPrinter:Say(nLin, 420, "_____________________",oFont10)

	nlin += 20
	oPrinter:Say(nLin, 30, "Ordem Finalizada:",oFont10)
	oPrinter:Box(nLin-10, 240, nLin+5, 260)		    // Box(row, col, bottom, right)
	oPrinter:Box(nLin-10, 270, nLin+5, 290)		    // Box(row, col, bottom, right)
	oPrinter:Say(nLin, 330, "Visto Liderança:",oFont10)
	oPrinter:Say(nLin, 420, "_____________________",oFont10)

	nlin += 20
	oPrinter:Say(nLin, 30, "Material Finalizado:",oFont10)
	oPrinter:Box(nLin-10, 240, nLin+5, 260)		    // Box(row, col, bottom, right)
	oPrinter:Box(nLin-10, 270, nLin+5, 290)		    // Box(row, col, bottom, right)
	oPrinter:Say(nLin, 330, "Visto PCP:",oFont10)
	oPrinter:Say(nLin, 420, "_____________________",oFont10)

Return


//-----------------------------------------------------------------------------
//	Imprime o espaço para registro das paradas
//-----------------------------------------------------------------------------
Static Function printParada()
	oPrinter:StartPage()

	Local nLinIni	:= 0

	nLin = 40
	nLinIni = nLin

	oPrinter:Line(nLin, 15, nLin, 550)
	oPrinter:Say(nLin+15, 250, "Paradas",oFont12b)
	oPrinter:Line(nLin+20, 15, nLin+20, 550)

	nLin +=32
	oPrinter:Say(nLin, 30, "Data",oFont10)
	oPrinter:Say(nLin, 73, "Turno",oFont10)
	oPrinter:Say(nLin, 108, "Operador",oFont10)
	oPrinter:Say(nLin, 160, "Inicio",oFont10)
	oPrinter:Say(nLin, 200, "Fim",oFont10)

	oPrinter:Say(nLin, 240, "Cód.Parada",oFont10)
	oPrinter:Say(nLin, 282, "Qtde.",oFont10)
	oPrinter:Say(nLin, 335, "Refugo",oFont10)
	oPrinter:Say(nLin, 380, "Cód.Ref.",oFont10)
	oPrinter:Say(nLin, 450, "Observacao",oFont10)

	// Looping de linhas em branco para apontamentos
	nLin += 2

	While nLin <= 810
		oPrinter:Line(nLin, 15, nLin, 550)
		nLin += 23
	EndDo

	// Colunas
	oPrinter:Line(nLinIni, 15, nLin, 15)
	oPrinter:Line(nLinIni+20, 70, nLin, 70)
	oPrinter:Line(nLinIni+20, 105, nLin, 105)
	oPrinter:Line(nLinIni+20, 160, nLin, 160)
	oPrinter:Line(nLinIni+20, 215, nLin, 215)
	oPrinter:Line(nLinIni+20, 270, nLin, 270)
	oPrinter:Line(nLinIni+20, 325, nLin, 325)
	oPrinter:Line(nLinIni+20, 380, nLin, 380)
	oPrinter:Line(nLinIni+20, 435, nLin, 435)
	oPrinter:Line(nLinIni, 550, nLin, 550)

	// Última linha
	oPrinter:Line(nLin, 15, nLin, 550)

	oPrinter:EndPage()
	oPrinter:Preview() //Gera e abre o arquivo em PDF
	FreeObj(oPrinter)
	oPrinter := nil
Return
