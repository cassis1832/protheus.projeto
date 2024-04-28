#INCLUDE "PROTHEUS.CH"
#INCLUDE "TBICONN.CH"

//---------------------------------------------------------------------------------
// PL030 - GERAÇÃO DE PEDIDO DE VENDA COM BASE NO PEDIDO EDI
// MATA410 - EXECAUTO
// Ler ZA0 por cliente/data/natureza/item
//---------------------------------------------------------------------------------
User Function PL020D()

	Private nOpcX     := 3          	// Tipo da operação (3-Inclusão / 4-Alteração / 5-Exclusão)
	Private cDoc      := ""         	// Numero do Pedido de Vendas (alteracao ou exclusao)

	Private cFilSA1   := ""			   // cliente
	Private cFilSE4   := ""			   // condição de pagamento
	Private cFilDA0   := ""			   // tabela de preços
	Private cFilDA1   := ""			   // itens da tabela de preços

	Private nX        := 0
	Private nY        := 0
	Private aCabec    := {}
	Private aItens    := {}
	Private aLinha    := {}
	Private aGravados := {}

	Private lOk       := .T.
	Private lTemLinha := .T.
	Private nPed      := 0

	Private cCliente  := ''
	Private cLoja 		:= ''
	Private cData 		:= ''
	Private cNatureza	:= ''

	Private lMsErroAuto    := .F.
	Private lAutoErrNoFile := .F.

	ChkFile("ZA0")

	Consistencia()       // Consiste a tabela inteira

	SA1->(dbSetOrder(1))
	SE4->(dbSetOrder(1))
	DA0->(dbSetOrder(1))

	cFilSA1 := xFilial("SA1")
	cFilSE4 := xFilial("SE4")
	cFilDAO := xFilial("DA0")
	cFilDA1 := xFilial("DA1")

	strSql := "SELECT ZA0010.*, SA7010.*, B1_TS "
	strSql += "  FROM ZA0010, SB1010, SA7010 "            + CRLF
	strSql += " WHERE ZA0_STATUS        =  '0' "          + CRLF
	strSql += "   AND ZA0_FILIAL        =  B1_FILIAL "    + CRLF
	strSql += "   AND ZA0_PRODUT        =  B1_COD "       + CRLF
	strSql += "   AND ZA0_FILIAL        =  A7_FILIAL "    + CRLF
	strSql += "   AND ZA0_CLIENT        =  A7_CLIENTE "   + CRLF
	strSql += "   AND ZA0_LOJA          =  A7_LOJA "      + CRLF
	strSql += "   AND ZA0_PRODUT        =  A7_PRODUTO "   + CRLF

	strSql += "   AND ZA0010.D_E_L_E_T_ <> '*' "          + CRLF
	strSql += "   AND SB1010.D_E_L_E_T_ <> '*' "          + CRLF
	strSql += "   AND SA7010.D_E_L_E_T_ <> '*' "          + CRLF

	strSql += " ORDER BY ZA0_CLIENT, ZA0_LOJA, ZA0_DTENTR, " + CRLF
	strSql += " A7_XNATUR, ZA0_PRODUT "                      + CRLF

	cAlias := MPSysOpenQuery(strSql)

	While (cAlias)->(!EOF())

		if (cAlias)->ZA0_CLIENT != cCliente    .or. ;
				(cAlias)->ZA0_LOJA   != cLoja    .or. ;
				(cAlias)->ZA0_DTENTR != cData    .or. ;
				(cAlias)->A7_XNATUR  != cNatureza

			GravaPedido()

			cCliente	   := (cAlias)->ZA0_CLIENT
			cLoja		   := (cAlias)->ZA0_LOJA
			cData		   := (cAlias)->ZA0_DTENTR
			cNatureza 	:= (cAlias)->A7_XNATUR

			// Verificar o cliente
			if SA1->(! MsSeek(cFilSA1 + cCliente + cLoja))
				lOk   := .F.
				FWAlertError("Cliente não cadastrado: " + cCliente,"Cadastro de Clientes")
			EndIf

			// Verificar condição de pagamento do cliente
			If SE4->(! MsSeek(cFilSE4 + SA1->A1_COND))
				lOk     := .F.
				FWAlertError("Cliente sem condição de pagamento cadastrada: " + cCliente,"Condição de Pagamento")
			EndIf

			// Verificar tabela de preço do cliente
			If DA0->(! MsSeek(cFilDAO + SA1->A1_TABELA))
				lOk   := .F.
				FWAlertError("Cliente sem tabela de preço cadastrada: " + cCliente,"Tabela de preços")
			EndIf

			cDoc := GetSxeNum("SC5", "C5_NUM")

			RollBAckSx8()
			aCabec   	:= {}
			aItens   	:= {}
			aLinha   	:= {}
			aGravados   := {}
			lTemLinha 	:= .F.

			// aadd(aCabec, {"C5_NUM"    , (cAlias)->ZA0_DOC	, Nil})
			aadd(aCabec, {"C5_TIPO"   , "N"				, Nil})
			aadd(aCabec, {"C5_CLIENTE", cCliente	   , Nil})
			aadd(aCabec, {"C5_LOJACLI", cLoja	      , Nil})
			aadd(aCabec, {"C5_LOJAENT", cLoja	      , Nil})
			aadd(aCabec, {"C5_CONDPAG", SA1->A1_COND	, Nil})
			aadd(aCabec, {"C5_NATUREZ", cNatureza	   , Nil})
		EndIf

		DA1->(dbSetOrder(2)) // DA1_FILIAL+DA1_CODPRO+DA1_CODTAB+DA1_ITEM

		If ! DA1->(DbSeek(cFilDA1 + (cAlias)->ZA0_PRODUT + SA1->A1_TABELA))
			FWAlertError("Tabela de preços não encontrada para o item: " + (cAlias)->ZA0_PRODUT,"Tabela de preços")
			lOk     := .F.
		EndIf

		aLinha := {}
		aadd(aLinha,{"C6_ITEM"   	, StrZero(nX,2)	      , Nil})
		aadd(aLinha,{"C6_PRODUTO"	, (cAlias)->ZA0_PRODUT	, Nil})
		aadd(aLinha,{"C6_TES"    	, (cAlias)->B1_TS		   , Nil})
		aadd(aLinha,{"C6_ENTREG" 	, Stod((cAlias)->ZA0_DTENTR) , Nil})
		aadd(aLinha,{"C6_QTDVEN" 	, (cAlias)->ZA0_QTDE    , Nil})
		aadd(aLinha,{"C6_PEDCLI" 	, (cAlias)->ZA0_NUMPED  , Nil})
		aadd(aLinha,{"C6_XCODPED" 	, (cAlias)->ZA0_CODPED  , Nil})
		aadd(aLinha,{"C6_VALOR"  	, (cAlias)->ZA0_QTDE * DA1->DA1_PRCVEN, Nil})
		aadd(aLinha,{"C6_PRCVEN" 	, DA1->DA1_PRCVEN       , Nil})
		aadd(aLinha,{"C6_PRUNIT" 	, DA1->DA1_PRCVEN       , Nil})

		// aadd(aLinha,{"C6_NUMPCOM" 	, (cAlias)->ZA0_NUMPED 	, Nil})
		// aadd(aLinha,{"C6_ITEMPC" 	, (cAlias)->ZA0_NUMPED 	, Nil})

		aadd(aItens, aLinha)

		lTemLinha := .T.

		aadd(aGravados,(cAlias)->R_E_C_N_O_)

		(cAlias)->(DbSkip())

	End While

	FWAlertSuccess("Pedidos gerados com sucesso!", "Geração de Pedidos de Vendas")

	ConOut("Fim: " + Time())
	ConOut(Repl("-",80))
