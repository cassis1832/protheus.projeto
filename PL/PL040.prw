#INCLUDE "PROTHEUS.CH"
#INCLUDE "TBICONN.CH"

//---------------------------------------------------------------------------------
// MATA410 - EXECAUTO
// Criação de pedido de venda
// https://centraldeatendimento.totvs.com/hc/pt-br/articles/7326654842775-Cross-Segmento-TOTVS-Backoffice-Linha-Protheus-SIGAFAT-EXECAUTO-MATA410
//---------------------------------------------------------------------------------

User Function PL040()

	Private nOpcX      := 5            //Seleciona o tipo da operacao (3-Inclusao / 4-Alteracao / 5-Exclusao)
	Private cDoc       := ""           //Numero do Pedido de Vendas (alteracao ou exclusao)
	Private cA1Cod     := "000001"     //Codigo do Cliente
	Private cA1Loja    := "01"         //Loja do Cliente
	Private cB1Cod     := "000001"     //Codigo do Produto
	Private cF4TES     := "501"        //Codigo do TES
	Private cE4Codigo  := "001"        //Codigo da Condicao de Pagamento
	Private cFilSA1    := ""
	Private cFilSB1    := ""
	Private cFilSE4    := ""
	Private cFilSF4    := ""
	Private nX         := 0
	Private nY         := 0
	Private aCabec     := {}
	Private aItens     := {}
	Private aLinha     := {}
	Private lOk        := .T.
	Private nPed       := 0

	Private lMsErroAuto    := .F.
	Private lAutoErrNoFile := .F.

	//----------------------------------------------------------------
	//* ABERTURA DO AMBIENTE
	//----------------------------------------------------------------

	ConOut(Repl("-",80))
	ConOut(PadC("Teste de Inclusao / Alteracao / Exclusao de Pedido de Venda", 80))

	PREPARE ENVIRONMENT EMPRESA "99" FILIAL "01" MODULO "FAT" TABLES "SC5","SC6","SA1","SA2","SB1","SB2","SF4"


	ZA0->(dbSetOrder(3))
	SA1->(dbSetOrder(1))
	SB1->(dbSetOrder(1))
	SE4->(dbSetOrder(1))
	SF4->(dbSetOrder(1))

	cFilZA0 := xFilial("ZA0")
	cFilAGG := xFilial("AGG")
	cFilSA1 := xFilial("SA1")
	cFilSB1 := xFilial("SB1")
	cFilSE4 := xFilial("SE4")
	cFilSF4 := xFilial("SF4")

	ConOut("Verificando o ambiente")

	ZA0->(DBGoTop("za0"))

	While ZA0->( !Eof() )

		DbSelectArea("SB1")

		DBSeek(cFilSB1 + ZA0->ZA0_PRODUT)

		if ! Eof()
			IF B1_FILIAL == xFilial("SB1") .And. B1_PRODUTO == ZA0_PRODUT
				ConOut("Item não cadastrado: " + ZA0->ZA0_PRODUT)
			EndIf
		EndIf

		If SF4->(! MsSeek(cFilSF4 + cF4TES))
			lOk     := .F.
			ConOut("Cadastrar TES: " + cF4TES)
		EndIf

		//VERIFICAR CONDICAO DE PAGAMENTO
		If SE4->(! MsSeek(cFilSE4 + cE4Codigo))
			lOk     := .F.
			ConOut("Cadastrar Condicao de Pagamento: " + cE4Codigo)
		EndIf

		//VERIFICAR CLIENTE
		If SA1->(! MsSeek(cFilSA1 + cA1Cod + cA1Loja))
			lOk     := .F.
			ConOut("Cadastrar Cliente: " + cA1Cod + " - " + cA1Loja)
		EndIf

		If lOk
			ConOut("Inicio: " + Time())

			For nY := 1 To 1  //Quantidade de Pedidos
				cDoc := GetSxeNum("SC5", "C5_NUM")
				RollBAckSx8()
				aCabec   := {}
				aItens   := {}
				aLinha   := {}
				aadd(aCabec, {"C5_NUM"    , cDoc     , Nil})
				aadd(aCabec, {"C5_TIPO"   , "N"      , Nil})
				aadd(aCabec, {"C5_CLIENTE", cA1Cod   , Nil})
				aadd(aCabec, {"C5_LOJACLI", cA1Loja  , Nil})
				aadd(aCabec, {"C5_LOJAENT", cA1Loja  , Nil})
				aadd(aCabec, {"C5_CONDPAG", cE4Codigo, Nil})

				If cPaisLoc == "PTG"
					aadd(aCabec, {"C5_DECLEXP", "TESTE", Nil})
				Endif

				CONOUT("Passou pelo Array do Cabecalho")

				For nX := 1 To 1  //Quantidade de Itens
					aLinha := {}
					aadd(aLinha,{"C6_ITEM"   , StrZero(nX,2), Nil})
					aadd(aLinha,{"C6_PRODUTO", cB1Cod       , Nil})
					aadd(aLinha,{"C6_QTDVEN" , 1            , Nil})
					aadd(aLinha,{"C6_PRCVEN" , 1000         , Nil})
					aadd(aLinha,{"C6_PRUNIT" , 1000         , Nil})
					aadd(aLinha,{"C6_VALOR"  , 1000         , Nil})
					aadd(aLinha,{"C6_TES"    , cF4TES       , Nil})
					aadd(aItens, aLinha)
					CONOUT("Passou pelo Array dos itens")
				Next nX

				CONOUT("Iniciando a gravacao")
				MSExecAuto({|a, b, c, d| MATA410(a, b, c, d)}, aCabec, aItens, nOpcX, .F.)

				If !lMsErroAuto
					nPed := nPed + 1
					ConOut("Incluido com sucesso! Pedido " + AllTrim(str(nPed)) + ": " + cDoc)
				Else
					ConOut("Erro na inclusao!")
					MOSTRAERRO()
				EndIf
			Next nY

			ConOut("Fim: " + Time())
		Endif

	end while

	ConOut("Fim: " + Time())
	ConOut(Repl("-",80))

	RESET ENVIRONMENT

Return(.T.)
