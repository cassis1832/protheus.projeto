#include "totvs.ch"
#Include "MSOLE.CH"

//-------------------------------------------------------------------
/*/{Protheus.doc} PL120
	Etiqueta da Kanjiko
	@author  Carlos Assis
	@since   09/07/2024
	@version 1.0
/*/
//-------------------------------------------------------------------
User Function PL120(cOp)
	Local aArea     := GetArea()

	Local aPergs    := {}
	Local aResps	:= {}
	Local cSql 	    := ""

	Private cAliasOrd, cAliasItem
	Private cOrdem		:= cOp
	Private cProduto	:= ""
	Private nNumEtq 	:= 0
	Private nQtdeEmb	:= 0

	if cOrdem == nil .or. cOrdem == ""
		aAdd(aPergs, {1, "Numero da Ordem"			, Space(11),,,"SC2",, 60, .F.})
		aAdd(aPergs, {1, "Codigo do Item"			, CriaVar("C2_PRODUTO",.F.),,,"SB1",, 60, .F.})
		aAdd(aPergs, {1, "Numero de Etiquetas"		, nNumEtq, "@E 999", "Positivo()", "", ".T.", 40,  .F.})
		aAdd(aPergs, {1, "Quantidade por Etiqueta"	, nQtdeEmb, "@E 99,999", "Positivo()", "", ".T.", 40,  .F.})

		If ParamBox(aPergs, "Parametros", @aResps,,,,,,,, .T., .T.)
			cOrdem    := aResps[1]
			cProduto  := aResps[2]
			nNumEtq   := aResps[3]
			nQtdeEmb  := aResps[4]
		Else
			return
		endif
	else
		aAdd(aPergs, {1, "Numero de Etiquetas"		, nNumEtq, "@E 999", "Positivo()", "", ".T.", 40,  .F.})
		aAdd(aPergs, {1, "Quantidade por Etiqueta"	, nQtdeEmb, "@E 99,999", "Positivo()", "", ".T.", 40,  .F.})

		If ParamBox(aPergs, "Parametros", @aResps,,,,,,,, .T., .T.)
			nNumEtq   := aResps[1]
			nQtdeEmb  := aResps[2]
		Else
			return
		endif
	endif

	if len(cOrdem) == 6
		cOrdem := cOrdem + "01001"
	endif

	// LER OP E ITEM
	if allTrim(cOrdem) != "" .AND. cOrdem != nil .AND. cOrdem != "0"
		cSql := "SELECT C2_NUM, C2_ITEM, C2_SEQUEN, C2_PRODUTO, C2_QUANT, C2_DATPRF "
		cSql += "  FROM " + RetSQLName("SC2") + " SC2 "
		cSql += " WHERE C2_NUM 			= '" + Substr(cOrdem,1,6) + "'"
		cSql += "   AND C2_ITEM			= '" + Substr(cOrdem,7,2) + "'"
		cSql += "   AND C2_SEQUEN		= '" + Substr(cOrdem,9,3) + "'"
		cSql += "   AND C2_FILIAL 		= '" + xFilial("SC2") + "' "
		cSql += "	AND SC2.D_E_L_E_T_ 	= ' ' "
		cAliasOrd := MPSysOpenQuery(cSql)

		if (cAliasOrd)->(EOF())
			Alert("ORDEM DE PRODUCAO NAO ENCONTRADA")
			return
		endif

		cProduto := (cAliasOrd)->C2_PRODUTO

		(cAliasOrd)->(DBCLOSEAREA())
	endif

	cSql := "SELECT B1_COD, B1_XPROJ, A7_CODCLI  "
	cSql += "  FROM " + RetSQLName("SB1") + " SB1 "
	cSql += " INNER JOIN " + RetSQLName("SA7") + " SA7 "
	cSql += "    ON A7_PRODUTO      = B1_COD "
	cSql += " WHERE B1_COD 			= '" + cProduto + "'"
	cSql += "   AND A7_CLIENTE 		>='" + "000001" + "' "
	cSql += "   AND A7_CLIENTE 		<='" + "000002" + "' "
	cSql += "   AND B1_FILIAL 		= '" + xFilial("SB1") + "' "
	cSql += "   AND A7_FILIAL 		= '" + xFilial("SA7") + "' "
	cSql += "	AND SB1.D_E_L_E_T_ 	= ' ' "
	cSql += "	AND SA7.D_E_L_E_T_ 	= ' ' "
	cAliasItem := MPSysOpenQuery(cSql)

	if (cAliasItem)->(EOF())
		Alert("ITEM NAO ENCONTRADO OU NAO PERTENCE A KANJIKO!")
		return
	endif

	etiqueta()

	(cAliasItem)->(DBCLOSEAREA())

	RestArea(aArea)
RETURN


