#Include "PROTHEUS.CH"
#Include "TBICONN.CH"
#Include 'FWMVCDef.ch'

/*/{Protheus.doc}	PL240A
	Distribuição da carga maquina gerencial
	10/10/2024 - 20% de ineficiencia
@author Carlos Assis
@since 25/09/2024
@version 1.0   
/*/
User Function PL240A(Inicio, Fim)
	Local aArea 		:= FWGetArea()
	Local aCampos 		:= {}
	Local oSay 			:= NIL

	Private	dDtIni		:= Inicio
	Private	dDtFim		:= Fim

	Private cTT1Name 	:= ""
	Private cTT2Name 	:= ""
	Private cAliasTT1 	:= GetNextAlias()
	Private cAliasTT2 	:= GetNextAlias()

	//Campos da temporaria de tempos disponiveis
	aCampos := {}
	aAdd(aCampos, {"TT_SEQ"			,"N", 10, 0})
	aAdd(aCampos, {"TT_RECURS"		,"C", 06, 0})
	aAdd(aCampos, {"TT_DATA"		,"C", 08, 0})
	aAdd(aCampos, {"TT_DISP"		,"N", 14, 3})
	aAdd(aCampos, {"TT_USADA"		,"N", 14, 3})

	oTT1 := FWTemporaryTable():New(cAliasTT1)
	oTT1:SetFields(aCampos)
	oTT1:AddIndex("1", {"TT_SEQ"} )
	oTT1:AddIndex("2", {"TT_RECURS", "TT_DATA"} )
	oTT1:Create()
	cTT1Name  := oTT1:GetRealName()


	//Campos da temporaria de demandas
	aCampos := {}
	aAdd(aCampos, {"TT2_SEQ"		,"N", 10, 0})
	aAdd(aCampos, {"TT2_PROD"		,"C", 15, 0})
	aAdd(aCampos, {"TT2_DATA"		,"C", 08, 0})
	aAdd(aCampos, {"TT2_QUANT"		,"N", 14, 3})
	aAdd(aCampos, {"TT2_OK"			,"C", 01, 0})

	oTT2 := FWTemporaryTable():New(cAliasTT2)
	oTT2:SetFields(aCampos)
	oTT2:AddIndex("1", {"TT2_SEQ"} )
	oTT2:Create()
	cTT2Name  := oTT2:GetRealName()

	FwMsgRun(NIL, {|oSay| CargaInicial(oSay)}	, "Preparando o calculo ", "Preparando...")

	// FwMsgRun(NIL, {|oSay| Calculo(oSay)}		, "Calculando distribuicao", "Calculando...")

	oTT1:Delete()
	oTT2:Delete()

	FWRestArea(aArea)
return


/*---------------------------------------------------------------------*
	Carregar ZA2 com a demanda e pedidos de vendas
 *---------------------------------------------------------------------*/
