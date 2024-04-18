#INCLUDE "PROTHEUS.CH"
#INCLUDE "TBICONN.CH"

//---------------------------------------------------------------------------------
// PL030 - GERAÇÂO DE PEDIDO DE VENDA COM BASE NO PEDIDO EDI
// MATA410 - EXECAUTO
// Ler ZA0 por cliente/data/grupo de tes/item para quebrar por data/grupamento de tes
//---------------------------------------------------------------------------------

User Function PL020D()

	Private nOpcX      := 3          // Tipo da opeçacao (3-Inclusao / 4-Alteracao / 5-Exclusao)
	Private cDoc       := ""         // Numero do Pedido de Vendas (alteracao ou exclusao)

	Private cFilSA1    := ""			// cliente
	Private cFilSA7    := ""			// Item x cliente
	Private cFilSB1    := ""			// item
	Private cFilSE4    := ""			// condição de pagamento
	Private cFilDA0    := ""			// tabela de pre�os
	Private cFilDA1    := ""			// itens da tabela de pre�os

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
	Private cGrTes 		:= ''

	//----------------------------------------------------------------
	//* ABERTURA DO AMBIENTE
	//----------------------------------------------------------------

	ZA0->(dbSetOrder(3)) // filial/cliente/loja/data/grtes/produto
	SA1->(dbSetOrder(1))
	SA7->(dbSetOrder(1))
	SB1->(dbSetOrder(1))
	SE4->(dbSetOrder(1))
	DA0->(dbSetOrder(1))
	DA1->(dbSetOrder(2)) // produto + tabela + item

	cFilZA0 := xFilial("ZA0")
	cFilAGG := xFilial("AGG")
	cFilSA1 := xFilial("SA1")
	cFilSA7 := xFilial("SA7")
	cFilSB1 := xFilial("SB1")
	cFilSE4 := xFilial("SE4")
	cFilDAO := xFilial("DA0")
	cFilDA1 := xFilial("DA1")

	ZA0->(DBGoTop())

	Do While ZA0->( !Eof() )

		if (ZA0->ZA0_STATUS == '0')

			if ZA0->ZA0_CLIENT != cCliente .or. ZA0->ZA0_LOJA != cLoja .or. ZA0->ZA0_DTENTR != cData .or. cGrTes != ZA0->ZA0_GRTES

				GravaPedido()

				cCliente := ZA0->ZA0_CLIENT
				cLoja		:= ZA0->ZA0_LOJA
				cData		:= ZA0->ZA0_DTENTR
				cGrTes 	:= ZA0->ZA0_GRTES

				// Verificar o cliente
				if SA1->(! MsSeek(cFilSA1 + cCliente + cLoja))
					lOk     := .F.
					MessageBox("Cliente não cadastrado: " + cCliente + " - " + cLoja, "",0)
				EndIf

				// Verificar condição de pagamento do cliente
				If SE4->(! MsSeek(cFilSE4 + SA1->A1_COND))
					lOk     := .F.
					MessageBox("Cliente sem condição de pagamento cadastrada: " + cCliente,"",0)
				EndIf

				// Verificar tabela de pre�o do cliente
				If DA0->(! MsSeek(cFilDAO + SA1->A1_TABELA))
					lOk     := .F.
					MessageBox("Cliente sem tabela de preço cadastrada: " + cCliente,"",0)
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

			If SB1->(! MsSeek(cFilSB1 + ZA0->ZA0_PRODUT))
				MessageBox("Item não cadastrado: " + ZA0->ZA0_PRODUT, "",0)
				lOk     := .F.
			EndIf

			If DA1->(! MsSeek(cFilDA1 + SB1->B1_COD + SA1->A1_TABELA))
				MessageBox("Tabela de preços não encontrada para o item: " + ZA0->ZA0_PRODUT,"",0)
				lOk     := .F.
			EndIf

			// Obter a TES da tabela item x cliente
			If SA7->(! MsSeek(cFilSA7 + ZA0->ZA0_CLIENT + ZA0->ZA0_LOJA + ZA0_PRODUT))
				MessageBox("Relação Item X Cliente não cadastrado: " + ZA0->ZA0_PRODUT,"",0)
				lOk     := .F.
			EndIf

			aLinha := {}
			aadd(aLinha,{"C6_ITEM"   	, StrZero(nX,2)	, Nil})
			aadd(aLinha,{"C6_PRODUTO"	, ZA0->ZA0_PRODUT	, Nil})
			aadd(aLinha,{"C6_TES"    	, SA7->A7_XTES		, Nil})
			aadd(aLinha,{"C6_ENTREG" 	, ZA0->ZA0_DTENTR , Nil})
			aadd(aLinha,{"C6_QTDVEN" 	, ZA0->ZA0_QTDE   , Nil})
			aadd(aLinha,{"C6_PRCVEN" 	, DA1->DA1_PRCVEN , Nil})
			aadd(aLinha,{"C6_PRUNIT" 	, DA1->DA1_PRCVEN , Nil})
			aadd(aLinha,{"C6_PEDCLI" 	, ZA0->ZA0_NUMPED , Nil})
			aadd(aLinha,{"C6_VALOR"  	, ZA0->ZA0_QTDE * DA1->DA1_PRCVEN, Nil})
			// aadd(aLinha,{"C6_NUMPCOM" 	, ZA0->ZA0_NUMPED 	, Nil})
			// aadd(aLinha,{"C6_ITEMPC" 	, ZA0->ZA0_NUMPED 	, Nil})

			aadd(aItens, aLinha)
			lTemLinha := .T.

		Endif

		ZA0->( dbSkip() )

	EndDo

	ConOut("Fim: " + Time())
	ConOut(Repl("-",80))

	RESET ENVIRONMENT

Return(.T.)

Static Function GravaPedido()

	// Primeira vez não grava porque está vazio
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
