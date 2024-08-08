#Include "PROTHEUS.CH"
#Include "RPTDEF.CH"
#Include "TBICONN.CH"

/*/{Protheus.doc}	PL070
	Extrair dados de uso de maquina em arquivo txt delimitado
	08/08/2024 - Tempo de operador e maquinas alternativas
@author Carlos Assis
@since 22/07/2024
@version 1.0   
/*/

User Function PL070()
	Local oSay 		:= NIL
	Local aPergs	:= {}
	Local aResps	:= {}

	Private dDtIni  := ""
	Private dDtFim  := ""

	Private aCampos 	:= {}
	Private cTableName 	:= ""
	Private cAliasTT 	:= GetNextAlias()

	AAdd(aPergs, {1, "Informe a data inicial "	, CriaVar("C2_DATPRF",.F.),"",".T.","",".T.", 70, .F.})
	AAdd(aPergs, {1, "Informe a data final "	, CriaVar("C2_DATPRF",.F.),"",".T.","",".T.", 70, .F.})

	If ParamBox(aPergs, "Extracao de Uso Planejado de Maquina", @aResps,,,,,,,, .T., .T.)
		dDtIni 	:= aResps[1]
		dDtFim 	:= aResps[2]
	Else
		return
	endif

	//Campos da temporária
	aAdd(aCampos, {"ID"			,"C", 36, 0})
	aAdd(aCampos, {"TT_PRODUTO"	,"C", 15, 0})
	aAdd(aCampos, {"TT_DESC"	,"C", 60, 0})
	aAdd(aCampos, {"TT_XCLIENT"	,"C", 30, 0})
	aAdd(aCampos, {"TT_XITEM"	,"C", 30, 0})
	aAdd(aCampos, {"TT_OP"		,"C", 11, 0})
	aAdd(aCampos, {"TT_TPOP"	,"C", 10, 0})
	aAdd(aCampos, {"TT_OPERAC"	,"C", 02, 0})
	aAdd(aCampos, {"TT_RECURSO"	,"C", 06, 0})
	aAdd(aCampos, {"TT_MAOOBRA"	,"N", 02, 0})
	aAdd(aCampos, {"TT_TEMPAD"	,"N", 05, 2})
	aAdd(aCampos, {"TT_LOTEPAD"	,"N", 06, 0})
	aAdd(aCampos, {"TT_DATPRI"	,"D", 08, 0})
	aAdd(aCampos, {"TT_DATPRF"	,"D", 08, 0})
	aAdd(aCampos, {"TT_QUANT"	,"N", 14, 3})
	aAdd(aCampos, {"TT_UM"		,"C", 02, 0})
	aAdd(aCampos, {"TT_SETUP"	,"N", 05, 2})
	aAdd(aCampos, {"TT_QTHS"	,"N", 14, 3})
	aAdd(aCampos, {"TT_QTHSTOT"	,"N", 14, 3})
	aAdd(aCampos, {"TT_XLIN"	,"C", 15, 0})
	aAdd(aCampos, {"TT_XLOCLIN"	,"C", 15, 0})
	aAdd(aCampos, {"TT_XTIPO"	,"C", 15, 0})
	aAdd(aCampos, {"TT_REC1"	,"C", 06, 0})
	aAdd(aCampos, {"TT_QTREC1"	,"N", 14, 3})
	aAdd(aCampos, {"TT_REC2"	,"C", 06, 0})
	aAdd(aCampos, {"TT_QTREC2"	,"N", 14, 3})
	aAdd(aCampos, {"TT_REC3"	,"C", 06, 0})
	aAdd(aCampos, {"TT_QTREC3"	,"N", 14, 3})
	aAdd(aCampos, {"TT_REC4"	,"C", 06, 0})
	aAdd(aCampos, {"TT_QTREC4"	,"N", 14, 3})
	aAdd(aCampos, {"TT_REC5"	,"C", 06, 0})
	aAdd(aCampos, {"TT_QTREC5"	,"N", 14, 3})

	//Cria a temporária
	oTempTable := FWTemporaryTable():New(cAliasTT)
	oTempTable:SetFields(aCampos)
	oTempTable:AddIndex("1", {"ID"} )
	oTempTable:Create()

	cTableName  := oTempTable:GetRealName()

	FwMsgRun(NIL, {|oSay| Processa(oSay)}, "Processando ordens de producao", "Extraindo dados...")

	FwMsgRun(NIL, {|oSay| GravaCSV(oSay)}, "Gravando arquivo CSV", "Gravacao de arquivo...")

	oTempTable:Delete()

	FWAlertSuccess("GERACAO EFETUADA COM SUCESSO!", "Extracao de Dados de OP")