Static Function CargaInicial(oSay)
	Local cSql 			:= ""
	Local cAlias 		:= ""
	Local nQuant		:= 0
	Local nSetup		:= 0

	Private nSeq		:= 0

	// Limpa a rodada anterior
	cSql := "DELETE FROM "  + RetSQLName("ZA2")
	cSql += " WHERE ZA2_FILIAL 	 	= '" + xFilial("ZA2") + "' "
	cSql += "	AND ZA2_TIPO  	    = '2' "
	cSql += "	AND D_E_L_E_T_  	= ' ' "

	if TCSqlExec(cSql) < 0
		MsgInfo("Erro na execução do delete tipo 2:", "Atenção")
		MsgInfo(TcSqlError(), "Atenção")
	endif

	Demandas()

	cSql := "SELECT TT2.*, "
	cSql += "	  	B1_COD, B1_DESC, B1_UM, B1_XCLIENT, B1_XITEM, B1_LE, B1_XPRIOR, "
	cSql += "	    G2_OPERAC, G2_RECURSO, G2_MAOOBRA, G2_SETUP, G2_TEMPAD, G2_LOTEPAD, G2_XDIRESQ,"
	cSql += "	  	H1_XLIN, H1_XLOCLIN, H1_XTIPO, H1_XSETUP, H1_XNOME, H1_XLINPRD "
	cSql += "  FROM " + cTT2Name + " TT2 "

	cSql += " INNER JOIN " + RetSQLName("SB1") + " SB1 "
	cSql += "	 ON B1_COD 		 	 = TT2.TT2_PROD "
	cSql += "   AND B1_MSBLQL 		 =  '2' "
	cSql += "   AND B1_FILIAL 	 	 = '" + xFilial("SB1") + "' "
	cSql += "	AND SB1.D_E_L_E_T_ 	 = ' ' "

	cSql += " INNER JOIN " + RetSQLName("SG2") + " SG2 "
	cSql += "    ON G2_PRODUTO 		 = B1_COD"
	cSql += "   AND G2_DTINI 	 	<= TT2.TT2_DATA "
	cSql += "   AND G2_DTFIM	 	>= TT2.TT2_DATA "
	cSql += "   AND G2_FILIAL		 = '" + xFilial("SG2") + "' "
	cSql += "   AND SG2.D_E_L_E_T_ 	 = ''

	cSql += " INNER JOIN " + RetSQLName("SH1") + " SH1 "
	cSql += "    ON H1_CODIGO 		 = G2_RECURSO"
	cSql += "   AND H1_FILIAL 	 	 = '" + xFilial("SH1") + "' "
	cSql += "   AND SH1.D_E_L_E_T_ 	 = ''

	cAlias := MPSysOpenQuery(cSql)

	nSeq := 0

	While (cAlias)->(! EOF())

		// Se for direita e esquerda deve dobrar a quantidade/hora
		if (cAlias)->G2_XDIRESQ == 'S'
			nQuant := (cAlias)->TT2_QUANT / ((cAlias)->G2_LOTEPAD * 2)
		else
			nQuant := (cAlias)->TT2_QUANT / (cAlias)->G2_LOTEPAD
		endif

		nSetup	:= 0.5

		if (cAlias)->G2_SETUP > 0
			nSetup	:= (cAlias)->G2_SETUP
		else
			if (cAlias)->H1_XSETUP > 0
				nSetup	:= (cAlias)->H1_XSETUP
			endif
		endif

		// Ajusta o setup pelo lote economico
		nSetup := nSetup * Ceiling((cAlias)->TT2_QUANT / (cAlias)->B1_LE)

		nSeq++

		RecLock("ZA2", .T.)
		ZA2_FILIAL	:= xFilial("ZA2")
		ZA2_TIPO	:= "2"
		ZA2_COD		:= GETSXENUM("ZA2", "ZA2_COD", 1)
		ZA2_OP		:= cValToChar(nSeq)
		ZA2_PROD	:= (cAlias)->TT2_PROD
		ZA2_CLIENT	:= (cAlias)->B1_XCLIENT
		ZA2_ITCLI	:= (cAlias)->B1_XITEM
		ZA2_LE		:= (cAlias)->B1_LE
		ZA2_QUANT	:= (cAlias)->TT2_QUANT
		ZA2_LINPRD	:= (cAlias)->H1_XLINPRD
		ZA2_OPER	:= (cAlias)->G2_OPERAC
		ZA2_RECURS	:= AllTrim((cAlias)->G2_RECURSO)
		ZA2_PRIOR	:= cValToChar((cAlias)->B1_XPRIOR)
		ZA2_DATPRI	:= stod((cAlias)->TT2_DATA)
		ZA2_DATPRF	:= stod((cAlias)->TT2_DATA)
		ZA2_TPOP	:= "p"
		ZA2_QUJE	:= 0
		ZA2_QTHORA	:= nQuant
		ZA2_HSTOT	:= nSetup + nQuant
		ZA2_HSTOTI	:= nSetup + (nQuant * 1.2)
		ZA2_STAT	:= "P"
		ZA2->(MsUnLock())
		ConfirmSx8()

		(cAlias)->(DbSkip())
	enddo

	(cAlias)->(DBCLOSEAREA())

	TemposDisponiveis()
return


