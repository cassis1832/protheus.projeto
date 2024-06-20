#Include "PROTHEUS.ch"
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
	Local nQtde       	:= 0
	Local nValor		:= 0
	Local nLinha     	:= 0
	Local aLinha      	:= {}

	Private cAliasZA0

	Private nOpcX       := 3            //Seleciona o tipo da operacao (3-Inclusao / 4-Alteracao / 5-Exclusao)
	Private cDoc       	:= ""    	    // Numero do Pedido de Vendas (alteracao ou exclusao)
	Private aCabec      := {}
	Private aItens      := {}
	Private aGravados   := {}

	Private nPed        := 0
	Private dLimite     := Date()

	Private cCliente    := ''
	Private cLoja       := ''
	Private cData       := ''
	Private cNatureza   := ''
	Private cHrEntr     := ''

	Private lMsErroAuto 	:= .F.
	Private lAutoErrNoFile 	:= .F.

	chkFile("SC5")
	chkFile("SC6")

	if VerParam() == .F.
		return
	endif

	cSql := "SELECT ZA0.*, A7_XNATUR, B1_DESC, B1_TS, B1_UM "
	cSql += "  FROM  " + RetSQLName("ZA0") + " ZA0 "

	cSql += " INNER JOIN " + RetSQLName("SB1") + " SB1 "
	cSql += "    ON B1_FILIAL 		=  '" + xFILIAL("SB1") + "'"
	cSql += "   AND B1_COD 			=  ZA0_PRODUT "
	cSql += "   AND SB1.D_E_L_E_T_ 	<> '*' "

	cSql += " INNER JOIN " + RetSQLName("SA7") + " SA7 "
	cSql += "    ON A7_FILIAL 		=  '" + xFILIAL("SA7") + "'"
	cSql += "   AND A7_CLIENTE 		=  ZA0_CLIENT "
	cSql += "   AND A7_LOJA 		=  ZA0_LOJA "
	cSql += "   AND A7_PRODUTO 		=  ZA0_PRODUT "
	cSql += "   AND SA7.D_E_L_E_T_  <> '*' "

	cSql += " WHERE ZA0_CLIENT  	=  '" + cCliente + "' "
	cSql += "   AND ZA0_LOJA    	=  '" + cLoja + "' "
	cSql += "   AND ZA0_DTENTR 		<= '" + Dtos(dLimite) + "' "
	cSql += "   AND ZA0_TIPOPE  	=  'F' "
	cSql += "   AND ZA0_STATUS  	=  '0' "
	cSql += "   AND ZA0_QTDE    	>  ZA0_QTCONF "
	cSql += "   AND ZA0.D_E_L_E_T_ 	<> '*' "
	cSql += " ORDER BY ZA0_DTENTR, A7_XNATUR, ZA0_HRENTR, ZA0_PRODUT "

	cAliasZA0 := MPSysOpenQuery(cSql)

	if (cAliasZA0)->(EOF())
		FWAlertWarning("NAO FOI ENCONTRADO NENHUM PEDIDO PARA SER GERADO! ","Geracao de pedidos de venda")
		return .T.
	endif

	While (cAliasZA0)->(!EOF())
		if Consistencia() == .T.
			if (cAliasZA0)->ZA0_DTENTR != cData .or. ;
					(cAliasZA0)->ZA0_HRENTR != cHrEntr .or. ;
					(cAliasZA0)->A7_XNATUR  != cNatureza

				if Len(aCabec) > 0 .And. Len(aItens) > 0
					GravaPedido()
				endif

				cData       := (cAliasZA0)->ZA0_DTENTR
				cHrEntr     := (cAliasZA0)->ZA0_HRENTR
				cNatureza   := (cAliasZA0)->A7_XNATUR
				nLinha 		:= 0

				cDoc := GetSxeNum("SC5", "C5_NUM")
				RollBAckSx8()

				aCabec   := {}
				aItens   := {}
				aLinha   := {}

				aadd(aCabec, {"C5_NUM"    , cDoc, Nil})
				aadd(aCabec, {"C5_TIPO"	  , "N", Nil})
				aadd(aCabec, {"C5_CLIENTE", cCliente, Nil})
				aadd(aCabec, {"C5_LOJACLI", cLoja, Nil})
				aadd(aCabec, {"C5_LOJAENT", cLoja, Nil})
				aadd(aCabec, {"C5_CONDPAG", SA1->A1_COND, Nil})
				aadd(aCabec, {"C5_NATUREZ", cNatureza, Nil})
			EndIf

			nQtde  := (cAliasZA0)->ZA0_QTDE - (cAliasZA0)->ZA0_QTCONF
			nValor := (cAliasZA0)->ZA0_QTDE * DA1->DA1_PRCVEN
			nLinha := nLinha + 1

			aLinha := {}
			aadd(aLinha,{"C6_ITEM"      , StrZero(nLinha,2), Nil})
			aadd(aLinha,{"C6_PRODUTO"   , (cAliasZA0)->ZA0_PRODUT, Nil})
			aadd(aLinha,{"C6_QTDVEN"    , nQtde, Nil})
			aadd(aLinha,{"C6_PRCVEN"    , DA1->DA1_PRCVEN, Nil})
			aadd(aLinha,{"C6_PRUNIT"    , DA1->DA1_PRCVEN, Nil})
			aadd(aLinha,{"C6_TES"       , (cAliasZA0)->B1_TS, Nil})
			aadd(aLinha,{"C6_ENTREG"    , Stod((cAliasZA0)->ZA0_DTENTR), Nil})
			aadd(aLinha,{"C6_PEDCLI"    , (cAliasZA0)->ZA0_NUMPED, Nil})

			// aadd(aLinha,{"C6_NUMPCOM" 	, (cAliasZA0)->ZA0_NUMPED 	, Nil})
			// aadd(aLinha,{"C6_ITEMPC" 	, (cAliasZA0)->ZA0_NUMPED 	, Nil})

			aadd(aItens, aClone(aLinha))

			aadd(aGravados,(cAliasZA0)->R_E_C_N_O_)

			//Gera devoluções com base na estrutura
			u_PL020E(@aItens)
		endif

		(cAliasZA0)->(DbSkip())
	End While

	if Len(aCabec) > 0 .And. Len(aItens) > 0
		GravaPedido()
	endif

	FWAlertSuccess("Foram criados " + cValToChar(nPed) + " pedidos de vendas", "Geracao de Pedidos de Vendas")
