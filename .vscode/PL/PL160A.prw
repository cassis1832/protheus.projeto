#Include "PROTHEUS.CH"
#Include "RPTDEF.CH"
#Include "TBICONN.CH"
#Include 'FWMVCDef.ch'

/*/{Protheus.doc}	PL160A
	Distribuição da carga maquina
	21/08/2024 - Não alterar ordens sacramentadas
	10/09/2024 - Saboneteira com prioridade para carga máquina
@author Carlos Assis
@since 20/08/2024
@version 1.0   
/*/
User Function PL160A(Inicio, Fim, Tipo)
	Local aArea 		:= FWGetArea()
	Local aCampos 		:= {}
	Local oSay 			:= NIL

	Private	dDtIni		:= Inicio
	Private	dDtFim		:= Fim
	Private	lTipo		:= Tipo

	Private cTT1Name 	:= ""
	Private cTT2Name 	:= ""
	Private cAliasTT1 	:= GetNextAlias()
	Private cAliasTT2 	:= GetNextAlias()

	//Campos da temporária de ordens
	aAdd(aCampos, {"TT1_ID"		,"C", 36, 0})
	aAdd(aCampos, {"TT1_PRODUT"	,"C", 15, 0})
	aAdd(aCampos, {"TT1_OP"		,"C", 11, 0})
	aAdd(aCampos, {"TT1_RECURS"	,"C", 06, 0})
	aAdd(aCampos, {"TT1_DATPRI"	,"D", 08, 0})
	aAdd(aCampos, {"TT1_DATPRF"	,"D", 08, 0})
	aAdd(aCampos, {"TT1_QUANT"	,"N", 14, 3})
	aAdd(aCampos, {"TT1_QUJE"	,"N", 14, 3})
	aAdd(aCampos, {"TT1_QTHSTO"	,"N", 14, 3})
	aAdd(aCampos, {"TT1_QTHORA"	,"N", 14, 3})
	aAdd(aCampos, {"TT1_PRIOR"	,"C", 03, 0})

	oTT1 := FWTemporaryTable():New(cAliasTT1)
	oTT1:SetFields(aCampos)
	oTT1:AddIndex("1", {"TT1_ID"} )
	oTT1:AddIndex("2", {"TT1_RECURS", "TT1_DATPRI", "TT1_PRIOR"} )
	oTT1:Create()
	cTT1Name  := oTT1:GetRealName()

	//Campos da temporária de maquinas
	aCampos := {}
	aAdd(aCampos, {"TT2_ID"			,"C", 36, 0})
	aAdd(aCampos, {"TT2_RECURS"		,"C", 06, 0})
	aAdd(aCampos, {"TT2_DATA"		,"C", 08, 0})
	aAdd(aCampos, {"TT2_DISP"		,"N", 14, 3})
	aAdd(aCampos, {"TT2_USADA"		,"N", 14, 3})

	oTT2 := FWTemporaryTable():New(cAliasTT2)
	oTT2:SetFields(aCampos)
	oTT2:AddIndex("1", {"TT2_ID"} )
	oTT2:AddIndex("2", {"TT2_RECURS", "TT2_DATA"} )
	oTT2:Create()
	cTT2Name  := oTT2:GetRealName()

	FwMsgRun(NIL, {|oSay| CargaInicial(oSay)}, "Preparando o calculo ", "Preparando...")

	FwMsgRun(NIL, {|oSay| Calculo(oSay)}, "Calculando distribuicao", "Calculando...")

	oTT1:Delete()
	oTT2:Delete()

	FWRestArea(aArea)
return


Static Function CargaInicial(oSay)
	CargaTT1()
	CargaTT2()
return


