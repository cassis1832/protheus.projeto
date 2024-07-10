#Include 'Protheus.ch'
#Include 'FWMVCDef.ch'
#Include "tbiconn.ch"

/*/{Protheus.doc} PL020B
Função 
   Gerar pedidos EDI para a Gestamp - clientes 4/5/6/7
   Gravar tabela ZA0 
   Esse programa chamado a partir do PL020 (manutenção do ZA0)

@author Assis
@since 24/06/2024
@version 1.0
	@return Nil, Função não tem retorno
	@example
	u_PL030()
/*/

User Function PL020B()
	Local aArea   		:= GetArea()
	Local cFunBkp 		:= FunName()

	Private cCliente 	:= ''
	Private cLoja	 	:= ''
	Private dInicio	 	:= date()
	Private dLimite  	:= date()
	Private cProdIni  	:= ''
	Private cProdFim  	:= ''

	Private cAliasSA7
	Private dtProcesso 	:= Date()
	Private hrProcesso 	:= Time()

	SetFunName("PL020B")

	if VerParam() == .F.
		return
	endif

	FwMsgRun(NIL, {|oSay| TrataLinhas(oSay)}, "Processando pedidos", "Gerando pedidos EDI...")

	FwMsgRun(NIL, {|oSay| LimpaDados(oSay)}, "Excluindo pedidos antigos", "Excluindo pedidos EDI antigos...")

	FWAlertSuccess("GERACAO EFETUADA COM SUCESSO PARA O CLIENTE " + cCliente, "Importacao EDI")

	SetFunName(cFunBkp)
	RestArea(aArea)
Return


/*---------------------------------------------------------------------*
	Obtem os itens do cliente da tabela itemXcliente
 *---------------------------------------------------------------------*/
Static Function TrataLinhas(oSay)
	cSql := "SELECT SA7.*, B1_DESC, B1_TS, B1_UM "
	cSql += "  FROM  " + RetSQLName("SA7") + " SA7 "
	cSql += " INNER JOIN " + RetSQLName("SB1") + " SB1 "
	cSql += "    ON B1_COD 			=  A7_PRODUTO "
	cSql += " WHERE A7_CLIENTE 		=  '" + cCliente + "'"
	cSql += "   AND A7_LOJA 		=  '" + cLoja + "'" 
	cSql += "   AND A7_PRODUTO 		>= '" + cProdIni + "'" 
	cSql += "   AND A7_PRODUTO 		<= '" + cProdFim + "'" 
	cSql += "   AND A7_FILIAL 		=  '" + xFILIAL("SA7") + "'"
	cSql += "   AND B1_FILIAL 		=  '" + xFILIAL("SB1") + "'"
	cSql += "   AND SA7.D_E_L_E_T_  <> '*' "
	cSql += "   AND SB1.D_E_L_E_T_ 	<> '*' "
	cSql += " ORDER BY A7_PRODUTO "
	cAliasSA7 := MPSysOpenQuery(cSql)	
 
 	if (cAliasSA7)->(EOF())
		FWAlertWarning("NAO FOI GERADA NENHUMA LINHA! ","Geracao de pedidos edi")
		return .T.
	endif

	While (cAliasSA7)->(!EOF()) 

		if (cAliasSA7)->A7_XFRENT != 0 .AND. (cAliasSA7)->A7_XQTENT != 0
			GravaDados()
		endif

		(cAliasSA7)->(DbSkip())
	End While
return

/*---------------------------------------------------------------------*
	Grava tabela ZA0
 *---------------------------------------------------------------------*/
