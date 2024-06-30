#Include "PROTHEUS.ch"
#INCLUDE "TBICONN.CH"

/*/{Protheus.doc} PL100A
    PL100A - GERAÇÃO DE PEDIDO DE VENDA COM BASE NO PEDIDO EDI
    MATA410 - EXECAUTO
	Params: aItensFat
		aItensFat - Itens a faturar	(produto, qtde, ts, data, pedido, preco, acao)
	@since 05/06/2024
/*/
User Function PL100A(aItensFat)
	Local aArea   		:= GetArea()
	Local cFunBkp 		:= FunName()

	// Tabelas
	Private aItensRet   := {}	// Itens a retornar 		(nIndFat, produto, qtde, agrega)
	Private aSaldoTer  	:= {}	// Saldos de terceiros		(produto, docto, serie, emissao, saldo, preco, usada, work)
	Private aLinGrav   	:= {}	// Linhas ZA0 gravadas no pedido

	if Len(aItensFat) == 0
		return
	endif

	// Explosão para carregar tabela de itens a retornar
	aItensRet := u_PL100B(@aItensFat)

	if Len(aItensRet) > 0
		TrataSaldoTerc()
	endif

	GravaPedido()

	SetFunName(cFunBkp)
	RestArea(aArea)
return


/*------------------------------------------------------------------------------
	Tratamento dos itens que devem ser retornados de terceiros
	Saldos de terceiros	(produto, docto, serie, emissao, preco, saldo, usada, work)
/*-----------------------------------------------------------------------------*/
Static Function	TrataSaldoTerc()
	Local cAlias
	Local cSql		:= ""
	Local nIndFat	:= 0
	Local nIndRet	:= 0
	Local nIndTerc	:= 0
	Local aLinha  	:= {}

	//Carrega tabela temporaria de saldos de terceiros com todos os itens que 
	//serão necessários para o pedido - SB6
	For nIndRet := 1 To Len(aItensRet)
		cSql := "SELECT B6_PRODUTO, B6_DOC, B6_SERIE, B6_EMISSAO, B6_PRUNIT, B6_SALDO, B6_IDENT "
		cSql += " FROM " + RetSQLName("SB6") + " SB6 "
		cSql += "WHERE B6_CLIFOR	  = '" + cCliente + "'"
		cSql += "  AND B6_LOJA 		  = '" + cLoja + "' "
		cSql += "  AND B6_PRODUTO 	  = '" + aItensRet[nIndRet][2] + "' "
		cSql += "  AND B6_SALDO 	  > 0"
		cSql += "  AND B6_FILIAL 	  = '" + xFilial("SB6") + "' "
		cSql += "  AND SB6.D_E_L_E_T_ = ' ' "
		cSql += "ORDER BY B6_EMISSAO "
		cAlias := MPSysOpenQuery(cSql)

		While (cAlias)->(!EOF())
			aLinha := {(cAlias)->B6_PRODUTO, (cAlias)->B6_DOC, (cAlias)->B6_SERIE,  ;
					(cAlias)->B6_EMISSAO, (cAlias)->B6_PRUNIT, (cAlias)->B6_SALDO, 0, 0, (cAlias)->B6_IDENT}
			AAdd(aSaldoTer, aLinha)
			(cAlias)->(DbSkip())
		EndDo
	next nInd

	// Percorre os itens a faturar e verifica se existe saldo suficiente para os retornos
	For nIndFat := 1 To Len(aItensFat)	
		// Percorre os retornos necessarios do item
		For nIndRet := 1 To Len(aItensRet)
			if nIndFat == aItensRet[nIndRet][1]
				BuscaSaldoDisp(nIndRet)
			endif
		Next nIndRet

		// Atualiza saldo disponivel em terceiro
		For nIndTerc := 1 To Len(aSaldoTer)
			if 	aItensFat[nIndFat][7] == .T.			// Tem saldo para retornar, atualiza qtde usada
				aSaldoTer[nIndTerc][7] := aSaldoTer[nIndTerc][7] + aSaldoTer[nIndTerc][8]   
			endif
			aSaldoTer[nIndTerc][8] = 0					// Zera work
		Next nIndTerc
	Next nIndFat
Return