/*
	Carrega tabela com as ordens de producao para calcular
*/
Static Function CargaTT1()
	Local cSql 		:= ""
	Local cAlias 	:= ""
	Local nQuant	:= 0
	Local nTotal	:= 0
	Local nSetup	:= 0
	Local cPrior	:= 0

	if lTipo == .T.
		cLinPrd := "01"
	Else
		cLinPrd := "02"
	Endif

	cSql := "SELECT C2_NUM, C2_ITEM, C2_SEQUEN, C2_PRODUTO, C2_STATUS, C2_PRIOR, B1_XPRIOR, "
	cSql += "	    C2_QUANT, C2_QUJE, C2_DATPRI, C2_DATPRF, C2_TPOP, "
	cSql += "	    G2_OPERAC, G2_RECURSO, G2_MAOOBRA, G2_SETUP, "
	cSql += "	  	G2_TEMPAD, G2_LOTEPAD, G2_XDIRESQ, "
	cSql += "	  	H1_XLIN, H1_XLOCLIN, H1_XTIPO, H1_XSETUP, H1_XNOME "
	cSql += "  FROM " + RetSQLName("SC2") + " SC2 "

	cSql += " INNER JOIN " + RetSQLName("SB1") + " SB1 "
	cSql += "	 ON B1_COD 		 	 = C2_PRODUTO"
	cSql += "   AND B1_FILIAL 	 	 = '" + xFilial("SB1") + "' "
	cSql += "	AND SB1.D_E_L_E_T_ 	 = ' ' "

	cSql += " INNER JOIN " + RetSQLName("SG2") + " SG2 "
	cSql += "    ON G2_PRODUTO 		 = C2_PRODUTO"
	cSql += "   AND G2_FILIAL		 = '" + xFilial("SG2") + "' "
	cSql += "   AND SG2.D_E_L_E_T_ 	 = ''

	cSql += " INNER JOIN " + RetSQLName("SH1") + " SH1 "
	cSql += "    ON H1_CODIGO 		 = G2_RECURSO"
	cSql += "   AND H1_LINHAPR 	 	 = '" + cLinPrd + "' "
	cSql += "   AND H1_FILIAL 	 	 = '" + xFilial("SH1") + "' "
	cSql += "   AND SH1.D_E_L_E_T_ 	 = ''

	cSql += " WHERE C2_DATPRF 	   	>= '" + dtos(dDtIni) + "'"
	cSql += "   AND C2_DATPRF	   	<= '" + dtos(dDtFim) + "'"
	cSql += "   AND C2_DATRF   		 = ''"
	cSql += "   AND C2_TPPR	   	     = 'I'"
	cSql += "   AND C2_FILIAL 	 	 = '" + xFilial("SC2") + "' "
	cSql += "	AND SC2.D_E_L_E_T_ 	 = ' ' "
	cSql += "	ORDER BY G2_RECURSO, C2_DATPRI, C2_NUM, C2_ITEM, C2_SEQUEN "
	cAlias := MPSysOpenQuery(cSql)

	While (cAlias)->(! EOF())

		// Se for direita e esquerda deve dobrar a quantidade/hora
		if (cAlias)->G2_XDIRESQ == 'S'
			nQuant := (cAlias)->C2_QUANT / ((cAlias)->G2_LOTEPAD * 2)
		else
			nQuant := (cAlias)->C2_QUANT / (cAlias)->G2_LOTEPAD
		endif

		if (cAlias)->G2_SETUP > 0
			nSetup	:= (cAlias)->G2_SETUP
		else
			if (cAlias)->H1_XSETUP > 0
				nSetup	:= (cAlias)->H1_XSETUP
			else
				nSetup	:= 0.5
			endif
		endif

		nTotal := nSetup + nQuant

		cPrior := (cAlias)->C2_PRIOR

		if (cAlias)->B1_XPRIOR <> "0"
			cPrior := (cAlias)->B1_XPRIOR
		endif

		cSql := "INSERT INTO " + cTT1Name + " ("
		cSql += " TT1_ID, TT1_PRODUT, TT1_OP, TT1_RECURS, TT1_PRIOR, "
		cSql += " TT1_DATPRI, TT1_DATPRF, TT1_QTHSTO) VALUES ('"

		cSql += FWUUIDv4() 			 				+ "','"
		cSql += (cAlias)->C2_PRODUTO 				+ "','"
		cSql += Transform((cAlias)->C2_NUM, "999999") + AllTrim((cAlias)->C2_ITEM) + AllTrim((cAlias)->C2_SEQUEN) +  "','"
		cSql += AllTrim((cAlias)->G2_RECURSO) 		+  "','"
		cSql += AllTrim(cPrior) 					+  "','"
		cSql += (cAlias)->C2_DATPRI 				+  "','"
		cSql += (cAlias)->C2_DATPRF 				+  "','"
		cSql += cValToChar(nTotal) 					+ "')"

		if TCSqlExec(cSql) < 0
			MsgInfo("Erro na execução da query:", "Atenção")
			MsgInfo(TcSqlError(), "Atenção3")
		endif

		(cAlias)->(DbSkip())
	enddo

	(cAlias)->(DBCLOSEAREA())
return


