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
	Local aArea   		:= GetArea()
	Local cFunBkp 		:= FunName()

	SetFunName("PL020C")

	// Limpar as demandas existentes - manuais - "AUTO"
	LimpaDemandas()

	// Criar demandas com base no EDI
	CriaEDI()

	// Criar demandas com base nos pedidos de vendas
	CriaPV()

	SetFunName(cFunBkp)
	RestArea(aArea)
Return

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

/*---------------------------------------------------------------------*
	Cria as demandas no codigo "AUTO" com base nos pedidos EDI
 *---------------------------------------------------------------------*/
Static Function CriaEDI()
	
	Local nSequencia := 0

	strSql := "SELECT ZA0010.* "
	strSql += " FROM ZA0010, SB1010 "                     + CRLF
	strSql += " WHERE ZA0_STATUS        =  '0' "          + CRLF
	strSql += " AND ZA0_FILIAL          =  B1_FILIAL "    + CRLF
	strSql += " AND ZA0_PRODUT          =  B1_COD "       + CRLF
	strSql += " AND ZA0010.D_E_L_E_T_   <> '*' "          + CRLF
	strSql += " AND SB1010.D_E_L_E_T_   <> '*' "          + CRLF

	strSql += " ORDER BY ZA0_CLIENT, ZA0_LOJA, ZA0_PRODUT " + CRLF

	cAlias := MPSysOpenQuery(strSql)

	While (cAlias)->(!EOF())

		nSequencia := nSequencia + 1

      // Inclusao
      DbSelectArea("SVR")
      RecLock("SVR", .T.)	
      SVR->VR_FILIAL		:= xFilial("SVR")
      SVR->VR_CODIGO   	:= "AUTO"
      SVR->VR_SEQUEN   	:= nSequencia
      SVR->VR_PROD 		:= (cAlias)->ZA0_PRODUT
      SVR->VR_LOCAL   	:= (cAlias)->B1_LOCAL
      SVR->VR_DATA 	  	:= (cAlias)->ZA0_DTENTR
      SVR->VR_QUANT 	   := (cAlias)->ZA0_QTDE
      SVR->VR_DOC 		:= (cAlias)->ZA0_NUMPED
      SVR->VR_TIPO   	:= "9"
      SVR->VR_REGORI   	:= 0
      SVR->VR_ORIGEM   	:= 'SVR'
      SVR->(MsUnlock())

      DbSelectArea("T4J")
      RecLock("T4J", .T.)	
      T4J->T4J_FILIAL	:= SVR->VR_FILIAL
      T4J->T4J_DATA 	  	:= SVR->VR_DATA
      T4J->T4J_PROD 		:= SVR->VR_PROD
      T4J->T4J_ORIGEM   := SVR->VR_TIPO
      T4J->T4J_DOC 		:= SVR->VR_DOC
      T4J->T4J_QUANT 	:= SVR->VR_QUANT
      T4J->T4J_LOCAL   	:= SVR->VR_LOCAL
      T4J->T4J_IDREG   	:= SVR->VR_FILIAL + SVR->VR_CODIGO + str(SVR->VR_SEQUEN)
      T4J->T4J_CODE   	:= SVR->VR_CODIGO
      T4J->T4J_PROC		:= '2'
      T4J->(MsUnlock())
		
		(cAlias)->(DbSkip())
     
  	End While

Return

/*---------------------------------------------------------------------*
	Cria as demandas no codigo "AUTO" com base nos pedidos de vendas
 *---------------------------------------------------------------------*/
Static Function CriaPV()
	Local nSequencia := 0

   strSql := "SELECT B1_COD, C6_LOCAL, C6_ENTREG, C6_QTDVEN, C6_NUM "
   strSql += " FROM SC5010, SC6010, SB1010, SF4010 "  + CRLF
   strSql += " WHERE C5_NOTA           = '' "         + CRLF
   strSql += " AND C5_LIBEROK          <> 'E' "       + CRLF
   
   strSql += " AND C5_FILIAL           =  C6_FILIAL " + CRLF
   strSql += " AND C5_NUM              =  C6_NUM "    + CRLF
   strSql += " AND C6_QTDENT           <= C6_QTDVEN " + CRLF
   strSql += " AND SC6010.C6_BLQ       <> 'R' "       + CRLF

   strSql += " AND C6_FILIAL           = B1_FILIAL "  + CRLF
   strSql += " AND C6_PRODUTO          = B1_COD "     + CRLF

   strSql += " AND C5_FILIAL           = F4_FILIAL "  + CRLF
   strSql += " AND F4_CODIGO           = C6_TES "     + CRLF
   strSql += " AND F4_QTDZERO          <> '1' "       + CRLF
   
   strSql += " AND SC5010.D_E_L_E_T_   <> '*' "       + CRLF
   strSql += " AND SC6010.D_E_L_E_T_   <> '*' "       + CRLF
   strSql += " AND SF4010.D_E_L_E_T_   <> '*' "       + CRLF
   strSql += " AND SB1010.D_E_L_E_T_   <> '*' "       + CRLF

   cAlias := MPSysOpenQuery(strSql)

	While (cAlias)->(!EOF())

		nSequencia := nSequencia + 1

      // Inclusao
      DbSelectArea("SVR")
      RecLock("SVR", .T.)	
      SVR->VR_FILIAL		:= xFilial("SVR")
      SVR->VR_CODIGO   	:= "AUTO"
      SVR->VR_SEQUEN   	:= nSequencia
      SVR->VR_PROD 		:= (cAlias)->B1_COD
      SVR->VR_LOCAL   	:= (cAlias)->C6_LOCAL
      SVR->VR_DATA 	  	:= (cAlias)->C6_ENTREG
      SVR->VR_QUANT 	   := (cAlias)->C6_QTDVEN - (cAlias)->C6_QTDENT
      SVR->VR_DOC 		:= (cAlias)->C6_NUM
      SVR->VR_TIPO   	:= "9"
      SVR->VR_REGORI   	:= 0
      SVR->VR_ORIGEM   	:= 'SVR'
      SVR->(MsUnlock())

      DbSelectArea("T4J")
      RecLock("T4J", .T.)	
      T4J->T4J_FILIAL	:= SVR->VR_FILIAL
      T4J->T4J_DATA 	  	:= SVR->VR_DATA
      T4J->T4J_PROD 		:= SVR->VR_PROD
      T4J->T4J_ORIGEM   := SVR->VR_TIPO
      T4J->T4J_DOC 		:= SVR->VR_DOC
      T4J->T4J_QUANT 	:= SVR->VR_QUANT
      T4J->T4J_LOCAL   	:= SVR->VR_LOCAL
      T4J->T4J_IDREG   	:= SVR->VR_FILIAL + SVR->VR_CODIGO + str(SVR->VR_SEQUEN)
      T4J->T4J_CODE   	:= SVR->VR_CODIGO
      T4J->T4J_PROC		:= '2'
      T4J->(MsUnlock())
		
		(cAlias)->(DbSkip())

  	End While

Return
