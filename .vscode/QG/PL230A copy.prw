#Include "PROTHEUS.CH"
#Include "TBICONN.CH"
#Include 'FWMVCDef.ch'
#INCLUDE 'parmtype.ch'

/*/{Protheus.doc}	PL230A
	Distribuição da carga maquina
@author Carlos Assis
@since 25/09/2024
@version 1.0   
/*/
User Function PL230A(Inicio, Fim)
	Local aArea 		:= FWGetArea()
	Local aCampos 		:= {}
	Local oSay 			:= NIL

	Private	dDtIni		:= Inicio
	Private	dDtFim		:= Fim

	Private cTTName 	:= ""
	Private cAliasTT 	:= GetNextAlias()

	//Campos da temporária de maquinas
	aCampos := {}
	aAdd(aCampos, {"TT_ID"			,"C", 36, 0})
	aAdd(aCampos, {"TT_RECURS"		,"C", 06, 0})
	aAdd(aCampos, {"TT_DATA"		,"C", 08, 0})
	aAdd(aCampos, {"TT_DISP"		,"N", 14, 3})
	aAdd(aCampos, {"TT_USADA"		,"N", 14, 3})

	oTT := FWTemporaryTable():New(cAliasTT)
	oTT:SetFields(aCampos)
	oTT:AddIndex("1", {"TT_ID"} )
	oTT:AddIndex("2", {"TT_RECURS", "TT_DATA"} )
	oTT:Create()
	cTTName  := oTT:GetRealName()

	FwMsgRun(NIL, {|oSay| CargaInicial(oSay)}, "Preparando o calculo ", "Preparando...")
	FwMsgRun(NIL, {|oSay| Calculo(oSay)}, "Calculando distribuicao", "Calculando...")

	oTT:Delete()

	FWRestArea(aArea)
return


