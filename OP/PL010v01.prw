#Include "Protheus.ch"
#Include "TBIConn.ch"
#Include "Colors.ch"
#Include "RPTDef.ch"
#Include "FwPrintsetup.ch"
 
/*/{Protheus.doc}RELAT03
Ordem de ProduÃ§Ã£o MR V01

@author Carlos ASsis
@since 04/11/2023
@version 1.0   
/*/
User Function MRPL010v01()

	Local cQuery 		:= ""
	Local cAliasOrd 	:= ""

	Local nLin 			:= 0
	Local oPrinter		:= nil

	Local aResps		:= {}
	Local cOrdemDe		:= 000001
	Local cOrdemAte		:= 000002

	// Setup da filial
	Local lPar01 		:= ""
	Local cPar02 		:= ""
	Local dPar03 		:= CTOD(' / / ')

	Prepare Environment Empresa '01' Filial '01'
    lPar01 := SuperGetMV("MV_PARAM",.F.)
    cPar02 := cFilAnt
    dPar03 := dDataBase
	//---------------

	aResps := GetParams()
	if aResps == nil
		return
	EndIf
 
	cOrdemDe	:= aResps[1]
	cOrdemAte	:= aResps[2]
	
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
    cQuery += "  AND C2_NUM >= '" + cOrdemDe  + "' " 				+ CRLF
    cQuery += "  AND C2_NUM <= '" + cOrdemAte + "' " 				+ CRLF
    cAliasOrd := MPSysOpenQuery(cQuery)

    While (cAliasOrd)->(!EOF())
		printCabec	(@cAliasOrd, @oPrinter, @nLin)
		printCompon	(@cAliasOrd, @oPrinter, @nLin)
		printOper	(@cAliasOrd, @oPrinter, @nLin)
		printRodape	(@oPrinter, @nLin)
        
        (cAliasOrd)->(DbSkip())
		return
    EndDo
return


Static Function getParams()
    Local aPergs    := {}
    Local aResps    := {}

    AAdd(aPergs, {1, "Ordem Inicial", Space(6) ,,,,, 20, .F.})
    AAdd(aPergs, {1, "Ordem Final", Space(6) ,,,,, 20, .F.})

    If ParamBox(aPergs, "Parâmetros do relatório", @aResps,,,,,,,, .T., .T.)
        Return(aResps)
    EndIf
Return nil


Static Function printCabec(cAliasOrd, oPrinter, nLin)
	Local oFont10 		:= TFont():New( "Arial",, -10, .T.)
	Local oFont12 		:= TFont():New( "Arial",, -12, .T.)
	Local oFont16 		:= TFont():New( "Arial",, -16, .T.)

	Local cFilePrintert		:= "OP" + cValToChar((cAliasOrd)->C2_NUM) + DToS(Date()) + StrTran(Time(),":","") + ".pdf"
	Local nDevice			:= 6 //1-DISCO, 2-SPOOL, 3-EMAIL, 4-EXCEL, 5-HTML, 6-PDF
	Local lAdjustToLegacy	:= .F.
	Local lDisableSetup		:= .T.

	oPrinter := FWMsPrinter():New(cFilePrintert,nDevice,lAdjustToLegacy,,lDisableSetup)
	oPrinter:SetResolution(72)
	oPrinter:SetPortrait() //oPrinter:SetLandscape()
	oPrinter:SetPaperSize(9) //1-Letter, 3-Tabloid, 7-Executive, 8-A3, 9-A4
	oPrinter:SetMargin(60,60,60,60) // nEsquerda, nSuperior, nDireita, nInferior
	oPrinter:SetParm( "-RFS")
	oPrinter:cPathPDF := "c:\temp\" // Se for usado PDF e fora de rotina agendada
	oPrinter:lServer := .F. //.T. Se for usado em rotina agendada
	oPrinter:lViewPDF := .T. //.F. Se for usado em rotina agendada
	oPrinter:StartPage()

	oPrinter:Box(40,15,100,550)		    // Box(row, col, bottom, right)

	nLin := 60
	/*oPrinter:SayBitmap(nLin-15, 20, "C:\temp\logo.jfif", 150, 50)*/
	/*oPrinter:SayBitmap(nLin-15, 20, "\images\logo.jfif", 150, 50)*/
	oPrinter:Say(nLin, 200,"ORDEM DE PRODUCAO",oFont16)

	oPrinter:Line(nLin-20, 400, 100, 400)
	oPrinter:Say(nLin, 410,"Num.",oFont10)
	oPrinter:Say(nLin, 460,cValToChar((cAliasOrd)->C2_NUM),oFont16)

	nLin +=65
	oPrinter:Say(nLin, 15, "Cod. Item:" ,oFont10)
	oPrinter:Say(nLin, 80, (cAliasOrd)->B1_COD, oFont12)
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


