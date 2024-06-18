#Include "PROTHEUS.CH"
#Include "RPTDEF.CH"
#Include "TBICONN.CH"
#Include "FWPrintSetup.ch"
#Include "Colors.ch"

/*/{Protheus.doc}	PL010
	Impressao da Ordem de Producao Modelo MR V01
@author Carlos Assis
@since 04/11/2023
@version 1.0   
/*/

Static oFont09 	:= TFont():New( "Arial",, -09, .T.)
Static oFont10 	:= TFont():New( "Arial",, -10, .T.)
Static oFont11 	:= TFont():New( "Arial",, -11, .T.)
Static oFont11b := TFont():New( "Arial",, -11, .T.,.T.)
Static oFont12 	:= TFont():New( "Arial",, -12, .T.)
Static oFont12b := TFont():New( "Arial",, -12, .T.,.T.)
Static oFont16b := TFont():New( "Arial",, -16, .T.,.T.)

User Function PL010()
	Local aPergs	    := {}
	Local aResps	    := {}
	Local cOrdemDe	    := 0
	Local cOrdemAte	    := 0
	Local lContinua	    := .T.
	Local cOp		    := ""
	Local nRecs		    := 0

	Private oPrinter    := nil
	Private cQuery 	    := ""
	Private lOper 	    := .T.  		   	// Todas as operacões juntas
	Private nLin 	    := 0
	PRivate cDir        := "c:\temp\"  		// Local do relatorio
	Private cFilePrint  := ""
	Private lComp		:= .F.

	Private cAliasOrd 	:= ""			   	// Dados da OP
	Private cAliasCmp	:= ""			   	// Componentes da OP
	Private cAliasOper  := ""			   	// Operacões da OP

	AAdd(aPergs, {1, "Ordem Inicial", CriaVar("C2_NUM",.F.),,,"SC2",, 50, .F.})
	AAdd(aPergs, {1, "Ordem Final"  , CriaVar("C2_NUM",.F.),,,"SC2",, 50, .F.})
	AAdd(aPergs ,{4, "Operacoes"   	,.T.,"Todas as operacoes juntas" ,90,"",.F.})

	If ParamBox(aPergs, "Parametros do relatorio", @aResps,,,,,,,, .T., .T.)
		cOrdemDe    := aResps[1]
		cOrdemAte	:= aResps[2]
		lOper		:= aResps[3]
	Else
		lContinua   := .F.
		return
	endif

	// LER OP E ITEM
	cQuery := "SELECT C2_NUM, C2_ITEM, C2_SEQUEN, C2_PRODUTO, "     + CRLF
	cQuery += "	 C2_QUANT, CAST(C2_DATPRI AS DATE) C2_DATPRI, "	    + CRLF
	cQuery += "	 CAST(C2_DATPRF AS DATE) C2_DATPRF, " 			    + CRLF
	cQuery += "	 B1_COD, B1_DESC, B1_UM, B1_XCLIENT, B1_XPROJ "     + CRLF
	cQuery += " FROM " +	RetSQLName("SC2") + " SC2 " 			+ CRLF
	cQuery += "INNER JOIN " + RetSQLName("SB1") + " SB1 " 		    + CRLF
	cQuery += "	  ON C2_PRODUTO = B1_COD " 					        + CRLF
	cQuery += "WHERE C2_FILIAL = '" + xFilial("SC2") + "' " 	    + CRLF
	cQuery += "	 AND SC2.D_E_L_E_T_ = ' ' " 					    + CRLF
	cQuery += "	 AND SB1.D_E_L_E_T_ = ' ' " 					    + CRLF

	If !Empty(cOrdemDe) .Or. !Empty(cOrdemAte)
		cQuery += " AND C2_NUM BETWEEN '" + cOrdemDe  + "' AND '" + cOrdemAte + "' " + CRLF
	EndIf

	cQuery += "	ORDER BY C2_NUM, C2_ITEM, C2_SEQUEN " + CRLF

	cAliasOrd := MPSysOpenQuery(cQuery)

	While (cAliasOrd)->(!EOF())

		cOp := (cAliasOrd)->C2_NUM + (cAliasOrd)->C2_ITEM + (cAliasOrd)->C2_SEQUEN

		// Ler os empenhos da OP
		cQuery := "SELECT D4_COD, D4_OP, D4_DATA, D4_QTDEORI, " + CRLF
		cQuery += "	 D4_QUANT, D4_LOTECTL, "					+ CRLF
		cQuery += "	 B1_COD, B1_DESC, B1_UM " 					+ CRLF
		cQuery += " FROM " + RetSQLName("SD4") + " SD4 " 		+ CRLF
		cQuery += "INNER JOIN " + RetSQLName("SB1") + " SB1 " 	+ CRLF
		cQuery += "	  ON D4_COD = B1_COD " 						+ CRLF
		cQuery += "WHERE SD4.D_E_L_E_T_ = ' ' " 				+ CRLF
		cQuery += "	 AND SB1.D_E_L_E_T_ = ' ' " 				+ CRLF
		cQuery += "  AND D4_FILIAL = '" + xFilial("SC5") + "' " + CRLF
		cQuery += "  AND D4_OP = '" + cOp + "' " 				+ CRLF
		cQuery += " ORDER BY D4_COD" 				 			+ CRLF
		cAliasCmp := MPSysOpenQuery(cQuery)

		nRecs = 0
		While (cAliasCmp)->(!EOF())
			nRecs += 1
			(cAliasCmp)->(DbSkip())
		EndDo

		if nRecs = 0
			FWAlertError("ITEM NAO POSSUI ESTRUTURA!", "ERRO")
			return
		endif

		(cAliasCmp)->(dbGoTop())

		// Ler as operacões do item
		cQuery := "SELECT G2_OPERAC, G2_RECURSO, G2_FERRAM, " 		    + CRLF
		cQuery += "	G2_DESCRI, G2_MAOOBRA, G2_SETUP, "					+ CRLF
		cQuery += "	G2_LOTEPAD, G2_TEMPAD, G2_CTRAB, "					+ CRLF
		cQuery += "	G2_TEMPEND "										+ CRLF
		cQuery += "FROM " + RetSQLName("SG2") + " SG2 " 				+ CRLF
		cQuery += "WHERE SG2.D_E_L_E_T_ = ' ' " 						+ CRLF
		cQuery += "  AND G2_FILIAL  = '" + xFilial("SC5") + "' " 	    + CRLF
		cQuery += "  AND G2_CODIGO  = '01'" 						 	+ CRLF
		cQuery += "  AND G2_PRODUTO = '" + (cAliasOrd)->B1_COD + "' "   + CRLF
		cQuery += " ORDER BY G2_OPERAC" 			 					+ CRLF
		cAliasOper := MPSysOpenQuery(cQuery)

		nRecs = 0
		While (cAliasOper)->(!EOF())
			nRecs += 1
			(cAliasOper)->(DbSkip())
		EndDo

		if nRecs = 0
			If ! FWAlertYesNo("ITEM NAO POSSUI OPERACOES!", "Confirma a impressao?")
				return
			EndIf
		EndIf

		(cAliasOper)->(dbGoTop())

		lComp = .F.

		if lOper	// Imprime todas as operacões da ordem na mesma página
			cFilePrint	:= "OP" + cValToChar((cAliasOrd)->C2_NUM)
			cFilePrint	+= cValToChar((cAliasOrd)->C2_ITEM)
			cFilePrint	+= cValToChar((cAliasOrd)->C2_SEQUEN)
			cFilePrint	+= DToS(Date()) + StrTran(Time(),":","") + ".pdf"

			printCabec	()
			printCompon	()
			printOper	()
			printApont	()
			printParada ()

		else // Imprime uma pagina por operacao
			While (cAliasOper)->(!EOF())
				cFilePrint	:= "OP" + cValToChar((cAliasOrd)->C2_NUM) + cValToChar((cAliasOrd)->C2_ITEM)
				cFilePrint	+= cValToChar((cAliasOrd)->C2_SEQUEN) + cValToChar((cAliasOper)->G2_OPERAC)
				cFilePrint	+= DToS(Date()) + StrTran(Time(),":","") + ".pdf"

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
//	Imprime o cabecalho da OP
//-----------------------------------------------------------------------------
Static Function printCabec()

	oPrinter := FWMSPrinter():New(cFilePrint,	IMP_PDF,.F.,cDir,.T.,,,,.T.,.F.,,.T.)
	oFont1 := TFont():New('Courier new',,-18,.T.)
	oPrinter:SetParm( "-RFS")
	oPrinter:cPathPDF := cDir 			// Se for usado PDF e fora de rotina agendada
	oPrinter:SetPortrait()
	oPrinter:SetPaperSize(DMPAPER_A4)
	oPrinter:SetMargin(40,40,40,40) 	// nEsquerda, nSuperior, nDireita, nInferior
	oPrinter:StartPage()

	oPrinter:Box(20,15,60,550)		    // Box(row, col, bottom, right)

	nLin := 40
	oPrinter:SayBitmap(nLin-15, 20, "\images\logo.png", 130, 30)
	oPrinter:Say(nLin+3, 190,"ORDEM DE PRODUCAO",oFont16b)

	oPrinter:Line(nLin-20, 400, 60, 400)
	oPrinter:Say(nLin-10, 430,"Num. Ordem",oFont10)
	oPrinter:Say(nLin-5 + 17, 410, cValToChar((cAliasOrd)->C2_NUM) + "/" + cValToChar((cAliasOrd)->C2_ITEM) + "/" + cValToChar((cAliasOrd)->C2_SEQUEN), oFont16b)

	nLin +=35
	oPrinter:Say(nLin, 15, "Cod. Item:" ,oFont10)
	oPrinter:Say(nLin, 75, (cAliasOrd)->B1_COD, oFont12b)
	oPrinter:Say(nLin, 150, "Descricao:",oFont10)
	oPrinter:Say(nLin, 210, (cAliasOrd)->B1_DESC, oFont11)

	nLin +=20
	oPrinter:Say(nLin, 15, "Data Inicio:",oFont10)
	oPrinter:Say(nLin, 75, DTOC((cAliasOrd)->C2_DATPRI), oFont11)
	oPrinter:Say(nLin, 150, "Data Termino:",oFont10)
	oPrinter:Say(nLin, 220, DTOC((cAliasOrd)->C2_DATPRF), oFont11)
	oPrinter:Say(nLin, 400, "Quantidade:",oFont10)

	if (cAliasOrd)->C2_QUANT - int((cAliasOrd)->C2_QUANT) == 0
		oPrinter:Say(nLin, 450, TRANSFORM((cAliasOrd)->C2_QUANT, "@E 999,999") + " " + (cAliasOrd)->B1_UM, oFont11b)
	else
		oPrinter:Say(nLin, 450, TRANSFORM((cAliasOrd)->C2_QUANT, "@E 999,999.999") + " " + (cAliasOrd)->B1_UM, oFont11b)
	endif

	nLin +=20
	oPrinter:Say(nLin, 15, "Cliente:",oFont10)
	oPrinter:Say(nLin, 75, (cAliasOrd)->B1_XCLIENT, oFont10)
	oPrinter:Say(nLin, 220, "Projeto:",oFont10)
	oPrinter:Say(nLin, 270,(cAliasOrd)->B1_XPROJ, oFont10)

