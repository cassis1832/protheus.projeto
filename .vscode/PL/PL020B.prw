#Include 'Protheus.ch'
#Include 'FWMVCDef.ch'
#Include "tbiconn.ch"

/*/{Protheus.doc} PL020B
Função 
   Gerar pedidos EDI para a Gestamp - clientes 4/5/6/7
   Gravar tabela ZA0 
   Esse programa chamado a partir do PL020 (manutenção do ZA0)
	18/07/2024 - Tratamento de entrega pelo dia da semana
	24/07/2024 - Criacao do tipope = V
	07/08/2024 - Tratar item bloqueado
@author Assis
@since 24/06/2024
@version 1.0
/*/

User Function PL020B()
	Local aArea   		:= GetArea()
	Local cFunBkp 		:= FunName()

	Private dInicio	 	:= date()
	Private dLimite  	:= date()
	Private cProdIni  	:= CriaVar("B1_COD")
	Private cProdFim  	:= CriaVar("B1_COD")

	Private cAliasSA7
	Private dtProcesso 	:= Date()
	Private hrProcesso 	:= Time()

	SetFunName("PL020B")

	if VerParam() == .F.
		return
	endif

	FwMsgRun(NIL, {|oSay| TrataLinhas(oSay)}, "Processando pedidos", "Gerando pedidos EDI...")

	FwMsgRun(NIL, {|oSay| LimpaDados(oSay)}, "Excluindo pedidos antigos", "Excluindo pedidos EDI antigos...")

	FWAlertSuccess("GERACAO EFETUADA COM SUCESSO!", "Importacao EDI")

	SetFunName(cFunBkp)
	RestArea(aArea)
Return


/*---------------------------------------------------------------------*
	Obtem os itens do cliente da tabela itemXcliente
 *---------------------------------------------------------------------*/
Static Function TrataLinhas(oSay)
	Local cSql 			:= ""
	Local cProd			:= ""

	Private aDiasSem	:= {}
	
	cSql := "SELECT SA7.*, B1_DESC, B1_TS, B1_UM "
	cSql += "  FROM  " + RetSQLName("SA7") + " SA7 "
	
	cSql += " INNER JOIN " + RetSQLName("SB1") + " SB1 "
	cSql += "    ON B1_COD 			=  A7_PRODUTO "
	cSql += "   AND B1_MSBLQL 		=  '2' "
	cSql += "   AND B1_FILIAL 		=  '" + xFILIAL("SB1") + "'"
	cSql += "   AND SB1.D_E_L_E_T_ 	<> '*' "
	
	cSql += " WHERE A7_CLIENTE 		IN ('000004', '000005', '000006')" 
	cSql += "   AND A7_PRODUTO 		>= '" + cProdIni + "'" 
	cSql += "   AND A7_PRODUTO 		<= '" + cProdFim + "'" 
	cSql += "   AND A7_FILIAL 		=  '" + xFILIAL("SA7") + "'"
	cSql += "   AND SA7.D_E_L_E_T_  <> '*' "
	cSql += " ORDER BY A7_CLIENTE, A7_PRODUTO "
	cAliasSA7 := MPSysOpenQuery(cSql)	
 
 	if (cAliasSA7)->(EOF())
		FWAlertWarning("NAO FOI GERADA NENHUMA LINHA! ","Geracao de pedidos edi")
		return .T.
	endif

	While (cAliasSA7)->(!EOF()) 

		if cProd != (cAliasSA7)->A7_PRODUTO
		    cProd 	 := (cAliasSA7)->A7_PRODUTO
			aDiasSem := CargaDias((cAliasSA7)->A7_XDIASEM)
		endif

		if (cAliasSA7)->A7_XQTENT != 0
			GravaDados()
		endif

		(cAliasSA7)->(DbSkip())
	End While
return

/*---------------------------------------------------------------------*
	Grava tabela ZA0
 *---------------------------------------------------------------------*/
Static Function GravaDados()
	Local dData  	:= dInicio
	Local cTipoPe 	:= ""

	While dData <= dLimite

		dData := VerDataValida(dData)

		if dData <= daySum(Date(), 7)
			cTipoPe := "F"
		else
			cTipoPe := "V"
		endif

		dbSelectArea("ZA0")
		DBSetOrder(2)  // Filial/cliente/loja/item/data

		if (MsSeek(xFilial("ZA0") + (cAliasSA7)->A7_CLIENTE + (cAliasSA7)->A7_LOJA + (cAliasSA7)->A7_PRODUTO + dtos(dData))) .AND. ZA0->ZA0_STATUS != "9"
			RecLock("ZA0", .F.)
			ZA0->ZA0_QTDE 	  	:= (cAliasSA7)->A7_XQTENT
			ZA0->ZA0_TIPOPE   	:= cTipoPe
			ZA0->ZA0_ORIGEM 	:= "PL020B"
			ZA0->ZA0_DTCRIA   	:= dtProcesso
			ZA0->ZA0_HRCRIA 	:= hrProcesso
			ZA0->ZA0_STATUS		:= "0"
		else	
			// Inclusão
			RecLock("ZA0", .T.)	
			ZA0->ZA0_FILIAL		:= xFilial("ZA0")	
			ZA0->ZA0_CODPED 	:= GETSXENUM("ZA0", "ZA0_CODPED", 1)                                                                                                  
			ZA0->ZA0_CLIENT 	:= (cAliasSA7)->A7_CLIENTE
			ZA0->ZA0_LOJA 		:= (cAliasSA7)->A7_LOJA
			ZA0->ZA0_PRODUT 	:= (cAliasSA7)->A7_PRODUTO
			ZA0->ZA0_ITCLI 		:= (cAliasSA7)->A7_CODCLI
			ZA0->ZA0_QTDE 		:= (cAliasSA7)->A7_XQTENT
			ZA0->ZA0_TIPOPE 	:= cTipoPe
			ZA0->ZA0_DTENTR		:= dData
			ZA0->ZA0_ORIGEM 	:= "PL020B"
			ZA0->ZA0_DTCRIA 	:= dtProcesso
			ZA0->ZA0_HRCRIA 	:= hrProcesso
			ZA0->ZA0_STATUS 	:= "0"
			ConfirmSx8()
		endif
	
		MsUnLock() 

		dData := daysum(dData, 1)
	End While