Static Function printCompon(cAliasOrd, oPrinter, nLin)
	Local cQuery        	:= ""
	Local cAliasCmp        	:= ""
	Local cOp 				:= ""
	Local oFont10 			:= TFont():New( "Arial",, -10, .T.)
	Local oFont12 			:= TFont():New( "Arial",, -12, .T.)

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
	oPrinter:Say(nLin+25, 225, "Material Necessario",oFont12)
	oPrinter:Line(nLin+30, 15, nLin+30, 550)

	nLin +=45
	oPrinter:Say(nLin, 15, "Cod. Item",oFont10)
	oPrinter:Say(nLin, 80, "Descricao",oFont10)
	oPrinter:Say(nLin, 300, "Quantidade",oFont10)
	oPrinter:Say(nLin, 360, "UM",oFont10)
	oPrinter:Say(nLin, 400, "Lote",oFont10)
	oPrinter:Say(nLin, 500, "Lote Real",oFont10)

   	While (cAliasCmp)->(!EOF())
		nLin +=20
		oPrinter:Say(nLin, 15, (cAliasCmp)->B1_COD, oFont10)
		oPrinter:Say(nLin, 80, (cAliasCmp)->B1_DESC,oFont10)
		oPrinter:Say(nLin, 300, TRANSFORM((cAliasCmp)->D4_QUANT, "@E 999,999.999"), oFont10)
		oPrinter:Say(nLin, 360, (cAliasCmp)->B1_UM,oFont10)
		oPrinter:Say(nLin, 400, (cAliasCmp)->D4_LOTECTL,oFont10)
        (cAliasCmp)->(DbSkip())
    EndDo
Return


Static Function printOper(cAliasOrd, oPrinter, nLin)
	Local cQuery        := ""
    Local cAliasOper    := ""

	Local oFont10 		:= TFont():New( "Arial",, -10, .T.)
	Local oFont12 		:= TFont():New( "Arial",, -12, .T.)

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
	oPrinter:Say(nLin+25, 260, "Operacoes",oFont12)
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


Static Function printRodape(oPrinter, nLin)
	Local nLinIni	:= 0
	Local oFont10 	:= TFont():New( "Arial",, -10, .T.)
	Local oFont12 	:= TFont():New( "Arial",, -12, .T.)

	nLin += 10
	nLinIni = nLin

	oPrinter:Line(nLin, 15, nLin, 550)
	oPrinter:Say(nLin+15, 235, "Apontamentos",oFont12)
	oPrinter:Line(nLin+20, 15, nLin+20, 550)

	nLin +=45
	oPrinter:Say(nLin, 30, "Data",oFont10)
	oPrinter:Say(nLin, 73, "Turno",oFont10)
	oPrinter:Say(nLin, 110, "Operador",oFont10)
	oPrinter:Say(nLin, 173, "Inicio",oFont10)
	oPrinter:Say(nLin, 228, "Fim",oFont10)
	oPrinter:Say(nLin, 282, "Qtde.",oFont10)
	oPrinter:Say(nLin, 335, "Refugo",oFont10)
	oPrinter:Say(nLin, 390, "Motivo",oFont10)
	oPrinter:Say(nLin, 450, "Observacao",oFont10)

	// Looping de apontamentos
	//
	nLin += 5

	While nLin <= 710
		oPrinter:Line(nLin, 15, nLin, 550)
		nLin += 20
	EndDo

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

	oPrinter:Line(nLin, 15, nLin, 550)

	nLin += 20
	oPrinter:Box(nLin, 15, nLin+100, 550)		    // Box(row, col, bottom, right)

	oPrinter:EndPage()
	oPrinter:Preview() //Gera e abre o arquivo em PDF
Return
