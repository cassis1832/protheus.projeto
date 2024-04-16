#INCLUDE "PROTHEUS.CH"
#INCLUDE "TBICONN.CH"

//---------------------------------------------------------------------------------
// MATA410 - EXECAUTO
// Criação de pedido de venda com base nos pedidos EDI
//---------------------------------------------------------------------------------

User Function PL040()

	Private nOpcX      := 3            // Tipo da operacao (3-Inclusao / 4-Alteracao / 5-Exclusao)
	Private cDoc       := ""           //Numero do Pedido de Vendas (alteracao ou exclusao)
	Private cFilSA1    := ""
	Private cFilSB1    := ""
	Private cFilSE4    := ""
	Private cFilSF4    := ""
	Private cFilDA0    := ""
	Private cFilDA1    := ""
	Private nX         := 0
	Private nY         := 0
	Private aCabec     := {}
	Private aItens     := {}
	Private aLinha     := {}
	Private lOk        := .T.
	Private lTemLinha  := .T.
	Private nPed       := 0

	Private lMsErroAuto    := .F.
	Private lAutoErrNoFile := .F.

	Private cCliente  	:= ''
	Private cLoja 		:= ''
	Private cData 		:= ''

	//----------------------------------------------------------------
	//* ABERTURA DO AMBIENTE
	//----------------------------------------------------------------

	ZA0->(dbSetOrder(3))
	SA1->(dbSetOrder(1))
	SB1->(dbSetOrder(1))
	SE4->(dbSetOrder(1))
	SF4->(dbSetOrder(1))
	DA0->(dbSetOrder(1))
	DA1->(dbSetOrder(2)) // produto + tabela + item

	cFilZA0 := xFilial("ZA0")
	cFilAGG := xFilial("AGG")
	cFilSA1 := xFilial("SA1")
	cFilSB1 := xFilial("SB1")
	cFilSE4 := xFilial("SE4")
	cFilSF4 := xFilial("SF4")
	cFilDAO := xFilial("DA0")
	cFilDA1 := xFilial("DA1")

	ZA0->(DBGoTop())

	While ZA0->( !Eof() )

		if ZA0->ZA0_CLIENT != cCliente .or. ZA0->ZA0_LOJA != cLoja .or. ZA0->ZA0_DTENTR != cData

			GravaPedido()

			cCliente 	:= ZA0->ZA0_CLIENT
			cLoja		:= ZA0->ZA0_LOJA
			cData		:= ZA0->ZA0_DTENTR

			// Verificar o cliente
			If SA1->(! MsSeek(cFilSA1 + cCliente + cLoja))
				lOk     := .F.
				ConOut("Cliente não cadastrado: " + cCliente + " - " + cLoja)
			EndIf

			// Verificar condição de pagamento do cliente
			If SE4->(! MsSeek(cFilSE4 + SA1->A1_COND))
				lOk     := .F.
				ConOut("Cliente sem condição de pagamento cadastrada: " + cCliente)
			EndIf

			// Verificar tabela de preço do cliente
			If DA0->(! MsSeek(cFilDAO + SA1->A1_TABELA))
				lOk     := .F.
				ConOut("Cliente sem tabela de preço cadastrada: " + cCliente)
			EndIf

			cDoc := GetSxeNum("SC5", "C5_NUM")

			RollBAckSx8()
			aCabec   	:= {}
			aItens   	:= {}
			aLinha   	:= {}
			lTemLinha 	:= .F.

			// aadd(aCabec, {"C5_NUM"    , ZA0->ZA0_DOC	, Nil})
			aadd(aCabec, {"C5_TIPO"   , "N"				, Nil})
			aadd(aCabec, {"C5_CLIENTE", ZA0->ZA0_CLIENT	, Nil})
			aadd(aCabec, {"C5_LOJACLI", ZA0->ZA0_LOJA	, Nil})
			aadd(aCabec, {"C5_LOJAENT", ZA0->ZA0_LOJA	, Nil})
			aadd(aCabec, {"C5_CONDPAG", SA1->A1_COND	, Nil})
		EndIf

		DbSelectArea("SB1")
		DBSeek(cFilSB1 + ZA0->ZA0_PRODUT)

		if ! Eof()
			IF SB1->B1_FILIAL != xFilial("SB1") .Or. SB1->B1_COD != ZA0->ZA0_PRODUT
				ConOut("Item não cadastrado: " + ZA0->ZA0_PRODUT)
			EndIf
		EndIf

		If SF4->(! MsSeek(cFilSF4 + SB1->B1_TS))
			lOk     := .F.
			ConOut("Item sem a TES de saída cadastrada: " + SB1->B1_TS)
		EndIf

		If DA1->(! MsSeek(cFilDA1 + SB1->B1_COD + SA1->A1_TABELA))
			MessageBox("Tabela de preços não encontrada para o item","",0)
			lOk     := .F.
		EndIf

		aLinha := {}
		aadd(aLinha,{"C6_ITEM"   	, StrZero(nX,2)		, Nil})
		aadd(aLinha,{"C6_PRODUTO"	, ZA0->ZA0_PRODUT	, Nil})
		aadd(aLinha,{"C6_TES"    	, SB1->B1_TS  		, Nil})
		aadd(aLinha,{"C6_ENTREG" 	, ZA0->ZA0_DTENTR 	, Nil})
		aadd(aLinha,{"C6_QTDVEN" 	, ZA0->ZA0_QTDE    	, Nil})
		aadd(aLinha,{"C6_PRCVEN" 	, DA1->DA1_PRCVEN 	, Nil})
		aadd(aLinha,{"C6_PRUNIT" 	, DA1->DA1_PRCVEN 	, Nil})
		aadd(aLinha,{"C6_PEDCLI" 	, ZA0->ZA0_NUMPED 	, Nil})
		aadd(aLinha,{"C6_VALOR"  	, ZA0->ZA0_QTDE * DA1->DA1_PRCVEN, Nil})
		// aadd(aLinha,{"C6_NUMPCOM" 	, ZA0->ZA0_NUMPED 	, Nil})
		// aadd(aLinha,{"C6_ITEMPC" 	, ZA0->ZA0_NUMPED 	, Nil})

		aadd(aItens, aLinha)
		lTemLinha := .T.

		ZA0->( dbSkip() )
	end while

	ConOut("Fim: " + Time())
	ConOut(Repl("-",80))

	RESET ENVIRONMENT

Return(.T.)

Static Function GravaPedido()

	// Primeira vez não grava - está vazio
	if cCliente != '' .and. lOk == .T. .and. lTemLinha == .T.

		MSExecAuto({|a, b, c, d| MATA410(a, b, c, d)}, aCabec, aItens, nOpcX, .F.)

		If !lMsErroAuto
			nPed := nPed + 1
			ConOut("Incluido com sucesso! Pedido " + AllTrim(str(nPed)) + ": " + cDoc)
		Else
			ConOut("Erro na inclusao!")
			MOSTRAERRO()
		EndIf
	Endif

return