Return


/*---------------------------------------------------------------------*
  Deleta da tabela ZA0 todos os registros que não foram atualizados
 *---------------------------------------------------------------------*/
Static Function LimpaDados(oSay)

   	dbSelectArea("ZA0")
   	ZA0->(DBSetOrder(3))  
   
   	DBSeek(xFilial("ZA0") + '000004')
	
	Do While ! Eof() 

		if ZA0_STATUS 	<> "9" .and. ;
			ZA0_TIPOPE 	<> "M" .and. ;
		  	(ZA0->ZA0_CLIENT == '000004' .or. ;
			 ZA0->ZA0_CLIENT == '000005' .or. ;
			 ZA0->ZA0_CLIENT == '000006') 

			if ZA0->ZA0_DTCRIA  <> dtProcesso .or. ;
				ZA0->ZA0_HRCRIA <> hrProcesso
				RecLock("ZA0", .F.)
				DbDelete()
				ZA0->(MsUnlock())
			endif
		endif

		DbSkip()
   EndDo
return


/*--------------------------------------------------------------------------
   Consistir os parametros informados pelo usuario
/*-------------------------------------------------------------------------*/
Static Function VerParam()
	Local aPergs        := {}
	Local aResps	    := {}
	Local lRet 			:= .T.

	cProdFim := "ZZZZZZZZZZZZ"

	AAdd(aPergs, {1, "Informe a data de entrega inicial "	, dInicio,"",".T.","",".T.", 70, .F.})
	AAdd(aPergs, {1, "Informe a data de entrega limite " 	, dLimite,"",".T.","",".T.", 70, .F.})
	AAdd(aPergs, {1, "Informe o item inicial "				, cProdIni,,,"SB1",, 70, .F.})
	AAdd(aPergs, {1, "Informe o item final " 				, cProdFim,,,"SB1",, 70, .F.})

	If ParamBox(aPergs, "Parametros", @aResps,,,,,,,, .T., .T.)
		dInicio	 	:= aResps[1]
		dLimite  	:= aResps[2]
		cProdIni 	:= aResps[3]
		cProdFim 	:= aResps[4]
	Else
		lRet := .F.
		return lRet
	endif
return lRet


/*---------------------------------------------------------------------*
	Verifica se o dia da semana é dia de entrega do cliente
	Se não for, traz o próximo dia válido
 *---------------------------------------------------------------------*/
Static Function VerDataValida(dData)
	Local dDataTest 	:= dData
	Local nDia			:= 0
	Local lAchou 		:= .F.

	While lAchou == .F.
		nDia := Dow(dDataTest)

		if aSCAN(aDiasSem, {|x| x == nDia}) == 0
			dDataTest := daySum(dDataTest, 1)
		Else
			lAchou := .T.
		endif
	EndDo
	
Return dDataTest


Static Function CargaDias(xDiaSem)
	Local aDias		:= {}
	Local aDias2 	:= {}

	if AllTrim(xDiaSem) == ""
		aDias := {"2","3","4","5","6"}
	else
		aDias := StrTokArr(AllTrim(xDiaSem), ';')
	endif

	if aSCAN(aDIAS, {|X| AllTrim(X)=='1'}) != 0
	 	AAdd(aDias2, 1)
	endif
	if aSCAN(aDIAS, {|X| AllTrim(X)=='2'}) != 0
	 	AAdd(aDias2, 2)
	endif
	if aSCAN(aDIAS, {|X| AllTrim(X)=='3'}) != 0
	 	AAdd(aDias2, 3)
	endif
	if aSCAN(aDIAS, {|X| AllTrim(X)=='4'}) != 0
	 	AAdd(aDias2, 4)
	endif
	if aSCAN(aDIAS, {|X| AllTrim(X)=='5'}) != 0
	 	AAdd(aDias2, 5)
	endif
	if aSCAN(aDIAS, {|X| AllTrim(X)=='6'}) != 0
	 	AAdd(aDias2, 6)
	endif
	if aSCAN(aDIAS, {|X| AllTrim(X)=='7'}) != 0
	 	AAdd(aDias2, 7)
	endif
return aDias2