Return

//-----------------------------------------------------------------------------
//	Imprime os componentes da OP (estrutura)
//-----------------------------------------------------------------------------
Static Function printCompon()

	if lOper = .F. 					// Uma operacao por pagina
		if lComp = .T.					// Já imprimiu a primeira operacao, nao imprime os componentes de novo
			return
		else
			lComp = .T.
		endif
	endif

	oPrinter:Line(nLin+10, 15, nLin+10, 550)
	oPrinter:Say(nLin+25, 225, "Material Necessario",oFont12b)
	oPrinter:Line(nLin+30, 15, nLin+30, 550)

	nLin +=45
	oPrinter:Say(nLin, 15, "Cod. Item",oFont09)
	oPrinter:Say(nLin, 70, "Descricao",oFont09)
	oPrinter:Say(nLin, 340, "Quantidade",oFont09)
	oPrinter:Say(nLin, 420, "Lote",oFont09)
	oPrinter:Say(nLin, 500, "Lote Real",oFont09)

	While (cAliasCmp)->(!EOF())
		nLin +=16
		oPrinter:Say(nLin, 15, (cAliasCmp)->B1_COD, oFont10)
		oPrinter:Say(nLin, 70, SUBSTR((cAliasCmp)->B1_DESC, 1, 55), oFont09)

		oPrinter:Say(nLin, 340, TRANSFORM((cAliasCmp)->D4_QTDEORI, "@E 999,999.999") + " " + (cAliasCmp)->B1_UM,oFont10)
		oPrinter:Say(nLin, 430, (cAliasCmp)->D4_LOTECTL,oFont10)
		(cAliasCmp)->(DbSkip())
	EndDo