Return(.T.)


/*--------------------------------------------------------------------------
   Consistir os parametros informados pelo usuario
/*-------------------------------------------------------------------------*/
Static Function VerParam()
	Local aPergs        := {}
	Local aResps	    := {}
	Local lRet 			:= .T.

	AAdd(aPergs, {1, "Informe o cliente ", CriaVar("ZA0_CLIENT",.F.),,,"SA1",, 50, .F.})
	AAdd(aPergs, {1, "Informe a loja "   , CriaVar("ZA0_LOJA",.F.),,,"SA1",, 50, .F.})
	AAdd(aPergs, {1, "Informe a data de entrega limite ", CriaVar("ZA0_DTENTR",.F.),,,"ZA0",, 50, .F.})

	If ParamBox(aPergs, "Parametros", @aResps,,,,,,,, .T., .T.)
		cCliente := aResps[1]
		cLoja    := aResps[2]
		dLimite  := aResps[3]
	Else
		lRet := .F.
		return lRet
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


/*--------------------------------------------------------------------------
   Grava o pedido no sistema
/*-------------------------------------------------------------------------*/
Static Function GravaPedido()
	MSExecAuto({|a, b, c, d| MATA410(a, b, c, d)}, aCabec, aItens, nOpcX, .F.)

	If !lMsErroAuto
		nPed := nPed + 1
		AtualizaGravados()
	Else
		ConOut("Erro na inclusao!")
		MOSTRAERRO()
	EndIf
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

	aGravados := {}
return

/*--------------------------------------------------------------------------
   Consistencia do arquivo ZA0 - grava status com erro
/*-------------------------------------------------------------------------*/
Static Function Consistencia()
	Local lOk1 := .T.

    // Verificar a TES do item
    if (cAliasZA0)->B1_TS == ''
        lOk1:= .F.
        FWAlertError("TES INVALIDA DO ITEM = " + ZA0->ZA0_PRODUT, ;
        "Cadastro Produto")
    Else
        if (cAliasZA0)->A7_XNATUR == ''
            lOk1:= .F.
            FWAlertError("Falta natureza na relacao Item X Cliente (" + ZA0->ZA0_PRODUT + "/" + ZA0->ZA0_CLIENT + ")!", ;
            "Cadastro Produto/Cliente")
        EndIf
    EndIf

    // Verificar a tabela de precos do item/cliente
    if lOk1 == .T.
		// Verificar a tabela de precos do cliente
		If DA1->(! MsSeek(xFilial("DA1") + SA1->A1_TABELA + (cAliasZA0)->ZA0_PRODUT, .T.))
			if DA1->DA1_CODPRO == (cAliasZA0)->ZA0_PRODUT .AND. DA1->DA1_CODTAB == SA1->A1_TABELA
                lOk1 := .F.
                FWAlertError("Tabela de precos nao encontrada para o item = " + (cAliasZA0)->ZA0_PRODUT, ;
                "Tabela de precos")
            EndIf
        EndIf
    endif

return lOk1