/*------------------------------------------------------------------------------
	Busca o item a retornar na tabela de saldos de terceiros
 	Se não tiver saldo suficiente dá mensagem e marca que não pode faturar o item
	Se tiver saldo soma a quant. necessária no campo work
	aSaldoTer  Saldos de terceiros		(produto, docto, serie, emissao, preco, saldo, usada, work)
/*-----------------------------------------------------------------------------*/
Static Function BuscaSaldoDisp(nIndRet)
	Local nIndTerc		:= 0
	Local nIndFat		:= 0
	Local nSaldoDisp	:= 0
	Local nQtdeNec		:= 0
	Local nQtdeUsar		:= 0

	nQtdeNec := aItensRet[nIndRet][3]

	For nIndTerc := 1 To Len(aSaldoTer)
		if nQtdeNec <= 0
			Exit
		endif

		if aSaldoTer[nIndTerc][1] == aItensRet[nIndRet][2]
			nSaldoDisp := aSaldoTer[nIndTerc][6] - aSaldoTer[nIndTerc][7] - aSaldoTer[nIndTerc][8] 

			if nSaldoDisp > 0
				if nSaldoDisp >= nQtdeNec
					aSaldoTer[nIndTerc][8] := aSaldoTer[nIndTerc][8] + nQtdeNec
					nQtdeNec := 0
				else
					nQtdeUsar := aSaldoTer[nIndTerc][6] - aSaldoTer[nIndTerc][7] - aSaldoTer[nIndTerc][8]
					aSaldoTer[nIndTerc][8] := aSaldoTer[nIndTerc][8] + nQtdeUsar
					nQtdeNec := nQtdeNec - nQtdeUsar
				endif
			endif
		endif
	Next nIndTerc
	
	if nQtdeNec > 0 		// Saldo insuficiente
		nIndFat := aItemRet[nIndRet][1]
		aItensFat[nIndFat][6] := .F.
	endif
Return

/*--------------------------------------------------------------------------
   	Grava o pedido no sistema
	aItensFat - Itens a faturar	(produto, qtde, ts, data, pedido, preco, acao)
/*-------------------------------------------------------------------------*/
Static Function GravaPedido()
	Local nOpcX 	:= 3            //Seleciona o tipo da operacao (3-Inclusao / 4-Alteracao / 5-Exclusao)
	Local nIndFat	:= 0
	Local nIndRet	:= 0
	Local aLinha  	:= {}
	Local aCabec    := {}			// Cabecalho do pedido - MATA410
	Local cDoc		:= ""

	Private nLinha 			:= 0
	Private aLinhas			:= {}	// Linhas do pedido - MATA410
	Private lMsErroAuto 	:= .F.
	Private lAutoErrNoFile 	:= .F.

	For nIndFat := 1 To Len(aItensFat)	
		if aItensFat[nIndFat][7] == .T.
			aLinha := {}
			nLinha := nLinha + 1
			aadd(aLinha,{"C6_ITEM"      , StrZero(nLinha,2), Nil})
			aadd(aLinha,{"C6_PRODUTO"   , aItensFat[nIndFat][1], Nil})
			aadd(aLinha,{"C6_QTDVEN"    , aItensFat[nIndFat][2], Nil})
			aadd(aLinha,{"C6_TES"       , aItensFat[nIndFat][3], Nil})
			aadd(aLinha,{"C6_ENTREG"    , aItensFat[nIndFat][4], Nil})
			aadd(aLinha,{"C6_PEDCLI"    , aItensFat[nIndFat][5], Nil})
			aadd(aLinha,{"C6_PRCVEN"    , aItensFat[nIndFat][6], Nil})
			aadd(aLinha,{"C6_PRUNIT"    , aItensFat[nIndFat][6], Nil})
			aadd(aLinhas, aLinha)

			For nIndRet := 1 To Len(aItensRet)	
				if nIndFat == aItensRet[nIndRet][1] 
					VerRemessa(nIndRet)
				endif
			next nIndRet
		endif
	next nIndFat

	if Len(aLinhas) > 0
		cDoc := GetSxeNum("SC5", "C5_NUM")
		RollBAckSx8()

		aCabec := {}
		aadd(aCabec, {"C5_NUM"    , cDoc, Nil})
		aadd(aCabec, {"C5_TIPO"	  , "N", Nil})
		aadd(aCabec, {"C5_CLIENTE", cCliente, Nil})
		aadd(aCabec, {"C5_LOJACLI", cLoja, Nil})
		aadd(aCabec, {"C5_LOJAENT", cLoja, Nil})
		aadd(aCabec, {"C5_CONDPAG", SA1->A1_COND, Nil})
		aadd(aCabec, {"C5_NATUREZ", cNatureza, Nil})

		MSExecAuto({|a, b, c, d| MATA410(a, b, c, d)}, aCabec, aLinhas, nOpcX, .F.)

		If !lMsErroAuto
			//AtualizaGravados()
		Else
			ConOut("Erro na inclusao!")
			MOSTRAERRO()
		EndIf
	endif