Return

//-----------------------------------------------------------------------------
//	Imprime as operacões da OP
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
	oPrinter:Say(nLin, 460, "Observacoes",oFont09)

	if lOper
		While (cAliasOper)->(!EOF())
			nLin +=16
			oPrinter:Say(nLin, 15, (cAliasOper)->G2_OPERAC, oFont10)
			oPrinter:Say(nLin, 60, (cAliasOper)->G2_DESCRI,oFont10)
			oPrinter:Say(nLin, 180, (cAliasOper)->G2_RECURSO, oFont10)

			if (cAliasOper)->G2_LOTEPAD - int((cAliasOper)->G2_LOTEPAD) == 0
				oPrinter:Say(nLin, 260, TRANSFORM((cAliasOper)->G2_LOTEPAD, "@E 99,999"), oFont10)
			else
				oPrinter:Say(nLin, 260, TRANSFORM((cAliasOper)->G2_LOTEPAD, "@E 99,999.999"), oFont10)
			endif

			(cAliasOper)->(DbSkip())
		EndDo
	else
		nLin +=16
		oPrinter:Say(nLin, 15, (cAliasOper)->G2_OPERAC, oFont10)
		oPrinter:Say(nLin, 60, (cAliasOper)->G2_DESCRI,oFont10)
		oPrinter:Say(nLin, 180, (cAliasOper)->G2_RECURSO, oFont10)

		if (cAliasOper)->G2_LOTEPAD - int((cAliasOper)->G2_LOTEPAD) == 0
			oPrinter:Say(nLin, 260, TRANSFORM((cAliasOper)->G2_LOTEPAD, "@E 99,999"), oFont10)
		else
			oPrinter:Say(nLin, 260, TRANSFORM((cAliasOper)->G2_LOTEPAD, "@E 99,999.999"), oFont10)
		endif
	endif
