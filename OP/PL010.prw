#Include "PROTHEUS.CH"
#Include "RPTDEF.CH"
#INCLUDE "TBICONN.CH"
#INCLUDE "FWPrintSetup.ch"
#Include "Colors.ch"
 
/*/{Protheus.doc}	MRPL010
	Ordem de Produ��o MR V01

@author Carlos ASsis
@since 04/11/2023
@version 1.0   
/*/
User Function MRPL010()
	Local cQuery 	:= ""
	Local cAliasOrd := ""

	Local nLin 		:= 0
	Local oPrinter	:= nil

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

	If ParamBox(aPergs, "Par�metros do relat�rio", @aResps,,,,,,,, .T., .T.)
		cOrdemDe	:= aResps[1]
		cOrdemAte	:= aResps[2]
	Else
		lContinua := .F.
	EndIf
 
	If lContinua
		// LER OP E ITEM
		cQuery := "SELECT C2_NUM, C2_ITEM, C2_SEQUEN, C2_PRODUTO, " 	+ CRLF
		cQuery += "	 C2_QUANT, CAST(C2_DATPRI AS DATE) C2_DATPRI, "		+ CRLF
		cQuery += "	 CAST(C2_DATPRF AS DATE) C2_DATPRF, " 				+ CRLF
		cQuery += "	 B1_COD, B1_DESC, B1_UM, B1_XCLIENT, B1_XPROJ " 	+ CRLF
		cQuery += "FROM " +	RetSQLName("SC2") + " SC2 " 				+ CRLF
		cQuery += "INNER JOIN " + RetSQLName("SB1") + " SB1 " 			+ CRLF
		cQuery += "		ON C2_PRODUTO = B1_COD " 						+ CRLF
		cQuery += "WHERE C2_FILIAL = '" + xFilial("SC5") + "' " 		+ CRLF 
		cQuery += "	 AND SC2.D_E_L_E_T_ = ' ' " 						+ CRLF
		cQuery += "	 AND SB1.D_E_L_E_T_ = ' ' " 						+ CRLF
		If !Empty(cOrdemDe) .Or. !Empty(cOrdemAte)
			cQuery += "  AND C2_NUM >= '" + cOrdemDe  + "' " 				+ CRLF
			cQuery += "  AND C2_NUM <= '" + cOrdemAte + "' " 				+ CRLF
		EndIf

		cAliasOrd := MPSysOpenQuery(cQuery)

		While (cAliasOrd)->(!EOF())
			printCabec	(@cAliasOrd, @oPrinter, @nLin)
			printCompon	(@cAliasOrd, @oPrinter, @nLin)
			printOper	(@cAliasOrd, @oPrinter, @nLin)
			printRodape	(@oPrinter, @nLin)
			
			(cAliasOrd)->(DbSkip())
		EndDo
	EndIf

return