Return(.T.)

/*--------------------------------------------------------------------------
   Grava o pedido no sistema
/*-------------------------------------------------------------------------*/
Static Function GravaPedido()

	// Primeira vez não grava porque estÃ¡ vazio
	if cCliente != '' .and. lOk == .T. .and. lTemLinha == .T.

		MSExecAuto({|a, b, c, d| MATA410(a, b, c, d)}, aCabec, aItens, nOpcX, .F.)

		If !lMsErroAuto
			nPed := nPed + 1
			ConOut("Incluido com sucesso! Pedido " + AllTrim(str(nPed)) + ": " + cDoc)
			AtualizaGravados()
		Else
			ConOut("Erro na inclusao!")
			MOSTRAERRO()
		EndIf
	Endif

return

/*--------------------------------------------------------------------------
   Atualiza o status no arquivo ZA0 para os pedidos criados
/*-------------------------------------------------------------------------*/
Static Function AtualizaGravados()
	Local nInd :=0

	For nInd := 1 to Len(aGravados) Step 1

      ZA0->(DbGoTo(aGravados[nInd]))

		RecLock("ZA0", .F.)

		ZA0->ZA0_Status  := '9'

		ZA0->(MsUnlock())
	Next

return

/*--------------------------------------------------------------------------
   Consistencia do arquivo ZA0 - grava status com erro
/*-------------------------------------------------------------------------*/
Static Function Consistencia()
	Local lOk   := .T.

   SA1->(dbSetOrder(1))
   SA7->(dbSetOrder(1))
   DA1->(dbSetOrder(2)) // produto + tabela + item

   dbSelectArea("ZA0")
   ZA0->(DBSetOrder(2))  // Filial/cliente/loja
   
   DBSeek(xFilial("ZA0"))

   Do While ! Eof() 
   
      if ZA0_STATUS != '9'
         lOk := .T.

         // Verificar a relacao Item X Cliente
         If SA7->(! MsSeek(xFilial("SA7") + ZA0->ZA0_CLIENT + ZA0->ZA0_LOJA + ZA0->ZA0_PRODUT))
            lOk     := .F.
            FWAlertError("Item X Cliente não cadastrada (" + ZA0->ZA0_PRODUT + "/" + ZA0->ZA0_CLIENT + ")!", "Cadastro Produto/Cliente")

            if SA7->A7_XNATUR == ''
               lOk     := .F.
               FWAlertError("Falta natureza na relação Item X Cliente (" + ZA0->ZA0_PRODUT + "/" + ZA0->ZA0_CLIENT + ")!", "Cadastro Produto/Cliente")
            EndIf
         EndIf

         // Verificar a tabela de precos do cliente
         If SA1->(! MsSeek(xFilial("SA1") + ZA0->ZA0_CLIENT + ZA0->ZA0_LOJA))
            lOk     := .F.
            FWAlertError("Cliente não cadastrado (" + ZA0->ZA0_CLIENT + ")!", "Cadastro de clientes")
         else
            If DA1->(! MsSeek(xFilial("DA1") + ZA0->ZA0_PRODUT + SA1->A1_TABELA, .T.))
               FWAlertError("Tabela de preços não encontrada para o item (" + ZA0->ZA0_PRODUT + ")!", "Tabela de preços")
               lOk     := .F.
            EndIf
         EndIf

         RecLock("ZA0", .F.)

         if lOk == .T.
            ZA0->ZA0_Status  := '0'
         else
            ZA0->ZA0_Status  := '1'
         EndIf
         
         ZA0->(MsUnlock())

      Endif

      DbSkip()
     
   EndDo

return