Return

//-----------------------------------------------------------------------------
//	Imprime o espaco para registro dos apontamentos e o rodapé da ordem
//-----------------------------------------------------------------------------
Static Function printApont()
	Local nLinIni	:= 0

	nLin += 10
	nLinIni = nLin

	oPrinter:Line(nLin, 15, nLin, 550)
	oPrinter:Say(nLin+15, 235, "Apontamentos",oFont12b)
	oPrinter:Line(nLin+20, 15, nLin+20, 550)

	nLin +=32
	oPrinter:Say(nLin, 30, "Data",oFont09)
	oPrinter:Say(nLin, 73, "Turno",oFont09)
	oPrinter:Say(nLin, 110, "Operador",oFont09)
	oPrinter:Say(nLin, 173, "Inicio",oFont09)
	oPrinter:Say(nLin, 228, "Fim",oFont09)
	oPrinter:Say(nLin, 282, "Qtde.",oFont09)
	oPrinter:Say(nLin, 335, "Refugo",oFont09)
	oPrinter:Say(nLin, 390, "Motivo",oFont09)
	oPrinter:Say(nLin, 450, "Observacao",oFont09)

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

	// �ltima linha
	oPrinter:Line(nLin, 15, nLin, 550)

	nLin += 10
	oPrinter:Box(nLin, 15, nLin+85, 550)		      // Box(row, col, bottom, right)

	nlin += 12
	oPrinter:Say(nLin, 240, "Sim     Nao",oFont10)

	nlin += 18
	oPrinter:Say(nLin, 30, "Pecas Separadas Para Liberacao:",oFont10)
	oPrinter:Box(nLin-10, 240, nLin+5, 260)		   // Box(row, col, bottom, right)
	oPrinter:Box(nLin-10, 270, nLin+5, 290)		   // Box(row, col, bottom, right)
	oPrinter:Say(nLin, 330, "Visto Qualidade:",oFont10)
	oPrinter:Say(nLin, 420, "_____________________",oFont10)

	nlin += 20
	oPrinter:Say(nLin, 30, "Ordem Finalizada:",oFont10)
	oPrinter:Box(nLin-10, 240, nLin+5, 260)		   // Box(row, col, bottom, right)
	oPrinter:Box(nLin-10, 270, nLin+5, 290)		   // Box(row, col, bottom, right)
	oPrinter:Say(nLin, 330, "Visto Lideranca:",oFont10)
	oPrinter:Say(nLin, 420, "_____________________",oFont10)

	nlin += 20
	oPrinter:Say(nLin, 30, "Material Finalizado:",oFont10)
	oPrinter:Box(nLin-10, 240, nLin+5, 260)		   // Box(row, col, bottom, right)
	oPrinter:Box(nLin-10, 270, nLin+5, 290)		   // Box(row, col, bottom, right)
	oPrinter:Say(nLin, 330, "Visto PCP:",oFont10)
	oPrinter:Say(nLin, 420, "_____________________",oFont10)

