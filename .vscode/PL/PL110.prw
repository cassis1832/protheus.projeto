#include "totvs.ch"
#include "MSOLE.CH"

//-------------------------------------------------------------------
/*/{Protheus.doc} PL110
	Etiqueta de Processo
	@author  Carlos Assis
	@since   20/05/2024
	@version 1.0
/*/
//-------------------------------------------------------------------
User Function PL110(cOp)
	Local aArea     	:= GetArea()
	Local aPergs    	:= {}
	Local aResps		:= {}

	Private cOrdem		:= Space(11)
	Private nNumEtq 	:= 0
	Private nQtdeEmb	:= 0
	Private cAliasOrd 	:= Nil

	if cOp != Nil
		if len(cOp) == 6
			cOrdem := cOp + "01001"
		else
			cOrdem := cOp
		endif
	endif

	if cOrdem != nil .and. Alltrim(cOrdem) != ""
		// LER OP E ITEM
		cSql := "SELECT C2_NUM, C2_ITEM, C2_SEQUEN, C2_PRODUTO, C2_QUANT, C2_DATPRF,"
		cSql += "       B1_COD, B1_DESC, B1_UM, B1_XITEM, B1_XCLIENT, B1_XPROJ, B1_XLINPRD, B1_XPROX, B1_XQEMB "
		cSql += "  FROM " + RetSQLName("SC2") + " SC2 "

		cSql += " INNER JOIN " + RetSQLName("SB1") + " SB1 "
		cSql += "    ON B1_COD 			= C2_PRODUTO "
		cSql += "   AND B1_FILIAL 		= '" + xFilial("SB1") + "' "
		cSql += "	AND SB1.D_E_L_E_T_ 	= ' ' "

		cSql += " WHERE C2_NUM 			= '" + Substr(cOrdem,1,6) + "'"
		cSql += "   AND C2_ITEM			= '" + Substr(cOrdem,7,2) + "'"
		cSql += "   AND C2_SEQUEN		= '" + Substr(cOrdem,9,3) + "'"
		cSql += "   AND C2_FILIAL 		= '" + xFilial("SC2") + "' "
		cSql += "	AND SC2.D_E_L_E_T_ 	= ' ' "
		cAliasOrd := MPSysOpenQuery(cSql)

		if (cAliasOrd)->(EOF())
			Alert("ORDEM DE PRODUCAO NAO ENCONTRADA!")
			return
		endif

		nQtdeEmb := (cAliasOrd)->B1_XQEMB

		if nQtdeEmb != 0
			nNumEtq := Ceiling(C2_QUANT / nQtdeEmb)
		endif
	endif

	aAdd(aPergs, {1, "Numero da Ordem"			, cOrdem,,,"SC2",, 60, .T.})
	aAdd(aPergs, {1, "Quantidade por Embalagem"	, nQtdeEmb, "@E 99,999", "Positivo()", "", ".T.", 40,  .T.})
	aAdd(aPergs, {1, "Numero de Etiquetas"		, nNumEtq,  "@E 999",    "Positivo()", "", ".T.", 40,  .T.})

	If ParamBox(aPergs, "ETIQUETA DE PROCESSO", @aResps,,,,,,,, .F., .T.)
		cOrdem    := aResps[1]
		nQtdeEmb  := aResps[2]
		nNumEtq   := aResps[3]
	Else
		return
	endif

	TrataOrdem()

	(cAliasOrd)->(DBCLOSEAREA())

	RestArea(aArea)
return


Static Function TrataOrdem()
	Local cSql	:= ''

	if cAliasOrd == Nil
		// LER OP E ITEM
		cSql := "SELECT C2_NUM, C2_ITEM, C2_SEQUEN, C2_PRODUTO, C2_QUANT, C2_DATPRF,"
		cSql += "       B1_COD, B1_DESC, B1_UM, B1_XITEM, B1_XCLIENT, B1_XPROJ, B1_XLINPRD, B1_XPROX "
		cSql += "  FROM " + RetSQLName("SC2") + " SC2 "

		cSql += " INNER JOIN " + RetSQLName("SB1") + " SB1 "
		cSql += "    ON B1_COD 			= C2_PRODUTO "
		cSql += "   AND B1_FILIAL 		= '" + xFilial("SB1") + "' "
		cSql += "	AND SB1.D_E_L_E_T_ 	= ' ' "

		cSql += " WHERE C2_NUM 			= '" + Substr(cOrdem,1,6) + "'"
		cSql += "   AND C2_ITEM			= '" + Substr(cOrdem,7,2) + "'"
		cSql += "   AND C2_SEQUEN		= '" + Substr(cOrdem,9,3) + "'"
		cSql += "   AND C2_FILIAL 		= '" + xFilial("SC2") + "' "
		cSql += "	AND SC2.D_E_L_E_T_ 	= ' ' "
		cAliasOrd := MPSysOpenQuery(cSql)

		if (cAliasOrd)->(EOF())
			Alert("ORDEM DE PRODUCAO NAO ENCONTRADA!")
			return
		endif
	endif

	EmiteEtiqueta(nNumEtq, nQtdeEmb)