Static Function CargaInicial(oSay)
	Local cSql 			:= ""
	Local cAlias 		:= ""
	Local cOP 			:= ""
	Local nQuant		:= 0
	Local nTotal		:= 0
	Local nSetup		:= 0
	Local nSeq			:= 0
	Local dData			:= Date()
	Local cPrior		:= ""
	Local cTppr			:= ""
	Local aDados 		:= {}

	Private lMsErroAuto := .F.

	// Limpa as linhas planejadas e de ordens encerradas
	SC2->(dbSetOrder(1))	// OP
	ZA2->(DBSetOrder(1))	// Tipo/Codigo
	ZA2->(DbSeek(xFilial("ZA2") + "1"))

	While ! ZA2->(EoF())
		RecLock("ZA2", .F.)

		if ZA2->ZA2_STAT == 'P'
			ZA2->(DbDelete())
		else
			If SC2->(MsSeek(xFilial("SC2") + ZA2->ZA2_OP))
				if AllTrim(dtos(SC2->C2_DATRF)) <> ''
					ZA2->(DbDelete())
				endif
			endif
		endif

		ZA2->(MsUnLock())
		ZA2->(DbSkip())
	enddo

	// Carrega os dados
	cSql := "SELECT C2_NUM, C2_ITEM, C2_SEQUEN, C2_PRODUTO, C2_STATUS, C2_PRIOR,"
	cSql += "	    C2_QUANT, C2_QUJE, C2_DATPRI, C2_DATPRF, C2_TPOP, C2_TPPR, "
	cSql += "	    C2_XDTINIP, C2_XDTFIMP, C2_XHRINIP, C2_XHRFIMP, "
	cSql += "	    C2_XSITEMP, C2_XOBSEMP, C2_XOBSPRD, "
	cSql += "	  	B1_COD, B1_DESC, B1_UM, B1_XCLIENT, B1_XITEM, B1_LE, B1_XPRIOR, B1_XTPPR, "
	cSql += "	    G2_OPERAC, G2_RECURSO, G2_MAOOBRA, G2_SETUP, G2_TEMPAD, G2_LOTEPAD, "
	cSql += "	  	H1_XLIN, H1_XLOCLIN, H1_XTIPO, H1_XSETUP, H1_XNOME, H1_XLINPRD "
	cSql += "  FROM " + RetSQLName("SC2") + " SC2 "

	cSql += " INNER JOIN " + RetSQLName("SB1") + " SB1 "
	cSql += "	 ON B1_COD 		 	 = C2_PRODUTO"
	cSql += "   AND B1_MSBLQL 		 =  '2' "
	cSql += "   AND B1_FILIAL 	 	 = '" + xFilial("SB1") + "' "
	cSql += "	AND SB1.D_E_L_E_T_ 	 = ' ' "

	cSql += " INNER JOIN " + RetSQLName("SG2") + " SG2 "
	cSql += "    ON G2_PRODUTO 		 = C2_PRODUTO"
	cSql += "   AND G2_CODIGO 	 	 = C2_ROTEIRO"
	cSql += "   AND G2_DTINI 	 	<= C2_DATPRI "
	cSql += "   AND G2_DTFIM	 	>= C2_DATPRF "
	cSql += "   AND G2_FILIAL		 = '" + xFilial("SG2") + "' "
	cSql += "   AND SG2.D_E_L_E_T_ 	 = ''

	cSql += " INNER JOIN " + RetSQLName("SH1") + " SH1 "
	cSql += "    ON H1_CODIGO 		 = G2_RECURSO"
	cSql += "   AND H1_FILIAL 	 	 = '" + xFilial("SH1") + "' "
	cSql += "   AND SH1.D_E_L_E_T_ 	 = ''

	cSql += " WHERE C2_DATPRF 	   	>= '" + dtos(dDtIni) + "'"
	cSql += "   AND C2_DATPRF	   	<= '" + dtos(dDtFim) + "'"
	cSql += "   AND C2_DATRF   		 = ''"
	cSql += "   AND C2_TPOP	   	     = 'F'"		// Firme
	cSql += "   AND C2_TPPR	   	     = 'I'"		// Interna
	cSql += "   AND C2_FILIAL 	 	 = '" + xFilial("SC2") + "' "
	cSql += "	AND SC2.D_E_L_E_T_ 	 = ' ' "
	cSql += "	ORDER BY G2_RECURSO, C2_DATPRI, C2_NUM, C2_ITEM, C2_SEQUEN "
	cAlias := MPSysOpenQuery(cSql)

	While (cAlias)->(! EOF())
		cOP		:= Transform((cAlias)->C2_NUM, "999999") + AllTrim((cAlias)->C2_ITEM) + AllTrim((cAlias)->C2_SEQUEN)
		cPrior := (cAlias)->C2_PRIOR
		nQuant := (cAlias)->C2_QUANT / (cAlias)->G2_LOTEPAD

		if (cAlias)->G2_SETUP > 0
			nSetup	:= (cAlias)->G2_SETUP
		else
			if (cAlias)->H1_XSETUP > 0
				nSetup	:= (cAlias)->H1_XSETUP
			else
				nSetup	:= 0.5
			endif
		endif

		nTotal 	:= nSetup + nQuant

		if AllTrim((cAlias)->B1_XPRIOR) == ''
			cPrior := '500'
		else
			cPrior := (cAlias)->B1_XPRIOR
		endif

		if AllTrim((cAlias)->B1_XTPPR) == ''
			cTppr := 'I'
		else
			cTppr := (cAlias)->B1_XTPPR
		endif

		if (cAlias)->C2_TPPR  != cTppr .or. (cAlias)->C2_PRIOR  != cPrior

			SC2->(DbSetOrder(1))
			SC2->(DbSeek(xFilial("SC2")+(cAlias)->C2_NUM+(cAlias)->C2_ITEM+(cAlias)->C2_SEQUEN)) //FILIAL + NUM + ITEM + SEQUEN + ITEMGRD

			Begin Transaction
				aDados := { ;
					{'C2_FILIAL' 	,xFilial("SC2") 		,NIL},;
					{'C2_NUM' 		,(cAlias)->C2_NUM 		,NIL},;
					{'C2_ITEM' 		,(cAlias)->C2_ITEM 		,NIL},;
					{'C2_SEQUEN' 	,(cAlias)->C2_SEQUEN 	,NIL},;
					{'C2_PRODUTO'   ,(cAlias)->C2_PRODUTO	,NIL},;
					{'C2_PRIOR' 	,cPrior 				,NIL},;
					{'C2_TPPR' 		,cTppr 					,NIL};
					}

				MSExecAuto({|x,y| Mata650(x,y)},aDados,4)

				If lMsErroAuto
					ConOut("Erro Execauto!")
					MostraErro()
				EndIf
			End Transaction
		endif

		// Ver se existe operacao firme (alteracao de recurso da OP)
		ZA2->(DBSetOrder(3))
		ZA2->(DbSeek(xFilial("ZA2") + cOP + (cAlias)->G2_OPERAC))

		if ("ZA2")->(EOF())
			nSeq++

			RecLock("ZA2", .T.)
			ZA2_FILIAL	:= xFilial("ZA2")
			ZA2_TIPO	:= "1"
			ZA2_COD		:= GETSXENUM("ZA2", "ZA2_COD", 1)
			ZA2_OP		:= cOP
			ZA2_PROD	:= (cAlias)->C2_PRODUTO
			ZA2_CLIENT	:= (cAlias)->B1_XCLIENT
			ZA2_ITCLI	:= (cAlias)->B1_XITEM
			ZA2_DATPRI	:= stod((cAlias)->C2_DATPRI)
			ZA2_DATPRF	:= stod((cAlias)->C2_DATPRF)
			// ZA2_TPOP	:= (cAlias)->C2_TPOP
			ZA2_LE		:= (cAlias)->B1_LE
			ZA2_QUANT	:= (cAlias)->C2_QUANT
			ZA2_QUJE	:= (cAlias)->C2_QUJE
			ZA2_RECURO	:= AllTrim((cAlias)->G2_RECURSO)
			ZA2_RECURS	:= AllTrim((cAlias)->G2_RECURSO)
			ZA2_LINPRD	:= (cAlias)->H1_XLINPRD
			ZA2_TIPLIN	:= (cAlias)->H1_XLIN
			ZA2_HSTOT	:= nTotal
			ZA2_QTHORA	:= (cAlias)->G2_LOTEPAD
			ZA2_DTINIP	:= stod((cAlias)->C2_XDTINIP)
			ZA2_DTFIMP	:= stod((cAlias)->C2_XDTFIMP)
			ZA2_HRINIP	:= (cAlias)->C2_XHRINIP
			ZA2_HRFIMP	:= (cAlias)->C2_XHRFIMP
			ZA2_OPER	:= (cAlias)->G2_OPERAC
			ZA2_PRIOR	:= cPrior
			ZA2_SITSLD	:= "S"
			ZA2_STAT	:= "P"
			ZA2->(MsUnLock())
			ConfirmSx8()
		endif

		(cAlias)->(DbSkip())
	enddo

	(cAlias)->(DBCLOSEAREA())

	// Carregar tabela de tempos disponiveis por recurso
	SH1->(DBSetOrder(1))
	SH1->(DbSeek(xFilial("SH1")))

	While ! SH1->(EoF())
		dData := dDtIni

		While dData <= dDtFim

			if Dow(dData) = 1
				dData := DaySum(dData, 1)
			Endif
			if Dow(dData) = 7
				dData := DaySum(dData, 2)
			Endif

			cSql := "INSERT INTO " + cTTName + " ("
			cSql += " TT_ID, TT_RECURS, TT_DATA, TT_DISP, TT_USADA) VALUES ('"
			cSql += FWUUIDv4() 			 		+ "','"
			cSql += SH1->H1_CODIGO 				+ "','"
			cSql += DTOS(dData) 				+ "','"
			cSql += cValToChar(SH1->H1_XHSDIA)	+ "','0')"

			if TCSqlExec(cSql) < 0
				MsgInfo("Erro na execução da query:", "Atenção")
				MsgInfo(TcSqlError(), "Atenção3")
			endif

			dData := DaySum(dData, 1)
		enddo

		SH1->(DbSkip())
	enddo