/*
	Imprime o cabe�alho da OP
*/
Static Function printCabec(cAliasOrd, oPrinter, nLin)
	Local oFont10 	:= TFont():New( "Arial",, -10, .T.)
	Local oFont12 	:= TFont():New( "Arial",, -12, .T.)
	Local oFont12b 	:= TFont():New( "Arial",, -12, .T., .T.)
	Local oFont16b 	:= TFont():New( "Arial",, -16, .T.,.T.)

	Local cFilePrintert		:= "OP" + cValToChar((cAliasOrd)->C2_NUM) + cValToChar((cAliasOrd)->C2_ITEM) + cValToChar((cAliasOrd)->C2_SEQUEN) + DToS(Date()) + StrTran(Time(),":","") + ".pdf"
	Local cDir				:= "c:\temp\"	// Local do relat�rio


	oPrinter := FWMSPrinter():New(cFilePrintert,IMP_PDF,.F.,cDir,.T.,,,,.T.,.F.,,.T.)
	oFont1 := TFont():New('Courier new',,-18,.T.)
	oPrinter:SetParm( "-RFS")
	oPrinter:cPathPDF := cDir 			// Se for usado PDF e fora de rotina agendada
	
	oPrinter:SetPortrait()
	oPrinter:SetPaperSize(DMPAPER_A4)
	oPrinter:SetMargin(50,50,50,50) // nEsquerda, nSuperior, nDireita, nInferior

	oPrinter:StartPage()

	oPrinter:Box(40,15,80,550)		    // Box(row, col, bottom, right)

	nLin := 60
	//oPrinter:SayBitmap(nLin-15, 20, "C:\temp\logo.jfif", 150, 50)
	oPrinter:Say(nLin+3, 190,"ORDEM DE PRODUCAO",oFont16b)

	oPrinter:Line(nLin-20, 400, 80, 400)
	oPrinter:Say(nLin-10, 420,"Num. Ordem",oFont10)
	oPrinter:Say(nLin-5 + 17, 410, cValToChar((cAliasOrd)->C2_NUM) + "/" + cValToChar((cAliasOrd)->C2_ITEM) + "/" + cValToChar((cAliasOrd)->C2_SEQUEN), oFont16b)

	nLin +=35
	oPrinter:Say(nLin, 15, "Cod. Item:" ,oFont10)
	oPrinter:Say(nLin, 80, (cAliasOrd)->B1_COD, oFont12b)
	oPrinter:Say(nLin, 160, "Descricao:",oFont10)
	oPrinter:Say(nLin, 220, (cAliasOrd)->B1_DESC, oFont12)

	nLin +=20
	oPrinter:Say(nLin, 15, "Quantidade:",oFont10)
	oPrinter:Say(nLin, 80, TRANSFORM((cAliasOrd)->C2_QUANT, "@E 999,999.999"), oFont12)
	oPrinter:Say(nLin, 160, "Unid. Medida:",oFont10)
	oPrinter:Say(nLin, 240, (cAliasOrd)->B1_UM, oFont10)
	oPrinter:Say(nLin, 400, "Qtde. Hora:",oFont10)

	nLin +=20
	oPrinter:Say(nLin, 15, "Data Inicio:",oFont10)
	oPrinter:Say(nLin, 80, DTOC((cAliasOrd)->C2_DATPRI), oFont12)
	oPrinter:Say(nLin, 160, "Data Termino:",oFont10)
	oPrinter:Say(nLin, 240, DTOC((cAliasOrd)->C2_DATPRF), oFont12)

Return

/*
	Imprime os componentes da OP (estrutura)
*/
Static Function printCompon(cAliasOrd, oPrinter, nLin)
	Local cQuery    := ""
	Local cAliasCmp	:= ""
	Local cOp 		:= ""
	Local oFont10 	:= TFont():New( "Arial",, -10, .T.)
	Local oFont12b	:= TFont():New( "Arial",, -12, .T., .T.)

	cOp := (cAliasOrd)->C2_NUM + (cAliasOrd)->C2_ITEM + (cAliasOrd)->C2_SEQUEN

	// LER COMPONENTES DA OP
    cQuery := "SELECT D4_COD, D4_OP, D4_DATA, D4_QTDEORI, " 	+ CRLF
    cQuery += "	 D4_QUANT, D4_LOTECTL, "						+ CRLF
    cQuery += "	 B1_COD, B1_DESC, B1_UM " 						+ CRLF
    cQuery += "FROM " + RetSQLName("SD4") + " SD4 " 			+ CRLF
    cQuery += "INNER JOIN " + RetSQLName("SB1") + " SB1 " 		+ CRLF
    cQuery += "		ON D4_COD = B1_COD " 						+ CRLF
    cQuery += "WHERE SD4.D_E_L_E_T_ = ' ' " 					+ CRLF
    cQuery += "	 AND SB1.D_E_L_E_T_ = ' ' " 					+ CRLF
    cQuery += "  AND D4_FILIAL = '" + xFilial("SC5") + "' " 	+ CRLF
    cQuery += "  AND D4_OP = '" + cOp + "' " 					+ CRLF
    cAliasCmp := MPSysOpenQuery(cQuery)

	oPrinter:Line(nLin+10, 15, nLin+10, 550)
	oPrinter:Say(nLin+25, 225, "Material Necessario",oFont12b)
	oPrinter:Line(nLin+30, 15, nLin+30, 550)

	nLin +=45
	oPrinter:Say(nLin, 15, "Cod. Item",oFont10)
	oPrinter:Say(nLin, 80, "Descricao",oFont10)
	oPrinter:Say(nLin, 310, "Quantidade",oFont10)
	oPrinter:Say(nLin, 410, "Lote",oFont10)
	oPrinter:Say(nLin, 500, "Lote Real",oFont10)

   	While (cAliasCmp)->(!EOF())
		nLin +=20
		oPrinter:Say(nLin, 15, (cAliasCmp)->B1_COD, oFont10)
		oPrinter:Say(nLin, 80, SUBSTR((cAliasCmp)->B1_DESC, 1, 35), oFont10)
		oPrinter:Say(nLin, 300, TRANSFORM((cAliasCmp)->D4_QUANT, "@E 999,999.999"), oFont10)
		oPrinter:Say(nLin, 345, (cAliasCmp)->B1_UM,oFont10)
		oPrinter:Say(nLin, 400, (cAliasCmp)->D4_LOTECTL,oFont10)
        (cAliasCmp)->(DbSkip())
    EndDo

