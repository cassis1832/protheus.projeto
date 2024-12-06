#Include 'Protheus.ch'
#Include 'FWMVCDef.ch'
#Include "tbiconn.ch"

/*/{Protheus.doc} PL020C
	Atualização das demandas do MRP com base no EDI e nos pedidos de vendas
    Atualizar tabelas SVB e SVR - demandas do MRP (cliente/loja)
@author Assis
@since 11/04/2024
@version 1.0
	@return Nil, Função não tem retorno
	@example
	u_PL020C()

	02/08/2024 - Desprezar previsao no passado
	07/08/2024 - Tratar item bloqueado
	27/08/2024 - Gerar demandas com 2 dias de diferença para a Gestamp
	08/09/2024 - Gerar demanda de plano mestre para a Gestamp
	22/09/2024 - Nao gravar T4j porque ele atualiza na sincronizacao
	08/09/2024 - Gerar demanda manual para a Gestamp
/*/

User Function PL020C()
	Local aArea   	:= GetArea()
	Local cFunBkp 	:= FunName()
	Local oSay 		:= NIL

	SetFunName("PL020C")

	FwMsgRun(NIL, {|oSay| Processa(oSay)}, "Processando pedidos", "Gerando demandas...")

	FWAlertSuccess("DEMANDAS GERADAS COM SUCESSO!", "Geracao de Demandas para o MRP")

	SetFunName(cFunBkp)
	RestArea(aArea)
Return


Static Function Processa(oSay)

	Private cAliasTT
	Private cTableName

	Private dtProcesso 	:= Date()
	Private hrProcesso 	:= Time()

	Private oTempTable

	oTempTable := FWTemporaryTable():New()

	//Adiciona no array das colunas as que serão incluidas (Nome do Campo, Tipo do Campo, Tamanho, Decimais)
	aFields := {}
	aAdd(aFields, {"ID",      "C", 36, 0})
	aAdd(aFields, {"TT_PROD", "C", 15, 0})
	aAdd(aFields, {"TT_DATA", "D",  8, 0})
	aAdd(aFields, {"TT_QUANT","N",  8, 2})
	aAdd(aFields, {"TT_LOCAL","C",  2, 0})
	aAdd(aFields, {"TT_DOC",  "C", 10, 0})
	aAdd(aFields, {"TT_DIAEO","N",  3, 0})
	aAdd(aFields, {"TT_ORIG", "C",  3, 0})
	aAdd(aFields, {"TT_TIPO", "C",  1, 0})

	oTempTable:SetFields( aFields )
	oTempTable:AddIndex("1", {"ID"} )
	oTempTable:Create()

	cAliasTT    := oTempTable:GetAlias()
	cTableName  := oTempTable:GetRealName()

	TrataEDI()

	TrataPV()

	GravaDemandas()

	oTempTable:Delete()
Return

/*---------------------------------------------------------------------*
	Grava tabela temporaria com base nos pedidos EDI
 *---------------------------------------------------------------------*/
