#include "totvs.ch"
#include "MSOLE.CH"

//-------------------------------------------------------------------
/*/{Protheus.doc} ETQPROC
Etiqueta de Processo
@author  Carlos Assis
@since   20/05/2024
@version 1.0
/*/
//-------------------------------------------------------------------
User Function ETQPROC()
	Local aArea     := GetArea()
	Local aPergs    := {}
	Local aResps	:= {}
	Local cSql 	    := ""

	Local cOrdem	:= 0
	Private nNumEtq := 0
	PRivate nQtdeEmb:= 0

	aAdd(aPergs, {1, "Numero da Ordem", CriaVar("C2_NUM",.F.),,,"SC2",, 50, .F.})
	aAdd(aPergs, {1, "Numero de Etiquetas", nNumEtq, "@E 999", "Positivo()", "", ".T.", 80,  .F.})
	aAdd(aPergs, {1, "Quantidade por Etiqueta", nQtdeEmb, "@E 99,999", "Positivo()", "", ".T.", 80,  .F.})

	If ParamBox(aPergs, "Parametros", @aResps,,,,,,,, .T., .T.)
		cOrdem    := aResps[1]
	Else
		return
	endif

	// LER OP E ITEM
	cSql := "SELECT C2_NUM, C2_ITEM, C2_SEQUEN, C2_PRODUTO, C2_QUANT, "
	cSql += "       B1_COD, B1_DESC, B1_UM, B1_XCLIENT, B1_XPROJ, B1_XQEMB "
	cSql += "  FROM " + RetSQLName("SC2") + " SC2 "
	cSql += " INNER JOIN " + RetSQLName("SB1") + " SB1 "
	cSql += "    ON C2_PRODUTO = B1_COD "
	cSql += " WHERE C2_FILIAL = '" + xFilial("SC2") + "' "
	cSql += "   AND B1_FILIAL = '" + xFilial("SB1") + "' "
	cSql += "   AND C2_NUM BETWEEN '" + cOrdem + "' AND '" + cOrdem + "' "
	cSql += "	  AND SC2.D_E_L_E_T_ = ' ' "
	cSql += "	  AND SB1.D_E_L_E_T_ = ' ' "

	cAliasOrd := MPSysOpenQuery(cSql)

	if (cAliasOrd)->(EOF())
		Alert("Ordem de Produção não encontrada")
	endif

	etqproci(cAliasOrd)

	RestArea(aArea)
RETURN