/*/{Protheus.doc} ETQPROC
Impressão via impressora termica ZEBRA
@author  Carlos Assis
@since   20/05/2024
@version 1.0
/*/
Static Function Etiqueta()
	Local nX        := 0

	Private aZPL	:= {}

	if nNumEtq = 1
		cMensagem := "SERA IMPRESSA <strong>" + cValToChar(nNumEtq) + " ETIQUETA.</strong>"
	else
		cMensagem := "SERAO IMPRESSAS <strong>" + cValToChar(nNumEtq) + " ETIQUETAS.</strong>"
	endif

	If ! FWAlertYesNo(cMensagem, "CONFIRMA A IMPRESSAO?")
		return
	EndIf

	For nX := 1 to nNumEtq
		aAdd(aZPL, "CT~~CD,~CC^~CT~")
		aAdd(aZPL, "^XA" )
		aAdd(aZPL, "~TA000" )
		aAdd(aZPL, "~JSN" )
		aAdd(aZPL, "^LT0^MNW^MTT^PON^PMN^LH0,0^JMA^PR4,4~SD30^JUS^LRN^CI27^PA0,1,1,0^XZ" )
		aAdd(aZPL, "^XA^MMT^PW799^LL599^LS0" )

		aAdd(aZPL, "^FO80,25^BY3")
		aAdd(aZPL, "^BCN,70,Y,N,N")
		aAdd(aZPL, "^FD" + (cAliasItem)->A7_CODCLI + "^FS")

		// GB --> FOLeft,top ---   GBwidth,high,dots
		aAdd(aZPL, "^FO20,130^GB760,66,1^FS")
		aAdd(aZPL, "^FT30,150^A0,15^FD" + "PRODUTO" + "^FS")
		aAdd(aZPL, "^FT210,185^A0,55^FD" + (cAliasItem)->A7_CODCLI + "^FS")

		aAdd(aZPL, "^FO20,210^GB270,86,1^FS")
		aAdd(aZPL, "^FT30,230^A0,15^FDFORNECEDOR^FS")
		aAdd(aZPL, "^FT30,280^A0,30^FD" + "METALREZENDE" + "^FS")
		aAdd(aZPL, "^FO295,210^GB270,86,1^FS")
		aAdd(aZPL, "^FT300,230^A0,15^FDCLIENTE^FS")
		aAdd(aZPL, "^FT305,280^A0,30^FD" + "KANJIKO DO BRASIL" + "^FS")
		aAdd(aZPL, "^FO570,210^GB210,86,1^FS")
		aAdd(aZPL, "^FT575,230^A0,15^FDPRATELEIRA^FS")
		aAdd(aZPL, "^FT570,280^A0,48^FD" + "" + "^FS")

		aAdd(aZPL, "^FO20,312^GB250,86,1^FS")
		aAdd(aZPL, "^FT30,330^A0,15^FD" + "DATA INSPECAO / R.E." + "^FS")
		aAdd(aZPL, "^FT30,380^A0,40^FD" + "" + "^FS")
		aAdd(aZPL, "^FO275,312^GB260,86,1^FS")
		aAdd(aZPL, "^FT285,330^A0,15^FD" + "DATA EXPEDICAO" + "^FS")
		aAdd(aZPL, "^FT285,380^A0,40^FD" + "" + "^FS")
		aAdd(aZPL, "^FT570,345^A0,30^FD" + "INSPECIONADO" + "^FS")
		aAdd(aZPL, "^FT630,380^A0,30^FD" + "100%" + "^FS")

		aAdd(aZPL, "^FO20,415^GB220,130,1^FS")
		aAdd(aZPL, "^FT30,430^A0,15^FD" + "QUANTIDADE" + "^FS")
		aAdd(aZPL, "^FT30,525^A0,100^FD" + cValToChar(nQtdeEmb) + "^FS")

		aAdd(aZPL, "^FO245,415^GB250,130,1^FS")
		aAdd(aZPL, "^FT255,430^A0,15^FD" + "RATREABILIDADE" + "^FS")
		aAdd(aZPL, "^FT220,480^A0,40^FD" + "" + "^FS")

		aAdd(aZPL, "^FO500,415^GB290,36,1^FS")
		aAdd(aZPL, "^FT550,440^A0,22^FD" + "RECEBIMENTO KDB" + "^FS")
		aAdd(aZPL, "^FO500,455^GB190,86,1^FS")
		aAdd(aZPL, "^FT505,470^A0,15^FD" + "MOD. CAR." + "^FS")
		aAdd(aZPL, "^FT510,520^A0,40^FD" + "MODELO" +  "^FS")
		aAdd(aZPL, "^FO695,455^GB95,86,1^FS")
		aAdd(aZPL, "^FT700,470^A0,15^FD" + "ENDERECO" + "^FS")
		aAdd(aZPL, "^FT720,520^A0,40^FD" + "B" +  "^FS")

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