Static Function Demandas()
	Local cSql 			:= ""
	Local cAlias 		:= ""
	Local nQtde			:= 0
	Local nPos			:= 0
	Private lFim		:= .F.

	cSql := "SELECT VR_PROD, B1_XCLIENT, SUBSTRING(VR_DATA,1,6) VR_DATA, SUM(VR_QUANT) VR_QUANT "
	cSql += "  FROM " + RetSQLName("SVR") + " SVR "

	cSql += " INNER JOIN " + RetSQLName("SB1") + " SB1 "
	cSql += "    ON B1_COD 		 	 = VR_PROD "
	cSql += "   AND B1_FILIAL 	 	 = '" + xFilial("SB1") + "' "
	cSql += "   AND SB1.D_E_L_E_T_ 	 = ''"
	 
	cSql += " WHERE VR_FILIAL 	 	 = '" + xFilial("SVR") + "' "
	cSql += "	AND VR_DATA 	 	>= '" + DTOS(dDtIni) + "'"
	cSql += "	AND VR_DATA 	 	<= '" + DTOS(dDtFim) + "'"
	cSql += "	AND SVR.D_E_L_E_T_ 	 = ' ' "
	cSql += " GROUP BY VR_PROD, B1_XCLIENT, SUBSTRING(VR_DATA,1,6) "

	cAlias := MPSysOpenQuery(cSql)

	While (cAlias)->(! EOF())
		nSeq++

		nQtde := (cAlias)->VR_QUANT

		nPos := At("GEST", Upper((cAlias)->B1_XCLIENT), 1)
		
		if nPos > 0
			nQtde := nQtde * 1.2
		endif

		cSql := "INSERT INTO " + cTT2Name + " ("
		cSql += " TT2_SEQ, TT2_PROD, TT2_DATA, TT2_QUANT, TT2_OK) VALUES ('"
		cSql += cValToChar(nSeq) 				+ "','"
		cSql += (cAlias)->VR_PROD 				+ "','"
		cSql += (cAlias)->VR_DATA + "01"		+ "','"
		cSql += cValToChar(nQtde) + "','0')"
		// cSql += cValToChar((cAlias)->VR_QUANT)	+ "','0')"

		if TCSqlExec(cSql) < 0
			MsgInfo("Erro na execução da query:", "Atenção")
			MsgInfo(TcSqlError(), "Atenção3")
		endif

		(cAlias)->(DbSkip())
	enddo

	(cAlias)->(DBCLOSEAREA())

	// Explosao das demandas para gerar demandas dos filhos
	(cAliasTT2)->(DBSetOrder(1))

	while lFim == .F.

		(cAliasTT2)->(DbGoTop())

		lFim := .T.

		While (cAliasTT2)->(! EOF())

			if (cAliasTT2)->TT2_OK == "0"
				Explosao((cAliasTT2)->TT2_PROD, (cAliasTT2)->TT2_QUANT, (cAliasTT2)->TT2_DATA)

				RecLock(cAliasTT2, .F.)
				(cAliasTT2)->TT2_OK := "1"
				(cAliasTT2)->(MsUnLock())
			endif

			(cAliasTT2)->(DbSkip())
		enddo
	enddo
return


Static Function Explosao(cProd, nQtde, dData)
	Local cSql 		:= ""
	Local nQtFilho 	:= 0
	Local cAlias

	cSql := "SELECT G1_COD, G1_COMP, G1_QUANT, G1_INI, G1_FIM, G1_FANTASM, B1_AGREGCU "
	cSql += "  FROM " + RetSQLName("SG1") + " SG1 "

	cSql += " INNER JOIN " + RetSQLName("SB1") + " SB1 "
	csQL += "	 ON B1_COD			=  G1_COMP "
	cSql += "   AND B1_MSBLQL 		=  '2' "
	cSql += "   AND B1_FILIAL 		= '" + xFilial("SB1") + "' "
	cSql += "   AND SB1.D_E_L_E_T_ 	= ' ' "

	cSql += " WHERE G1_COD 			= '" + cProd + "' "
	cSql += "   AND G1_INI 		   <= '" + DTOS(Date()) + "' "
	cSql += "   AND G1_FIM 		   >= '" + DTOS(Date()) + "' "
	cSql += "   AND G1_FILIAL 		= '" + xFilial("SG1") + "' "
	cSql += "   AND SG1.D_E_L_E_T_ 	= ' ' "
	cSql += " ORDER BY G1_TRT, G1_COMP "
	cAlias := MPSysOpenQuery(cSql)

	While (cAlias)->(!EOF())
		nSeq++

		nQtFilho := nQtde * (cAlias)->G1_QUANT

		cSql := "INSERT INTO " + cTT2Name + " ("
		cSql += " TT2_SEQ, TT2_PROD, TT2_DATA, TT2_QUANT, TT2_OK) VALUES ('"
		cSql += cValToChar(nSeq) 			+ "','"
		cSql += (cAlias)->G1_COMP 			+ "','"
		cSql += dData 						+ "','"
		cSql += cValToChar(nQtFilho)		+ "','0')"

		if TCSqlExec(cSql) < 0
			MsgInfo("Erro na execução da query A:", "Atenção")
			MsgInfo(TcSqlError(), "Atenção3")
		endif

		lFim := .F.

		(cAlias)->(DbSkip())
	enddo

	(cAlias)->(DBCLOSEAREA())
