#Include 'Protheus.ch'
#Include 'FWMVCDef.ch'

/*/{Protheus.doc} CARGA01
Função: CARGA01
@author Assis
@since 07/06/2024
@version 1.0
	@return Nil, Fução não tem retorno
	@example
	u_PL070()
/*/

Static cTitulo := "CARGA 01"

User Function CARGA01()
	Local cSql	:= ""
	Local cAlias

	cSQL += "SELECT C2_NUM, C2_ITEM, C2_SEQUEN, C2_PRODUTO, C2_QUANT, C2_DATPRI, C2_DATPRF, C2_QUJE, "
	cSQL += "		G2_OPERAC, G2_RECURSO, G2_MAOOBRA, G2_SETUP, G2_TEMPAD, G2_LOTEPAD "
	cSQL += "  FROM " + RetSQLName("SC2") + " SC2 "
	cSQL += " INNER JOIN " + RetSQLName("SG2") + " SG2 "
	cSQL += "    ON G2_PRODUTO 		=  C2_PRODUTO "
	cSQL += " WHERE C2_DATPRI 		>= '20240701' "
	cSQL += "   AND SC2.D_E_L_E_T_ 	= '' "
	cSQL += "   AND SG2.D_E_L_E_T_ 	= '' "
	cSQL += "   AND C2_FILIAL    	=  '" + xFilial("SC2") + "'"
	cSQL += "   AND G2_FILIAL    	=  '" + xFilial("SG2") + "'"
	cSQL += " ORDER BY C2_NUM, C2_ITEM, C2_SEQUEN, G2_OPERAC "
	cAlias := MPSysOpenQuery(cSQL)

	While (cAlias)->(!EOF())
		dData := DaySub(Stod((cAlias)->ZA0_DTENTR), 1)

		if Dow(dData) = 1
			dData := DaySub(dData, 2)
		Endif
		if Dow(dData) = 7
			dData := DaySub(dData, 1)
		Endif

		cSql := "INSERT INTO " + cTableName + " "
		cSql += "(ID, TT_PROD, TT_LOCAL, TT_QUANT, TT_DATA, TT_DOC, TT_DIAEO) "
		cSql += "VALUES ('"
		cSql += FWUUIDv4() 						+ "','"
		cSql += (cAlias)->ZA0_PRODUT 			+ "','"
		cSql += (cAlias)->B1_LOCPAD 			+ "','"
		cSql += cValToChar((cAlias)->ZA0_SALDO) + "','"
		cSql += dtoc( dData) 					+ "','"
		cSql += (cAlias)->ZA0_NUMPED 			+ "','"
		cSql += cValToChar((cAlias)->B1_XDIAEO) + "')"

		if TCSqlExec(cSql) < 0
			MsgInfo("Erro na execução da query:", "Atenção")
			MsgInfo(TcSqlError(), "Atenção2")
		endif

		(cAlias)->(DbSkip())

	End While
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
	cSQL += " INNER JOIN " + RetSQLName("SB1") + " SB1 "
    cSQL += "    ON B1_COD			=  C6_PRODUTO "     
	cSQL += " INNER JOIN " + RetSQLName("SF4") + " SF4 "
    cSQL += "    ON F4_CODIGO      	=  C6_TES "
    cSQL += "   AND F4_QTDZERO    	<> '1' "       
    cSQL += " WHERE C5_NOTA      	=  '' "         
    cSQL += "   AND C5_LIBEROK    	<> 'E' "       
    cSQL += "   AND C5_FILIAL      	=  '" + xFilial("SC5") + "'"
    cSQL += "   AND C6_FILIAL      	=  '" + xFilial("SC6") + "'"
    cSQL += "   AND B1_FILIAL      	=  '" + xFilial("SB1") + "'"
    cSQL += "   AND F4_FILIAL      	=  '" + xFilial("SF4") + "'"
    cSQL += "   AND SC5.D_E_L_E_T_  <> '*' "       
    cSQL += "   AND SC6.D_E_L_E_T_ 	<> '*' "       
    cSQL += "   AND SB1.D_E_L_E_T_  <> '*' "       
    cSQL += "   AND SF4.D_E_L_E_T_  <> '*' "       
    cAlias := MPSysOpenQuery(cSQL)

	While (cAlias)->(!EOF())

        dData := DaySub(Stod((cAlias)->C6_ENTREG), 1)

        if Dow(dData) = 1
            dData := DaySub(dData, 2)
        Endif
        if Dow(dData) = 7
            dData := DaySub(dData, 1)
        Endif

        cSql := "INSERT INTO " + cTableName + " (ID, TT_PROD, TT_LOCAL, TT_QUANT, TT_DATA, TT_DOC, TT_DIAEO) VALUES "
        cSql += "('" + FWUUIDv4() + "','" + (cAlias)->B1_COD + "'"
        cSql += ",'" + (cAlias)->C6_LOCAL + "','" + cValToChar((cAlias)->C6_SALDO) + "'" 
        cSql += ",'" + dtoc(dData) + "','" + (cAlias)->C6_NUM + "'" 
        cSql += ",'" + cValToChar((cAlias)->B1_XDIAEO) + "')"

        if TCSqlExec(cSql) < 0
           MsgInfo("Erro na execução da query:", "Atenção")
           MsgInfo(TcSqlError(), "Atenção2")
        endif

		(cAlias)->(DbSkip())
  	End While