return


Static Function Processa(oSay)
	Local cSql 			:= ""
	Local cSql2			:= ""
	Local cAlias 		:= ""
	Local cAlias2 		:= ""
	Local nQuant		:= 0
	Local nTotal		:= 0
	Local nSetup		:= 0
	Local cRec1			:= ""
	Local cRec2			:= ""
	Local cRec3			:= ""
	Local cRec4			:= ""
	Local cRec5			:= ""

	cSql := "SELECT C2_NUM, C2_ITEM, C2_SEQUEN, C2_PRODUTO, "
	cSql += "	    C2_QUANT, C2_DATPRI, C2_DATPRF, C2_TPOP, "
	cSql += "	  	B1_COD, B1_DESC, B1_UM, B1_XCLIENT, B1_XITEM, "
	cSql += "	    G2_OPERAC, G2_RECURSO, G2_MAOOBRA, G2_SETUP, "
	cSql += "	  	G2_TEMPAD, G2_LOTEPAD, "
	cSql += "	  	H1_XLIN, H1_XLOCLIN, H1_XTIPO, H1_XSETUP "
	cSql += "  FROM " + RetSQLName("SC2") + " SC2 "

	cSql += " INNER JOIN " + RetSQLName("SB1") + " SB1 "
	cSql += "	 ON B1_COD 		 =  C2_PRODUTO"
	cSql += "   AND B1_FILIAL 	 = '" + xFilial("SB1") + "' "
	cSql += "	AND SB1.D_E_L_E_T_ = ' ' "

	cSql += " INNER JOIN " + RetSQLName("SG2") + " SG2 "
	cSql += "    ON G2_PRODUTO = C2_PRODUTO"
	cSql += "   AND G2_FILIAL 	 = '" + xFilial("SG2") + "' "
	cSql += "   AND SG2.D_E_L_E_T_ = ''

	cSql += " INNER JOIN " + RetSQLName("SH1") + " SH1 "
	cSql += "    ON H1_CODIGO = G2_RECURSO"
	cSql += "   AND H1_FILIAL 	 = '" + xFilial("SH1") + "' "
	cSql += "   AND SH1.D_E_L_E_T_ = ''

	cSql += " WHERE C2_DATPRF >= '" + dtos(dDtIni) + "'"
	cSql += "   AND C2_DATPRF <= '" + dtos(dDtFim) + "'"
	cSql += "   AND C2_FILIAL 	 = '" + xFilial("SC2") + "' "
	cSql += "	AND SC2.D_E_L_E_T_ = ' ' "
	cSql += "	ORDER BY C2_NUM, C2_ITEM, C2_SEQUEN "
	cAlias := MPSysOpenQuery(cSql)

	While (cAlias)->(! EOF())
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

		nTotal := nSetup + nQuant

		cRec1 := (cAlias)->G2_RECURSO
		cRec2 := ""
		cRec3 := ""
		cRec4 := ""
		cRec5 := ""

		cSql2 := "SELECT * FROM " + RetSQLName("SH3") + " SH3 "
		cSql2 += " WHERE H3_PRODUTO = '" + (cAlias)->C2_PRODUTO + "'"
		cSql2 += "   AND H3_RECPRIN = '" + (cAlias)->G2_RECURSO + "'"
		cSql2 += "   AND H3_OPERAC  = '" + (cAlias)->G2_OPERAC + "'"
		cSql2 += "   AND H3_FILIAL 	= '" + xFilial("SH3") + "' "
		cSql2 += "   AND SH3.D_E_L_E_T_ = ' ' "
		cAlias2 := MPSysOpenQuery(cSql2)

		While (cAlias2)->(! EOF())
			if cRec2 == ""
				cRec2 := (cAlias2)->H3_RECALTE
			elseif cRec3 == ""
				cRec3 := (cAlias2)->H3_RECALTE
			elseif cRec4 == ""
				cRec4 := (cAlias2)->H3_RECALTE
			else
				cRec5 := (cAlias2)->H3_RECALTE
			endif

			(cAlias2)->(DbSkip())
		enddo

		(cAlias2)->(DBCLOSEAREA())

		cSql := "INSERT INTO " + cTableName + " ("
		cSql += " ID, TT_PRODUTO, TT_OP, TT_TPOP, TT_DESC, TT_XCLIENT, TT_OPERAC, TT_RECURSO, "
		cSql += " TT_MAOOBRA, TT_TEMPAD, TT_LOTEPAD, TT_DATPRI, TT_DATPRF, TT_QUANT, TT_UM, "
		cSql += " TT_SETUP, TT_QTHS, TT_QTHSTOT, TT_XLIN, TT_XLOCLIN, TT_XTIPO, TT_XITEM, "
		cSql += " TT_REC1, TT_REC2, TT_REC3, TT_REC4, TT_REC5, "
		cSql += " TT_QTREC1, TT_QTREC2, TT_QTREC3, TT_QTREC4, TT_QTREC5) VALUES ('"

		cSql += FWUUIDv4() 			 				+ "','"
		cSql += (cAlias)->C2_PRODUTO 				+ "','"
		cSql += Transform((cAlias)->C2_NUM, "999999") + AllTrim((cAlias)->C2_ITEM) + AllTrim((cAlias)->C2_SEQUEN) +  "','"
		cSql += AllTrim((cAlias)->C2_TPOP) +  "','"
		cSql += AllTrim((cAlias)->B1_DESC) +  "','"
		cSql += AllTrim((cAlias)->B1_XCLIENT) +  "','"
		cSql += AllTrim((cAlias)->G2_OPERAC) +  "','"
		cSql += AllTrim((cAlias)->G2_RECURSO) +  "','"
		cSql += cValToChar((cAlias)->G2_MAOOBRA) +  "','"
		cSql += cValToChar((cAlias)->G2_TEMPAD) +  "','"
		cSql += cValToChar((cAlias)->G2_LOTEPAD) +  "','"
		cSql += (cAlias)->C2_DATPRI +  "','"
		cSql += (cAlias)->C2_DATPRF +  "','"
		cSql += cValToChar((cAlias)->C2_QUANT) +  "','"
		cSql += (cAlias)->B1_UM +  "','"
		cSql += cValToChar(nSetup) +  "','"
		cSql += cValToChar(nQuant) +  "','"
		cSql += cValToChar(nTotal) +  "','"
		cSql += (cAlias)->H1_XLIN +  "','"
		cSql += (cAlias)->H1_XLOCLIN +  "','"
		cSql += (cAlias)->H1_XTIPO +  "','"
		cSql += (cAlias)->B1_XITEM + "','"
		cSql += cRec1 + "','" + cRec2 + "','" + cRec3 + "','" + cRec4 + "','" + cRec5 + "','"
		cSql += "0','0','0','0','0')"

		if TCSqlExec(cSql) < 0
			MsgInfo("Erro na execução da query:", "Atenção")
			MsgInfo(TcSqlError(), "Atenção3")
		endif

		(cAlias)->(DbSkip())
	enddo

	(cAlias)->(DBCLOSEAREA())