return


Static Function TemposDisponiveis()
	Local cSql 			:= ""
	Local cAlias 		:= ""
	Local dData			:= Date()
	Local nSeq			:= 0

	// Carregar tabela de tempos disponiveis por recurso
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

			nSeq++

			cSql := "INSERT INTO " + cTT1Name + " ("
			cSql += "TT_SEQ, TT_RECURS, TT_DATA, TT_DISP, TT_USADA) VALUES ('"
			cSql += cValToChar(nSeq) 				+ "','"
			cSql += (cAlias)->H1_CODIGO 			+ "','"
			cSql += DTOS(dData) 					+ "','"
			cSql += cValToChar((cAlias)->H1_XHSDIA)	+ "','0')"

			if TCSqlExec(cSql) < 0
				MsgInfo("Erro na execução da query X:", "Atenção")
				MsgInfo(TcSqlError(), "Atenção3")
			endif

			dData := DaySum(dData, 1)
		enddo

		(cAlias)->(DbSkip())
	enddo

	(cAlias)->(DBCLOSEAREA())
return

/*---------------------------------------------------------------------*
	Distribuicao da carga maquina
 *---------------------------------------------------------------------*/
Static Function Calculo(oSay)
	Local nQtNec	:= 0
	Local dDtIniP 	:= date()
	Local dDtFimP 	:= date()

	(cAliasTT1)->(DBSetOrder(2))

	ZA2->(DBSetOrder(2))
	ZA2->(DbSeek(xFilial("ZA2")+"2"))

	While ("ZA2")->(! EOF())
		if ZA2->ZA2_TIPO == '2'
			nQtNec 	:= ZA2->ZA2_HSTOT
			dDtIniP := NIL
			dDtFimP := NIL

			(cAliasTT1)->(DbGoTop())
			(cAliasTT1)->(DbSeek(ZA2->ZA2_RECURS + dtos(ZA2->ZA2_DATPRI)))

			if ! (cAliasTT1)->(EOF())
				While nQtNec > 0
					if (cAliasTT1)->TT_RECURS == ZA2->ZA2_RECURS
						if (cAliasTT1)->TT_DISP > (cAliasTT1)->TT_USADA					// Tem horas disponiveis no dia

							if dDtIniP == NIL
								dDtIniP := stod((cAliasTT1)->TT_DATA)
							endif

							dDtFimP := stod((cAliasTT1)->TT_DATA)

							RecLock(cAliasTT1, .F.)

							if (cAliasTT1)->TT_DISP - (cAliasTT1)->TT_USADA >= nQtNec		// Disponivel é suficiente
								(cAliasTT1)->TT_USADA := (cAliasTT1)->TT_USADA + nQtNec
								nQtNec := 0
							else
								nQtNec := nQtNec - ((cAliasTT1)->TT_DISP - (cAliasTT1)->TT_USADA)
								(cAliasTT1)->TT_USADA := (cAliasTT1)->TT_DISP
							endif

							(cAliasTT1)->(MsUnLock())
						endif

						(cAliasTT1)->(DbSkip())
					else
						nQtNec := 0
					endif
				enddo
			endif
		endif

		ZA2->(DbSkip())
	enddo

	(cAliasTT1)->(DBCLOSEAREA())
return