Static Function TrataEDI()
    Local dData, cAlias, cTipo

	dData := DaySum(Date(), 180)

	cSQL := "SELECT ZA0_CLIENT, ZA0_DTENTR, ZA0_PRODUT, B1_LOCPAD, B1_XDIAEO, ZA0_QTDE, "
	cSQL += " 	    ZA0_NUMPED, ZA0_QTDE - ZA0_QTCONF AS ZA0_SALDO, ZA0_TIPOPE "
	cSQL += "  FROM " + RetSQLName("ZA0") + " ZA0 "
	
	cSQL += " INNER JOIN " + RetSQLName("SB1") + " SB1 "
	cSQL += "    ON B1_COD 			=  ZA0_PRODUT "       
	cSql += "   AND B1_MSBLQL 		=  '2' "
	cSQL += "   AND B1_FILIAL    	=  '" + xFilial("SB1") + "'"
	cSQL += "   AND SB1.D_E_L_E_T_ 	<> '*' "          
	
	cSQL += " WHERE ZA0_STATUS 		=  '0' "          
	cSql += "   AND ZA0_DTENTR 		<= '" + Dtos(dData) + "'"
	cSQL += "   AND ZA0_FILIAL   	=  '" + xFilial("ZA0") + "'"
	cSQL += "   AND ZA0.D_E_L_E_T_	<> '*' "          
	cSQL += " ORDER BY ZA0_CLIENT, ZA0_LOJA, ZA0_PRODUT " 
	cAlias := MPSysOpenQuery(cSQL)

	While (cAlias)->(!EOF())
		cTipo := "9"

		if (cAlias)->ZA0_TIPOPE == "V"
        	dData := Stod((cAlias)->ZA0_DTENTR)
			if Dow(dData) = 1
				dData := DaySum(dData, 1)
			Endif
			if Dow(dData) = 7
				dData := DaySum(dData, 2)
			Endif
		else
        	dData := DaySub(Stod((cAlias)->ZA0_DTENTR), 2)
		
			if Dow(dData) = 1
				dData := DaySub(dData, 2)
			Endif
			if Dow(dData) = 7
				dData := DaySub(dData, 1)
			Endif
		endif
 
		if (cAlias)->ZA0_TIPOPE == "F" .or. dData > date()
			cSql := "INSERT INTO " + cTableName + " " 
			cSql += "(ID, TT_PROD, TT_LOCAL, TT_QUANT, TT_DATA, TT_DOC, TT_DIAEO, TT_TIPO, TT_ORIG) "
			cSql += "VALUES ('" + FWUUIDv4() 		+ "','" 
			cSql += (cAlias)->ZA0_PRODUT 			+ "','"
			cSql += (cAlias)->B1_LOCPAD 			+ "','" 
			cSql += cValToChar((cAlias)->ZA0_SALDO) + "','" 
			cSql += dtos(dData) 					+ "','" 
			cSql += (cAlias)->ZA0_NUMPED 			+ "','" 
			cSql += cValToChar((cAlias)->B1_XDIAEO) + "','"
			cSql += cTipo 							+ "','"
			cSql += "ZA0" 							+ "')"

			if TCSqlExec(cSql) < 0
				MsgInfo("Erro na execução da query:", "Atenção")
				MsgInfo(TcSqlError(), "Atenção2")
			endif
		endif
		
		(cAlias)->(DbSkip())
  	End While

	(cAlias)->(DBCloseArea())
Return

/*---------------------------------------------------------------------*
	Grava tabela temporária com base nos pedidos de vendas
 *---------------------------------------------------------------------*/
Static Function TrataPV()
    Local dData, cAlias

    cSQL := "SELECT B1_COD, C6_LOCAL, C6_ENTREG, C6_QTDVEN, C6_NUM, B1_XDIAEO, (C6_QTDVEN - C6_QTDENT) AS C6_SALDO "
	cSQL += "  FROM " + RetSQLName("SC5") + " SC5 "

	cSQL += " INNER JOIN " + RetSQLName("SC6") + " SC6 "
    cSQL += "    ON C6_NUM         	=  C5_NUM "    
    cSQL += "   AND C6_QTDENT      	<  C6_QTDVEN " 
    cSQL += "   AND C6_BLQ 			<> 'R' "       
    cSQL += "   AND C6_FILIAL      	=  '" + xFilial("SC6") + "'"
    cSQL += "   AND SC6.D_E_L_E_T_ 	<> '*' "       
	
	cSQL += " INNER JOIN " + RetSQLName("SB1") + " SB1 "
    cSQL += "    ON B1_COD			=  C6_PRODUTO "     
    cSQL += "   AND B1_MRP			=  'S' "     
	cSql += "   AND B1_MSBLQL 		=  '2' "
    cSQL += "   AND B1_FILIAL      	=  '" + xFilial("SB1") + "'"
    cSQL += "   AND SB1.D_E_L_E_T_  <> '*' "       
	
	cSQL += " INNER JOIN " + RetSQLName("SF4") + " SF4 "
    cSQL += "    ON F4_CODIGO      	=  C6_TES "
    cSQL += "   AND F4_QTDZERO    	<> '1' "       
    cSQL += "   AND F4_FILIAL      	=  '" + xFilial("SF4") + "'"
    cSQL += "   AND SF4.D_E_L_E_T_  <> '*' "       
    
	cSQL += " WHERE C5_NOTA      	=  '' "         
    cSQL += "   AND C5_LIBEROK    	<> 'E' "       
    cSQL += "   AND C5_FILIAL      	=  '" + xFilial("SC5") + "'"
    cSQL += "   AND SC5.D_E_L_E_T_  <> '*' "       
    cAlias := MPSysOpenQuery(cSQL)

	While (cAlias)->(!EOF())
        dData := DaySub(Stod((cAlias)->C6_ENTREG), 1)
        if Dow(dData) = 1
            dData := DaySub(dData, 2)
        Endif
        if Dow(dData) = 7
            dData := DaySub(dData, 1)
        Endif

        cSql := "INSERT INTO " + cTableName + " (ID, TT_PROD, TT_LOCAL, TT_QUANT, TT_DATA, TT_DOC, TT_DIAEO, TT_TIPO, TT_ORIG) "
		cSql += "VALUES ('" + FWUUIDv4() 			+ "','" 
		cSql += (cAlias)->B1_COD 					+ "','"
		cSql += (cAlias)->C6_LOCAL 					+ "','" 
		cSql += cValToChar((cAlias)->C6_SALDO) 		+ "','" 
		cSql += dtos(dData) 						+ "','" 
		cSql += (cAlias)->C6_NUM 					+ "','" 
		cSql += cValToChar((cAlias)->B1_XDIAEO) 	+ "','"
		cSql += "1" 								+ "','"
		cSql += "SC6" 								+ "')"

        if TCSqlExec(cSql) < 0
           MsgInfo("Erro na execução da query:", "Atenção")
           MsgInfo(TcSqlError(), "Atenção2")
        endif

		(cAlias)->(DbSkip())
  	End While

	(cAlias)->(DBCloseArea())
