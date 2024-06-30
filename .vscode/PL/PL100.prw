#Include "PROTHEUS.ch"
#INCLUDE "TBICONN.CH"

/*/{Protheus.doc} PL100
    PL100 - GERAÇÃO DE PEDIDO DE VENDA COM BASE NO PEDIDO EDI
    MATA410 - EXECAUTO
    Ler ZA0 por cliente/data/natureza/hora de entrega/item
	@type  Function
	@author aSSIS
	@since 05/06/2024
	@version 1.0
	@param param_name, param_type, param_descr
	@return return_var, return_type, return_description
    /*/

User Function PL100()
	Local aArea   		:= GetArea()
	Local cFunBkp 		:= FunName()

	Local cSql			:= ""
	Local nQtde       	:= 0
	Local aLinha     	:= {}

	Private cAliasZA0

	// Tabelas
	Private aItensFat   := {}	// Itens a faturar					(produto, qtde, ts, data, pedido, preco, acao)
	Private aLinGrav   	:= {}	// Linhas ZA0 gravadas no pedido

	Private nPed        := 0
	Private dLimite     := Date()

	Private cCliente    := ''
	Private cLoja       := ''
	Private cData       := ''
	Private cNatureza   := ''
	Private cHrEntr     := ''
	Private cGrupoPV    := ''
	Private cProduto    := ''

	if VerParam() == .F.
		return
	endif

	// Ler os pedidos EDI
	cSql := "SELECT ZA0.*, A7_XNATUR, B1_DESC, B1_TS, B1_UM, A7_XGRUPV"
	cSql += "  FROM  " + RetSQLName("ZA0") + " ZA0 "

	cSql += " INNER JOIN " + RetSQLName("SB1") + " SB1"
	cSql += "    ON B1_COD 			=  ZA0_PRODUT "

	cSql += " INNER JOIN " + RetSQLName("SA7") + " SA7 "
	cSql += "    ON A7_CLIENTE 		=  ZA0_CLIENT"
	cSql += "   AND A7_LOJA 		=  ZA0_LOJA"
	cSql += "   AND A7_PRODUTO 		=  ZA0_PRODUT"

	cSql += " WHERE ZA0_CLIENT  	=  '" + cCliente + "'"
	cSql += "   AND ZA0_LOJA    	=  '" + cLoja + "'"
	cSql += "   AND ZA0_DTENTR 		<= '" + Dtos(dLimite) + "'"
	cSql += "   AND ZA0_TIPOPE  	=  'F' "
	cSql += "   AND ZA0_STATUS  	=  '0' "
	cSql += "   AND ZA0_QTDE    	>  ZA0_QTCONF "

	cSql += "   AND B1_FILIAL 		=  '" + xFILIAL("SB1") + "'"
	cSql += "   AND A7_FILIAL 		=  '" + xFILIAL("SA7") + "'"

	cSql += "   AND ZA0.D_E_L_E_T_ 	<> '*' "
	cSql += "   AND SB1.D_E_L_E_T_ 	<> '*' "
	cSql += "   AND SA7.D_E_L_E_T_  <> '*' "

	if cCliente == "000001" .OR. cCliente == "000002" .OR. cCliente == "000003"  // Kanjiko e GKTB quebra por projeto
		cSql += " ORDER BY ZA0_DTENTR, A7_XNATUR, ZA0_HRENTR, A7_XGRUPV, ZA0_PRODUT "
	else
		if cCliente == "000004"  // Gestamp Betim quebra por item
			cSql += " ORDER BY ZA0_DTENTR, A7_XNATUR, ZA0_PRODUT "
		else
			cSql += " ORDER BY ZA0_DTENTR, A7_XNATUR, ZA0_HRENTR, ZA0_PRODUT "
		endif
	endif

	cAliasZA0 := MPSysOpenQuery(cSql)

	if (cAliasZA0)->(EOF())
		FWAlertWarning("NAO FOI ENCONTRADO NENHUM PEDIDO PARA SER GERADO! ","Geracao de pedidos de venda")
		return .T.
	endif

	While (cAliasZA0)->(!EOF())
		if Consistencia() == .T.

			if VerQuebra() == .T.
				u_PL100A(@aItensFat)

				cProduto    := (cAliasZA0)->ZA0_PRODUT
				cData       := (cAliasZA0)->ZA0_DTENTR
				cHrEntr     := (cAliasZA0)->ZA0_HRENTR
				cNatureza   := (cAliasZA0)->A7_XNATUR
				cGrupoPV    := (cAliasZA0)->A7_XGRUPV
				aItensFat 	:= {}
				aItensRet 	:= {}
			endif

			nQtde  := (cAliasZA0)->ZA0_QTDE - (cAliasZA0)->ZA0_QTCONF

			// (produto, qtde, ts, data, pedido, preco, acao)
			aLinha := {(cAliasZA0)->ZA0_PRODUT,	nQtde, (cAliasZA0)->B1_TS, ;
				Stod((cAliasZA0)->ZA0_DTENTR), (cAliasZA0)->ZA0_NUMPED, DA1->DA1_PRCVEN, .T.}

			aadd(aItensFat, aLinha)
		endif

		(cAliasZA0)->(DbSkip())
	End While

	u_PL100A(@aItensFat)

	if nPed == 0
		FWAlertSuccess("NAO FOI CRIADO NENHUM PEDIDO DE VENDA!", "Geracao de Pedidos de Vendas")
	Else
		FWAlertSuccess("FORAM CRIADOS " + cValToChar(nPed) + " PEDIDOS DE VENDAS", "Geracao de Pedidos de Vendas")
	EndIf

	SetFunName(cFunBkp)
	RestArea(aArea)
Return(.T.)


/*------------------------------------------------------------------------------
	Verifica se houve quebra para gerar novo pedido
/*-----------------------------------------------------------------------------*/
Static Function VerQuebra()
	Local lQuebra	:= .F.

	if cCliente == "000001" .OR. cCliente == "000002" .OR. cCliente == "000003" // Kanjiko e GKTB quebra por projeto
		if (cAliasZA0)->ZA0_DTENTR != cData 			.or. ;
				(cAliasZA0)->ZA0_HRENTR  != cHrEntr 	.or. ;
				(cAliasZA0)->A7_XNATUR   != cNatureza 	.or. ;
				(cAliasZA0)->A7_XGRUPV   != cGrupoPV
			lQuebra := .T.
		EndIf
	Else
		if cCliente == "000004"  // Gestamp Betim quebra por item
			if (cAliasZA0)->ZA0_DTENTR != cData 			.or. ;
					(cAliasZA0)->ZA0_PRODUT != cProduto 	.or. ;
					(cAliasZA0)->A7_XNATUR  != cNatureza
				lQuebra := .T.
			EndIf
		else
			if (cAliasZA0)->ZA0_DTENTR != cData .or. ;
					(cAliasZA0)->ZA0_HRENTR != cHrEntr 		.or. ;
					(cAliasZA0)->A7_XNATUR  != cNatureza
				lQuebra := .T.
			EndIf
		endif
	EndIf

return lQuebra


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
