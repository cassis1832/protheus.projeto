#INCLUDE "PROTHEUS.CH"
#INCLUDE "TBICONN.CH"

/*/{Protheus.doc} PL020D
    PL030 - GERAÇÃO DE PEDIDO DE VENDA COM BASE NO PEDIDO EDI
    MATA410 - EXECAUTO
    Ler ZA0 por cliente/data/natureza/hora de entrega/item
	@type  Function
	@author aSSIS
	@since 05/06/2024
	@version 1.0
	@param param_name, param_type, param_descr
	@return return_var, return_type, return_description
    /*/

User Function PL020D()
	Local aPergs        := {}
	Local aResps	    := {}
	Local nItem 	    := 0

	Private nOpcX       := 3	                // Tipo da operação (3-Inclusão / 4-Alteração / 5-Exclusão)
	Private cDoc        := ""    	            // Numero do Pedido de Vendas (alteracao ou exclusao)

	Private nX          := 0
	Private nY          := 0
	Private aCabec      := {}
	Private aItens      := {}
	Private aLinha      := {}
	Private aGravados   := {}

	Private lOk         := .T.
	Private lTemLinha   := .T.
	Private nPed        := 0
	Private nQtde       := 0
	Private dLimite     := Date()

	Private cCliente    := ''
	Private cLoja       := ''
	Private cData       := ''
	Private cNatureza   := ''
	Private cHrEntr     := ''

	Private lMsErroAuto := .F.
	Private lAutoErrNoFile := .F.

	AAdd(aPergs, {1, "Informe o cliente ", CriaVar("ZA0_CLIENT",.F.),,,"SA1",, 50, .F.})
	AAdd(aPergs, {1, "Informe a loja "   , CriaVar("ZA0_LOJA",.F.),,,"SA1",, 50, .F.})
	AAdd(aPergs, {1, "Informe a data de entrega limite ", CriaVar("ZA0_DTENTR",.F.),,,"ZA0",, 50, .F.})

	If ParamBox(aPergs, "Parametros", @aResps,,,,,,,, .T., .T.)
		cCliente := aResps[1]
		cLoja    := aResps[2]
		dLimite  := aResps[3]
	Else
		return
	endif

	SA1->(dbSetOrder(1))
	SE4->(dbSetOrder(1))
	DA1->(dbSetOrder(2)) // DA1_FILIAL+DA1_CODPRO+DA1_CODTAB+DA1_ITEM

	// Verificar o cliente
	if SA1->(! MsSeek(xFilial("SA1") + cCliente + cLoja))
		lOk := .F.
		FWAlertError("Cliente nao cadastrado: " + cCliente,"Cadastro de Clientes")
	else
		// Verificar condição de pagamento do cliente
		If SE4->(! MsSeek(xFilial("SE4") + SA1->A1_COND))
			lOk := .F.
			FWAlertError("Cliente sem condicao de pagamento cadastrada: " + cCliente,"Condicao de Pagamento")
		EndIf

		// Verificar a tabela de precos do cliente
		If SA1->A1_TABELA == ""
			lOk:= .F.
			FWAlertError("Tabela de precos do cliente nao encontrada!", "Tabela de precos")
		EndIf
	EndIf

	if lOk == .F.
		return
	endif

	strSql := "SELECT ZA0010.*, SA7010.*, B1_TS "
	strSql += "  FROM ZA0010, SB1010, SA7010 "
	strSql += " WHERE ZA0_CLIENT  = '" + cCliente + "' "
	strSql += "   AND ZA0_LOJA    = '" + cLoja + "' "
	strSql += "   AND ZA0_DTENTR <= '" + Dtos(dLimite) + "' "
	strSql += "   AND ZA0_TIPOPE  = 'F' "
	strSql += "   AND ZA0_STATUS  = '0' "
	strSql += "   AND ZA0_QTDE    > ZA0_QTCONF "
	strSql += "   AND ZA0_FILIAL  = B1_FILIAL "
	strSql += "   AND ZA0_PRODUT  = B1_COD "
	strSql += "   AND ZA0_FILIAL  = A7_FILIAL "
	strSql += "   AND ZA0_CLIENT  = A7_CLIENTE "
	strSql += "   AND ZA0_LOJA    = A7_LOJA "
	strSql += "   AND ZA0_PRODUT  = A7_PRODUTO "
	strSql += "   AND ZA0010.D_E_L_E_T_ <> '*' "
	strSql += "   AND SB1010.D_E_L_E_T_ <> '*' "
	strSql += "   AND SA7010.D_E_L_E_T_ <> '*' "
	strSql += " ORDER BY ZA0_DTENTR, A7_XNATUR, ZA0_HRENTR, ZA0_PRODUT "

	cAlias := MPSysOpenQuery(strSql)

	While (cAlias)->(!EOF())

		lOk := 	Consistencia()

		if lOk == .T.
			if (cAlias)->ZA0_DTENTR != cData .or. ;
					(cAlias)->ZA0_HRENTR != cHrEntr .or. ;
					(cAlias)->A7_XNATUR  != cNatureza

				GravaPedido()

				cData       := (cAlias)->ZA0_DTENTR
				cHrEntr     := (cAlias)->ZA0_HRENTR
				cNatureza   := (cAlias)->A7_XNATUR

				cDoc := GetSxeNum("SC5", "C5_NUM")

				RollBAckSx8()
				aCabec      := {}
				aItens      := {}
				aLinha      := {}
				aGravados   := {}
				lTemLinha   := .F.
				nItem       := 0

				// aadd(aCabec, {"C5_NUM"    , (cAlias)->ZA0_DOC	, Nil})
				aadd(aCabec, {"C5_TIPO",    "N", Nil})
				aadd(aCabec, {"C5_CLIENTE", cCliente, Nil})
				aadd(aCabec, {"C5_LOJACLI", cLoja, Nil})
				aadd(aCabec, {"C5_LOJAENT", cLoja, Nil})
				aadd(aCabec, {"C5_CONDPAG", SA1->A1_COND, Nil})
				aadd(aCabec, {"C5_NATUREZ", cNatureza, Nil})
			EndIf

			nQtde := (cAlias)->ZA0_QTDE - (cAlias)->ZA0_QTCONF
			nX := nX + 1

			//nItem := nItem + 5

			aLinha := {}
			aadd(aLinha,{"C6_ITEM"      , StrZero(nX,2), Nil})
			aadd(aLinha,{"C6_PRODUTO"   , (cAlias)->ZA0_PRODUT, Nil})
			aadd(aLinha,{"C6_TES"       , (cAlias)->B1_TS, Nil})
			aadd(aLinha,{"C6_ENTREG"    , Stod((cAlias)->ZA0_DTENTR), Nil})
			aadd(aLinha,{"C6_QTDVEN"    , nQtde, Nil})
			aadd(aLinha,{"C6_PEDCLI"    , (cAlias)->ZA0_NUMPED, Nil})
			aadd(aLinha,{"C6_XCODPED"   , (cAlias)->ZA0_CODPED, Nil})
			aadd(aLinha,{"C6_VALOR"     , (cAlias)->ZA0_QTDE * DA1->DA1_PRCVEN, Nil})
			aadd(aLinha,{"C6_PRCVEN"    , DA1->DA1_PRCVEN, Nil})
			aadd(aLinha,{"C6_PRUNIT"    , DA1->DA1_PRCVEN, Nil})

			// aadd(aLinha,{"C6_NUMPCOM" 	, (cAlias)->ZA0_NUMPED 	, Nil})
			// aadd(aLinha,{"C6_ITEMPC" 	, (cAlias)->ZA0_NUMPED 	, Nil})

			aadd(aItens, aLinha)

			lTemLinha := .T.

			aadd(aGravados,(cAlias)->R_E_C_N_O_)

			//Gera devoluções com base na estrutura
			//u_PL020E(@aItens)
		endif

		(cAlias)->(DbSkip())

	End While

	GravaPedido()

	FWAlertSuccess("Pedidos gerados com sucesso!", "Geracao de Pedidos de Vendas")