/*
	Carrega tabela com as datas do calendario e o tempo disponivel por maquina
*/
Static Function CargaTT2()
	Local cSql 			:= ""
	Local cAlias 		:= ""
	Local dData			:= Date()

	cSql := "SELECT H1_XHSDIA, H1_CODIGO  "
	cSql += "  FROM " + RetSQLName("SH1") + " SH1 "
	cSql += " WHERE H1_FILIAL 	 	 = '" + xFilial("SH1") + "' "
	cSql += "	AND SH1.D_E_L_E_T_ 	 = ' ' "
	cSql += "	ORDER BY H1_CODIGO "
	cAlias := MPSysOpenQuery(cSql)

	While (cAlias)->(! EOF())

		dData := dDtIni

		While dData <= dDtFim

			if Dow(dData) = 1
				dData := DaySum(dData, 1)
			Endif
			if Dow(dData) = 7
				dData := DaySum(dData, 2)
			Endif

			cSql := "INSERT INTO " + cTT2Name + " ("
			cSql += " TT2_ID, TT2_RECURS, TT2_DATA, TT2_DISP, TT2_USADA) VALUES ('"
			cSql += FWUUIDv4() 			 			+ "','"
			cSql += (cAlias)->H1_CODIGO 			+ "','"
			cSql += DTOS(dData) 					+ "','"
			cSql += cValToChar((cAlias)->H1_XHSDIA)	+ "','0')"

			if TCSqlExec(cSql) < 0
				MsgInfo("Erro na execução da query:", "Atenção")
				MsgInfo(TcSqlError(), "Atenção3")
			endif

			dData := DaySum(dData, 1)
		enddo

		(cAlias)->(DbSkip())
	enddo

	(cAlias)->(DBCLOSEAREA())
return

/*
	Distribuicao da carga maquina
*/
Static Function Calculo(oSay)
	Local nQtNec	:= 0
	Local dDtIniP 	:= date()
	Local dDtFimP 	:= date()

	(cAliasTT1)->(DBSetOrder(2))
	(cAliasTT2)->(DBSetOrder(2))

	(cAliasTT1)->(DbGoTop())

	While (cAliasTT1)->(! EOF())

		nQtNec 	:= (cAliasTT1)->TT1_QTHSTO
		dDtIniP := NIL
		dDtFimP := NIL

		(cAliasTT2)->(DbGoTop())
		(cAliasTT2)->(DbSeek((cAliasTT1)->TT1_RECURS + dtos((cAliasTT1)->TT1_DATPRI)))

		if ! (cAliasTT2)->(EOF())
			While nQtNec > 0
				if (cAliasTT2)->TT2_RECURS == (cAliasTT1)->TT1_RECURS
					if (cAliasTT2)->TT2_DISP > (cAliasTT2)->TT2_USADA					// Tem horas disponiveis no dia

						if dDtIniP == NIL
							dDtIniP := stod((cAliasTT2)->TT2_DATA)
						endif

						dDtFimP := stod((cAliasTT2)->TT2_DATA)

						RecLock(cAliasTT2, .F.)

						if (cAliasTT2)->TT2_DISP - (cAliasTT2)->TT2_USADA >= nQtNec		// Disponivel é suficiente
							(cAliasTT2)->TT2_USADA := (cAliasTT2)->TT2_USADA + nQtNec
							nQtNec := 0
						else
							nQtNec := nQtNec - ((cAliasTT2)->TT2_DISP - (cAliasTT2)->TT2_USADA)
							(cAliasTT2)->TT2_USADA := (cAliasTT2)->TT2_DISP
						endif

						(cAliasTT2)->(MsUnLock())
					endif

					(cAliasTT2)->(DbSkip())
				else
					nQtNec := 0
				endif
			enddo

			SC2->(dbSetOrder(1))

			If SC2->(MsSeek(xFilial("SC2") + (cAliasTT1)->TT1_OP))
				RecLock("SC2", .F.)
				SC2->C2_XDTINIP := dDtIniP

				if dDtFimP > SC2->C2_DATPRF
					SC2->C2_XDTFIMP := NIL
					SC2->C2_XOBSPRD := "Data calculada fora da data de termino"
				else
					SC2->C2_XDTFIMP := dDtFimP
					SC2->C2_XOBSPRD := ""
				endif

				// Saboneteira tem prioridade na carga maquina
				if SC2->C2_PRODUTO == AvKey("11401720", "C2_PRODUTO") ;
						.OR. SC2->C2_PRODUTO == AvKey("11501720", "C2_PRODUTO") ;
						.OR. SC2->C2_PRODUTO == AvKey("25401720", "C2_PRODUTO") ;
						.OR. SC2->C2_PRODUTO == AvKey("25501720", "C2_PRODUTO")
					SC2->C2_PRIOR := "100"
				endif

				SC2->(MsUnLock())
			endif
		endif

		(cAliasTT1)->(DbSkip())
	enddo

	(cAliasTT1)->(DBCLOSEAREA())
	(cAliasTT2)->(DBCLOSEAREA())
return