/*/{Protheus.doc} ETQPROC
Impressão via impressora termica ZEBRA
@author  Carlos Assis
@since   20/05/2024
@version 1.0
/*/
Static Function etqproci(cAliasOrd)
	Local cPorta    := "LPT1"
	Local cFila     := "ETQPROC"
	Local ENTER		:= Chr(13)+Chr(10)
	Local nQtde     := 0
	Local nUltima   := (cAliasOrd)->C2_QUANT
	Local nX        := 0

	if nNumEtq <> 0
		nQtde := nNumEtq
	else
		if nQtdeEmb <> 0
			nQtde := NoRound((cAliasOrd)->C2_QUANT / nQtdeEmb, 0)
			nUltima := (cAliasOrd)->C2_QUANT - ((nQtde - 1) * nQtdeEmb )
		else
			if (cAliasOrd)->B1_XQEMB != 0 .and. (cAliasOrd)->C2_QUANT > (cAliasOrd)->B1_XQEMB
				nQtde := NoRound((cAliasOrd)->C2_QUANT / (cAliasOrd)->B1_XQEMB, 0)
				nUltima := (cAliasOrd)->C2_QUANT - ((nQtde - 1) * (cAliasOrd)->B1_XQEMB )
			else
				nQtde := 1
				nUltima := 1
			endif
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

	MSCBPRINTER("ZEBRA", cPorta ,,,.F.,,,,40000 , cFila, .F.)
	MSCBCHKSTATUS(.F.)

	For nX := 1 to nQtde
		MSCBINFOETI("VOLUMES","7X10")
		MSCBWrite("CT~~CD,~CC^~CT~" + ENTER)
		MSCBWrite("^XA" + ENTER)
		MSCBWrite("~TA000" + ENTER)
		MSCBWrite("~JSN" + ENTER)
		MSCBWrite("^LT0^MNW^MTT^PON^PMN^LH0,0^JMA^PR4,4~SD30^JUS^LRN^CI27^PA0,1,1,0^XZ" + ENTER)
		MSCBWrite("^XA^MMT^PW799^LL599^LS0" + ENTER)

		MSCBWrite("^FT10,70^ADN,60,25^FDMETALREZENDE^FS" + ENTER)
		MSCBWrite("^FT500,70^ADN,40,25^FDPROCESSO^FS" + ENTER)

		MSCBWrite("^FO10,108^GB450,96,2^FS" + ENTER)
		MSCBWrite("^FT20,130^ADN,1,2^FDItem^FS" + ENTER)
		MSCBWrite("^FT20,180^ADN,36,20^FD71584-BW000 (R)^FS" + ENTER)
		MSCBWrite("^FO470,108^GB320,96,2^FS" + ENTER)
		MSCBWrite("^FT540,180^ADN,36,20^FD10101040^FS" + ENTER)

		MSCBWrite("^FO10,208^GB260,96,2^FS" + ENTER)
		MSCBWrite("^FT20,230^ADN,1,2^FDCliente^FS" + ENTER)
		MSCBWrite("^FT20,280^ADN,36,20^FDGESTAMP^FS" + ENTER)

		MSCBWrite("^FO275,208^GB260,96,2^FS" + ENTER)
		MSCBWrite("^FT285,230^ADN,1,2^FDData^FS" + ENTER)
		MSCBWrite("^FT285,280^ADN,28,16^FD18/12/2024^FS" + ENTER)

		MSCBWrite("^FO540,208^GB250,96,2^FS" + ENTER)
		MSCBWrite("^FT550,230^ADN,1,2^FDOP^FS" + ENTER)
		MSCBWrite("^FT570,280^ADN,28,16^FD888.888^FS" + ENTER)

		MSCBWrite("^FO10,308^GB260,96,2^FS" + ENTER)
		MSCBWrite("^FT20,330^ADN,1,2^FDOper.Atual^FS" + ENTER)
		MSCBWrite("^FT20,380^ADN,36,20^FD030^FS" + ENTER)
		MSCBWrite("^FO275,308^GB260,96,2^FS" + ENTER)
		MSCBWrite("^FT285,330^ADN,1,2^FDProx.Oper^FS" + ENTER)
		MSCBWrite("^FT285,380^ADN,28,16^FDSOLDA^FS" + ENTER)
		MSCBWrite("^FO540,308^GB250,96,2^FS" + ENTER)
		MSCBWrite("^FT550,330^ADN,1,2^FDTurno^FS" + ENTER)
		MSCBWrite("^FT570,380^ADN,28,16^FD^FS" + ENTER)

		MSCBWrite("^FO10,408^GB190,96,2^FS" + ENTER)
		MSCBWrite("^FT20,430^ADN,1,2^FDQtde 1^FS" + ENTER)
		MSCBWrite("^FT20,480^ADN,36,20^FD^FS" + ENTER)
		MSCBWrite("^FO205,408^GB190,96,2^FS" + ENTER)
		MSCBWrite("^FT215,430^ADN,1,2^FDQtde 2^FS" + ENTER)
		MSCBWrite("^FT220,480^ADN,28,16^FD^FS" + ENTER)
		MSCBWrite("^FO405,408^GB190,96,2^FS" + ENTER)
		MSCBWrite("^FT415,430^ADN,1,2^FDQtde 3^FS" + ENTER)
		MSCBWrite("^FT570,480^ADN,28,16^FD^FS" + ENTER)
		MSCBWrite("^FO600,408^GB190,96,2^FS" + ENTER)
		MSCBWrite("^FT610,430^ADN,1,2^FDQtde 4^FS" + ENTER)
		MSCBWrite("^FT570,480^ADN,28,16^FD^FS" + ENTER)

		MSCBWrite("^PQ1,0,1,Y" + ENTER)
		MSCBWrite("^XZ" + ENTER)
		MSCBEND()
	next nX

	MSCBCLOSEPRINTER()
Return nil
