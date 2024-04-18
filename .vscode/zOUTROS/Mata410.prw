#INCLUDE "PROTHEUS.CH"
#INCLUDE "TBICONN.CH"

//---------------------------------------------------------------------------------
// MATA410 - EXECAUTO
// Criação de pedido de venda
// https://centraldeatendimento.totvs.com/hc/pt-br/articles/7326654842775-Cross-Segmento-TOTVS-Backoffice-Linha-Protheus-SIGAFAT-EXECAUTO-MATA410
//---------------------------------------------------------------------------------

User Function MyMata410()

	Local nOpcX      := 5            //Seleciona o tipo da operacao (3-Inclusao / 4-Alteracao / 5-Exclusao)
	Local cDoc       := ""           //Numero do Pedido de Vendas (alteracao ou exclusao)
	Local cA1Cod     := "000001"     //Codigo do Cliente
	Local cA1Loja    := "01"         //Loja do Cliente
	Local cB1Cod     := "000001"     //Codigo do Produto
	Local cF4TES     := "501"        //Codigo do TES
	Local cE4Codigo  := "001"        //Codigo da Condicao de Pagamento
	Local cFilSA1    := ""
	Local cFilSB1    := ""
	Local cFilSE4    := ""
	Local cFilSF4    := ""
	Local nX         := 0
	Local nY         := 0
	Local aCabec     := {}
	Local aItens     := {}
	Local aLinha     := {}
	Local lOk        := .T.
	Local nPed       := 0

	Private lMsErroAuto    := .F.
	Private lAutoErrNoFile := .F.

	//****************************************************************
	//* ABERTURA DO AMBIENTE
	//****************************************************************

	ConOut(Repl("-",80))
	ConOut(PadC("Teste de Inclusao / Alteracao / Exclusao de Pedido de Venda", 80))

	PREPARE ENVIRONMENT EMPRESA "99" FILIAL "01" MODULO "FAT" TABLES "SC5","SC6","SA1","SA2","SB1","SB2","SF4"

	SA1->(dbSetOrder(1))
	SB1->(dbSetOrder(1))
	SE4->(dbSetOrder(1))
	SF4->(dbSetOrder(1))

	cFilAGG := xFilial("AGG")
	cFilSA1 := xFilial("SA1")
	cFilSB1 := xFilial("SB1")
	cFilSE4 := xFilial("SE4")
	cFilSF4 := xFilial("SF4")

	//****************************************************************
	//* VERIFICACAO DO AMBIENTE PARA TESTE
	//****************************************************************

	ConOut("Verificando o ambiente")

	//VERIFICAR PRODUTO
	If SB1->(! MsSeek(cFilSB1 + cB1Cod))
		lOk     := .F.
		ConOut("Cadastrar Produto: " + cB1Cod)
	EndIf

	//VERIFICAR TES
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

		//****************************************************************
		//* INCLUSAO - INICIO
		//****************************************************************

		IF nOpcX = 3 //Inclusao
			ConOut("Teste de Inclusao")
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

			//****************************************************************
			//* ALTERACAO - INICIO
			//****************************************************************

		ELSEIF nOpcX = 4 //Alteracao
			ConOut("Teste de Alteracao")
			ConOut("Inicio: " + Time())
			aCabec         := {}
			aItens         := {}
			aLinha         := {}
			lMsErroAuto    := .F.
			lAutoErrNoFile := .F.

			aadd(aCabec,{"C5_NUM"    , cDoc     , Nil})
			aadd(aCabec,{"C5_TIPO"   , "N"      , Nil})
			aadd(aCabec,{"C5_CLIENTE", cA1Cod   , Nil})
			aadd(aCabec,{"C5_LOJACLI", cA1Loja  , Nil})
			aadd(aCabec,{"C5_LOJAENT", cA1Loja  , Nil})
			aadd(aCabec,{"C5_CONDPAG", cE4Codigo, Nil})

			If cPaisLoc == "PTG"
				aadd(aCabec, {"C5_DECLEXP", "TESTE", Nil})
			Endif

			//ALTERACAO NO ITEM
			For nX := 1 To 1
				aLinha := {}
				aadd(aLinha,{"LINPOS"    , "C6_ITEM", StrZero(nX,2)})
				aadd(aLinha,{"AUTDELETA" , "N"      , Nil          })
				aadd(aLinha,{"C6_PRODUTO", cB1Cod   , Nil          })
				aadd(aLinha,{"C6_QTDVEN" , 2        , Nil          })
				aadd(aLinha,{"C6_PRCVEN" , 2000     , Nil          })
				aadd(aLinha,{"C6_PRUNIT" , 2000     , Nil          })
				aadd(aLinha,{"C6_VALOR"  , 4000     , Nil          })
				aadd(aLinha,{"C6_TES"    , cF4TES   , Nil          })
				aadd(aItens, aLinha)
			Next nX

			MSExecAuto({|a, b, c, d| MATA410(a, b, c, d)}, aCabec, aItens, nOpcX, .F.)

			If !lMsErroAuto
				ConOut("Alterado com sucesso! Pedido: " + cDoc)
			Else
				ConOut("Erro na alteracao!")
				MOSTRAERRO()
			EndIf

			ConOut("Fim: " + Time())

			//****************************************************************
			//* EXCLUSAO - INICIO
			//****************************************************************

		ELSEIF nOpcX = 5 //Exclusao
			ConOut("Teste de Exclusao")
			ConOut("Inicio: " + Time())
			aCabec         := {}
			aItens         := {}
			aLinha         := {}
			lMsErroAuto    := .F.
			lAutoErrNoFile := .F.

			aadd(aCabec, {"C5_NUM",     cDoc,      Nil})
			aadd(aCabec, {"C5_TIPO",    "N",       Nil})
			aadd(aCabec, {"C5_CLIENTE", cA1Cod,    Nil})
			aadd(aCabec, {"C5_LOJACLI", cA1Loja,   Nil})
			aadd(aCabec, {"C5_LOJAENT", cA1Loja,   Nil})
			aadd(aCabec, {"C5_CONDPAG", cE4Codigo, Nil})

			If cPaisLoc == "PTG"
				aadd(aCabec, {"C5_DECLEXP", "TESTE", Nil})
			Endif

			MSExecAuto({|a, b, c| MATA410(a, b, c)}, aCabec, aItens, 5)

			If !lMsErroAuto
				ConOut("Excluido com sucesso! Pedido: " + cDoc)
			Else
				ConOut("Erro na exclusao!")
			EndIf

			ConOut("Fim: " + Time())
			ConOut(Repl("-",80))
		EndIf
	EndIf

	RESET ENVIRONMENT

Return(.T.)
