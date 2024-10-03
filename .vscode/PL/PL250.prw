#Include "PROTHEUS.CH"
#Include "TBICONN.CH"
#Include "RPTDEF.CH"
#Include "FWPrintSetup.ch"
#Include "Colors.ch"

/*/{Protheus.doc}	PL250
	Impressao do plano de produção por maquina
@author Carlos Assis
@since 13/09/2024
@version 1.0   
/*/

Static oFont09 	:= TFont():New( "Arial",, -09, .T.)
Static oFont10 	:= TFont():New( "Arial",, -10, .T.)
Static oFont11 	:= TFont():New( "Arial",, -11, .T.)
Static oFont11b := TFont():New( "Arial",, -11, .T.,.T.)
Static oFont12 	:= TFont():New( "Arial",, -12, .T.)
Static oFont12b := TFont():New( "Arial",, -12, .T.,.T.)
Static oFont16b := TFont():New( "Arial",, -16, .T.,.T.)

User Function PL250()
	Local aArea   		:= GetArea()
	Local cSql			:= ""

	Local aPergs	    := {}
	Local aResps	    := {}

	Local cMaqIni   	:= ""
	Local cMaqFim   	:= ""
	Local dDtIni   		:= Date()
	Local dDtFim   		:= Date()

	Private oPrinter    := nil
	Private cAlias 		:= ""
	Private cRecurso	:= ""
	Private dData		:= Stod("20010101")

	Private cFilePrint  := ""
	Private nLin 	    := 0
	Private cDir        := "c:\temp\"  		// Local do relatorio

	AAdd(aPergs, {1, "Informe a data inicial "	, CriaVar("C2_DATPRI",.F.),"",".T.","",".T.", 70, .T.})
	AAdd(aPergs, {1, "Informe a data final "	, CriaVar("C2_DATPRI",.F.),"",".T.","",".T.", 70, .T.})
	AAdd(aPergs, {1, "Maquina inicial"			, CriaVar("H1_CODIGO",.F.),,,"SH1",, 60, .F.})
	AAdd(aPergs, {1, "Maquina final"			, CriaVar("H1_CODIGO",.F.),,,"SH1",, 60, .T.})

	If ParamBox(aPergs, "EMISSAO DO PLANO DE PRODUCAO", @aResps,,,,,,,, .T., .T.)
		dDtIni  	:= aResps[1]
		dDtFim  	:= aResps[2]
		cMaqIni  	:= aResps[3]
		cMaqFim  	:= aResps[4]
	Else
		return
	endif

	cFilePrint	:= "PL250" + "-" + DToS(dDtIni) + "-" + DToS(dDtFim) + "-"
	cFilePrint	+= DToS(Date()) + StrTran(Time(),":","") + ".pdf"

	oPrinter := FWMSPrinter():New(cFilePrint,	IMP_PDF,.F.,cDir,.T.,,,,.T.,.F.,,.T.)
	oFont1 := TFont():New('Courier new',,-18,.T.)
	oPrinter:SetParm( "-RFS")
	oPrinter:cPathPDF := cDir 			// Se for usado PDF e fora de rotina agendada
	oPrinter:SetPortrait()
	oPrinter:SetPaperSize(DMPAPER_A4)
	oPrinter:SetMargin(40,40,40,40) 	// nEsquerda, nSuperior, nDireita, nInferior

	SH1->(DBSetOrder(1))
	SH1->(DbSeek(xFilial("SH1")))

	While ! SH1->(EoF())
		if Upper(AllTrim(SH1->H1_CODIGO)) >= Upper(AllTrim(cMaqIni)) .AND. ;
				Upper(AllTrim(SH1->H1_CODIGO)) <= Upper(AllTrim(cMaqFim))

			dDia := dDtIni

			While dDia <= dDtFim
				cSql := "SELECT ZA2.* FROM " + RetSQLName("ZA2") + " ZA2 "

				cSql += " INNER JOIN " + RetSQLName("SC2") + " SC2 "
				cSql += "	 ON C2_NUM+C2_ITEM+C2_SEQUEN = ZA2_OP"
				cSql += " 	AND C2_TPOP 	   	 = 'F'"		// Firme
				cSql += "   AND C2_DATRF   		 = ''"		// Aberta
				cSql += "   AND C2_FILIAL 	 	 = '" + xFilial("SC2") + "'"
				cSql += "	AND SC2.D_E_L_E_T_ 	 = ' ' "

				cSql += " WHERE ZA2_RECURS 		 = '" + SH1->H1_CODIGO 	+ "'"
				cSql += "   AND ZA2_TIPO         = '1'"
				cSql += "   AND ZA2_STAT         = 'L'"
				cSql += "   AND ZA2_DTINIP      <= '" + dtos(dDia) 				+ "'"
				cSql += "   AND ZA2_DTFIMP      >= '" + dtos(dDia) 				+ "'"
				cSql += "   AND ZA2_FILIAL 		 = '" + xFilial("ZA2") 			+ "'"
				cSql += "	AND ZA2.D_E_L_E_T_ 	 = ' ' "
				cSql += " ORDER BY ZA2_DTINIP, ZA2_HRINIP, ZA2_DTFIMP, ZA2_HRFIMP "
				cAlias := MPSysOpenQuery(cSql)

				While (cAlias)->(! EOF())

					if (cRecurso != (cAlias)->ZA2_RECURS)
						cRecurso := (cAlias)->ZA2_RECURS
						printCabec()
					else
						if nLin > 700
							printCabec()
						endif
					endif

					if dData != dDia
						nLin += 50
						dData := dDia

						oPrinter:Line(nLin-17, 15, nLin-17, 550)
						oPrinter:Say(nLin, 220, DTOC(dDia), oFont16b)
						oPrinter:Line(nLin+3, 15, nLin+3, 550)
					endif

					nLin +=35
					oPrinter:Say(nLin, 15, "Cod. Item:" ,oFont10)
					oPrinter:Say(nLin, 70, (cAlias)->ZA2_PROD, oFont12b)

					oPrinter:Say(nLin, 155, "Descricao:",oFont10)
					oPrinter:Say(nLin, 215, (cAlias)->ZA2_ITCLI, oFont12b)

					oPrinter:Say(nLin, 360, "Quantidade:",oFont10)
					if (cAlias)->ZA2_QUANT - int((cAlias)->ZA2_QUANT) == 0
						oPrinter:Say(nLin, 420, TRANSFORM((cAlias)->ZA2_QUANT, "@E 999,999"), oFont12b)
					else
						oPrinter:Say(nLin, 420, TRANSFORM((cAlias)->ZA2_QUANT, "@E 999,999.999"), oFont12b)
					endif

					oPrinter:Box(nLin-10, 520, nLin+5, 540)		   // Box(row, col, bottom, right)

					nLin +=20
					oPrinter:Say(nLin, 15, "Ordem:",oFont10)
					oPrinter:Say(nLin, 70, (cAlias)->ZA2_OP, oFont11b)

					oPrinter:Say(nLin, 155, "Data:",oFont10)
					oPrinter:Say(nLin, 215, DTOC(Stod((cAlias)->ZA2_DTINIP)) + " - " + DTOC(Stod((cAlias)->ZA2_DTFIMP)), oFont11b)

					oPrinter:Say(nLin, 360, "Duracao:",oFont10)
					oPrinter:Say(nLin, 420, TRANSFORM((cAlias)->ZA2_HSTOT, "@E 999,999.999"), oFont12b)

					oPrinter:Box(nLin-10, 520, nLin+5, 540)		   // Box(row, col, bottom, right)

					nLin +=20
					oPrinter:Say(nLin, 15, "Cliente:",oFont10)
					oPrinter:Say(nLin, 70, (cAlias)->ZA2_CLIENT, oFont10)

					(cAlias)->(DbSkip())
				enddo

				dDia = daySum(dDia, 1)
				(cAlias)->(DBCLOSEAREA())
			enddo
		endif

		SH1->(DbSkip())
	enddo

	oPrinter:EndPage()

	//Gera e abre o arquivo em PDF
	oPrinter:Preview()
	FreeObj(oPrinter)
	oPrinter := nil

	Sleep(1000)

	RestArea(aArea)
Return

//-----------------------------------------------------------------------------
//	Imprime o cabecalho 
//-----------------------------------------------------------------------------
Static Function printCabec()
	oPrinter:StartPage()
	oPrinter:Box(20,15,60,550)		    // Box(row, col, bottom, right)

	nLin := 40
	oPrinter:SayBitmap(nLin-15, 20, "\images\logo.png", 130, 30)
	oPrinter:Say(nLin+5, 190,"PLANO DE PRODUCAO",oFont16b)

	oPrinter:Line(nLin-20, 400, 60, 400)
	oPrinter:Say(nLin-5, 445,"Maquina",oFont10)
	oPrinter:Say(nLin-5 + 17, 440, cRecurso , oFont16b)

	nLin += 10

	dData := Stod("20010101")
Return