return

///	aSaldoTer  Saldos de terceiros		(produto, docto, serie, emissao,  preco, saldo, usada, work)
Static Function VerRemessa(nIndRet)
	Local aLinha  	:= {}
	Local nQtdeVen	:= 0
	Local nIndTerc 	:= 0
	Local nIndFat	:= aItensRet[nIndRet][1]
	Local aItemOri  := {}
	Local nQtdeNec	:= aItensRet[nIndRet][3]

	For nIndTerc := 1 To Len(aSaldoTer)	
		if nQtdeNec <= 0 
			Exit
		endif

		if aItensRet[nIndRet][2] == aSaldoTer[nIndTerc][1]		// produto

			nSaldoDisp := aSaldoTer[nIndTerc][6]

			if nSaldoDisp > 0
				if nSaldoDisp >= nQtdeNec
					nQtdeVen := nQtdeNec
					aSaldoTer[nIndTerc][6] := aSaldoTer[nIndTerc][6] - nQtdeNec
					nQtdeNec := 0
				else
					nQtdeVen := aSaldoTer[nIndTerc][6] 
					aSaldoTer[nIndTerc][6] := 0
					nQtdeNec := nQtdeNec - nQtdeVen
				endif

				aItemOri := LerNFE(aSaldoTer[nIndTerc][2], ;
									aSaldoTer[nIndTerc][1], ;
									aSaldoTer[nIndTerc][9])

				aLinha := {}
				nLinha := nLinha + 1
				aadd(aLinha,{"C6_ITEM"      , StrZero(nLinha,2), Nil})
				aadd(aLinha,{"C6_PRODUTO"   , aSaldoTer[nIndTerc][1], Nil})
				aadd(aLinha,{"C6_QTDVEN"    , nQtdeVen, Nil})
				aadd(aLinha,{"C6_PRCVEN"    , aItemOri[2] , Nil})
				aadd(aLinha,{"C6_PRUNIT"    , aItemOri[2] , Nil})
				aadd(aLinha,{"C6_TES"       , "685", Nil})
				aadd(aLinha,{"C6_ENTREG"    , aItensFat[nIndFat][4], Nil})
				aadd(aLinha,{"C6_PEDCLI"    , aItensFat[nIndFat][5], Nil})

				aadd(aLinha,{"C6_NFORI"    	, aSaldoTer[nIndTerc][2], Nil})
				aadd(aLinha,{"C6_SERIORI"   , aSaldoTer[nIndTerc][3], Nil})
				aadd(aLinha,{"C6_ITEMORI"  	, aItemOri[1], Nil})
				aadd(aLinha,{"C6_IDENTB6"  	, aSaldoTer[nIndTerc][9], Nil})
				aadd(aLinhas, aLinha)
			endif
		endif

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


Static Function LerNFE(cDoc, cProduto, cIdent)
	Local cSql 		:= ""
	Local cItem 	:= ""
	Local nVunit 	:= 0
	Local ret       := {}

	cSql := "SELECT D1_ITEM, D1_VUNIT "
	cSql += " FROM " + RetSQLName("SD1") + " SD1 "
	cSql += "WHERE D1_FORNECE	  = '" + cCliente + "'"
	cSql += "  AND D1_LOJA 		  = '" + cLoja + "' "
	cSql += "  AND D1_DOC 		  = '" + cDoc + "' "
	cSql += "  AND D1_COD 	  	  = '" + cProduto + "' "
	cSql += "  AND D1_IDENTB6  	  = '" + cIdent + "' "
	cSql += "  AND D1_FILIAL 	  = '" + xFilial("SD1") + "' "
	cSql += "  AND SD1.D_E_L_E_T_ = ' ' "
	cAlias := MPSysOpenQuery(cSql)

	if (cAlias)->(!EOF())
		cItem := (cAlias)->D1_ITEM
		nVunit := (cAlias)->D1_VUNIT
		ret := {cItem, nVunit}
	endif

Return ret