Return


/*---------------------------------------------------------------------*
    Gera novas demandas a partir da tabela temporária
    Agrupa por dias entre ordens
 *---------------------------------------------------------------------*/
Static Function GravaDemandas()
	Local cSql		:= ''
    Local cAlias	:= ''
	Local dDtFim	:= ''

	Private dDtIni	
	Private	cProd       := ""
	Private cLocal      := ""
	Private cDoc        := ""
	Private nQtde       := 0
	Private cTipo       := ""
	Private nSequencia  := 0

	cSql := "DELETE FROM "  + RetSQLName("SVR")
	cSql += " WHERE VR_FILIAL  	=  '" + xFilial("SVR") + "' "
	cSql += "	AND VR_CODIGO  	=  'AUTO'"

	if TCSqlExec(cSql) < 0
		MsgInfo("Erro na delete do SVR:", "Atenção")
		MsgInfo(TcSqlError(), "Atenção")
	endif

    cAlias := GetNextAlias()

	cSQL := "SELECT * FROM  "  + cTableName
	cSQL += " ORDER BY TT_PROD, TT_DATA "
    DBUseArea(.T., "TOPCONN", TCGenQry(,,cSQL), cAlias, .T., .T.)

    while !(cAlias)->(Eof())
        if cProd != (cAlias)->TT_PROD
            if cProd != ""
                GravaReg()
            endif
            cProd  := (cAlias)->TT_PROD
            dDtIni := stod((cAlias)->TT_DATA)
            dDtFim := DaySum(dDtIni, (cAlias)->TT_DIAEO)
            cDoc   := (cAlias)->TT_DOC
            cLocal := (cAlias)->TT_LOCAL
            nQtde  := (cAlias)->TT_QUANT
            cTipo  := (cAlias)->TT_TIPO
		else
			if dDtFim >= stod((cAlias)->TT_DATA)
				nQtde := nQtde + (cAlias)->TT_QUANT
			else
				GravaReg()
				dDtIni := stod((cAlias)->TT_DATA)
				dDtFim := DaySum(dDtIni, (cAlias)->TT_DIAEO)
				cDoc   := (cAlias)->TT_DOC
	            cLocal := (cAlias)->TT_LOCAL
				nQtde  := (cAlias)->TT_QUANT
            	cTipo  := (cAlias)->TT_TIPO
			endif
        endif

        (cAlias)->(DBSkip())
	end while
    
    if nQtde > 0
        GravaReg()
    endif

    (cAlias)->(DBCloseArea())
return

/*---------------------------------------------------------------------*
    Grava SVR 
 *---------------------------------------------------------------------*/
Static Function GravaReg()

		if nQtde <= 0
			return
		endif

		nSequencia := nSequencia + 1

		DbSelectArea("SVR")
		RecLock("SVR", .T.)
		SVR->VR_FILIAL	:= xFilial("SVR")
		SVR->VR_CODIGO  := "AUTO"
		SVR->VR_SEQUEN  := nSequencia
		SVR->VR_PROD 	:= cProd
		SVR->VR_DATA 	:= dDtIni
		SVR->VR_QUANT	:= nQtde
		SVR->VR_LOCAL  	:= cLocal
		SVR->VR_DOC 	:= cDoc
		SVR->VR_TIPO   	:= cTipo
		SVR->VR_REGORI  := 0
		SVR->VR_ORIGEM  := 'SVR'
		SVR->VR_XDTCRI  := dtProcesso
		SVR->VR_XHRCRI 	:= hrProcesso
		SVR->(MsUnlock())

return
