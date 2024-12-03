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
	Local cOrdemDe	:= 0
	Local cQuery 	:= ""

	AAdd(aPergs, {1, "Número da Ordem", CriaVar("C2_NUM",.F.),,,"SC2",, 50, .F.})

	If ParamBox(aPergs, "Parâmetros do relatório", @aResps,,,,,,,, .T., .T.)
		cOrdemDe    := aResps[1]
	Else
		return
	endif

	// LER OP E ITEM
	cQuery := "SELECT C2_NUM, C2_ITEM, C2_SEQUEN, C2_PRODUTO, C2_QUANT, "
	cQuery += "       B1_COD, B1_DESC, B1_UM, B1_XCLIENT, B1_XPROJ, B1_XQEMB "
	cQuery += "  FROM " + RetSQLName("SC2") + " SC2 "
	cQuery += " INNER JOIN " + RetSQLName("SB1") + " SB1 "
	cQuery += "    ON C2_PRODUTO = B1_COD "
	cQuery += " WHERE C2_FILIAL = '" + xFilial("SC2") + "' "
	cQuery += "   AND B1_FILIAL = '" + xFilial("SB1") + "' "
	cQuery += "   AND C2_NUM BETWEEN '" + cOrdemDe + "' AND '" + cOrdemDe + "' "
	cQuery += "	  AND SC2.D_E_L_E_T_ = ' ' "
	cQuery += "	  AND SB1.D_E_L_E_T_ = ' ' "

	cAliasOrd := MPSysOpenQuery(cQuery)

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
	Local nQtde     := 1
	Local nUltima   := (cAliasOrd)->C2_QUANT
	Local nX        := 0

	if (cAliasOrd)->B1_XQEMB != 0
		nQtde := NoRound((cAliasOrd)->C2_QUANT / (cAliasOrd)->B1_XQEMB, 0)
		nUltima := (cAliasOrd)->C2_QUANT - ((nQtde - 1) * (cAliasOrd)->B1_XQEMB )
	endif

	// Alert("nQtde=" + cValToChar(nQtde))
	// Alert("nUltima=" +  cValToChar(nUltima))

	cMensagem := "Serão impressas <strong>" + cValToChar(nQtde) + " etiquetas.</strong>"
	If ! FWAlertYesNo(cMensagem, "Confirma a impressão?")
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
		MSCBWrite("^LT0" + ENTER)
		MSCBWrite("^MNW" + ENTER)
		MSCBWrite("^MTT" + ENTER)
		MSCBWrite("^PON" + ENTER)
		MSCBWrite("^PMN" + ENTER)
		MSCBWrite("^LH0,0" + ENTER)
		MSCBWrite("^JMA" + ENTER)
		MSCBWrite("^PR4,4" + ENTER)
		MSCBWrite("~SD30" + ENTER)
		MSCBWrite("^JUS" + ENTER)
		MSCBWrite("^LRN" + ENTER)
		MSCBWrite("^CI27" + ENTER)
		MSCBWrite("^PA0,1,1,0" + ENTER)
		MSCBWrite("^XZ" + ENTER)
		MSCBWrite("^XA" + ENTER)
		MSCBWrite("^MMT" + ENTER)
		MSCBWrite("^PW799" + ENTER)
		MSCBWrite("^LL599" + ENTER)
		MSCBWrite("^LS0" + ENTER)
		MSCBWrite("^FO16,408^GB767,96,2^FS" + ENTER)
		MSCBWrite("^FO527,311^GB256,80,2^FS" + ENTER)
		MSCBWrite("^FO607,215^GB176,80,2^FS" + ENTER)
		MSCBWrite("^FO431,215^GB160,80,2^FS" + ENTER)
		MSCBWrite("^FO309,511^GFA,689,4320,60,:Z64:eJzt1j2unDAQAOBBFC59BB/FR/OmyrGe0RavfEeIoxSvdfcoHCYzY+wFFrOkiRSJ2V2LH38CPGOzAFdcccX/GhYRb2CocR5scLSr6Id0BO/oOxxoI2IEjaAQOtpLSj7FcuPC1g4YZuvITvu2FxvPWz1Vq/atx1jsCKZhtdixbS3ZtG+N2PRk3fjaSuOmJ2urZbKwBqt1LZtmy3vjkwXo+Xa5QbLAHYAHhrp5M20tn1tbjGJv1dpUrQdwUf+FpTFnq3Fh48Ja/F5tEOurpY4n7bfZhmI7DGIVnRKrDqwXG4vtWXR8dHjYcM4qmh7Z/ty37u2dLD/JbH+MNnAyIM83yi9IQ7ZHmK2T/D7Zj1Ss1D0zW+2NNk5Zm7LtynU7GbQD+z4V68ZsVcui+VzbOxYr+UDOb7UDDd8Z28m4EDPFwis74Fu2vdwfz6OHvR9bTzkUq6Tf2v5CeNjfk/5a16R3mGtDSw1Qbbg01zO4YqU2Fva2sTx7sx2r/Xxh7WxtKjYWa7+mlpX5S8OaLc/eQ4v8LXZcWZ69p62bxOpsZfZuxspw3601j3WSSjBwVvgNk6SkXM0RW94Lsk4urW1Y27L0jMXmi1OBNK2mZfLQdltrTtj8HqRlomlV0/YNqxc2Li3lrliYrdvY/ow15f/G2nL3bPs9e8UVV1zxL+MP8+/0KQ==:38C6" + ENTER)
		MSCBWrite("^FO698,480^GFA,125,228,12,:Z64:eJxjYCANyDc8qGP/8KfggQUDg/2BB//5P/6zALEtHzw8PK/wvAyIXQBkzyluR2bzP/4BZ9s/R7AtniP0gtn2x/8e7v/4D6yGv/3v4fYPNfIgvZQAAPEzPcY=:22E8" + ENTER)
		MSCBWrite("^FO709,367^GFA,117,228,12,:Z64:eJxjYCAN1De389XP+ScPZfcB2fYNQDZzc/s55jl8lQcQbEMQ2765/Z39HD5GKLsOxgaqsYOpgbKrQez6+d/l6ufwgc0EsoF28cmT6EQMAADzJSTt:B2B3" + ENTER)
		MSCBWrite("^FO733,270^GFA,89,152,8,:Z64:eJxjYMAPHjw8zi5/AELbA+n6g4f/VULpQiBdePBwH4i2bjx4B5m2bzz4B6ROnv/HD3soDTKHWAAAoZ8kAQ==:34EC" + ENTER)
		MSCBWrite("^FO271,311^GB240,80,2^FS" + ENTER)
		MSCBWrite("^FO16,311^GB240,80,2^FS" + ENTER)
		MSCBWrite("^FO371,366^GFA,229,380,20,:Z64:eJyt0CEOwyAUBmCmcK8XIOEaLBO9UhlpmFkQ8z3BDjKPqKMXaDKq6haaGcRC9gAxNddffsn/3ssjZN/41zIzOGsKdIzN+9EVk2garVnR7tmMO04RtErAvCBq+FmfjQjSQTbpuBOpVwPwW6SBBrTTYEaZrtsM1KLxanKULtsB53Usd1u0De1TdlTjYOySLiGaJ95Suxxa64tNeHNows4/+ZcvJDpXBQ==:B8FF" + ENTER)
		MSCBWrite("^FO164,366^GFA,161,228,12,:Z64:eJxjYCANPHj884898wP55wUPGB48//mnvv2D/HOLBwz15y1kis8VMDyXAbLPWcg8PAdUC2QXgtjnD/A/4H/AYN0HZB8Gsuyh7AMfGB4A9dr3Q/SC2PLsP2Tq+z/Ig9TIM/+QkWd/IA+EJLoSFQAA60k49A==:1026" + ENTER)
		MSCBWrite("^FO239,215^GB176,80,2^FS" + ENTER)
		MSCBWrite("^FO16,215^GB208,80,2^FS" + ENTER)
		MSCBWrite("^FO431,119^GB352,80,2^FS" + ENTER)
		MSCBWrite("^FO248,119^GB176,80,2^FS" + ENTER)
		MSCBWrite("^FO464,23^GB319,80,2^FS" + ENTER)
		MSCBWrite("^FO16,23^GB171,80,2^FS" + ENTER)
		MSCBWrite("^FO499,270^GFA,133,228,12,:Z64:eJxjYCAN1BcU/uCzsGB4+APELv4DYj/+w8DAbv+cj0/+A8PjeQj2cz4g2wLIlingB7Nlj/Px8T2QR2LLgNnyQDb/AxmwXv52vvrjB+TBZkLY/A9+kOhINAAAIA4mTg==:C723" + ENTER)
		MSCBWrite("^FO337,270^GFA,129,228,12,:Z64:eJxjYCANMLc/kJGpsyiQAbH7P/BZ/JeBsPsq2Aue90HYcyzYPx6GsO3nWDA/PNz+8Q+QXQ9mz/8MYheD1cwpngNig/VC2PVgM+XBauybgXbZ8YP1UgIAkbkqyw==:7389" + ENTER)
		MSCBWrite("^FO72,258^GFA,221,512,16,:Z64:eJzFzzsOwjAMAFCjDB1zBN8kvlhEwwm4UrdeIxUDa6oOeIhs4rRC9ALgxXqSvwC/DccQB82U6MYBELx0j5PmbtRuXbRUM2nqfijHbkwR3LJtKwfz1U/m9ZUrhcGad89TRPG7nS6lJRI8eRQ6WYXw2zWEz/wy5MrmY39xK3Mgu++uz1bvlNXmofrui5bR9nnZDe1Hs+PDlFDavf+ON1pMjR0=:1DC4" + ENTER)
		MSCBWrite("^FO723,175^GFA,117,152,8,:Z64:eJxjYMAPHh7+IGN/+AFD4fEfMvbHPzBYHreRYTxXwGB5TgZIMzDIA2n58wcY6kE0SB1I/MAHoHqIuvrjP/7vP/+Bwf7gh//7jz8gYBsCAAA3LySb:A922" + ENTER)
		MSCBWrite("^FO351,175^GFA,97,152,8,:Z64:eJxjYMAP5Nv5Hh7+IMNgf7yv8PgPGQbL5+csz8nIMBTA6XfyELquHkLbFYJoSyhtf1wOKP6/gb+dzx5EE7AODgDBPiHT:9E7E" + ENTER)
		MSCBWrite("^FO718,26^GFA,169,576,8,:Z64:eJzF0TEOQEAQheHXKbU6V1AqNtkrEYUtZLmb1hEUo9pbYJbFBgkVr/nayT/AX4tWSAAZsfpQWacHDVCxw26z2l7VhMAZOuM7a4L0TJyqJAhn6tmdLXzNouD7rJI2J3T5Ybw7ol/UUJvcI+Q+Vtsr+fpFLzYDNQGIzA==:B2DA" + ENTER)
		MSCBWrite("^FO67,79^GFA,189,304,16,:Z64:eJxjYCAbMIGI+vbv7PLn+GSsm/sP/wHx+7+z25/jk7Nunv/wH5DPPK/4X+U5PnnL/xbF70H8OcX/CqH85UC+/ZziPhB/53GL4nYwv/AOkC/74x2Ezwzhy8D58wr/VIL4/yyKz4Pt+/DD/lz9nYoai8J/YPd8+CEP5FvUWBT8Id9vOAEANl9CkA==:D359" + ENTER)
		MSCBWrite("^FO42,518^GFA,497,1760,32,:Z64:eJztk0FuwyAQRbGQyq4cgZuUo9lRFl3mSo56EaRcgCULxO8fDIZW3VbZhMgxnmfGzJ+PUq/x1OGSUmtQpigPbLqoOo2WYWzka1ELsnLYhfPG6eZS5wuDBlAronCPwGkYXAO7JQCScL6mAGbvnGuDAy6N88aMyebOuTaS34Hs62uZGfPEs48+4gs2M3DBJ7nNpnTukks+rI/CqoRrTuR3cu7FB/8oUjmuwrMuzNE4lcgzX5hdy3/nwXAHLFO0xPYhZCG/JdbZeSEPlb8dnBolc3KHsKBQVwYGtxPPFGWfeNXo5JaLDxk7p0bJnZxPbG6cuPnBZae2BQanqp1bdh154qK/D00fUWJXVf/tvepTpL8HF31dXO8wtT/l0Hfi7M/g19afwaW/LrH/t7m/9fux+4PX/ssfzU6Hvyb/NX+N+sWfk3+bPwcXf2vI4QiTv/Wp/9/no31DuIsiotLT+WIla93H9s9n+zWePr4BoQ3mJQ==:DBB6" + ENTER)
		MSCBWrite("^FT765,131^A0I,48,58^FH\^CI28^FD"+AllTrim("ESTAMPARIA")+"^FS^CI27" + ENTER)
		MSCBWrite("^FO337,23^GB113,80,2^FS" + ENTER)
		MSCBWrite("^FO205,23^GB125,80,2^FS" + ENTER)
		MSCBWrite("^FO19,119^GB205,80,2^FS" + ENTER)
		MSCBWrite("^FO35,175^GFA,281,456,24,:Z64:eJy10LEKglAUgOEbBS3SExi+QA+gFPoiPUKL3KFRWryL6AsYvkZtxh1c5AjNYoiDqyKUF8y6V3Ru6sBZvuE/cBD63yz4LtcZdmNoTmGv+CajtlR4pBIOwjF3w8eMEqkIaMv9DbgffIWDl0aJ87mUKUJzFpldBlvhXqlR27HUcs/9GtVpBoYX9tgVHh/VUhae1OkdrGDyw+Rgpg3gM+8MvhmdgdmNPvR3vO8jNKuTqs2HjkEoezxlXS1a4ZFwcVchN+6SrubVH5/5Y75TlYV1:133E" + ENTER)
		MSCBWrite("^FO346,77^GFA,161,216,12,:Z64:eJxjYCAFMDHU85+z+PPwMFvh8cM/6uXPWQLZbYXnH/5htzz/e87Dw8fq7xS/Y7c8/hnIfmY/p3hdveXxYiC7zHpOcR8ymx3CtoOyQerlgOrP1csffvjn/W8+eZnCP/X8hx8A2WzyMgU/SHImEAAAostE4g==:2C81" + ENTER)
		MSCBWrite("^FO210,79^GFA,189,304,16,:Z64:eJxjYCAbMIGI+vbv7PLn+GSsm/sP/wHx+7+z25/jk7Nunv/wH5DPPK/4X+U5PnnL/xbF70H8OcX/CqH85UC+/ZziPhB/53GL4nYwv/AOkC/74x2Ezwzhy8D58wr/VIL4/yyKz4Pt+/DD/lz9nYoai8J/YPd8+CEP5FvUWBT8Id9vOAEANl9CkA==:D359" + ENTER)
		MSCBWrite("^FT758,324^A0I,51,51^FH\^CI28^FD"+AllTrim((cAliasOrd)->B1_XCLIENT)+"^FS^CI27" + ENTER)
		MSCBWrite("^FT738,428^A0I,62,94^FH\^CI28^FD"+AllTrim((cAliasOrd)->B1_COD)+"^FS^CI27" + ENTER)
		MSCBWrite("^FT709,34^A0I,69,74^FH\^CI28^FD"+AllTrim((cAliasOrd)->C2_NUM)+"^FS^CI27" + ENTER)
		MSCBWrite("^FT548,221^A0I,63,84^FH\^CI28^FD"+AllTrim("30")+"^FS^CI27" + ENTER)
		MSCBWrite("^FT337,226^A0I,63,84^FH\^CI28^FD"+AllTrim("40")+"^FS^CI27" + ENTER)

		MSCBWrite("^PQ1,0,1,Y" + ENTER)
		MSCBWrite("^XZ" + ENTER)
		MSCBEND()
	next nX

	MSCBCLOSEPRINTER()
Return nil
