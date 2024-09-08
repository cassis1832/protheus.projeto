#Include "PROTHEUS.ch"
#INCLUDE "TBICONN.CH"

/*/{Protheus.doc} PL210C
    PL210C - Carga da tabela de terceiros
	Params: Tabela de itens a retornar
	@since 05/06/2024
/*/
User Function PL210C(aItens)
	Local cAlias
	Local cSql		:= ""
	Local nIndRet	:= 0
	Local nAlocado	:= 0
	Local aLinha  	:= {}
	Local aItensRet := {}

	// Itens a retornar 	(nIndFat, produto, qtde, agrega)
	// Saldos de terceiros	(produto, docto, serie, emissao, saldo, preco, usada, work, ident, item)
	Private aSaldoTer  	:= {}

	if Len(aItens) == 0
		return
	endif

	aItensRet := aItens

	//Carrega tabela de saldos de terceiros com todos os itens que
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

			cItem 	 := LerNota((cAlias)->B6_DOC, (cAlias)->B6_PRODUTO, (cAlias)->B6_IDENT)
			nAlocado := LerAlocados((cAlias)->B6_PRODUTO, (cAlias)->B6_DOC, (cAlias)->B6_SERIE, cItem)

			nSaldoDisp := (cAlias)->B6_SALDO - nAlocado

			if nSaldoDisp > 0
				// (produto, docto, serie, emissao, preco, saldo, usada, work, ident, item)
				aLinha := { ;
					(cAlias)->B6_PRODUTO, (cAlias)->B6_DOC, (cAlias)->B6_SERIE,  ;
					(cAlias)->B6_EMISSAO, (cAlias)->B6_PRUNIT, nSaldoDisp, ;
					0, 0, (cAlias)->B6_IDENT, cItem}

				AAdd(aSaldoTer, aLinha)
			endif

			(cAlias)->(DbSkip())
		EndDo
	next nInd

	(cAlias)->(DBCLOSEAREA())
Return aSaldoTer


Static Function LerNota(cDoc, cProduto, cIdent)
	Local cAlias
	Local cSql 		:= ""
	Local cItem 	:= ""

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
		cItem 	:= (cAlias)->D1_ITEM
	endif

	(cAlias)->(DBCLOSEAREA())
Return cItem


Static Function LerAlocados(cProduto, cNfOri, cSerieOri, cItemOri)
	Local cAlias
	Local cSql		:= ""
	Local nAlocado 	:= 0

	// Carregar pedidos de vendas
	cSql := "SELECT C5_NUM, C6_QTDVEN "
	cSql += "  FROM  " + RetSQLName("SC5") + " SC5 "
	cSql += " INNER JOIN " + RetSQLName("SC6") + " SC6 "
	cSql += "    ON C5_NUM         =  C6_NUM "
	cSql += " WHERE C5_NOTA        =  '' "
	cSql += "   AND C5_CLIENTE     =  '" + cCliente + "'"
	cSql += "   AND C5_LOJACLI     =  '" + cLoja + "'"
	cSql += "   AND C5_LIBEROK     <> 'E' "
	cSql += "   AND C6_QTDENT      <  C6_QTDVEN "
	cSql += "   AND C6_BLQ 		   <> 'R' "
	cSql += "   AND C6_PRODUTO     =  '" + cProduto + "' "
	cSql += "   AND C6_NFORI 	   =  '" + cNfOri + "' "
	cSql += "   AND C6_SERIORI     =  '" + cSerieOri + "' "
	cSql += "   AND C6_ITEMORI 	   =  '" + cItemOri + "' "
	cSql += "   AND C5_FILIAL      =  '" + xFilial("SC5") + "'"
	cSql += "   AND C6_FILIAL      =  '" + xFilial("SC6") + "'"
	cSql += "   AND SC5.D_E_L_E_T_ <> '*' "
	cSql += "   AND SC6.D_E_L_E_T_ <> '*' "
	cAlias := MPSysOpenQuery(cSql)

	While (cAlias)->(!EOF())
		nAlocado := nAlocado + (cAlias)->C6_QTDVEN
		(cAlias)->(DbSkip())
	End

	(cAlias)->(DBCLOSEAREA())
return nAlocado
