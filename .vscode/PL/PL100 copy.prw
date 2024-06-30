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

	Private cAliasTT
	Private cTableName
	Private oTempTable

	Private cAliasZA0

	// Tabelas
	Private aItensFat   := {}	// Itens a faturar					(produto, qtde, ts, data, pedido, acao, preco)
	Private aItensRet   := {}	// Itens a retornar 				(nIndFat, produto, qtde)

	Private aLinGrav   	:= {}	// Linhas ZA0 gravadas no pedido

	Private nPed        := 0
	Private dLimite     := Date()

	Private cCliente    := ''
	Private cLoja       := ''
	Private cData       := ''
	Private cNatureza   := ''
	Private cHrEntr     := ''
	Private cProjeto    := ''
	Private cProduto    := ''

	Private nLinha     	:= 0
	Private aLinha     	:= {}

	Private lMsErroAuto 	:= .F.
	Private lAutoErrNoFile 	:= .F.

	if VerParam() == .F.
		return
	endif

	oTempTable := FWTemporaryTable():New()

	aFields := {}
	aAdd(aFields, {"ID"			, "C", 36, 0})
	aAdd(aFields, {"TT_PRODUTO"	, "C", 15, 0})
	aAdd(aFields, {"TT_DOC"		, "C",  9, 0})
	aAdd(aFields, {"TT_SERIE"	, "C",  3, 0})
	aAdd(aFields, {"TT_EMISSAO"	, "D",  8, 0})
	aAdd(aFields, {"TT_PRUNIT"	, "N", 12, 2})
	aAdd(aFields, {"TT_SALDO"	, "N", 12, 2})
	aAdd(aFields, {"TT_USADA"	, "N", 12, 2})
	aAdd(aFields, {"TT_WORK"	, "N", 12, 2})

	oTempTable:SetFields( aFields )
	oTempTable:AddIndex("1", {"ID"} )
	oTempTable:AddIndex("2", {"TT_PRODUTO", "TT_EMISSAO", "TT_DOC", "ID"} )
	oTempTable:Create()

	cAliasTT    := oTempTable:GetAlias()
	cTableName  := oTempTable:GetRealName()

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
				TrataPedido()
				aItensFat := {}
				aItensRet := {}
			endif

			nQtde  := (cAliasZA0)->ZA0_QTDE - (cAliasZA0)->ZA0_QTCONF

			aLinha := {(cAliasZA0)->ZA0_PRODUT,	nQtde, DA1->DA1_PRCVEN, (cAliasZA0)->B1_TS,	;
				Stod((cAliasZA0)->ZA0_DTENTR), (cAliasZA0)->ZA0_NUMPED, .T.}
			aadd(aItensFat, aLinha)
		endif

		(cAliasZA0)->(DbSkip())
	End While

	TrataPedido()

	if nPed == 0
		FWAlertSuccess("NAO FOI CRIADO NENHUM PEDIDO DE VENDA!", "Geracao de Pedidos de Vendas")
	Else
		FWAlertSuccess("FORAM CRIADOS " + cValToChar(nPed) + " PEDIDOS DE VENDAS", "Geracao de Pedidos de Vendas")
	EndIf

	SetFunName(cFunBkp)
	RestArea(aArea)
Return(.T.)


Static Function TrataPedido()

	if Len(aItensFat) == 0
		return
	endif

	aItensRet := u_PL100A(@aItensFat)

	if Len(aItensRet) > 0
		CargaSaldoTerc()
		VerSaldoTerc()
	endif

	GravaPedido()
return