Return

/*
	Imprime as opera��es da OP
*/
Static Function printOper(cAliasOrd, oPrinter, nLin)
	Local cQuery        := ""
    Local cAliasOper    := ""

	Local oFont10 		:= TFont():New( "Arial",, -10, .T.)
	Local oFont12b 		:= TFont():New( "Arial",, -12, .T., .T.)

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

	oPrinter:Line(nLin+10, 15, nLin+10, 550)
	oPrinter:Say(nLin+25, 250, "Operacoes",oFont12b)
	oPrinter:Line(nLin+30, 15, nLin+30, 550)

	nLin +=45
	oPrinter:Say(nLin, 15, "Oper.",oFont10)
	oPrinter:Say(nLin, 70, "Descricao",oFont10)
	oPrinter:Say(nLin, 260, "Maquina",oFont10)

 	While (cAliasOper)->(!EOF())
		nLin +=20
		oPrinter:Say(nLin, 15, (cAliasOper)->G2_OPERAC, oFont10)
		oPrinter:Say(nLin, 70, (cAliasOper)->G2_DESCRI,oFont10)
		oPrinter:Say(nLin, 260, (cAliasOper)->G2_RECURSO, oFont10)
        (cAliasOper)->(DbSkip())
    EndDo
Return

/*
	Imprime o espa�o para registro dos apontamentos e o rodap� da ordem
*/
Static Function printRodape(oPrinter, nLin)
	Local nLinIni	:= 0
	Local oFont10 	:= TFont():New( "Arial",, -10, .T.)
	Local oFont12b 	:= TFont():New( "Arial",, -12, .T., .T.)

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
		nLin += 25
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

	nLin += 20
	oPrinter:Box(nLin, 15, nLin+100, 550)		    // Box(row, col, bottom, right)

	nlin += 10
	oPrinter:Say(nLin, 240, "Sim     N�o",oFont10)

	nlin += 20
	oPrinter:Say(nLin, 30, "Pe�as Separadas Para Libera��o:",oFont10)
	oPrinter:Box(nLin-10, 240, nLin+5, 260)		    // Box(row, col, bottom, right)
	oPrinter:Box(nLin-10, 270, nLin+5, 290)		    // Box(row, col, bottom, right)
	oPrinter:Say(nLin, 330, "Visto Qualidade:",oFont10)
	oPrinter:Say(nLin, 420, "_____________________",oFont10)
	
	nlin += 20
	oPrinter:Say(nLin, 30, "Ordem Finalizada:",oFont10)
	oPrinter:Box(nLin-10, 240, nLin+5, 260)		    // Box(row, col, bottom, right)
	oPrinter:Box(nLin-10, 270, nLin+5, 290)		    // Box(row, col, bottom, right)
	oPrinter:Say(nLin, 330, "Visto Lideran�a:",oFont10)
	oPrinter:Say(nLin, 420, "_____________________",oFont10)

	nlin += 20
	oPrinter:Say(nLin, 30, "Material Finalizado:",oFont10)
	oPrinter:Box(nLin-10, 240, nLin+5, 260)		    // Box(row, col, bottom, right)
	oPrinter:Box(nLin-10, 270, nLin+5, 290)		    // Box(row, col, bottom, right)
	oPrinter:Say(nLin, 330, "Visto PCP:",oFont10)
	oPrinter:Say(nLin, 420, "_____________________",oFont10)

	oPrinter:EndPage()
	oPrinter:Preview() //Gera e abre o arquivo em PDF
	FreeObj(oPrinter)
	oPrinter := nil
Return