Return(.T.)

/*--------------------------------------------------------------------------
   Grava o pedido no sistema
/*-------------------------------------------------------------------------*/
Static Function GravaPedido()

	// Primeira vez não grava porque está vazio
	if cNatureza != '' .and. lTemLinha == .T.

		MSExecAuto({|a, b, c, d| MATA410(a, b, c, d)}, aCabec, aItens, nOpcX, .F.)

		If !lMsErroAuto
			nPed := nPed + 1
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
        ZA0->ZA0_QTCONF  := ZA0->ZA0_QTDE
		ZA0->ZA0_STATUS  := '9'
		ZA0->(MsUnlock())
	Next

return

/*--------------------------------------------------------------------------
   Consistencia do arquivo ZA0 - grava status com erro
/*-------------------------------------------------------------------------*/
Static Function Consistencia()
	Local lOk1 := .T.

    // Verificar a TES do item
    if (cAlias)->B1_TS == ''
        lOk1:= .F.
        FWAlertError("TES INVALIDA DO ITEM = " + ZA0->ZA0_PRODUT, ;
        "Cadastro Produto")
    Else
        if (cAlias)->A7_XNATUR == ''
            lOk1:= .F.
            FWAlertError("Falta natureza na relacao Item X Cliente (" + ZA0->ZA0_PRODUT + "/" + ZA0->ZA0_CLIENT + ")!", ;
            "Cadastro Produto/Cliente")
        EndIf
    EndIf

    // Verificar a tabela de precos do item/cliente
    if lOk1 == .T.
    	If DA1->(! MsSeek(xFilial("DA1") + (cAlias)->ZA0_PRODUT + SA1->A1_TABELA + AvKey("", "DA1_ITEM"), .T.))
            if DA1->DA1_CODPRO == (cAlias)->ZA0_PRODUT .AND. DA1->DA1_CODTAB == SA1->A1_TABELA
            else
                lOk1 := .F.
                FWAlertError("Tabela de precos nao encontrada para o item = " + (cAlias)->ZA0_PRODUT, ;
                "Tabela de precos")
            EndIf
        EndIf
    endif

return lOk1