return


/*
	Distribuicao da carga maquina
*/
Static Function Calculo(oSay)
	Local nQtNec	:= 0
	Local dDtIniP 	:= date()
	Local dDtFimP 	:= date()

	(cAliasTT)->(DBSetOrder(2))

	ZA2->(DBSetOrder(2)) 	// ZA2_FILIAL+ZA2_TIPO+ZA2_PRIOR+ZA2_DATPRI+ZA2_OP+ZA2_OPER
	ZA2->(DbSeek(xFilial("ZA2")+"1"))

	While ("ZA2")->(! EOF()) .and. ZA2->ZA2_TIPO == "1"

		nQtNec 	:= ZA2->ZA2_HSTOT
		dDtIniP := NIL
		dDtFimP := NIL

		(cAliasTT)->(DbGoTop())
		(cAliasTT)->(DbSeek(ZA2->ZA2_RECURS + dtos(ZA2->ZA2_DATPRI)))

		if ! (cAliasTT)->(EOF())
			While nQtNec > 0
				if (cAliasTT)->TT_RECURS == ZA2->ZA2_RECURS  .and. (cAliasTT)->TT_DATA <= dtos(ZA2->ZA2_DATPRF)
					if (cAliasTT)->TT_DISP > (cAliasTT)->TT_USADA					// Tem horas disponiveis no dia

						if dDtIniP == NIL
							dDtIniP := stod((cAliasTT)->TT_DATA)
						endif

						dDtFimP := stod((cAliasTT)->TT_DATA)

						RecLock(cAliasTT, .F.)

						if (cAliasTT)->TT_DISP - (cAliasTT)->TT_USADA >= nQtNec		// Disponivel é suficiente
							(cAliasTT)->TT_USADA := (cAliasTT)->TT_USADA + nQtNec
							nQtNec := 0
						else
							nQtNec := nQtNec - ((cAliasTT)->TT_DISP - (cAliasTT)->TT_USADA)
							(cAliasTT)->TT_USADA := (cAliasTT)->TT_DISP
						endif

						(cAliasTT)->(MsUnLock())
					endif

					(cAliasTT)->(DbSkip())
				else
					nQtNec := 0
				endif
			enddo

			SC2->(dbSetOrder(1))

			If SC2->(MsSeek(xFilial("SC2") + ZA2->ZA2_OP))
				RecLock("SC2", .F.)
				SC2->C2_XDTINIP := dDtIniP

				if dDtFimP > SC2->C2_DATPRF
					SC2->C2_XDTFIMP := NIL
					SC2->C2_XOBSPRD := "Data calculada fora da data de termino"
				else
					SC2->C2_XDTFIMP := dDtFimP
					SC2->C2_XOBSPRD := ""
				endif

				SC2->(MsUnLock())
			endif
		endif

		ZA2->(DbSkip())
	enddo

	(cAliasTT)->(DBCLOSEAREA())
return


Static Function LerAlternativo(cProd, cOper, cRec)

	RecLock(ZA2, .F.)
	ZA2_RECURS := xxxx
	(ZA2)->(MsUnLock())

return