/*------------------------------------------------------------------------------
	Verificar se tem saldo terc. para todos os retornos por item a faturar
 	Se faltar algum retorno, não fatura o item nem os retornos dele
/*-----------------------------------------------------------------------------*/
Static Function	VerSaldoTerc()
	Local nInd			:= 0
	Local nIndFat		:= 0
	Local nIndRet		:= 0
	Local nIndTerc		:= 0
	Local nSaldoTerc	:= 0

	cAliasTT->(DbSetOrder(2))

	// Percorre os itens a faturar
	For nIndFat := 1 To Len(aItensFat)	

		// Zera Work
		cSql := "UPDATE " + cTableName + " SET TT_WORD = '0'  "

		if TCSqlExec(cSql) < 0
			MsgInfo("Erro na execução da query update 1:", "Atenção")
			MsgInfo(TcSqlError(), "Atenção3")
		endif

		// Percorre os retornos dos itens a faturar
		For nIndRet := 1 To Len(aItensRet)

			if nIndFat == aItensRet[nIndRet][1]

				cAliasTT->( MsSeek(aItensRet[nIndRet][2]) )

				nIndTerc  := aScan(aSaldoTer,{|x| AllTrim(x[1]) == aItensRet[nIndRet][2]})				// Busca o produto

				nSaldoTerc := aSaldoTer[nIndTerc][2] - aSaldoTer[nIndTerc][3] - aSaldoTer[nIndTerc][4]	// saldo - qtde usada - work

				if nSaldoTerc >= aItensRet[nIndRet][3]
					aSaldoTer[nIndTerc][4] := aSaldoTer[nIndTerc][4] + aItensRet[nIndRet][3]
				else
					// Saldo insuficiente
					aItensFat[nIndFat][6] := .F.
				endif
			endif

		next nIndRet

		// Atualiza qtde usada
		if 	aItensFat[nIndFat][6] == .T.
			For nInd := 1 To Len(aSaldoTer)
				aSaldoTer[nInd][3] := aSaldoTer[nInd][3] + aSaldoTer[nInd][4]
			next nInd
		endif

	next nIndFat
Return


/*------------------------------------------------------------------------------
	Carrega tabela temporaria de saldos de terceiros com todos os itens que 
	serão necessários para o pedido
/*-----------------------------------------------------------------------------*/
Static Function	CargaSaldoTerc()
	Local nInd		:= 0
	Local cAlias

	cSql := "DELETE FROM " + cTableName 
	if TCSqlExec(cSql) < 0
		MsgInfo("Erro na execução da query delete 1:", "Atenção")
		MsgInfo(TcSqlError(), "Atenção 1")
	endif

	For nInd := 1 To Len(aItensRet)
		cSql := "SELECT B6_PRODUTO, B6_DOC, B6_SERIE, B6_EMISSAO, B6_PRUNIT, B6_SALDO "
		cSql += " FROM " + RetSQLName("SB6") + " SB6 "
		cSql += "WHERE B6_CLIFOR	  = '" + cCliente + "'"
		cSql += "  AND B6_LOJA 		  = '" + cLoja + "' "
		cSql += "  AND B6_PRODUTO 	  = '" + aItensRet[nInd][2] + "' "
		cSql += "  AND B6_SALDO 	  > 0"
		cSql += "  AND B6_FILIAL 	  = '" + xFilial("SB6") + "' "
		cSql += "  AND SB6.D_E_L_E_T_ = ' ' "
		cSql += "ORDER BY B6_EMISSAO "
		cAlias := MPSysOpenQuery(cSql)

		While (cAlias)->(!EOF())
			RecLock(cAliasTmp, .T.)
			(cAliasTmp)->ID				= FWUUIDv4()
			(cAliasTmp)->TT_PRODUTO		= (cAlias)->B6_PRODUTO
			(cAliasTmp)->TT_DOC			= (cAlias)->B6_DOC
			(cAliasTmp)->TT_SERIE		= (cAlias)->B6_SERIE
			(cAliasTmp)->TT_EMISSAO 	= (cAlias)->B6_EMISSAO 
			(cAliasTmp)->TT_PRUNIT 		= (cAlias)->B6_PRUNIT
			(cAliasTmp)->TT_SALDO 		= (cAlias)->B6_SALDO
			(cAliasTmp)->TT_USADA		= 0
			(cAliasTmp)->TT_WORK		= 0
			(cAliasTmp)->(MsUnlock())
			(cAlias)->(DbSkip())
		EndDo
	next nInd
Return


/*------------------------------------------------------------------------------
	Verifica se houve quebra para gerar novo pedido
/*-----------------------------------------------------------------------------*/
Static Function VerQuebra()
	Local lQuebra	:= .F.

	if cCliente == "000001" .OR. cCliente == "000002" .OR. cCliente == "000003" // Kanjiko e GKTB quebra por projeto
		if (cAliasZA0)->ZA0_DTENTR != cData 			.or. ;
				(cAliasZA0)->ZA0_HRENTR  != cHrEntr 	.or. ;
				(cAliasZA0)->A7_XNATUR   != cNatureza 	.or. ;
				(cAliasZA0)->A7_XGRUPV   != cProjeto
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
   Grava o pedido no sistema
