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
/*/

User Function PL020C()
	Local aArea   := GetArea()
	Local cFunBkp := FunName()

	Private cAliasTT
	Private cTableName
	Private oTempTable

	Private nSequencia  := 0
	Private	cProd       := ""
	Private nQtde       := 0
	Private cLocal      := ""
	Private cDoc        := ""
	Private dDtIni

	SetFunName("PL020C")

	oTempTable := FWTemporaryTable():New()

	//Adiciona no array das colunas as que serão incluidas (Nome do Campo, Tipo do Campo, Tamanho, Decimais)
	aFields := {}
	aAdd(aFields, {"ID",      "C", 36, 0})
	aAdd(aFields, {"TT_PROD", "C", 15, 0})
	aAdd(aFields, {"TT_DATA", "C", 10, 0})
	aAdd(aFields, {"TT_QUANT","N",  8, 2})
	aAdd(aFields, {"TT_LOCAL","C",  2, 0})
	aAdd(aFields, {"TT_DOC",  "C", 10, 0})
	aAdd(aFields, {"TT_DIAEO","N",  3, 0})

	oTempTable:SetFields( aFields )
	oTempTable:AddIndex("1", {"ID"} )
	oTempTable:AddIndex("2", {"TT_PROD", "TT_DATA"} )
	oTempTable:Create()

	cAliasTT    := oTempTable:GetAlias()
	cTableName  := oTempTable:GetRealName()

	CriaEDI()
	CriaPV()
	GravaDemandas()

	oTempTable:Delete()

	FWAlertSuccess("Demandas geradas com sucesso!", "Geracao de Demandas para o MRP")

	SetFunName(cFunBkp)
	RestArea(aArea)
Return

/*---------------------------------------------------------------------*
	Grava tabela temporaria com base nos pedidos EDI
 *---------------------------------------------------------------------*/
Static Function CriaEDI()
    Local dData, cAlias

	strSql := "SELECT ZA0_DTENTR, ZA0_PRODUT, B1_LOCPAD, B1_XDIAEO, ZA0_QTDE, ZA0_NUMPED, ZA0_QTDE - ZA0_QTCONF AS ZA0_SALDO "
	strSql += " FROM ZA0010, SB1010 "                     
	strSql += " WHERE ZA0_STATUS = '0' "          
	strSql += " AND ZA0_FILIAL   = B1_FILIAL "    
	strSql += " AND ZA0_PRODUT   = B1_COD "       
	strSql += " AND ZA0010.D_E_L_E_T_ <> '*' "          
	strSql += " AND SB1010.D_E_L_E_T_ <> '*' "          
	strSql += " ORDER BY ZA0_CLIENT, ZA0_LOJA, ZA0_PRODUT " 
	cAlias := MPSysOpenQuery(strSql)

	While (cAlias)->(!EOF())
        dData := DaySub(Stod((cAlias)->ZA0_DTENTR), 1)

        if Dow(dData) = 1
            dData := DaySub(dData, 2)
        Endif
        if Dow(dData) = 7
            dData := DaySub(dData, 1)
        Endif

        cSql := "INSERT INTO " + cTableName + " (ID, TT_PROD, TT_LOCAL, TT_QUANT, TT_DATA, TT_DOC, TT_DIAEO) VALUES "
        cSql += "('" + FWUUIDv4() + "','" + (cAlias)->ZA0_PRODUT + "'"
        cSql += ",'" + (cAlias)->B1_LOCPAD + "','" + cValToChar((cAlias)->ZA0_SALDO) + "'" 
        cSql += ",'" + dtoc( dData) + "','" + (cAlias)->ZA0_NUMPED + "'" 
        cSql += ",'" + cValToChar((cAlias)->B1_XDIAEO) + "')"

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
Static Function CriaPV()
    Local dData, cAlias

    strSql := "SELECT B1_COD, C6_LOCAL, C6_ENTREG, C6_QTDVEN, C6_NUM, B1_XDIAEO, C6_QTDVEN - C6_QTDENT AS C6_SALDO "
    strSql += " FROM SC5010, SC6010, SB1010, SF4010 "  
    strSql += " WHERE C5_NOTA      = '' "         
    strSql += " AND C5_LIBEROK    <> 'E' "       
    strSql += " AND C5_FILIAL      = C6_FILIAL " 
    strSql += " AND C5_NUM         = C6_NUM "    
    strSql += " AND C6_QTDENT      < C6_QTDVEN " 
    strSql += " AND SC6010.C6_BLQ <> 'R' "       
    strSql += " AND C6_FILIAL      = B1_FILIAL "  
    strSql += " AND C6_PRODUTO     = B1_COD "     
    strSql += " AND C5_FILIAL      = F4_FILIAL "  
    strSql += " AND F4_CODIGO      = C6_TES "     
    strSql += " AND F4_QTDZERO    <> '1' "       
    strSql += " AND SC5010.D_E_L_E_T_   <> '*' "       
    strSql += " AND SC6010.D_E_L_E_T_   <> '*' "       
    strSql += " AND SF4010.D_E_L_E_T_   <> '*' "       
    strSql += " AND SB1010.D_E_L_E_T_   <> '*' "       
    cAlias := MPSysOpenQuery(strSql)

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

	// Limpar as demandas existentes - manuais - "AUTO"
	LimpaDemandas()

    cAlias := GetNextAlias()

	strSql := "SELECT * FROM  "  + cTableName
	strSql += " ORDER BY TT_PROD, TT_DATA "

    DBUseArea(.T., "TOPCONN", TCGenQry(,,strSql), cAlias, .T., .T.)

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
		T4J->T4J_IDREG  := SVR->VR_FILIAL + SVR->VR_CODIGO + str(SVR->VR_SEQUEN)
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