return


Static Function GravaCSV(oSay)
	Local cSql 		:= ""
	Local cAlias	:= ""
	Local cArquivo	:= "c:\temp\PL070.csv"
	Local cLinha	:= ""
	Local nParada	:= 0
	Local nMaoObra	:= 0

	cSql := "SELECT * FROM " + cTableName
	cAlias := MPSysOpenQuery(cSql)

	oFile := FWFileWriter():New(cArquivo, .T.)

	If oFile:Exists()
		oFile:Erase()
	EndIf

	If (oFile:Create())
		cLinha := "Numero Ordem;Tipo;Produto;Descricao;Cliente;Operacao;Maquina;Operadores;Tempo Padrao;Lote Padrao;Dt.Inicio;Dt.Fim;"
		cLinha += "Quantidade;UM;Setup;Qtde.Horas;Horas Totais;Horas Totais Com Paradas;Tempo Operador;Linha de Producao;"
		cLinha += "Local da Maquina;Tipo de Maquina;Alternativa 2;Alternativa 3;Alternativa 4;Alternativa 5"
		oFile:Write(cLinha + CRLF)

		While (cAlias)->(! EOF())
			if (cAlias)->TT_QTHS > 1
				nParada := (cAlias)->TT_QTHS * 0.1
			else
				nParada := 0
			endif

			nParada := nParada + (cAlias)->TT_QTHSTOT

			nMaoObra := (cAlias)->TT_MAOOBRA * nParada

			cLinha := (cAlias)->TT_OP + ";"
			cLinha += AllTrim((cAlias)->TT_TPOP) + ";"
			cLinha += AllTrim((cAlias)->TT_PRODUTO) + ";"
			cLinha += AllTrim((cAlias)->TT_DESC) + ";"
			cLinha += AllTrim((cAlias)->TT_XCLIENT) + ";"
			cLinha += AllTrim((cAlias)->TT_OPERAC) + ";"
			cLinha += AllTrim((cAlias)->TT_RECURSO) + ";"
			cLinha += AllTrim(cValToChar((cAlias)->TT_MAOOBRA)) + ";"
			cLinha += TRANSFORM((cAlias)->TT_TEMPAD, "@E 999999.99") + ";"
			cLinha += TRANSFORM((cAlias)->TT_LOTEPAD, "@E 999999.99") + ";"
			cLinha += dtoc(stod((cAlias)->TT_DATPRI)) + ";"
			cLinha += dtoc(stod((cAlias)->TT_DATPRF)) + ";"
			cLinha += TRANSFORM((cAlias)->TT_QUANT, "@E 999999") + ";"
			cLinha += AllTrim((cAlias)->TT_UM) + ";"
			cLinha += TRANSFORM((cAlias)->TT_SETUP, "@E 999999.99") + ";"
			cLinha += TRANSFORM((cAlias)->TT_QTHS, "@E 999999.99") + ";"
			cLinha += TRANSFORM((cAlias)->TT_QTHSTOT, "@E 999999.99") + ";"
			cLinha += TRANSFORM(nParada, "@E 999999.99") + ";"
			cLinha += TRANSFORM(nMaoObra, "@E 999999.99") + ";"
			cLinha += AllTrim((cAlias)->TT_XLIN) + ";"
			cLinha += AllTrim((cAlias)->TT_XLOCLIN) + ";"
			cLinha += AllTrim((cAlias)->TT_XTIPO) + ";"
			cLinha += AllTrim((cAlias)->TT_REC2) + ";"
			cLinha += AllTrim((cAlias)->TT_REC3) + ";"
			cLinha += AllTrim((cAlias)->TT_REC4) + ";"
			cLinha += AllTrim((cAlias)->TT_REC5) + ";"
			oFile:Write(cLinha + CRLF)

			(cAlias)->(DbSkip())
		enddo

		oFile:Close()
	Endif

	(cAlias)->(DBCLOSEAREA())
return