RETURN


Static Function EmiteEtiqueta(nNumEtq, nQtdeEmb)
	Local nX        := 0
	Local nUltima   := (cAliasOrd)->C2_QUANT

	// Campos para imprimir
	Local cNumOp	:= (cAliasOrd)->C2_NUM + (cAliasOrd)->C2_ITEM + (cAliasOrd)->C2_SEQUEN
	Local cData		:= cValToChar(Stod((cAliasOrd)->C2_DATPRF))
	Local cItem     := (cAliasOrd)->B1_COD
	Local cDescr    := (cAliasOrd)->B1_XITEM
	Local cCliente  := Substr((cAliasOrd)->B1_XCLIENT,1,16)
	Local cOpAtual	:= ''
	Local cOpProx	:= ''

	Private nQtde   := 0
	Private aZPL	:= {}

	// Operacao atual
	if Alltrim(Upper((cAliasOrd)->B1_XLINPRD)) == "S"
		cOpAtual := "Solda"
	endif

	if Alltrim(Upper((cAliasOrd)->B1_XLINPRD)) == "E"
		cOpAtual := "Estamparia"
	endif

	// Proxima operacao
	if Alltrim(Upper((cAliasOrd)->B1_XPROX)) == "S"
		cOpProx := "Solda"
	endif

	if Alltrim(Upper((cAliasOrd)->B1_XPROX)) == "E"
		cOpProx := "Estamparia"
	endif

	if Alltrim(Upper((cAliasOrd)->B1_XPROX)) == "C"
		cOpProx := "Care"
	endif

	if Alltrim(Upper((cAliasOrd)->B1_XPROX)) == "X"
		cOpProx := "Exped."
	endif

	if nNumEtq <> 0
		nQtde := nNumEtq
	else
		if nQtdeEmb <> 0
			nQtde := NoRound((cAliasOrd)->C2_QUANT / nQtdeEmb, 0)
			nUltima := (cAliasOrd)->C2_QUANT - ((nQtde - 1) * nQtdeEmb )
		else
			nUltima := nQtde
			// else
			// 	if (cAliasOrd)->B1_XQEMB != 0 .and. (cAliasOrd)->C2_QUANT > (cAliasOrd)->B1_XQEMB
			// 		nQtde := NoRound((cAliasOrd)->C2_QUANT / (cAliasOrd)->B1_XQEMB, 0)
			// 		nUltima := (cAliasOrd)->C2_QUANT - ((nQtde - 1) * (cAliasOrd)->B1_XQEMB )
			// 	else
			// 		nQtde := 1
			// 		nUltima := 1
			// 	endif
		endif
	endif

	if nQtde = 1
		cMensagem := "SERA IMPRESSA <strong>" + cValToChar(nQtde) + " ETIQUETA.</strong>"
	else
		cMensagem := "SERAO IMPRESSAS <strong>" + cValToChar(nQtde) + " ETIQUETAS.</strong>"
	endif

	If ! FWAlertYesNo(cMensagem, "CONFIRMA A IMPRESSAO?")
		return
	EndIf

	For nX := 1 to nQtde
		aAdd(aZPL, "CT~~CD,~CC^~CT~")
		aAdd(aZPL, "^XA" )
		aAdd(aZPL, "~TA000" )
		aAdd(aZPL, "~JSN" )
		aAdd(aZPL, "^LT0^MNW^MTT^PON^PMN^LH0,0^PR5,5~SD15^JUS^LRN^CI27^PA0,1,1,0^XZ" )
		aAdd(aZPL, "^XA^MMT^PW799^LL599^LS0" )

		aAdd(aZPL, "^FT30,72^A0,40^FDMETALREZENDE^FS" )
		aAdd(aZPL, "^FT600,72^A0,40^FDPROCESSO^FS")

		// GB --> FOLeft,top ---   GBwidth,high,dots
		aAdd(aZPL, "^FO20,108^GB270,96,1^FS")
		aAdd(aZPL, "^FT30,130^A0,17^FDITEM^FS")
		aAdd(aZPL, "^FT30,185^A0,52^FD" + cItem + "^FS")
		aAdd(aZPL, "^FO295,108^GB495,96,1^FS")
		aAdd(aZPL, "^FT305,130^A0,17^FDDESCRICAO^FS")
		aAdd(aZPL, "^FT310,185^A0,50^FD" + Substr(cDescr,1,20) + "^FS")

		aAdd(aZPL, "^FO20,210^GB300,96,1^FS")
		aAdd(aZPL, "^FT30,230^A0,17^FDCLIENTE^FS")
		aAdd(aZPL, "^FT30,280^A0,35^FD" + cCliente + "^FS")
		aAdd(aZPL, "^FO325,210^GB210,96,1^FS")
		aAdd(aZPL, "^FT335,230^A0,17^FDDATA^FS")
		aAdd(aZPL, "^FT350,280^A0,35^FD" + cData + "^FS")
		aAdd(aZPL, "^FO540,210^GB250,96,1^FS")
		aAdd(aZPL, "^FT550,230^A0,17^FDORDEM^FS")
		aAdd(aZPL, "^FT550,280^A0,35^FD" + cNumOp + "^FS")

		aAdd(aZPL, "^FO20,312^GB250,96,1^FS")
		aAdd(aZPL, "^FT30,330^A0,17^FDOPER.ATUAL^FS")
		aAdd(aZPL, "^FT30,380^A0,40^FD" + cOpAtual + "^FS")

		aAdd(aZPL, "^FO275,312^GB260,96,1^FS")
		aAdd(aZPL, "^FT285,330^A0,17^FDOPERADOR^FS")

		aAdd(aZPL, "^FO540,312^GB250,96,1^FS")
		aAdd(aZPL, "^FT550,330^A0,17^FDTURNO^FS")
		aAdd(aZPL, "^FT570,380^A0,40^FD^FS")

		aAdd(aZPL, "^FO20,412^GB180,96,1^FS")
		aAdd(aZPL, "^FT30,430^A0,17^FDPROX.OPER.^FS")
		aAdd(aZPL, "^FT30,480^A0,40^FD" + cOpProx + "^FS")

		aAdd(aZPL, "^FO205,412^GB190,96,1^FS")
		aAdd(aZPL, "^FT215,430^A0,17^FDQTDE 1^FS")
		if nX < nQtde
			aAdd(aZPL, "^FT215,480^A0,40^FD" + cValToChar(nQtdeEmb) + "^FS")
		endif
		aAdd(aZPL, "^FT220,480^A0,40^FD^FS")

		aAdd(aZPL, "^FO405,412^GB190,96,1^FS")
		aAdd(aZPL, "^FT415,430^A0,17^FDQTDE 2^FS")
		aAdd(aZPL, "^FT570,480^A0,40^FD^FS")

		aAdd(aZPL, "^FO600,412^GB190,96,1^FS")
		aAdd(aZPL, "^FT610,430^A0,17^FDQTDE 3^FS")
		aAdd(aZPL, "^FT570,480^A0,40^FD^FS")

		aAdd(aZPL, "^PQ1,0,1,Y")
		aAdd(aZPL, "^XZ")
	next nX

	PrintZPL()

Return nil


Static Function PrintZPL()
	Local cPorta    := "LPT1"
	Local cFila     := "ETQPROC"
	Local ENTER		:= Chr(13)+Chr(10)
	Local nX	:= 0

	ZPLToTXT()

	MSCBPRINTER("ZEBRA", cPorta ,,,.F.,,,,40000 , cFila, .F.)
	MSCBCHKSTATUS(.F.)
	MSCBINFOETI("VOLUMES","7X10")

	For nX := 1 to Len(aZpl)
		MSCBWrite(aZPL[nX] + ENTER)
	next nX

	MSCBEND()
	MSCBCLOSEPRINTER()
return


Static Function ZPLToTXT()
	Local nX	:= 0

	oFile := FWFileWriter():New("c:\temp\ZPL.txt", .T.)

	If oFile:Exists()
		oFile:Erase()
	EndIf

	//Se houve falha ao criar, mostra a mensagem
	If ! oFile:Create()
		MsgStop("Houve um erro ao gerar o arquivo: " + CRLF + oFWriter:Error():Message, "Atenção")
	Else
		For nX := 1 to Len(aZPL)
			oFile:Write(aZPL[nX] + CRLF)
		next nX

		oFile:Close()
	Endif

return