Return


//-----------------------------------------------------------------------------
//	Imprime o espa�o para registro das paradas
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
	oPrinter:Say(nLin, 28, "Data",oFont09)
	oPrinter:Say(nLin, 69, "Turno",oFont09)
	oPrinter:Say(nLin, 107, "Operador",oFont09)
	oPrinter:Say(nLin, 164, "Inicio",oFont09)
	oPrinter:Say(nLin, 215, "Fim",oFont09)

	oPrinter:Say(nLin, 252, "Cod.Par.",oFont09)
	oPrinter:Say(nLin, 304, "Qtde.",oFont09)
	oPrinter:Say(nLin, 350, "Refugo",oFont09)
	oPrinter:Say(nLin, 408, "Cod.Ref.",oFont09)
	oPrinter:Say(nLin, 472, "Observacao",oFont09)

	// Looping de linhas em branco para apontamentos
	nLin += 2

	While nLin <= 810
		oPrinter:Line(nLin, 15, nLin, 550)
		nLin += 23
	EndDo

	// Colunas
	oPrinter:Line(nLinIni, 15, nLin, 15)
	oPrinter:Line(nLinIni+20, 65, nLin, 65)
	oPrinter:Line(nLinIni+20, 100, nLin, 100)
	oPrinter:Line(nLinIni+20, 150, nLin, 150)
	oPrinter:Line(nLinIni+20, 200, nLin, 200)
	oPrinter:Line(nLinIni+20, 249, nLin, 249)
	oPrinter:Line(nLinIni+20, 295, nLin, 295)
	oPrinter:Line(nLinIni+20, 345, nLin, 345)
	oPrinter:Line(nLinIni+20, 400, nLin, 400)
	oPrinter:Line(nLinIni+20, 460, nLin, 460)
	oPrinter:Line(nLinIni, 550, nLin, 550)

	// Última linha
	oPrinter:Line(nLin, 15, nLin, 550)

	oPrinter:EndPage()
	oPrinter:Preview() //Gera e abre o arquivo em PDF
	FreeObj(oPrinter)
	oPrinter := nil
	Sleep(1000)
Return