Static Function GravaDados()
	Local dData  := dInicio

	While dData <= dLimite

		if Dow(dData) = 1 	// domingo
			dData := daySum(dData, 1)
		endif
		if Dow(dData) = 7 	// sábado
			dData := daySum(dData, 2)
		endif

		dbSelectArea("ZA0")
		DBSetOrder(2)  // Filial/cliente/loja/item/data

		if (MsSeek(xFilial("ZA0") + cCliente + cLoja + (cAliasSA7)->A7_PRODUTO + dtos(dData))) .AND. ZA0->ZA0_STATUS != "9"
			RecLock("ZA0", .F.)
			ZA0->ZA0_DTCRIA   := dtProcesso
			ZA0->ZA0_HRCRIA   := hrProcesso
			ZA0->ZA0_TIPOPE   := "F"
			ZA0->ZA0_QTDE 	  := (cAliasSA7)->A7_XQTENT
		else	
			// Inclusão
			RecLock("ZA0", .T.)	
			ZA0->ZA0_FILIAL	:= xFilial("ZA0")	
			ZA0->ZA0_CODPED := GETSXENUM("ZA0", "ZA0_CODPED", 1)                                                                                                  
			ZA0->ZA0_CLIENT := cCliente
			ZA0->ZA0_LOJA 	:= cLoja
			ZA0->ZA0_PRODUT := (cAliasSA7)->A7_PRODUTO
			ZA0->ZA0_ITCLI 	:= (cAliasSA7)->A7_CODCLI
			ZA0->ZA0_TIPOPE := "F"
			ZA0->ZA0_QTDE 	:= (cAliasSA7)->A7_XQTENT
			ZA0->ZA0_DTENTR := dData
			ZA0->ZA0_ORIGEM := "PL020B"
			ZA0->ZA0_DTCRIA := dtProcesso
			ZA0->ZA0_HRCRIA := hrProcesso
			ZA0->ZA0_STATUS := "0"
			ConfirmSx8()
		endif
	
		MsUnLock() 

		dData := daysum(dData, (cAliasSA7)->A7_XFRENT)
	End While
Return


/*---------------------------------------------------------------------*
  Deleta da tabela ZA0 todos os registros que não foram atualizados
 *---------------------------------------------------------------------*/
Static Function LimpaDados(oSay)

   	dbSelectArea("ZA0")
   	ZA0->(DBSetOrder(3))  
   
   	DBSeek(xFilial("ZA0") + cCliente + cLoja)
	
	Do While ! Eof() 

		if ZA0->ZA0_CLIENT 	== cCliente 	.AND. ;
			ZA0->ZA0_LOJA  	== cLoja 		.AND. ;
			ZA0_STATUS     	<> "9" 

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

	AAdd(aPergs, {1, "Informe o cliente "					, CriaVar("ZA0_CLIENT",.F.),,,"SA1",, 50, .F.})
	AAdd(aPergs, {1, "Informe a loja "   					, CriaVar("ZA0_LOJA"  ,.F.),,,"SA1",, 30, .F.})
	AAdd(aPergs, {1, "Informe a data de entrega inicial "	, CriaVar("ZA0_DTENTR",.F.),"",".T.","",".T.", 70, .F.})
	AAdd(aPergs, {1, "Informe a data de entrega limite " 	, CriaVar("ZA0_DTENTR",.F.),"",".T.","",".T.", 70, .F.})
	AAdd(aPergs, {1, "Informe o item inicial "				, CriaVar("B1_COD",.F.),,,"SB1",, 70, .F.})
	AAdd(aPergs, {1, "Informe o item final " 				, CriaVar("B1_COD",.F.),,,"SB1",, 70, .F.})

	If ParamBox(aPergs, "Parametros", @aResps,,,,,,,, .T., .T.)
		cCliente := aResps[1]
		cLoja    := aResps[2]
		dInicio	 := aResps[3]
		dLimite  := aResps[4]
		cProdIni := aResps[5]
		cProdFim := aResps[6]
	Else
		lRet := .F.
		return lRet
	endif

	if cCliente != "000004" .and. cCliente != "000005" .and. cCliente != "000006" .and. cCliente != "000007"
		lRet := .F.
		FWAlertError("CLIENTE NAO GESTAMP!")
	endif

	SA1->(dbSetOrder(1))
	SE4->(dbSetOrder(1))
	DA1->(dbSetOrder(1))

	// Verificar o cliente
	if SA1->(! MsSeek(xFilial("SA1") + cCliente + cLoja))
		lRet := .F.
		FWAlertError("Cliente nao cadastrado: " + cCliente,"Cadastro de Clientes")
	else
		// Verificar condição de pagamento do cliente
		If SE4->(! MsSeek(xFilial("SE4") + SA1->A1_COND))
			lRet := .F.
			FWAlertError("Cliente sem condicao de pagamento cadastrada: " + cCliente,"Condicao de Pagamento")
		EndIf

		// Verificar a tabela de precos do cliente
		If SA1->A1_TABELA == ""
			lRet := .F.
			FWAlertError("Tabela de precos do cliente nao encontrada!", "Tabela de precos")
		EndIf
	EndIf
return lRet