/*-------------------------------------------------------------------------*/
Static Function GravaPedido()
	Local nOpcX 	:= 3            //Seleciona o tipo da operacao (3-Inclusao / 4-Alteracao / 5-Exclusao)
	Local nIndFat	:= 0
	Local nIndRet	:= 0

	Local aCabec    := {}			// Cabecalho do pedido - MATA410
	Local aLinhas	:= {}			// Linhas do pedido - MATA410

	nLinha := 0

	For nIndFat := 1 To Len(aItensFat)	
		if aItensFat[nIndFat][6] == .T.

			aLinha := {}
			nLinha := nLinha + 1
			aadd(aLinha,{"C6_ITEM"      , StrZero(nLinha,2), Nil})
			aadd(aLinha,{"C6_PRODUTO"   , aItensFat[nIndFat][1], Nil})
			aadd(aLinha,{"C6_QTDVEN"    , aItensFat[nIndFat][2], Nil})
			aadd(aLinha,{"C6_PRCVEN"    , aItensFat[nIndFat][3], Nil})
			aadd(aLinha,{"C6_PRUNIT"    , aItensFat[nIndFat][3], Nil})
			aadd(aLinha,{"C6_TES"       , aItensFat[nIndFat][4], Nil})
			aadd(aLinha,{"C6_ENTREG"    , aItensFat[nIndFat][5], Nil})
			aadd(aLinha,{"C6_PEDCLI"    , aItensFat[nIndFat][6], Nil})
			aadd(aLinhas, aLinha)

			For nIndRet := 1 To Len(aItensRet)	
				if nIndFat == aItensRet[nIndRet][1] 
					VerRemessa(aItensRet[nIndRet])
				endif
			next nIndRet
		endif
	next nIndFat

	if Len(aLinhas) > 0
		aCabec   := {}
		aadd(aCabec, {"C5_NUM"    , cDoc, Nil})
		aadd(aCabec, {"C5_TIPO"	  , "N", Nil})
		aadd(aCabec, {"C5_CLIENTE", cCliente, Nil})
		aadd(aCabec, {"C5_LOJACLI", cLoja, Nil})
		aadd(aCabec, {"C5_LOJAENT", cLoja, Nil})
		aadd(aCabec, {"C5_CONDPAG", SA1->A1_COND, Nil})
		aadd(aCabec, {"C5_NATUREZ", cNatureza, Nil})

		MSExecAuto({|a, b, c, d| MATA410(a, b, c, d)}, aCabec, aItens, nOpcX, .F.)

		If !lMsErroAuto
			nPed := nPed + 1
			AtualizaGravados()
		Else
			ConOut("Erro na inclusao!")
			MOSTRAERRO()
		EndIf
	endif
return


Static Function VerRemessa(aItemRet)
	Local nIndTerc	:= 0

	nQtde := aItemRet[3]

	For nIndTerc := 1 To Len(aSaldoNF)	

		if aItemRet[2] == aSaldoNF[1]		// produto

		
		endif
		
		aadd(aSaldoTer, {aItensRet[nInd][2], nQtde, 0})
	aLinha := {}
	nLinha := nLinha + 1
	aadd(aLinha,{"C6_ITEM"      , StrZero(nLinha,2), Nil})
	aadd(aLinha,{"C6_PRODUTO"   , aItensRet[nIndRet][1], Nil})
	aadd(aLinha,{"C6_QTDVEN"    , aItensRet[nIndRet][2], Nil})
	aadd(aLinha,{"C6_PRCVEN"    , DA1->DA1_PRCVEN, Nil})
	aadd(aLinha,{"C6_PRUNIT"    , DA1->DA1_PRCVEN, Nil})
	aadd(aLinha,{"C6_TES"       , aItensFat[nIndFat][3], Nil})
	aadd(aLinha,{"C6_ENTREG"    , aItensFat[nIndFat][4], Nil})
	aadd(aLinha,{"C6_PEDCLI"    , aItensFat[nIndFat][5], Nil})
	aadd(aLinhas, aLinha)
	next nIndTerc
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