Return


/*---------------------------------------------------------------------*
    Gera novas demandas a partir da tabela temporária
    Agrupa por dias entre ordens
 *---------------------------------------------------------------------*/
Static Function GravaDemandas()
    Local cAlias
		
	Private nSequencia  := 0

	// Limpar as demandas existentes - manuais - "AUTO"
	LimpaDemandas()

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
            dDtIni := CToD((cAlias)->TT_DATA)
            dDtFim := DaySum(CToD((cAlias)->TT_DATA), (cAlias)->TT_DIAEO)
            cDoc   := (cAlias)->TT_DOC
            cLocal :=  (cAlias)->TT_LOCAL
            nQtde  := 0
        endif

        if dDtFim >= CToD((cAlias)->TT_DATA)
            nQtde := nQtde + (cAlias)->TT_QUANT
        else
            GravaReg()
            dDtIni := CToD((cAlias)->TT_DATA)
            dDtFim := DaySum(CToD((cAlias)->TT_DATA), (cAlias)->TT_DIAEO)
            cDoc   := (cAlias)->TT_DOC
            nQtde  := 0
        endif

        (cAlias)->(DBSkip())
	end while
    
    if nQtde > 0
        GravaReg()
    endif

    (cAlias)->(DBCloseArea())
return

/*---------------------------------------------------------------------*
    Grava SVR e T4J
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
		SVR->VR_QUANT 	:= nQtde
		SVR->VR_DATA 	:= dDtIni
		SVR->VR_LOCAL  	:= cLocal
		SVR->VR_DOC 	:= cDoc
		SVR->VR_TIPO   	:= "9"
		SVR->VR_REGORI  := 0
		SVR->VR_ORIGEM  := 'SVR'
		SVR->(MsUnlock())

		DbSelectArea("T4J")
		RecLock("T4J", .T.)
		T4J->T4J_FILIAL	:= SVR->VR_FILIAL
		T4J->T4J_DATA 	:= SVR->VR_DATA
		T4J->T4J_PROD 	:= SVR->VR_PROD
		T4J->T4J_ORIGEM := SVR->VR_TIPO
		T4J->T4J_DOC 	:= SVR->VR_DOC
		T4J->T4J_QUANT 	:= SVR->VR_QUANT
		T4J->T4J_LOCAL  := SVR->VR_LOCAL
		T4J->T4J_IDREG  := SVR->VR_FILIAL + SVR->VR_CODIGO + cValToChar(nSequencia)
		T4J->T4J_CODE   := SVR->VR_CODIGO
		T4J->T4J_PROC	:= '2'
		T4J->(MsUnlock())

return

/*---------------------------------------------------------------------*
	Elimina todas as demandas do codigo "AUTO"
 *---------------------------------------------------------------------*/
Static Function LimpaDemandas()

	dbSelectArea("SVR")
	SVR->(DBSetOrder(1))  // 
	DBGoTop()

    While SVR->( !Eof() )

        if VR_CODIGO = 'AUTO'
            RecLock("SVR", .F.)
            DbDelete()
            SVR->(MsUnlock())
        EndIf

        SVR->( dbSkip() )

  	End While

	dbSelectArea("T4J")
	T4J->(DBSetOrder(1))  // 
	DBGoTop()

    While T4J->( !Eof() )

		if T4J_CODE = 'AUTO'
      		RecLock("T4J", .F.)
      		DbDelete()
      		SVR->(MsUnlock())
		EndIf

		T4J->( dbSkip() )

  	End While

return
